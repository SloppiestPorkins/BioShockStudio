"""Import starter-weapon viewmodel FBX exports into /Game/BioShockWeapons.

Same path as the TommyGun slice: export-firstperson (or export-fbx for Shotgun) into a directory,
then import_bioshock.main(export_dir, "/Game/BioShockWeapons").

Call from Unreal Python / -run=pythonscript after exports exist under TEMP (or BIOSHOCK_WEAPON_EXPORT_ROOT).

Wrench is not imported here: WP_WrenchMesh is a StaticMesh in ShockGame.U (no UAPW / SkeletalMesh);
import_bioshock only ingests skeletal rigs. Record that gap rather than substituting another asset.
"""

import json
import os

import unreal

import import_bioshock


CONTENT_ROOT = "/Game/BioShockWeapons"

# Export folder name → expected skeletal rig name in the manifest (attachment or sole rig).
_WEAPONS = (
    ("WP_Pistol", "WP_Pistol"),
    ("WP_Shotgun", "WP_Shotgun"),
    ("WP_ChemicalThrower", "WP_ChemicalThrower"),
    ("WP_Crossbow", "WP_Crossbow"),
    ("WP_TommyGun", "WP_TommyGun"),
    ("WP_GrenadeLauncher", "WP_GrenadeLauncher"),
)


def _log(message):
    unreal.log("[bioshock-weapon-import] %s" % message)


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _disable_interchange():
    for flag in ("PNG", "Texture", "FBX", "OBJ"):
        unreal.SystemLibrary.execute_console_command(
            None, "Interchange.FeatureFlags.Import.%s 0" % flag)


def main(export_root=None, out=None):
    export_root = export_root or os.environ.get(
        "BIOSHOCK_WEAPON_EXPORT_ROOT",
        os.path.join(os.environ.get("TEMP", "."), "bioshock-h3-weapons"),
    )
    out = out or os.environ.get(
        "BIOSHOCK_WEAPON_IMPORT_OUT",
        os.path.join(os.environ.get("TEMP", "."), "weapon_mesh_import_report.json"),
    )

    report = {
        "exportRoot": export_root,
        "contentRoot": CONTENT_ROOT,
        "imported": {},
        "skipped": [],
        "failures": [],
        "wrench": (
            "not imported — WP_WrenchMesh is StaticMesh in ShockGame.U "
            "(no AnimationPackageWrapper / SkeletalMesh); import_bioshock cannot ingest it"
        ),
    }
    failures = report["failures"]

    _disable_interchange()

    if not os.path.isdir(export_root):
        failures.append("export root missing: %s" % export_root)
        _write(out, report)
        raise RuntimeError("weapon-import:\n- " + "\n- ".join(failures))

    for folder, rig_name in _WEAPONS:
        export_dir = os.path.join(export_root, folder)
        manifest = os.path.join(export_dir, "ue5_manifest.json")
        if not os.path.isfile(manifest):
            # Also accept TEMP layout from run_weapon_pipeline (Pistol not WP_Pistol).
            alt = os.path.join(export_root, folder.replace("WP_", ""), "ue5_manifest.json")
            if os.path.isfile(alt):
                export_dir = os.path.dirname(alt)
                manifest = alt
            else:
                report["skipped"].append("%s (no ue5_manifest.json under %s)" % (folder, export_dir))
                continue

        _log("importing %s from %s" % (rig_name, export_dir))
        try:
            imported = import_bioshock.main(export_dir, content_root=CONTENT_ROOT)
        except Exception as exc:  # noqa: BLE001
            failures.append("%s import raised: %s" % (rig_name, exc))
            continue

        if not imported:
            failures.append("%s imported no skeletal meshes" % rig_name)
            continue

        paths = {name: mesh.get_path_name() for name, mesh in imported.items()}
        report["imported"][rig_name] = paths
        if rig_name not in imported:
            # First-person exports also bring NEWPlayerHands; weapon must still be present.
            failures.append(
                "%s missing from import result (got %s)" % (rig_name, sorted(imported.keys()))
            )
        else:
            _log("  %s -> %s" % (rig_name, paths[rig_name]))

    report["errorCount"] = len(failures)
    report["weapon_import"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("weapon-import (%d errors):\n- " % len(failures) + "\n- ".join(failures))
    _log("Success - %d weapon folder(s) imported" % len(report["imported"]))
    return report


if __name__ == "__main__":
    main()
