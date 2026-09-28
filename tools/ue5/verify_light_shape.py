"""Verify W-BUG-01 light shape / rotation / cone against the real Medical manifest.

Headless (`-run=pythonscript`). Spawns from the authored `lights[].effect` census — not synthetic
ordinals. Asserts:

  (a) every effect=2 (spot) light with radius → SpotLight, attenuation + rotation + OuterConeAngle
  (b) every effect=3 (sun) light -> SpotLight, never UE5's scene-wide DirectionalLight (28 Sept
      correction -- see the check's own comment)
  (c) point-shaped lights with radius remain PointLight (regression)
  (d) an existing wrong-class actor under a spot key is destroyed and replaced, not reused
"""

import json
import math
import os
import sys
from collections import Counter

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_level


def _tag_value(actor, prefix):
    for tag in actor.tags:
        text = str(tag)
        if text.startswith(prefix):
            return text[len(prefix):]
    return None


def _collect_by_key():
    found = {}
    for actor in import_level._actor_subsystem().get_all_level_actors():
        if not import_level._is_imported_light_actor(actor):
            continue
        key = _tag_value(actor, import_level.KEY_TAG_PREFIX)
        if key:
            found[key] = actor
    return found


def _expected_rotation_degrees(light, actors_by_key):
    raw = light.get("rotation")
    if not raw:
        actor_doc = actors_by_key.get(light["key"])
        raw = (actor_doc or {}).get("rotation")
    if not raw:
        return None
    pitch, yaw, roll = raw
    scale = import_level.ROTATOR_TO_DEGREES
    return (roll * scale, pitch * scale, yaw * scale)


def _rotation_close(actor, expected_rpy, tol_deg=0.5):
    """Compare aim DIRECTION, not raw roll/pitch/yaw.

    A spotlight's rotation only matters through where it points, and a large share of Medical's
    ceiling/wall fixtures are aimed straight up or down (pitch ~= +-90 deg). At that pole, roll and
    yaw rotate about the same physical axis (gimbal lock): UE5's own rotator normalisation can
    report the identical orientation as any split between "all roll" and "all yaw", which does not
    equal the raw manifest triple's own split even when the resulting light direction is exactly
    right. Comparing forward vectors (equivalently, the rotation each represents) is pole-safe;
    comparing the three Euler components directly is not.
    """
    got_forward = unreal.MathLibrary.get_forward_vector(actor.get_actor_rotation())
    expected_forward = unreal.MathLibrary.get_forward_vector(unreal.Rotator(
        roll=expected_rpy[0], pitch=expected_rpy[1], yaw=expected_rpy[2]))
    dot = (
        got_forward.x * expected_forward.x
        + got_forward.y * expected_forward.y
        + got_forward.z * expected_forward.z)
    # Both are unit vectors (rotating a unit X axis); clamp for float noise before acos.
    angle_deg = math.degrees(math.acos(max(-1.0, min(1.0, dot))))
    return angle_deg <= tol_deg


