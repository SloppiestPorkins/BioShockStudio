"""Set complex-as-simple collision on the compiled-world mesh(es) already in a map, and clear
any auto-generated convex/box/sphere primitives left over from a plain OBJ reimport.

Standalone from fix_compiled_world_materials.py's own _use_complex_collision (same fix, same
reasoning) because that script's main() also touches materials, which isn't wanted for a
collision-only repair after reimport_compiled_world_only.py regressed this again (4 Sept 2026 --
see verify_collision.py's docstring for the original incident this fix pattern comes from).

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/fix_compiled_world_collision.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_COLLISION_MAPS   comma-separated /Game map paths (default /Game/BioShockSlice/1-Medical)
"""
import json, os, re
import unreal

MAPS = [m.strip() for m in os.environ.get(
    "BIOSHOCK_COLLISION_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if m.strip()]
OUT = os.path.join(os.environ.get("TEMP", "."), "fix_compiled_world_collision.json")
_MODEL_ASSET = re.compile(r"^Model\d+_\d+$")


def _use_complex_collision(mesh):
    body = mesh.get_editor_property("body_setup")
    if body is None:
        return False
    body.set_editor_property(
        "collision_trace_flag", unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
    try:
        agg = body.get_editor_property("agg_geom")
        agg.set_editor_property("convex_elems", [])
        agg.set_editor_property("box_elems", [])
        agg.set_editor_property("sphere_elems", [])
        body.set_editor_property("agg_geom", agg)
    except Exception as exc:  # noqa: BLE001
        unreal.log_warning("[cw-collision-fix] could not clear simple collision: %s" % exc)
    return True


def _ensure_static_mobility(comp):
    """Complex-as-simple only works for Static mobility (Chaos)."""
    if comp is None:
        return False
    if comp.get_editor_property("mobility") == unreal.ComponentMobility.STATIC:
        return False
    comp.set_editor_property("mobility", unreal.ComponentMobility.STATIC)
    return True


def main():
    report = {"maps": []}
    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors_sys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

    for map_path in MAPS:
        entry = {"map": map_path, "fixed": []}
        if not lvl.load_level(map_path):
            entry["error"] = "could not load"
            report["maps"].append(entry)
            continue

        for actor in actors_sys.get_all_level_actors():
            if not isinstance(actor, unreal.StaticMeshActor):
                continue
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
            if mesh is None:
                continue
            label = (actor.get_actor_label() or "").strip().lower()
            name = mesh.get_name()
            if label != "compiled world" and not _MODEL_ASSET.match(name):
                continue
            ok = _use_complex_collision(mesh)
            restored = _ensure_static_mobility(comp)
            if ok:
                unreal.EditorAssetLibrary.save_loaded_asset(mesh)
            entry["fixed"].append({
                "actor": actor.get_actor_label(),
                "mesh": name,
                "ok": ok,
                "restoredStatic": restored,
            })

        lvl.save_current_level()
        report["maps"].append(entry)

    with open(OUT, "w", encoding="utf-8") as h:
        json.dump(report, h, indent=2)
    unreal.log("[cw-collision-fix] wrote " + OUT)
    return report


if __name__ == "__main__":
    main()
