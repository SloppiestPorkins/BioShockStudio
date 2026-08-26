"""Batch34: PlayHUD, ActivateSecurityBot, EndDLCLevel."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch34] %s" % m)


def main(shockgame, shockai, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlayHUD")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionPlayHUD"))
    if not apply.get("ok"):
        f.append("PlayHUD defaults")
    if not a.request_play() or not bool(a.get_play_requested()):
        f.append("PlayHUD")
    report["play_hud"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionActivateSecurityBot")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionActivateSecurityBot"))
    if not apply.get("ok"):
        f.append("SecBot defaults")
    a.configure("Player", "SecurityBot_A")
    if not a.request_activate() or str(a.get_last_bot_label()) != "SecurityBot_A":
        f.append("SecBot")
    report["sec_bot"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEndDLCLevel")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionEndDLCLevel"))
    if not apply.get("ok"):
        f.append("DLC defaults")
    a.configure(True)
    if not a.request_end() or not bool(a.get_failed_level()):
        f.append("DLC")
    report["dlc"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch34:\n- " + "\n- ".join(f))
    _log("PASS batch34")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
