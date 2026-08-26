"""Headless driver: batch census first slices."""

import json
import os
import sys
import traceback

sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")

SCRIPTING = os.environ.get(
    "BIOSHOCK_SCRIPTING_SCHEMA",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\Scripting.schema.json")
SHOCKGAME = os.environ.get(
    "BIOSHOCK_SHOCKGAME_SCHEMA",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json")
OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\action_batch_census_report.json")

result = {"error": None}
try:
    import verify_action_batch_census
    result = verify_action_batch_census.main(SCRIPTING, SHOCKGAME, OUT)
except Exception as exc:  # noqa: BLE001
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
