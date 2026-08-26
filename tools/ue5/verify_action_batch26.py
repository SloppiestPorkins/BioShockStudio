"""Batch26: SetAIState, DealDamageInRadius, ShowBathysphereUI, DoorKeypadUsed."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch26] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetAIState")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionSetAIState"))
    if not apply.get("ok") or "AIState" not in apply.get("applied", []):
        f.append("AIState defaults")
    a.configure("MedicalSplicer", 2)
    if not a.request_set() or int(a.get_ai_state()) != 2:
        f.append("AIState")
    report["ai_state"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDealDamageInRadius")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionDealDamageInRadius"))
    if not apply.get("ok") or "DamageAmount" not in apply.get("applied", []):
        f.append("Radius defaults")
    a.configure("Explosion_A", 50.0, 128, 256)
    if not a.request_deal() or abs(float(a.get_damage_amount()) - 50.0) > 0.01:
        f.append("Radius")
    report["damage_radius"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionShowBathysphereUI")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionShowBathysphereUI"))
    if not apply.get("ok") or "BathysphereSystem" not in apply.get("applied", []):
        f.append("BathUI defaults")
    a.configure("BioshockBathyspheres")
    if not a.request_show() or str(a.get_last_bathysphere_system()) != "BioshockBathyspheres":
        f.append("BathUI")
    report["bath_ui"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDoorKeypadUsed")
    a = unreal.new_object(cls)
    a.configure("Keypad_A", True)
    if not a.request_used() or not bool(a.get_success()):
        f.append("Keypad")
    report["keypad"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch26:\n- " + "\n- ".join(f))
    _log("PASS batch26")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
