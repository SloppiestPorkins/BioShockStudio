#!/usr/bin/env python3
"""Query a level manifest (<map>.ue5-level.json) instead of hand-writing json.load one-liners.

By 3 Oct 2026 the manifest had been probed with 315 hand-typed `python -c "json.load(...)"`
commands, 14 of which failed: UnicodeDecodeError from not opening the file as utf-8 (Windows
defaults to cp1252), KeyError on guessed field names, and 47 re-probes of `.keys()` because
nobody remembered the schema. This reads the file once, always as utf-8, never indexes a field
it has not checked exists, and prints the schema from the real file so no doc can go stale.

    python tools/manifest_query.py [--map 1-Medical | --manifest PATH] <command> ...

    schema [ARRAY] [--depth N]   top-level keys; for each array, its items' keys, value types
                                 and how many items carry each key (ARRAY alone goes deeper)
    hist [--by FIELD]            actors counted by className (or any dotted FIELD)
    class NAME [--fields a,b]    actors of one class: key, label, UE location, plus fields
                                 (dotted paths such as door.locked; a missing field prints "-")
    find SUBSTR                  actors whose key/name/label/className/mesh asset contains it
    near X Y Z [--radius 1500] [--space ue|manifest]
                                 actors and placed instances within R, nearest first. X Y Z may
                                 be pasted straight from the UE details panel ("X=-17018 Y=...")
    actor KEY_OR_LABEL [--brief] full record(s), pretty; matches key, then label, then name.
                                 --brief drops the raw property hex and trailer
    assets SUBSTR                assets whose key/name/file contains it, with placement counts
    mesh NAME                    which actors/instances place a mesh, and their material overrides

Options valid before or after the command: --map NAME (default 1-Medical), --manifest PATH,
--json (raw records instead of a table), --limit N (rows, default 100, 0 = all).
Default manifest: C:/Users/Jack/Documents/BioShockUE5/Exports/slice/<map>/<map>.ue5-level.json.

Coordinate spaces (two are mixed in one file, which is why `near` needs --space)
------------------------------------------------------------------------------
The manifest's own basis (its "basis" field) is right-handed, +X forward, +Y left, +Z up,
centimetres. Unreal is left-handed, +Y right. Measured in the UE editor (30 Sept 2026), five
Light_Beams actors sit at
    (-17018, 1322, 7508) (-17289, 1246, 7687) (-17277, 1465, 7699)
    (-25232, 1120, 8064) (-31896, 1887, 8356)
and the manifest's instances of StaticMesh_Light_Beams_4400 carry translations
(transform[12:15], row-vector matrix) of
    (-17018, -1322, 7508) (-17289, -1246, 7687) (-17277, -1465, 7699)
    (-25232, -1120, 8064) (-31896, -1887, 8356)
(actors StaticMeshActor2111/2099/2098/3787/3600). All five agree exactly with X and Z unchanged
and Y negated - no scale, no offset - so

    UE = (mx, -my, mz)        manifest = (ux, -uy, uz)

That applies to instances[].transform, lights[].location and boundsMin/boundsMax. But
actors[].location is NOT in manifest space: it is the source engine's own (UE2, left-handed)
value, already equal to UE - StaticMeshActor2111's is (-17017.5, 1322.4, 7508). So actors are
used as-is and only instances are flipped. Brush/volume instances differ from their actor's
location by the prePivot; `near` lists those instances separately, and drops instances that sit
on their actor's location so each placement appears once. All locations printed are UE space.
"""

from __future__ import annotations

import argparse
import difflib
import json
import math
import re
import sys
from collections import Counter
from pathlib import Path

EXPORT_ROOT = Path("C:/Users/Jack/Documents/BioShockUE5/Exports/slice")
DEFAULT_MAP = "1-Medical"
DEFAULT_LIMIT = 100
DEFAULT_RADIUS = 1500.0
CELL_WIDTH = 60
# An instance closer than this to its actor's location is the same placement, not a second one.
SAME_PLACEMENT_CM = 1.0
BULKY_KEYS = ("properties", "trailerHex")
# Which coordinate space each position field is in (derivation in the module docstring).
SPACE_NOTES = {
    "actors.location": "UE space (as shown in the editor)",
    "instances.transform": "manifest space; translation = [12:15], UE = (x, -y, z)",
    "lights.location": "manifest space; UE = (x, -y, z)",
    "boundsMin": "manifest space",
    "boundsMax": "manifest space",
}


