"""Headless commandlet driver for verify_pickups.py."""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "pickups_report.json"),
)

try:
    import verify_pickups

    verify_pickups.main(OUT)
except Exception as exc:  # noqa: BLE001
    # main() may already have written a full report to OUT before raising --
    # merge the error/traceback into it instead of clobbering that data (w19 fix).
    merged = {}
    if os.path.isfile(OUT):
        try:
            with open(OUT, "r", encoding="utf-8") as existing:
                merged = json.load(existing)
        except Exception:  # noqa: BLE001 -- fall back to a fresh dict on unreadable JSON
            merged = {}
    merged["error"] = str(exc)
    merged["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(merged, handle, indent=2)
    raise
