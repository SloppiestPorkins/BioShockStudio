"""audit_level_materials.py's _master_null_texture_params only checks BaseColor/Emissive/
Normal -- never Opacity or OpacityMask. Drip decals and glass are Masked/Translucent
materials (see M_BioShock_Shader_*_Masked_V4 / *_mask_V5 masters), where a NULL opacity
or opacity-mask texture makes the whole surface render as fully clipped/invisible even
though BaseColor is bound correctly -- exactly what audit_level_materials.py would call
"fine". This checks MP_OPACITY and MP_OPACITY_MASK specifically on every master material
that MI_*drip*/MI_*glass* instances resolve back to.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_drip_glass_opacity.py \
    -unattended -nopause -nosplash
"""
import json, os, sys
import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from audit_level_materials import _resolve_parent_material, _asset_path

MAP = os.environ.get("BIOSHOCK_PROBE_MAP", "/Game/BioShockSlice/1-Medical")
OUT = os.path.join(os.environ.get("TEMP", "."), "probe_drip_glass_opacity.json")
_KEYWORDS = ("drip", "glass")


def _opacity_state(master):
    edit = unreal.MaterialEditingLibrary
    out = {}
    for prop, label in (
        (unreal.MaterialProperty.MP_OPACITY, "Opacity"),
        (unreal.MaterialProperty.MP_OPACITY_MASK, "OpacityMask"),
    ):
        node = edit.get_material_property_input_node(master, prop)
        info = {"connected": node is not None, "className": node.get_class().get_name() if node is not None else None}
        if isinstance(node, unreal.MaterialExpressionTextureSampleParameter2D):
            tex = node.get_editor_property("texture")
            info["textureBound"] = tex is not None
            info["texturePath"] = _asset_path(tex)
        out[label] = info
    try:
        out["blendMode"] = str(master.get_editor_property("blend_mode"))
    except Exception:  # noqa: BLE001
        out["blendMode"] = None
    return out


def main():
    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors_sys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    if not lvl.load_level(MAP):
        raise RuntimeError("could not load %s" % MAP)

    checked_masters = {}
    hits = []
    for actor in actors_sys.get_all_level_actors():
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        comp = actor.static_mesh_component
        try:
            materials = comp.get_materials() if comp else []
        except Exception:  # noqa: BLE001
            materials = []
        for index, mi in enumerate(materials or []):
            if mi is None:
                continue
            path = _asset_path(mi) or ""
            if not any(k in path.lower() for k in _KEYWORDS):
                continue
            master = _resolve_parent_material(mi)
            master_path = _asset_path(master)
            if master_path not in checked_masters:
                checked_masters[master_path] = _opacity_state(master) if master is not None else {"error": "no master"}
            hits.append({
                "actor": actor.get_actor_label(),
                "instance": path,
                "master": master_path,
            })

    report = {
        "map": MAP,
        "instanceHitCount": len(hits),
        "masters": checked_masters,
    }
    with open(OUT, "w", encoding="utf-8") as h:
        json.dump(report, h, indent=2, default=str)
    unreal.log("[drip-glass-opacity] wrote %s (%d masters)" % (OUT, len(checked_masters)))
    return report


if __name__ == "__main__":
    main()
