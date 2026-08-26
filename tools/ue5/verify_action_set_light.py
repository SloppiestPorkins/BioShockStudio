"""Phase 4 census #6: ActionSetLightProperties brightness/colour apply (first slice)."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-set-light] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionSetLightProperties" not in classes:
        raise RuntimeError("ActionSetLightProperties missing from %s" % schema_path)

    action_class = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetLightProperties")
    if action_class is None:
        raise RuntimeError("ShockActionSetLightProperties missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionSetLightProperties")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    light_actor = subsystem.spawn_actor_from_class(
        unreal.PointLight, unreal.Vector(0.0, 0.0, 100.0))
    if light_actor is None:
        raise RuntimeError("spawn PointLight failed")

    # Match import_level: intensity = authored LightBrightness scale (no candela multiply).
    # Configure takes FColor; pass via getters after configure to avoid Python Color channel order traps.
    action.configure("MedicalHallLight", True, 2.5, True, unreal.Color(r=255, g=128, b=64, a=255))
    configured = action.get_light_color()
    report["configuredColor"] = [
        int(configured.r), int(configured.g), int(configured.b), int(configured.a)]
    if report["configuredColor"][:3] != [255, 128, 64]:
        failures.append("Configure Color channel order wrong: %s" % report["configuredColor"])
    if not action.apply_to_actor(light_actor):
        failures.append("ApplyToActor returned false")
    else:
        report["lastApplied"] = str(action.get_last_applied_actor_name())
        component = light_actor.light_component
        report["intensity"] = float(component.get_editor_property("intensity"))
        color = component.get_editor_property("light_color")
        report["lightColor"] = [float(color.r), float(color.g), float(color.b), float(color.a)]
        if abs(report["intensity"] - 2.5) > 0.01:
            failures.append("intensity %s != 2.5" % report["intensity"])
        # Component light_color is FLinearColor 0–1 from SetLightColor(FLinearColor(FColor)).
        expected = [255 / 255.0, 128 / 255.0, 64 / 255.0]
        for i, name in enumerate(("R", "G", "B")):
            got = report["lightColor"][i]
            # Accept either linear 0–1 or byte-scaled Color-shaped returns.
            if abs(got - expected[i]) > 0.02 and abs(got - expected[i] * 255.0) > 1.0:
                failures.append(
                    "light %s mismatch: got %s expected linear %s" % (name, got, expected[i]))
                break

    no_change = unreal.new_object(action_class)
    no_change.configure("X", False, 9.0, False, unreal.Color(0, 0, 0, 255))
    if no_change.apply_to_actor(light_actor):
        failures.append("Apply with no ChangeProperty flags should fail")

    if action.apply_to_actor(None):
        failures.append("ApplyToActor(None) should be false")

    subsystem.destroy_actor(light_actor)
    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionSetLightProperties failed:\n- " + "\n- ".join(failures))
    _log("PASS: SetLightProperties applies brightness+colour to PointLight")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
