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

Animations only (keep the healthy mesh; re-bind clips to its Skeleton):

  set BIOSHOCK_ANIMS_ONLY=1
  set BIOSHOCK_ANIM_CHUNK=50
  set BIOSHOCK_ANIM_OFFSET=0

Chunk defaults to 50 when ANIMS_ONLY is set and CHUNK is unset. Raise OFFSET by CHUNK each run
until the report's anim_remaining is 0. Leftover AnimSequences from a prior Skeleton delete do not
re-bind by themselves — they must be re-imported against the in-memory Skeleton.

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


def _env_flag(name):
    return os.environ.get(name, "").strip().lower() in ("1", "true", "yes")


def _anim_slice(export_dir, offset, limit):
    """Temp export root with a sliced animation list; copy only the sliced FBX files."""
    out = os.path.join(
        os.environ.get("TEMP", "."),
        "bioshock-h7-aggressor-babyjane-anims-%d-%d" % (offset, limit),
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

    total = 0
    sliced_count = 0
    remaining = 0
    for rig in manifest.get("rigs") or []:
        all_anims = list(rig.get("animations") or [])
        total = len(all_anims)
        sliced = all_anims[offset : offset + limit]
        sliced_count = len(sliced)
        remaining = max(0, total - (offset + sliced_count))
        rig["animations"] = sliced
        for animation in sliced:
            rel = animation["file"].replace("/", os.sep)
            src = os.path.join(export_dir, rel)
            dst = os.path.join(out, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            if not os.path.isfile(src):
                raise RuntimeError("animation FBX missing: %s" % src)
            shutil.copy2(src, dst)

    with open(os.path.join(out, "ue5_manifest.json"), "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)

    return out, total, sliced_count, remaining


def _import_animations_only(export_dir, content_root, normalize_fbx=True,
                            fingerprint_export_dir=None):
    """Re-import animation FBXs onto the existing SkeletalMesh's Skeleton — do not touch the mesh.

    Old AnimSequences authored against a deleted Skeleton object at the same package path must be
    replaced; soft re-bind is not relied on (h6 secondary crash).

    `fingerprint_export_dir`: when set (full export root after the last chunk), stamp the complete
    fingerprint so reuse matches a non-sliced manifest. While chunking, leave the prior stamp alone.
    """
    import unreal
    import import_bioshock

    manifest_path = os.path.join(export_dir, "ue5_manifest.json")
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    imported = {}
    anim_ok = 0
    anim_fail = 0
    for rig in manifest.get("rigs") or []:
        destination = "%s/%s" % (content_root, rig["name"])
        mesh_path = "%s/%s" % (destination, rig["name"])
        if not unreal.EditorAssetLibrary.does_asset_exist(mesh_path):
            raise RuntimeError(
                "BIOSHOCK_ANIMS_ONLY requires existing mesh at %s" % mesh_path
            )
        mesh = unreal.EditorAssetLibrary.load_asset(mesh_path)
        if mesh is None or not isinstance(mesh, unreal.SkeletalMesh):
            raise RuntimeError("could not load SkeletalMesh %s" % mesh_path)
        skeleton = mesh.get_editor_property("skeleton")
        if skeleton is None:
            raise RuntimeError("mesh %s has no Skeleton" % mesh_path)
        # Ensure skeleton package is on disk before any AnimSequence replace_existing write.
        if not unreal.EditorAssetLibrary.save_loaded_asset(skeleton):
            raise RuntimeError("save_loaded_asset failed for Skeleton of %s" % rig["name"])

        for animation in rig.get("animations") or []:
            animation_file = os.path.join(export_dir, animation["file"].replace("/", os.sep))
            if normalize_fbx:
                animation_file = import_bioshock._normalize_fbx(
                    animation_file, export_dir
                )
            assets = import_bioshock._import(
                animation_file,
                "%s/Animations" % destination,
                import_bioshock._animation_options(skeleton, animation["frameRate"]),
            )
            sequence = next(
                (a for a in assets if isinstance(a, unreal.AnimSequence)), None
            )
            if sequence is None:
                anim_fail += 1
                import_bioshock._log("  FAILED to import %s" % animation["file"])
                continue
            tags = {
                "BioShockFrameRate": animation["frameRate"],
                "BioShockFrameCount": animation["frameCount"],
            }
            if animation.get("pairedWith"):
                tags["BioShockPairedWith"] = animation["pairedWith"]
            import_bioshock._tag(sequence, tags)
            notifies = import_bioshock._apply_notifies(
                sequence, animation.get("notifies") or []
            )
            unreal.EditorAssetLibrary.save_loaded_asset(sequence)
            anim_ok += 1
            import_bioshock._log(
                "  anim %s ok (notifies=%d)" % (animation["name"], notifies)
            )

        if fingerprint_export_dir:
            with open(
                os.path.join(fingerprint_export_dir, "ue5_manifest.json"),
                "r",
                encoding="utf-8",
            ) as handle:
                full_manifest = json.load(handle)
            full_rig = next(
                (r for r in full_manifest.get("rigs") or [] if r["name"] == rig["name"]),
                None,
            )
            if full_rig is not None:
                fingerprint = import_bioshock._rig_fingerprint(
                    full_manifest, full_rig, fingerprint_export_dir
                )
                import_bioshock._stamp_fingerprint(
                    mesh, full_rig, destination, fingerprint
                )
        imported[rig["name"]] = mesh

    return imported, anim_ok, anim_fail


def main():
    export = os.environ.get("BIOSHOCK_BABYJANE_EXPORT", DEFAULT_EXPORT)
    mesh_only = _env_flag("BIOSHOCK_MESH_ONLY")
    anims_only = _env_flag("BIOSHOCK_ANIMS_ONLY")
    if mesh_only and anims_only:
        raise RuntimeError("BIOSHOCK_MESH_ONLY and BIOSHOCK_ANIMS_ONLY are mutually exclusive")

    chunk_raw = os.environ.get("BIOSHOCK_ANIM_CHUNK", "").strip()
    offset_raw = os.environ.get("BIOSHOCK_ANIM_OFFSET", "0").strip()
    anim_offset = int(offset_raw or "0")
    anim_chunk = int(chunk_raw) if chunk_raw else 0

    report = {
        "export": export,
        "content_root": CONTENT_ROOT,
        "exported": False,
        "mesh_only": mesh_only,
        "anims_only": anims_only,
        "anim_offset": anim_offset,
        "anim_chunk": anim_chunk or None,
        "error": None,
    }

    export, did_export = _ensure_export(export)
    report["export"] = export
    report["exported"] = did_export
    full_export = export

    if mesh_only:
        export = _mesh_only_export(export)
        report["export"] = export
    elif anims_only:
        # Chunk only on the anims-only path — never delete/reimport the healthy mesh per slice.
        if anim_chunk <= 0:
            anim_chunk = 50
            report["anim_chunk"] = anim_chunk
        export, total, sliced, remaining = _anim_slice(export, anim_offset, anim_chunk)
        report["export"] = export
        report["anim_total"] = total
        report["anim_sliced"] = sliced
        report["anim_remaining"] = remaining
    elif anim_chunk > 0:
        raise RuntimeError(
            "BIOSHOCK_ANIM_CHUNK requires BIOSHOCK_ANIMS_ONLY=1 "
            "(refusing to delete/reimport the mesh once per chunk)"
        )

    os.environ["BIOSHOCK_FORCE_IMPORT"] = "1"

    import import_bioshock

    if anims_only:
        stamp_root = full_export if report.get("anim_remaining", 0) == 0 else None
        imported, anim_ok, anim_fail = _import_animations_only(
            export,
            CONTENT_ROOT,
            normalize_fbx=True,
            fingerprint_export_dir=stamp_root,
        )
        report["anim_ok"] = anim_ok
        report["anim_fail"] = anim_fail
        report["imported"] = sorted(imported.keys())
        report["import_report"] = {"mode": "anims_only", "fingerprint_stamped": stamp_root is not None}
        if anim_fail:
            raise RuntimeError(
                "animation import failures: ok=%d fail=%d" % (anim_ok, anim_fail)
            )
    else:
        imported = import_bioshock.main(
            export, content_root=CONTENT_ROOT, reuse_existing=False
        )
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
