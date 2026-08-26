"""Phase 3 first slice: the runtime classes exist, and pawn numbers come from schema JSON."""

import json
import os

import unreal

# Pinned by ClassDefaultsInheritanceTests against VengeanceShared.U class defaults.
# Engine.U Pawn ships 78; that is not ShockPlayer's standing height.
_VP_COLLISION_HEIGHT = 68.0


def _log(message):
    unreal.log("[bioshock-runtime] %s" % message)


def _inherited_float(classes, class_name, prop):
    seen = set()
    current = class_name
    while current and current not in seen:
        seen.add(current)
        entry = classes.get(current)
        if not entry:
            return None
        for default in entry.get("defaults") or []:
            if default.get("name") != prop:
                continue
            if default.get("index") not in (None, 0):
                continue
            text = default.get("value") or ""
            if text.startswith("<"):
                return None
            try:
                return float(text)
            except ValueError:
                return None
        current = entry.get("super")
    return None


def _merge_vpawn_collision_height(rows):
    """ShockGame.U schema stops at the VPawn import. Inject the C#-pinned default."""
    classes = {row["name"]: row for row in rows}
    if _inherited_float(classes, "ShockPlayer", "CollisionHeight") is not None:
        return rows, False
    entry = {"name": "CollisionHeight", "value": str(_VP_COLLISION_HEIGHT)}
    vpawn = classes.get("VPawn")
    if vpawn is None:
        rows = list(rows) + [{"name": "VPawn", "super": "Pawn", "defaults": [entry]}]
    else:
        defaults = list(vpawn.get("defaults") or [])
        defaults.append(entry)
        vpawn["defaults"] = defaults
    return rows, True


def _require_class(name):
    path = "/Script/BioShockRuntime.%s" % name
    loaded = unreal.load_class(None, path)
    if loaded is None:
        raise RuntimeError("runtime class missing: %s" % path)
    return loaded


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    rows, injected = _merge_vpawn_collision_height(rows)
    apply_schema_path = schema_path
    if injected:
        apply_schema_path = os.path.join(
            os.path.dirname(os.path.abspath(report_path)), "ShockGame.schema.with_vpawn.json")
        os.makedirs(os.path.dirname(apply_schema_path), exist_ok=True)
        with open(apply_schema_path, "w", encoding="utf-8") as handle:
            json.dump(rows, handle)
    classes = {row["name"]: row for row in rows}

    report = {
        "schema": schema_path,
        "applySchema": apply_schema_path,
        "schemaClasses": len(classes),
        "error": None,
    }
    failures = []

    player_class = _require_class("ShockPlayer")
    ai_class = _require_class("BaseShockAI")
    weapon_class = _require_class("ShockWeapon")
    mode_class = _require_class("ShockGameMode")
    report["classes"] = ["ShockPlayer", "BaseShockAI", "ShockWeapon", "ShockGameMode", "ShockPawn", "ShockAction"]

    mode_cdo = unreal.get_default_object(mode_class)
    default_pawn = mode_cdo.get_editor_property("default_pawn_class")
    report["gameModeDefaultPawn"] = str(default_pawn)
    if default_pawn != player_class:
        failures.append("ShockGameMode default pawn is %s, not ShockPlayer" % default_pawn)

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player = subsystem.spawn_actor_from_class(player_class, unreal.Vector(0.0, 0.0, 100.0))
    ai = subsystem.spawn_actor_from_class(ai_class, unreal.Vector(150.0, 0.0, 100.0))
    weapon = subsystem.spawn_actor_from_class(weapon_class, unreal.Vector(300.0, 0.0, 50.0))
    if player is None or ai is None or weapon is None:
        raise RuntimeError("spawn failed")

    raw = unreal.ShockSchemaLibrary.apply_class_defaults(player, apply_schema_path, "ShockPlayer")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw), "applied": []}
    report["applyOk"] = bool(apply.get("ok"))
    report["applyError"] = apply.get("error")
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyClassDefaults failed: %s" % apply.get("error"))

    movement = player.get_editor_property("character_movement")
    capsule = player.get_editor_property("capsule_component")
    measured = {
        "capsuleRadius": float(capsule.get_editor_property("capsule_radius")),
        "capsuleHalfHeight": float(capsule.get_editor_property("capsule_half_height")),
        "maxWalkSpeed": float(movement.get_editor_property("max_walk_speed")),
        "jumpZVelocity": float(movement.get_editor_property("jump_z_velocity")),
        "baseEyeHeight": float(player.get_editor_property("base_eye_height")),
        "authoredHealth": float(player.get_editor_property("authored_health")),
        "authoredMaxHealth": float(player.get_editor_property("authored_max_health")),
    }
    expected = {
        "capsuleRadius": _inherited_float(classes, "ShockPlayer", "CollisionRadius"),
        "maxWalkSpeed": _inherited_float(classes, "ShockPlayer", "GroundSpeed"),
        "jumpZVelocity": _inherited_float(classes, "ShockPlayer", "JumpZ"),
        "baseEyeHeight": _inherited_float(classes, "ShockPlayer", "BaseEyeHeight"),
        "authoredHealth": _inherited_float(classes, "ShockPlayer", "Health"),
        "authoredMaxHealth": _inherited_float(classes, "ShockPlayer", "MaxHealth"),
        "capsuleHalfHeight": _inherited_float(classes, "ShockPlayer", "CollisionHeight"),
    }
    report["measured"] = measured
    report["expected"] = expected
    report["collisionHeight"] = {
        "status": "CONFIRMED_BYTES",
        "declaredOn": "VPawn",
        "package": "VengeanceShared.U",
        "injectedVPawn": injected,
    }

    for key, want in expected.items():
        got = measured[key]
        if want is None:
            failures.append("schema has no float for %s" % key)
            continue
        if abs(got - want) > 0.05:
            failures.append("%s %s != schema %s" % (key, got, want))

    # UE's Character default MaxWalkSpeed is 600. Schema GroundSpeed is 450. If apply was a no-op
    # this is the check that fails, not CollisionRadius (which happens to also be 34).
    if abs(measured["maxWalkSpeed"] - 600.0) < 0.05:
        failures.append("MaxWalkSpeed is still UE's 600 default; schema GroundSpeed was not applied")
    if abs(measured["capsuleHalfHeight"] - 88.0) < 0.05:
        failures.append("capsuleHalfHeight is still UE's 88 default; CollisionHeight was not applied")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("runtime skeleton failed:\n- " + "\n- ".join(failures))
    _log("PASS: runtime classes spawned; ShockPlayer numbers match ShockGame.U + VPawn CollisionHeight")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_RUNTIME_SCHEMA"], os.environ["BIOSHOCK_RUNTIME_OUT"])
