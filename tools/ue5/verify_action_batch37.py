"""Batch37: SetDoorBrokenState, ForcePlayerCrouch, HideNeedleElement, ShowNeedleElement."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch37] %s" % m)


def main(shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetDoorBrokenState")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionSetDoorBrokenState"))
    if not apply.get("ok"):
        f.append("DoorBroken defaults")
    a.configure("Door_A", True)
    if not a.request_set() or not bool(a.get_is_broken()):
        f.append("DoorBroken")
    report["door_broken"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionForcePlayerCrouch")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionForcePlayerCrouch"))
    if not apply.get("ok"):
        f.append("Crouch defaults")
    a.configure(True)
    if not a.request_crouch() or not bool(a.get_should_crouch()):
        f.append("Crouch")
    report["crouch"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionHideNeedleElement")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "HideNeedleElement"))
    if not apply.get("ok"):
        f.append("HideNeedle defaults")
    if not a.request_hide() or not bool(a.get_hide_requested()):
        f.append("HideNeedle")
    report["hide_needle"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionShowNeedleElement")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ShowNeedleElement"))
    if not apply.get("ok"):
        f.append("ShowNeedle defaults")
    if not a.request_show() or not bool(a.get_show_requested()):
        f.append("ShowNeedle")
    report["show_needle"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch37:\n- " + "\n- ".join(f))
    _log("PASS batch37")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
