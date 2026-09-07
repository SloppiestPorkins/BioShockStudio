"""Measure where FidgetShotgun puts the hands vs where the WP_Shotgun mesh sits.

Spawns a ShockPlayer, equips the Shotgun, advances past equip so FidgetShotgun is
posing the ViewHands, then samples — in the FIRST-PERSON CAMERA's space (+X fwd,
+Y right, +Z up) — the hand bones and every shotgun bone, plus the shotgun mesh
local bounding box. The goal is a data-driven placement: land the shotgun grip on
the right hand and the forestock under the left hand instead of guessing offsets.

  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_shotgun_grip.py \
    -unattended -nopause -nosplash
Writes %TEMP%/shotgun_grip_probe.json (or BIOSHOCK_SHOTGUN_GRIP_OUT).
"""

from __future__ import annotations

import json
import os

import unreal

OUT = os.environ.get(
    "BIOSHOCK_SHOTGUN_GRIP_OUT",
    os.path.join(os.environ.get("TEMP", "."), "shotgun_grip_probe.json"),
)

HAND_BONES = (
    "Bip01_R_Hand", "Bip01_L_Hand", "Bip01_R_Forearm", "Bip01_L_Forearm",
    "R_grip", "R_Grip",
    "kBone_L_Thumb1", "kBone_L_Thumb3", "kBone_L_Index1", "kBone_L_Index2",
    "kBone_L_Index3", "kBone_L_Middle1", "kBone_L_Middle3", "kBone_L_Ring1",
    "kBone_L_Pinky1",
    "kBone_R_Thumb1", "kBone_R_Index1", "kBone_R_Middle1",
)


def _v(x):
    return [round(x.x, 3), round(x.y, 3), round(x.z, 3)]


def _cam_space(cam_xf, world_pt):
    return _v(cam_xf.inverse_transform_location(world_pt))


def _comp_bone_names(comp):
    out = []
    try:
        n = comp.get_num_bones()
    except Exception:
        n = 0
    for i in range(n):
        try:
            out.append(str(comp.get_bone_name(i)))
        except Exception:
            break
    return out


def _bone_world(comp, name):
    try:
        return comp.get_socket_location(unreal.Name(name))
    except Exception:
        return None


