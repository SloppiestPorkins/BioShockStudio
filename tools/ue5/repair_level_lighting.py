"""Make an imported BioShock level actually readable: rescale the raw-ported light
intensities, give the SkyLight a real constant ambient, add a SkyAtmosphere, and pin
exposure with an unbound PostProcessVolume.

BioShock's UnrealEd 2.5 brightness scalars (0..1-ish) were carried through verbatim, so a
level lands with ~hundreds of point lights at <2 cd and a SkyLight set to real-time-capture
with nothing to capture. Result: a near-black scene that the viewport's auto-exposure washes
to flat grey. This is a stopgap, not authored lighting.

Idempotent: everything it adds is tagged BIOSHOCK_LIGHT_REPAIR and updated in place on re-run.
Per-light originals are stashed in a tag (BIOSHOCK_LIGHT_ORIG=<value>) so a re-run rescales
from the original, not the already-scaled value.

Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/repair_level_lighting.py \
    -unattended -nopause -nosplash
Env: BIOSHOCK_LIGHT_MAP (default /Game/BioShockLevel/1-Medical),
     BIOSHOCK_LIGHT_FACTOR (default 120), BIOSHOCK_LIGHT_MIN/MAX (8 / 400),
     BIOSHOCK_LIGHT_DRY=1 to report without saving.
"""

from __future__ import annotations

import json
import os

import unreal

MAP = os.environ.get("BIOSHOCK_LIGHT_MAP", "/Game/BioShockLevel/1-Medical")
FACTOR = float(os.environ.get("BIOSHOCK_LIGHT_FACTOR", "8"))
CLAMP_MIN = float(os.environ.get("BIOSHOCK_LIGHT_MIN", "2"))
CLAMP_MAX = float(os.environ.get("BIOSHOCK_LIGHT_MAX", "64"))
# Reach, not brightness, was what made this level dark. import_level turns inverse-square OFF so
# the authored LightBrightness stays a scale; in that mode UE5 shapes reach with
# pow(saturate(1 - d/radius), exponent), and the exponent DEFAULTS TO 8. Measured across all 664
# lights, that put 10% brightness at a median of 1.0 m in corridors 3-5 m wide: blown-out white
# within arm's reach of each bulb and near-black everywhere else. Both halves of that - "god rays
# are super bright and just white" and "walls are dark" - are this one number. An exponent near 2
# is the gentle curve UE2.5 approximated; raising the multiplier instead (it was 120) only widened
# the gap between the hotspot and the wall.
FALLOFF = float(os.environ.get("BIOSHOCK_LIGHT_FALLOFF", "2"))
# Every number below is a look-at-it judgement, so each is overridable without editing this file.
# Rapture reads on light-and-shadow contrast far more than on absolute brightness: prefer a dim
# ambient with bright practicals over lifting everything uniformly.
SUN_LUX = float(os.environ.get("BIOSHOCK_LIGHT_SUN", "6"))
SKY_INTENSITY = float(os.environ.get("BIOSHOCK_LIGHT_SKY", "1.5"))
EXPOSURE_EV = float(os.environ.get("BIOSHOCK_LIGHT_EV", "11"))
DRY = os.environ.get("BIOSHOCK_LIGHT_DRY", "0") == "1"
REPAIR_TAG = "BIOSHOCK_LIGHT_REPAIR"
ORIG_PREFIX = "BIOSHOCK_LIGHT_ORIG="
SKY_CUBEMAP = "/Engine/MapTemplates/Sky/DaylightAmbientCubemap.DaylightAmbientCubemap"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_reports", "repair_level_lighting.json")


def _lvl():
    return unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def _actors():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def _tag_value(actor, prefix):
    for t in actor.tags:
        s = str(t)
        if s.startswith(prefix):
            return s[len(prefix):]
    return None


def _set_tag(actor, prefix, value):
    tags = [t for t in actor.tags if not str(t).startswith(prefix)]
    tags.append(unreal.Name("%s%s" % (prefix, value)))
    actor.tags = tags


def _has_tag(actor, tag):
    return any(str(t) == tag for t in actor.tags)


def _rescale_local_lights(report):
    scaled = 0
    for actor in _actors().get_all_level_actors():
        if not isinstance(actor, (unreal.PointLight, unreal.SpotLight, unreal.RectLight)):
            continue
        comp = actor.get_editor_property("light_component")
        if comp is None:
            continue

        orig = _tag_value(actor, ORIG_PREFIX)
        base = float(orig) if orig is not None else float(comp.get_editor_property("intensity"))
        if orig is None:
            _set_tag(actor, ORIG_PREFIX, "%.4f" % base)

        if base <= 0.0:
            continue
        new_val = max(CLAMP_MIN, min(CLAMP_MAX, base * FACTOR))
        # No intensity_units here. This used to set CANDELAS and report success; UE5 ignores the
        # unit while bUseInverseSquaredFalloff is false, and a read-back showed all 664 lights
        # still UNITLESS. Intensity is a bare multiplier in this mode - leave the unit alone.
        comp.set_editor_property("intensity", new_val)
        comp.set_editor_property("light_falloff_exponent", FALLOFF)
        scaled += 1
    report["localLightsScaled"] = scaled
    report["factor"] = FACTOR
    report["falloffExponent"] = FALLOFF
    # Reach at 10% brightness for the median light, the number that actually tracks whether a wall
    # is lit. Recorded so a re-run can be compared against the 1.0 m that started this.
    report["tenPercentReachAtRadius400"] = round(400.0 * (1.0 - pow(0.1, 1.0 / FALLOFF)), 1)


