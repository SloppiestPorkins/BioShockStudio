"""Batch10: SpawnReactiveActor, ResurrectionStation, LockDoor, TrainingMessage."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch10] %s" % m)


def main(shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnReactiveActor")
    a = unreal.new_object(cls)
    a.configure("SpawnedRA", "Marker_A", "ReactiveActor_Crate", True)
    if not a.request_spawn() or not bool(a.get_starts_physical()):
        f.append("Reactive")
    report["reactive"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionActivateResurrectionStation")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionActivateResurrectionStation"))
    if not apply.get("ok") or not bool(a.get_activate_station()):
        f.append("Station defaults")
    a.configure("VitaChamber_A", True)
    if not a.request_activate():
        f.append("Station")
    report["station"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionLockDoor")
    a = unreal.new_object(cls)
    a.configure("MedicalDoor")
    if not a.request_lock():
        f.append("LockDoor")
    report["lock_door"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionShowTrainingMessage")
    a = unreal.new_object(cls)
    a.configure("Training_Hack")
    if not a.request_show():
        f.append("Training")
    report["training"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch10:\n- " + "\n- ".join(f))
    _log("PASS batch10")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
