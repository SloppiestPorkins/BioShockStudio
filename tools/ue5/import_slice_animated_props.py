"""Place the 1-Medical ScriptableMover props into the playable slice as AShockAnimatedProp.

E2 (`e4c91f5`) built `AShockAnimatedProp` (transform-driven spin + keyframe move) and made
`ShockActionPlayAnimation` / `ChangeAnimationRate` real, but the slice predates it — the
meat-locker door, the morgue door, the curtains, the turret-trap panels all sit static.

This places every `ScriptableMover` as an `AShockAnimatedProp` in KeyframeMove mode with its
authored `KeyPos` / `KeyRot` as the target key. `PropLabel` = the manifest label, so a script
`ActionPlayAnimation` targeting that label (the movers' `triggeredBy` scripts) drives it via
`PlayScriptedMotion`. Idempotent (`BioShockKey=`), wired into `setup_playable_slice`.

BioShock rotation units: 65536 = 360 degrees. KeyPos is a component-relative offset.

Duplicate-collider note (30 Sept 2026 audit, `task_977a74fe`): ScriptableMover / Fan / Mover are
already denylisted by `import_level._should_place_mesh_instance` (deferred to
`_import_animated_props`, which also destroys any leftover `instance:` mesh). So unlike
stations/pickups/switches, movers do not get a second BlockAll StaticMeshActor from the generic
pipeline. Reusing `import_slice_pickups._place` still calls `destroy_instance_duplicates` — a
no-op here, kept for consistency.
"""
from __future__ import annotations

import json
import os
import struct
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_level  # noqa: E402
import import_slice_pickups as pk  # noqa: E402  (reuse _place / _load_mesh)

SLICE_MAP = "/Game/BioShockSlice/1-Medical"
DEFAULT_MANIFEST = pk.DEFAULT_MANIFEST
OUT = os.path.join(os.environ.get("TEMP", "."), "import_slice_animated_props.json")

MOVE_DURATION = 1.6

# EShockAnimatedPropMode / EShockPropLoopMode
MODE_KEYFRAME = 1
LOOP_ONESHOT, LOOP_PINGPONG, LOOP_LOOP = 0, 1, 2

_LOOPING_INITIAL_STATES = {"LoopMove", "ConstantLoop", "ContinuousLoop"}


def _prop_keys(entry):
    """Return (KeyPos xyz, KeyRot pitch/yaw/roll deg) from the mover's serialized properties."""
    kp = kr = None
    for p in entry.get("properties") or []:
        if p.get("arrayIndex") != 1:
            continue
        h = bytes.fromhex(p.get("valueHex") or "")
        if p.get("name") == "KeyPos" and len(h) == 12:
            kp = struct.unpack("<3f", h)
        elif p.get("name") == "KeyRot" and len(h) == 12:
            i = struct.unpack("<3i", h)
            kr = tuple(v * 360.0 / 65536.0 for v in i)
    return kp, kr


def main(manifest_path=None, map_path=SLICE_MAP, save=True):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LEVEL_JSON", DEFAULT_MANIFEST)
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    level = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not level.load_level(map_path):
        raise RuntimeError("could not load %s" % map_path)

    prop_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockAnimatedProp")
    if prop_cls is None:
        raise RuntimeError("AShockAnimatedProp missing — build the plugin first")

    existing = import_level._existing_by_key()
    report = {"manifest": manifest_path, "movers": 0, "details": []}

    for entry in manifest.get("actors") or []:
        if entry.get("className") != "ScriptableMover":
            continue
        label = str(entry.get("label") or entry.get("name") or entry["key"])
        kp, kr = _prop_keys(entry)
        actor, _created = pk._place(prop_cls, entry, existing)
        if actor is None:
            continue

        target = unreal.Transform()
        target.set_editor_property(
            "translation", unreal.Vector(*(kp or (0.0, 0.0, 0.0))))
        if kr:
            target.set_editor_property("rotation", unreal.Rotator(kr[0], kr[1], kr[2]).quaternion())

        loop = LOOP_ONESHOT
        state = (entry.get("mover") or {}).get("initialState")
        if state in _LOOPING_INITIAL_STATES:
            loop = LOOP_LOOP

        actor.configure_keyframe_motion(
            unreal.Name(label),
            [unreal.Transform(), target],
            MOVE_DURATION,
            unreal.ShockPropLoopMode.LOOP if loop == LOOP_LOOP else unreal.ShockPropLoopMode.ONE_SHOT)

        mesh = pk._load_mesh(entry.get("staticMesh"))
        comp = actor.get_editor_property("prop_mesh")
        if mesh and comp:
            comp.set_static_mesh(mesh)

        report["movers"] += 1
        report["details"].append({"label": label, "keyPos": kp, "keyRotDeg": kr, "loop": loop})

    if save:
        level.save_current_level()

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    unreal.log("[slice-animated-props] %s" % json.dumps(report))
    unreal.log("Success - 0 error(s)")
    return report


if __name__ == "__main__":
    main()
