"""List the actors near a point in a live map copy, with mesh, materials and visibility - to find
what draws an unexpected surface in a live capture.

Env: BIOSHOCK_MAP (via live_paths), PROBE_AT="x,y,z" (game/UE units), PROBE_RADIUS (default 400).
Run: python tools/ue5/ue_run.py tools/ue5/probe_actors_near.py --env PROBE_AT=-17320,2150,7900

Pipeline: diagnostic -- live-renderer map copies.
"""
import json
import os
import sys

import unreal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import live_paths  # noqa: E402

at = unreal.Vector(*[float(v) for v in os.environ.get("PROBE_AT", "0,0,0").split(",")])
radius = float(os.environ.get("PROBE_RADIUS", "400"))
level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
if not level.load_level(live_paths.live_map()):
    raise RuntimeError("could not load %s" % live_paths.live_map())
rows = []
for a in actors.get_all_level_actors():
    origin, extent = a.get_actor_bounds(False)
    # distance from the probe point to the actor's bounds box
    d = [max(abs(origin.x - at.x) - extent.x, 0), max(abs(origin.y - at.y) - extent.y, 0), max(abs(origin.z - at.z) - extent.z, 0)]
    dist = (d[0] ** 2 + d[1] ** 2 + d[2] ** 2) ** 0.5
    if dist > radius:
        continue
    for comp in a.get_components_by_class(unreal.PrimitiveComponent):
        mesh = None
        if isinstance(comp, unreal.StaticMeshComponent) and comp.static_mesh:
            mesh = comp.static_mesh.get_path_name()
        mats = [m.get_path_name() if m else "None" for m in comp.get_materials()] if hasattr(comp, "get_materials") else []
        rows.append({"actor": a.get_actor_label(), "class": a.get_class().get_name(), "comp": comp.get_name(),
                     "dist": round(dist), "visible": bool(comp.is_visible()), "hiddenInGame": bool(comp.get_editor_property("hidden_in_game")),
                     "mesh": mesh, "materials": mats[:6], "extent": [round(extent.x), round(extent.y), round(extent.z)]})
rows.sort(key=lambda r: r["dist"])
out = os.path.join(os.environ.get("TEMP", "."), "probe_actors_near.json")
json.dump(rows, open(out, "w"), indent=1)
unreal.log("PROBE_NEAR %d components within %d of %s -> %s" % (len(rows), radius, os.environ.get("PROBE_AT"), out))
