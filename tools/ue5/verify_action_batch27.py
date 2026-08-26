"""Batch27: GathererCrawlThroughDoor, StopAIHeadTracking, ForcePlayerMove, SpawnPickup."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch27] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionGathererCrawlThroughDoor")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionGathererCrawlThroughDoor"))
    if not apply.get("ok") or "bShouldUnlock" not in apply.get("applied", []):
        f.append("Crawl defaults")
    if not bool(a.get_should_unlock()):
        f.append("Crawl unlock default")
    a.configure("LittleSister_A", "Door_Crawl_01", True, False, True)
    if not a.request_crawl() or str(a.get_last_door_label()) != "Door_Crawl_01":
        f.append("Crawl")
    report["crawl"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStopAIHeadTracking")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionStopAIHeadTracking"))
    if not apply.get("ok"):
        f.append("StopHead defaults")
    a.configure("Thug_A")
    if not a.request_stop() or str(a.get_last_ai_label()) != "Thug_A":
        f.append("StopHead")
    report["stop_head"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionForcePlayerMove")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionForcePlayerMove"))
    if not apply.get("ok"):
        f.append("ForceMove defaults")
    a.configure("PlayerMarker_A", "Root", 5.0, 200.0, 90.0)
    if not a.request_move() or abs(float(a.get_time_out()) - 5.0) > 0.01:
        f.append("ForceMove")
    report["force_move"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnPickup")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionSpawnPickup"))
    if not apply.get("ok"):
        f.append("Pickup defaults")
    a.configure("Loot_A", "SpawnPoint_A", "EVEHypoPickup", "EVEHypo", 3, True)
    if not a.request_spawn() or int(a.get_stack_size()) != 3:
        f.append("Pickup")
    report["spawn_pickup"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch27:\n- " + "\n- ".join(f))
    _log("PASS batch27")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
