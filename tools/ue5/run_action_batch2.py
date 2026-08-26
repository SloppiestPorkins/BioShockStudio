"""Headless driver: batch2 census."""

import json
import os
import sys
import traceback

sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")

SHOCKAI = os.environ.get(
    "BIOSHOCK_SHOCKAI_SCHEMA",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockAI.schema.json")
SHOCKGAME = os.environ.get(
    "BIOSHOCK_SHOCKGAME_SCHEMA",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json")
OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\action_batch2_report.json")

try:
    import verify_action_batch2
    verify_action_batch2.main(SHOCKAI, SHOCKGAME, OUT)
except Exception as exc:  # noqa: BLE001
    result = {"error": str(exc), "traceback": traceback.format_exc()}
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
