"""Batch3: FadeView, Concept, ScriptedSequence, DealDamage."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch3] %s" % m)


def main(scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionCinematicFadeView")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionCinematicFadeView"))
    if not apply.get("ok") or abs(float(a.get_duration()) - 2.0) > 0.01:
        f.append("Fade defaults")
    a.configure(0.0, 1.0, 2.0, 0.0)
    if not a.request_fade():
        f.append("Fade request")
    report["fade"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDisableOrEnableConcept")
    a = unreal.new_object(cls)
    a.configure("Concept_Hack", False)
    if not a.request_toggle() or bool(a.get_last_enable()):
        f.append("Concept")
    report["concept"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionControlScriptedSequence")
    a = unreal.new_object(cls)
    a.configure("MedicalRAM", 1)
    if not a.request_control() or int(a.get_last_run_now()) != 1:
        f.append("Seq")
    report["seq"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDealDamage")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionDealDamage"))
    if not apply.get("ok") or abs(float(a.get_damage_amount()) - 100.0) > 0.01:
        f.append("Damage defaults")
    a.configure("MedicalSplicer", 50.0, 1.0)
    if not a.request_damage() or abs(float(a.get_last_damage_amount()) - 50.0) > 0.01:
        f.append("Damage request")
    report["damage"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch3:\n- " + "\n- ".join(f))
    _log("PASS batch3")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SCRIPTING_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
