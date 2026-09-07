"""Headless driver for verify_animated_props.py."""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "animated_props_report.json"),
)

result = {"error": None}
try:
    import verify_animated_props

    result = verify_animated_props.main(OUT)
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
