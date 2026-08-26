"""Batch19: ResurrectionStation, Holdable, Achievement, WeaponFireMessage."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch19] %s" % m)


def main(shockai, shockgame, scripting, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDisableOrEnableResurrectionStation")
    a = unreal.new_object(cls)
    a.configure("VitaChamber_A", False)
    if not a.request_set() or bool(a.get_enable()):
        f.append("ResurrectionStation")
    report["resurrection"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionRemoveAvailableHoldable")
    a = unreal.new_object(cls)
    a.configure("Pistol")
    if not a.request_remove() or str(a.get_last_holdable_class()) != "Pistol":
        f.append("Holdable")
    report["holdable"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAwardAchievement")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionAwardAchievement"))
    if not apply.get("ok"):
        f.append("Achievement defaults")
    a.configure("BoughtOneSlot")
    if not a.request_award() or str(a.get_last_achievement()) != "BoughtOneSlot":
        f.append("Achievement")
    report["achievement"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTellAIToSendWeaponFireMessage")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer", "Weapon_A", "Pistol")
    if not a.request_tell() or str(a.get_last_ai_label()) != "MedicalSplicer":
        f.append("WeaponFire")
    report["weapon_fire"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch19:\n- " + "\n- ".join(f))
    _log("PASS batch19")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
