#!/usr/bin/env python3
"""Diff two level manifests (<map>.ue5-level.json): actors, assets, instances, lights.

Re-exporting a map after a decoder change and eyeballing a 47 MB JSON is how the array-size
fix's Medical fallout was nearly missed (14 actors gone, 2 added, 11 door fields changed).
This prints a compact table of what moved, by actor key, so the next re-export is one command:

    python tools/manifest_diff.py OLD.json NEW.json
    python tools/manifest_diff.py OLD.json NEW.json --json

Actors are matched by ``key``. A field counts as changed when both sides have the actor and the
JSON value differs (including type). Counts for ``assets``, ``instances`` and ``lights`` are
always printed; per-key add/remove for those collections is included when the totals differ or
any key moved. Plain stdlib, files opened as utf-8.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


COLLECTIONS = ("actors", "assets", "instances", "lights")
ACTOR_ID_FIELDS = ("key", "className", "label", "name")
# Bulky / noisy fields that drown the table; still reported under --json and when they alone change.
BULKY_FIELDS = frozenset({"properties", "trailerHex", "trailer"})


def load_manifest(path: Path) -> dict:
    if not path.is_file():
        raise SystemExit("manifest not found: %s" % path)
    with open(path, "r", encoding="utf-8") as handle:
        document = json.load(handle)
    if not isinstance(document, dict):
        raise SystemExit("%s is not a level manifest (top level is %s)"
                         % (path, type(document).__name__))
    return document


def as_list(document: dict, name: str) -> list:
    value = document.get(name)
    return value if isinstance(value, list) else []


def item_key(item: dict, collection: str) -> str | None:
    key = item.get("key")
    if isinstance(key, str) and key:
        return key
    if collection == "instances":
        # Instances often lack a stable key; fall back to actorKey + asset + label.
        parts = [item.get("actorKey"), item.get("asset"), item.get("label")]
        if any(parts):
            return "|".join("" if p is None else str(p) for p in parts)
    return None


def index_by_key(items: list, collection: str) -> dict[str, dict]:
    indexed: dict[str, dict] = {}
    for item in items:
        if not isinstance(item, dict):
            continue
        key = item_key(item, collection)
        if key is None:
            continue
        # First wins; duplicates are rare and would only confuse a diff.
        indexed.setdefault(key, item)
    return indexed


def summarize_actor(actor: dict) -> dict[str, Any]:
    return {field: actor.get(field) for field in ACTOR_ID_FIELDS if field in actor or field == "key"}


def field_diff(old: dict, new: dict) -> dict[str, Any]:
    keys = sorted(set(old) | set(new))
    changed: dict[str, Any] = {}
    for key in keys:
        if old.get(key) != new.get(key):
            changed[key] = {"old": old.get(key), "new": new.get(key)}
    return changed


def compact_value(value: Any, width: int = 48) -> str:
    if value is None:
        return "-"
    if isinstance(value, (dict, list)):
        text = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    else:
        text = str(value)
    text = text.replace("\n", " ")
    if len(text) > width:
        return text[: width - 1] + "…"
    return text


def diff_collection(old_doc: dict, new_doc: dict, collection: str) -> dict[str, Any]:
    old_items = as_list(old_doc, collection)
    new_items = as_list(new_doc, collection)
    old_map = index_by_key(old_items, collection)
    new_map = index_by_key(new_items, collection)
    old_keys = set(old_map)
    new_keys = set(new_map)
    added_keys = sorted(new_keys - old_keys)
    removed_keys = sorted(old_keys - new_keys)
    changed: list[dict[str, Any]] = []
    for key in sorted(old_keys & new_keys):
        fields = field_diff(old_map[key], new_map[key])
        if fields:
            entry = {
                "key": key,
                "className": new_map[key].get("className", old_map[key].get("className")),
                "label": new_map[key].get("label", old_map[key].get("label")),
                "fields": fields,
            }
            changed.append(entry)
    return {
        "collection": collection,
        "oldCount": len(old_items),
        "newCount": len(new_items),
        "added": [summarize_actor(new_map[k]) if collection == "actors"
                  else {"key": k} for k in added_keys],
        "removed": [summarize_actor(old_map[k]) if collection == "actors"
                    else {"key": k} for k in removed_keys],
        "changed": changed,
    }


def diff_manifests(old_doc: dict, new_doc: dict) -> dict[str, Any]:
    result = {
        "old": {
            "package": old_doc.get("package"),
            "generator": old_doc.get("generator"),
            "formatVersion": old_doc.get("formatVersion"),
        },
        "new": {
            "package": new_doc.get("package"),
            "generator": new_doc.get("generator"),
            "formatVersion": new_doc.get("formatVersion"),
        },
        "collections": {},
    }
    for name in COLLECTIONS:
        result["collections"][name] = diff_collection(old_doc, new_doc, name)
    return result


def print_table(report: dict[str, Any]) -> None:
    print("manifest diff")
    print("  old: package=%s generator=%s formatVersion=%s"
          % (report["old"].get("package"), report["old"].get("generator"),
             report["old"].get("formatVersion")))
    print("  new: package=%s generator=%s formatVersion=%s"
          % (report["new"].get("package"), report["new"].get("generator"),
             report["new"].get("formatVersion")))
    print()
    print("%-12s %8s %8s %8s %8s %8s"
          % ("collection", "old", "new", "added", "removed", "changed"))
    print("-" * 56)
    for name in COLLECTIONS:
        block = report["collections"][name]
        print("%-12s %8d %8d %8d %8d %8d"
              % (name, block["oldCount"], block["newCount"],
                 len(block["added"]), len(block["removed"]), len(block["changed"])))
    print()

    actors = report["collections"]["actors"]
    if actors["removed"]:
        print("actors removed (%d)" % len(actors["removed"]))
        for item in actors["removed"]:
            print("  - %-48s  %-28s  %s"
                  % (item.get("key"), item.get("className") or "-", item.get("label") or "-"))
        print()
    if actors["added"]:
        print("actors added (%d)" % len(actors["added"]))
        for item in actors["added"]:
            print("  + %-48s  %-28s  %s"
                  % (item.get("key"), item.get("className") or "-", item.get("label") or "-"))
        print()
    if actors["changed"]:
        print("actors changed (%d)" % len(actors["changed"]))
        for item in actors["changed"]:
            fields = item["fields"]
            names = sorted(fields)
            bulky_only = set(names) <= BULKY_FIELDS
            shown = [n for n in names if n not in BULKY_FIELDS] or names
            print("  ~ %-48s  %-28s  %s"
                  % (item.get("key"), item.get("className") or "-", item.get("label") or "-"))
            if bulky_only and set(names) & BULKY_FIELDS:
                print("      fields: %s (bulky)" % ", ".join(names))
            else:
                for name in shown:
                    pair = fields[name]
                    print("      %-22s  %s  ->  %s"
                          % (name, compact_value(pair["old"]), compact_value(pair["new"])))
                skipped = [n for n in names if n in BULKY_FIELDS and n not in shown]
                if skipped:
                    print("      (+ bulky: %s)" % ", ".join(skipped))
        print()

    for name in ("assets", "instances", "lights"):
        block = report["collections"][name]
        if not (block["added"] or block["removed"] or block["changed"]):
            continue
        print("%s key moves: +%d -%d ~%d"
              % (name, len(block["added"]), len(block["removed"]), len(block["changed"])))
        for item in block["removed"][:20]:
            print("  - %s" % item.get("key"))
        if len(block["removed"]) > 20:
            print("  - … %d more" % (len(block["removed"]) - 20))
        for item in block["added"][:20]:
            print("  + %s" % item.get("key"))
        if len(block["added"]) > 20:
            print("  + … %d more" % (len(block["added"]) - 20))
        print()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Diff two *.ue5-level.json manifests (actors / assets / instances / lights).")
    parser.add_argument("old", type=Path, help="baseline / production manifest")
    parser.add_argument("new", type=Path, help="re-exported manifest")
    parser.add_argument("--json", action="store_true",
                        help="emit the full report as JSON instead of a table")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    report = diff_manifests(load_manifest(args.old), load_manifest(args.new))
    if args.json:
        json.dump(report, sys.stdout, ensure_ascii=False, indent=2)
        sys.stdout.write("\n")
    else:
        print_table(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
