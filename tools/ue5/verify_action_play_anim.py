"""Phase 4 census #12: ActionPlayAnimation play-request record (no mesh playback)."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-play-anim] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionPlayAnimation" not in classes:
        raise RuntimeError("ActionPlayAnimation missing from %s" % schema_path)

    action_class = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionPlayAnimation")
    if action_class is None:
        raise RuntimeError("ShockActionPlayAnimation missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionPlayAnimation")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    report["rate"] = float(action.get_animation_rate())
    report["aliveOnly"] = bool(action.get_only_play_on_alive_pawns())
    if abs(report["rate"] - 1.0) > 0.001:
        failures.append("AnimationRate default should be 1")
    if not report["aliveOnly"]:
        failures.append("bOnlyPlayOnAlivePawns default should be true")
    if "AnimationRate" not in report["applied"]:
        failures.append("schema should apply AnimationRate")
    if "bOnlyPlayOnAlivePawns" not in report["applied"]:
        failures.append("schema should apply bOnlyPlayOnAlivePawns")

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    target = subsystem.spawn_actor_from_class(unreal.TargetPoint, unreal.Vector(0.0, 40.0, 0.0))
    if target is None:
        raise RuntimeError("spawn TargetPoint failed")

    action.configure("MedicalProp", "Idle", 1.0, 0)
    if not action.play_on_actor(target):
        failures.append("PlayOnActor returned false")
    else:
        report["lastAnim"] = str(action.get_last_played_animation())
        report["lastActor"] = str(action.get_last_played_actor_name())
        if report["lastAnim"] != "Idle":
            failures.append("LastPlayedAnimation mismatch")

    empty = unreal.new_object(action_class)
    if empty.play_on_actor(target):
        failures.append("PlayOnActor with empty Animation should fail")
    if action.play_on_actor(None):
        failures.append("PlayOnActor(None) should fail")

    subsystem.destroy_actor(target)
    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionPlayAnimation failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionPlayAnimation records play request")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
