"""Per-level paths for the live renderer's map preparation (one place, any of the 21 levels).

Every live-map script (import_baked_world, create_missing_materials, apply_material_overrides,
apply_baked_props, import_extra_assets) takes its defaults from here, keyed by BIOSHOCK_MAP
(default 1-Medical). Explicit per-script env vars still win.

  live map      /Game/BioShockLive/<map>_Baked   (a COPY; the source map is never modified)
  copied from   the hand-built playable slice for 1-Medical, otherwise /Game/BioShockLevel/<map>
  exports       <project>/Exports/live/<map>/... (export-level, export-vertex-lighting)
                <project>/Exports/baked/<map>/... (export-baked-lightmaps)
"""
from __future__ import annotations

import os

MAP = os.environ.get("BIOSHOCK_MAP", "1-Medical")


def _project():
    import unreal
    return os.path.dirname(unreal.Paths.get_project_file_path())


def live_map():
    return "/Game/BioShockLive/%s_Baked" % MAP


def source_map():
    return "/Game/BioShockSlice/1-Medical" if MAP == "1-Medical" else "/Game/BioShockLevel/%s" % MAP


def export_root():
    """Directory holding <map>.ue5-level.json, Meshes/, Rigs/, Textures/ from export-level."""
    return os.path.join(_project(), "Exports", "live", MAP, MAP)


def level_json():
    return os.path.join(export_root(), "%s.ue5-level.json" % MAP)


def vertex_lighting_json():
    return os.path.join(_project(), "Exports", "live", MAP, "vertex_lighting.json")


def baked_dir():
    return os.path.join(_project(), "Exports", "baked", MAP, MAP)


def material_dest():
    return "/Game/BioShockLevel/%s" % MAP


def baked_world_dest():
    return "/Game/BioShockLive/BakedWorld/%s" % MAP


def mi_dirs():
    dirs = ["/Game/BioShockLevel/%s/Materials" % MAP]
    if MAP == "1-Medical":
        dirs += ["/Game/BioShockSlice/Content/1-Medical/Materials", "/Game/BioShockSlice/Content/Meshes/PropMat"]
    return dirs
