"""Batch20: SpawnerRepop, EscortedGatherer, HandAttachment, ApplyImpulse."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch20] %s" % m)


def main(shockai, shockgame, scripting, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetSpawnerRepopulationState")
    a = unreal.new_object(cls)
    a.configure("Spawner_A", True)
    if not a.request_set() or not bool(a.get_flag()):
        f.append("SpawnerRepop")
    report["spawner_repop"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnPlayerEscortedGatherer")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionSpawnPlayerEscortedGatherer"))
    if not apply.get("ok") or "SpawnedGathererLabel" not in apply.get("applied", []):
        f.append("Gatherer defaults")
    a.configure("Vent_A", "Pos_A", "PlayerEscortedGatherer", True, True)
    if not a.request_spawn() or str(a.get_last_spawned_gatherer_label()) != "PlayerEscortedGatherer":
        f.append("Gatherer")
    report["escorted_gatherer"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionApplyScriptedHandAttachment")
    a = unreal.new_object(cls)
    a.configure("HandTool", "b_LeftHand")
    if not a.request_apply() or str(a.get_last_attachment_class()) != "HandTool":
        f.append("HandAttachment")
    report["hand_attachment"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionApplyImpulse")
    a = unreal.new_object(cls)
    a.configure("Crate_A", unreal.Vector(0.0, 0.0, 500.0), "None")
    if not a.request_apply() or str(a.get_last_target()) != "Crate_A":
        f.append("Impulse")
    report["impulse"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch20:\n- " + "\n- ".join(f))
    _log("PASS batch20")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ.get("BIOSHOCK_SCRIPTING_SCHEMA", ""),
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
