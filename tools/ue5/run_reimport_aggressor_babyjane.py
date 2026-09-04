"""Force-reimport AggressorBabyJane (mesh + skeleton + animations) after the Z-up normalizer fix.

If BIOSHOCK_BABYJANE_EXPORT already has AggressorBabyJane.fbx + ue5_manifest.json, that tree is
used. Otherwise this exports into %TEMP%/bioshock-h4-aggressor-babyjane via:

  export-fbx <1-Medical.bsm> UAPW_AggressorBabyJane <out> --mesh Agg_BabyJane

Fingerprint reuse cannot keep the inverted asset (`NORMALIZER_AXIS_POLICY` + force).

Mesh-only recovery (skip the 457 animation FBX imports):

  set BIOSHOCK_MESH_ONLY=1

That writes a temp manifest copy with animations=[] under %TEMP% and imports against it; the
original export cache is not modified. Use after a crash left AggressorBabyJane.uasset bloated —
import_bioshock deletes the prior mesh/skeleton/physics before reimport.

    UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \\
        -script=tools\\ue5\\run_reimport_aggressor_babyjane.py -unattended -nopause -nosplash

Report: %TEMP%/bioshock_reimport_aggressor_babyjane.json
Then: setup_test_arena.py + run_test_arena_verify.py — uprightDelta must be strongly positive.
Health check: tools/ue5/verify_aggressor_babyjane_health.py (file size + load seconds).
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_BABYJANE_REIMPORT_OUT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock_reimport_aggressor_babyjane.json"),
)
DEFAULT_EXPORT = os.path.join(
    os.environ.get("TEMP", "."), "bioshock-h4-aggressor-babyjane"
)
CONTENT_ROOT = os.environ.get("BIOSHOCK_CHARACTER_CONTENT_ROOT", "/Game/BioShockCharacters")


def _repo_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def _game_root():
    override = os.environ.get("BIOSHOCK_REMASTERED_PATH")
    if override and os.path.isdir(os.path.join(override, "ContentBaked", "pc", "Maps")):
        return override
    return r"G:\SteamLibrary\steamapps\common\BioShock Remastered"


def _package_bsm():
    path = os.path.join(_game_root(), "ContentBaked", "pc", "Maps", "1-Medical.bsm")
    if not os.path.isfile(path):
        raise RuntimeError(
            "1-Medical.bsm not found at %s (set BIOSHOCK_REMASTERED_PATH)" % path
        )
    return path


def _export_ready(export_dir):
    manifest = os.path.join(export_dir, "ue5_manifest.json")
    mesh = os.path.join(export_dir, "AggressorBabyJane.fbx")
    return os.path.isfile(manifest) and os.path.isfile(mesh)


def _ensure_export(export_dir):
    if _export_ready(export_dir):
        return export_dir, False

    os.makedirs(export_dir, exist_ok=True)
    cli = os.path.join(_repo_root(), "src", "BioShockStudio.Cli")
    cmd = [
        "dotnet",
        "run",
        "--project",
        cli,
        "--",
        "export-fbx",
        _package_bsm(),
        "UAPW_AggressorBabyJane",
        export_dir,
        "--mesh",
        "Agg_BabyJane",
    ]
    subprocess.run(cmd, check=True, cwd=_repo_root())
    if not _export_ready(export_dir):
        raise RuntimeError(
            "export-fbx did not write AggressorBabyJane.fbx + ue5_manifest.json under %s"
            % export_dir
        )
    return export_dir, True


def _mesh_only_export(export_dir):
    """Copy mesh FBX + a manifest with animations=[] into a temp dir; leave the cache untouched."""
    out = os.path.join(
        os.environ.get("TEMP", "."), "bioshock-h6-aggressor-babyjane-mesh-only"
    )
    if os.path.isdir(out):
        shutil.rmtree(out)
    os.makedirs(out, exist_ok=True)

    shutil.copy2(
        os.path.join(export_dir, "AggressorBabyJane.fbx"),
        os.path.join(out, "AggressorBabyJane.fbx"),
    )
    textures_src = os.path.join(export_dir, "Textures")
    if os.path.isdir(textures_src):
        shutil.copytree(textures_src, os.path.join(out, "Textures"))

    with open(os.path.join(export_dir, "ue5_manifest.json"), "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
    for rig in manifest.get("rigs") or []:
        rig["animations"] = []
    with open(os.path.join(out, "ue5_manifest.json"), "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
    return out


def main():
    export = os.environ.get("BIOSHOCK_BABYJANE_EXPORT", DEFAULT_EXPORT)
    mesh_only = os.environ.get("BIOSHOCK_MESH_ONLY", "").strip().lower() in (
        "1",
        "true",
        "yes",
    )
    report = {
        "export": export,
        "content_root": CONTENT_ROOT,
        "exported": False,
        "mesh_only": mesh_only,
        "error": None,
    }

    export, did_export = _ensure_export(export)
    report["export"] = export
    report["exported"] = did_export

    if mesh_only:
        export = _mesh_only_export(export)
        report["export"] = export

    # Fingerprint reuse would keep the inverted / bloated mesh; this run must rebuild from FBX.
    os.environ["BIOSHOCK_FORCE_IMPORT"] = "1"

    import import_bioshock

    imported = import_bioshock.main(export, content_root=CONTENT_ROOT, reuse_existing=False)
    report["imported"] = sorted(imported.keys())
    report["import_report"] = getattr(import_bioshock.main, "last_report", None)
    if "AggressorBabyJane" not in imported:
        raise RuntimeError(
            "AggressorBabyJane missing from import result: %s" % report["imported"]
        )
    report["ok"] = True
    return report


if __name__ == "__main__":
    result = {"error": None}
    try:
        result = main()
    except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
        result["error"] = str(exc)
        result["traceback"] = traceback.format_exc()
        raise
    finally:
        os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
        with open(OUT, "w", encoding="utf-8") as handle:
            json.dump(result, handle, indent=2)
