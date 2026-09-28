"""One-off: dump collision bounds for the w21 in-scope interact-trace failures.

Loads /Game/BioShockSlice/1-Medical, reads %TEMP%/interact_trace_report.json's
result.traceHits, and for every wrong_mesh_or_blocker / no_hit row (wrong_interactable
is out of scope) records:

  * target actor location + collision-only get_actor_bounds
  * for wrong_mesh_or_blocker, the named hitActor's location + collision bounds
  * AABB overlap depths on XYZ (positive = overlapping on that axis)
  * stand= / awayDegenerate= echoed from the report for no_hit diagnosis

Write-only diagnostic — does not move actors. Output: %TEMP%/w21_interact_fail_bounds.json

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/dump_interact_fail_bounds.py \
    -unattended -nopause -nosplash
"""
from __future__ import annotations

import json
import os

import unreal

MAP = os.environ.get("BIOSHOCK_CLEAR_MAP", "/Game/BioShockSlice/1-Medical")
REPORT_IN = os.path.join(os.environ.get("TEMP", "."), "interact_trace_report.json")
OUT = os.path.join(os.environ.get("TEMP", "."), "w21_interact_fail_bounds.json")


def _vec(v):
    return [round(float(v.x), 3), round(float(v.y), 3), round(float(v.z), 3)]


def _bounds(actor):
    if actor is None:
        return None
    origin, extent = actor.get_actor_bounds(True)
    loc = actor.get_actor_location()
    return {
        "label": actor.get_actor_label(),
        "class": actor.get_class().get_name(),
        "location": _vec(loc),
        "boundsOrigin": _vec(origin),
        "boundsExtent": _vec(extent),
    }


def _overlap_depths(a, b):
    if not a or not b:
        return None
    o1, e1 = a["boundsOrigin"], a["boundsExtent"]
    o2, e2 = b["boundsOrigin"], b["boundsExtent"]
    depths = []
    for i in range(3):
        a_min, a_max = o1[i] - e1[i], o1[i] + e1[i]
        b_min, b_max = o2[i] - e2[i], o2[i] + e2[i]
        depths.append(round(min(a_max, b_max) - max(a_min, b_min), 3))
    overlapping = all(d > 0.0 for d in depths)
    return {
        "depthsXYZ": depths,
        "minDepth": round(min(depths), 3),
        "overlapping": overlapping,
        "shortestAxis": "xyz"[depths.index(min(depths))] if overlapping else None,
    }


def _index_by_label(actors):
    # The interact-trace report's target/hitActor names come from C++ GetName() (the object's
    # internal name), not the World Outliner display label -- these can differ for BioShock-
    # imported actors (confirmed during z1's landing pass, same session). Index by get_name().
    by_label = {}
    for actor in actors:
        name = actor.get_name()
        if name:
            by_label[name] = actor
    return by_label


def main():
    report = {"map": MAP, "sourceReport": REPORT_IN, "cases": [], "error": None}
    if not os.path.isfile(REPORT_IN):
        report["error"] = "missing %s — run run_verify_interact_trace.py first" % REPORT_IN
        with open(OUT, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)
        raise RuntimeError(report["error"])

    raw = json.load(open(REPORT_IN, encoding="utf-8"))
    hits = (raw.get("result") or {}).get("traceHits") or []
    inscope = [
        h for h in hits
        if h.get("classification") in ("wrong_mesh_or_blocker", "no_hit")
    ]
    report["traceHitClasses"] = (raw.get("result") or {}).get("traceHitClasses")
    report["inScopeCount"] = len(inscope)

    if not unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(MAP):
        report["error"] = "could not load %s" % MAP
        with open(OUT, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)
        raise RuntimeError(report["error"])

    by_label = _index_by_label(
        unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors())

    for hit in inscope:
        target_name = hit.get("target") or ""
        target_actor = by_label.get(target_name)
        target_bounds = _bounds(target_actor)
        hit_name = hit.get("hitActor")
        hit_bounds = None
        overlap = None
        if hit.get("classification") == "wrong_mesh_or_blocker" and hit_name and hit_name != "None":
            hit_bounds = _bounds(by_label.get(hit_name))
            overlap = _overlap_depths(target_bounds, hit_bounds)
        report["cases"].append({
            "kind": hit.get("kind"),
            "classification": hit.get("classification"),
            "target": target_name,
            "hitActor": hit_name,
            "hitDist": hit.get("hitDist"),
            "standToTarget": hit.get("standToTarget"),
            "awayDegenerate": hit.get("awayDegenerate"),
            "stand": hit.get("stand"),
            "targetAim": hit.get("targetAim"),
            "targetFound": target_actor is not None,
            "targetBounds": target_bounds,
            "hitActorBounds": hit_bounds,
            "overlap": overlap,
        })

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[w21-dump] wrote %d cases to %s" % (len(report["cases"]), OUT))
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
