"""Headless driver: reimport WP_Shotgun textures from recovered bulk PNGs.

Prerequisite (host Python, editor closed):

  python tools/ue5/recover_stripped_textures.py \\
      --out %TEMP%/bioshock-shotgun-tex-fixed --group WP_Shotgun \\
      Shotgun_NoUpgrades_Diffuse Shotgun_NoUpgrades_Normal Shotgun_NoUpgrades_Specular

Then:

  UnrealEditor-Cmd <proj> -run=pythonscript \\
      -script=tools/ue5/run_reimport_shotgun_textures.py -unattended -nopause -nosplash

Report: %TEMP%/shotgun_texture_reimport_report.json
"""
from __future__ import annotations

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_SHOTGUN_TEX_IMPORT_OUT",
    os.path.join(os.environ.get("TEMP", "."), "shotgun_texture_reimport_report.json"),
)

result = {"error": None}
try:
    import reimport_shotgun_textures

    result = reimport_shotgun_textures.main(out=OUT)
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
