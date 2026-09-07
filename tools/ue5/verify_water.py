"""Headless verify: AShockWaterVolume surface + IsActorInWater + underwater PP fade.

Spawns volumes in the editor world (does not require 1-Medical). Asserts:
  - configure_from_half_extent places a visible surface with a material
  - player IsInWaterForVerify true inside / false outside
  - underwater blend fades toward 1 when inside, toward 0 when outside

Materials: runs author_water_material.ensure_water_materials first.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/verify_water.py \\
    -unattended -nopause -nosplash
Env: BIOSHOCK_ACTION_OUT (default %TEMP%/verify_water.json)
"""

from __future__ import annotations

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))


def _log(message):
    unreal.log("[bioshock-water] %s" % message)


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _spawn(subsystem, cls, label, loc, rot=None):
    rot = rot or unreal.Rotator(0.0, 0.0, 0.0)
    actor = subsystem.spawn_actor_from_class(cls, loc, rot)
    if actor:
        actor.set_actor_label(label)
    return actor


def _destroy_all(subsystem, actors):
    for actor in actors:
        if actor:
            subsystem.destroy_actor(actor)


def main(out):
    report = {"failures": [], "results": []}
    failures = report["failures"]

    def check(name, ok, detail=None):
        entry = {"name": name, "ok": bool(ok)}
        if detail is not None:
            entry["detail"] = detail
        report["results"].append(entry)
        if not ok:
            failures.append("%s: %s" % (name, detail))

    import author_water_material

    mat_report = {"failures": [], "assets": {}}
    author_water_material.ensure_water_materials(mat_report)
    report["materials"] = mat_report.get("assets") or {}
    check(
        "materials_authored",
        bool(mat_report.get("assets", {}).get("M_ShockWater"))
        and not mat_report.get("failures"),
        mat_report.get("failures") or mat_report.get("assets"),
    )

    water_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWaterVolume")
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    if not water_cls or not player_cls:
        failures.append("ShockWaterVolume or ShockPlayer class missing")
        _write(out, report)
        raise RuntimeError("water:\n- " + "\n- ".join(failures))

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    spawned = []

    still = _spawn(
        subsystem, water_cls, "VerifyWaterStill", unreal.Vector(0.0, 0.0, 100.0)
    )
    spawned.append(still)
    if still:
        still.configure_from_half_extent(unreal.Vector(400.0, 300.0, 80.0), False)
        still.refresh_overlaps_for_verify()
        has_surface = bool(still.has_visible_surface_for_verify())
        check("still_surface", has_surface)
        report["still"] = {
            "cascading": bool(getattr(still, "cascading", False)),
            "hasSurface": has_surface,
        }

    cascade = _spawn(
        subsystem, water_cls, "VerifyWaterCascade", unreal.Vector(2000.0, 0.0, 100.0)
    )
    spawned.append(cascade)
    if cascade:
        cascade.configure_from_half_extent(unreal.Vector(40.0, 40.0, 200.0), True)
        check("cascade_surface", bool(cascade.has_visible_surface_for_verify()))
        check(
            "cascade_flag",
            bool(getattr(cascade, "cascading", False)) is True,
            getattr(cascade, "cascading", None),
        )

    player = _spawn(
        subsystem, player_cls, "VerifyWaterPlayer", unreal.Vector(0.0, 0.0, 100.0)
    )
    spawned.append(player)
    if player and still:
        still.refresh_overlaps_for_verify()
        in_water = bool(player.is_in_water_for_verify())
        check("player_in_water", in_water)

        for _ in range(12):
            player.advance_underwater_post_process_for_verify(0.05)
        blend_in = float(player.get_underwater_blend_for_verify())
        report["blendIn"] = blend_in
        check("underwater_blend_in", blend_in >= 0.9, blend_in)

        player.set_actor_location(unreal.Vector(5000.0, 0.0, 100.0), False, False)
        still.refresh_overlaps_for_verify()
        out_water = not bool(player.is_in_water_for_verify())
        check("player_out_of_water", out_water)
        for _ in range(12):
            player.advance_underwater_post_process_for_verify(0.05)
        blend_out = float(player.get_underwater_blend_for_verify())
        report["blendOut"] = blend_out
        check("underwater_blend_out", blend_out <= 0.1, blend_out)

    _destroy_all(subsystem, spawned)
    report["water"] = "ok" if not failures else "fail"
    report["visual"] = (
        "headless cannot judge look — confirm flooded-room surface + underwater grade via "
        "capture_shot.ps1 / PIE on /Game/BioShockSlice/1-Medical after re-import or "
        "repair_water_surfaces.py"
    )
    _write(out, report)
    if failures:
        raise RuntimeError("water:\n- " + "\n- ".join(failures))
    _log("PASS water")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "verify_water.json"),
        )
    )
