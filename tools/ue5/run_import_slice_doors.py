"""Headless driver: rebuild and save the playable slice's doors only."""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "slice_doors_report.json"),
)

try:
    import import_slice_doors

    result = import_slice_doors.main()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
except Exception as exc:  # noqa: BLE001 -- commandlet must preserve the failure in JSON
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(
            {"error": str(exc), "traceback": traceback.format_exc()},
            handle,
            indent=2,
        )
    raise
