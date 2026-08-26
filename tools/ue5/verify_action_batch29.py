"""Batch29: StopTimer, EnableOrDisableHudMessages, PlayMovie, TelekinesisDropObject."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch29] %s" % m)


def main(scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStopTimer")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionStopTimer"))
    if not apply.get("ok"):
        f.append("StopTimer defaults")
    a.configure("Script_Timer_A")
    if not a.request_stop() or str(a.get_last_script_label()) != "Script_Timer_A":
        f.append("StopTimer")
    report["stop_timer"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEnableOrDisableHudMessages")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionEnableOrDisableHudMessages"))
    if not apply.get("ok"):
        f.append("HudMsg defaults")
    a.configure(True)
    if not a.request_set() or not bool(a.get_disable_hud_messages()):
        f.append("HudMsg")
    report["hud_messages"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlayMovie")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionPlayMovie"))
    if not apply.get("ok"):
        f.append("Movie defaults")
    a.configure("IntroMovie")
    if not a.request_play() or str(a.get_last_movie_name()) != "IntroMovie":
        f.append("Movie")
    report["play_movie"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTelekinesisDropObject")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionTelekinesisDropObject"))
    if not apply.get("ok"):
        f.append("TKDrop defaults")
    if not a.request_drop() or not bool(a.get_drop_requested()):
        f.append("TKDrop")
    report["tk_drop"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch29:\n- " + "\n- ".join(f))
    _log("PASS batch29")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
