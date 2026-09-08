"""Audit placed ambient audio from cue root to imported payload.

Run with UnrealEditor-Cmd while the editor is closed.  The JSON report is written
to ``BIOSHOCK_AMBIENT_AUDIT_OUT`` (TEMP by default).  A failing audit raises so a
headless run cannot mistake partial inspection for a pass.
"""

from __future__ import annotations

import json
import math
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_audio


OUT = os.environ.get(
    "BIOSHOCK_AMBIENT_AUDIT_OUT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock_ambient_audio_audit.json"),
)
SAMPLE_LIMIT = int(os.environ.get("BIOSHOCK_AMBIENT_AUDIT_LIMIT", "32"))


def _load_soft_wave(node):
    for field in ("sound_wave_asset_ptr", "sound_wave"):
        try:
            value = node.get_editor_property(field)
        except Exception:
            continue
        if value is None:
            continue
        if hasattr(value, "load_synchronous"):
            value = value.load_synchronous()
        if value is not None:
            return value
    return None


def _reachable_wave_players(cue):
    root = cue.get_editor_property("first_node")
    pending = [root] if root else []
    visited = set()
    players = []
    while pending:
        node = pending.pop()
        path = node.get_path_name()
        if path in visited:
            continue
        visited.add(path)
        if isinstance(node, unreal.SoundNodeWavePlayer):
            players.append(node)
        try:
            pending.extend(
                child
                for child in node.get_editor_property("child_nodes")
                if child is not None
            )
        except Exception:
            pass
    return root, players, visited


def _number(asset, name, default=0.0):
    try:
        return float(asset.get_editor_property(name))
    except Exception:
        return float(default)


def _wave_record(wave, source_sizes):
    name = wave.get_name()
    duration = _number(wave, "duration")
    channels = int(_number(wave, "num_channels"))
    sample_rate = int(_number(wave, "imported_sample_rate"))
    # RawPCMDataSize is not a reflected property in UE5.7.  Duration, channels,
    # sample rate, the source payload and the serialized asset are independent
    # non-stub evidence available to Python without adding a C++ audit shim.
    package_name = str(wave.get_outermost().get_name())
    relative = package_name.removeprefix("/Game/").replace("/", os.sep) + ".uasset"
    asset_file = os.path.join(import_audio.SLICE_PROJECT, "Content", relative)
    return {
        "name": name,
        "path": wave.get_path_name(),
        "duration": duration,
        "channels": channels,
        "sampleRate": sample_rate,
        "sourceBytes": int(source_sizes.get(name, 0)),
        "assetBytes": os.path.getsize(asset_file) if os.path.isfile(asset_file) else 0,
    }


def _source_sizes(manifest, audio_dir):
    sizes = {}
    for wave in manifest.get("waves") or []:
        candidates = []
        if wave.get("file"):
            candidates.append(os.path.join(audio_dir, wave["file"].replace("/", os.sep)))
        candidates.append(
            os.path.join(audio_dir, "waves", import_audio._safe_name(wave["name"]) + ".mp3")
        )
        for path in candidates:
            if os.path.isfile(path):
                sizes[wave["name"]] = os.path.getsize(path)
                break
    return sizes


def _cue_record(cue, source_sizes):
    root, players, reachable = _reachable_wave_players(cue)
    waves = [
        _wave_record(wave, source_sizes)
        for wave in (_load_soft_wave(player) for player in players)
        if wave is not None
    ]
    override = bool(cue.get_editor_property("override_attenuation"))
    settings = cue.get_editor_property("attenuation_overrides")
    extents = settings.get_editor_property("attenuation_shape_extents")
    inner = float(extents.x)
    falloff = float(settings.get_editor_property("falloff_distance"))
    sound_class = cue.get_editor_property("sound_class_object")
    parent_class = (
        sound_class.get_editor_property("parent_class") if sound_class else None
    )
    class_properties = (
        sound_class.get_editor_property("properties") if sound_class else None
    )
    virtualization_value = cue.get_editor_property("virtualization_mode")
    virtualization = str(virtualization_value)
    return {
        "name": cue.get_name(),
        "path": cue.get_path_name(),
        "root": root.get_class().get_name() if root else None,
        "reachableNodeCount": len(reachable),
        "reachableWavePlayerCount": len(players),
        "wavePlayersLooping": all(
            bool(player.get_editor_property("looping")) for player in players
        ),
        "waves": waves,
        "attenuationOverride": override,
        "innerRadius": inner,
        "falloffDistance": falloff,
        "outerRadius": inner + falloff,
        "soundClass": sound_class.get_name() if sound_class else None,
        "soundClassParent": parent_class.get_name() if parent_class else None,
        "soundClassVolume": (
            float(class_properties.get_editor_property("volume"))
            if class_properties
            else 0.0
        ),
        "cueVolume": float(cue.get_editor_property("volume_multiplier")),
        "virtualization": virtualization,
        "resumesAfterVirtualization": virtualization_value in (
            unreal.VirtualizationMode.RESTART,
            unreal.VirtualizationMode.PLAY_WHEN_SILENT,
            unreal.VirtualizationMode.SEEK_RESTART,
        ),
    }


