"""Re-time animated lights already placed in a map: LightPeriod / 35 s per cycle, not the raw byte.

import_level._apply_light_effect used to pass LightPeriod straight through as seconds, so every
pulsing/flickering light in an existing import cycles ~35x too slowly (Medical's red quarantine
light, Light609 with LightPeriod 93, took 93 s per pulse instead of ~2.7 s). import_level now
converts via light_period_seconds(); this applies the same value to maps imported before that,
without a level re-import. Idempotent: it sets each period from the manifest, never scales the
current value.

Env:
  BIOSHOCK_LIGHT_MANIFEST  <map>.ue5-level.json (default: the project's 1-Medical export)
  BIOSHOCK_LIGHT_MAP       map to repair (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_LIGHT_DRY       "1" to report only

Pipeline: one-off -- import_level now applies light_period_seconds() on every import; this
re-times lights in maps imported before that.
"""
from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from import_level import KEY_TAG_PREFIX, light_period_seconds  # noqa: E402

MAP_PATH = os.environ.get("BIOSHOCK_LIGHT_MAP", "/Game/BioShockSlice/1-Medical")
DRY = os.environ.get("BIOSHOCK_LIGHT_DRY", "0") == "1"
OUT = os.path.join(os.environ.get("TEMP", "."), "repair_light_periods.json")


def main():
    manifest_path = os.environ.get("BIOSHOCK_LIGHT_MANIFEST") or os.path.join(
        os.path.dirname(unreal.Paths.get_project_file_path()),
        "Exports", "slice", "1-Medical", "1-Medical.ue5-level.json")
    with open(manifest_path, encoding="utf-8") as handle:
        lights = {light["key"]: light for light in json.load(handle).get("lights") or []}

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(MAP_PATH):
        raise RuntimeError("could not load %s" % MAP_PATH)

    report = {"map": MAP_PATH, "dryRun": DRY, "retimed": [], "unchanged": 0, "noManifestLight": []}
    effect_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockLightEffectComponent")
    for actor in unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors():
        component = actor.get_component_by_class(effect_cls) if effect_cls else None
        if component is None:
            continue
        key = next((str(tag)[len(KEY_TAG_PREFIX):] for tag in actor.tags
                    if str(tag).startswith(KEY_TAG_PREFIX)), None)
        light = lights.get(key)
        if light is None:
            report["noManifestLight"].append(actor.get_actor_label())
            continue
        want = max(light_period_seconds(light.get("period")), 0.1)
        have = float(component.get_editor_property("period_seconds"))
        if abs(have - want) < 1e-3:
            report["unchanged"] += 1
            continue
        report["retimed"].append({"actor": actor.get_actor_label(), "key": key,
                                  "lightPeriod": light.get("period"),
                                  "fromSeconds": round(have, 3), "toSeconds": round(want, 3)})
        if not DRY:
            actor.modify()
            component.modify()
            component.set_editor_property("period_seconds", want)

    if report["retimed"] and not DRY:
        if not level.save_current_level():
            raise RuntimeError("save_current_level failed")
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[light-periods] retimed=%d unchanged=%d noManifestLight=%d -> %s" % (
        len(report["retimed"]), report["unchanged"], len(report["noManifestLight"]), OUT))
    return report


if __name__ == "__main__":
    main()
