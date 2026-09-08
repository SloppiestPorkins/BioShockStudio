"""Import BioShock audio payloads/cues and replace placed sound placeholders.

Run after ``bioshock-tool export-audio 1-Medical <audio-dir>`` and after the
level import. The importer owns ``/Game/BioShockAudio/<package>`` and is
idempotent: existing immutable waves are reused, generated cues are rebuilt, and a source
actor key always resolves to one AmbientSound actor.

Only payloads named by ``wave.file`` are imported. Located-but-not-exported
native/streamed samples remain explicit skips; no silent substitute is made.
"""

from __future__ import annotations

import json
import os
import re

import unreal


SLICE_PROJECT = r"C:\Users\Jack\Documents\BioShockUE5"
DEFAULT_AUDIO_DIR = os.path.join(
    SLICE_PROJECT, "Exports", "slice", "1-Medical", "Audio"
)
DEFAULT_LEVEL_MANIFEST = os.path.join(
    SLICE_PROJECT, "Exports", "slice", "1-Medical", "1-Medical.ue5-level.json"
)
DEFAULT_MAP = "/Game/BioShockSlice/1-Medical"
SUPPORTED_VERSION = 1
KEY_TAG_PREFIX = "BioShockKey="


def _safe_name(value):
    result = re.sub(r"[^A-Za-z0-9_]", "_", str(value))
    if not result:
        return "Unnamed"
    if result[0].isdigit():
        result = "_" + result
    return result


def _asset_path(folder, name):
    safe = _safe_name(name)
    return "%s/%s.%s" % (folder, safe, safe)


def _is_single_frame_mp3(path):
    """True only for a valid MPEG Layer III first frame with no second frame.

    UE5.7's importer rejects the two shipped 208-byte ambience payloads with its own
    ``a one-frame stream`` diagnosis. Keep them explicit rather than generating import errors.
    """
    data = open(path, "rb").read()
    if len(data) < 8:
        return False
    header = int.from_bytes(data[:4], "big")
    if (header & 0xFFE00000) != 0xFFE00000:
        return False
    version_bits = (header >> 19) & 0x3
    layer_bits = (header >> 17) & 0x3
    bitrate_index = (header >> 12) & 0xF
    sample_index = (header >> 10) & 0x3
    padding = (header >> 9) & 0x1
    if version_bits == 1 or layer_bits != 1 or bitrate_index in (0, 15) or sample_index == 3:
        return False
    mpeg1_rates = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320]
    mpeg2_rates = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160]
    sample_rates = [44100, 48000, 32000]
    if version_bits == 3:
        bitrate = mpeg1_rates[bitrate_index]
        sample_rate = sample_rates[sample_index]
        frame_bytes = (144000 * bitrate) // sample_rate + padding
    else:
        bitrate = mpeg2_rates[bitrate_index]
        divisor = 2 if version_bits == 2 else 4
        sample_rate = sample_rates[sample_index] // divisor
        frame_bytes = (72000 * bitrate) // sample_rate + padding
    return frame_bytes >= len(data)


def _ensure_folder(path):
    if not unreal.EditorAssetLibrary.does_directory_exist(path):
        if not unreal.EditorAssetLibrary.make_directory(path):
            raise RuntimeError("could not create content folder %s" % path)


def _source_key(actor):
    for raw in actor.tags:
        value = str(raw)
        if value.startswith(KEY_TAG_PREFIX):
            return value[len(KEY_TAG_PREFIX) :]
    return None


