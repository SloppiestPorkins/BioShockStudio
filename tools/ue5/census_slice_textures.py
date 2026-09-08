"""Census exported Medical textures and cross-check low-resolution tails with BulkContent.

This host-Python tool does not mutate content. It writes its JSON report to %TEMP% by default.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from PIL import Image

import recover_stripped_textures as bulk


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--manifest",
        default=r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json")
    parser.add_argument(
        "--out", default=os.path.join(os.environ.get("TEMP", "."), "texture_census_1-Medical.json"))
    args = parser.parse_args(argv)

    manifest_path = Path(args.manifest)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    catalog_path = bulk._bulk_dir(bulk._game_root()) / bulk.CATALOG_NAME
    entries = bulk.parse_catalog(catalog_path.read_bytes())
    by_name = {}
    for entry in entries:
        by_name.setdefault(entry["texture"].lower(), []).append(entry)

    textures = {}
    intent_mismatches = []
    for intent in manifest.get("textures") or []:
        relative = intent.get("file") or ""
        stem = Path(relative).stem
        record = textures.setdefault(stem, {
            "stem": stem, "file": str(manifest_path.parent / relative), "intents": []})
        record["intents"].append({
            "material": intent.get("material"), "slot": intent.get("slot"),
            "usage": intent.get("usage"), "colourSpace": intent.get("colourSpace"),
        })
        usage = intent.get("usage")
        colour = intent.get("colourSpace")
        if (usage == "BaseColor" and colour != "Srgb") or (
                usage == "NormalMap" and colour != "Linear"):
            intent_mismatches.append(record["intents"][-1] | {"stem": stem})

    clear_bulk_offenders = []
    low_resolution = []
    missing = []
    for stem, record in sorted(textures.items()):
        path = Path(record["file"])
        if not path.is_file():
            missing.append(stem)
            continue
        try:
            with Image.open(path) as image:
                width, height = image.size
        except Exception as exc:  # noqa: BLE001
            record["readError"] = str(exc)
            continue
        record["exportedSize"] = [width, height]
        if width <= 128 or height <= 128:
            low_resolution.append(record)
        candidates = by_name.get(stem.lower(), [])
        best = None
        for entry in candidates:
            try:
                fmt, bulk_w, bulk_h, levels = bulk._detect_format_and_top(entry["size"])
            except Exception:  # noqa: BLE001
                continue
            if best is None or bulk_w * bulk_h > best["bulkSize"][0] * best["bulkSize"][1]:
                best = {
                    "group": entry["group"], "chunk": entry["chunk"],
                    "offset": entry["offset"], "bytes": entry["size"], "format": fmt,
                    "bulkSize": [bulk_w, bulk_h], "levels": len(levels),
                }
        if best:
            record["bulk"] = best
            uses_surface_data = any(
                i["usage"] in ("BaseColor", "NormalMap") for i in record["intents"])
            if uses_surface_data and (
                    best["bulkSize"][0] >= width * 4 and best["bulkSize"][1] >= height * 4):
                clear_bulk_offenders.append(record)

    report = {
        "manifest": str(manifest_path), "catalog": str(catalog_path),
        "uniqueTextures": len(textures), "missingExports": missing,
        "intentMismatches": intent_mismatches,
        "lowResolution": low_resolution,
        "clearBulkOffenders": clear_bulk_offenders,
    }
    Path(args.out).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("textures=%d lowResolution=%d bulkOffenders=%d intentMismatches=%d" % (
        len(textures), len(low_resolution), len(clear_bulk_offenders), len(intent_mismatches)))
    print(args.out)
    return report


if __name__ == "__main__":
    main()
