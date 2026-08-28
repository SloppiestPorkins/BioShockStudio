"""Unit tests for tools/ue5/import_policy.py — runnable without Unreal."""

import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import import_policy  # noqa: E402


class ImportPolicyTests(unittest.TestCase):
    def test_dead_body_actor_classes(self):
        self.assertTrue(import_policy.is_dead_body_actor("DeadBodyContainer"))
        self.assertTrue(import_policy.is_dead_body_actor("KeyframedDeadBodyContainer"))
        self.assertTrue(import_policy.is_dead_body_actor("CorpseMaleBooty"))
        self.assertFalse(import_policy.is_dead_body_actor("StaticMeshActor"))

    def test_corpse_physics_only_on_containers(self):
        self.assertTrue(import_policy.uses_corpse_physics("DeadBodyContainer"))
        self.assertTrue(import_policy.uses_corpse_physics("KeyframedDeadBodyContainer"))
        self.assertFalse(import_policy.uses_corpse_physics("CorpseMaleBooty"))
        self.assertFalse(import_policy.uses_corpse_physics("AggBabyJaneBooty"))

    def test_requires_skeletal_rig(self):
        self.assertTrue(import_policy.requires_skeletal_rig("ShadowplayDoctor", "CorpseFemale"))
        self.assertTrue(import_policy.requires_skeletal_rig("AggBabyJaneBooty", "CorpseFemale"))
        self.assertFalse(import_policy.requires_skeletal_rig("StaticMeshActor", "Med_DoorAnim"))

    def test_effective_rig_names_unions_corpse_meshes(self):
        manifest = {
            "actors": [
                {"key": "a1", "className": "DeadBodyContainer", "skeletalMesh": "CorpseFemale"},
                {"key": "a2", "className": "AggBabyJaneBooty", "skeletalMesh": "CorpseFemale"},
            ],
            "assets": [
                {"key": "s1", "name": "CorpseMale", "kind": "SkeletalMesh"},
                {"key": "s2", "name": "Agg_BabyJane", "kind": "SkeletalMesh"},
            ],
            "instances": [
                {"actorKey": "a2", "asset": "s1"},
            ],
        }
        self.assertEqual(
            import_policy.dead_body_mesh_names(manifest),
            {"CorpseFemale", "CorpseMale"},
        )
        self.assertEqual(
            import_policy.effective_rig_names(manifest, {"Agg_BabyJane"}),
            {"Agg_BabyJane", "CorpseFemale", "CorpseMale"},
        )

    def test_medical_export_when_present(self):
        path = os.environ.get(
            "BIOSHOCK_SLICE_MANIFEST",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json",
        )
        if not os.path.exists(path):
            self.skipTest("Medical slice manifest not on disk")
        with open(path, encoding="utf-8") as handle:
            manifest = json.load(handle)
        names = import_policy.dead_body_mesh_names(manifest)
        self.assertIn("CorpseFemale", names)
        self.assertIn("CorpseMale", names)
        effective = import_policy.effective_rig_names(manifest, {"Agg_BabyJane"})
        self.assertTrue(names.issubset(effective))


if __name__ == "__main__":
    unittest.main()
