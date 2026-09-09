"""Headless verify: the slice has the Rapture mood layer (PPV + height fog)."""

import json
import os

import unreal

OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "slice_look_report.json"),
)
TAG = unreal.Name("BioShockSliceLook")


def main(out=OUT):
    report = {"failures": []}
    failures = report["failures"]

    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not lvl.load_level("/Game/BioShockSlice/1-Medical"):
        failures.append("could not load slice")
        raise RuntimeError("slice_look:\n- " + "\n- ".join(failures))

    sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    ppv = None
    fog = None
    for a in sub.get_all_level_actors():
        if TAG not in a.tags:
            continue
        if isinstance(a, unreal.PostProcessVolume):
            ppv = a
        elif isinstance(a, unreal.ExponentialHeightFog):
            fog = a

    report["hasPpv"] = ppv is not None
    report["hasFog"] = fog is not None
    if ppv is None:
        failures.append("no BioShockSliceLook PostProcessVolume")
    else:
        if not ppv.get_editor_property("unbound"):
            failures.append("look PPV is not unbound")
        s = ppv.get_editor_property("settings")
        if not s.get_editor_property("override_color_saturation"):
            failures.append("look PPV does not override saturation")
        report["saturation"] = float(s.get_editor_property("color_saturation").x)
    if fog is None:
        failures.append("no BioShockSliceLook ExponentialHeightFog")

    report["slice_look"] = "ok" if not failures else "fail"
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("slice_look:\n- " + "\n- ".join(failures))
    unreal.log("Success - slice look present")
    return report


if __name__ == "__main__":
    main()
