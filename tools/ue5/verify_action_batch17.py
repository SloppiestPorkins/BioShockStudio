"""Batch17: StartAIHeadTracking, SetCollisionAvoidance, RemoveItems, LevelSwitching."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch17] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStartAIHeadTracking")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionStartAIHeadTracking"))
    if not apply.get("ok"):
        f.append("HeadTrack defaults")
    a.configure("MedicalSplicer", "LookAtMarker", True, 2.5, unreal.Vector(0.0, 0.0, 10.0))
    if not a.request_start() or str(a.get_last_ai_label()) != "MedicalSplicer":
        f.append("HeadTrack")
    report["head_track"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetCollisionAvoidance")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer", True)
    if not a.request_set() or not bool(a.get_should_use_collision_avoidance()):
        f.append("Avoidance")
    report["collision_avoidance"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionRemoveItemsFromPlayer")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionRemoveItemsFromPlayer"))
    if not apply.get("ok") or "StackSize" not in apply.get("applied", []):
        f.append("RemoveItems defaults")
    a.configure_inventory("PistolAmmo", 12)
    if not a.request_remove() or str(a.get_last_removed_item_class()) != "PistolAmmo" or int(a.get_last_removed_stack_size()) != 12:
        f.append("RemoveItems")
    report["remove_items"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEnableOrDisableLevelSwitching")
    a = unreal.new_object(cls)
    a.configure(True)
    if not a.request_set() or not bool(a.get_last_disable_level_switching()):
        f.append("LevelSwitching")
    report["level_switching"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch17:\n- " + "\n- ".join(f))
    _log("PASS batch17")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
