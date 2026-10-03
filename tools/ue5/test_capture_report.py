"""Unit tests for capture_report.py, runnable without Unreal.

Synthetic images cover the verdicts (blank, near-black, identical to baseline, shifted, missing).
Real 1280x720 captures are used when present: set CAPTURE_SAMPLE_SHOTS to a folder of PNGs, or keep
the default below; those tests skip when the folder is absent. Captures are copyrighted game
imagery, so they are read from outside the repo and never copied into it.
"""

import glob
import json
import os
import random
import shutil
import sys
import tempfile
import unittest

from PIL import Image, ImageChops, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import capture_report  # noqa: E402

SAMPLE_SHOTS = os.environ.get(
    "CAPTURE_SAMPLE_SHOTS",
    r"C:\Users\Jack\AppData\Local\Temp\claude\C--Users-Jack-Documents-AI-Test"
    r"\9ae00176-5148-4c8e-9fe9-dc9e9d9c6c6f\scratchpad\shots",
)
SAMPLES = sorted(glob.glob(os.path.join(SAMPLE_SHOTS, "*.png")))


def _noise(size=(320, 180), lo=40, hi=200, seed=7):
    rng = random.Random(seed)
    im = Image.new("RGB", size)
    im.putdata([(rng.randint(lo, hi), rng.randint(lo, hi), rng.randint(lo, hi))
                for _ in range(size[0] * size[1])])
    return im


