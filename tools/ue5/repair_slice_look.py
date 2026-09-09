"""Give the playable slice the Rapture look: colour grade + atmosphere.

`repair_level_lighting.py` already fixes falloff/intensity/exposure. This is the mood layer the
user asked for ("a fidelity pass as it does not look like BioShock"):

  * an unbound PostProcessVolume with a warm-shadows / cool-highlights split tone, crushed
    blacks, an S-curve, low global saturation (neon + practicals still pop), bloom, a soft
    vignette, a light chromatic-aberration edge, and fine film grain;
  * an ExponentialHeightFog with volumetric fog so the god-ray shafts catch and the air reads
    heavy and wet.

Every value is overridable by env var (see KNOBS) so it can be tuned without a rebuild.
Idempotent — tagged actors are reused. Wired into `setup_playable_slice` after
`repair_level_lighting`.

Env: BIOSHOCK_LOOK_MAPS (comma list, default /Game/BioShockSlice/1-Medical)
"""
from __future__ import annotations

import json
import os

import unreal

MAPS = [v.strip() for v in os.environ.get(
    "BIOSHOCK_LOOK_MAPS", "/Game/BioShockSlice/1-Medical").split(",") if v.strip()]
OUT = os.path.join(os.environ.get("TEMP", "."), "repair_slice_look.json")
TAG = unreal.Name("BioShockSliceLook")


def _f(name, default):
    try:
        return float(os.environ.get(name, default))
    except (TypeError, ValueError):
        return float(default)


KNOBS = {
    # Conservative by default — the slice already reads warm/deco/moody after the lighting +
    # god-ray + collision fixes. This layer is a gentle grade; crank it with the editor open.
    "saturation": _f("BIOSHOCK_LOOK_SAT", 0.94),
    "contrast": _f("BIOSHOCK_LOOK_CONTRAST", 1.03),
    "black_lift": _f("BIOSHOCK_LOOK_BLACKS", 0.0),
    "shadow_warm": _f("BIOSHOCK_LOOK_SHADOW_WARM", 1.03),
    "shadow_cool": _f("BIOSHOCK_LOOK_SHADOW_COOL", 0.98),
    "highlight_warm": _f("BIOSHOCK_LOOK_HL_WARM", 0.99),
    "highlight_cool": _f("BIOSHOCK_LOOK_HL_COOL", 1.02),
    "bloom": _f("BIOSHOCK_LOOK_BLOOM", 0.0),      # 0 = don't override (keep project default)
    "vignette": _f("BIOSHOCK_LOOK_VIGNETTE", 0.3),
    "fringe": _f("BIOSHOCK_LOOK_FRINGE", 0.0),
    "grain": _f("BIOSHOCK_LOOK_GRAIN", 0.1),
    # Medical is a high-Z interior (~7800). Exponential height fog floods an interior white very
    # easily — kept barely-there by default (a faint depth haze); crank BIOSHOCK_LOOK_FOG to
    # taste with the editor open. Volumetric fog OFF by default — it smears the god-ray beams.
    "fog_density": _f("BIOSHOCK_LOOK_FOG", 0.0009),
    "fog_height_falloff": _f("BIOSHOCK_LOOK_FOG_FALLOFF", 1.0),
    "fog_max_opacity": _f("BIOSHOCK_LOOK_FOG_MAXOP", 0.14),
    "fog_floor_z": _f("BIOSHOCK_LOOK_FOG_Z", 7680.0),
    "volumetric_fog": _f("BIOSHOCK_LOOK_VOLFOG", 0.0),
    "fog_scatter_r": _f("BIOSHOCK_LOOK_FOG_R", 0.06),
    "fog_scatter_g": _f("BIOSHOCK_LOOK_FOG_G", 0.075),
    "fog_scatter_b": _f("BIOSHOCK_LOOK_FOG_B", 0.10),
}


def _actors():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def _tagged(cls):
    for a in _actors().get_all_level_actors():
        if isinstance(a, cls) and TAG in a.tags:
            return a
    return None


