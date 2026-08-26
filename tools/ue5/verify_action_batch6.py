"""Batch6: SpawnZoneRepop, InitiateQuest, SpotlightTarget, ChangePressure."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch6] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionManipulateSpawnZoneRepopulation")
    a = unreal.new_object(cls)
    a.configure("MedicalZone", unreal.ShockSpawnZoneRepopulationState.ENABLE, unreal.ShockSpawnZoneRepopulationState.NO_CHANGE)
    if not a.request_manipulate() or a.get_aggressor_state() != unreal.ShockSpawnZoneRepopulationState.ENABLE:
        f.append("SpawnZone")
    report["spawn_zone"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionInitiateQuest")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionInitiateQuest"))
    if not apply.get("ok") or not bool(a.get_set_as_active_quest()):
        f.append("Quest defaults")
    a.configure("Quest_Medical", True, True, "New Goal")
    if not a.request_initiate():
        f.append("Quest request")
    report["quest"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetMovableSpotlightTarget")
    a = unreal.new_object(cls)
    a.configure("Spot_A", "PlayerPawn")
    if not a.request_set_target():
        f.append("Spotlight")
    report["spotlight"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangePressure")
    a = unreal.new_object(cls)
    a.configure("Region_A", 1)
    if not a.request_change() or int(a.get_desired_pressure()) != 1:
        f.append("Pressure")
    report["pressure"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch6:\n- " + "\n- ".join(f))
    _log("PASS batch6")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
