"""Phase 4 census #9: ActionHideOrShowActor SetHidden stand-in."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-hide-show] %s" % message)


def _actor_hidden(actor):
    """Best-effort read of UE5 actor hidden state from Python."""
    for name in ("actor_hidden_in_game", "b_hidden"):
        try:
            return bool(actor.get_editor_property(name))
        except Exception:  # noqa: BLE001
            pass
    try:
        return bool(actor.is_hidden_ed())
    except Exception:  # noqa: BLE001
        return None


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionHideOrShowActor" not in classes:
        raise RuntimeError("ActionHideOrShowActor missing from %s" % schema_path)

    action_class = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionHideOrShowActor")
    if action_class is None:
        raise RuntimeError("ShockActionHideOrShowActor missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionHideOrShowActor")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    report["hideDefault"] = bool(action.get_hide_actor())
    if not report["hideDefault"]:
        failures.append("schema/default HideActor should be true")
    if "HideActor" not in report["applied"]:
        failures.append("ApplyActionDefaults should apply HideActor=true")

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    target = subsystem.spawn_actor_from_class(unreal.TargetPoint, unreal.Vector(10.0, 0.0, 0.0))
    if target is None:
        raise RuntimeError("spawn TargetPoint failed")

    action.configure("MedicalProp", True)
    if not action.apply_to_actor(target):
        failures.append("hide ApplyToActor failed")
    report["lastAppliedHide"] = bool(action.get_last_applied_hide())
    report["actorHiddenAfterHide"] = _actor_hidden(target)
    if not report["lastAppliedHide"]:
        failures.append("LastAppliedHide should be true after hide")
    if report["actorHiddenAfterHide"] is False:
        failures.append("actor not hidden after hide")

    action.configure("MedicalProp", False)
    if not action.apply_to_actor(target):
        failures.append("show ApplyToActor failed")
    report["lastAppliedHideAfterShow"] = bool(action.get_last_applied_hide())
    report["actorHiddenAfterShow"] = _actor_hidden(target)
    if report["lastAppliedHideAfterShow"]:
        failures.append("LastAppliedHide should be false after show")
    if report["actorHiddenAfterShow"] is True:
        failures.append("actor still hidden after show")

    if action.apply_to_actor(None):
        failures.append("ApplyToActor(None) should fail")

    subsystem.destroy_actor(target)
    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionHideOrShowActor failed:\n- " + "\n- ".join(failures))
    _log("PASS: HideOrShowActor applies SetActorHiddenInGame")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