def _import_waves(manifest, manifest_dir, wave_folder, report):
    tasks = []
    names_by_task = {}
    imported = {}
    for wave in manifest.get("waves") or []:
        relative = wave.get("file")
        if not relative:
            # export_slice_audio.ps1 materializes the English `_int` package here. The locator
            # still truthfully describes it as LocalisedMap; this exact-name file is additional
            # payload availability, not a rewritten decode claim.
            materialized = os.path.join(
                manifest_dir, "waves", _safe_name(wave["name"]) + ".mp3"
            )
            if os.path.isfile(materialized):
                relative = os.path.relpath(materialized, manifest_dir)
            else:
                report["wavesSkippedNoPayload"] += 1
                continue
        source = os.path.normpath(os.path.join(manifest_dir, relative.replace("/", os.sep)))
        if not os.path.isfile(source):
            report["missingPayloads"].append({"wave": wave.get("name"), "file": source})
            continue
        if source.lower().endswith(".mp3") and _is_single_frame_mp3(source):
            report["singleFramePayloads"].append(
                {"wave": wave.get("name"), "file": source}
            )
            continue
        existing = unreal.load_asset(_asset_path(wave_folder, wave["name"]))
        if existing is not None:
            imported[wave["name"]] = existing
            continue
        task = unreal.AssetImportTask()
        task.set_editor_property("filename", source)
        task.set_editor_property("destination_path", wave_folder)
        task.set_editor_property("destination_name", _safe_name(wave["name"]))
        task.set_editor_property("automated", True)
        task.set_editor_property("replace_existing", True)
        task.set_editor_property("save", False)
        tasks.append(task)
        names_by_task[id(task)] = wave["name"]

    if tasks:
        unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks(tasks)

    for task in tasks:
        expected = _asset_path(wave_folder, names_by_task[id(task)])
        asset = unreal.load_asset(expected)
        if asset is None:
            report["waveImportFailures"].append(names_by_task[id(task)])
            continue
        imported[names_by_task[id(task)]] = asset
    report["wavesImported"] = len(imported)
    return imported


def _is_looping(cue):
    for field in ("monoloop", "polyloopRange"):
        value = cue.get(field)
        if value and (float(value.get("min", -1)) >= 0 or float(value.get("max", -1)) >= 0):
            return True
    return False


def _apply_cue_settings(asset, cue, looping):
    volume = cue.get("volume", 100)
    pitch = cue.get("pitch", 1.0)
    asset.set_editor_property("volume_multiplier", max(0.0, float(volume) / 100.0))
    asset.set_editor_property("pitch_multiplier", max(0.01, float(pitch)))

    is_2d = cue.get("is2DPositional") is True
    outer = float(cue.get("outerRadius", 3000.0))
    inner = float(cue.get("innerRadius", 0.0))
    if not is_2d and outer > 0.0:
        asset.set_editor_property("override_attenuation", True)
        settings = asset.get_editor_property("attenuation_overrides")
        settings.set_editor_property("attenuation_shape", unreal.AttenuationShape.SPHERE)
        settings.set_editor_property(
            "attenuation_shape_extents", unreal.Vector(max(0.0, inner), 0.0, 0.0)
        )
        settings.set_editor_property("falloff_distance", max(1.0, outer - inner))
        asset.set_editor_property("attenuation_overrides", settings)

    asset.set_editor_property("override_concurrency", True)
    concurrency = asset.get_editor_property("concurrency_overrides")
    concurrency.set_editor_property(
        "max_count", max(1, int(cue.get("loopSoundLimit") or (8 if looping else 16)))
    )
    asset.set_editor_property("concurrency_overrides", concurrency)

    if looping:
        try:
            for node in asset.get_editor_property("all_nodes"):
                if isinstance(node, unreal.SoundNodeWavePlayer):
                    node.set_editor_property("looping", True)
        except Exception:
            # The factory graph still imports and plays; verification reports this approximation.
            pass

    asset.modify()
    unreal.EditorAssetLibrary.save_loaded_asset(asset, False)


