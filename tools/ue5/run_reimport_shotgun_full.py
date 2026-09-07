"""Force-reimport WP_Shotgun only from a recovered export tree.

Expects %TEMP%/recover-weapons/WP_Shotgun with real (non-stub) PNGs under Textures/
— produce them with recover_stripped_textures.py (or a TextureReader+bulk export), then:

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/run_reimport_shotgun_full.py ...

Fingerprint reuse would otherwise keep the old mesh; this driver always sets
BIOSHOCK_FORCE_IMPORT=1 after texture recovery.
"""
from __future__ import annotations

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_SHOTGUN_FULL_IMPORT_OUT",
    os.path.join(os.environ.get("TEMP", "."), "shotgun_full_reimport.json"),
)
EXPORT = os.environ.get(
    "BIOSHOCK_SHOTGUN_EXPORT",
    os.path.join(os.environ.get("TEMP", "."), "recover-weapons", "WP_Shotgun"),
)

# Always force: recovered PNGs change content without changing FBX mtime fingerprints.
os.environ["BIOSHOCK_FORCE_IMPORT"] = "1"

result = {"error": None}
try:
    import unreal

    import import_bioshock

    for flag in ("PNG", "Texture", "FBX", "OBJ"):
        unreal.SystemLibrary.execute_console_command(
            None, "Interchange.FeatureFlags.Import.%s 0" % flag
        )
    imported = import_bioshock.main(EXPORT, content_root="/Game/BioShockWeapons")
    result = {
        "export": EXPORT,
        "forceImport": True,
        "imported": {k: v.get_path_name() for k, v in (imported or {}).items()},
        "shotgun_full_reimport": "ok",
    }
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
except Exception as exc:  # noqa: BLE001
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
