"""Recover mip-stripped BioShock textures from BulkContent into PNGs.

`export-fbx` / `ResolveMesh` call `MaterialExporter.Resolve` without a
`BulkTextureCatalog`, so textures whose top mips live only in
`ContentBaked/pc/BulkContent` export as the package's 64x64 tail (a few KB of
placeholder). Pistol_DIFF is fine because it ships unstripped (`StrippedNumMips=0`);
Shotgun_NoUpgrades_* are stripped and need this recovery.

This is the UE5-lane workaround for that CLI gap. The durable C# fix is to pass
`BulkTextureCatalog.Load(root)` into `MaterialExporter.Resolve` from
`ResolveMesh` / `export-textures` (Claude Code lane: `src/BioShockStudio.Cli`).

Usage (host Python, not Unreal):

  python tools/ue5/recover_stripped_textures.py \\
      --out %TEMP%/bioshock-shotgun-tex-fixed \\
      --group WP_Shotgun \\
      Shotgun_NoUpgrades_Diffuse Shotgun_NoUpgrades_Normal Shotgun_NoUpgrades_Specular

Writes `<out>/Textures/<name>.png` and `<out>/recover_stripped_textures.json`.
"""
from __future__ import annotations

import argparse
import json
import os
import struct
import sys
from pathlib import Path

from PIL import Image


CATALOG_NAME = "Catalog.bdc"
HEADER_SIZE = 23
CHUNK_GAP = 1
RECORD_SIZE = 20
OFFSET_ALIGNMENT = 32768


def _game_root() -> Path:
    override = os.environ.get("BIOSHOCK_REMASTERED_PATH")
    if override and Path(override, "ContentBaked", "pc", "Maps").is_dir():
        return Path(override)
    return Path(r"G:\SteamLibrary\steamapps\common\BioShock Remastered")


def _bulk_dir(game_root: Path) -> Path:
    return game_root / "ContentBaked" / "pc" / "BulkContent"


def _try_read_fstring(data: bytes, offset: int):
    if offset < 0 or offset >= len(data):
        return None, offset
    units = data[offset]
    if units < 2 or units > 128:
        return None, offset
    nbytes = units * 2
    if offset + 1 + nbytes > len(data):
        return None, offset
    if struct.unpack_from("<H", data, offset + 1 + nbytes - 2)[0] != 0:
        return None, offset
    chars = []
    for i in range(units - 1):
        c = struct.unpack_from("<H", data, offset + 1 + i * 2)[0]
        if c < 32 or c > 126:
            return None, offset
        chars.append(chr(c))
    return "".join(chars), offset + 1 + nbytes


def parse_catalog(data: bytes):
    entries = []
    chunk = ""
    offset = HEADER_SIZE
    while offset < len(data):
        name, next_off = _try_read_fstring(data, offset)
        if name is None:
            offset += 1
            continue
        offset = next_off
        if name.lower().endswith(".blk"):
            chunk = name
            offset += CHUNK_GAP
            continue
        group, offset = _try_read_fstring(data, offset)
        if group is None or offset + RECORD_SIZE > len(data):
            break
        leading, at, size, repeated, index = struct.unpack_from("<IiIii", data, offset)
        offset += RECORD_SIZE
        if leading != 0 or size != repeated or size <= 0:
            continue
        if at % OFFSET_ALIGNMENT != 0:
            continue
        entries.append(
            {
                "texture": name,
                "group": group,
                "chunk": chunk,
                "offset": at,
                "size": size,
                "index": index,
            }
        )
    return entries


