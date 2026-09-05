"""Headless verify: main menu + difficulty + save/load + loading screen (Phase U7)."""

from __future__ import annotations

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-frontend] %s" % message)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    classes = {
        "ShockMainMenuWidget": "/Script/BioShockRuntime.ShockMainMenuWidget",
        "ShockDifficultySelect": "/Script/BioShockRuntime.ShockDifficultySelect",
        "ShockSaveLoadMenu": "/Script/BioShockRuntime.ShockSaveLoadMenu",
        "ShockLoadingScreen": "/Script/BioShockRuntime.ShockLoadingScreen",
        "ShockSaveGame": "/Script/BioShockRuntime.ShockSaveGame",
        "ShockStubMenu": "/Script/BioShockRuntime.ShockStubMenu",
    }
    loaded = {}
    for name, path in classes.items():
        cls = unreal.load_class(None, path)
        loaded[name] = bool(cls)
        if not cls:
            failures.append("%s class missing" % name)
    report["classes"] = loaded
    if failures:
        _write(out, report)
        raise RuntimeError("frontend:\n- " + "\n- ".join(failures))

    textures = {
        "/Game/BioShockUI/Pause/T_Pause_Logo": "logo",
        "/Game/BioShockUI/Pause/T_Pause_ChevronUp": "chevron",
    }
    textures_on_disk = {}
    for path, role in textures.items():
        present = bool(unreal.EditorAssetLibrary.does_asset_exist(path))
        textures_on_disk[path] = present
        if not present:
            report.setdefault("textureGaps", []).append(
                "%s missing %s (text fallback OK)" % (role, path)
            )
    report["texturesOnDisk"] = textures_on_disk

    world = unreal.EditorLevelLibrary.get_editor_world()
    ok = bool(unreal.ShockMainMenuWidget.run_headless_frontend_verify(world))
    err = str(unreal.ShockMainMenuWidget.get_last_frontend_verify_error())
    report["frontendVerify"] = {"ok": ok, "error": err}
    if not ok:
        failures.append("RunHeadlessFrontendVerify: %s" % (err or "failed"))

    # Soft checks via CDOs / defaults.
    menu_cdo = unreal.get_default_object(
        unreal.load_class(None, classes["ShockMainMenuWidget"])
    )
    play_path = str(menu_cdo.get_resolved_play_level_path())
    report["firstLevel"] = play_path
    report["firstLevelChoice"] = (
        "/Game/BioShockSlice/1-Medical — spawn-ready PlayerStart + ShockGameMode; "
        "/Game/BioShockLevel/1-Welcome not used (no reliable PlayerStart in slice path)"
    )
    if "1-Medical" not in play_path.replace("\\", "/"):
        failures.append("first level is %s, want Medical slice" % play_path)

    report["stubs"] = {
        "options": "Not implemented panel",
        "credits": "Not implemented — CreditsContainer.swf text extract deferred",
        "directorsCommentary": "Not implemented panel",
        "museum": "Not implemented panel",
        "challengeRooms": "Not implemented panel",
        "planeIntro": "deferred (U7 table mention; not in wired flow)",
        "menuBackground": (
            "dark Deco gradient — no still plate in sharedlibrary; "
            "BinkMovies attractMovie/Bathy_BG are loops, not UMG plates"
        ),
    }
    report["frontend"] = "ok" if not failures else "fail"
    report["visual"] = (
        "headless cannot judge BioShock likeness — confirm via "
        "capture_shot.ps1 -Map /Game/BioShockUI/MainMenu "
        "(menu map is not paused)"
    )
    _write(out, report)
    if failures:
        raise RuntimeError("frontend:\n- " + "\n- ".join(failures))
    _log("PASS frontend")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "frontend_report.json"),
        )
    )
