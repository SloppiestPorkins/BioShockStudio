"""Headless driver: verify MainMenu startup map, widget, and Play → 1-Medical.

Unreal's -run=pythonscript does not reliably honour `if __name__ == '__main__'`, so the work runs
at import time, and the report is written even when the run fails.
"""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_MAIN_MENU_VERIFY_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\main_menu_verify_report.json",
)

result = {"error": None}
try:
    import verify_main_menu

    result = verify_main_menu.main(OUT)
except Exception as exc:  # noqa: BLE001 -- the commandlet must still write the file
    # main() may already have written a full report to OUT before raising --
    # merge the error/traceback into it instead of clobbering that data (w19 fix).
    merged = result
    if os.path.isfile(OUT):
        try:
            with open(OUT, "r", encoding="utf-8") as existing:
                merged = json.load(existing)
        except Exception:  # noqa: BLE001 -- fall back to the stub result on unreadable JSON
            merged = result
    merged["error"] = str(exc)
    merged["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(merged, handle, indent=2)
    raise
