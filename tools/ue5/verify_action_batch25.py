"""Batch25: ActionFor, SecurityBotSpawnLocation, ChangeStaticMesh, TellAIToContinue."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch25] %s" % m)


def main(shockai, shockgame, scripting, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionFor")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionFor"))
    if not apply.get("ok") or "counterName" not in apply.get("applied", []):
        f.append("For defaults")
    a.configure("forCounter", 0.0, 5.0, -1)
    if not a.request_enter_for() or not bool(a.get_entered_for()):
        f.append("For")
    report["for"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAssignNextSecurityBotSpawnLocation")
    a = unreal.new_object(cls)
    a.configure("BotSpawn_A")
    if not a.request_assign() or str(a.get_last_spawn_location_label()) != "BotSpawn_A":
        f.append("BotSpawn")
    report["bot_spawn"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeStaticMesh")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionChangeStaticMesh"))
    if not apply.get("ok") or "TargetLabel" not in apply.get("applied", []):
        f.append("Mesh defaults")
    a.configure("Door_A", "SM_Door")
    if not a.request_change() or str(a.get_last_target_label()) != "Door_A":
        f.append("Mesh")
    report["static_mesh"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTellAIToContinue")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer")
    if not a.request_continue() or str(a.get_last_ai_label()) != "MedicalSplicer":
        f.append("Continue")
    report["continue"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch25:\n- " + "\n- ".join(f))
    _log("PASS batch25")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
