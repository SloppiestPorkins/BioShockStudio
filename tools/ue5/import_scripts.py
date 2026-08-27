"""Import level-placed Script actors from ue5-level.json as AShockScript.

First slice: Label, location, TriggeredBy (decoded from property valueHex), and action
*class* stubs for every ShockAction* that loads. Does not decode per-action package
properties (Seconds, Variable names, If branches, …) — those stay UNKNOWN here.

Idempotent via BioShockScriptKey=<manifest key> tags (full refresh each run). Shared
UShockScriptRegistry across imported scripts so TriggeredBy / SendTriggerMessage can resolve.
"""

from __future__ import annotations

import json

import unreal

KEY_TAG_PREFIX = "BioShockScriptKey="


def _log(message):
    unreal.log("[bioshock-scripts] %s" % message)


def _actor_subsystem():
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem)


def _existing_by_key():
    found = {}
    for actor in _actor_subsystem().get_all_level_actors():
        for tag in actor.tags:
            text = str(tag)
            if text.startswith(KEY_TAG_PREFIX):
                found[text[len(KEY_TAG_PREFIX) :]] = actor
    return found


def decode_triggered_by_hex(value_hex):
    """Decode a Script actor's TriggeredBy Str property ValueHex.

    Tagged Str payload: one byte character count (including trailing null), then UTF-16LE.
    Confirmed against Medical samples (player, All, 1-Medical).
    """
    if not value_hex:
        return ""
    raw = bytes.fromhex(value_hex)
    if len(raw) < 2:
        return ""
    body = raw[1:]
    if len(body) % 2 == 1:
        body = body[:-1]
    return body.decode("utf-16-le", errors="replace").rstrip("\x00")


def triggered_by_from_actor(actor_doc):
    for prop in actor_doc.get("properties") or []:
        if prop.get("name") == "TriggeredBy" and prop.get("type") == "Str":
            return decode_triggered_by_hex(prop.get("valueHex") or "")
    return ""


# UnrealScript Action* → concrete UShockAction* when names do not match 1:1.
ACTION_CLASS_OVERRIDES = {
    # Base assign is abstract; overwrite is the UC ActionVariableAssign behaviour.
    "ActionVariableAssign": "ShockActionVariableAssignOverwrite",
}


def shock_action_class_name(action_class):
    """ActionWait → ShockActionWait (with a few concrete overrides)."""
    if not action_class or not action_class.startswith("Action"):
        return None
    if action_class in ACTION_CLASS_OVERRIDES:
        return ACTION_CLASS_OVERRIDES[action_class]
    return "Shock" + action_class


def try_create_action(action_class, object_name):
    """Instantiate a first-slice ShockAction by UnrealScript class name. Params not applied."""
    shock_name = shock_action_class_name(action_class)
    if not shock_name:
        return None, "bad-name"
    cls = unreal.load_class(None, "/Script/BioShockRuntime.%s" % shock_name)
    if not cls:
        return None, "missing-class"
    try:
        action = unreal.new_object(cls)
    except Exception:
        return None, "abstract-or-fail"
    if action_class == "ActionScriptNote" and hasattr(action, "configure"):
        try:
            action.configure(object_name or action_class)
        except Exception:
            pass
    return action, "ok"


def import_scripts(manifest_path, limit=None):
    """Destroy prior BioShockScriptKey actors, then spawn AShockScript from the manifest."""
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    if not script_cls:
        raise RuntimeError("ShockScript class missing — rebuild BioShockRuntime")

    for _key, actor in list(_existing_by_key().items()):
        _actor_subsystem().destroy_actor(actor)

    report = {
        "manifest": manifest_path,
        "scripts_in_manifest": 0,
        "created": 0,
        "skipped": 0,
        "actions_mapped": 0,
        "actions_unmapped": 0,
        "unmapped_classes": {},
        "with_triggered_by": 0,
        "registry_num": 0,
        "failures": [],
        "sample": {},
    }

    scripts = [a for a in (manifest.get("actors") or []) if a.get("className") == "Script"]
    report["scripts_in_manifest"] = len(scripts)
    if limit is not None:
        scripts = scripts[: int(limit)]

    registry = None
    sample_actor = None
    sample_tb = ""
    for actor_doc in scripts:
        key = actor_doc.get("key") or ("Script_%s" % actor_doc.get("exportIndex"))
        label = actor_doc.get("label") or actor_doc.get("name") or key
        triggered_by = triggered_by_from_actor(actor_doc)
        if triggered_by:
            report["with_triggered_by"] += 1

        location = actor_doc.get("location") or [0, 0, 0]
        # LevelActorDocument.Location is not GameBasis-converted (import_level._place).
        loc = unreal.Vector(float(location[0]), float(location[1]), float(location[2]))
        actor = _actor_subsystem().spawn_actor_from_class(script_cls, loc, unreal.Rotator(0, 0, 0))
        if actor is None:
            report["skipped"] += 1
            continue
        report["created"] += 1
        actor.tags = [KEY_TAG_PREFIX + key]
        actor.set_actor_label(str(label))
        actor.configure(label, triggered_by)
        if registry is None:
            registry = actor.ensure_registry()
        else:
            actor.set_registry(registry)

        runner = actor.get_runner()
        sa = actor_doc.get("scriptActions") or {}
        action_count = 0
        for ref in sa.get("actions") or []:
            if not ref:
                report["actions_unmapped"] += 1
                continue
            action_class = ref.get("className") or ""
            action, _status = try_create_action(action_class, ref.get("objectName"))
            if action is None:
                report["actions_unmapped"] += 1
                report["unmapped_classes"][action_class] = (
                    report["unmapped_classes"].get(action_class, 0) + 1
                )
                continue
            runner.add_action(action)
            report["actions_mapped"] += 1
            action_count += 1

        if str(label) == "TipUnlock1-Medical":
            sample_actor = actor
            sample_tb = triggered_by
            report["sample"] = {
                "label": str(label),
                "triggeredBy": triggered_by,
                "action_stubs": action_count,
            }

    if registry is not None:
        report["registry_num"] = int(registry.num())

    if registry is not None and sample_actor is not None and sample_tb:
        accepted = int(registry.dispatch_message("MessageTrigger", sample_tb))
        report["sample"]["dispatch_accepted"] = accepted
        sample_actor.tick_script(0.0)
        report["sample"]["actions_completed"] = int(sample_actor.get_runner().get_actions_completed())

    _log(
        "imported scripts created=%s mapped=%s unmapped=%s registry=%s"
        % (
            report["created"],
            report["actions_mapped"],
            report["actions_unmapped"],
            report["registry_num"],
        )
    )
    return report
