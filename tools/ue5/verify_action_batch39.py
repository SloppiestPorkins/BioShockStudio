"""Batch39: DealShockingDamageInRadius, AttachToBone."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch39] %s" % m)


def main(shockgame, shockai, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDealShockingDamageInRadius")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionDealShockingDamageInRadius"))
    if not apply.get("ok") or "DamageAmount" not in apply.get("applied", []):
        f.append("Shocking defaults")
    if abs(float(a.get_damage_amount()) - 100.0) > 0.01 or int(a.get_max_num_bolts()) != 5:
        f.append("Shocking default values")
    a.configure("TeslaSource_A", 75.0, 24, 512, 1024, 3, "TeslaEffect", 2.0, unreal.Vector2D(0.1, 0.5))
    if not a.request_deal() or str(a.get_last_source_actor_label()) != "TeslaSource_A":
        f.append("Shocking")
    report["shocking"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAttachToBone")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionAttachToBone"))
    if not apply.get("ok"):
        f.append("AttachBone defaults")
    a.configure("Prop_A", "Base_A", "Socket_01", unreal.Vector(10, 0, 0), unreal.Rotator(0, 90, 0))
    if not a.request_attach() or str(a.get_last_attachment_actor_label()) != "Prop_A":
        f.append("AttachBone")
    report["attach_bone"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch39:\n- " + "\n- ".join(f))
    _log("PASS batch39")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
