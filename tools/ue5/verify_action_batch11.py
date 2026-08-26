"""Batch11: CompleteQuest, RemoveGoal, ToggleAIAttacking, SetActorLabel."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch11] %s" % m)


def main(shockai, scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionCompleteQuest")
    a = unreal.new_object(cls)
    a.configure("Quest_Medical", True)
    if not a.request_complete():
        f.append("CompleteQuest")
    report["complete_quest"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionRemoveGoal")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer", "MovementGoal")
    if not a.request_remove() or str(a.get_last_goal_name()) != "MovementGoal":
        f.append("RemoveGoal")
    report["remove_goal"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionToggleAIAttacking")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer", False)
    if not a.request_toggle() or bool(a.get_can_attack()):
        f.append("ToggleAttack")
    report["toggle_attack"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetActorLabel")
    a = unreal.new_object(cls)
    a.configure("OldLabel", "NewLabel")
    actor = unreal.EditorLevelLibrary.spawn_actor_from_class(unreal.Actor, unreal.Vector(0, 0, 0))
    actor.set_actor_label("OldLabel")
    if not a.apply_to_actor(actor) or str(a.get_last_new_label()) != "NewLabel":
        f.append("SetActorLabel")
    unreal.EditorLevelLibrary.destroy_actor(actor)
    report["set_label"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch11:\n- " + "\n- ".join(f))
    _log("PASS batch11")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
