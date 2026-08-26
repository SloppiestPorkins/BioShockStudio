"""Phase 4 census #10: ActionSpawnAI spawn-request record (no SpawningManager)."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-spawn-ai] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    if "ActionSpawnAI" not in classes:
        raise RuntimeError("ActionSpawnAI missing from %s" % schema_path)

    action_class = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSpawnAI")
    if action_class is None:
        raise RuntimeError("ShockActionSpawnAI missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(action, schema_path, "ActionSpawnAI")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    report["corpseDefault"] = bool(action.get_corpse_can_be_removed())
    if not report["corpseDefault"]:
        failures.append("bCorpseCanBeRemoved default should be true")
    if "bCorpseCanBeRemoved" not in report["applied"]:
        failures.append("schema should apply bCorpseCanBeRemoved")

    action.configure("ThuggishSplicer", "MedicalSpawnPoint", "SpawnedThug_1", 0.0, 50.0, True)
    if not action.request_spawn():
        failures.append("RequestSpawn returned false")
    report["lastType"] = str(action.get_last_requested_ai_type())
    report["lastLoc"] = str(action.get_last_requested_location_label())
    if report["lastType"] != "ThuggishSplicer":
        failures.append("LastRequestedAIType mismatch")
    if report["lastLoc"] != "MedicalSpawnPoint":
        failures.append("LastRequestedLocationLabel mismatch")

    empty = unreal.new_object(action_class)
    if empty.request_spawn():
        failures.append("RequestSpawn with empty AIType should fail")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionSpawnAI failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionSpawnAI records spawn request without SpawningManager")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
