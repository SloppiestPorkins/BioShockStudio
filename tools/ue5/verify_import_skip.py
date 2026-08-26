"""Prove that the rig importer skips a current import and refuses a stale one.

The failure this exists to catch: a skip that keeps an existing mesh because the bone count and
animation *names* still match, after the export on disk has actually changed. Inventory-only
matching is how that ships. The importer stamps a fingerprint of the export; this script tampers
with that stamp and deletes an animation, and both must force a re-import.
"""

import json
import os
import time

import unreal

import import_bioshock
import verify_bioshock_import


def _log(message):
    unreal.log("[bioshock-skip] %s" % message)


def _disable_interchange():
    for flag in ("PNG", "Texture", "FBX", "OBJ"):
        unreal.SystemLibrary.execute_console_command(
            None, "Interchange.FeatureFlags.Import.%s 0" % flag)


def _import(export_directory, content_root):
    started = time.perf_counter()
    import_bioshock.main(export_directory, content_root=content_root)
    elapsed = time.perf_counter() - started
    report = dict(import_bioshock.main.last_report)
    report["elapsedSeconds"] = round(elapsed, 3)
    return report


def _first_mesh(export_directory, content_root):
    with open(os.path.join(export_directory, "ue5_manifest.json"), encoding="utf-8") as handle:
        manifest = json.load(handle)
    rig = manifest["rigs"][0]
    path = "%s/%s/%s" % (content_root, rig["name"], rig["name"])
    mesh = unreal.EditorAssetLibrary.load_asset(path)
    if mesh is None:
        raise RuntimeError("missing skeletal mesh %s after import" % path)
    return rig, mesh, path


def _break_fingerprint(mesh):
    unreal.EditorAssetLibrary.set_metadata_tag(mesh, import_bioshock.FINGERPRINT_TAG, "stale")
    unreal.EditorAssetLibrary.save_loaded_asset(mesh)


def _delete_one_animation(rig, content_root):
    folder = "%s/%s/Animations" % (content_root, rig["name"])
    expected = (rig.get("animations") or [{}])[0].get("name")
    if not expected:
        raise RuntimeError("manifest rig %s has no animations to delete" % rig["name"])
    for path in unreal.EditorAssetLibrary.list_assets(folder, recursive=False) or []:
        asset = unreal.EditorAssetLibrary.load_asset(path)
        if isinstance(asset, unreal.AnimSequence) and asset.get_name() == expected:
            if not unreal.EditorAssetLibrary.delete_asset(path):
                raise RuntimeError("could not delete animation %s" % path)
            return expected
    raise RuntimeError("animation %s was not on disk to delete" % expected)


def main(export_directory, report_path, content_root="/Game/BioShockSkipTest"):
    _disable_interchange()
    with open(os.path.join(export_directory, "ue5_manifest.json"), encoding="utf-8") as handle:
        rig_count = len(json.load(handle)["rigs"])

    result = {
        "export": export_directory,
        "contentRoot": content_root,
        "rigCount": rig_count,
        "error": None,
    }
    failures = []

    first = _import(export_directory, content_root)
    result["first"] = first
    _log("first import: %s" % first)

    second = _import(export_directory, content_root)
    result["second"] = second
    _log("second import: %s" % second)
    if second.get("reused") != rig_count:
        failures.append("second import reused %s, expected %d (skip did not fire)"
                        % (second.get("reused"), rig_count))

    rig, mesh, _mesh_path = _first_mesh(export_directory, content_root)
    _break_fingerprint(mesh)
    stale = _import(export_directory, content_root)
    result["afterFingerprintBreak"] = stale
    _log("after fingerprint break: %s" % stale)
    if stale.get("reused", rig_count) >= rig_count:
        failures.append("fingerprint mismatch still reused every rig; skip did not refuse stale")
    if stale.get("reused", 0) != rig_count - 1:
        failures.append("after breaking one fingerprint, reused %s, expected %d"
                        % (stale.get("reused"), rig_count - 1))

    restored = _import(export_directory, content_root)
    result["afterStaleRestored"] = restored
    if restored.get("reused") != rig_count:
        failures.append("after re-stamping, reused %s, expected %d"
                        % (restored.get("reused"), rig_count))

    deleted = _delete_one_animation(rig, content_root)
    result["deletedAnimation"] = deleted
    missing = _import(export_directory, content_root)
    result["afterAnimationDeleted"] = missing
    _log("after deleting %s: %s" % (deleted, missing))
    if missing.get("reused", rig_count) >= rig_count:
        failures.append("missing animation %s still reused every rig" % deleted)

    folder = "%s/%s/Animations" % (content_root, rig["name"])
    names = set()
    for path in unreal.EditorAssetLibrary.list_assets(folder, recursive=False) or []:
        asset = unreal.EditorAssetLibrary.load_asset(path)
        if isinstance(asset, unreal.AnimSequence):
            names.add(asset.get_name())
    if deleted not in names:
        failures.append("re-import did not restore deleted animation %s" % deleted)

    verify_bioshock_import.main(export_directory, content_root=content_root)

    result["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    if failures:
        raise RuntimeError("import skip verification failed:\n- " + "\n- ".join(failures))
    _log("PASS: skip reuses a current import and refuses a stale or incomplete one")
    return result


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SKIP_EXPORT"], os.environ["BIOSHOCK_SKIP_OUT"])
