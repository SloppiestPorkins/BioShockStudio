"""Batch5: AssertFact, Loop, TeleportPawn, SetOrUnsetInputContext."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch5] %s" % m)


def main(scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAssertFact")
    a = unreal.new_object(cls)
    a.configure("Fact_Hack", "slot2", "slot3")
    if not a.request_assert():
        f.append("AssertFact")
    report["assert_fact"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionLoop")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionLoop"))
    if not apply.get("ok") or int(a.get_current_index()) != -1:
        f.append("Loop defaults")
    if not a.request_enter_loop() or not bool(a.get_entered_loop()) or int(a.get_current_index()) != 0:
        f.append("Loop enter")
    report["loop"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTeleportPawnToLocation")
    a = unreal.new_object(cls)
    a.configure("PlayerPawn", "MedicalStart")
    if not a.request_teleport():
        f.append("Teleport")
    report["teleport"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetOrUnsetInputContext")
    a = unreal.new_object(cls)
    a.configure("Cinematic", True)
    if not a.request_context() or not bool(a.get_unset()):
        f.append("InputContext")
    report["input_context"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch5:\n- " + "\n- ".join(f))
    _log("PASS batch5")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SCRIPTING_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
