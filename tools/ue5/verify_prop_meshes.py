"""Headless verify: pickup / container / mover / station actors have a real mesh, not a marker."""

import json
import os

import unreal

OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "prop_meshes_report.json"),
)
CHECKED = ("ShockConsumablePickup", "ShockSearchableContainer",
           "ShockAnimatedProp", "ShockStationBase")


def main(out=OUT):
    report = {"failures": [], "byClass": {}}
    failures = report["failures"]
    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not lvl.load_level("/Game/BioShockSlice/1-Medical"):
        failures.append("could not load slice")
        raise RuntimeError("prop_meshes:\n- " + "\n- ".join(failures))

    acts = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    marker = nomat = ok = 0
    for a in acts:
        cn = a.get_class().get_name()
        if cn not in CHECKED:
            continue
        comp = a.get_component_by_class(unreal.StaticMeshComponent)
        m = comp.get_editor_property("static_mesh") if comp else None
        vis = comp.get_editor_property("visible") if comp else False
        if not m or not vis:
            continue  # legitimately hidden (corpse container, keypress pickup) — not a marker
        if m.get_path_name().startswith("/Engine/BasicShapes"):
            marker += 1
            continue
        # Effective material = component override, falling back to the asset slot.
        slot_count = max(1, len(m.get_editor_property("static_materials") or []))
        bad = any(
            (comp.get_material(i) is None or "WorldGrid" in comp.get_material(i).get_name())
            for i in range(slot_count))
        if bad:
            nomat += 1
        else:
            ok += 1
    report["realMesh"] = ok
    report["markerMesh"] = marker
    report["nullMaterial"] = nomat
    if marker > 0:
        failures.append("%d visible pickup/container/mover/station actors still on a marker sphere" % marker)

    report["prop_meshes"] = "ok" if not failures else "fail"
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("prop_meshes:\n- " + "\n- ".join(failures))
    unreal.log("Success - real=%d marker=%d nullMat=%d" % (ok, marker, nomat))
    return report


if __name__ == "__main__":
    main()
