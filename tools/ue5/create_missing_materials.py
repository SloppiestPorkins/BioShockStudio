"""Create material instances ONLY for manifest materials that have none yet (additive, never re-parents).

The full material pass (import_level._import_level_materials) also re-configures existing
instances, which the slice shares -- a refresh once changed 23 parents. This runs that pass on a
filtered manifest: materials whose MI_<name> does not exist, and only their textures. Written for
the Skins-only materials the exporter began emitting on 7 Oct 2026 (posters, ad variants, decals).

Env:
  BIOSHOCK_LEVEL_JSON  manifest with the materials (default Exports/live/1-Medical/1-Medical/1-Medical.ue5-level.json)
  BIOSHOCK_MAT_DEST    instance/texture folder (default /Game/BioShockLevel/1-Medical)

Run: python tools/ue5/ue_run.py tools/ue5/create_missing_materials.py --timeout 3600

Pipeline: entry-point -- live-renderer map preparation.
"""
from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import import_level  # noqa: E402
import live_paths  # noqa: E402

DEST = os.environ.get("BIOSHOCK_MAT_DEST") or live_paths.material_dest()
MI_DIRS = live_paths.mi_dirs()


def main():
    path = os.environ.get("BIOSHOCK_LEVEL_JSON") or live_paths.level_json()
    with open(path, encoding="utf-8") as fh:
        manifest = json.load(fh)

    def exists(name):
        return any(unreal.EditorAssetLibrary.does_asset_exist("%s/MI_%s" % (d, name)) for d in MI_DIRS)

    missing = [m for m in manifest.get("materials") or [] if not exists(m["name"])]
    names = {m["name"] for m in missing}
    filtered = dict(manifest)
    filtered["materials"] = missing
    filtered["textures"] = [t for t in manifest.get("textures") or [] if t.get("material") in names]
    report = {"created": 0, "updated": 0, "skipped": 0, "unsupported": 0}
    unreal.log("MISSING_MATERIALS %d of %d lack an instance; textures %d" % (
        len(missing), len(manifest.get("materials") or []), len(filtered["textures"])))
    if missing:
        made = import_level._import_level_materials(filtered, os.path.dirname(path), DEST, "/Game/BioShockLevel", report)
        unreal.log("MISSING_MATERIALS created %d instances" % len([v for v in made.values() if v]))


main()
