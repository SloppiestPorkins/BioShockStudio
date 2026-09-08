"""Headless structural verification for the 1-Medical audio slice."""

from __future__ import annotations

import json
import os
import re
import subprocess

import unreal

import import_audio


UE_CMD = r"G:\Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
PROJECT = r"C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject"
GAME_URL = "/Game/BioShockSlice/1-Medical?game=/Script/BioShockRuntime.ShockGameMode"
GAME_OK = re.compile(
    r"BIOSHOCK_AUDIO_VERIFY_OK weapon=Pistol before=0 after=1 sound=(\S+)"
)


def _key(actor):
    for raw in actor.tags:
        value = str(raw)
        if value.startswith(import_audio.KEY_TAG_PREFIX):
            return value[len(import_audio.KEY_TAG_PREFIX) :]
    return None


def _expected_payload_names(manifest, audio_dir):
    names = set()
    for wave in manifest.get("waves") or []:
        relative = wave.get("file")
        if relative:
            source = os.path.join(audio_dir, relative.replace("/", os.sep))
            if os.path.isfile(source) and not import_audio._is_single_frame_mp3(source):
                names.add(wave["name"])
                continue
        localized = os.path.join(
            audio_dir, "waves", import_audio._safe_name(wave["name"]) + ".mp3"
        )
        if os.path.isfile(localized) and not import_audio._is_single_frame_mp3(localized):
            names.add(wave["name"])
    return names


def _run_game(log_path):
    if os.path.isfile(log_path):
        os.remove(log_path)
    command = [
        UE_CMD,
        PROJECT,
        GAME_URL,
        "-game",
        "-bioshockverifyaudio",
        "-unattended",
        "-nopause",
        "-nosplash",
        "-log",
        "-abslog=%s" % log_path,
    ]
    result = subprocess.run(command, timeout=600)
    text = ""
    if os.path.isfile(log_path):
        text = open(log_path, encoding="utf-8", errors="replace").read()
    match = GAME_OK.search(text)
    return result.returncode, match.group(1) if match else None


def main(
    out_path,
    audio_dir=import_audio.DEFAULT_AUDIO_DIR,
    level_manifest_path=import_audio.DEFAULT_LEVEL_MANIFEST,
    map_path=import_audio.DEFAULT_MAP,
):
    failures = []
    manifest_path = os.path.join(audio_dir, "ue5_audio_manifest.json")
    manifest = json.load(open(manifest_path, encoding="utf-8"))
    level_manifest = json.load(open(level_manifest_path, encoding="utf-8"))
    root = "/Game/BioShockAudio/" + import_audio._safe_name(manifest["sourcePackage"])
    wave_folder = root + "/Waves"
    cue_folder = root + "/Cues"

    expected_waves = _expected_payload_names(manifest, audio_dir)
    missing_waves = [
        name
        for name in sorted(expected_waves)
        if unreal.load_asset(import_audio._asset_path(wave_folder, name)) is None
    ]
    if missing_waves:
        failures.append("%d payload-backed SoundWaves missing" % len(missing_waves))

    required = {
        "Pistol": "pistol_fire",
        "TommyGun": "weapons_tommy_fire",
        "Shotgun": "weapons_shotgun_launch",
        "GrenadeLauncher": "weapons_GL_launch",
        "Wrench": "weapons_wrench_swipe",
    }
    weapon_report = {}
    for weapon, expected_cue in required.items():
        definition = unreal.ShockWeaponDefLibrary.resolve_weapon_def(unreal.Name(weapon))
        resolved = str(definition.get_editor_property("fire_sound_cue")) if definition else ""
        cue = unreal.load_asset(import_audio._asset_path(cue_folder, expected_cue))
        weapon_report[weapon] = {
            "resolved": resolved,
            "expected": expected_cue,
            "cueLoaded": cue is not None,
        }
        if resolved != expected_cue or cue is None:
            failures.append("%s fire sound unresolved (%s)" % (weapon, resolved))

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        failures.append("could not load audio-wired map")
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    ambient_by_key = {
        _key(actor): actor
        for actor in subsystem.get_all_level_actors()
        if isinstance(actor, unreal.AmbientSound) and _key(actor)
    }
    level_by_name = {
        entry.get("name"): entry
        for entry in level_manifest.get("actors") or []
        if entry.get("className") in ("AmbientSound", "MusicBox")
    }
    cue_names = {
        os.path.basename(path).split(".", 1)[0]
        for path in unreal.EditorAssetLibrary.list_assets(cue_folder, recursive=True)
    }
    expected_ambient = 0
    wired_ambient = 0
    ambient_missing = []
    for audio_actor in manifest.get("actors") or []:
        source = level_by_name.get(audio_actor.get("actor"))
        if source is None:
            continue
        if not any(import_audio._safe_name(name) in cue_names for name in audio_actor.get("cues") or []):
            continue
        expected_ambient += 1
        actor = ambient_by_key.get(source["key"])
        sound = None
        if actor:
            sound = actor.get_editor_property("audio_component").get_editor_property("sound")
        if sound:
            wired_ambient += 1
        else:
            ambient_missing.append(source["key"])
    if wired_ambient != expected_ambient:
        failures.append(
            "AmbientSound wiring %d/%d" % (wired_ambient, expected_ambient)
        )

    game_log = os.path.join(os.environ.get("TEMP", "."), "bioshock_audio_game.log")
    game_exit, game_sound = _run_game(game_log)
    if game_sound != "pistol_fire":
        failures.append("game audio component check missing (%s)" % game_sound)

    report = {
        "soundWaveExpected": len(expected_waves),
        "soundWaveMissing": missing_waves,
        "weapons": weapon_report,
        "ambientExpected": expected_ambient,
        "ambientWired": wired_ambient,
        "ambientMissing": ambient_missing,
        "gameExitCode": game_exit,
        "gameSound": game_sound,
        "gameLog": game_log,
        "failures": failures,
    }
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("audio verify:\n- " + "\n- ".join(failures))
    unreal.log(
        "BIOSHOCK_AUDIO_VERIFY waves=%d ambient=%d weapons=%d game=1"
        % (len(expected_waves), wired_ambient, len(required))
    )
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main(os.path.join(os.environ.get("TEMP", "."), "bioshock_audio_verify.json"))