def main(manifest_path=None, report_path=None):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LIGHT_MANIFEST")
    report_path = report_path or os.environ.get("BIOSHOCK_LIGHT_SHAPE_OUT")
    if not manifest_path:
        raise RuntimeError("Set BIOSHOCK_LIGHT_MANIFEST to a level JSON.")
    if not report_path:
        raise RuntimeError("Set BIOSHOCK_LIGHT_SHAPE_OUT to the JSON report path.")

    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    actors_by_key = {a["key"]: a for a in (manifest.get("actors") or []) if a.get("key")}
    lights = manifest.get("lights") or []

    spots = []
    suns = []
    points = []
    for light in lights:
        shape = import_level._light_shape(light)
        radius = light.get("radius")
        has_radius = radius is not None and float(radius) > 0
        if shape == "spot" and has_radius:
            spots.append(light)
        elif shape == "sun":
            suns.append(light)
        elif shape == "point" and has_radius:
            points.append(light)

    report = {
        "package": manifest.get("package"),
        "census": {
            "effectValues": {},
            "coneSet": sum(1 for light in lights if light.get("cone") is not None),
            "spots": len(spots),
            "suns": len(suns),
            "pointsWithRadius": len(points),
        },
        "coneFormula": "cos(half_angle_deg) = 1 - cone/255",
        "shapeMap": dict(import_level._UE2_LIGHT_EFFECT_TO_SHAPE),
        "checks": [],
        "error": None,
    }
    report["census"]["effectValues"] = {
        str(k): v for k, v in Counter(light.get("effect") for light in lights).items()
    }

    if not spots:
        raise RuntimeError(
            "Medical manifest has no effect=2 spot lights with radius — cannot verify shape map")
    if not points:
        raise RuntimeError("Medical manifest has no point lights — regression case missing")

    failures = []

    def check(name, ok, detail=None):
        report["checks"].append({"name": name, "ok": bool(ok), "detail": detail})
        if not ok:
            failures.append("%s: %s" % (name, detail))

    # --- (d) negative case: wrong-class squatter under a spot key must be replaced ---
    probe = spots[0]
    probe_key = probe["key"]
    existing = import_level._existing_by_key()
    old = existing.get(probe_key)
    if old is not None:
        import_level._actor_subsystem().destroy_actor(old)
        existing.pop(probe_key, None)
    squatter = import_level._actor_subsystem().spawn_actor_from_class(
        unreal.PointLight,
        unreal.Vector(*import_level._to_unreal_location(probe.get("location", [0, 0, 0]))))
    if squatter is None:
        raise RuntimeError("failed to spawn PointLight squatter for negative case")
    squatter.tags = [unreal.Name(import_level.KEY_TAG_PREFIX + probe_key)]
    existing[probe_key] = squatter
    squatter_id = squatter.get_name()

    import_report = {"created": 0, "updated": 0, "skipped": 0, "unsupported": 0}
    handled = set()
    import_level._import_lights(manifest, existing, import_report, handled)
    report["import"] = import_report

    by_key = _collect_by_key()
    replaced = by_key.get(probe_key)
    check(
        "wrong_class_replaced",
        replaced is not None
        and isinstance(replaced, unreal.SpotLight)
        and replaced.get_name() != squatter_id,
        "got %s name=%s squatter was %s"
        % (type(replaced).__name__ if replaced else None,
           replaced.get_name() if replaced else None,
           squatter_id))

    # --- (a) spots ---
    spot_ok = 0
    for light in spots:
        actor = by_key.get(light["key"])
        if actor is None:
            failures.append("spot missing %s" % light["key"])
            continue
        if not isinstance(actor, unreal.SpotLight):
            failures.append(
                "spot %s is %s not SpotLight" % (light["key"], type(actor).__name__))
            continue
        component = actor.get_editor_property("light_component")
        radius = float(component.get_editor_property("attenuation_radius"))
        if abs(radius - float(light["radius"])) > 0.5:
            failures.append(
                "spot %s radius %s != %s" % (light["key"], radius, light["radius"]))
            continue
        cone_byte = light.get("cone")
        if cone_byte is None:
            cone_byte = import_level._DEFAULT_SPOT_CONE_BYTE
        expected_cone = import_level._cone_half_angle_degrees(cone_byte)
        got_cone = float(component.get_editor_property("outer_cone_angle"))
        if abs(got_cone - expected_cone) > 0.05:
            failures.append(
                "spot %s outer_cone_angle %s != %s (cone byte %s)"
                % (light["key"], got_cone, expected_cone, cone_byte))
            continue
        expected_rot = _expected_rotation_degrees(light, actors_by_key)
        if expected_rot is None:
            failures.append("spot %s has no rotation in lights[] or actors[]" % light["key"])
            continue
        if not _rotation_close(actor, expected_rot):
            got = actor.get_actor_rotation()
            failures.append(
                "spot %s rotation (r,p,y)=(%s,%s,%s) != expected %s"
                % (light["key"], got.roll, got.pitch, got.yaw, expected_rot))
            continue
        spot_ok += 1
    check("all_spots_ok", spot_ok == len(spots), "%d/%d" % (spot_ok, len(spots)))

    # --- (b) suns / directionals ---
    # 28 Sept correction: sun/directional shapes are real, individually-placed BioShock lights.
    # UE5's DirectionalLight is a positionless, whole-scene singleton -- spawning six of them (as
    # Medical's census has) produces the editor's own "multiple directional lights are competing"
    # warning and starves water/forward-shaded surfaces of a deterministic light, which is exactly
    # what the user's live PIE report showed as an untextured/checkerboard water surface. These now
    # spawn as a real local SpotLight (a real reach, a wide default cone) like every other placed
    # light, never the scene-wide actor.
    sun_ok = 0
    for light in suns:
        actor = by_key.get(light["key"])
        if actor is None:
            failures.append("sun missing %s" % light["key"])
            continue
        if not isinstance(actor, unreal.SpotLight):
            failures.append(
                "sun %s is %s not SpotLight (a DirectionalLight competes scene-wide)"
                % (light["key"], type(actor).__name__))
            continue
        expected_rot = _expected_rotation_degrees(light, actors_by_key)
        if expected_rot is not None and not _rotation_close(actor, expected_rot):
            got = actor.get_actor_rotation()
            failures.append(
                "sun %s rotation (r,p,y)=(%s,%s,%s) != expected %s"
                % (light["key"], got.roll, got.pitch, got.yaw, expected_rot))
            continue
        sun_ok += 1
    check("all_suns_ok", sun_ok == len(suns), "%d/%d" % (sun_ok, len(suns)))
    check(
        "no_directional_lights_in_level",
        not any(isinstance(a, unreal.DirectionalLight) for a in by_key.values()),
    )

    # --- (c) point regression ---
    point_ok = 0
    for light in points:
        actor = by_key.get(light["key"])
        if actor is None:
            failures.append("point missing %s" % light["key"])
            continue
        if not isinstance(actor, unreal.PointLight):
            failures.append(
                "point %s is %s not PointLight" % (light["key"], type(actor).__name__))
            continue
        point_ok += 1
    check("point_regression", point_ok == len(points), "%d/%d" % (point_ok, len(points)))

    # Spot cone formula sanity (128 → acos(1-128/255) ≈ 60.13° half angle)
    half_128 = import_level._cone_half_angle_degrees(128)
    check(
        "cone_formula_128",
        abs(half_128 - math.degrees(math.acos(1.0 - 128.0 / 255.0))) < 1e-9,
        half_128)

    if failures:
        report["error"] = failures[:30]
        os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)
        raise RuntimeError("light shape verify failed:\n- " + "\n- ".join(failures[:30]))

    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    return report


if __name__ == "__main__":
    main()