def _gradient(size=(320, 180)):
    w, h = size
    im = Image.new("RGB", size)
    im.putdata([((x * 255) // (w - 1), (y * 255) // (h - 1), 128) for y in range(h) for x in range(w)])
    return im


def _shift(im, dx):
    out = Image.new("RGB", im.size)
    out.paste(im, (dx, 0))
    return out


class FrameStatsTests(unittest.TestCase):
    def test_uniform_frame_has_zero_stddev(self):
        mean, sd = capture_report.frame_stats(Image.new("RGB", (64, 36), (90, 90, 90)))
        self.assertAlmostEqual(mean, 90.0, places=3)
        self.assertAlmostEqual(sd, 0.0, places=3)

    def test_noise_has_spread(self):
        mean, sd = capture_report.frame_stats(_noise())
        self.assertGreater(sd, 20)
        self.assertTrue(100 < mean < 140)


class CompareTests(unittest.TestCase):
    def test_identical_is_zero(self):
        im = _gradient()
        mad, pct, resized, _tile = capture_report.compare(im, im.copy())
        self.assertEqual(mad, 0.0)
        self.assertEqual(pct, 0.0)
        self.assertFalse(resized)

    def test_shift_is_large(self):
        im = _gradient()
        mad, pct, _, _tile = capture_report.compare(_shift(im, 40), im)
        self.assertGreater(mad, capture_report.DEFAULT_THRESHOLD)
        self.assertGreater(pct, 10.0)

    def test_small_uniform_offset_is_below_pixel_delta(self):
        im = Image.new("RGB", (64, 36), (100, 100, 100))
        other = Image.new("RGB", (64, 36), (110, 100, 100))
        mad, pct, _, _tile = capture_report.compare(other, im)
        self.assertAlmostEqual(mad, 10.0 / 3.0, places=3)
        self.assertEqual(pct, 0.0)  # 10 levels is under the 24-level per-pixel cut

    def test_pct_counts_pixels_over_delta(self):
        base = Image.new("RGB", (100, 10), (0, 0, 0))
        shot = base.copy()
        shot.paste((0, 0, 200), (0, 0, 25, 10))  # a quarter of the pixels, blue channel only
        _, pct, _, _ = capture_report.compare(shot, base)
        self.assertAlmostEqual(pct, 25.0, places=3)

    def test_small_patch_is_caught_by_worst_tile(self):
        # A 100x100 white patch (a wedge, a decal, a sign) is diluted below the whole-frame
        # threshold; the worst tile must still catch it.
        base = Image.effect_noise((1280, 720), 40).convert("RGB")
        shot = base.copy()
        ImageDraw.Draw(shot).rectangle((600, 300, 699, 399), fill=(255, 255, 255))
        mad, pct, _, tile = capture_report.compare(shot, base)
        self.assertLess(mad, capture_report.DEFAULT_THRESHOLD)
        self.assertGreater(tile, capture_report.DEFAULT_TILE_THRESHOLD)

    def test_size_mismatch_resizes_baseline(self):
        im = _gradient((320, 180))
        mad, _, resized, _ = capture_report.compare(im, _gradient((640, 360)))
        self.assertTrue(resized)
        self.assertLess(mad, 2.0)


class ReportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="capture_report_test_")
        self.run = os.path.join(self.tmp, "run")
        self.base = os.path.join(self.tmp, "baseline")
        os.makedirs(self.run)
        os.makedirs(self.base)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _save(self, folder, name, im):
        im.save(os.path.join(folder, name + ".png"))

    def _by_name(self, report):
        return {s["name"]: s for s in report["shots"]}

    def test_verdicts(self):
        good = _gradient()
        self._save(self.run, "same", good)
        self._save(self.base, "same", good)
        self._save(self.run, "moved", _shift(good, 40))
        self._save(self.base, "moved", good)
        self._save(self.run, "blank", Image.new("RGB", (320, 180), (128, 128, 128)))
        self._save(self.run, "black", Image.new("RGB", (320, 180), (0, 0, 0)))
        self._save(self.run, "dim", _noise(lo=0, hi=5))
        self._save(self.run, "new", good)

        report = capture_report.build_report(self.run, self.base)
        shots = self._by_name(report)

        self.assertEqual(shots["same"]["verdict"], "unchanged")
        self.assertEqual(shots["same"]["meanAbsDiff"], 0.0)
        self.assertEqual(shots["moved"]["verdict"], "CHANGED")
        self.assertIn("changed", shots["moved"]["flags"])
        self.assertEqual(shots["blank"]["verdict"], "BLANK")
        self.assertNotIn("near-black", shots["blank"]["flags"])
        self.assertEqual(shots["black"]["verdict"], "BLANK")
        self.assertIn("near-black", shots["black"]["flags"])
        self.assertEqual(shots["dim"]["verdict"], "NEAR-BLACK")
        self.assertNotIn("blank", shots["dim"]["flags"])
        self.assertEqual(shots["new"]["verdict"], "no baseline")
        self.assertIsNone(shots["new"]["baseline"])

        self.assertEqual(sorted(report["failed"]), ["black", "blank", "dim"])
        self.assertEqual(report["needsHumanLook"], ["moved"])

    def test_threshold_controls_changed(self):
        good = _gradient()
        self._save(self.run, "moved", _shift(good, 40))
        self._save(self.base, "moved", good)
        mad = capture_report.build_report(self.run, self.base)["shots"][0]["meanAbsDiff"]
        report = capture_report.build_report(self.run, self.base, threshold=mad + 1,
                                             tile_threshold=256)
        self.assertEqual(report["shots"][0]["verdict"], "unchanged")

    def test_outputs_and_wording(self):
        good = _gradient()
        self._save(self.run, "a", good)
        self._save(self.base, "a", _shift(good, 30))
        self._save(self.run, "b", good)
        self._save(self.run, "c", good)
        self._save(self.run, "d", good)
        self._save(self.run, "e", good)
        report = capture_report.build_report(self.run, self.base)

        sheet = os.path.join(self.run, "contact_sheet.png")
        self.assertTrue(os.path.isfile(sheet))
        with Image.open(sheet) as im:
            # 5 shots -> 4 columns x 2 rows of 320x(180+40) tiles plus padding
            self.assertEqual(im.size, (4 * 326 + 6, 2 * 226 + 6))
        with open(os.path.join(self.run, "report.json"), encoding="utf-8") as f:
            data = json.load(f)
        self.assertEqual(len(data["shots"]), 5)
        self.assertIn("a human must look", data["changedMeans"])
        self.assertIn("not a pass/fail", data["changedMeans"])
        with open(os.path.join(self.run, "report.md"), encoding="utf-8") as f:
            md = f.read()
        self.assertIn('"changed" means "a human must look"', md)
        self.assertIn("| a | CHANGED |", md)
        self.assertIn("A human must look at (changed vs baseline): a", md)
        self.assertEqual(report["needsHumanLook"], ["a"])

    def test_report_outputs_are_not_treated_as_shots(self):
        self._save(self.run, "a", _gradient())
        capture_report.build_report(self.run)
        report = capture_report.build_report(self.run)  # second pass sees contact_sheet.png
        self.assertEqual([s["name"] for s in report["shots"]], ["a"])

    def test_capture_set_status_adds_missing_viewpoints_in_order(self):
        self._save(self.run, "second", _gradient())
        self._save(self.run, "second_hud", _noise())
        status = {"set": "t", "viewpoints": [
            {"name": "first", "status": "busy"},
            {"name": "second", "status": "ok"},
            {"name": "third", "status": "no shot"},
        ]}
        with open(os.path.join(self.run, "capture_set.json"), "w", encoding="utf-8-sig") as f:
            json.dump(status, f)  # PowerShell writers may add a BOM
        report = capture_report.build_report(self.run, os.path.join(self.tmp, "nonexistent"))
        names = [s["name"] for s in report["shots"]]
        self.assertEqual(names, ["first", "second", "third", "second_hud"])
        shots = self._by_name(report)
        self.assertEqual(shots["first"]["verdict"], "MISSING")
        self.assertEqual(shots["first"]["captureStatus"], "busy")
        self.assertEqual(shots["third"]["verdict"], "MISSING")
        self.assertEqual(shots["second"]["verdict"], "no baseline")
        self.assertFalse(report["baselineFound"])
        self.assertEqual(sorted(report["failed"]), ["first", "third"])

    def test_main_exit_codes(self):
        self._save(self.run, "a", _gradient())
        self.assertEqual(capture_report.main([self.run]), 0)
        self._save(self.run, "b", Image.new("RGB", (32, 18), (0, 0, 0)))
        self.assertEqual(capture_report.main([self.run]), 1)
        self.assertEqual(capture_report.main([os.path.join(self.tmp, "nope")]), 2)

    def test_changed_alone_does_not_fail(self):
        good = _gradient()
        self._save(self.run, "a", _shift(good, 60))
        self._save(self.base, "a", good)
        self.assertEqual(capture_report.main([self.run, "--baseline", self.base]), 0)

    def test_empty_run_fails(self):
        self.assertEqual(capture_report.main([self.run]), 1)


@unittest.skipUnless(SAMPLES, "no sample captures at %s" % SAMPLE_SHOTS)
class RealCaptureTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="capture_report_real_")

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_real_captures_are_not_blank(self):
        for path in SAMPLES:
            with Image.open(path) as im:
                mean, sd = capture_report.frame_stats(im)
            self.assertGreater(sd, capture_report.BLANK_STDDEV, path)
            self.assertGreater(mean, capture_report.NEAR_BLACK_MEAN, path)

    def test_real_capture_vs_itself_and_shifted(self):
        run = os.path.join(self.tmp, "run")
        base = os.path.join(self.tmp, "base")
        os.makedirs(run)
        os.makedirs(base)
        with Image.open(SAMPLES[0]) as im:
            shot = im.convert("RGB")
        shot.save(os.path.join(run, "same.png"))
        shot.save(os.path.join(base, "same.png"))
        _shift(shot, 64).save(os.path.join(run, "shifted.png"))
        shot.save(os.path.join(base, "shifted.png"))

        report = capture_report.build_report(run, base)
        shots = {s["name"]: s for s in report["shots"]}
        self.assertEqual(shots["same"]["verdict"], "unchanged")
        self.assertEqual(shots["same"]["pctPixelsChanged"], 0.0)
        self.assertEqual(shots["shifted"]["verdict"], "CHANGED")
        self.assertGreater(shots["shifted"]["pctPixelsChanged"], 1.0)
        self.assertEqual(shots["same"]["size"], [1280, 720])

    def test_real_captures_differ_from_each_other(self):
        if len(SAMPLES) < 2:
            self.skipTest("need two sample captures")
        with Image.open(SAMPLES[0]) as a, Image.open(SAMPLES[1]) as b:
            mad, _, _, _ = capture_report.compare(a, b)
        self.assertGreater(mad, capture_report.DEFAULT_THRESHOLD)

    def test_contact_sheet_over_all_samples(self):
        run = os.path.join(self.tmp, "run")
        os.makedirs(run)
        for path in SAMPLES:
            shutil.copy(path, run)
        report = capture_report.build_report(run)
        self.assertEqual(len(report["shots"]), len(SAMPLES))
        self.assertEqual(report["failed"], [])
        with Image.open(report["contactSheet"]) as sheet:
            diff = ImageChops.difference(sheet.convert("RGB"), Image.new("RGB", sheet.size, (24, 24, 24)))
            self.assertIsNotNone(diff.getbbox())


if __name__ == "__main__":
    unittest.main()
