"""Batch28: ChangeLevel, ChangeResistanceSet, ToggleSecurityCameraSpotlight, DestroyAIs."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch28] %s" % m)


def main(scripting, shockgame, shockai, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeLevel")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionChangeLevel"))
    if not apply.get("ok") or "persist" not in apply.get("applied", []):
        f.append("ChangeLevel defaults")
    if not bool(a.get_persist()):
        f.append("ChangeLevel persist default")
    a.configure("1-Medical", "StartSpot_A", True, True)
    if not a.request_change() or str(a.get_last_map_name()) != "1-Medical":
        f.append("ChangeLevel")
    report["change_level"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeResistanceSet")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionChangeResistanceSet"))
    if not apply.get("ok") or "ResistanceSetName" not in apply.get("applied", []):
        f.append("Resistance defaults")
    if str(a.get_resistance_set_name()) != "Default":
        f.append("Resistance default value")
    a.configure("Reactive_A", "FireImmune")
    if not a.request_change() or str(a.get_last_resistance_set_name()) != "FireImmune":
        f.append("Resistance")
    report["resistance"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionToggleSecurityCameraSpotlight")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionToggleSecurityCameraSpotlight"))
    if not apply.get("ok"):
        f.append("Spotlight defaults")
    a.configure("Cam_A", True)
    if not a.request_toggle() or not bool(a.get_spotlight_on()):
        f.append("Spotlight")
    report["spotlight"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDestroyAIs")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionDestroyAIs"))
    if not apply.get("ok") or "bOnlyLowDetailAIs" not in apply.get("applied", []):
        f.append("DestroyAIs defaults")
    if not bool(a.get_only_low_detail()):
        f.append("DestroyAIs low-detail default")
    a.configure("ShockAI", True)
    if not a.request_destroy() or str(a.get_last_base_class_name()) != "ShockAI":
        f.append("DestroyAIs")
    report["destroy_ais"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch28:\n- " + "\n- ".join(f))
    _log("PASS batch28")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
