"""Batch22: LinkedGatherer, ChangeAnimationRate, ReplaceQuest, ClearTrainingMessage."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch22] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnLinkedGathererAndProtector")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionSpawnLinkedGathererAndProtector"))
    if not apply.get("ok") or "bGathererCorpseCanBeRemoved" not in apply.get("applied", []):
        f.append("Linked defaults")
    a.configure("Protector", "Vent_A", "BigDaddy_A", "LittleSister_A", True)
    if not a.request_spawn() or str(a.get_last_gatherer_label()) != "LittleSister_A":
        f.append("Linked")
    report["linked"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeAnimationRate")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionChangeAnimationRate"))
    if not apply.get("ok") or "TargetAnimationRate" not in apply.get("applied", []):
        f.append("AnimRate defaults")
    a.configure("Player", "Fidget", 0.5, 0.0)
    if not a.request_change() or abs(float(a.get_target_animation_rate()) - 0.5) > 0.01:
        f.append("AnimRate")
    report["anim_rate"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionReplaceQuest")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionReplaceQuest"))
    if not apply.get("ok") or "UpdatedMessage" not in apply.get("applied", []):
        f.append("ReplaceQuest defaults")
    a.configure("OldQuest", "NewQuest", True, "Goal Updated")
    if not a.request_replace() or str(a.get_last_replacement_quest_name()) != "NewQuest":
        f.append("ReplaceQuest")
    report["replace_quest"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionClearTrainingMessage")
    a = unreal.new_object(cls)
    a.configure("HackTip")
    if not a.request_clear() or str(a.get_last_message_name()) != "HackTip":
        f.append("ClearTraining")
    report["clear_training"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch22:\n- " + "\n- ".join(f))
    _log("PASS batch22")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