# --- loading -----------------------------------------------------------------------------------

def manifest_path(map_name: str | None, manifest: str | None) -> Path:
    if manifest:
        return Path(manifest)
    name = map_name or DEFAULT_MAP
    return EXPORT_ROOT / name / ("%s.ue5-level.json" % name)


def load_manifest(path: Path) -> dict:
    if not path.is_file():
        raise SystemExit("manifest not found: %s" % path)
    with open(path, "r", encoding="utf-8") as handle:
        document = json.load(handle)
    if not isinstance(document, dict):
        raise SystemExit("%s is not a level manifest (top level is %s, not an object)"
                         % (path, type(document).__name__))
    return document


def array(document: dict, name: str) -> list:
    value = document.get(name)
    return value if isinstance(value, list) else []


# --- coordinates -------------------------------------------------------------------------------

def manifest_to_ue(point) -> tuple[float, float, float]:
    return (float(point[0]), -float(point[1]), float(point[2]))


def ue_to_manifest(point) -> tuple[float, float, float]:
    return (float(point[0]), -float(point[1]), float(point[2]))


def actor_ue_location(actor: dict):
    location = actor.get("location")
    if isinstance(location, list) and len(location) == 3:
        return tuple(float(v) for v in location)
    return None


def instance_ue_location(instance: dict):
    transform = instance.get("transform")
    if isinstance(transform, list) and len(transform) == 16:
        return manifest_to_ue(transform[12:15])
    return None


