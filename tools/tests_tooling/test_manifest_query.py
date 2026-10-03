"""Tests for tools/manifest_query.py: a small hand-built manifest, plus the real Medical one.

    python -m unittest discover -s tools/tests_tooling
"""

from __future__ import annotations

import contextlib
import io
import json
import math
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import manifest_query as mq  # noqa: E402

REAL_MANIFEST = mq.manifest_path("1-Medical", None)

# Light_Beams positions measured in the UE editor, 30 Sept 2026 (see manifest_query's docstring).
MEASURED_BEAMS_UE = [(-17018, 1322, 7508), (-17289, 1246, 7687), (-17277, 1465, 7699),
                     (-25232, 1120, 8064), (-31896, 1887, 8356)]


def translation(x, y, z):
    return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, y, z, 1]


SAMPLE = {
    "formatVersion": 4,
    "basis": "right-handed, +X forward, +Y left, +Z up, centimetres",
    "boundsMin": [-100, -100, -100],
    "assets": [
        {"key": "StaticMesh_Beam_1", "name": "Beam", "kind": "StaticMesh", "triangleCount": 30,
         "sections": [{"material": "Light_Beam_01"}], "file": "Meshes/Beam_1.obj"},
        {"key": "Brush_Model9_2", "name": "Model9", "kind": "Brush", "sections": []},
    ],
    "actors": [
        {"key": "SMA_A_1", "name": "A", "label": "Beam1", "className": "StaticMeshActor",
         "location": [100, 200, 300], "staticMesh": "Beam",
         "materialOverrides": [{"objectName": "MI_Red"}], "properties": [{"name": "x"}],
         "trailerHex": "00", "door": None},
        {"key": "SMA_B_2", "name": "Beam1", "label": "Café", "className": "StaticMeshActor",
         "location": [5000, 0, 0], "staticMesh": "Beam", "materialOverrides": []},
        {"key": "Door_D_3", "name": "D", "label": "MorgueDoor", "className": "MedicalDoor",
         "location": [110, 210, 300], "skeletalMesh": "Door_Mesh", "materialOverrides": [],
         "door": {"locked": True}},
        {"key": "Brush_V_4", "name": "V", "label": "Vol", "className": "TriggerVolume",
         "location": [0, 0, 0], "materialOverrides": []},
    ],
    "instances": [
        # Manifest space: Y is negated relative to the actor (UE) location.
        {"asset": "StaticMesh_Beam_1", "actorKey": "SMA_A_1", "label": "Beam1",
         "transform": translation(100, -200, 300)},
        {"asset": "StaticMesh_Beam_1", "actorKey": "SMA_B_2", "label": "Café",
         "transform": translation(5000, 0, 0)},
        # A brush whose geometry sits away from its actor (prePivot) - a separate placement.
        {"asset": "Brush_Model9_2", "actorKey": "Brush_V_4", "label": "Vol",
         "transform": translation(120, -190, 300)},
    ],
    "lights": [{"key": "Light_L_5", "name": "L", "location": [1, -2, 3]}],
}


class SampleManifestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.path = Path(cls.tmp.name) / "Sample.ue5-level.json"
        cls.path.write_text(json.dumps(SAMPLE, ensure_ascii=False), encoding="utf-8")

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def run_cli(self, *argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            try:
                code = mq.main(["--manifest", str(self.path), *argv])
            except SystemExit as exc:
                code = exc.code if isinstance(exc.code, int) else 1
                err.write(str(exc.code))
        return code, out.getvalue(), err.getvalue()

    def test_coordinate_mapping_is_y_negation(self):
        self.assertEqual(mq.manifest_to_ue([1, 2, 3]), (1.0, -2.0, 3.0))
        self.assertEqual(mq.ue_to_manifest(mq.manifest_to_ue([4, -5, 6])), (4.0, -5.0, 6.0))
        self.assertEqual(mq.instance_ue_location(SAMPLE["instances"][0]), (100.0, 200.0, 300.0))

    def test_parse_point_accepts_pasted_ue_vector(self):
        self.assertEqual(mq.parse_point(["X=-17018.000 Y=1322.000 Z=7508.000"]),
                         (-17018.0, 1322.0, 7508.0))
        self.assertEqual(mq.parse_point(["(-1,", "2,", "3.5)"]), (-1.0, 2.0, 3.5))
        with self.assertRaises(SystemExit):
            mq.parse_point(["1", "2"])

    def test_get_path_never_raises(self):
        actor = SAMPLE["actors"][2]
        self.assertTrue(mq.get_path(actor, "door.locked"))
        self.assertIsNone(mq.get_path(actor, "door.missing.deeper"))
        self.assertIsNone(mq.get_path(SAMPLE["actors"][0], "door.locked"))
        self.assertEqual(mq.get_path(actor, "location.1"), 210)

    def test_schema_lists_keys_types_and_space_notes(self):
        code, out, _ = self.run_cli("schema")
        self.assertEqual(code, 0)
        self.assertIn("actors: list of 4", out)
        self.assertIn("location", out)
        self.assertIn("UE space", out)
        self.assertIn("manifest space", out)
        code, out, _ = self.run_cli("schema", "actors")
        self.assertIn("door.locked", out)
        self.assertRegex(out, r"skeletalMesh\s+str\s+1/4")

    def test_hist(self):
        code, out, _ = self.run_cli("hist", "--json")
        self.assertEqual(json.loads(out)["counts"],
                         {"StaticMeshActor": 2, "MedicalDoor": 1, "TriggerVolume": 1})

    def test_class_with_fields_and_unknown_class(self):
        code, out, _ = self.run_cli("class", "medicaldoor", "--fields", "door.locked")
        self.assertEqual(code, 0)
        self.assertIn("MorgueDoor", out)
        self.assertIn("True", out)
        code, _, err = self.run_cli("class", "MedicalDor")
        self.assertNotEqual(code, 0)
        self.assertIn("MedicalDoor", err)

    def test_find_matches_mesh_and_unicode_label(self):
        code, out, _ = self.run_cli("find", "café", "--json")
        self.assertEqual([h["key"] for h in json.loads(out)], ["SMA_B_2"])
        code, out, _ = self.run_cli("find", "beam", "--json")
        self.assertEqual({h["key"] for h in json.loads(out)}, {"SMA_A_1", "SMA_B_2"})

    def test_near_in_both_spaces_dedupes_instances(self):
        code, out, _ = self.run_cli("near", "100", "200", "300", "--radius", "50", "--json")
        hits = json.loads(out)["hits"]
        keys = [(h["kind"], h["key"]) for h in hits]
        # The beam's own instance sits on its actor and is dropped; the brush instance is not.
        self.assertEqual(keys[0], ("actor", "SMA_A_1"))
        self.assertIn(("instance", "Brush_V_4"), keys)
        self.assertNotIn(("instance", "SMA_A_1"), keys)
        self.assertIn(("actor", "Door_D_3"), keys)
        code, out2, _ = self.run_cli("near", "100", "-200", "300", "--space", "manifest",
                                     "--radius", "50", "--json")
        self.assertEqual(json.loads(out2)["hits"], hits)

    def test_actor_prefers_label_over_name(self):
        code, out, err = self.run_cli("actor", "Beam1", "--brief")
        record = json.loads(out)
        self.assertEqual(record["key"], "SMA_A_1")
        self.assertIn("omitted by --brief", record["properties"])
        self.assertIn("SMA_B_2", err)  # the name match is reported, not silently dropped
        code, _, err = self.run_cli("actor", "nope")
        self.assertNotEqual(code, 0)

    def test_assets(self):
        code, out, _ = self.run_cli("assets", "beam", "--json")
        rows = json.loads(out)
        self.assertEqual([(r["key"], r["placements"]) for r in rows], [("StaticMesh_Beam_1", 2)])

    def test_mesh_reports_overrides_and_unexported_meshes(self):
        code, out, _ = self.run_cli("mesh", "Beam", "--json")
        placements = {p["actorKey"]: p for p in json.loads(out)["placements"]}
        self.assertEqual(placements["SMA_A_1"]["materialOverrides"], ["MI_Red"])
        self.assertEqual(placements["SMA_B_2"]["materialOverrides"], [])
        code, out, _ = self.run_cli("mesh", "Door_Mesh")
        self.assertEqual(code, 0)
        self.assertIn("UNPLACED", out)
        code, _, err = self.run_cli("mesh", "eam")
        self.assertEqual(code, 1)
        self.assertIn("Beam", err)

    def test_options_after_command_and_limit(self):
        code, out, _ = self.run_cli("hist", "--limit", "1")
        self.assertIn("... 2 more", out)


@unittest.skipUnless(REAL_MANIFEST.is_file(), "real Medical manifest not present")
class RealMedicalManifestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.index = mq.Index(mq.load_manifest(REAL_MANIFEST))

    def test_measured_beam_positions_match_instances_and_actors(self):
        beams = [i for i in self.index.instances if i.get("asset") == "StaticMesh_Light_Beams_4400"]
        for point in MEASURED_BEAMS_UE:
            nearest_instance = min(math.dist(mq.instance_ue_location(i), point) for i in beams)
            self.assertLess(nearest_instance, 1.0, point)
            actor = self.index.actor_by_key[min(
                beams, key=lambda i: math.dist(mq.instance_ue_location(i), point))["actorKey"]]
            self.assertLess(math.dist(mq.actor_ue_location(actor), point), 1.0, point)

    def test_near_finds_the_beam(self):
        hits = mq.near_hits(self.index, MEASURED_BEAMS_UE[0], 50)
        self.assertEqual(hits[0]["mesh"], "Light_Beams")


if __name__ == "__main__":
    unittest.main()
