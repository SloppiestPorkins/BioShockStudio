"""Headless verify: status menu + pause menu (Phase U4).

Requires Status/Pause textures under /Game/BioShockUI/{Status,Pause}.
Headless only — no visual likeness claim.
"""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-status-pause] %s" % message)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    status_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockStatusMenu")
    pause_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPauseMenu")
    if not status_cls:
        failures.append("ShockStatusMenu class missing")
    if not pause_cls:
        failures.append("ShockPauseMenu class missing")
    if failures:
        _write(out, report)
        raise RuntimeError("status-pause:\n- " + "\n- ".join(failures))

    required = {
        "/Game/BioShockUI/Status/T_Status_Tab_Map": "status tab",
        "/Game/BioShockUI/Status/T_Status_Help_Research": "status help",
        "/Game/BioShockUI/Pause/T_Pause_Logo": "pause logo",
        "/Game/BioShockUI/Pause/T_Pause_ChevronUp": "pause chevron",
    }
    textures_on_disk = {}
    for path, role in required.items():
        present = bool(unreal.EditorAssetLibrary.does_asset_exist(path))
        textures_on_disk[path] = present
        if not present:
            failures.append(
                "%s texture missing %s — run import_bioshock_ui.py" % (role, path)
            )
    report["texturesOnDisk"] = textures_on_disk

    world = unreal.EditorLevelLibrary.get_editor_world()
    ok_status = bool(unreal.ShockStatusMenu.run_headless_status_verify(world))
    err_status = str(unreal.ShockStatusMenu.get_last_status_verify_error())
    report["statusVerify"] = {"ok": ok_status, "error": err_status}
    if not ok_status:
        failures.append("RunHeadlessStatusVerify: %s" % (err_status or "failed"))

    ok_pause = bool(unreal.ShockPauseMenu.run_headless_pause_verify(world))
    err_pause = str(unreal.ShockPauseMenu.get_last_pause_verify_error())
    report["pauseVerify"] = {"ok": ok_pause, "error": err_pause}
    if not ok_pause:
        failures.append("RunHeadlessPauseVerify: %s" % (err_pause or "failed"))

    report["statusPause"] = "ok" if not failures else "fail"
    report["visual"] = (
        "headless cannot judge BioShock likeness — confirm via "
        "capture_shot.ps1 -Map /Game/BioShockSlice/1-Medical -Extra "
        "'-bioshockshothud','-bioshockshotstatus' and "
        "'-bioshockshothud','-bioshockshotpause' (human still confirms PIE feel)"
    )
    report["stubs"] = {
        "pauseSave": "log-only stub",
        "pauseLoad": "log-only stub",
        "pauseOptions": "log-only stub",
        "pauseMainMenu": "log-only stub",
        "mapTab": "placeholder level name + coords; plan render deferred",
        "messagesTab": "empty — diary collection not wired",
    }
    _write(out, report)
    if failures:
        raise RuntimeError("status-pause:\n- " + "\n- ".join(failures))
    _log("PASS status-pause")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "status_pause_report.json"),
        )
    )
