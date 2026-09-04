"""Targeted probe: find every StaticMeshActor slot in 1-Medical whose bound material
path contains "drip" or "glass" (case-insensitive), and report its resolution/texture
state. User-reported (4 Sept 2026): "check like the wall dripping texture cus ik that
was missing and some glass". audit_level_materials.py's broken-slot sample only captures
*unresolved* (null) slots — a drip/glass MI that resolves but is otherwise wrong (bad
blend mode, missing opacity mask, etc.) wouldn't show there, so this checks by name
directly instead.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_drip_glass_materials.py \
    -unattended -nopause -nosplash
"""
import json, os, sys
import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from audit_level_materials import _slot_report, _mesh_component_slots

MAP = os.environ.get("BIOSHOCK_PROBE_MAP", "/Game/BioShockSlice/1-Medical")
OUT = os.path.join(os.environ.get("TEMP", "."), "probe_drip_glass_materials.json")
_KEYWORDS = ("drip", "glass")


def main():
    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    actors_sys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    if not lvl.load_level(MAP):
        raise RuntimeError("could not load %s" % MAP)

    hits = []
    for actor in actors_sys.get_all_level_actors():
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        comp = actor.static_mesh_component
        slots = _mesh_component_slots(comp)
        for slot in slots:
            path = (slot.get("material") or "")
            if not any(k in path.lower() for k in _KEYWORDS):
                continue
            hits.append({
                "actor": actor.get_actor_label(),
                "location": [actor.get_actor_location().x, actor.get_actor_location().y, actor.get_actor_location().z],
                "slot": slot,
            })

    report = {"map": MAP, "hitCount": len(hits), "hits": hits}
    with open(OUT, "w", encoding="utf-8") as h:
        json.dump(report, h, indent=2, default=str)
    unreal.log("[drip-glass-probe] wrote %s (%d hits)" % (OUT, len(hits)))
    return report


if __name__ == "__main__":
    main()
