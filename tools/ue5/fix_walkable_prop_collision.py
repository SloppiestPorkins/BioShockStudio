"""Set complex-as-simple collision on walkable-architecture static mesh props (tunnels,
corridors, stairs, doorways, rooms) — the same fix already applied to the compiled-world
shell (fix_compiled_world_collision.py) and confirmed by hand on "loadroom" (4 Sept 2026,
user: "i did it to the loadroom and i can actually walk in there now").

Deliberately NOT applied to every static mesh in the project. A convex hull is the
correct, cheap collision for small/decorative props (barrels, signs, tables, pillars,
ad frames — see verify_collision.py's own docstring); complex-as-simple is for large,
often-concave pieces the player actually walks through, and only works on Static
mobility in Chaos (see h11 in tools/agents/tasks/).

Candidates are chosen by name (word-boundary match against a walkable-architecture
keyword list) AND a minimum bounding-box size, so a small prop that happens to share a
keyword substring (e.g. "medical_sign_room2" containing "room") doesn't get swept in
alongside genuinely room-scale geometry like "loadroom".

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/fix_walkable_prop_collision.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_WALKABLE_MAPS   comma-separated /Game map paths (default /Game/BioShockSlice/1-Medical)
  BIOSHOCK_WALKABLE_DRY    "1" to report candidates without changing anything
  BIOSHOCK_WALKABLE_MIN_SIZE   minimum bounding-box largest dimension in uu (default 300 = 3m)

Pipeline: retired -- superseded by fix_all_complex_collision (in STEPS), which applies complex-
as-simple to every slice mesh.
"""
import json, os, re, sys
import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from fix_compiled_world_collision import _use_complex_collision, _ensure_static_mobility

MAPS = [m.strip() for m in os.environ.get(
    "BIOSHOCK_WALKABLE_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if m.strip()]
DRY = os.environ.get("BIOSHOCK_WALKABLE_DRY", "0") == "1"
MIN_SIZE = float(os.environ.get("BIOSHOCK_WALKABLE_MIN_SIZE", "300"))
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_walkable_prop_collision.json")

# Substring, case-insensitive — NOT word-boundary: "loadroom" (the confirmed working
# case) is one compound token with no internal boundary between "load" and "room", so
# \bword\b would never match it. False positives from this looseness are caught by
# _EXCLUDE_SUBSTR below and the minimum-size filter, not by tightening the boundary.
_KEYWORDS = re.compile(
    r"(tunnel|corridor|stairs?|door|hallway|room|ramp|walkway|catwalk|bridge|"
    r"elevator|lift|platform|passage|archway)",
    re.IGNORECASE,
)
# Explicit excludes: names that would keyword-match but are decorative, not architecture
# (a sign naming a room is not the room). Extend this list rather than tightening the
# keyword regex if another false positive turns up.
_EXCLUDE_SUBSTR = ("sign",)


def _matches(name):
    if not _KEYWORDS.search(name):
        return False
    lname = name.lower()
    return not any(bad in lname for bad in _EXCLUDE_SUBSTR)


def main():
    report = {"maps": [], "minSize": MIN_SIZE, "dryRun": DRY}
    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors_sys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

    for map_path in MAPS:
        entry = {"map": map_path, "candidates": [], "fixed": [], "skippedSize": []}
        if not lvl.load_level(map_path):
            entry["error"] = "could not load"
            report["maps"].append(entry)
            continue

        seen_meshes = set()
        for actor in actors_sys.get_all_level_actors():
            if not isinstance(actor, unreal.StaticMeshActor):
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None:
                continue
            name = mesh.get_name()
            if not _matches(name):
                continue

            origin, box_extent = actor.get_actor_bounds(False)
            largest_dim = 2.0 * max(box_extent.x, box_extent.y, box_extent.z)
            item = {
                "actor": actor.get_actor_label(),
                "mesh": name,
                "largestDim": largest_dim,
            }
            if largest_dim < MIN_SIZE:
                item["status"] = "skipped_too_small"
                entry["skippedSize"].append(item)
                continue

            entry["candidates"].append(item)
            if mesh.get_name() in seen_meshes:
                item["status"] = "already_done_this_run" if not DRY else "would_fix_dup"
                continue
            seen_meshes.add(mesh.get_name())

            if DRY:
                item["status"] = "would_fix"
                continue

            ok = _use_complex_collision(mesh)
            restored = _ensure_static_mobility(comp)
            if ok:
                unreal.EditorAssetLibrary.save_loaded_asset(mesh)
            item["status"] = "fixed"
            item["ok"] = ok
            item["restoredStatic"] = restored
            entry["fixed"].append(item)

        if not DRY and entry["fixed"]:
            lvl.save_current_level()
        report["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as h:
        json.dump(report, h, indent=2, default=str)
    unreal.log("[walkable-collision-fix] wrote " + OUT)
    return report


if __name__ == "__main__":
    main()
