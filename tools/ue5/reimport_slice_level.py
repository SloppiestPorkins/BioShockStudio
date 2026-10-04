"""Re-import a level manifest INTO the playable slice map, then save it.

The playable slice (/Game/BioShockSlice/1-Medical) is built by running setup_playable_slice's STEPS
over an imported level. When the exporter changes what a level contains -- on 4 Oct 2026 the
struct-array size fix recovered 442 Medical actors the old export had dropped -- the slice needs the
new manifest imported into it, then STEPS re-run so the new actors get the slice treatment
(collision, lighting, doors, pickups, scripts...). import_level is idempotent by BioShockKey: existing
actors are updated, missing ones created, meshes that already exist are reused.

Run with the editor closed, through ue_run (one Unreal process at a time):
    python tools/ue5/ue_run.py reimport_slice_level --timeout 7200
then: python tools/ue5/ue_run.py setup_playable_slice --timeout 7200

Env:
  BIOSHOCK_LEVEL_JSON  manifest (default: the project's Exports/slice/1-Medical/1-Medical.ue5-level.json)
  BIOSHOCK_SLICE_MAP   map (default /Game/BioShockSlice/1-Medical)

Commit the UE repo before running: the UE repo is the undo.

Pipeline: entry-point -- a top-level driver for refreshing the slice from a new export.
"""
from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_level  # noqa: E402

MAP_PATH = os.environ.get("BIOSHOCK_SLICE_MAP", "/Game/BioShockSlice/1-Medical")
OUT = os.path.join(os.environ.get("TEMP", "."), "reimport_slice_level.json")


def main():
    manifest = os.environ.get("BIOSHOCK_LEVEL_JSON") or os.path.join(
        os.path.dirname(unreal.Paths.get_project_file_path()),
        "Exports", "slice", "1-Medical", "1-Medical.ue5-level.json")
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(MAP_PATH):
        raise RuntimeError("could not load %s" % MAP_PATH)
    # Reuse rigs already in the project: re-importing them headless crashed the engine
    # (AsyncLoading2 assertion on Gate01Anim, 4 Oct 2026). Set BIOSHOCK_REUSE_RIGS=0 to force.
    os.environ.setdefault("BIOSHOCK_REUSE_RIGS", "1")
    report = import_level.main(manifest)
    if not level.save_current_level():
        raise RuntimeError("save_current_level failed for %s" % MAP_PATH)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump({"map": MAP_PATH, "manifest": manifest, "report": report}, handle, indent=2,
                  default=str)
    unreal.log("[reimport-slice-level] %s -> %s" % (manifest, OUT))
    return report


if __name__ == "__main__":
    main()
