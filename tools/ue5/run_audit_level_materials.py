"""Headless driver: audit 1-Medical material slots → tools/ue5/_reports/."""

import json
import os
import sys
import traceback

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.append(ROOT)

OUT = os.environ.get(
    "BIOSHOCK_AUDIT_OUT",
    os.path.join(ROOT, "_reports", "audit_1-Medical_materials.json"),
)

result = {"error": None}
try:
    import audit_level_materials
    result = audit_level_materials.main(report_path=OUT)
except Exception as exc:  # noqa: BLE001
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
