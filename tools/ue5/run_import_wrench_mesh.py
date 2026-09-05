"""Headless driver: import Wrench StaticMesh viewmodel into /Game/BioShockWeapons/WP_Wrench.

Export first (outside the editor):

  bioshock-tool export-staticmesh ShockGame WP_WrenchMesh %TEMP%/bioshock-h22-wrench

Then:

  UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \\
      -script=<repo>/tools/ue5/run_import_wrench_mesh.py -unattended -nopause -nosplash
"""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_WRENCH_IMPORT_OUT",
    os.path.join(os.environ.get("TEMP", "."), "wrench_mesh_import_report.json"),
)
EXPORT_ROOT = os.environ.get(
    "BIOSHOCK_WRENCH_EXPORT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-h22-wrench"),
)

result = {"error": None}
try:
    import import_wrench_mesh

    result = import_wrench_mesh.main(EXPORT_ROOT, OUT)
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
