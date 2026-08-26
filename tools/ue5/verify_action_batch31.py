"""Batch31: SetEffectsSystemContext, ResetProtectorAttackTargets, EnableOrDisableDamageVolume, ClearAIDamageStates."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch31] %s" % m)


def main(shockgame, shockai, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetEffectsSystemContext")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionSetEffectsSystemContext"))
    if not apply.get("ok") or "Context" not in apply.get("applied", []):
        f.append("EffectsContext defaults")
    a.configure("Underwater", 2, False, True)
    if not a.request_set() or str(a.get_last_context()) != "Underwater":
        f.append("EffectsContext")
    if int(a.get_context_applies_to()) != 2 or bool(a.get_remove_instead_of_add()):
        f.append("EffectsContext params")
    report["effects_context"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionResetProtectorAttackTargets")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionResetProtectorAttackTargets"))
    if not apply.get("ok"):
        f.append("ResetProtector defaults")
    a.configure("Protector_A")
    if not a.request_reset() or str(a.get_last_protector_label()) != "Protector_A":
        f.append("ResetProtector")
    report["reset_protector"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEnableOrDisableDamageVolume")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionEnableOrDisableDamageVolume"))
    if not apply.get("ok"):
        f.append("DamageVolume defaults")
    a.configure("ShockDamage_A", True)
    if not a.request_set() or not bool(a.get_enable_volume()):
        f.append("DamageVolume")
    report["damage_volume"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionClearAIDamageStates")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionClearAIDamageStates"))
    if not apply.get("ok"):
        f.append("ClearDamage defaults")
    a.configure("Thug_A")
    if not a.request_clear() or str(a.get_last_ai_label()) != "Thug_A":
        f.append("ClearDamage")
    report["clear_damage"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch31:\n- " + "\n- ".join(f))
    _log("PASS batch31")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
