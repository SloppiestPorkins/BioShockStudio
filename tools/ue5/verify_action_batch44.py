"""Batch44: SetPlasmidSlotLockedState — census tail."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch44] %s" % m)


def main(out, shockgame):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetPlasmidSlotLockedState")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionSetPlasmidSlotLockedState"))
    if not apply.get("ok"):
        f.append("PlasmidLock defaults")
    a.configure(1, True)
    if not a.request_set():
        f.append("PlasmidLock")
    report["plasmid_lock"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch44:\n- " + "\n- ".join(f))
    _log("PASS batch44")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_ACTION_OUT"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
    )
