"""Batch14: MaterialSwitch, AttachmentVis, HandAnim, QuestObjective."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch14] %s" % m)


def main(shockai, scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetMaterialSwitchIndex")
    a = unreal.new_object(cls)
    a.configure("MS_Medical", 2.0)
    if not a.request_set() or abs(float(a.get_last_index()) - 2.0) > 0.01:
        f.append("MaterialSwitch")
    report["material_switch"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionToggleAIAttachmentVisibility")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer", "Weapon", True)
    if not a.request_toggle() or not bool(a.get_hide_attachments()):
        f.append("AttachmentVis")
    report["attachment"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlayScriptedHandAnimation")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionPlayScriptedHandAnimation"))
    if not apply.get("ok") or int(a.get_animation_end_behavior()) != 4:
        f.append("Hand defaults")
    a.configure("Hand_Inject", "None", 4, 0.0, False)
    if not a.request_play():
        f.append("Hand")
    report["hand"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionCompleteQuestObjective")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionCompleteQuestObjective"))
    if not apply.get("ok") or int(a.get_number_of_objectives_completed()) != 1:
        f.append("Objective defaults")
    a.configure("Quest_Medical", True, 1)
    if not a.request_complete():
        f.append("Objective")
    report["objective"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch14:\n- " + "\n- ".join(f))
    _log("PASS batch14")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
