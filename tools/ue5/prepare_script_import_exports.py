"""Prepare sidecars + lightweight ue5-level.json for script import (outside UE).

Writes under %TEMP%/bioshock-script-import-all-maps by default — never into the worktree.

  1. export-script-actions <map>  (reuse if present and non-trivial)
  2. Ue5Manifest-only level JSON via the TEMP helper (no mesh/OBJ/rig dumps)

Run this before UnrealEditor-Cmd ... run_import_scripts_all_maps.py.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

SHIPPED_MAPS = [
    "0-Lighthouse",
    "1-Medical",
    "1-Welcome",
    "2-Fisheries",
    "2-SubBay",
    "3-Arcadia",
    "3-Market",
    "4-Recreation",
    "5-Hephaestus",
    "5-Ryan",
    "6-Resi",
    "6-Slums",
    "7-BossFight",
    "7-Gauntlet",
    "7-Science",
    "Autoplay",
    "Entry",
    "museum",
    "ChallengeRoomCombat",
    "ChallengeRoomDecoy",
    "ChallengeRoomElectric",
]


def _repo_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def _default_root():
    return os.path.join(os.environ.get("TEMP", "."), "bioshock-script-import-all-maps")


def _manifest_only_dll_dir():
    return os.path.join(_default_root(), "manifest-only-tool")


def _sidecar_path(root, map_name):
    return os.path.join(root, "%s.script-actions.json" % map_name)


def _manifest_path(root, map_name):
    return os.path.join(root, map_name, "%s.ue5-level.json" % map_name)


def _reuse_sidecar(root, map_name):
    dest = _sidecar_path(root, map_name)
    if os.path.isfile(dest) and os.path.getsize(dest) > 50:
        return dest, "existing"
    temp = os.environ.get("TEMP", "")
    for prior in ("a21-importer-reverify", "a14-import-verify"):
        src = os.path.join(temp, prior, "%s.script-actions.json" % map_name)
        if os.path.isfile(src) and os.path.getsize(src) > 50:
            os.makedirs(root, exist_ok=True)
            # Hard-link or copy — keep prep root self-contained.
            import shutil

            shutil.copy2(src, dest)
            return dest, "copied:%s" % prior
    if map_name == "1-Medical":
        src = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical.script-actions.json"
        if os.path.isfile(src):
            import shutil

            os.makedirs(root, exist_ok=True)
            shutil.copy2(src, dest)
            return dest, "copied:slice"
    return dest, None


def _reuse_manifest(root, map_name):
    dest = _manifest_path(root, map_name)
    if os.path.isfile(dest) and os.path.getsize(dest) > 1000:
        return dest, "existing"
    temp = os.environ.get("TEMP", "")
    candidates = []
    for prior in ("a21-importer-reverify", "a14-import-verify"):
        candidates.append(
            os.path.join(temp, prior, map_name, map_name, "%s.ue5-level.json" % map_name)
        )
    if map_name == "1-Medical":
        candidates.append(
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json"
        )
    for src in candidates:
        if os.path.isfile(src) and os.path.getsize(src) > 1000:
            import shutil

            os.makedirs(os.path.dirname(dest), exist_ok=True)
            shutil.copy2(src, dest)
            return dest, "copied"
    return dest, None


def export_sidecar(root, map_name):
    dest, how = _reuse_sidecar(root, map_name)
    if how:
        return dest, how
    os.makedirs(root, exist_ok=True)
    cli = os.path.join(_repo_root(), "src", "BioShockStudio.Cli")
    subprocess.run(
        [
            "dotnet",
            "run",
            "--project",
            cli,
            "--",
            "export-script-actions",
            map_name,
            dest,
        ],
        check=True,
        cwd=_repo_root(),
    )
    return dest, "exported"


def export_manifest(root, map_name):
    dest, how = _reuse_manifest(root, map_name)
    if how:
        return dest, how
    tool_dir = _manifest_only_dll_dir()
    csproj = os.path.join(tool_dir, "ExportUe5ManifestOnly.csproj")
    if not os.path.isfile(csproj):
        raise RuntimeError(
            "missing TEMP manifest-only tool at %s — create ExportUe5ManifestOnly first" % tool_dir
        )
    out_dir = root  # tool writes <out>/<map>/<map>.ue5-level.json
    os.makedirs(out_dir, exist_ok=True)
    subprocess.run(
        ["dotnet", "run", "--project", csproj, "--", map_name, out_dir],
        check=True,
        cwd=tool_dir,
    )
    # Tool nests as out/<PackageName>/<PackageName>.ue5-level.json
    produced = os.path.join(out_dir, map_name, "%s.ue5-level.json" % map_name)
    if not os.path.isfile(produced):
        # Some Write paths nest one less level when out already ends with package name.
        alt = os.path.join(out_dir, "%s.ue5-level.json" % map_name)
        if os.path.isfile(alt):
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            import shutil

            shutil.move(alt, dest)
            produced = dest
    if not os.path.isfile(produced):
        raise RuntimeError("manifest-only export did not write %s" % produced)
    if produced != dest and os.path.isfile(produced):
        # Already at dest path from tool layout.
        pass
    return produced, "exported"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        default=_default_root(),
        help="prep directory (default %%TEMP%%/bioshock-script-import-all-maps)",
    )
    parser.add_argument(
        "--maps",
        default="",
        help="comma-separated subset (default: all 21)",
    )
    parser.add_argument(
        "--skip-medical-manifest",
        action="store_true",
        help="skip Medical level JSON (default Medical import is skipped anyway)",
    )
    args = parser.parse_args(argv)
    maps = [m.strip() for m in args.maps.split(",") if m.strip()] or list(SHIPPED_MAPS)
    os.makedirs(args.root, exist_ok=True)
    report = {"root": args.root, "maps": {}}
    for map_name in maps:
        print("=== prepare %s ===" % map_name, flush=True)
        entry = {}
        try:
            path, how = export_sidecar(args.root, map_name)
            entry["sidecar"] = path
            entry["sidecar_how"] = how
            if map_name == "1-Medical" and args.skip_medical_manifest:
                entry["manifest"] = None
                entry["manifest_how"] = "skipped"
            else:
                path, how = export_manifest(args.root, map_name)
                entry["manifest"] = path
                entry["manifest_how"] = how
            entry["ok"] = True
        except Exception as exc:  # noqa: BLE001
            entry["ok"] = False
            entry["error"] = str(exc)
            report["maps"][map_name] = entry
            out = os.path.join(args.root, "prepare_report.json")
            with open(out, "w", encoding="utf-8") as handle:
                json.dump(report, handle, indent=2)
            raise
        report["maps"][map_name] = entry
        print(json.dumps(entry, indent=2), flush=True)

    out = os.path.join(args.root, "prepare_report.json")
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    print("prepare ok -> %s" % out, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