def main(
    out_path=OUT,
    audio_dir=import_audio.DEFAULT_AUDIO_DIR,
    map_path=import_audio.DEFAULT_MAP,
):
    manifest_path = os.path.join(audio_dir, "ue5_audio_manifest.json")
    manifest = json.load(open(manifest_path, encoding="utf-8"))
    sizes = _source_sizes(manifest, audio_dir)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    actors = [
        actor
        for actor in subsystem.get_all_level_actors()
        if isinstance(actor, unreal.AmbientSound) and import_audio._source_key(actor)
    ]

    unique = {}
    active_components = 0
    for actor in actors:
        component = actor.get_editor_property("audio_component")
        if component.get_editor_property("auto_activate"):
            active_components += 1
        sound = component.get_editor_property("sound")
        if isinstance(sound, unreal.SoundCue):
            unique[sound.get_path_name()] = sound

    sampled = [
        _cue_record(unique[path], sizes)
        for path in sorted(unique)[:SAMPLE_LIMIT]
    ]
    failures = []
    if not sampled:
        failures.append("no placed ambient cues were sampled")
    if active_components != len(actors):
        failures.append(
            "AmbientSound auto-activate setting %d/%d"
            % (active_components, len(actors))
        )
    for cue in sampled:
        if not cue["root"] or cue["reachableWavePlayerCount"] < 1:
            failures.append("%s has no root-connected wave player" % cue["name"])
        if not cue["wavePlayersLooping"]:
            failures.append("%s is not a persistent ambient loop" % cue["name"])
        if not cue["waves"]:
            failures.append("%s has no loadable wave" % cue["name"])
        for wave in cue["waves"]:
            if (
                wave["duration"] <= 0.0
                or wave["channels"] <= 0
                or wave["sampleRate"] <= 0
                or wave["sourceBytes"] <= 44
                or wave["assetBytes"] <= 0
            ):
                failures.append("%s/%s has no real audio data" % (cue["name"], wave["name"]))
        if (
            not cue["attenuationOverride"]
            or not math.isfinite(cue["outerRadius"])
            or cue["outerRadius"] < import_audio.AMBIENT_MIN_OUTER_RADIUS
        ):
            failures.append("%s has invalid attenuation" % cue["name"])
        if cue["soundClass"] != import_audio.AMBIENT_SOUND_CLASS_NAME:
            failures.append("%s is not routed to Ambient" % cue["name"])
        if cue["soundClassParent"] != "Master":
            failures.append("%s Ambient class is not under Master" % cue["name"])
        if cue["soundClassVolume"] <= 0.0 or cue["cueVolume"] <= 0.0:
            failures.append("%s is routed at zero volume" % cue["name"])
        if not cue["resumesAfterVirtualization"]:
            failures.append("%s cannot resume after virtualization" % cue["name"])

        wave = cue["waves"][0] if cue["waves"] else {"name": "-", "duration": 0.0}
        unreal.log(
            "BIOSHOCK_AUDIO ambient cue=%s wave=%s dur=%.3f atten=%.0f class=%s"
            % (
                cue["name"],
                wave["name"],
                wave["duration"],
                cue["outerRadius"],
                cue["soundClass"] or "None",
            )
        )

    report = {
        "map": map_path,
        "ambientActors": len(actors),
        "autoActivateComponents": active_components,
        "uniqueCues": len(unique),
        "sampledCues": sampled,
        "sourcePayloads": len(sizes),
        "failures": failures,
    }
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ambient audio audit:\n- " + "\n- ".join(failures))
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