def main():
    report = {"failures": [], "samples": {}}
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    if not player_cls:
        report["failures"].append("ShockPlayer class missing")
        _write(report)
        return report

    player = subsystem.spawn_actor_from_class(
        player_cls, unreal.Vector(0, 0, 100), unreal.Rotator(0, 0, 0)
    )
    if not player:
        report["failures"].append("spawn player")
        _write(report)
        return report

    weapon = player.give_weapon_by_def(unreal.Name("Shotgun"), 3)
    if not weapon:
        report["failures"].append("GiveWeaponByDef(Shotgun) null")
        subsystem.destroy_actor(player)
        _write(report)
        return report
    player.equip_weapon(weapon)

    view_hands = player.get_editor_property("view_hands")
    cam = player.get_editor_property("first_person_camera")
    gun = weapon.get_editor_property("mesh")

    # Sample L_Hand vs R_grip across the FidgetShotgun loop to see how rigid the two-hand
    # hold is (if L_Hand swings a lot relative to R_grip, a frame-0 bake is wrong).
    sway = []
    if view_hands and cam:
        for step in range(0, 60, 6):
            cam_xf0 = cam.get_world_transform()
            rg = view_hands.get_socket_location(unreal.Name("R_grip"))
            lh = view_hands.get_socket_location(unreal.Name("Bip01_L_Hand"))
            rel = cam_xf0.inverse_transform_location(lh) - cam_xf0.inverse_transform_location(rg)
            sway.append({"t": round(step * 0.05, 2), "LHand_minus_Rgrip_cam": _v(rel)})
            for _ in range(6):
                player.advance_view_hands_animation_for_verify(0.05)
    report["fidgetSway"] = sway
    report["playingAnim"] = str(player.get_playing_view_hands_animation_name_for_verify())
    report["activeGripSocket"] = str(player.get_active_grip_socket_for_verify())

    if not (view_hands and cam and gun):
        report["failures"].append(
            "component missing: view_hands=%s cam=%s gun=%s"
            % (bool(view_hands), bool(cam), bool(gun))
        )
        subsystem.destroy_actor(player)
        _write(report)
        return report

    for c in (view_hands, gun):
        for m in ("refresh_bone_transforms", "tick_component", "update_bounds"):
            try:
                getattr(c, m)(0.0) if m == "tick_component" else getattr(c, m)()
            except Exception:
                pass
    cam_xf = cam.get_world_transform()

    report["cameraWorld"] = {
        "loc": _v(cam_xf.translation),
        "rot": [round(cam_xf.rotation.rotator().pitch, 2),
                round(cam_xf.rotation.rotator().yaw, 2),
                round(cam_xf.rotation.rotator().roll, 2)],
    }
    report["fov"] = round(cam.get_editor_property("field_of_view"), 2)

    # --- hands ---
    hb = {}
    all_hand_bones = _comp_bone_names(view_hands)
    report["handBoneCount"] = len(all_hand_bones)
    for name in HAND_BONES:
        w = _bone_world(view_hands, name)
        if w is not None and name in all_hand_bones:
            hb[name] = {"cam": _cam_space(cam_xf, w), "world": _v(w)}
    # also the grip socket
    for sock in ("Launcher", "Shotgun"):
        try:
            if view_hands.does_socket_exist(unreal.Name(sock)):
                w = view_hands.get_socket_location(unreal.Name(sock))
                hb["socket:%s" % sock] = {"cam": _cam_space(cam_xf, w), "world": _v(w)}
        except Exception:
            pass
    report["hands"] = hb
    report["allHandBones"] = all_hand_bones

    # --- shotgun mesh ---
    gb = {}
    gun_bones = _comp_bone_names(gun)
    for name in gun_bones:
        w = _bone_world(gun, name)
        if w is not None:
            gb[name] = {"cam": _cam_space(cam_xf, w), "world": _v(w)}
    report["gunBones"] = gb
    report["gunBoneNames"] = gun_bones

    gun_xf = gun.get_world_transform()
    report["gunComponentWorld"] = {
        "loc": _v(gun_xf.translation),
        "rot": [round(gun_xf.rotation.rotator().pitch, 2),
                round(gun_xf.rotation.rotator().yaw, 2),
                round(gun_xf.rotation.rotator().roll, 2)],
        "relLoc": _v(gun.get_editor_property("relative_location")),
        "relRot": [round(gun.get_editor_property("relative_rotation").pitch, 2),
                   round(gun.get_editor_property("relative_rotation").yaw, 2),
                   round(gun.get_editor_property("relative_rotation").roll, 2)],
    }

    sk = gun.get_skeletal_mesh_asset()
    if sk:
        b = sk.get_bounds()
        report["gunMeshBounds"] = {
            "origin": _v(b.origin), "extent": _v(b.box_extent),
            "radius": round(b.sphere_radius, 2),
        }
    # local-space bone positions (component space, ref pose independent of attach)
    # component-space bone offsets = world bone minus gun component world loc, un-rotated
    local = {}
    inv = gun_xf.inverse()
    for name in gun_bones:
        w = _bone_world(gun, name)
        if w is not None:
            local[name] = _v(inv.transform_location(w))
    report["gunBonesComponentSpace"] = local

    # After the runtime's AlignShotgunToHandPose: how does the barrel sit relative to each
    # left-hand bone? Sample points along SG_Body -> SG_Pump and past it.
    body_w = _bone_world(gun, "SG_Body")
    pump_w = _bone_world(gun, "SG_Pump")
    lhand = {n: _bone_world(view_hands, n) for n in (
        "Bip01_L_Hand", "kBone_L_Index1", "kBone_L_Middle1", "kBone_L_Ring1",
        "kBone_L_Pinky1", "kBone_L_Thumb1", "kBone_L_Index2", "kBone_L_Middle2")}
    if body_w and pump_w:
        axis = (pump_w - body_w)
        blen = axis.length()
        axis = axis / blen if blen > 0 else axis
        barrel_pts = {}
        for frac in (0.8, 1.0, 1.2, 1.4):
            p = body_w + axis * (blen * frac)
            near = {}
            for bn, bw in lhand.items():
                if bw is None:
                    continue
                d = bw - p
                perp = d - axis * (d | axis)  # perpendicular gap to barrel line
                near[bn] = {"gap": round(perp.length(), 2), "along": round(d | axis, 2)}
            barrel_pts["frac_%.1f" % frac] = {"pt_cam": _cam_space(cam_xf, p), "toBones": near}
        report["barrelVsLeftHand"] = barrel_pts
    report["gunFinalRot_cam"] = None
    try:
        gxf = gun.get_world_transform()
        # gun local axes expressed in camera space
        report["gunFinalAxes_cam"] = {
            "fwd": _v(cam_xf.inverse_transform_vector(gxf.transform_vector(unreal.Vector(1,0,0)))),
            "right": _v(cam_xf.inverse_transform_vector(gxf.transform_vector(unreal.Vector(0,1,0)))),
            "up": _v(cam_xf.inverse_transform_vector(gxf.transform_vector(unreal.Vector(0,0,1)))),
        }
    except Exception as e:
        report["gunFinalAxes_cam"] = str(e)

    subsystem.destroy_actor(player)
    _write(report)
    unreal.log("[shotgun-grip] wrote %s" % OUT)
    return report


def _write(report):
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)


if __name__ == "__main__":
    import traceback
    try:
        main()
    except Exception:
        try:
            with open(OUT, "a", encoding="utf-8") as f:
                f.write("\n\nEXC:\n" + traceback.format_exc())
        except Exception:
            pass
        raise
