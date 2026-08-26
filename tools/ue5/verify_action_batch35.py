"""Batch35: BathysphereMode, WaitUntilActorHasLanded, CascadingWaterVolume, AssignNextGathererLabel."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch35] %s" % m)


def main(shockgame, shockai, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEnableBathysphereModeForPlayer")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionEnableBathysphereModeForPlayer"))
    if not apply.get("ok"):
        f.append("BathMode defaults")
    a.configure(True)
    if not a.request_set() or not bool(a.get_enable_bathysphere_mode()):
        f.append("BathMode")
    report["bath_mode"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionWaitUntilActorHasLanded")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionWaitUntilActorHasLanded"))
    if not apply.get("ok") or "TargetLabel" not in apply.get("applied", []):
        f.append("Landed defaults")
    if a.request_wait():
        f.append("Landed should reject placeholder")
    a.configure("FallingCrate_A")
    if not a.request_wait() or str(a.get_last_target_label()) != "FallingCrate_A":
        f.append("Landed")
    report["landed"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEnableOrDisableCascadingWaterVolume")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionEnableOrDisableCascadingWaterVolume"))
    if not apply.get("ok"):
        f.append("WaterVol defaults")
    a.configure("WaterFall_A", False)
    if not a.request_set() or bool(a.get_enable_volume()):
        f.append("WaterVol")
    report["water_vol"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAssignNextGathererLabel")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionAssignNextGathererLabel"))
    if not apply.get("ok"):
        f.append("GathererLbl defaults")
    a.configure("Protector_A", "Gatherer_Spawn_A")
    if not a.request_assign() or str(a.get_last_protector_label()) != "Protector_A":
        f.append("GathererLbl")
    report["gatherer_lbl"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch35:\n- " + "\n- ".join(f))
    _log("PASS batch35")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
