"""List what is actually AROUND the player start, ranked by how much of the view it can fill.

The screen probe traces along ECC_Visibility, so anything with collision disabled is invisible to
it - it reports the wall behind. A large flat translucent pane with no collision therefore reads
as "nothing there" no matter how much of the frame it covers, which is how a pale wedge survived
four rounds of tracing.

This looks from the other end: enumerate every actor near the start, record bounds, flatness and
materials, and rank by frontal area. A big, flat, translucent, collision-free actor near the
camera is the shape of the thing being hunted.

Read-only. Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_near_actors.py \
    -unattended -nopause -nosplash
Env: BIOSHOCK_NEAR_MAP (default /Game/BioShockSlice/1-Medical)
     BIOSHOCK_NEAR_RADIUS (default 1200 uu around the first PlayerStart)
"""

from __future__ import annotations

import json
import os

import unreal

MAP = os.environ.get("BIOSHOCK_NEAR_MAP", "/Game/BioShockSlice/1-Medical")
RADIUS = float(os.environ.get("BIOSHOCK_NEAR_RADIUS", "1200"))
OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "_reports", "probe_near_actors.json")


def _materials(actor):
    out = []
    for comp in actor.get_components_by_class(unreal.MeshComponent):
        for i in range(comp.get_num_materials()):
            mat = comp.get_material(i)
            if mat is None:
                out.append("<empty>")
                continue
            entry = {"name": mat.get_name()}
            base = mat
            if isinstance(mat, unreal.MaterialInstance):
                parent = mat.get_editor_property("parent")
                if parent is not None:
                    base = parent
            try:
                entry["blend"] = str(base.get_editor_property("blend_mode"))
            except Exception:  # noqa: BLE001
                pass
            out.append(entry)
    return out


def _collision(actor):
    states = set()
    for comp in actor.get_components_by_class(unreal.PrimitiveComponent):
        try:
            states.add(str(comp.get_editor_property("collision_enabled")))
        except Exception:  # noqa: BLE001
            states.add("unreadable")
    return sorted(states)


def main():
    report = {"map": MAP, "radius": RADIUS, "error": None}
    if not unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(MAP):
        report["error"] = "could not load %s" % MAP
        _write(report)
        raise RuntimeError(report["error"])

    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()

    start = None
    for actor in actors:
        if isinstance(actor, unreal.PlayerStart):
            start = actor.get_actor_location()
            break
    if start is None:
        report["error"] = "no PlayerStart"
        _write(report)
        raise RuntimeError(report["error"])
    report["playerStart"] = [round(start.x, 1), round(start.y, 1), round(start.z, 1)]

    rows = []
    for actor in actors:
        if not actor.get_components_by_class(unreal.MeshComponent):
            continue
        origin, extent = actor.get_actor_bounds(only_colliding_components=False)
        delta = origin - start
        distance = float(delta.length())
        if distance > RADIUS:
            continue

        dims = sorted([extent.x, extent.y, extent.z])
        # Flatness: smallest half-extent over largest. A pane is ~0; a crate is ~1. This is the
        # discriminator that matters - the thing being hunted is big in two axes and thin in one.
        flatness = (dims[0] / dims[2]) if dims[2] > 0.001 else 1.0
        rows.append({
            "label": actor.get_actor_label(),
            "class": type(actor).__name__,
            "distance": round(distance, 1),
            "extent": [round(extent.x, 1), round(extent.y, 1), round(extent.z, 1)],
            # Frontal area of the two largest axes: how much of the view it could fill.
            "frontalArea": round(dims[2] * dims[1] * 4.0, 0),
            "flatness": round(flatness, 3),
            "collision": _collision(actor),
            "materials": _materials(actor),
        })

    rows.sort(key=lambda r: -r["frontalArea"])
    report["actorsNearStart"] = len(rows)
    report["top"] = rows[:25]

    # The specific shape of the suspect, called out so it is not lost in a 25-row list.
    report["flatTranslucentNoCollision"] = [
        r for r in rows
        if r["flatness"] < 0.15
        and any(isinstance(m, dict) and "TRANSLUCENT" in str(m.get("blend", "")).upper()
                for m in r["materials"])
    ]
    report["noCollisionLargeFlat"] = [
        r for r in rows
        if r["flatness"] < 0.15 and r["collision"] == ["CollisionEnabled.NO_COLLISION"]
    ]

    _write(report)
    unreal.log("[near] near=%d flatTranslucent=%d noCollisionFlat=%d" % (
        report["actorsNearStart"], len(report["flatTranslucentNoCollision"]),
        len(report["noCollisionLargeFlat"])))
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
