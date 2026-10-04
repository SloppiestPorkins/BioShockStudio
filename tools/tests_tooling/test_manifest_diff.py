"""Tests for tools/manifest_diff.py — synthetic small manifests in temp files.

    python -m unittest tools.tests_tooling.test_manifest_diff
    python -m unittest discover -s tools/tests_tooling -p 'test_manifest_diff.py'
"""

from __future__ import annotations

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import manifest_diff as md  # noqa: E402


OLD = {
    "formatVersion": 4,
    "package": "Sample",
    "generator": "BioShockStudio",
    "assets": [
        {"key": "StaticMesh_A_1", "name": "A"},
        {"key": "StaticMesh_B_2", "name": "B"},
    ],
    "instances": [
        {"actorKey": "SMA_1", "asset": "StaticMesh_A_1", "label": "one"},
    ],
    "lights": [
        {"key": "Light_L_1", "name": "L"},
    ],
    "actors": [
        {"key": "SMA_Keep_1", "className": "StaticMeshActor", "label": "Keep",
         "staticMesh": "A", "door": None},
        {"key": "SMA_Gone_2", "className": "StaticMeshActor", "label": "Gone",
         "staticMesh": "B"},
        {"key": "Door_D_3", "className": "MedicalDoor", "label": "Door",
         "door": {"locked": True, "attachments": [], "complete": True}},
    ],
}

NEW = {
    "formatVersion": 4,
    "package": "Sample",
    "generator": "BioShockStudio",
    "assets": [
        {"key": "StaticMesh_A_1", "name": "A"},
        {"key": "StaticMesh_C_3", "name": "C"},
    ],
    "instances": [
        {"actorKey": "SMA_1", "asset": "StaticMesh_A_1", "label": "one"},
        {"actorKey": "SMA_1", "asset": "StaticMesh_C_3", "label": "two"},
    ],
    "lights": [
        {"key": "Light_L_1", "name": "L"},
        {"key": "Light_L_2", "name": "L2"},
    ],
    "actors": [
        {"key": "SMA_Keep_1", "className": "StaticMeshActor", "label": "Keep",
         "staticMesh": "A", "door": None, "tag": "changed"},
        {"key": "Door_D_3", "className": "MedicalDoor", "label": "Door",
         "door": {"locked": False, "attachments": [{"staticMesh": {"objectName": "X"}}],
                  "complete": True}},
        {"key": "TV_New_4", "className": "TV_WallMounted", "label": "SteinmanTele"},
    ],
}


class ManifestDiffTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.old_path = Path(cls.tmp.name) / "old.ue5-level.json"
        cls.new_path = Path(cls.tmp.name) / "new.ue5-level.json"
        cls.old_path.write_text(json.dumps(OLD, ensure_ascii=False), encoding="utf-8")
        cls.new_path.write_text(json.dumps(NEW, ensure_ascii=False), encoding="utf-8")

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def run_cli(self, *argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            try:
                code = md.main([str(self.old_path), str(self.new_path), *argv])
            except SystemExit as exc:
                code = exc.code if isinstance(exc.code, int) else 1
                err.write(str(exc.code))
        return code, out.getvalue(), err.getvalue()

    def test_counts_and_actor_moves(self):
        report = md.diff_manifests(OLD, NEW)
        actors = report["collections"]["actors"]
        self.assertEqual(actors["oldCount"], 3)
        self.assertEqual(actors["newCount"], 3)
        self.assertEqual([a["key"] for a in actors["removed"]], ["SMA_Gone_2"])
        self.assertEqual([a["key"] for a in actors["added"]], ["TV_New_4"])
        changed_keys = {c["key"] for c in actors["changed"]}
        self.assertEqual(changed_keys, {"SMA_Keep_1", "Door_D_3"})
        door = next(c for c in actors["changed"] if c["key"] == "Door_D_3")
        self.assertIn("door", door["fields"])
        self.assertTrue(door["fields"]["door"]["old"]["locked"])
        self.assertFalse(door["fields"]["door"]["new"]["locked"])

    def test_assets_instances_lights(self):
        report = md.diff_manifests(OLD, NEW)
        assets = report["collections"]["assets"]
        self.assertEqual(assets["oldCount"], 2)
        self.assertEqual(assets["newCount"], 2)
        self.assertEqual([a["key"] for a in assets["removed"]], ["StaticMesh_B_2"])
        self.assertEqual([a["key"] for a in assets["added"]], ["StaticMesh_C_3"])
        self.assertEqual(report["collections"]["instances"]["newCount"], 2)
        self.assertEqual(len(report["collections"]["lights"]["added"]), 1)

    def test_table_and_json_cli(self):
        code, out, _ = self.run_cli()
        self.assertEqual(code, 0)
        self.assertIn("actors removed", out)
        self.assertIn("SMA_Gone_2", out)
        self.assertIn("TV_New_4", out)
        self.assertIn("Door_D_3", out)
        code, out, _ = self.run_cli("--json")
        self.assertEqual(code, 0)
        payload = json.loads(out)
        self.assertEqual(payload["collections"]["actors"]["removed"][0]["className"],
                         "StaticMeshActor")

    def test_missing_file_exits(self):
        with self.assertRaises(SystemExit):
            md.load_manifest(Path(self.tmp.name) / "nope.json")


if __name__ == "__main__":
    unittest.main()
