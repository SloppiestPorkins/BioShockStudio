"""Repair ambient cues and placed actors without rebuilding unrelated audio.

Pipeline: one-off -- a focused re-run of ambient audio; import_audio runs in every rebuild
(STEPS).
"""

from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_audio


def main(
    audio_dir=import_audio.DEFAULT_AUDIO_DIR,
    level_manifest_path=import_audio.DEFAULT_LEVEL_MANIFEST,
    map_path=import_audio.DEFAULT_MAP,
):
    manifest = json.load(
        open(os.path.join(audio_dir, "ue5_audio_manifest.json"), encoding="utf-8")
    )
    level_manifest = json.load(open(level_manifest_path, encoding="utf-8"))
    package = import_audio._safe_name(manifest.get("sourcePackage") or "Unknown")
    cue_folder = "/Game/BioShockAudio/%s/Cues" % package
    ambient_class = import_audio._ensure_ambient_sound_class()
    ambient_names = {
        name
        for actor in manifest.get("actors") or []
        if actor.get("className") in ("AmbientSound", "MusicBox")
        for name in actor.get("cues") or []
    }

    report = {
        "ambientCuesRepaired": 0,
        "ambientCuesMissing": [],
        "ambientActorsWired": 0,
        "ambientMissingSource": [],
        "ambientMissingCue": [],
        "ambientSpawnFailures": [],
    }
    cue_docs = {
        cue["name"]: cue
        for cue in manifest.get("cues") or []
        if cue["name"] in ambient_names
    }
    cue_assets = {}
    for name, cue in cue_docs.items():
        asset = unreal.load_asset(import_audio._asset_path(cue_folder, name))
        if asset is None:
            report["ambientCuesMissing"].append(name)
            continue
        import_audio._apply_cue_settings(asset, cue, True, ambient_class)
        cue_assets[name] = asset
        report["ambientCuesRepaired"] += 1

    import_audio._replace_sound_actors(
        manifest, level_manifest, cue_assets, map_path, report
    )
    out_path = os.path.join(
        os.environ.get("TEMP", "."), "bioshock_ambient_repair_report.json"
    )
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    # Missing cue assets are payload-backed skips already reported by import_audio;
    # they are not repair failures and no silent substitute is created.
    if report["ambientSpawnFailures"]:
        raise RuntimeError("ambient repair incomplete: %s" % out_path)
    unreal.log(
        "BIOSHOCK_AUDIO_REPAIR cues=%d actors=%d report=%s"
        % (
            report["ambientCuesRepaired"],
            report["ambientActorsWired"],
            out_path,
        )
    )
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
