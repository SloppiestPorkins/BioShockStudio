"""Headless driver for import_hud_ui.py.

PNG export directory default: %TEMP%/BioShockHudUi/import (see export_hud_ui.py).
"""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_HUD_UI_IMPORT_OUT",
    os.path.join(os.environ.get("TEMP", "."), "hud_ui_import_report.json"),
)
EXPORT = os.environ.get(
    "BIOSHOCK_HUD_UI_EXPORT",
    os.path.join(os.environ.get("TEMP", "."), "BioShockHudUi", "import"),
)

result = {"error": None}
try:
    import import_hud_ui

    result = import_hud_ui.main(EXPORT, OUT)
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
