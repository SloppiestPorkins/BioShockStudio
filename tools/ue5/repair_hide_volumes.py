"""Hide gameplay-volume brushes that are drawing as green geometry.

import_level spawns FluidVolume/CascadingWaterVolume/TriggerVolume as UE5 volume actors and
documents them as invisible. They are not: a spawned PhysicsVolume keeps a UBrushComponent, which
is a real renderable primitive, and Unreal draws volume brushes GREEN. A -game capture of the
Medical Pavilion entrance came back with a saturated green bar (RGB ~80,255,30) across the bottom
of the window - three overlapping water volumes drawn as solid geometry.

This is invisible in the editor by construction, because volume brushes are SUPPOSED to draw
there. It only shows in a game-side render, which is why nothing caught it until the capture
harness could be aimed.

Fixed at source in import_level._hide_volume_in_game; this repairs maps already on disk.
Collision is untouched - being inside the volume is the whole point of it.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_hide_volumes.py \
    -unattended -nopause -nosplash
Env: BIOSHOCK_HIDEVOL_MAP (default /Game/BioShockSlice/1-Medical)
     BIOSHOCK_HIDEVOL_DRY=1 to report without saving

Pipeline: one-off -- import_level now sets hidden_in_game/visible on spawned volumes; this
fixed maps saved before that.
"""

from __future__ import annotations

import json
import os

import unreal

MAP = os.environ.get("BIOSHOCK_HIDEVOL_MAP", "/Game/BioShockSlice/1-Medical")
DRY = os.environ.get("BIOSHOCK_HIDEVOL_DRY", "0") == "1"
OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "_reports", "repair_hide_volumes.json")


def main():
    report = {"map": MAP, "dryRun": DRY, "error": None,
              "volumes": 0, "componentsHidden": 0, "alreadyHidden": 0, "actors": []}
    if not unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(MAP):
        report["error"] = "could not load %s" % MAP
        _write(report)
        raise RuntimeError(report["error"])

    for actor in unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors():
        if not isinstance(actor, unreal.Volume):
            continue
        report["volumes"] += 1
        entry = {"label": actor.get_actor_label(), "class": type(actor).__name__,
                 "hidden": 0, "already": 0}
        for component in actor.get_components_by_class(unreal.PrimitiveComponent):
            try:
                was_hidden = bool(component.get_editor_property("hidden_in_game"))
                was_invisible = not bool(component.get_editor_property("visible"))
            except Exception:  # noqa: BLE001
                continue
            if was_hidden and was_invisible:
                entry["already"] += 1
                report["alreadyHidden"] += 1
                continue
            if DRY:
                entry["hidden"] += 1
                continue
            component.set_editor_property("hidden_in_game", True)
            component.set_editor_property("visible", False)
            # Re-read: this project has repeatedly produced tools that counted intent.
            if (bool(component.get_editor_property("hidden_in_game"))
                    and not bool(component.get_editor_property("visible"))):
                entry["hidden"] += 1
                report["componentsHidden"] += 1
        if entry["hidden"] or entry["already"]:
            report["actors"].append(entry)

    if not DRY and report["componentsHidden"]:
        world = unreal.EditorLevelLibrary.get_editor_world()
        # save_map, not save_current_level: the latter routes through
        # InternalPromptForCheckoutAndSave, whose Slate notification asserts headless.
        if not unreal.EditorLoadingAndSavingUtils.save_map(world, MAP):
            report["error"] = "save_map failed"
            _write(report)
            raise RuntimeError(report["error"])
        report["saved"] = True

    _write(report)
    unreal.log("[hidevol] volumes=%d hidden=%d alreadyHidden=%d" % (
        report["volumes"], report["componentsHidden"], report["alreadyHidden"]))
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
