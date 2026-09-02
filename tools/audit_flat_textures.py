#!/usr/bin/env python3
"""Classify flat exported PNG textures and document likely decode failures."""

from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageStat


DEFAULT_EXPORT_DIR = Path(
    "C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/Textures"
)
REPORT_PATH = Path(__file__).resolve().parents[1] / "docs/research/flat-textures.md"
FLAT_RGB_STDDEV = 3.0
ALPHA_CARRIER_STDDEV = 5.0
TINY_FILE_BYTES = 4096
LEGIT_NAME_WORDS = ("black", "white", "transparent", "default")
NORMAL_NAME_WORDS = ("normal", "norm", "nrm")
MATERIAL_SLOTS = ("diffuse", "normalMap", "specular")


@dataclass(frozen=True)
class TextureAudit:
    path: Path
    relative_path: str
    classification: str
    size_bytes: int
    dimensions: tuple[int, int]
    mean_rgb: tuple[float, float, float]
    rgb_stddev: tuple[float, float, float]
    alpha_stddev: float
    alpha_range: tuple[int, int]


def _name_has_word(path: Path, words: tuple[str, ...]) -> bool:
    """Match underscore/dash-delimited asset-name words without case sensitivity."""
    stem = path.stem.casefold().replace("-", "_")
    parts = stem.split("_")
    return any(part.startswith(word) for part in parts for word in words)


def _is_flat_normal(path: Path, mean_rgb: tuple[float, float, float]) -> bool:
    return (
        _name_has_word(path, NORMAL_NAME_WORDS)
        and abs(mean_rgb[0] - 128) <= 20
        and abs(mean_rgb[1] - 128) <= 20
        and mean_rgb[2] >= 235
    )


def audit_texture(path: Path, export_dir: Path) -> TextureAudit:
    with Image.open(path) as source:
        rgba = source.convert("RGBA")
        dimensions = rgba.size
        alpha_range = rgba.getchannel("A").getextrema()
        sample = rgba.resize((32, 32), Image.Resampling.LANCZOS)
        stats = ImageStat.Stat(sample)

    mean_rgb = tuple(stats.mean[:3])
    rgb_stddev = tuple(stats.stddev[:3])
    alpha_stddev = stats.stddev[3]
    size_bytes = path.stat().st_size
    flat_rgb = all(value < FLAT_RGB_STDDEV for value in rgb_stddev)
    flat_alpha = alpha_stddev <= ALPHA_CARRIER_STDDEV

    if not flat_rgb:
        classification = "non-flat"
    elif _is_flat_normal(path, mean_rgb):
        classification = "flat-normal"
    elif alpha_stddev > ALPHA_CARRIER_STDDEV:
        classification = "alpha-carrier"
    elif (
        flat_alpha
        and size_bytes <= TINY_FILE_BYTES
        and _name_has_word(path, LEGIT_NAME_WORDS)
    ):
        classification = "legit-flat"
    else:
        # A flat texture without positive name/normal/alpha evidence is suspicious.
        # This deliberately includes small files such as glasscon_diffuse.png: PNG
        # compression size alone cannot prove that its source art was uniform.
        classification = "suspect"

    return TextureAudit(
        path=path,
        relative_path=path.relative_to(export_dir).as_posix(),
        classification=classification,
        size_bytes=size_bytes,
        dimensions=dimensions,
        mean_rgb=mean_rgb,
        rgb_stddev=rgb_stddev,
        alpha_stddev=alpha_stddev,
        alpha_range=alpha_range,
    )


def _normalized_texture_path(value: str) -> str:
    return value.replace("\\", "/").casefold().lstrip("./")


def load_material_bindings(export_dir: Path) -> dict[str, list[str]]:
    manifest_path = export_dir.parent / "1-Medical.ue5-level.json"
    if not manifest_path.is_file():
        return {}

    with manifest_path.open("r", encoding="utf-8") as stream:
        manifest = json.load(stream)

    bindings: dict[str, list[str]] = defaultdict(list)
    for material in manifest.get("materials", []):
        material_name = material.get("name") or material.get("key") or "<unnamed>"
        material_key = material.get("key")
        label = (
            f"{material_name} (`{material_key}`)"
            if material_key and material_key != material_name
            else str(material_name)
        )
        for slot in MATERIAL_SLOTS:
            texture_path = material.get(slot)
            if not isinstance(texture_path, str) or not texture_path:
                continue
            normalized = _normalized_texture_path(texture_path)
            if normalized.startswith("textures/"):
                normalized = normalized[len("textures/") :]
            bindings[normalized].append(f"{label} [{slot}]")
    return dict(bindings)


