"""Batch23: RemoveCraftingFormula, StartSecurityAlarm, RemoveHandAttach, FilterItem."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch23] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionRemoveCraftingFormula")
    a = unreal.new_object(cls)
    a.configure("AmmoFormula")
    if not a.request_remove() or str(a.get_last_formula_class()) != "AmmoFormula":
        f.append("Formula")
    report["formula"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStartSecurityAlarm")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionStartSecurityAlarm"))
    if not apply.get("ok") or "NumSecurityBotsToSpawn" not in apply.get("applied", []):
        f.append("Alarm defaults")
    a.configure("Player", "SecurityBot", 2, True, False)
    if not a.request_start() or int(a.get_num_security_bots_to_spawn()) != 2:
        f.append("Alarm")
    report["alarm"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionRemoveScriptedHandAttachment")
    a = unreal.new_object(cls)
    if not a.request_remove() or not bool(a.was_remove_requested()):
        f.append("RemoveHand")
    report["remove_hand"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionFilterItem")
    a = unreal.new_object(cls)
    a.configure("PistolAmmo", False)
    if not a.request_filter() or bool(a.get_un_filter()):
        f.append("FilterItem")
    report["filter"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch23:\n- " + "\n- ".join(f))
    _log("PASS batch23")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
