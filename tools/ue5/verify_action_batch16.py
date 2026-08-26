"""Batch16: SpawnTurret, SpawnSecurityBot, WeaponVis, Bathysphere."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch16] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnTurret")
    a = unreal.new_object(cls)
    a.configure("TurretSpawner_A")
    if not a.request_spawn():
        f.append("Turret")
    report["turret"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnSecurityBot")
    a = unreal.new_object(cls)
    a.configure("BotSpawner_A", True, "PlayerPawn")
    if not a.request_spawn():
        f.append("SecurityBot")
    report["security_bot"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionToggleAIWeaponVisibility")
    a = unreal.new_object(cls)
    a.configure("MedicalSplicer", False)
    if not a.request_toggle() or bool(a.get_show_weapon()):
        f.append("WeaponVis")
    report["weapon_vis"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionUnlockBathysphereDestination")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionUnlockBathysphereDestination"))
    if not apply.get("ok"):
        f.append("Bath defaults")
    a.configure("2-Medical", "BioshockBathyspheres")
    if not a.request_unlock():
        f.append("Bath")
    report["bathysphere"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch16:\n- " + "\n- ".join(f))
    _log("PASS batch16")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
