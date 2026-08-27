"""Batch40: SetPlayerFOV, TrainingCondition, GrenadierSuicide, UnHackSecurity."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch40] %s" % m)


def main(out, shockgame, shockai):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetPlayerFOV")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionSetPlayerFOV"))
    if not apply.get("ok"):
        f.append("FOV defaults")
    a.configure(90.0)
    if not a.request_set() or abs(float(a.get_fov()) - 90.0) > 0.01:
        f.append("FOV")
    report["fov"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTrainingCondition")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "TrainingCondition"))
    if not apply.get("ok") or int(a.get_tick_delay()) != 10:
        f.append("Training defaults")
    a.configure(1.5, 5, 2, "Concept_A")
    if not a.request_evaluate():
        f.append("Training")
    report["training"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetGrenadierSuicideState")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionSetGrenadierSuicideState"))
    if not apply.get("ok"):
        f.append("Grenadier defaults")
    a.configure("Grenadier_A", 1)
    if not a.request_set():
        f.append("Grenadier")
    report["grenadier"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionUnHackSecuritySystem")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionUnHackSecuritySystem"))
    if not apply.get("ok"):
        f.append("UnHack defaults")
    if not a.request_un_hack():
        f.append("UnHack")
    report["unhack"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch40:\n- " + "\n- ".join(f))
    _log("PASS batch40")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_ACTION_OUT"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
    )