def _fix_directional(report):
    found = 0
    for actor in _actors().get_all_level_actors():
        if not isinstance(actor, unreal.DirectionalLight):
            continue
        found += 1
        comp = actor.get_editor_property("directional_light_component")
        if comp is None:
            continue
        comp.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
        comp.set_editor_property("intensity", SUN_LUX)  # lux — soft interior key through the roof
    report["directionalLights"] = found


def _fix_skylight(report):
    sky = None
    for actor in _actors().get_all_level_actors():
        if isinstance(actor, unreal.SkyLight):
            sky = actor
            break
    if sky is None:
        sky = _actors().spawn_actor_from_class(unreal.SkyLight, unreal.Vector(0, 0, 300))
        _set_tag(sky, "", REPAIR_TAG)

    comp = sky.get_editor_property("light_component")
    cubemap = unreal.load_asset(SKY_CUBEMAP)
    comp.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
    comp.set_editor_property("real_time_capture", False)
    comp.set_editor_property("source_type", unreal.SkyLightSourceType.SLS_SPECIFIED_CUBEMAP)
    if cubemap is not None:
        comp.set_editor_property("cubemap", cubemap)
    comp.set_editor_property("intensity", SKY_INTENSITY)
    comp.set_editor_property("lower_hemisphere_is_black", False)
    try:
        comp.recapture_sky()
    except Exception:  # noqa: BLE001
        pass
    report["skyLightCubemap"] = SKY_CUBEMAP if cubemap is not None else None


def _ensure_sky_atmosphere(report):
    for actor in _actors().get_all_level_actors():
        if actor.get_class().get_name() == "SkyAtmosphere":
            report["skyAtmosphere"] = "existing"
            return
    atmo = _actors().spawn_actor_from_class(
        unreal.load_class(None, "/Script/Engine.SkyAtmosphere"), unreal.Vector(0, 0, 0))
    if atmo is not None:
        _set_tag(atmo, "", REPAIR_TAG)
        report["skyAtmosphere"] = "added"
    else:
        report["skyAtmosphere"] = "failed"


def _ensure_post_process(report):
    ppv = None
    for actor in _actors().get_all_level_actors():
        if isinstance(actor, unreal.PostProcessVolume) and _has_tag(actor, REPAIR_TAG):
            ppv = actor
            break
    if ppv is None:
        ppv = _actors().spawn_actor_from_class(unreal.PostProcessVolume, unreal.Vector(0, 0, 0))
        _set_tag(ppv, "", REPAIR_TAG)
    ppv.set_editor_property("unbound", True)
    ppv.set_editor_property("priority", 1.0)
    settings = ppv.get_editor_property("settings")
    settings.set_editor_property("override_auto_exposure_method", True)
    settings.set_editor_property("auto_exposure_method", unreal.AutoExposureMethod.AEM_MANUAL)
    settings.set_editor_property("override_auto_exposure_bias", True)
    settings.set_editor_property("auto_exposure_bias", EXPOSURE_EV)  # manual meter EV
    ppv.set_editor_property("settings", settings)
    report["postProcessVolume"] = "ok"


def main():
    report = {"map": MAP, "dryRun": DRY, "error": None}
    if not _lvl().load_level(MAP):
        report["error"] = "could not load %s" % MAP
        _write(report)
        raise RuntimeError(report["error"])

    world = unreal.EditorLevelLibrary.get_editor_world()
    world.get_world_settings().set_editor_property("force_no_precomputed_lighting", True)

    _rescale_local_lights(report)
    _fix_directional(report)
    _fix_skylight(report)
    _ensure_sky_atmosphere(report)
    _ensure_post_process(report)

    if DRY:
        report["saved"] = False
    else:
        # EditorLoadingAndSavingUtils.save_map, not LevelEditorSubsystem.save_current_level: the
        # latter routes through InternalPromptForCheckoutAndSave, whose completion notification
        # asserts on Slate (CurrentApplication.IsValid()) under -run=pythonscript.
        saved = False
        _write(report)  # persist findings before a save that can still trip a headless assert
        try:
            saved = bool(unreal.EditorLoadingAndSavingUtils.save_map(world, MAP))
        except Exception as exc:  # noqa: BLE001
            unreal.log_warning("[light-repair] save_map failed (%s); falling back" % exc)
        if not saved and not _lvl().save_current_level():
            report["error"] = "save_current_level failed"
            _write(report)
            raise RuntimeError(report["error"])
        report["saved"] = True

    _write(report)
    unreal.log("[light-repair] %s" % json.dumps(report))
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
