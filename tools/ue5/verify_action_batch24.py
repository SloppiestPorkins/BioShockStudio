"""Batch24: MakeBotsAttack, PlaceItemInContainer, AssignNextGathererBooty."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch24] %s" % m)


def main(shockai, shockgame, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionMakeBotsAttack")
    a = unreal.new_object(cls)
    a.configure("BotController_A", "Player")
    if not a.request_attack() or str(a.get_last_controller_label()) != "BotController_A":
        f.append("MakeBotsAttack")
    report["bots_attack"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPlaceItemInContainer")
    a = unreal.new_object(cls)
    a.configure("Safe_A")
    if not a.request_place() or str(a.get_last_container_label()) != "Safe_A":
        f.append("PlaceItem")
    report["place_item"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAssignNextGathererBooty")
    a = unreal.new_object(cls)
    a.configure("Booty_A", "LittleSister_A")
    if not a.request_assign() or str(a.get_last_gatherer_label()) != "LittleSister_A":
        f.append("Booty")
    report["booty"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch24:\n- " + "\n- ".join(f))
    _log("PASS batch24")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_SHOCKAI_SCHEMA"], os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
