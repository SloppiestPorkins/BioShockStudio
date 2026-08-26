"""Headless driver: possess ShockPlayer and pin GameMode/PlayerStart on the Medical slice umap."""

import json
import os
import sys
import traceback

sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")

SCHEMA = os.environ.get(
    "BIOSHOCK_RUNTIME_SCHEMA",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json")
OUT = os.environ.get(
    "BIOSHOCK_POSSESS_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\possess_report.json")

result = {"error": None}
try:
    import verify_possess
    result = verify_possess.main(SCHEMA, OUT)
except Exception as exc:  # noqa: BLE001 -- the commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
