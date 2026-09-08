"""Headless driver for import_slice_enemies.py."""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

out = os.environ.get(
    "BIOSHOCK_ENEMIES_OUT",
    os.path.join(os.environ.get("TEMP", "."), "slice_enemies_import.json"),
)
result = {"error": None}
try:
    import import_slice_enemies

    result = import_slice_enemies.main()
except Exception as exc:  # noqa: BLE001
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise

os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
with open(out, "w", encoding="utf-8") as handle:
    json.dump(result, handle, indent=2)
