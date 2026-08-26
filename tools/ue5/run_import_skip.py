"""Headless driver: prove rig skip-on-exists, and that it refuses a stale asset.

Unreal's -run=pythonscript does not reliably honour `if __name__ == '__main__'`, so the work runs
at import time and the report is written even when the run raises.
"""

import json
import os
import sys
import traceback

sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")

EXPORT = os.environ.get(
    "BIOSHOCK_SKIP_EXPORT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\TommyGun")
OUT = os.environ.get(
    "BIOSHOCK_SKIP_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\skip_report.json")

result = {"error": None}
try:
    import verify_import_skip
    result = verify_import_skip.main(EXPORT, OUT)
except Exception as exc:  # noqa: BLE001 -- the commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
