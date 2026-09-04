"""Headless driver for import_all_levels.py.

Unreal's -run=pythonscript does not reliably honour `if __name__ == '__main__'`, so the work runs
at import time and the report is written even when the run raises.

Environment:
  BIOSHOCK_IMPORT_MAPS              comma-separated map list (default: all 21 shipped)
  BIOSHOCK_IMPORT_FORCE=1           re-import even when BioShockKey count matches
  BIOSHOCK_IMPORT_LIGHTING_STOPGAP=0   disable dynamic fill (default on)
  BIOSHOCK_IMPORT_RIGS              none (default) | all | comma-separated mesh names
  BIOSHOCK_IMPORT_OUT               report JSON (default %TEMP%/bioshock_import_all_levels.json)
  BIOSHOCK_IMPORT_KEEP_EXPORTS=1    keep each map's %TEMP%/bioshock-import-all-levels/<map>/ tree
                                   (default: delete it after the map imports)
"""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_IMPORT_OUT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock_import_all_levels.json"),
)

result = {"error": None}
try:
    import import_all_levels

    result = import_all_levels.main(OUT)
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    result = {"error": str(exc), "traceback": traceback.format_exc()}
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