def _create_cue(cue_name, cue, waves, cue_folder, report, suffix=None):
    generated_name = cue_name if suffix is None else "%s__%s" % (cue_name, suffix)
    alternatives = cue.get("alternatives") or []
    if suffix is not None:
        alternatives = [
            alt for alt in alternatives if alt.get("surfaceType") == suffix
        ]
    wave_assets = []
    seen = set()
    for alt in alternatives:
        wave_name = alt.get("wave")
        if wave_name in waves and wave_name not in seen:
            wave_assets.append(waves[wave_name])
            seen.add(wave_name)
    if not wave_assets:
        return None
    # USoundNodeRandom::MAX_ALLOWED_CHILD_NODES is 32 in UE5.7. Surface-specific
    # footstep derivatives stay below it; retain/report the engine limit for broader cues.
    if len(wave_assets) > 32:
        report["cueAlternativesTruncated"].append(
            {"cue": generated_name if suffix is not None else cue_name,
             "available": len(wave_assets), "imported": 32}
        )
        wave_assets = wave_assets[:32]

    safe = _safe_name(generated_name)
    object_path = _asset_path(cue_folder, safe)
    if unreal.EditorAssetLibrary.does_asset_exist(object_path):
        unreal.EditorAssetLibrary.delete_asset(object_path)

    factory = unreal.SoundCueFactoryNew()
    factory.set_editor_property("initial_sound_waves", wave_assets)
    asset = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
        safe, cue_folder, unreal.SoundCue, factory
    )
    if asset is None:
        report["cueFailures"].append(generated_name)
        return None
    _apply_cue_settings(asset, cue, _is_looping(cue))
    return asset


def _import_cues(manifest, waves, cue_folder, event_folder, report):
    cue_assets = {}
    cue_docs = {}
    for cue in manifest.get("cues") or []:
        name = cue["name"]
        cue_docs[name] = cue
        asset = _create_cue(name, cue, waves, cue_folder, report)
        if asset:
            cue_assets[name] = asset
            report["cuesImported"] += 1

        if "footstep" in name.lower():
            surfaces = sorted(
                {
                    alt.get("surfaceType")
                    for alt in cue.get("alternatives") or []
                    if alt.get("surfaceType")
                }
            )
            for surface in surfaces:
                if _create_cue(name, cue, waves, cue_folder, report, surface):
                    report["surfaceCuesImported"] += 1

    # Runtime aliases preserve the load-bearing SourceClassName + Event key. Where shipped
    # conditions offer several responses, choose the first payload-backed response and report
    # that approximation instead of pretending FilteredState/LevelContext selection is decoded.
    event_choices = {}
    for event in manifest.get("events") or []:
        key = "%s__%s" % (event["sourceClassName"], event["event"])
        choices = event_choices.setdefault(key, [])
        for cue_name in event.get("cues") or []:
            if cue_name not in choices:
                choices.append(cue_name)

    for key, choices in event_choices.items():
        chosen = next((name for name in choices if name in cue_assets), None)
        if chosen is None:
            report["eventAliasesSkipped"] += 1
            continue
        source_doc = cue_docs[chosen]
        alias = _create_cue(key, source_doc, waves, event_folder, report)
        if alias:
            report["eventAliasesImported"] += 1
            if len(choices) > 1:
                report["eventAliasesApproximated"] += 1
    return cue_assets


def _replace_sound_actors(manifest, level_manifest, cue_assets, map_path, report):
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    existing = {}
    for actor in subsystem.get_all_level_actors():
        key = _source_key(actor)
        if key:
            existing[key] = actor

    source_entries = {
        entry.get("name"): entry
        for entry in level_manifest.get("actors") or []
        if entry.get("className") in ("AmbientSound", "MusicBox")
    }
    for audio_actor in manifest.get("actors") or []:
        if audio_actor.get("className") not in ("AmbientSound", "MusicBox"):
            continue
        source = source_entries.get(audio_actor.get("actor"))
        if source is None:
            report["ambientMissingSource"].append(audio_actor.get("actor"))
            continue
        cue = next(
            (cue_assets.get(name) for name in audio_actor.get("cues") or [] if name in cue_assets),
            None,
        )
        if cue is None:
            report["ambientMissingCue"].append(audio_actor.get("actor"))
            continue

        key = source["key"]
        previous = existing.get(key)
        if previous:
            transform = previous.get_actor_transform()
            tags = list(previous.tags)
            label = previous.get_actor_label()
            if isinstance(previous, unreal.AmbientSound):
                actor = previous
            else:
                subsystem.destroy_actor(previous)
                actor = subsystem.spawn_actor_from_class(
                    unreal.AmbientSound, transform.translation, transform.rotation.rotator()
                )
                actor.set_actor_scale3d(transform.scale3d)
        else:
            location = source.get("location") or [0.0, 0.0, 0.0]
            actor = subsystem.spawn_actor_from_class(
                unreal.AmbientSound, unreal.Vector(*location)
            )
            tags = [unreal.Name(KEY_TAG_PREFIX + key)]
            label = source.get("label") or source.get("name") or key

        if actor is None:
            report["ambientSpawnFailures"].append(key)
            continue
        actor.set_actor_label(label)
        sample = next(
            (
                alt.get("wave")
                for cue_name in audio_actor.get("cues") or []
                for alt in next(
                    (
                        c.get("alternatives") or []
                        for c in manifest.get("cues") or []
                        if c.get("name") == cue_name
                    ),
                    [],
                )
                if alt.get("wave")
            ),
            "",
        )
        tags = [
            tag
            for tag in tags
            if not str(tag).startswith(("BioShockAudioCue=", "BioShockAudioSample="))
        ]
        tags.extend(
            [
                unreal.Name("BioShockAudioCue=" + cue.get_name()),
                unreal.Name("BioShockAudioSample=" + sample),
            ]
        )
        actor.tags = tags
        component = actor.get_editor_property("audio_component")
        component.set_editor_property("sound", cue)
        component.set_editor_property("auto_activate", True)
        component.set_editor_property("is_ui_sound", False)
        report["ambientActorsWired"] += 1

    if not level.save_current_level():
        raise RuntimeError("could not save audio-wired level %s" % map_path)


