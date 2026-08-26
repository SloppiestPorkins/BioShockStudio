"""Batch36: AttachCollisionDamageListener, EnableOrDisableHavokForceActor, Ragdoll, SetNextAssassinTeleportPoint."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch36] %s" % m)


def main(scripting, shockgame, shockai, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAttachCollisionDamageListener")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionAttachCollisionDamageListener"))
    if not apply.get("ok"):
        f.append("CollListen defaults")
    a.configure("ReactiveCrate_A", "Owner_A")
    if not a.request_attach() or str(a.get_last_target_label()) != "ReactiveCrate_A":
        f.append("CollListen")
    report["coll_listen"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEnableOrDisableHavokForceActor")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionEnableOrDisableHavokForceActor"))
    if not apply.get("ok") or "enabled" not in apply.get("applied", []):
        f.append("HavokEnable defaults")
    if not bool(a.get_enabled()):
        f.append("HavokEnable default value")
    a.configure("ForceActor_A", False)
    if not a.request_set() or bool(a.get_enabled()):
        f.append("HavokEnable")
    report["havok_enable"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionRagdoll")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionRagdoll"))
    if not apply.get("ok"):
        f.append("Ragdoll defaults")
    a.configure("Thug_A", True, unreal.Vector(0, 0, 1), 500.0)
    if not a.request_ragdoll() or str(a.get_last_ai_label()) != "Thug_A" or not bool(a.get_relative_to_ai_rotation()):
        f.append("Ragdoll")
    report["ragdoll"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetNextAssassinTeleportPoint")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionSetNextAssassinTeleportPoint"))
    if not apply.get("ok"):
        f.append("AssTp defaults")
    a.configure("Assassin_A", "TeleportPoint_A")
    if not a.request_set() or str(a.get_last_assassin_label()) != "Assassin_A":
        f.append("AssTp")
    report["ass_tp"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch36:\n- " + "\n- ".join(f))
    _log("PASS batch36")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
