"""Give a live-view map copy the exposure the live renderer was calibrated under.

Baked BSP/prop light and zone ambient (unlit materials) were calibrated against the game on the
Medical slice copy, whose effective post-process is a manual exposure with bias 11 (measured on
PostProcessVolume_0, 6 Oct 2026). Other levels' base maps carry whatever their import left, so
this upserts one unbound, high-priority volume (tag BIOSHOCK_LIVE_PP) with the same exposure.
The Medical copy already has the slice's volumes and is left alone unless forced.

Env: BIOSHOCK_MAP (via live_paths), BIOSHOCK_PP_FORCE=1 to add the volume to 1-Medical too.

Run: python tools/ue5/ue_run.py tools/ue5/setup_live_postprocess.py

Pipeline: entry-point -- live-renderer map preparation.
"""
from __future__ import annotations

import os
import sys

import unreal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import live_paths  # noqa: E402

TAG = "BIOSHOCK_LIVE_PP"


def main():
    if live_paths.MAP == "1-Medical" and os.environ.get("BIOSHOCK_PP_FORCE") != "1":
        unreal.log("LIVE_PP skipped for 1-Medical (copy carries the slice's volumes)")
        return
    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    if not level.load_level(live_paths.live_map()):
        raise RuntimeError("could not load %s" % live_paths.live_map())
    ppv = next((a for a in actors.get_all_level_actors() if TAG in [str(t) for t in a.tags]), None)
    if ppv is None:
        ppv = actors.spawn_actor_from_class(unreal.PostProcessVolume, unreal.Vector(0, 0, 0))
        ppv.set_actor_label("live exposure")
        ppv.tags = [unreal.Name(TAG)]
    ppv.set_editor_property("unbound", True)
    ppv.set_editor_property("priority", 100.0)
    s = ppv.get_editor_property("settings")
    s.set_editor_property("override_auto_exposure_method", True)
    s.set_editor_property("auto_exposure_method", unreal.AutoExposureMethod.AEM_MANUAL)
    s.set_editor_property("override_auto_exposure_bias", True)
    s.set_editor_property("auto_exposure_bias", 11.0)
    ppv.set_editor_property("settings", s)
    level.save_current_level()
    unreal.log("LIVE_PP set on %s" % live_paths.live_map())


main()
