"""Headless driver for import_scripts_all_maps.py (Phase 2.3 tail / B1).

Unreal's -run=pythonscript does not reliably honour `if __name__ == '__main__'`, so the work
runs at import time and the report is written even when the run raises.

Environment:
  BIOSHOCK_SCRIPT_IMPORT_MAPS                comma-separated map list
  BIOSHOCK_SCRIPT_IMPORT_INCLUDE_MEDICAL=1   also re-import Medical (default skip)
  BIOSHOCK_SCRIPT_IMPORT_OUT                 report JSON path
  BIOSHOCK_SCRIPT_IMPORT_ROOT                prep dir with sidecars + manifests
  BIOSHOCK_SCRIPT_IMPORT_STOP_ON_ERROR=0     continue after a map failure
"""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_SCRIPT_IMPORT_OUT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock_import_scripts_all_maps.json"),
)

result = {"error": None}
try:
    import import_scripts_all_maps

    result = import_scripts_all_maps.main(OUT)
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    result = {"error": str(exc), "traceback": traceback.format_exc()}
    os.makedirs(os.path.dirname(os.path.abspath(OUT)) or ".", exist_ok=True)
    # Preserve any partial report the batch already wrote.
    if not os.path.isfile(OUT):
        with open(OUT, "w", encoding="utf-8") as handle:
            json.dump(result, handle, indent=2)
    else:
        try:
            with open(OUT, encoding="utf-8") as handle:
                prior = json.load(handle)
            prior["error"] = result["error"]
            prior["traceback"] = result["traceback"]
            with open(OUT, "w", encoding="utf-8") as handle:
                json.dump(prior, handle, indent=2)
        except Exception:
            with open(OUT, "w", encoding="utf-8") as handle:
                json.dump(result, handle, indent=2)
    raise
