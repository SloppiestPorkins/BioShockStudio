"""Load the slice level, find the compiled-world actor, trace rays outward from interior points
until one hits the compiled-world mesh, and print a camera position 160 cm off that face plus a
look-at point. Feed the pair to capture_shot as -bioshockshotabs / -bioshockshotlook.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/find_bsp_wall_camera.py \
    -unattended -nopause -nosplash -nullrhi
"""
import os, json, random, unreal

LEVEL = "/Game/BioShockSlice/1-Medical"
OUT = os.path.join(os.environ["TEMP"], "bsp_wall_camera.json")

unreal.EditorLoadingAndSavingUtils.load_map(LEVEL)
syslib = unreal.SystemLibrary
world = unreal.EditorLevelLibrary.get_editor_world()

comp = None
owner = None
for a in unreal.EditorLevelLibrary.get_all_level_actors():
    for c in a.get_components_by_class(unreal.StaticMeshComponent):
        sm = c.get_editor_property("static_mesh")
        if sm and "Model1_20761" in sm.get_path_name():
            comp = c
            owner = a
            break
    if comp:
        break

res = {"found": False}
if comp is None:
    res["error"] = "compiled-world component not found"
else:
    origin, extent = owner.get_actor_bounds(False)
    res["bounds_origin"] = [origin.x, origin.y, origin.z]
    res["bounds_extent"] = [extent.x, extent.y, extent.z]

    random.seed(1)
    dirs = [unreal.Vector(1, 0, 0), unreal.Vector(-1, 0, 0),
            unreal.Vector(0, 1, 0), unreal.Vector(0, -1, 0)]
    hits = []
    for _ in range(1500):
        p = unreal.Vector(
            origin.x + random.uniform(-0.75, 0.75) * extent.x,
            origin.y + random.uniform(-0.75, 0.75) * extent.y,
            origin.z + random.uniform(-0.3, 0.3) * extent.z)
        for d in dirs:
            end = unreal.Vector(p.x + d.x * 6000, p.y + d.y * 6000, p.z + d.z * 6000)
            hr = syslib.line_trace_single_by_profile(
                world, p, end, "BlockAll", False, [], unreal.DrawDebugTrace.NONE, True)
            if hr is None:
                continue
            if not hr.get_editor_property("blocking_hit"):
                continue
            ch = hr.get_editor_property("component")
            if ch is None or "Model1_20761" not in str(ch.get_path_name()):
                continue
            loc = hr.get_editor_property("location")
            nrm = hr.get_editor_property("impact_normal")
            dist = ((loc.x - p.x) ** 2 + (loc.y - p.y) ** 2 + (loc.z - p.z) ** 2) ** 0.5
            if 150 < dist < 3000:
                hits.append((dist, [loc.x, loc.y, loc.z], [nrm.x, nrm.y, nrm.z]))

    res["candidates"] = len(hits)
    if hits:
        # a mid-range hit: close enough to fill the frame, far enough the camera clears the wall
        hits.sort()
        pick = hits[len(hits) // 2]
        dist, loc, nrm = pick
        cam = [loc[0] + nrm[0] * 160, loc[1] + nrm[1] * 160, loc[2] + nrm[2] * 160]
        res.update(found=True, wall_hit=loc, wall_normal=nrm, camera=cam, look_at=loc, hit_dist=dist)

with open(OUT, "w") as h:
    json.dump(res, h, indent=2, default=str)
unreal.log("[bsp-wall-cam] " + json.dumps(res, default=str)[:800])
