"""Place 1-Medical's `InPlayerViewTrigger` instances into the playable slice.

`InPlayerViewTrigger` never had a dedicated actor class wired -- same "other decoded-but-unplaced
classes" fallback as switches, so all 14 instances in 1-Medical imported as inert TargetPoints.
Checked 30 Sept 2026: every single one is a real `TriggeredBy` target for a real Script
(`SteinmanIntro`, `Quarantine_PistolIntro`, `Ghost_TwoTwo`, `EternalFlameBlast`,
`QuarSwitch_UnlockMaintenanceHall`, `TrainingHackTurret`, ...) whose `scriptMessageClass` resolves
to UE2's base `Message` class -- which `UShockScriptRunner::MatchesMessageClass` accepts from any
message class, so only the label needs to match. Before this fix none of these scripts could ever
fire: several of Medical's scripted narrative/tutorial beats (Steinman's intro, the first ghost
sequence, the hacking tutorial, ...) were entirely dead.

`enabled` is deliberately NOT read from the manifest: this exporter only serializes properties
that differ from the class default, so a bare bool's presence could mean either "explicitly turned
on" or "explicitly turned off" depending on which way the *compiled* class default runs, and there
is no `ActionEnableOrDisableInPlayerViewTrigger`-style action anywhere in the plugin that could
ever turn one on later if it started disabled -- so importing every instance active by default is
both the safer and the more narratively plausible reading. `TriggerWhenNotSeen` and
`MinimumDistance` don't have that ambiguity (a plain bool/float, not a toggle whose default
direction matters) and are read directly.

Env: BIOSHOCK_LEVEL_JSON overrides the manifest path.
"""
from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_level  # noqa: E402

SLICE_MAP = "/Game/BioShockSlice/1-Medical"
DEFAULT_MANIFEST = r"C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/1-Medical.ue5-level.json"
OUT = os.path.join(os.environ.get("TEMP", "."), "import_slice_in_player_view_triggers.json")

TRIGGER_CLASS_NAME = "InPlayerViewTrigger"


def _prop_map(entry):
    return {p.get("name"): p for p in (entry.get("properties") or [])}


def main(manifest_path=None, map_path=SLICE_MAP, save=True):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)

    trigger_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockInPlayerViewTrigger")
    if trigger_cls is None:
        raise RuntimeError("runtime ShockInPlayerViewTrigger class missing — build the plugin first")

    existing = import_level._existing_by_key()
    report = {"manifest": manifest_path, "placed": 0, "triggerWhenNotSeen": 0, "withDistanceGate": 0}

    for entry in manifest.get("actors") or []:
        if entry.get("className") != TRIGGER_CLASS_NAME:
            continue
        key = entry["key"]
        actor = existing.get(key)
        if actor is not None and actor.get_class() != trigger_cls:
            import_level._actor_subsystem().destroy_actor(actor)
            actor = None
        loc = unreal.Vector(*(entry.get("location") or [0.0, 0.0, 0.0]))
        rot = import_level._rotation(entry.get("rotation") or [0, 0, 0])
        if actor is None:
            actor = import_level._actor_subsystem().spawn_actor_from_class(trigger_cls, loc, rot)
            if actor is None:
                continue
        else:
            actor.set_actor_location(loc, False, False)
            actor.set_actor_rotation(rot, False)

        label = str(entry.get("label") or entry.get("name") or key)
        actor.set_actor_label(label)
        actor.tags = [
            unreal.Name(import_level.KEY_TAG_PREFIX + key),
            unreal.Name("BioShockClass=" + entry["className"]),
        ]
        existing[key] = actor

        props = _prop_map(entry)
        trigger_when_not_seen = "TriggerWhenNotSeen" in props
        min_dist = 0.0
        dist_prop = props.get("MinimumDistance")
        if dist_prop and dist_prop.get("valueHex"):
            decoded = import_level._decode_float32_hex(dist_prop["valueHex"])
            if decoded is not None:
                min_dist = float(decoded)

        actor.configure(unreal.Name(label), trigger_when_not_seen, min_dist)
        actor.set_editor_property("trigger_enabled", True)

        report["placed"] += 1
        if trigger_when_not_seen:
            report["triggerWhenNotSeen"] += 1
        if min_dist > 0.0:
            report["withDistanceGate"] += 1

    if save:
        level.save_current_level()

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[slice-in-player-view-triggers] %s" % json.dumps(report))
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
