"""Headless verify: radial menu + weapon select screen (Phase U3).

Requires Radial textures under /Game/BioShockUI/Radial (import_bioshock_ui.py).
Headless only — no visual likeness claim.
"""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-radial] %s" % message)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    radial_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockRadialMenu")
    select_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeaponSelectScreen")
    if not radial_cls:
        failures.append("ShockRadialMenu class missing")
    if not select_cls:
        failures.append("ShockWeaponSelectScreen class missing")
    if failures:
        _write(out, report)
        raise RuntimeError("radial:\n- " + "\n- ".join(failures))

    required = [
        "T_Radial_BrassRing",
        "T_Radial_Digit_0",
        "T_Radial_Digit_9",
    ]
    textures_on_disk = {}
    for name in required:
        path = "/Game/BioShockUI/Radial/%s" % name
        present = bool(unreal.EditorAssetLibrary.does_asset_exist(path))
        textures_on_disk[name] = present
        if not present:
            failures.append(
                "Radial texture missing %s — run import_bioshock_ui.py (staging in "
                "%%TEMP%%/bioshock-ui-radial-staging)" % path
            )
    report["texturesOnDisk"] = textures_on_disk

    world = unreal.EditorLevelLibrary.get_editor_world()
    ok_radial = bool(unreal.ShockRadialMenu.run_headless_radial_verify(world))
    err_radial = str(unreal.ShockRadialMenu.get_last_radial_verify_error())
    report["radialVerify"] = {"ok": ok_radial, "error": err_radial}
    if not ok_radial:
        failures.append("RunHeadlessRadialVerify: %s" % (err_radial or "failed"))

    ok_select = bool(unreal.ShockWeaponSelectScreen.run_headless_select_verify(world))
    err_select = str(unreal.ShockWeaponSelectScreen.get_last_select_verify_error())
    report["selectVerify"] = {"ok": ok_select, "error": err_select}
    if not ok_select:
        failures.append("RunHeadlessSelectVerify: %s" % (err_select or "failed"))

    report["radial"] = "ok" if not failures else "fail"
    report["visual"] = (
        "headless cannot judge BioShock likeness — confirm open radial via "
        "capture_shot.ps1 -Map /Game/BioShockSlice/1-Medical -Extra "
        "'-bioshockshothud','-bioshockshotradial' (human still confirms PIE feel)"
    )
    _write(out, report)
    if failures:
        raise RuntimeError("radial:\n- " + "\n- ".join(failures))
    _log("PASS radial")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "radial_report.json"),
        )
    )
