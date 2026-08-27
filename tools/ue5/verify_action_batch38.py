"""Batch38: EndGame, ChangePEGWaitDistance, DisableOrEnableAdaptiveDifficulty, ForceGathererInteractable."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch38] %s" % m)


def main(shockgame, shockai, out):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionEndGame")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionEndGame"))
    if not apply.get("ok") or "NumberOfGatherersKilledToGetBadEnding" not in apply.get("applied", []):
        f.append("EndGame defaults")
    if int(a.get_number_of_gatherers_killed_to_get_bad_ending()) != 14:
        f.append("EndGame threshold default")
    if not a.request_end() or not bool(a.get_end_requested()):
        f.append("EndGame")
    report["end_game"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionChangePEGWaitDistance")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionChangePEGWaitDistance"))
    if not apply.get("ok"):
        f.append("PEG defaults")
    a.configure("PEG_A", 256.0)
    if not a.request_set() or abs(float(a.get_wait_distance()) - 256.0) > 0.01:
        f.append("PEG")
    report["peg"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionDisableOrEnableAdaptiveDifficulty")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionDisableOrEnableAdaptiveDifficulty"))
    if not apply.get("ok"):
        f.append("Adaptive defaults")
    a.configure(False)
    if not a.request_set() or bool(a.get_enable()):
        f.append("Adaptive")
    report["adaptive"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionForceGathererInteractable")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionForceGathererInteractable"))
    if not apply.get("ok"):
        f.append("ForceGather defaults")
    a.configure("Gatherer_A", True)
    if not a.request_force() or not bool(a.get_force_interactable()):
        f.append("ForceGather")
    report["force_gather"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch38:\n- " + "\n- ".join(f))
    _log("PASS batch38")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_ACTION_OUT"],
    )
