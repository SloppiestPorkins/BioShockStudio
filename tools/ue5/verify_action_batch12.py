"""Batch12: FadeVolume, InitiateDamage, HavokForce, QuestArrow."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch12] %s" % m)


def main(scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionFadeVolumeOverride")
    a = unreal.new_object(cls)
    a.configure(0.5, 2.0)
    if not a.request_fade() or abs(float(a.get_last_volume()) - 0.5) > 0.01:
        f.append("FadeVolume")
    report["fade_volume"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionInitiateDamage")
    a = unreal.new_object(cls)
    a.configure("Player", "Weapon", "MedicalSplicer", "Ammo_Pistol", 0.0)
    if not a.request_damage():
        f.append("InitiateDamage")
    report["initiate_damage"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionTriggerHavokForceActor")
    a = unreal.new_object(cls)
    a.configure("ForceActor_A")
    if not a.request_trigger():
        f.append("HavokForce")
    report["havok_force"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangeQuestArrowActor")
    a = unreal.new_object(cls)
    a.configure("Quest_Medical", "Arrow_A", "1-Medical")
    if not a.request_change():
        f.append("QuestArrow")
    report["quest_arrow"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch12:\n- " + "\n- ".join(f))
    _log("PASS batch12")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SCRIPTING_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
