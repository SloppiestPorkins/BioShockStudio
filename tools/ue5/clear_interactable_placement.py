"""Nudge specific 1-Medical interactables clear of a flush-overlapping static mesh.

w19 confirmed ShockConsumablePickup_12's 48uu Visibility sphere overlaps shelf
StaticMeshActor_1517 by ~8.5uu (sphere top Z≈8143, shelf underside Z≈8142.5, measured
precisely via get_actor_bounds in the w21 landing pass). A dead-center interact trace still
grazes the shelf. That is content placement, not a harness bug — see
docs/research/w19-remaining-interact-fails.md §6b/§6d and
docs/research/w21-interact-trace-placement-nudge.md.

w21's first draft scanned every placed interactable against every nearby StaticMeshActor and
flagged ANY AABB overlap in a small band as fixable. Running it (dry-run) found 137/212
interactables "overlapping" something -- almost all false positives: normal close-together
loot placement (items sitting near each other on a shelf/table is completely ordinary scene
composition, not a bug) and ~33 cases where a stale duplicate StaticMeshActor ghost shares the
exact same label as the real pickup (a pre-existing, previously-undiscovered import-hygiene
issue, out of scope for this task -- flagged separately). None of that noise corresponds to an
actual interact-trace failure; only 29 specific actors ever failed the verify.

So this pass is deliberately narrow: it only nudges the handful of actors from the
BIOSHOCK_INTERACT_TRACE_HIT report that (a) classify as wrong_mesh_or_blocker and (b) measure a
genuine flush overlap (EPS, MAX_FIXABLE_OVERLAP] against their OWN reported hitActor specifically
-- not "any nearby StaticMeshActor". A general whole-level clearance pass is not built here; the
risk of moving correctly-placed loot outweighs the benefit for content this narrow.

Env: BIOSHOCK_CLEAR_PLACEMENT_DRY=1 to report without moving.
"""
from __future__ import annotations

import json
import os

import unreal

SLICE_MAP = "/Game/BioShockSlice/1-Medical"
OUT = os.path.join(os.environ.get("TEMP", "."), "clear_interactable_placement.json")
REPORT_IN = os.path.join(os.environ.get("TEMP", "."), "interact_trace_report.json")

# Overlap deeper than this (uu) is treated as real, not float noise.
EPS = 0.5
# Only the flush-graze band. Deeper embeds (stacked loot, corpses, world hulls) are a different
# class of failure and are not touched here. Measured real data (w21 landing) put the confirmed
# flagship case (ShockConsumablePickup_12 vs StaticMeshActor_1517) at 8.544uu; the smallest real
# deep overlap in the same dataset was 24.678uu, so 12.0 keeps clear margin on both sides.
MAX_FIXABLE_OVERLAP = 12.0
# Separate by this much past zero-overlap so a re-probe cannot re-graze.
CLEARANCE = 2.0


def _vec_tuple(v):
    return (float(v.x), float(v.y), float(v.z))


def _bounds(actor):
    origin, extent = actor.get_actor_bounds(True)
    return _vec_tuple(origin), _vec_tuple(extent)


def _aabb_overlap_depths(o1, e1, o2, e2):
    depths = []
    for i in range(3):
        a_min, a_max = o1[i] - e1[i], o1[i] + e1[i]
        b_min, b_max = o2[i] - e2[i], o2[i] + e2[i]
        depths.append(min(a_max, b_max) - max(a_min, b_min))
    return depths


def _index_by_name(actors):
    # The interact-trace report's target/hitActor names come from C++ GetName() (the object's
    # internal name), not the World Outliner display label -- confirmed different during z1's
    # landing pass, same session. Index by get_name(), not get_actor_label().
    return {a.get_name(): a for a in actors if a.get_name()}


def _candidate_cases():
    """Read the live interact-trace report and return the wrong_mesh_or_blocker rows."""
    if not os.path.isfile(REPORT_IN):
        return []
    raw = json.load(open(REPORT_IN, encoding="utf-8"))
    hits = (raw.get("result") or {}).get("traceHits") or []
    return [h for h in hits if h.get("classification") == "wrong_mesh_or_blocker"]


def clear_overlaps(map_path=SLICE_MAP, save=False, dry_run=None, reload_map=True):
    """Nudge only the actors named in the live interact-trace report's wrong_mesh_or_blocker
    rows, and only when they measure a genuine flush overlap against their own reported
    hitActor. Returns a report dict."""
    if dry_run is None:
        dry_run = os.environ.get("BIOSHOCK_CLEAR_PLACEMENT_DRY", "").strip() in ("1", "true", "True")

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if reload_map:
        if not level.load_level(map_path):
            raise RuntimeError("could not load %s" % map_path)

    cases = _candidate_cases()
    by_name = _index_by_name(
        unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors())

    report = {
        "map": map_path,
        "dryRun": dry_run,
        "eps": EPS,
        "maxFixableOverlap": MAX_FIXABLE_OVERLAP,
        "clearance": CLEARANCE,
        "casesConsidered": len(cases),
        "nudged": [],
        "skipped": [],
    }

    for case in cases:
        target_name = case.get("target") or ""
        hit_name = case.get("hitActor") or ""
        actor = by_name.get(target_name)
        blocker = by_name.get(hit_name)
        if not actor or not blocker or actor == blocker:
            report["skipped"].append({"target": target_name, "hitActor": hit_name, "reason": "actor-not-found"})
            continue

        a_origin, a_extent = _bounds(actor)
        b_origin, b_extent = _bounds(blocker)
        depths = _aabb_overlap_depths(a_origin, a_extent, b_origin, b_extent)
        if any(d <= 0.0 for d in depths):
            report["skipped"].append({"target": target_name, "hitActor": hit_name, "reason": "no-aabb-overlap"})
            continue
        overlap = min(depths)
        if overlap <= EPS or overlap > MAX_FIXABLE_OVERLAP:
            report["skipped"].append({
                "target": target_name, "hitActor": hit_name, "reason": "overlap-out-of-band",
                "overlap": round(overlap, 3),
            })
            continue

        axis = depths.index(overlap)
        direction = 1.0 if a_origin[axis] >= b_origin[axis] else -1.0
        delta = [0.0, 0.0, 0.0]
        delta[axis] = direction * (overlap + CLEARANCE)

        loc = actor.get_actor_location()
        new_loc = unreal.Vector(loc.x + delta[0], loc.y + delta[1], loc.z + delta[2])
        entry = {
            "actor": target_name,
            "class": actor.get_class().get_name(),
            "blocker": hit_name,
            "axis": "xyz"[axis],
            "overlap": round(overlap, 3),
            "delta": [round(c, 3) for c in delta],
            "from": [round(loc.x, 3), round(loc.y, 3), round(loc.z, 3)],
            "to": [round(new_loc.x, 3), round(new_loc.y, 3), round(new_loc.z, 3)],
        }
        if not dry_run:
            actor.set_actor_location(new_loc, False, False)
        report["nudged"].append(entry)

    if save and not dry_run and report["nudged"]:
        level.save_current_level()

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[clear-placement] nudged=%d skipped=%d considered=%d dry=%s" % (
        len(report["nudged"]), len(report["skipped"]), len(cases), dry_run))
    return report


def main(map_path=SLICE_MAP, save=True):
    return clear_overlaps(map_path=map_path, save=save)


if __name__ == "__main__":
    main()
