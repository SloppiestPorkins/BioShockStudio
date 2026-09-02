"""Report the falloff parameters of every local light, not just intensity.

The earlier render probe recorded intensity alone, which made a 664-light level look merely dim
and sent the repair at the brightness multiplier. Intensity is meaningless on its own here:
import_level deliberately disables inverse-square falloff so the authored LightBrightness stays a
scale, and in that mode UE5 shapes reach with LightFalloffExponent, whose default is 8 -
near-zero at roughly half the attenuation radius. A steep exponent and a large multiplier read as
blown-out bulbs in a black room, which is exactly the reported symptom.

Read-only. Run headless:
  UnrealEditor-Cmd <proj> -run=pythonscript -script=tools/ue5/probe_light_falloff.py \
    -unattended -nopause -nosplash
Env: BIOSHOCK_LIGHTPROBE_MAP (default /Game/BioShockLevel/1-Medical)
"""

from __future__ import annotations

import json
import os

import unreal

MAP = os.environ.get("BIOSHOCK_LIGHTPROBE_MAP", "/Game/BioShockLevel/1-Medical")
OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "_reports", "probe_light_falloff.json")

# (property, key) pairs read off every local light component. Wrapped individually because a
# property missing on a given light class must not lose the rest of the row.
FIELDS = (
    ("intensity", "intensity"),
    ("attenuation_radius", "radius"),
    ("light_falloff_exponent", "falloff"),
    ("use_inverse_squared_falloff", "invSq"),
    ("intensity_units", "units"),
    ("cast_shadows", "shadows"),
)


def _stats(values):
    if not values:
        return None
    ordered = sorted(values)
    n = len(ordered)
    return {
        "n": n,
        "min": round(ordered[0], 3),
        "p50": round(ordered[n // 2], 3),
        "p90": round(ordered[min(n - 1, int(n * 0.9))], 3),
        "max": round(ordered[-1], 3),
    }


def main():
    report = {"map": MAP, "error": None}
    if not unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(MAP):
        report["error"] = "could not load %s" % MAP
        _write(report)
        raise RuntimeError(report["error"])

    rows = []
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if not isinstance(actor, (unreal.PointLight, unreal.SpotLight, unreal.RectLight)):
            continue
        comp = actor.get_editor_property("light_component")
        if comp is None:
            continue
        row = {"label": actor.get_actor_label(), "type": type(actor).__name__}
        for prop, key in FIELDS:
            try:
                value = comp.get_editor_property(prop)
            except Exception as exc:  # noqa: BLE001
                row[key] = "unreadable: %s" % exc
                continue
            row[key] = value if isinstance(value, (int, float, bool)) else str(value)
        rows.append(row)

    report["lightCount"] = len(rows)
    for _, key in FIELDS:
        numeric = [r[key] for r in rows if isinstance(r.get(key), (int, float))
                   and not isinstance(r.get(key), bool)]
        if numeric:
            report["%sStats" % key] = _stats(numeric)
    # Non-numeric fields matter as a tally, not a percentile: one light differing is the finding.
    for key in ("invSq", "units", "shadows"):
        report["%sTally" % key] = {
            str(v): sum(1 for r in rows if str(r.get(key)) == str(v))
            for v in {str(r.get(key)) for r in rows}
        }

    # Reach is what actually decides whether a wall is lit. With inverse-square off UE5 uses
    # pow(saturate(1 - d/radius), exponent), so the distance at which a light still delivers 10%
    # is radius * (1 - 0.1^(1/exponent)) - the number to compare against room size.
    reaches = []
    for row in rows:
        radius, falloff = row.get("radius"), row.get("falloff")
        if isinstance(radius, (int, float)) and isinstance(falloff, (int, float)) and falloff > 0:
            reaches.append(radius * (1.0 - pow(0.1, 1.0 / falloff)))
    report["tenPercentReachStats"] = _stats(reaches)
    report["sample"] = rows[:5]

    _write(report)
    unreal.log("[light-probe] %s" % json.dumps(
        {k: v for k, v in report.items() if k != "sample"}))
    return report


def _write(report):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main()
