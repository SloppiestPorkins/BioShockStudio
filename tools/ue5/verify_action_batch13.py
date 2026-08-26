"""Batch13: LevelSaving, RetractFact, AIVulnerability, VariableDecrement."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch13] %s" % m)


def main(shockai, scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEnableOrDisableLevelSaving")
    a = unreal.new_object(cls)
    a.configure(True)
    if not a.request_set() or not bool(a.get_last_disable_level_saving()):
        f.append("LevelSaving")
    report["level_saving"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionRetractFact")
    a = unreal.new_object(cls)
    a.configure("Fact_Hack", "s2", "s3")
    if not a.request_retract():
        f.append("RetractFact")
    report["retract"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetAIVulnerability")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionSetAIVulnerability"))
    if not apply.get("ok") or not bool(a.get_vulnerable()):
        f.append("Vuln defaults")
    a.configure("MedicalSplicer", False, True, False)
    if not a.request_set() or bool(a.get_vulnerable()):
        f.append("Vuln")
    report["vuln"] = "ok"

    scope_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockVariableScope")
    scope = unreal.new_object(scope_cls)
    scope.set("Counter", "5")
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableDecrement")
    a = unreal.new_object(cls)
    a.configure("Counter")
    if not a.apply_to_scope(scope) or str(scope.get_value_or_empty("Counter")) != "4":
        f.append("Dec")
    report["decrement"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch13:\n- " + "\n- ".join(f))
    _log("PASS batch13")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
