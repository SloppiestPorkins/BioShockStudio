"""Pure naming policy for texture files imported with multiple engine intents."""

import os
import re


def intent_key(stem: str, srgb: bool, usage: str, is_opacity: bool) -> tuple:
    """Return the identity of one texture file and engine-intent pair."""
    return stem, srgb, usage, is_opacity


def asset_name(
    stem: str,
    srgb: bool,
    usage: str,
    is_opacity: bool,
    *,
    is_primary: bool,
) -> str:
    """Return the deterministic UE asset name for a texture intent."""
    if is_primary:
        return stem
    if is_opacity or usage == "Mask":
        suffix = "mask"
    elif usage == "NormalMap":
        suffix = "n"
    elif usage == "Height":
        suffix = "height"
    elif not srgb:
        suffix = "data"
    else:
        suffix = re.sub(r"[^a-z0-9]+", "_", usage.lower()).strip("_") or "data"
    return "%s_%s" % (stem, suffix)


def classify(entries: list[dict], opacity_pairs: set) -> dict:
    """Classify manifest texture entries by primary intent and UE asset name."""
    classified = []
    primary_by_stem = {}

    for entry in entries:
        is_opacity = (entry.get("material"), entry.get("file")) in opacity_pairs
        srgb = False if is_opacity else entry["colourSpace"] == "Srgb"
        stem = os.path.splitext(entry["file"].replace("\\", "/").rsplit("/", 1)[-1])[0]
        key = intent_key(stem, srgb, entry["usage"], is_opacity)
        classified.append((entry, stem, srgb, is_opacity, key))

        # The primary is the first sRGB diffuse in list order. The first entry is only a
        # fallback, so finding a later colour diffuse replaces it deterministically.
        if stem not in primary_by_stem or (
            srgb
            and entry["usage"] == "Diffuse"
            and not primary_by_stem[stem][1]
        ):
            primary_by_stem[stem] = (key, srgb and entry["usage"] == "Diffuse")

    result = {}
    for entry, stem, srgb, is_opacity, key in classified:
        is_primary = key == primary_by_stem[stem][0]
        result[id(entry)] = {
            "name": asset_name(
                stem,
                srgb,
                entry["usage"],
                is_opacity,
                is_primary=is_primary,
            ),
            "srgb": srgb,
            "is_primary": is_primary,
        }
    return result