def parse_point(tokens: list[str]) -> tuple[float, float, float]:
    """Three numbers from 'X Y Z', 'X,Y,Z', '(X, Y, Z)' or UE's 'X=.. Y=.. Z=..'."""
    numbers = re.findall(r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", " ".join(tokens))
    if len(numbers) != 3:
        raise SystemExit("near needs exactly three coordinates, got %d from %r"
                         % (len(numbers), " ".join(tokens)))
    return tuple(float(n) for n in numbers)


def fmt_point(point) -> str:
    if point is None:
        return "-"
    return "(%s)" % ", ".join("%d" % round(v) for v in point)


# --- generic helpers ---------------------------------------------------------------------------

def get_path(record, dotted: str):
    """Value at a dotted path ('door.locked', 'drawScale3D.0'), or None if any step is missing."""
    value = record
    for part in dotted.split("."):
        if isinstance(value, dict):
            if part not in value:
                return None
            value = value[part]
        elif isinstance(value, list) and part.lstrip("-").isdigit():
            index = int(part)
            if not -len(value) <= index < len(value):
                return None
            value = value[index]
        else:
            return None
    return value


def type_name(value) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "bool"
    if isinstance(value, int):
        return "int"
    if isinstance(value, float):
        return "float"
    if isinstance(value, str):
        return "str"
    if isinstance(value, list):
        inner = sorted({type_name(v) for v in value})
        return "list[%s]" % "|".join(inner) if inner else "list"
    if isinstance(value, dict):
        return "dict"
    return type(value).__name__


def cell(value) -> str:
    if value is None:
        return "-"
    if isinstance(value, float):
        text = "%g" % value
    elif isinstance(value, (dict, list)):
        text = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    else:
        text = str(value)
    text = text.replace("\n", " ")
    return text if len(text) <= CELL_WIDTH else text[:CELL_WIDTH - 3] + "..."


def print_table(headers: list[str], rows: list[list], limit: int, total: int | None = None) -> None:
    total = len(rows) if total is None else total
    if not rows:
        return
    shown = rows if limit <= 0 else rows[:limit]
    text_rows = [[cell(v) for v in row] for row in shown]
    widths = [len(h) for h in headers]
    for row in text_rows:
        for i, value in enumerate(row):
            widths[i] = max(widths[i], len(value))
    print("  ".join(h.ljust(widths[i]) for i, h in enumerate(headers)).rstrip())
    print("  ".join("-" * w for w in widths).rstrip())
    for row in text_rows:
        print("  ".join(v.ljust(widths[i]) for i, v in enumerate(row)).rstrip())
    if total > len(shown):
        print("... %d more (use --limit 0 for all)" % (total - len(shown)))


def emit_json(value) -> None:
    print(json.dumps(value, indent=2, ensure_ascii=False))


def contains(haystack, needle_lower: str) -> bool:
    return isinstance(haystack, str) and needle_lower in haystack.lower()


def mesh_name_of(actor: dict):
    return actor.get("staticMesh") or actor.get("skeletalMesh")


def override_names(actor: dict) -> list[str]:
    names = []
    for entry in actor.get("materialOverrides") or []:
        if isinstance(entry, dict):
            names.append(str(entry.get("objectName", "?")))
        elif entry is not None:
            names.append(str(entry))
    return names


class Index:
    """The lookups every command needs, built once."""

    def __init__(self, document: dict):
        self.document = document
        self.actors = array(document, "actors")
        self.instances = array(document, "instances")
        self.assets = array(document, "assets")
        self.actor_by_key = {a.get("key"): a for a in self.actors if isinstance(a, dict)}
        self.asset_by_key = {a.get("key"): a for a in self.assets if isinstance(a, dict)}
        self.instances_by_actor: dict[str, list[dict]] = {}
        self.instances_by_asset: dict[str, list[dict]] = {}
        for instance in self.instances:
            if not isinstance(instance, dict):
                continue
            self.instances_by_actor.setdefault(instance.get("actorKey"), []).append(instance)
            self.instances_by_asset.setdefault(instance.get("asset"), []).append(instance)

    def asset_keys_of(self, actor: dict) -> list[str]:
        return [i.get("asset") for i in self.instances_by_actor.get(actor.get("key"), [])
                if i.get("asset")]


def actor_row(actor: dict) -> list:
    return [actor.get("key"), actor.get("label"), actor.get("className"),
            fmt_point(actor_ue_location(actor))]


ACTOR_HEADERS = ["key", "label", "className", "ue_location"]


def actor_json(actor: dict, extra: dict | None = None) -> dict:
    out = {"key": actor.get("key"), "label": actor.get("label"),
           "className": actor.get("className"), "ueLocation": actor_ue_location(actor)}
    if extra:
        out.update(extra)
    return out


# --- commands ----------------------------------------------------------------------------------

def describe_items(items: list, depth: int, prefix: str = "") -> list[list]:
    """[path, types, present/total] rows for the keys of a list of dicts, recursing into dicts."""
    dicts = [item for item in items if isinstance(item, dict)]
    present: Counter = Counter()
    types: dict[str, Counter] = {}
    # One "list[...]" entry per key with the union of element types, not one per distinct list.
    element_types: dict[str, set] = {}
    for item in dicts:
        for key, value in item.items():
            present[key] += 1
            if isinstance(value, list):
                element_types.setdefault(key, set()).update(type_name(v) for v in value)
                types.setdefault(key, Counter())["list"] += 1
            else:
                types.setdefault(key, Counter())[type_name(value)] += 1
    rows = []
    for key in sorted(present, key=lambda k: (-present[k], k)):
        path = prefix + key
        names = []
        for kind, _ in types[key].most_common():
            if kind == "list" and element_types.get(key):
                kind = "list[%s]" % "|".join(sorted(element_types[key]))
            names.append(kind)
        kinds = "|".join(names)
        rows.append([path, kinds, "%d/%d" % (present[key], len(dicts))])
        if depth > 1:
            children = [item[key] for item in dicts if isinstance(item.get(key), dict)]
            if children:
                rows.extend(describe_items(children, depth - 1, path + "."))
            nested = [v for item in dicts if isinstance(item.get(key), list)
                      for v in item[key] if isinstance(v, dict)]
            if nested:
                rows.extend(describe_items(nested, depth - 1, path + "[]."))
    return rows


def cmd_schema(index: Index, args) -> int:
    document = index.document
    if args.array:
        if args.array not in document:
            close = difflib.get_close_matches(args.array, list(document), n=3)
            raise SystemExit("no top-level key %r%s" % (
                args.array, " (did you mean %s?)" % ", ".join(close) if close else ""))
        value = document[args.array]
        targets = [(args.array, value)]
        depth = args.depth or 3
    else:
        targets = list(document.items())
        depth = args.depth or 1
    if args.json:
        out = {}
        for name, value in targets:
            if isinstance(value, list) and any(isinstance(v, dict) for v in value):
                out[name] = {"count": len(value), "fields": [
                    dict({"path": p, "types": t, "present": c},
                         **({"space": SPACE_NOTES["%s.%s" % (name, p)]}
                            if "%s.%s" % (name, p) in SPACE_NOTES else {}))
                    for p, t, c in describe_items(value, depth)]}
            else:
                out[name] = {"type": type_name(value),
                             "value": value if not isinstance(value, dict) else sorted(value)}
                if name in SPACE_NOTES:
                    out[name]["space"] = SPACE_NOTES[name]
        emit_json(out)
        return 0
    for name, value in targets:
        if isinstance(value, list) and any(isinstance(v, dict) for v in value):
            print("%s: list of %d" % (name, len(value)))
            for path, kinds, count in describe_items(value, depth):
                note = SPACE_NOTES.get("%s.%s" % (name, path))
                print(("    %-40s %-28s %-11s %s" % (path, kinds, count,
                                                     "<- " + note if note else "")).rstrip())
        elif isinstance(value, dict):
            print("%s: dict {%s}" % (name, ", ".join(sorted(value))))
        else:
            note = SPACE_NOTES.get(name)
            print(("%s: %s %s %s" % (name, type_name(value), cell(value),
                                     "<- " + note if note else "")).rstrip())
    return 0


def cmd_hist(index: Index, args) -> int:
    field = args.by
    counts = Counter()
    for actor in index.actors:
        value = get_path(actor, field)
        counts[cell(value) if not isinstance(value, str) else value] += 1
    rows = [[name, n] for name, n in counts.most_common()]
    if args.json:
        emit_json({"by": field, "actors": len(index.actors),
                   "counts": {name: n for name, n in counts.most_common()}})
        return 0
    print("%d actors, %d distinct %s" % (len(index.actors), len(counts), field))
    print_table([field, "count"], rows, args.limit)
    return 0


def cmd_class(index: Index, args) -> int:
    wanted = args.name.lower()
    matches = [a for a in index.actors if str(a.get("className", "")).lower() == wanted]
    if not matches:
        classes = sorted({str(a.get("className")) for a in index.actors})
        close = difflib.get_close_matches(args.name, classes, n=5, cutoff=0.5)
        close += [c for c in classes if wanted in c.lower() and c not in close][:5]
        raise SystemExit("no actors of class %r%s" % (
            args.name, "; similar: %s" % ", ".join(close) if close else ""))
    fields = [f.strip() for f in (args.fields or "").split(",") if f.strip()]
    for field in fields:
        if all(get_path(a, field) is None for a in matches):
            keys = sorted({k for a in matches for k in a})
            print("warning: no %s actor has %r; its keys are: %s"
                  % (matches[0].get("className"), field, ", ".join(keys)), file=sys.stderr)
    if args.json:
        emit_json([actor_json(a, {f: get_path(a, f) for f in fields}) for a in matches])
        return 0
    print("%d %s actors" % (len(matches), matches[0].get("className")))
    rows = [[a.get("key"), a.get("label"), fmt_point(actor_ue_location(a))]
            + [get_path(a, f) for f in fields] for a in matches]
    print_table(["key", "label", "ue_location"] + fields, rows, args.limit)
    return 0


def cmd_find(index: Index, args) -> int:
    needle = args.substr.lower()
    hits = []
    for actor in index.actors:
        fields = [("key", actor.get("key")), ("name", actor.get("name")),
                  ("label", actor.get("label")), ("className", actor.get("className")),
                  ("mesh", mesh_name_of(actor))]
        fields += [("asset", key) for key in index.asset_keys_of(actor)]
        matched = sorted({name for name, value in fields if contains(value, needle)})
        if matched:
            hits.append((actor, matched))
    if args.json:
        emit_json([actor_json(a, {"mesh": mesh_name_of(a), "matchedOn": m}) for a, m in hits])
        return 0
    print("%d actors match %r" % (len(hits), args.substr))
    rows = [actor_row(a) + [mesh_name_of(a), ",".join(m)] for a, m in hits]
    print_table(ACTOR_HEADERS + ["mesh", "matched"], rows, args.limit)
    return 0


def near_hits(index: Index, centre_ue, radius: float) -> list[dict]:
    hits = []
    for actor in index.actors:
        location = actor_ue_location(actor)
        if location is None:
            continue
        distance = math.dist(location, centre_ue)
        if distance <= radius:
            hits.append({"kind": "actor", "distance": distance, "key": actor.get("key"),
                         "label": actor.get("label"), "className": actor.get("className"),
                         "mesh": mesh_name_of(actor), "ueLocation": location})
    for instance in index.instances:
        location = instance_ue_location(instance)
        if location is None:
            continue
        distance = math.dist(location, centre_ue)
        if distance > radius:
            continue
        actor = index.actor_by_key.get(instance.get("actorKey"))
        if actor is not None:
            actor_location = actor_ue_location(actor)
            if (actor_location is not None
                    and math.dist(actor_location, location) <= SAME_PLACEMENT_CM):
                continue
        asset = index.asset_by_key.get(instance.get("asset")) or {}
        hits.append({"kind": "instance", "distance": distance, "key": instance.get("actorKey"),
                     "label": instance.get("label"),
                     "className": actor.get("className") if actor else asset.get("kind"),
                     "mesh": asset.get("name") or instance.get("asset"), "ueLocation": location})
    hits.sort(key=lambda h: h["distance"])
    return hits


def cmd_near(index: Index, args) -> int:
    point = parse_point(args.coords)
    centre_ue = point if args.space == "ue" else manifest_to_ue(point)
    hits = near_hits(index, centre_ue, args.radius)
    if args.json:
        emit_json({"centreUe": centre_ue, "centreManifest": ue_to_manifest(centre_ue),
                   "radius": args.radius, "hits": hits})
        return 0
    print("%d within %g cm of UE %s (manifest %s)"
          % (len(hits), args.radius, fmt_point(centre_ue), fmt_point(ue_to_manifest(centre_ue))))
    rows = [["%.0f" % h["distance"], h["kind"], h["key"], h["label"], h["className"], h["mesh"],
             fmt_point(h["ueLocation"])] for h in hits]
    print_table(["dist", "kind", "key", "label", "className", "mesh", "ue_location"],
                rows, args.limit)
    return 0


def cmd_actor(index: Index, args) -> int:
    wanted = args.key_or_label
    # Label before name: the label is what the UE outliner shows. The two namespaces overlap
    # (name StaticMeshActor14 is a wall panel; label StaticMeshActor14 is three light beams), so
    # say when the other one also matched.
    matches = [a for a in index.actors if a.get("key") == wanted]
    if not matches:
        by_label = [a for a in index.actors if a.get("label") == wanted]
        by_name = [a for a in index.actors if a.get("name") == wanted and a not in by_label]
        matches = by_label or by_name
        if by_label and by_name:
            print("note: %d more actor(s) have name %r (internal object name, not label): %s"
                  % (len(by_name), wanted, ", ".join(str(a.get("key")) for a in by_name[:5])),
                  file=sys.stderr)
    if not matches:
        lowered = wanted.lower()
        matches = [a for a in index.actors
                   if any(str(a.get(f, "")).lower() == lowered for f in ("key", "name", "label"))]
    if not matches:
        names = [str(a.get(f)) for a in index.actors for f in ("key", "label") if a.get(f)]
        close = difflib.get_close_matches(wanted, names, n=5, cutoff=0.6)
        raise SystemExit("no actor with key/name/label %r%s (try: find %s)" % (
            wanted, "; similar: %s" % ", ".join(close) if close else "", wanted))
    records = []
    for actor in matches:
        record = dict(actor)
        if args.brief:
            for key in BULKY_KEYS:
                if key in record:
                    record[key] = "<%d omitted by --brief>" % len(record[key])
        record["_ueLocation"] = actor_ue_location(actor)
        record["_instances"] = [
            {"asset": i.get("asset"), "ueLocation": instance_ue_location(i)}
            for i in index.instances_by_actor.get(actor.get("key"), [])]
        records.append(record)
    if len(records) > 1 and not args.json:
        print("%d actors match %r" % (len(records), wanted), file=sys.stderr)
    emit_json(records if len(records) > 1 else records[0])
    return 0


def cmd_assets(index: Index, args) -> int:
    needle = args.substr.lower()
    hits = [a for a in index.assets
            if any(contains(a.get(f), needle) for f in ("key", "name", "file", "group"))]
    if args.json:
        emit_json([dict(a, placements=len(index.instances_by_asset.get(a.get("key"), [])))
                   for a in hits])
        return 0
    print("%d assets match %r" % (len(hits), args.substr))
    rows = []
    for asset in hits:
        materials = [s.get("material") for s in asset.get("sections") or [] if isinstance(s, dict)]
        rows.append([asset.get("key"), asset.get("kind"), asset.get("triangleCount"),
                     len(index.instances_by_asset.get(asset.get("key"), [])),
                     ",".join(str(m) for m in materials), asset.get("file")])
    print_table(["key", "kind", "tris", "placed", "section materials", "file"], rows, args.limit)
    return 0


def cmd_mesh(index: Index, args) -> int:
    wanted = args.name.lower()
    meshes = [a for a in index.assets
              if wanted in (str(a.get("name", "")).lower(), str(a.get("key", "")).lower())]
    names = {str(m.get("name")).lower() for m in meshes} | {wanted}
    # A mesh the exporter skipped (e.g. LowRentDoor_Mesh, "no vertex data") has no asset entry
    # but is still named by the actors that use it.
    named_by_actor = any(isinstance(mesh_name_of(a), str) and mesh_name_of(a).lower() in names
                         for a in index.actors)
    if not meshes and not named_by_actor:
        candidates = sorted({str(a.get("name")) for a in index.assets
                             if contains(a.get("name"), wanted) or contains(a.get("key"), wanted)}
                            | {mesh_name_of(a) for a in index.actors
                               if contains(mesh_name_of(a), wanted)})
        if not candidates:
            raise SystemExit("no mesh named %r (try: assets %s)" % (args.name, args.name))
        print("no exact mesh %r; %d mesh names contain it:" % (args.name, len(candidates)),
              file=sys.stderr)
        for name in candidates[:20]:
            print("    %s" % name, file=sys.stderr)
        return 1
    keys = {m.get("key") for m in meshes}
    placements = []
    seen_actor_keys = set()
    for key in keys:
        for instance in index.instances_by_asset.get(key, []):
            actor = index.actor_by_key.get(instance.get("actorKey"))
            seen_actor_keys.add(instance.get("actorKey"))
            placements.append({
                "actorKey": instance.get("actorKey"), "asset": key,
                "label": instance.get("label"),
                "className": actor.get("className") if actor else None,
                "ueLocation": instance_ue_location(instance),
                "materialOverrides": override_names(actor) if actor else []})
    # Actors that name the mesh but were not placed (no instance), e.g. skipped doors.
    for actor in index.actors:
        mesh = mesh_name_of(actor)
        if (isinstance(mesh, str) and mesh.lower() in names
                and actor.get("key") not in seen_actor_keys):
            placements.append({
                "actorKey": actor.get("key"), "asset": None, "label": actor.get("label"),
                "className": actor.get("className"), "ueLocation": actor_ue_location(actor),
                "materialOverrides": override_names(actor), "unplaced": True})
    if args.json:
        emit_json({"meshes": [{"key": m.get("key"), "kind": m.get("kind"),
                               "sections": m.get("sections")} for m in meshes],
                   "placements": placements})
        return 0
    for mesh in meshes:
        sections = [s.get("material") for s in mesh.get("sections") or [] if isinstance(s, dict)]
        print("%s (%s, %s tris) default materials: %s" % (
            mesh.get("key"), mesh.get("kind"), mesh.get("triangleCount"),
            ", ".join(str(s) for s in sections) or "-"))
    if not meshes:
        print("%s: no asset in this manifest (not exported - see its 'skipped' list)" % args.name)
    print("%d placements" % len(placements))
    rows = [[p["actorKey"], p["label"], p["className"], fmt_point(p["ueLocation"]),
             ",".join(p["materialOverrides"]) or "-", "UNPLACED" if p.get("unplaced") else ""]
            for p in placements]
    print_table(["actorKey", "label", "className", "ue_location", "overrides", ""],
                rows, args.limit)
    return 0


# --- CLI ---------------------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    # The shared options sit on every subparser with SUPPRESS defaults, so they work both before
    # and after the command ("hist --map 1-Medical" as well as "--map 1-Medical hist").
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--map", default=argparse.SUPPRESS, help="map name (default 1-Medical)")
    common.add_argument("--manifest", default=argparse.SUPPRESS, help="explicit manifest path")
    common.add_argument("--json", action="store_true", default=argparse.SUPPRESS,
                        help="raw JSON instead of a table")
    common.add_argument("--limit", type=int, default=argparse.SUPPRESS,
                        help="max table rows (default %d, 0 = all)" % DEFAULT_LIMIT)

    parser = argparse.ArgumentParser(
        prog="manifest_query.py", parents=[common],
        description="Query a <map>.ue5-level.json manifest (always read as utf-8).",
        epilog="Locations print in UE space; see the module docstring for the mapping.")
    sub = parser.add_subparsers(dest="command", metavar="command")
    sub.required = True

    p = sub.add_parser("schema", parents=[common], help="keys and value types from the real file")
    p.add_argument("array", nargs="?", help="one top-level key to describe in depth")
    p.add_argument("--depth", type=int, default=0,
                   help="nesting depth (default 1, or 3 with ARRAY)")
    p.set_defaults(func=cmd_schema)

    p = sub.add_parser("hist", parents=[common], help="actors counted by className")
    p.add_argument("--by", default="className", help="dotted actor field to count by")
    p.set_defaults(func=cmd_hist)

    p = sub.add_parser("class", parents=[common], help="actors of one class")
    p.add_argument("name")
    p.add_argument("--fields", help="comma-separated dotted fields to add as columns")
    p.set_defaults(func=cmd_class)

    p = sub.add_parser("find", parents=[common], help="actors matching a substring")
    p.add_argument("substr")
    p.set_defaults(func=cmd_find)

    p = sub.add_parser("near", parents=[common], help="actors/instances near a point")
    p.add_argument("coords", nargs="+", help="X Y Z, or a pasted 'X=.. Y=.. Z=..'")
    p.add_argument("--radius", type=float, default=DEFAULT_RADIUS)
    p.add_argument("--space", choices=("ue", "manifest"), default="ue",
                   help="space of X Y Z (default ue: what the UE editor shows)")
    p.set_defaults(func=cmd_near)

    p = sub.add_parser("actor", parents=[common], help="full record of one actor")
    p.add_argument("key_or_label")
    p.add_argument("--brief", action="store_true", help="omit raw property hex and trailer")
    p.set_defaults(func=cmd_actor)

    p = sub.add_parser("assets", parents=[common], help="assets matching a substring")
    p.add_argument("substr")
    p.set_defaults(func=cmd_assets)

    p = sub.add_parser("mesh", parents=[common], help="who places a mesh, with what overrides")
    p.add_argument("name")
    p.set_defaults(func=cmd_mesh)
    return parser


def main(argv: list[str] | None = None) -> int:
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass
    args = build_parser().parse_args(argv)
    args.map = getattr(args, "map", None)
    args.manifest = getattr(args, "manifest", None)
    args.json = getattr(args, "json", False)
    args.limit = getattr(args, "limit", DEFAULT_LIMIT)
    index = Index(load_manifest(manifest_path(args.map, args.manifest)))
    return args.func(index, args)


if __name__ == "__main__":
    sys.exit(main())