def _format_mean(mean_rgb: tuple[float, float, float]) -> str:
    return "(" + ", ".join(f"{value:.2f}" for value in mean_rgb) + ")"


def write_report(
    export_dir: Path,
    audits: list[TextureAudit],
    bindings: dict[str, list[str]],
) -> None:
    counts = Counter(item.classification for item in audits)
    class_order = ("legit-flat", "alpha-carrier", "flat-normal", "suspect", "non-flat")
    suspects = [item for item in audits if item.classification == "suspect"]

    lines = [
        "# Flat exported texture census",
        "",
        "Status: **VERIFIED** for the exported PNG files currently present in the directory below. ",
        "The `suspect` label identifies files requiring source/decode investigation; it does not by ",
        "itself prove a particular decoder fault.",
        "",
        f"Export directory: `{export_dir.as_posix()}`",
        "",
        "RGB flatness is per-channel standard deviation `< 3` after a 32x32 Lanczos downsample. ",
        "Alpha carriers have sampled alpha standard deviation `> 5`. Legitimate named constants ",
        f"must also be at most {TINY_FILE_BYTES:,} bytes. Flat normals require a normal-map name and ",
        "sampled mean RGB within 20 of `(128, 128)` with blue at least 235. Remaining flat-RGB, ",
        "flat-alpha images are suspects, including small files: compression size cannot establish ",
        "that source art was intentionally uniform.",
        "",
        "## Counts",
        "",
        "| Class | Count |",
        "|---|---:|",
    ]
    lines.extend(f"| {name} | {counts[name]} |" for name in class_order)
    lines.extend((f"| **Total PNGs** | **{len(audits)}** |", "", "## Suspects", ""))

    if not suspects:
        lines.append("No suspect textures were found.")
    else:
        lines.extend(
            (
                "| Texture | Size (bytes) | Dimensions | Mean RGB | Alpha range | Material bindings |",
                "|---|---:|---:|---|---:|---|",
            )
        )
        for item in suspects:
            material_bindings = bindings.get(item.relative_path.casefold(), [])
            binding_text = "<br>".join(material_bindings) if material_bindings else "Not found in manifest"
            lines.append(
                f"| `{item.relative_path}` | {item.size_bytes:,} | "
                f"{item.dimensions[0]}x{item.dimensions[1]} | {_format_mean(item.mean_rgb)} | "
                f"{item.alpha_range[0]}..{item.alpha_range[1]} | {binding_text} |"
            )

    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def print_summary(audits: list[TextureAudit]) -> None:
    counts = Counter(item.classification for item in audits)
    class_order = ("legit-flat", "alpha-carrier", "flat-normal", "suspect", "non-flat")
    width = max(len("Class"), *(len(name) for name in class_order))
    print(f"{'Class':<{width}}  Count")
    print(f"{'-' * width}  -----")
    for name in class_order:
        print(f"{name:<{width}}  {counts[name]:>5}")
    print(f"{'total':<{width}}  {len(audits):>5}")
    print(f"\nReport: {REPORT_PATH}")


def main() -> int:
    export_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_EXPORT_DIR
    export_dir = export_dir.expanduser().resolve()
    if not export_dir.is_dir():
        print(f"error: texture export directory does not exist: {export_dir}", file=sys.stderr)
        return 2

    png_paths = sorted(
        (path for path in export_dir.rglob("*") if path.is_file() and path.suffix.casefold() == ".png"),
        key=lambda path: path.relative_to(export_dir).as_posix().casefold(),
    )
    audits = [audit_texture(path, export_dir) for path in png_paths]
    bindings = load_material_bindings(export_dir)
    write_report(export_dir, audits, bindings)
    print_summary(audits)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
