"""Batch9: SetAIPatrol, ChangePawnPhysics, SetPawnInvincibility, LODOverride."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch9] %s" % m)


def main(shockai, scripting, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetAIPatrol")
    a = unreal.new_object(cls)
    a.configure("MedicalAggressor", "Patrol_A")
    if not a.request_set_patrol():
        f.append("Patrol")
    report["patrol"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangePawnPhysics")
    a = unreal.new_object(cls)
    a.configure("PlayerPawn", True, False)
    if not a.request_change() or not bool(a.get_disable_physics()):
        f.append("Physics")
    report["physics"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetPawnInvincibility")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionSetPawnInvincibility"))
    if not apply.get("ok") or not bool(a.get_invincible()):
        f.append("PawnInv defaults")
    a.configure("MedicalSplicer", False)
    if not a.request_set() or bool(a.get_invincible()):
        f.append("PawnInv")
    report["pawn_inv"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetAINormalLODOverrideTime")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer", 5.0)
    if not a.request_set() or abs(float(a.get_lod_override_time()) - 5.0) > 0.01:
        f.append("LOD")
    report["lod"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch9:\n- " + "\n- ".join(f))
    _log("PASS batch9")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