def main(
    audio_dir=DEFAULT_AUDIO_DIR,
    level_manifest_path=DEFAULT_LEVEL_MANIFEST,
    map_path=DEFAULT_MAP,
):
    manifest_path = os.path.join(audio_dir, "ue5_audio_manifest.json")
    if not os.path.isfile(manifest_path):
        raise RuntimeError(
            "audio manifest missing: %s (run export_slice_audio.ps1 first)" % manifest_path
        )
    if not os.path.isfile(level_manifest_path):
        raise RuntimeError("level manifest missing: %s" % level_manifest_path)

    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
    with open(level_manifest_path, "r", encoding="utf-8") as handle:
        level_manifest = json.load(handle)
    if int(manifest.get("version", -1)) != SUPPORTED_VERSION:
        raise RuntimeError("unsupported audio manifest version %r" % manifest.get("version"))

    package = _safe_name(manifest.get("sourcePackage") or "Unknown")
    root = "/Game/BioShockAudio/" + package
    wave_folder = root + "/Waves"
    cue_folder = root + "/Cues"
    event_folder = root + "/Events"
    for folder in (root, wave_folder, cue_folder, event_folder):
        _ensure_folder(folder)

    report = {
        "manifest": manifest_path,
        "root": root,
        "wavesImported": 0,
        "wavesSkippedNoPayload": 0,
        "waveImportFailures": [],
        "missingPayloads": [],
        "singleFramePayloads": [],
        "cuesImported": 0,
        "surfaceCuesImported": 0,
        "cueFailures": [],
        "cueAlternativesTruncated": [],
        "eventAliasesImported": 0,
        "eventAliasesSkipped": 0,
        "eventAliasesApproximated": 0,
        "ambientActorsWired": 0,
        "ambientMissingSource": [],
        "ambientMissingCue": [],
        "ambientSpawnFailures": [],
    }
    waves = _import_waves(manifest, audio_dir, wave_folder, report)
    cues = _import_cues(manifest, waves, cue_folder, event_folder, report)
    _replace_sound_actors(manifest, level_manifest, cues, map_path, report)
    unreal.EditorAssetLibrary.save_directory(root, only_if_is_dirty=True, recursive=True)
    report_path = os.path.join(
        os.environ.get("TEMP", "."), "bioshock_audio_import_report.json"
    )
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log(
        "BIOSHOCK_AUDIO_IMPORT waves=%d cues=%d ambient=%d skipped_no_payload=%d report=%s"
        % (
            report["wavesImported"],
            report["cuesImported"],
            report["ambientActorsWired"],
            report["wavesSkippedNoPayload"],
            report_path,
        )
    )
    return report


if __name__ == "__main__":
    main()
