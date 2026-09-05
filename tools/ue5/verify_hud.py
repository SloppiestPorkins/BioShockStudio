"""Headless verify: player HUD widget shows live health + weapon ammo, updates on damage.

Requires imported Scaleform textures under /Game/BioShockUI/HUD (see import_bioshock_ui.py).
Visual likeness to BioShock's HUD is a human PIE / capture_shot.ps1 check — this script only
asserts construction, text updates, viewport add, and non-null meter-frame / digit textures.
"""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-hud] %s" % message)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    hud_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockHudWidget")
    if not hud_cls:
        failures.append("ShockHudWidget class missing")
        _write(out, report)
        raise RuntimeError("hud:\n- " + "\n- ".join(failures))

    required = [
        "T_Hud_MeterFrame",
        "T_Hud_FillMask",
        "T_Hud_BrassRing",
        "T_Hud_Digit_0",
        "T_Hud_Digit_9",
        "T_Hud_Icon_Cross",
        "T_Hud_Icon_Hypo",
    ]
    textures_on_disk = {}
    for name in required:
        path = "/Game/BioShockUI/HUD/%s" % name
        present = bool(unreal.EditorAssetLibrary.does_asset_exist(path))
        textures_on_disk[name] = present
        if not present:
            failures.append(
                "HUD texture missing %s — run import_bioshock_ui.py (staging in "
                "%%TEMP%%/bioshock-ui-hud-staging)" % path
            )
    report["texturesOnDisk"] = textures_on_disk

    # Stale h21 arcs must be gone.
    for stale in ("T_Hud_HealthArc", "T_Hud_EveArc", "T_Hud_MeterUnderlay"):
        if unreal.EditorAssetLibrary.does_asset_exist("/Game/BioShockUI/HUD/%s" % stale):
            failures.append("stale h21 texture still present: %s" % stale)

    world = unreal.EditorLevelLibrary.get_editor_world()
    ok = bool(unreal.ShockHudWidget.run_headless_hud_verify(world))
    err = str(unreal.ShockHudWidget.get_last_hud_verify_error())
    report["verify"] = {"ok": ok, "error": err}
    if not ok:
        failures.append("RunHeadlessHudVerify: %s" % (err or "failed"))

    report["hud"] = "ok" if not failures else "fail"
    report["visual"] = (
        "headless cannot judge BioShock likeness — confirm upper-left health/EVE meters via "
        "capture_shot.ps1 -Map /Game/BioShockSlice/1-Medical (human still confirms)"
    )
    _write(out, report)
    if failures:
        raise RuntimeError("hud:\n- " + "\n- ".join(failures))
    _log("PASS hud")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "hud_report.json"),
        )
    )
