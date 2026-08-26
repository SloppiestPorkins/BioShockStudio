"""Batch8: SendTriggerMessage, DisplayDebug, Invincibility, RunConsoleCommand."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch8] %s" % m)


def main(scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSendTriggerMessage")
    a = unreal.new_object(cls)
    a.configure("Script_A")
    if not a.request_send():
        f.append("Trigger")
    report["trigger"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDisplayOnScreenDebugMessage")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionDisplayOnScreenDebugMessage"))
    if not apply.get("ok"):
        f.append("Debug defaults")
    a.configure("hello debug")
    if not a.request_display() or str(a.get_last_message()) != "hello debug":
        f.append("Debug")
    report["debug"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetPlayerInvincibility")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionSetPlayerInvincibility"))
    if not apply.get("ok") or not bool(a.get_invincible()):
        f.append("Invinc defaults")
    a.configure(False)
    if not a.request_set() or bool(a.get_last_invincible()):
        f.append("Invinc")
    report["invinc"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionRunConsoleCommand")
    a = unreal.new_object(cls)
    a.configure("stat fps")
    if not a.request_run() or str(a.get_last_command()) != "stat fps":
        f.append("Console")
    report["console"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch8:\n- " + "\n- ".join(f))
    _log("PASS batch8")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SCRIPTING_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