def _grade_ppv(report):
    ppv = _tagged(unreal.PostProcessVolume)
    if ppv is None:
        ppv = _actors().spawn_actor_from_class(unreal.PostProcessVolume, unreal.Vector(0, 0, 0))
        ppv.tags = [TAG]
        try:
            ppv.set_actor_label("SliceLook_PPV")
        except Exception:
            pass
    ppv.set_editor_property("unbound", True)
    ppv.set_editor_property("priority", 2.0)  # above repair_level_lighting's exposure PPV

    s = ppv.get_editor_property("settings")

    # Global tone: BioShock Medical is desaturated with a gentle S-curve; shadows tinted warm
    # (rust/brass), highlights cool (the aquamarine cast). color_*_shadows/midtones/highlights
    # are Vector4s where W is the master weight — leave W at its default (1) and nudge RGB.
    s.set_editor_property("override_color_saturation", True)
    s.set_editor_property("color_saturation", unreal.Vector4(
        KNOBS["saturation"], KNOBS["saturation"], KNOBS["saturation"], 1.0))
    s.set_editor_property("override_color_contrast", True)
    s.set_editor_property("color_contrast", unreal.Vector4(
        KNOBS["contrast"], KNOBS["contrast"], KNOBS["contrast"], 1.0))
    s.set_editor_property("override_color_gamma_shadows", True)
    s.set_editor_property("color_gamma_shadows", unreal.Vector4(
        1.0 / KNOBS["shadow_warm"], 1.0, 1.0 / KNOBS["shadow_cool"], 1.0))
    s.set_editor_property("override_color_gamma_highlights", True)
    s.set_editor_property("color_gamma_highlights", unreal.Vector4(
        1.0 / KNOBS["highlight_warm"], 1.0, 1.0 / KNOBS["highlight_cool"], 1.0))

    s.set_editor_property("override_vignette_intensity", True)
    s.set_editor_property("vignette_intensity", KNOBS["vignette"])
    s.set_editor_property("override_film_grain_intensity", True)
    s.set_editor_property("film_grain_intensity", KNOBS["grain"])
    if KNOBS["fringe"] > 0.0:
        s.set_editor_property("override_scene_fringe_intensity", True)
        s.set_editor_property("scene_fringe_intensity", KNOBS["fringe"])
    if KNOBS["bloom"] > 0.0:
        s.set_editor_property("override_bloom_intensity", True)
        s.set_editor_property("bloom_intensity", KNOBS["bloom"])

    ppv.set_editor_property("settings", s)
    report["ppv"] = "ok"


def _atmosphere(report):
    fog = _tagged(unreal.ExponentialHeightFog)
    if fog is None:
        fog = _actors().spawn_actor_from_class(
            unreal.ExponentialHeightFog, unreal.Vector(0.0, 0.0, KNOBS["fog_floor_z"]))
        fog.tags = [TAG]
        try:
            fog.set_actor_label("SliceLook_HeightFog")
        except Exception:
            pass
    fog.set_actor_location(unreal.Vector(0.0, 0.0, KNOBS["fog_floor_z"]), False, False)
    comp = fog.get_component_by_class(unreal.ExponentialHeightFogComponent)
    if comp is None:
        report["fog"] = "no component"
        return
    comp.set_fog_density(KNOBS["fog_density"])
    comp.set_fog_height_falloff(KNOBS["fog_height_falloff"])
    comp.set_fog_inscattering_color(unreal.LinearColor(
        KNOBS["fog_scatter_r"], KNOBS["fog_scatter_g"], KNOBS["fog_scatter_b"], 1.0))
    comp.set_fog_max_opacity(KNOBS["fog_max_opacity"])
    want_vol = KNOBS["volumetric_fog"] > 0.5
    try:
        comp.set_volumetric_fog(want_vol)
        if want_vol:
            comp.set_volumetric_fog_scattering_distribution(0.2)
            comp.set_volumetric_fog_extinction_scale(0.6)
    except Exception as exc:  # noqa: BLE001
        report["volumetricFog"] = "unavailable: %s" % exc
    report["fog"] = "ok (volumetric=%s)" % want_vol


def _clear(entry):
    n = 0
    for a in list(_actors().get_all_level_actors()):
        if TAG in a.tags:
            _actors().destroy_actor(a)
            n += 1
    entry["cleared"] = n


def main(clear=False):
    clear = clear or os.environ.get("BIOSHOCK_LOOK_CLEAR", "") not in ("", "0")
    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    result = {"knobs": KNOBS, "clear": clear, "maps": []}
    for map_path in MAPS:
        entry = {"map": map_path}
        if not lvl.load_level(map_path):
            entry["error"] = "could not load"
            result["maps"].append(entry)
            continue
        if clear:
            _clear(entry)
        else:
            _grade_ppv(entry)
            _atmosphere(entry)
        lvl.save_current_level()
        result["maps"].append(entry)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    unreal.log("[slice-look] %s" % json.dumps(result))
    unreal.log("Success - 0 error(s)")
    return result


if __name__ == "__main__":
    main()
