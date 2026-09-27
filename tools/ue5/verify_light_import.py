"""Verify PointLight radius and brightness mapping against a level manifest.

Phase 1.4. Inverse-square off, intensity = authored LightBrightness (or 1.0),
attenuation radius = authored LightRadius. Raises RuntimeError on mismatch.
"""

import json
import os

import unreal

import import_level


def _tag_value(actor, prefix):
    for tag in actor.tags:
        text = str(tag)
        if text.startswith(prefix):
            return text[len(prefix):]
    return None


def main(manifest_path=None, report_path=None):
    manifest_path = manifest_path or os.environ.get("BIOSHOCK_LIGHT_MANIFEST")
    report_path = report_path or os.environ.get("BIOSHOCK_LIGHT_LOOK_OUT")
    if not manifest_path:
        raise RuntimeError("Set BIOSHOCK_LIGHT_MANIFEST to a level JSON.")
    if not report_path:
        raise RuntimeError("Set BIOSHOCK_LIGHT_LOOK_OUT to the JSON report path.")

    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    expected = [light for light in (manifest.get("lights") or [])
                if light.get("radius") is not None and float(light["radius"]) > 0]
    dropped = len(manifest.get("lights") or []) - len(expected)
    if not expected:
        raise RuntimeError("manifest has no lights with a usable radius")

    report = {
        "package": manifest.get("package"),
        "expectedPointLights": len(expected),
        "droppedNoRadius": dropped,
        "intensityScale": 1.0,
        "inverseSquared": False,
        "lights": [],
        "error": None,
    }

    import_report = {"created": 0, "updated": 0, "skipped": 0, "unsupported": 0}
    existing = import_level._existing_by_key()
    handled = set()
    import_level._import_lights(manifest, existing, import_report, handled)
    report["import"] = import_report

    by_key = {}
    for actor in import_level._actor_subsystem().get_all_level_actors():
        if not isinstance(actor, unreal.PointLight):
            continue
        key = _tag_value(actor, "BioShockKey=")
        if key:
            by_key[key] = actor

    if len(by_key) != len(expected):
        raise RuntimeError(
            "PointLight count %d != usable-radius lights %d"
            % (len(by_key), len(expected)))

    failures = []
    for light in expected:
        actor = by_key.get(light["key"])
        if actor is None:
            failures.append("missing %s" % light["key"])
            continue
        component = actor.get_editor_property("light_component")
        radius = float(component.get_editor_property("attenuation_radius"))
        intensity = float(component.get_editor_property("intensity"))
        inverse = bool(component.get_editor_property("use_inverse_squared_falloff"))
        authored_intensity = float(light["brightness"]) if light.get("brightness") is not None else 1.0
        light_type = light.get("type")
        # SCR-G07 / W-BUG-03: LT_None (type 0) means the light is off, not just unanimated.
        expected_intensity = 0.0 if light_type == 0 else authored_intensity
        expected_radius = float(light["radius"])
        sample = {
            "key": light["key"],
            "attenuationRadius": radius,
            "intensity": intensity,
            "inverseSquared": inverse,
            "lightType": light_type,
        }
        report["lights"].append(sample)
        if abs(radius - expected_radius) > 0.5:
            failures.append("%s radius %s != %s" % (light["key"], radius, expected_radius))
        if abs(intensity - expected_intensity) > 1e-4:
            failures.append("%s intensity %s != %s" % (light["key"], intensity, expected_intensity))
        if inverse:
            failures.append("%s still inverse-squared" % light["key"])
        if expected_intensity > 0.05 and intensity >= expected_intensity * 50:
            failures.append("%s intensity %s looks like the old *1000 guess" % (light["key"], intensity))

        effect_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockLightEffectComponent")
        effect = actor.get_component_by_class(effect_cls) if effect_cls else None
        mapped_effect_ordinals = import_level._UE2_LIGHT_TYPE_TO_EFFECT
        if light_type in mapped_effect_ordinals:
            if effect is None:
                failures.append("%s type %s got no ShockLightEffectComponent" % (light["key"], light_type))
            else:
                expected_ordinal = int(getattr(
                    unreal.EShockLightEffectType, mapped_effect_ordinals[light_type]))
                got_ordinal = int(effect.get_effect_type_for_verify())
                if got_ordinal != expected_ordinal:
                    failures.append(
                        "%s effect ordinal %s != expected %s"
                        % (light["key"], got_ordinal, expected_ordinal))
        elif light_type not in (None, 0) and effect is not None:
            failures.append(
                "%s type %s is unmapped but still got an effect component" % (light["key"], light_type))

    if failures:
        raise RuntimeError("light mapping failed:\n- " + "\n- ".join(failures[:20]))

    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    return report


if __name__ == "__main__":
    main()
