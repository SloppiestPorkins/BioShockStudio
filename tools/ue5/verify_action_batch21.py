"""Batch21: GathererVent spawn flag, TellAIToWait, ClearContainer, LocomotionKeyword."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch21] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetGathererVentPlayerCanSpawn")
    a = unreal.new_object(cls)
    a.configure("Vent_A", True)
    if not a.request_set() or not bool(a.get_flag()):
        f.append("GathererVent")
    report["gatherer_vent"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTellAIToWait")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer")
    if not a.request_wait() or str(a.get_last_ai_label()) != "MedicalSplicer":
        f.append("TellAIToWait")
    report["tell_wait"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionClearContainer")
    a = unreal.new_object(cls)
    a.configure("Safe_A")
    if not a.request_clear() or str(a.get_last_container_label()) != "Safe_A":
        f.append("ClearContainer")
    report["clear_container"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionModifyLocomotionKeyword")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionModifyLocomotionKeyword"))
    if not apply.get("ok") or "KeywordPriority" not in apply.get("applied", []):
        f.append("Loco defaults")
    a.configure("MedicalSplicer", "Walk", 1, True)
    if not a.request_modify() or not bool(a.get_add_keyword()):
        f.append("Loco")
    report["locomotion"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch21:\n- " + "\n- ".join(f))
    _log("PASS batch21")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
