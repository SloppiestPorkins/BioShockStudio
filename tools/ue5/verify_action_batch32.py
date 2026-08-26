"""Batch32: SetCorpseCanBeRemoved, UnEquipAllPlasmids, StartTimer, IncrementNumRosesPlayerPickedUp."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch32] %s" % m)


def main(scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetCorpseCanBeRemoved")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionSetCorpseCanBeRemoved"))
    if not apply.get("ok"):
        f.append("Corpse defaults")
    a.configure("Corpse_A", True)
    if not a.request_set() or not bool(a.get_corpse_can_be_removed()):
        f.append("Corpse")
    report["corpse"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionUnEquipAllPlasmids")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionUnEquipAllPlasmids"))
    if not apply.get("ok"):
        f.append("Plasmids defaults")
    if not a.request_unequip() or not bool(a.get_unequip_requested()):
        f.append("Plasmids")
    report["plasmids"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStartTimer")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionStartTimer"))
    if not apply.get("ok"):
        f.append("StartTimer defaults")
    a.configure(3.5)
    if not a.request_start() or abs(float(a.get_last_seconds()) - 3.5) > 0.01:
        f.append("StartTimer")
    report["start_timer"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionIncrementNumRosesPlayerPickedUp")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionIncrementNumRosesPlayerPickedUp"))
    if not apply.get("ok"):
        f.append("Roses defaults")
    if not a.request_increment() or not bool(a.get_rose_increment_requested()):
        f.append("Roses")
    report["roses"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch32:\n- " + "\n- ".join(f))
    _log("PASS batch32")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
