"""Headless driver: create/wire the BioShock front-end main menu.

Unreal's -run=pythonscript does not reliably honour `if __name__ == '__main__'`, so the work runs
at import time, and the report is written even when the run fails.
"""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_MAIN_MENU_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\main_menu_setup_report.json",
)

result = {"error": None}
try:
    import setup_main_menu

    result = setup_main_menu.main(OUT)
except Exception as exc:  # noqa: BLE001 -- the commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
