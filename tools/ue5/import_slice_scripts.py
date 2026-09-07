"""Import Medical Script actors into the playable slice map (/Game/BioShockSlice/1-Medical).

Wraps import_scripts.import_scripts after loading the slice level. Sidecar defaults to
Exports\\slice\\1-Medical.script-actions.json next to the level JSON.
"""

from __future__ import annotations

import json
import os

import unreal

import import_scripts
import import_slice_doors

DEFAULT_MANIFEST = (
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json"
)
SLICE_MAP = "/Game/BioShockSlice/1-Medical"


def _log(message):
    unreal.log("[bioshock-slice-scripts] %s" % message)


def main(manifest_path=None, map_path=SLICE_MAP, limit=None, save=True):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    if not os.path.isfile(manifest_path):
        raise RuntimeError("missing manifest %s" % manifest_path)

    import_slice_doors._open_slice_map(map_path)
    # Full Medical script set — playable slice needs LoadRoomDoor + OpenMedicalHallwayDoor etc.
    limit_env = os.environ.get("BIOSHOCK_SCRIPT_LIMIT")
    if limit is None and limit_env:
        limit = int(limit_env)

    report = import_scripts.import_scripts(manifest_path, limit=limit)
    report["map"] = map_path

    if save:
        level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
        if not level.save_current_level():
            raise RuntimeError("could not save %s" % map_path)

    _log("slice scripts created=%s registry=%s" % (report.get("created"), report.get("registry_num")))
    return report


if __name__ == "__main__":
    out = os.environ.get(
        "BIOSHOCK_ACTION_OUT",
        os.path.join(os.environ.get("TEMP", "."), "slice_scripts_report.json"),
    )
    result = main()
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
