"""Batch43: DisableOrEnableMachine, PlaceItemInContainerSlot, BouncerCanStepBack, EquipPlasmid."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch43] %s" % m)


def main(out, shockgame, shockai):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDisableOrEnableMachine")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionDisableOrEnableMachine"))
    if not apply.get("ok"):
        f.append("Machine defaults")
    a.configure("Machine_A", "ShockMachine", False)
    if not a.request_set():
        f.append("Machine")
    report["machine"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlaceItemInContainerSlot")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionPlaceItemInContainerSlot"))
    if not apply.get("ok") or int(a.get_stack_size()) != 1:
        f.append("PlaceSlot defaults")
    a.configure_inventory("MedKit", 2)
    a.configure_slot("Chest_A", 1, True)
    if not a.request_place():
        f.append("PlaceSlot")
    report["place_slot"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetBouncerCanStepBack")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionSetBouncerCanStepBack"))
    if not apply.get("ok"):
        f.append("Bouncer defaults")
    a.configure("Bouncer_A", False)
    if not a.request_set():
        f.append("Bouncer")
    report["bouncer"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEquipPlasmid")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionEquipPlasmid"))
    if not apply.get("ok"):
        f.append("EquipPlasmid defaults")
    a.configure("Incinerate", 1)
    if not a.request_equip():
        f.append("EquipPlasmid")
    report["equip_plasmid"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch43:\n- " + "\n- ".join(f))
    _log("PASS batch43")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_ACTION_OUT"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
    )
