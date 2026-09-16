"""Headless verify for ActionEnableOrDisableCascadingWaterVolume (R2.5).

Spawns a throwaway AShockWaterVolume, toggles bCascading on/off through the action, and checks
the property actually changed on the target (not just recorded on the action).
"""
import json
import os

import unreal


def _cls(name):
    c = unreal.load_class(None, "/Script/BioShockRuntime.%s" % name)
    if c is None:
        raise RuntimeError("missing class %s" % name)
    return c


def main(out_path):
    failures = []
    report = {"failures": failures}
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    world = unreal.EditorLevelLibrary.get_editor_world()

    water = subsystem.spawn_actor_from_class(
        _cls("ShockWaterVolume"), unreal.Vector(0.0, 0.0, 0.0), unreal.Rotator(0, 0, 0)
    )
    water.set_actor_label("R25_WaterVolume")
    water.configure_from_half_extent(unreal.Vector(200.0, 200.0, 100.0), False)

    try:
        action = unreal.new_object(_cls("ShockActionEnableOrDisableCascadingWaterVolume"))
        action.configure("R25_WaterVolume", True)
        applied_on = int(action.apply_in_world(world))
        cascading_on = bool(water.get_editor_property("cascading"))
        if not (applied_on == 1 and cascading_on):
            failures.append("enable did not set bCascading (applied=%s cascading=%s)" % (applied_on, cascading_on))

        action2 = unreal.new_object(_cls("ShockActionEnableOrDisableCascadingWaterVolume"))
        action2.configure("R25_WaterVolume", False)
        applied_off = int(action2.apply_in_world(world))
        cascading_off = bool(water.get_editor_property("cascading"))
        if not (applied_off == 1 and not cascading_off):
            failures.append("disable did not clear bCascading (applied=%s cascading=%s)" % (applied_off, cascading_off))
    finally:
        subsystem.destroy_actor(water)

    report["status"] = "pass" if not failures else "fail"
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("cascading_water:\n- " + "\n- ".join(failures))
    unreal.log("Success - 2/2 checks passed")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "verify_action_cascading_water.json"),
        )
    )
