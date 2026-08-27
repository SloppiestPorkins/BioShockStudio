"""Batch41: KeypadContainer, HackSecurity, ProtectorVent, SoundPropagation."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch41] %s" % m)


def main(out, shockgame, shockai):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionKeypadContainerUsed")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionKeypadContainerUsed"))
    if not apply.get("ok"):
        f.append("Keypad defaults")
    a.configure("Keypad_A", True)
    if not a.request_notify():
        f.append("Keypad")
    report["keypad"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionHackSecuritySystem")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionHackSecuritySystem"))
    if not apply.get("ok") or abs(float(a.get_shutdown_time()) - 30.0) > 0.01:
        f.append("HackSec defaults")
    a.configure(45.0)
    if not a.request_hack():
        f.append("HackSec")
    report["hack_sec"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAssignNextProtectorVent")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionAssignNextProtectorVent"))
    if not apply.get("ok"):
        f.append("ProtVent defaults")
    a.configure("Vent_A", "Protector_A")
    if not a.request_assign():
        f.append("ProtVent")
    report["prot_vent"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEnableOrDisableSoundPropagation")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionEnableOrDisableSoundPropagation"))
    if not apply.get("ok"):
        f.append("SoundProp defaults")
    a.configure(False)
    if not a.request_set() or bool(a.get_enable()):
        f.append("SoundProp")
    report["sound_prop"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch41:\n- " + "\n- ".join(f))
    _log("PASS batch41")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_ACTION_OUT"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
    )
