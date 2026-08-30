"""Headless driver: prep Medical + -game encounter verify."""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

SCHEMA = os.environ.get(
    "BIOSHOCK_RUNTIME_SCHEMA",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json",
)
OUT = os.environ.get(
    "BIOSHOCK_ENCOUNTER_OUT",
    os.path.join(os.environ.get("TEMP", "."), "encounter_report.json"),
)

result = {"error": None}
try:
    import verify_encounter

    result = verify_encounter.main(SCHEMA, OUT)
except Exception as exc:  # noqa: BLE001
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
