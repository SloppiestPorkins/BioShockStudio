"""Headless driver: import starter-weapon viewmodels into /Game/BioShockWeapons.

Exports must already exist under BIOSHOCK_WEAPON_EXPORT_ROOT (default %TEMP%/bioshock-h3-weapons).
Produce them outside the editor with bioshock-tool / dotnet run, e.g.:

  export-firstperson Pistol <TEMP>/bioshock-h3-weapons/WP_Pistol --fbx --group=WP_Pistol
  export-firstperson Crossbow <TEMP>/.../WP_Crossbow --fbx --group=WP_Crossbow
  export-firstperson Chem <TEMP>/.../WP_ChemicalThrower --fbx --group=WP_ChemicalThrower
  export-fbx <fullpath-to-ShockGame.U> UAPW_WP_Shotgun <TEMP>/.../WP_Shotgun --mesh WP_ShotgunMesh

Wrench cannot use this path (StaticMesh) — see import_wrench_mesh.py / run_import_wrench_mesh.py.
"""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_WEAPON_IMPORT_OUT",
    os.path.join(os.environ.get("TEMP", "."), "weapon_mesh_import_report.json"),
)
EXPORT_ROOT = os.environ.get(
    "BIOSHOCK_WEAPON_EXPORT_ROOT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-h3-weapons"),
)

result = {"error": None}
try:
    import import_weapon_meshes

    result = import_weapon_meshes.main(EXPORT_ROOT, OUT)
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