def _blocks(size: int) -> int:
    return max(1, (size + 3) // 4)


def _mip_bytes(fmt: str, width: int, height: int) -> int:
    block = 8 if fmt == "DXT1" else 16
    return _blocks(width) * _blocks(height) * block


def _find_chain(fmt: str, declared: int, total: int):
    width = height = declared
    while width >= 1 and height >= 1:
        levels = []
        summed = 0
        w, h = width, height
        while w >= 1 and h >= 1 and summed < total:
            levels.append((w, h))
            summed += _mip_bytes(fmt, w, h)
            if summed == total:
                return levels
            w = max(1, w // 2)
            h = max(1, h // 2)
            if w == 1 and h == 1 and summed < total:
                break
        width = max(1, width // 2)
        height = max(1, height // 2)
        if width == 1 and height == 1:
            break
    return []


def _detect_format_and_top(size: int):
    for declared in (2048, 1024, 512, 256):
        for fmt in ("DXT1", "DXT5"):
            levels = _find_chain(fmt, declared, size)
            if levels:
                return fmt, levels[0][0], levels[0][1], levels
    raise RuntimeError("bulk blob size %d is not a DXT1/DXT5 mip chain" % size)


def _write_dds(path: Path, fmt: str, width: int, height: int, payload: bytes):
    hdr = bytearray(128)
    hdr[0:4] = b"DDS "
    struct.pack_into("<I", hdr, 4, 124)
    flags = 0x1 | 0x2 | 0x4 | 0x1000 | 0x80000  # caps/height/width/pixelformat/linearsize
    struct.pack_into("<I", hdr, 8, flags)
    struct.pack_into("<I", hdr, 12, height)
    struct.pack_into("<I", hdr, 16, width)
    struct.pack_into("<I", hdr, 20, len(payload))
    struct.pack_into("<I", hdr, 28, 1)
    struct.pack_into("<I", hdr, 76, 32)
    struct.pack_into("<I", hdr, 80, 0x4)  # DDPF_FOURCC
    hdr[84:88] = fmt.encode("ascii")
    struct.pack_into("<I", hdr, 108, 0x1000)  # DDSCAPS_TEXTURE
    path.write_bytes(bytes(hdr) + payload)


def find_entry(entries, texture: str, group: str | None):
    candidates = [e for e in entries if e["texture"].lower() == texture.lower()]
    if not candidates:
        return None
    if group:
        for e in candidates:
            if e["group"].lower() == group.lower():
                return e
    return candidates[0]


def recover_one(bulk_dir: Path, entry: dict, out_png: Path) -> dict:
    fmt, width, height, levels = _detect_format_and_top(entry["size"])
    chunk_path = bulk_dir / entry["chunk"]
    if not chunk_path.is_file():
        raise FileNotFoundError(chunk_path)
    with open(chunk_path, "rb") as handle:
        handle.seek(entry["offset"])
        blob = handle.read(entry["size"])
    if len(blob) != entry["size"]:
        raise RuntimeError(
            "short read %s: got %d want %d" % (entry["texture"], len(blob), entry["size"])
        )
    top_bytes = _mip_bytes(fmt, width, height)
    dds_path = out_png.with_suffix(".dds")
    _write_dds(dds_path, fmt, width, height, blob[:top_bytes])
    img = Image.open(dds_path)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_png)
    dds_path.unlink(missing_ok=True)
    return {
        "texture": entry["texture"],
        "group": entry["group"],
        "chunk": entry["chunk"],
        "offset": entry["offset"],
        "size": entry["size"],
        "format": fmt,
        "width": width,
        "height": height,
        "levels": len(levels),
        "png": str(out_png),
        "pngBytes": out_png.stat().st_size,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("textures", nargs="+", help="Texture object names to recover")
    parser.add_argument(
        "--group",
        default="WP_Shotgun",
        help="Bulk catalog group (export outer). Default WP_Shotgun.",
    )
    parser.add_argument(
        "--out",
        default=os.path.join(os.environ.get("TEMP", "."), "bioshock-shotgun-tex-fixed"),
        help="Output directory (Textures/ written underneath)",
    )
    parser.add_argument(
        "--game-root",
        default=None,
        help="BioShock Remastered install root (or set BIOSHOCK_REMASTERED_PATH)",
    )
    args = parser.parse_args(argv)

    game_root = Path(args.game_root) if args.game_root else _game_root()
    bulk_dir = _bulk_dir(game_root)
    catalog_path = bulk_dir / CATALOG_NAME
    if not catalog_path.is_file():
        raise SystemExit("Catalog.bdc missing at %s" % catalog_path)

    entries = parse_catalog(catalog_path.read_bytes())
    out_root = Path(args.out)
    tex_dir = out_root / "Textures"
    tex_dir.mkdir(parents=True, exist_ok=True)

    report = {
        "gameRoot": str(game_root),
        "bulkDir": str(bulk_dir),
        "group": args.group,
        "recovered": [],
        "failures": [],
    }

    for name in args.textures:
        entry = find_entry(entries, name, args.group)
        if entry is None:
            report["failures"].append("%s not in Catalog.bdc (group=%s)" % (name, args.group))
            continue
        try:
            info = recover_one(bulk_dir, entry, tex_dir / (name + ".png"))
            report["recovered"].append(info)
            print(
                "OK %s %dx%d %s -> %s (%d bytes)"
                % (name, info["width"], info["height"], info["format"], info["png"], info["pngBytes"])
            )
        except Exception as exc:  # noqa: BLE001
            report["failures"].append("%s: %s" % (name, exc))
            print("FAIL %s: %s" % (name, exc), file=sys.stderr)

    report_path = out_root / "recover_stripped_textures.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("report: %s" % report_path)
    if report["failures"] or not report["recovered"]:
        raise SystemExit(1)
    return 0


if __name__ == "__main__":
    main()
