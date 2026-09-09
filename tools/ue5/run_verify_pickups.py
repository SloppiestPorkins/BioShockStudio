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
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump({"error": str(exc), "traceback": traceback.format_exc()}, handle, indent=2)
    raise
