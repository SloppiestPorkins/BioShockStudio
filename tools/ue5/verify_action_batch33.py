"""Batch33: PlayEffectAndWaitForStart, GrenadierUseLiveGrenadeWeapon, WaitForCriticalMessageStart, StopHUD."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch33] %s" % m)


def main(scripting, shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlayEffectAndWaitForStart")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionPlayEffectAndWaitForStart"))
    if not apply.get("ok") or "TimeoutSeconds" not in apply.get("applied", []):
        f.append("FxWait defaults")
    if abs(float(a.get_timeout_seconds()) - 60.0) > 0.01:
        f.append("FxWait timeout default")
    a.configure("PlayDialogue", "Tag_A", 12.0, "Speaker_A", False, True)
    if not a.request_play() or str(a.get_last_effect_event_to_play()) != "PlayDialogue":
        f.append("FxWait")
    report["fx_wait"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionGrenadierUseLiveGrenadeWeapon")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionGrenadierUseLiveGrenadeWeapon"))
    if not apply.get("ok"):
        f.append("Grenadier defaults")
    a.configure("Grenadier_A")
    if not a.request_use() or str(a.get_last_grenadier_label()) != "Grenadier_A":
        f.append("Grenadier")
    report["grenadier"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionWaitForCriticalMessageStart")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionWaitForCriticalMessageStart"))
    if not apply.get("ok") or "TimeoutSeconds" not in apply.get("applied", []):
        f.append("CritWait defaults")
    a.configure("VO_Line_A", 30.0, "Speaker_A")
    if not a.request_wait() or str(a.get_last_effect_event_to_wait_for()) != "VO_Line_A":
        f.append("CritWait")
    report["crit_wait"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionStopHUD")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionStopHUD"))
    if not apply.get("ok"):
        f.append("StopHUD defaults")
    if not a.request_stop() or not bool(a.get_stop_requested()):
        f.append("StopHUD")
    report["stop_hud"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch33:\n- " + "\n- ".join(f))
    _log("PASS batch33")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
