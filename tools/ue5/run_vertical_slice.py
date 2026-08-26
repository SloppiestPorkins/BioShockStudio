"""Headless driver: build the Phase 0 vertical slice and write its report.

Unreal's -run=pythonscript does not reliably honour `if __name__ == '__main__'`, so the work runs
at import time, and the report is written even when the run fails — a traceback that reaches only
the log is not evidence anyone can read afterwards.
"""

import json
import os
import sys
import traceback

sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")

MANIFEST = os.environ.get(
    "BIOSHOCK_SLICE_MANIFEST",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json")
# Exported alongside the level by the same build. The older Exports\TommyGun predates manifest
# texture intent and import_bioshock refuses it outright, which is the correct behaviour.
WEAPON = os.environ.get(
    "BIOSHOCK_SLICE_WEAPON",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\TommyGun")
OUT = os.environ.get(
    "BIOSHOCK_SLICE_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\slice_report.json")

# Phase 0's "one enemy archetype": the splicer `1-Medical` places most of. Every other skeletal
# asset falls back to its bind-pose static mesh. Set to an empty string for every rig the level
# places -- that is the honest whole-level run. A first import of an unstamped rig still pays
# the animation cost; a second import of the same export reuses (`import_bioshock`).
RIGS = os.environ.get("BIOSHOCK_SLICE_RIGS", "Agg_BabyJane")
rig_names = {name.strip() for name in RIGS.split(",") if name.strip()} or None

result = {"error": None}
try:
    import verify_vertical_slice
    result = verify_vertical_slice.main(MANIFEST, OUT, WEAPON, rig_names)
except Exception as exc:  # noqa: BLE001 -- the commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
