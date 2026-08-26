"""Headless driver: Phase 4 ActionScriptNote first slice."""

import json
import os
import sys
import traceback

sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")

SCHEMA = os.environ.get(
    "BIOSHOCK_ACTION_SCHEMA",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\Scripting.schema.json")
OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\action_script_note_report.json")

result = {"error": None}
try:
    import verify_action_script_note
    result = verify_action_script_note.main(SCHEMA, OUT)
except Exception as exc:  # noqa: BLE001
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
