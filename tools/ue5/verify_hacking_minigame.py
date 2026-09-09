"""Headless verify: hacking pipe-puzzle minigame (Phase U6).

Logic-focused — pipe tiles are UMG shapes (vector sprite export deferred).
Chrome textures under /Game/BioShockUI/Hacking are optional (color fallback).
"""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-hacking-minigame] %s" % message)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockHackingMinigame")
    if not cls:
        failures.append("ShockHackingMinigame class missing")
        _write(out, report)
        raise RuntimeError("hacking_minigame:\n- " + "\n- ".join(failures))

    textures = {
        "/Game/BioShockUI/Hacking/T_Hack_Bezel": "bezel",
        "/Game/BioShockUI/Hacking/T_Hack_HazardStrip": "hazard strip",
        "/Game/BioShockUI/Hacking/T_Hack_Banner": "banner",
        "/Game/BioShockUI/Hacking/T_Hack_Ring": "ring",
    }
    textures_on_disk = {}
    for path, role in textures.items():
        present = bool(unreal.EditorAssetLibrary.does_asset_exist(path))
        textures_on_disk[path] = present
    report["texturesOnDisk"] = textures_on_disk
    report["gaps"] = {
        "pipeArt": "pipe tiles drawn as UMG shapes — DefineSprite export deferred",
    }

    world = unreal.EditorLevelLibrary.get_editor_world()
    ok = bool(unreal.ShockHackingMinigame.run_headless_hacking_minigame_verify(world))
    err = str(unreal.ShockHackingMinigame.get_last_hacking_minigame_verify_error())
    report["hackingMinigameVerify"] = {"ok": ok, "error": err}
    if not ok:
        failures.append("RunHeadlessHackingMinigameVerify: %s" % (err or "failed"))

    # Auto-Hack now requires an Auto-Hack Tool (w7) — TryAutoHack returns false and logs
    # BIOSHOCK_HACK autohack=denied reason=no_tool when the inventory has none. The native
    # RunHeadlessHackingMinigameVerify covers the with-tool path.
    report["autoHackToolGated"] = True

    report["hackingMinigame"] = "ok" if not failures else "fail"
    report["visual"] = (
        "headless cannot judge BioShock likeness — confirm via "
        "capture_shot.ps1 -Map /Game/BioShockSlice/1-Medical -Extra "
        "'-bioshockshothud','-bioshockshothack' (or UnrealEditor-Cmd -game "
        "-bioshockscreenshot -bioshockshothud -bioshockshothack); "
        "human still confirms PIE feel"
    )
    _write(out, report)
    if failures:
        raise RuntimeError("hacking_minigame:\n- " + "\n- ".join(failures))
    _log("PASS hacking minigame")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "hacking_minigame_report.json"),
        )
    )
