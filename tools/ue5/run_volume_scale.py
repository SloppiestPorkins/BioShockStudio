"""Headless driver for repair_volume_scale.py."""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_VOLSCALE_OUT",
    os.path.join(os.environ.get("TEMP", "."), "repair_volume_scale.json"),
)

result = {"error": None}
try:
    import repair_volume_scale

    result = repair_volume_scale.main()
except Exception as exc:  # noqa: BLE001
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
