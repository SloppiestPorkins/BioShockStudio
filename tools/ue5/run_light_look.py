"""Headless driver: import Medical lights and write a mapping report."""

import json
import os
import sys
import traceback

sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")

MANIFEST = os.environ.get(
    "BIOSHOCK_LIGHT_MANIFEST",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\1-Medical\1-Medical\1-Medical.ue5-level.json")
OUT = os.environ.get(
    "BIOSHOCK_LIGHT_LOOK_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\cubemap-look\light_look_report.json")

result = {"error": None}
try:
    import verify_light_import
    result = verify_light_import.main(MANIFEST, OUT)
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
