"""Revert fix_translucent_alpha_opacity.py's change. That fix was based on a wrong diagnosis:
Wall_Leak_diff/reinforcedglass_diffuse's low-average alpha was assumed to be packed spec/gloss
noise, but a visual pixel-map of the actual channel data shows a coherent drip-streak gradient
(Wall_Leak) and a coherent wire-mesh grid (reinforced glass) -- genuine, deliberate coverage
masks, not noise. Wiring a constant 1.0 into Opacity instead broke the master's compile outright
(user report 4 Sept 2026: "untextured file, gray with squares" -- UE's default/error-material
checker, not just "looks solid"). Reverts every master fix_translucent_alpha_opacity.py touched
back to sampling the BaseColor texture's Alpha channel into Opacity, matching import_bioshock.py's
current (reverted) behaviour.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/undo_translucent_alpha_opacity.py \
    -unattended -nopause -nosplash
Env:
  BIOSHOCK_OPACITY_REPORT   fix_translucent_alpha_opacity.py's own report JSON
                            (default %TEMP%/fix_translucent_alpha_opacity.json)
"""
import json, os, sys
import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_bioshock

REPORT = os.environ.get(
    "BIOSHOCK_OPACITY_REPORT",
    os.path.join(os.environ.get("TEMP", "."), "fix_translucent_alpha_opacity.json"),
)
OUT = os.path.join(os.environ.get("TEMP", "."), "undo_translucent_alpha_opacity.json")


def _restore(master):
    edit = unreal.MaterialEditingLibrary
    base_node = edit.get_material_property_input_node(master, unreal.MaterialProperty.MP_BASE_COLOR)
    if base_node is None:
        return False
    edit.connect_material_property(base_node, "A", unreal.MaterialProperty.MP_OPACITY)
    # The stray Constant node the bad fix added is left in place, disconnected -- harmless
    # (unused expressions don't affect the compiled shader) and safer than risking a delete API
    # mismatch on a script meant to run once.
    edit.recompile_material(master)
    unreal.EditorAssetLibrary.save_loaded_asset(master)
    return True


def main():
    with open(REPORT, "r", encoding="utf-8") as handle:
        report = json.load(handle)

    out = {"restored": [], "skipped": []}
    for entry in report.get("fixed") or []:
        path = entry["master"]
        master = import_bioshock._load_if_exists(path)
        if master is None:
            out["skipped"].append(entry)
            continue
        ok = _restore(master)
        (out["restored"] if ok else out["skipped"]).append(entry)

    with open(OUT, "w", encoding="utf-8") as h:
        json.dump(out, h, indent=2, default=str)
    unreal.log("[undo-translucent-alpha-opacity] wrote %s (%d restored / %d skipped)" % (
        OUT, len(out["restored"]), len(out["skipped"])))
    return out


if __name__ == "__main__":
    main()
