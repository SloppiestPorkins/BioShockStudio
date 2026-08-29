"""Headless driver: capture a 1-Medical shot → tools/ue5/_shots/ + report."""

import json
import os
import sys
import traceback

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.append(ROOT)

OUT = os.environ.get(
    "BIOSHOCK_SHOT_OUT",
    os.path.join(ROOT, "_reports", "capture_pie_shot.json"),
)

result = {"error": None}
try:
    import capture_pie_shot
    result = capture_pie_shot.main(report_path=OUT)
except Exception as exc:  # noqa: BLE001
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
