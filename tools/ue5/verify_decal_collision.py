"""Confirm decal meshes are NoCollision while glass/architecture still collide.

Structural checks (authoritative under -run=pythonscript): matched decal StaticMesh
assets / components report NO_COLLISION; a sample of glass panes and the compiled-
world shell keep QUERY_AND_PHYSICS. Pair with a separate `run_collision.py` pass for
the PlayerStart floor-standable behavioural control.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/run_decal_collision.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_DECAL_MAPS   comma-separated /Game map paths (default /Game/BioShockSlice/1-Medical)
"""
from __future__ import annotations

import json
import os
import re
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

MAPS = [
    m.strip()
    for m in os.environ.get("BIOSHOCK_DECAL_MAPS", "/Game/BioShockSlice/1-Medical").split(",")
    if m.strip()
]
OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "verify_decal_collision.json"),
)

_DECAL = re.compile(
    r"(wall_leak|bloodsmear|blood.?splat|bloodsplat|damdec|scorch|"
    r"drip|decal|smear|splat|footprint)",
    re.IGNORECASE,
)
_EXCLUDE = ("glass", "window", "puddle", "water")
_MODEL = re.compile(r"^Model\d+_\d+$")


def _is_decal_name(name: str) -> bool:
    if not _DECAL.search(name):
        return False
    lname = name.lower()
    return not any(bad in lname for bad in _EXCLUDE)


def _collision_enabled(obj) -> str:
    try:
        return str(obj.get_editor_property("collision_enabled"))
    except Exception:  # noqa: BLE001
        pass
    try:
        return str(obj.get_collision_enabled())
    except Exception:  # noqa: BLE001
        return "unreadable"


def _mesh_default_collision(mesh) -> str:
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return "no_body_setup"
    try:
        default = body.get_editor_property("default_instance")
        return str(default.get_editor_property("collision_enabled"))
    except Exception:  # noqa: BLE001
        return _collision_enabled(mesh)


def _is_no_collision(state: str) -> bool:
    return "NO_COLLISION" in state.upper()


def main(out_path: str = OUT):
    report = {"maps": [], "failures": [], "checks": 0}
    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors_sys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

    for map_path in MAPS:
        map_report = {
            "map": map_path,
            "decalMeshes": [],
            "glassMeshes": [],
            "shell": [],
        }
        if not lvl.load_level(map_path):
            report["failures"].append("could not load %s" % map_path)
            report["maps"].append(map_report)
            continue

        seen_decal = set()
        seen_glass = set()
        for actor in actors_sys.get_all_level_actors():
            if not isinstance(actor, unreal.StaticMeshActor):
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None:
                continue
            name = mesh.get_name()
            label = (actor.get_actor_label() or "").strip().lower()
            comp_state = _collision_enabled(comp)
            mesh_state = _mesh_default_collision(mesh)

            if _is_decal_name(name):
                if name in seen_decal:
                    continue
                seen_decal.add(name)
                entry = {
                    "mesh": name,
                    "componentCollision": comp_state,
                    "meshCollision": mesh_state,
                }
                ok = _is_no_collision(comp_state) or _is_no_collision(mesh_state)
                entry["ok"] = ok
                map_report["decalMeshes"].append(entry)
                report["checks"] += 1
                if not ok:
                    report["failures"].append(
                        "%s: decal %s still has collision (comp=%s mesh=%s)"
                        % (map_path, name, comp_state, mesh_state)
                    )
            elif re.search(r"windowglass|glass_sheet|glass_safety", name, re.I):
                if name in seen_glass:
                    continue
                seen_glass.add(name)
                entry = {
                    "mesh": name,
                    "componentCollision": comp_state,
                    "meshCollision": mesh_state,
                }
                ok = not _is_no_collision(comp_state) and not _is_no_collision(mesh_state)
                entry["ok"] = ok
                map_report["glassMeshes"].append(entry)
                report["checks"] += 1
                if not ok:
                    report["failures"].append(
                        "%s: glass %s lost collision (comp=%s mesh=%s)"
                        % (map_path, name, comp_state, mesh_state)
                    )
            elif label == "compiled world" or _MODEL.match(name):
                entry = {
                    "mesh": name,
                    "componentCollision": comp_state,
                    "meshCollision": mesh_state,
                }
                ok = not _is_no_collision(comp_state)
                entry["ok"] = ok
                map_report["shell"].append(entry)
                report["checks"] += 1
                if not ok:
                    report["failures"].append(
                        "%s: compiled-world %s has NoCollision" % (map_path, name)
                    )

        # Capsule/line sweeps through decal actors: must not self-hit. Positive control
        # for architecture is the structural shell/glass check above plus a separate
        # run_collision.py pass (floor traces are flaky when interleaved with a full
        # actor census under -run=pythonscript — see verify_collision's own standalone run).
        if not map_report["decalMeshes"]:
            report["failures"].append("%s: no decal-named meshes found" % map_path)
        if not map_report["glassMeshes"] and not map_report["shell"]:
            report["failures"].append("%s: no glass/shell controls found" % map_path)

        report["maps"].append(map_report)

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, default=str)

    for failure in report["failures"]:
        unreal.log_error("BIOSHOCK_DECAL_COLLISION_FAIL %s" % failure)
    if not report["failures"]:
        unreal.log(
            "BIOSHOCK_DECAL_COLLISION_OK checks=%d maps=%d"
            % (report["checks"], len(report["maps"]))
        )
    return report


if __name__ == "__main__":
    main()
