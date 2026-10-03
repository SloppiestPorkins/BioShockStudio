"""Summarise one capture_set.ps1 run: contact sheet, per-shot frame stats, and a diff against baseline.

  python tools/ue5/capture_report.py RUN_DIR [--baseline DIR] [--threshold 2.0]

Writes RUN_DIR/contact_sheet.png, RUN_DIR/report.json and RUN_DIR/report.md.

A rendered capture is the only check in this project that can see what a player sees, but a folder
of PNGs is easy to skim past. This puts every shot on one sheet with its verdict, flags frames that
rendered nothing (stddev < 1) or almost nothing (mean < 3), and measures how far each shot moved
from its baseline. "changed" is a request for a human to look at the pair, not a failure: lighting,
materials and FX legitimately change the picture. Only blank / near-black / missing shots fail.

If RUN_DIR holds capture_set.json (written by capture_set.ps1), its viewpoint order and capture
status are used, so a viewpoint that produced no PNG still shows up on the sheet as missing.
Pillow only.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat

BLANK_STDDEV = 1.0
NEAR_BLACK_MEAN = 3.0
DEFAULT_THRESHOLD = 2.0
# Worst tile of a 16x9 grid, same mean-abs-diff measure. A whole-frame mean dilutes a change confined
# to a small region (a 100x100 white patch scores 1.4 globally, 189 on its tile); measured run-to-run
# noise on the animated dust-beam view peaks at 7.5 per tile, so 20 sits well clear of both.
DEFAULT_TILE_THRESHOLD = 20.0
TILE_GRID = (16, 9)
PIXEL_DELTA = 24
THUMB_W = 320
THUMB_H = 180
LABEL_H = 40
COLUMNS = 4
OUTPUTS = ("contact_sheet.png",)

CHANGED_MEANING = (
    '"changed" means "a human must look": the shot differs from its baseline by more than the '
    "threshold. It is not a pass/fail verdict. Open both PNGs and decide whether the difference is "
    "the intended fix or a regression. Only BLANK, NEAR-BLACK and MISSING shots are failures."
)

VERDICT_COLOURS = {
    "BLANK": (200, 40, 40),
    "NEAR-BLACK": (200, 40, 40),
    "MISSING": (200, 40, 40),
    "CHANGED": (230, 160, 20),
    "unchanged": (60, 160, 70),
    "no baseline": (110, 110, 110),
}
FAILING = ("BLANK", "NEAR-BLACK", "MISSING")


def frame_stats(img):
    """Mean and stddev of an image, averaged over R, G, B - the same measure capture_shot.ps1 uses."""
    st = ImageStat.Stat(img.convert("RGB"))
    return sum(st.mean) / 3.0, sum(st.stddev) / 3.0


def compare(img, base, pixel_delta=PIXEL_DELTA):
    """Mean absolute difference (0-255 levels, averaged over channels) and the percentage of pixels
    whose largest channel difference exceeds pixel_delta. A baseline of another size is resized to
    the shot first and reported as such, so a resolution change cannot hide behind an exception."""
    img = img.convert("RGB")
    base = base.convert("RGB")
    resized = base.size != img.size
    if resized:
        base = base.resize(img.size, Image.BILINEAR)
    diff = ImageChops.difference(img, base)
    mad = sum(ImageStat.Stat(diff).mean) / 3.0
    r, g, b = diff.split()
    worst = ImageChops.lighter(ImageChops.lighter(r, g), b)
    over = worst.point(lambda v: 255 if v > pixel_delta else 0)
    changed_pixels = over.histogram()[255]
    pct = 100.0 * changed_pixels / (img.size[0] * img.size[1])
    cols, rows = TILE_GRID
    w, h = diff.size
    tile = 0.0
    for j in range(rows):
        for i in range(cols):
            box = (i * w // cols, j * h // rows, (i + 1) * w // cols, (j + 1) * h // rows)
            tile = max(tile, sum(ImageStat.Stat(diff.crop(box)).mean) / 3.0)
    return mad, pct, resized, tile


def _load_status(run_dir):
    path = os.path.join(run_dir, "capture_set.json")
    if not os.path.isfile(path):
        return None
    with open(path, encoding="utf-8-sig") as f:
        return json.load(f)


def _shot_names(run_dir, status):
    """Viewpoint order from capture_set.json, then any other PNG in the folder (e.g. *_hud.png)."""
    names = []
    if status:
        for vp in status.get("viewpoints", []):
            names.append(vp["name"])
    pngs = sorted(
        os.path.splitext(f)[0]
        for f in os.listdir(run_dir)
        if f.lower().endswith(".png") and f not in OUTPUTS
    )
    for n in pngs:
        if n not in names:
            names.append(n)
    return names


def analyse(run_dir, baseline_dir=None, threshold=DEFAULT_THRESHOLD, pixel_delta=PIXEL_DELTA,
            tile_threshold=DEFAULT_TILE_THRESHOLD):
    status = _load_status(run_dir)
    by_name = {vp["name"]: vp for vp in (status or {}).get("viewpoints", [])}
    shots = []
    for name in _shot_names(run_dir, status):
        png = os.path.join(run_dir, name + ".png")
        entry = {"name": name, "file": png if os.path.isfile(png) else None, "flags": []}
        if name in by_name:
            entry["captureStatus"] = by_name[name].get("status")
        if entry["file"] is None:
            entry["verdict"] = "MISSING"
            entry["flags"].append("missing")
            shots.append(entry)
            continue

        with Image.open(png) as im:
            img = im.convert("RGB")
        entry["size"] = list(img.size)
        mean, sd = frame_stats(img)
        entry["mean"] = round(mean, 3)
        entry["stddev"] = round(sd, 3)
        if sd < BLANK_STDDEV:
            entry["flags"].append("blank")
        if mean < NEAR_BLACK_MEAN:
            entry["flags"].append("near-black")

        base_path = os.path.join(baseline_dir, name + ".png") if baseline_dir else None
        if base_path and os.path.isfile(base_path):
            with Image.open(base_path) as bm:
                base = bm.convert("RGB")
            mad, pct, resized, tile = compare(img, base, pixel_delta)
            entry["baseline"] = base_path
            entry["meanAbsDiff"] = round(mad, 3)
            entry["pctPixelsChanged"] = round(pct, 3)
            entry["worstTileDiff"] = round(tile, 3)
            if resized:
                entry["flags"].append("baseline-size-differs")
            if mad > threshold:
                entry["flags"].append("changed")
            elif tile > tile_threshold:
                entry["flags"].append("changed")
                entry["flags"].append("changed-locally")
        else:
            entry["baseline"] = None

        if "blank" in entry["flags"]:
            entry["verdict"] = "BLANK"
        elif "near-black" in entry["flags"]:
            entry["verdict"] = "NEAR-BLACK"
        elif "changed" in entry["flags"]:
            entry["verdict"] = "CHANGED"
        elif entry["baseline"]:
            entry["verdict"] = "unchanged"
        else:
            entry["verdict"] = "no baseline"
        shots.append(entry)

    summary = {}
    for s in shots:
        summary[s["verdict"]] = summary.get(s["verdict"], 0) + 1
    return {
        "runDir": os.path.abspath(run_dir),
        "baselineDir": os.path.abspath(baseline_dir) if baseline_dir else None,
        "baselineFound": bool(baseline_dir and os.path.isdir(baseline_dir)),
        "threshold": threshold,
        "tileThreshold": tile_threshold,
        "pixelDelta": pixel_delta,
        "blankStddevBelow": BLANK_STDDEV,
        "nearBlackMeanBelow": NEAR_BLACK_MEAN,
        "changedMeans": CHANGED_MEANING,
        "failed": [s["name"] for s in shots if s["verdict"] in FAILING],
        "needsHumanLook": [s["name"] for s in shots if s["verdict"] == "CHANGED"],
        "summary": summary,
        "shots": shots,
    }


def _font(size):
    for name in ("arial.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def contact_sheet(report, out_path):
    shots = report["shots"]
    cols = max(1, min(COLUMNS, len(shots)))
    rows = max(1, (len(shots) + cols - 1) // cols)
    pad = 6
    tile_w, tile_h = THUMB_W + pad, THUMB_H + LABEL_H + pad
    sheet = Image.new("RGB", (cols * tile_w + pad, rows * tile_h + pad), (24, 24, 24))
    draw = ImageDraw.Draw(sheet)
    name_font, info_font = _font(14), _font(12)

    for i, s in enumerate(shots):
        x = pad + (i % cols) * tile_w
        y = pad + (i // cols) * tile_h
        colour = VERDICT_COLOURS.get(s["verdict"], (110, 110, 110))
        if s["file"]:
            with Image.open(s["file"]) as im:
                thumb = im.convert("RGB")
            thumb.thumbnail((THUMB_W, THUMB_H))
            ox = x + (THUMB_W - thumb.size[0]) // 2
            oy = y + (THUMB_H - thumb.size[1]) // 2
            sheet.paste(thumb, (ox, oy))
        else:
            draw.rectangle([x, y, x + THUMB_W - 1, y + THUMB_H - 1], fill=(50, 20, 20))
            draw.text((x + 10, y + THUMB_H // 2 - 8), "no image (%s)" % (s.get("captureStatus") or "missing"),
                      fill=(240, 200, 200), font=info_font)
        draw.rectangle([x, y, x + THUMB_W - 1, y + THUMB_H - 1], outline=colour, width=3)
        draw.rectangle([x, y + THUMB_H, x + THUMB_W - 1, y + THUMB_H + LABEL_H - 1], fill=colour)
        draw.text((x + 6, y + THUMB_H + 3), s["name"], fill=(255, 255, 255), font=name_font)
        info = s["verdict"]
        if s["verdict"] == "MISSING" and s.get("captureStatus"):
            info += " - capture %s" % s["captureStatus"]
        if "mean" in s:
            info += "  mean %.1f sd %.1f" % (s["mean"], s["stddev"])
        if "meanAbsDiff" in s:
            info += "  diff %.2f" % s["meanAbsDiff"]
        draw.text((x + 6, y + THUMB_H + 21), info, fill=(255, 255, 255), font=info_font)
    sheet.save(out_path)
    return sheet.size


def _markdown(report):
    lines = [
        "# Capture report",
        "",
        "- Run: `%s`" % report["runDir"],
        "- Baseline: `%s`%s" % (report["baselineDir"] or "none",
                               "" if report["baselineFound"] or not report["baselineDir"] else " (not found)"),
        "",
        "**%s**" % report["changedMeans"],
        "",
        "Frame checks: blank when stddev < %.0f, near-black when mean < %.0f. Changed when the "
        "whole-frame mean absolute difference > %.2f levels, or any tile of a %dx%d grid differs by "
        "> %.0f (flag changed-locally); the %% column counts pixels whose largest channel moved more "
        "than %d levels." % (report["blankStddevBelow"], report["nearBlackMeanBelow"],
                             report["threshold"], TILE_GRID[0], TILE_GRID[1],
                             report["tileThreshold"], report["pixelDelta"]),
        "",
        "| viewpoint | verdict | capture | mean | stddev | mean abs diff | %% px > %d | flags |" % report["pixelDelta"],
        "|---|---|---|---|---|---|---|---|",
    ]

    def cell(v, fmt="%.2f"):
        return "" if v is None else fmt % v

    for s in report["shots"]:
        lines.append("| %s | %s | %s | %s | %s | %s | %s | %s |" % (
            s["name"], s["verdict"], s.get("captureStatus") or "",
            cell(s.get("mean")), cell(s.get("stddev")), cell(s.get("meanAbsDiff")),
            cell(s.get("pctPixelsChanged")), ", ".join(s["flags"])))
    lines.append("")
    if report["failed"]:
        lines.append("FAILED (blank, near-black or missing): " + ", ".join(report["failed"]))
    if report["needsHumanLook"]:
        lines.append("A human must look at (changed vs baseline): " + ", ".join(report["needsHumanLook"]))
    if not report["failed"] and not report["needsHumanLook"]:
        lines.append("No blank frames and nothing over the change threshold. That says the pictures "
                     "match the baseline, not that the baseline looks right.")
    lines.append("")
    return "\n".join(lines)


def build_report(run_dir, baseline_dir=None, threshold=DEFAULT_THRESHOLD, pixel_delta=PIXEL_DELTA,
                 tile_threshold=DEFAULT_TILE_THRESHOLD):
    report = analyse(run_dir, baseline_dir, threshold, pixel_delta, tile_threshold)
    if report["shots"]:
        report["contactSheet"] = os.path.join(os.path.abspath(run_dir), "contact_sheet.png")
        contact_sheet(report, report["contactSheet"])
    else:
        report["contactSheet"] = None
    with open(os.path.join(run_dir, "report.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    with open(os.path.join(run_dir, "report.md"), "w", encoding="utf-8") as f:
        f.write(_markdown(report))
    return report


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("run_dir")
    ap.add_argument("--baseline", default=None, help="folder of <viewpoint>.png baselines")
    ap.add_argument("--tile-threshold", type=float, default=DEFAULT_TILE_THRESHOLD,
                    help="worst-tile mean-absolute-difference above which a shot is flagged changed "
                         "(default 20; catches changes confined to a small region)")
    ap.add_argument("--threshold", type=float, default=DEFAULT_THRESHOLD,
                    help="mean-absolute-difference above which a shot is flagged changed (default 2.0)")
    ap.add_argument("--pixel-delta", type=int, default=PIXEL_DELTA,
                    help="per-pixel channel difference counted as a changed pixel (default 24)")
    args = ap.parse_args(argv)

    if not os.path.isdir(args.run_dir):
        print("capture_report: no such run dir: %s" % args.run_dir, file=sys.stderr)
        return 2
    report = build_report(args.run_dir, args.baseline, args.threshold, args.pixel_delta,
                          args.tile_threshold)

    for s in report["shots"]:
        extra = ""
        if "meanAbsDiff" in s:
            extra = "  diff=%.2f (%.1f%% px)" % (s["meanAbsDiff"], s["pctPixelsChanged"])
        if "mean" in s:
            stats = "  mean=%.1f sd=%.1f" % (s["mean"], s["stddev"])
        else:
            stats = "  (capture status: %s)" % (s.get("captureStatus") or "unknown")
        print("%-32s %-12s%s%s" % (s["name"], s["verdict"], stats, extra))
    print("contact sheet: %s" % report["contactSheet"])
    print("report       : %s" % os.path.join(report["runDir"], "report.md"))
    if report["needsHumanLook"]:
        print('CHANGED vs baseline - a human must look (not a failure): ' + ", ".join(report["needsHumanLook"]))
    if report["failed"]:
        print("FAILED - blank, near-black or missing: " + ", ".join(report["failed"]))
        return 1
    if not report["shots"]:
        print("FAILED - no shots in run dir")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
