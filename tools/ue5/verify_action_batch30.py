"""Batch30: SetAIRangedWeaponAccuracy, EnableOrDisableTrainingMessages, HackTurret, ControlPlant."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch30] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetAIRangedWeaponAccuracy")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionSetAIRangedWeaponAccuracy"))
    if not apply.get("ok"):
        f.append("Accuracy defaults")
    a.configure("Weapon_A", unreal.Vector2D(0.1, 0.3), unreal.Vector2D(1.0, 2.0), unreal.Vector2D(0.2, 0.4), unreal.Vector2D(0.5, 1.5))
    if not a.request_set() or str(a.get_last_ranged_weapon_label()) != "Weapon_A":
        f.append("Accuracy")
    if abs(float(a.get_accuracy_range_vs_player().x) - 0.1) > 0.01:
        f.append("Accuracy range")
    report["accuracy"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEnableOrDisableTrainingMessages")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionEnableOrDisableTrainingMessages"))
    if not apply.get("ok"):
        f.append("Training defaults")
    a.configure(False)
    if not a.request_set() or bool(a.get_enable_training_messages()):
        f.append("Training")
    report["training"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionHackTurret")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionHackTurret"))
    if not apply.get("ok") or "SetHacked" not in apply.get("applied", []):
        f.append("HackTurret defaults")
    if not bool(a.get_set_hacked()):
        f.append("HackTurret default value")
    a.configure("Turret_A", True)
    if not a.request_hack() or str(a.get_last_turret_label()) != "Turret_A":
        f.append("HackTurret")
    report["hack_turret"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionControlPlant")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionControlPlant"))
    if not apply.get("ok"):
        f.append("Plant defaults")
    a.configure(2.5, True)
    if not a.request_control() or abs(float(a.get_duration()) - 2.5) > 0.01 or not bool(a.get_revive()):
        f.append("Plant")
    report["control_plant"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch30:\n- " + "\n- ".join(f))
    _log("PASS batch30")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
