"""Tests for tools/ue5/check_repairs_registered.py on a throwaway tools/ue5-shaped folder.

    python -m unittest discover -s tools/tests_tooling
"""

from __future__ import annotations

import contextlib
import io
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "ue5"))
import check_repairs_registered as crr  # noqa: E402

PIPELINE = '''
"""Slice setup. Mentions repair_mentioned_only in its docstring, which must not count."""
import unreal


def _local_step():
    import fix_via_local
    return fix_via_local.main()


STEPS = [
    ("repair_in_steps", "repair_in_steps", "main", ()),
    ("local", None, _local_step, ()),
    ("import", "import_thing", "main", ()),
    ("import2", "import_thing2", "main", ()),
    # repair_comment_only is mentioned here in a comment, which must not count either.
]
'''

FILES = {
    "setup_playable_slice.py": PIPELINE,
    "repair_in_steps.py": '"""In STEPS."""\n',
    "fix_via_local.py": '"""Imported by a local STEPS callable."""\n',
    "repair_by_importer.py": '"""Called by import_thing."""\n',
    "import_thing.py": 'import repair_by_importer\nrepair_by_importer.main()\n',
    "repair_by_string.py": '"""Loaded by path."""\n',
    "reimport_x.py": 'SCRIPT = "tools/ue5/repair_by_string.py"\n',
    "repair_comment_only.py": '"""Only ever mentioned in a comment."""\n',
    "repair_mentioned_only.py": '"""Only mentioned in a docstring."""\n',
    "repair_wrapper_only.py": '"""Only run by its run_ wrapper."""\n',
    "run_repair_wrapper_only.py": 'import repair_wrapper_only\nrepair_wrapper_only.main()\n',
    "repair_chain_driver.py": '"""Unregistered driver."""\nimport repair_chain_child\n',
    "repair_chain_child.py": '"""Only called by an unregistered driver."""\n',
    "repair_registered_driver.py": '"""Called by import_thing2."""\nimport fix_chain_ok\n',
    "import_thing2.py": 'import repair_registered_driver\n',
    "fix_chain_ok.py": '"""Called by a registered repair."""\n',
    "repair_one_off.py": '"""Renames assets once.\n\nPipeline: one-off\n"""\n',
    "fix_retired.py": '"""Superseded by fix_all.\n\n  pipeline: Retired - see fix_all\n"""\n',
    "fix_says_pipeline_elsewhere.py": 'X = 1\n"""Pipeline: one-off"""\n',
}


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        for name, text in FILES.items():
            (self.dir / name).write_text(textwrap.dedent(text), encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def statuses(self):
        report = crr.check(self.dir)
        return {r["script"][:-3]: r for r in report["results"]}

    def test_registration_rules(self):
        s = self.statuses()
        self.assertTrue(s["repair_in_steps"]["status"].startswith("STEPS"))
        self.assertIn("_local_step", s["fix_via_local"]["status"])
        self.assertEqual(s["repair_by_importer"]["status"], "via import_thing")
        self.assertEqual(s["repair_registered_driver"]["status"], "via import_thing2")
        self.assertEqual(s["fix_chain_ok"]["status"], "via repair_registered_driver")
        self.assertEqual(s["repair_one_off"]["status"], "opted out (one-off)")
        self.assertEqual(s["fix_retired"]["status"], "opted out (retired)")

    def test_unregistered_cases(self):
        s = self.statuses()
        for name in ("repair_comment_only", "repair_mentioned_only", "repair_wrapper_only",
                     "repair_chain_driver", "repair_chain_child", "fix_says_pipeline_elsewhere",
                     # reimport_x is a hand-run tool not reachable from STEPS: its reference to
                     # repair_by_string must not register it.
                     "repair_by_string"):
            self.assertFalse(s[name]["registered"], name)
        self.assertIn("run_repair_wrapper_only", " ".join(s["repair_wrapper_only"]["notes"]))
        self.assertIn("unregistered repair_chain_driver",
                      " ".join(s["repair_chain_child"]["notes"]))
        self.assertIn("setup_playable_slice", " ".join(s["repair_comment_only"]["notes"]))

    def test_exit_codes(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            self.assertEqual(crr.main(["--ue5-dir", str(self.dir)]), 1)
        self.assertIn("repair_comment_only.py", out.getvalue())
        for name in list(FILES):
            if name.startswith(("repair_", "fix_")) and not self.statuses()[name[:-3]]["registered"]:
                (self.dir / name).unlink()
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(crr.main(["--ue5-dir", str(self.dir)]), 0)

    def test_missing_steps_is_exit_2(self):
        (self.dir / "setup_playable_slice.py").write_text("X = 1\n", encoding="utf-8")
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(crr.main(["--ue5-dir", str(self.dir)]), 2)


class RealRepoTests(unittest.TestCase):
    def test_real_tools_ue5_parses_and_knows_the_beam_repair(self):
        report = crr.check(crr.UE5_DIR)
        status = {r["script"]: r["status"] for r in report["results"]}
        self.assertTrue(status["repair_light_beams.py"].startswith("STEPS"))
        # import_bioshock only mentions it in a comment; that alone must never register it.
        self.assertGreater(len(status), 20)


if __name__ == "__main__":
    unittest.main()
