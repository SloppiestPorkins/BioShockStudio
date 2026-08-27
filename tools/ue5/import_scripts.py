"""Import level-placed Script actors from ue5-level.json as AShockScript.

Places Label, location, TriggeredBy (valueHex), and ShockAction stubs. Applies:
1) Phase 2.1 schema *class defaults*, then
2) per-instance scalar props from `export-script-actions` sidecar (bySourceKey),
3) nested If/Loop (and testsOr when a Shock ActionBool exists) from childArrays.

Idempotent via BioShockScriptKey.
"""

from __future__ import annotations

import json
import os

import unreal

KEY_TAG_PREFIX = "BioShockScriptKey="
MAX_NEST_DEPTH = 32

DEFAULT_SCHEMA_DIR = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice"
SCHEMA_FILES = (
    "Scripting.schema.json",
    "ShockGame.schema.json",
    "ShockAI.schema.json",
)

# UnrealScript Action* → concrete UShockAction* when names do not match 1:1.
ACTION_CLASS_OVERRIDES = {
    "ActionVariableAssign": "ShockActionVariableAssignOverwrite",
    # ShockGame.U ships this class name in lowercase.
    "actionSetQuestHint": "ShockActionSetQuestHint",
    "BooleanStatement": "ShockBooleanStatement",
    "TruthStatement": "ShockTruthStatement",
    "AndStatement": "ShockAndStatement",
    "NotStatement": "ShockNotStatement",
}

# Schema Lookup class name when it differs from the placed Action* name.
SCHEMA_CLASS_OVERRIDES = {
    "actionSetQuestHint": "actionSetQuestHint",
}


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
    """Decode Script TriggeredBy Str ValueHex: count byte + UTF-16LE."""
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


def shock_action_class_name(action_class):
    if not action_class:
        return None
    if action_class in ACTION_CLASS_OVERRIDES:
        return ACTION_CLASS_OVERRIDES[action_class]
    if action_class.startswith("Action"):
        return "Shock" + action_class
    return None


def _child_arrays(bag):
    return (bag or {}).get("childArrays") or (bag or {}).get("child_arrays") or {}


def _child_keys(bag, *names):
    arrays = _child_arrays(bag)
    for name in names:
        if name in arrays and arrays[name] is not None:
            return list(arrays[name])
        for key, value in arrays.items():
            if key.lower() == name.lower() and value is not None:
                return list(value)
    return []


def schema_paths(schema_dir=None):
    root = schema_dir or os.environ.get("BIOSHOCK_SCHEMA_DIR", DEFAULT_SCHEMA_DIR)
    return [os.path.join(root, name) for name in SCHEMA_FILES if os.path.isfile(os.path.join(root, name))]


def apply_schema_defaults(action, action_class, paths):
    """Try each schema file until ApplyActionDefaults reports ok."""
    schema_name = SCHEMA_CLASS_OVERRIDES.get(action_class, action_class)
    for path in paths:
        try:
            raw = unreal.ShockSchemaLibrary.apply_action_defaults(action, path, schema_name)
            report = json.loads(raw)
            if report.get("ok"):
                return True, path, report.get("applied") or []
        except Exception:
            continue
    return False, None, []


def load_action_props(props_path):
    if not props_path or not os.path.isfile(props_path):
        return {}
    with open(props_path, "r", encoding="utf-8") as handle:
        doc = json.load(handle)
    return doc.get("bySourceKey") or doc.get("by_source_key") or {}


def _prop(bag, *names):
    props = (bag or {}).get("properties") or {}
    for name in names:
        if name in props and props[name] is not None:
            return props[name]
        # case-insensitive fallback
        for key, value in props.items():
            if key.lower() == name.lower() and value is not None:
                return value
    return None


def apply_instance_props(action, action_class, source_key, props_by_key, stats):
    """Overlay per-instance package properties after schema defaults."""
    if not source_key or source_key not in props_by_key:
        return False
    bag = props_by_key[source_key]
    try:
        if action_class == "ActionWait":
            seconds = _prop(bag, "Seconds")
            if seconds is not None and hasattr(action, "configure"):
                action.configure(float(seconds))
                stats["instance_applied"] += 1
                return True
        if action_class in ("ActionVariableAssign", "ActionVariableAssignIfNotExist"):
            lhs = _prop(bag, "lhs", "Lhs")
            rhs = _prop(bag, "rhs", "Rhs")
            if lhs is not None and rhs is not None and hasattr(action, "configure"):
                action.configure(lhs, str(rhs))
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionScriptNote":
            note = _prop(bag, "Note")
            if note is not None and hasattr(action, "configure"):
                action.configure(str(note))
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionSendTriggerMessage":
            instigator = _prop(bag, "Instigator")
            if instigator is not None and hasattr(action, "configure"):
                action.configure(instigator)
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionLog":
            text = _prop(bag, "Text")
            if text is not None and hasattr(action, "configure"):
                action.configure(str(text))
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionPlayEffect":
            tag = _prop(bag, "EffectTag")
            label = _prop(bag, "ActorLabel")
            event = _prop(bag, "EffectEvent")
            if (tag is not None or label is not None) and hasattr(action, "configure"):
                action.configure(event or "", tag or "", label or "")
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionSetProperty":
            obj = _prop(bag, "Object")
            prop = _prop(bag, "Property")
            value = _prop(bag, "NewValue")
            if obj is not None and prop is not None and value is not None and hasattr(action, "configure"):
                action.configure(obj, prop, str(value))
                stats["instance_applied"] += 1
                return True
        if action_class in ("ActionNonBlockingExecuteScript", "ActionBlockingExecuteScript"):
            target = _prop(bag, "targetScript", "TargetScript")
            if target is not None and hasattr(action, "configure"):
                action.configure(target, action_class == "ActionBlockingExecuteScript")
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionHideOrShowActor":
            label = _prop(bag, "ActorLabel")
            hide = _prop(bag, "HideActor")
            if label is not None and hasattr(action, "configure"):
                action.configure(label, bool(hide) if hide is not None else False)
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionDestroyActor":
            target = _prop(bag, "Target")
            if target is not None and hasattr(action, "configure"):
                action.configure(target)
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionAttackTarget":
            ai = _prop(bag, "AILabel")
            target = _prop(bag, "TargetLabel")
            if ai is not None and target is not None and hasattr(action, "configure"):
                action.configure(ai, target, False)
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionPlayAnimation":
            target = _prop(bag, "TargetLabel")
            anim = _prop(bag, "Animation")
            channel = _prop(bag, "Channel")
            if target is not None and hasattr(action, "configure"):
                action.configure(target, anim or "", 1.0, int(channel) if channel is not None else 0)
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionSpawnAI":
            loc = _prop(bag, "SpawnLocationLabel")
            spawned = _prop(bag, "SpawnedAILabel")
            if loc is not None and hasattr(action, "configure"):
                # Configure(AIType, SpawnLocation, SpawnedLabel, minR, maxR, bForce) — type often default
                ai_type = _prop(bag, "AITypeToSpawn") or ""
                min_r = float(_prop(bag, "MinRadiusToSpawnAroundSpawnLoc") or 0.0)
                max_r = float(_prop(bag, "MaxRadiusToSpawnAroundSpawnLoc") or 0.0)
                force = bool(_prop(bag, "bForceSpawn") or False)
                action.configure(ai_type, loc, spawned or "", min_r, max_r, force)
                stats["instance_applied"] += 1
                return True
        if action_class == "AndStatement":
            lhs = _prop(bag, "lhs", "Lhs")
            rhs = _prop(bag, "rhs", "Rhs")
            if (lhs is not None or rhs is not None) and hasattr(action, "configure"):
                action.configure(bool(lhs) if lhs is not None else False, bool(rhs) if rhs is not None else False)
                stats["instance_applied"] += 1
                return True
        if action_class == "NotStatement":
            rhs = _prop(bag, "rhs", "Rhs")
            if rhs is not None and hasattr(action, "configure"):
                action.configure(bool(rhs))
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionTestFact":
            s1 = _prop(bag, "Slot_1", "Slot1")
            s2 = _prop(bag, "Slot_2", "Slot2")
            s3 = _prop(bag, "Slot_3", "Slot3")
            if s1 is not None and hasattr(action, "configure"):
                action.configure(s1, str(s2 or ""), str(s3 or ""))
                stats["instance_applied"] += 1
                return True
    except Exception:
        stats["instance_fail"] += 1
        return False
    return False


def try_create_action(
    action_class,
    object_name,
    paths,
    stats,
    source_key=None,
    props_by_key=None,
    depth=0,
    visiting=None,
):
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

    ok, _path, applied = apply_schema_defaults(action, action_class, paths)
    if ok:
        stats["schema_applied"] += 1
        stats["schema_props"] += len(applied)
    else:
        stats["schema_miss"] += 1

    apply_instance_props(action, action_class, source_key, props_by_key or {}, stats)

    if action_class == "ActionScriptNote" and hasattr(action, "configure"):
        try:
            note = object_name or action_class
            if hasattr(action, "get_note"):
                current = str(action.get_note() or "")
                if current:
                    note = current
            # Only configure from object name when instance/schema left Note empty.
            if hasattr(action, "get_note") and not str(action.get_note() or ""):
                action.configure(note)
        except Exception:
            pass

    expand_nested_actions(
        action,
        action_class,
        source_key,
        props_by_key or {},
        paths,
        stats,
        depth=depth,
        visiting=visiting,
    )
    return action, "ok"


def _create_from_source_key(child_key, props_by_key, paths, stats, depth, visiting, nest_bucket):
    bag = props_by_key.get(child_key) or {}
    child_class = bag.get("className") or bag.get("class_name") or ""
    child_name = bag.get("objectName") or bag.get("object_name") or child_key
    if not child_class:
        stats["nested_unmapped"] += 1
        stats["nested_unmapped_classes"]["(missing-className)"] = (
            stats["nested_unmapped_classes"].get("(missing-className)", 0) + 1
        )
        return None
    child, status = try_create_action(
        child_class,
        child_name,
        paths,
        stats,
        source_key=child_key,
        props_by_key=props_by_key,
        depth=depth + 1,
        visiting=visiting,
    )
    if child is None:
        stats["nested_unmapped"] += 1
        stats["nested_unmapped_classes"][child_class] = (
            stats["nested_unmapped_classes"].get(child_class, 0) + 1
        )
        return None
    stats[nest_bucket] += 1
    return child


def expand_nested_actions(
    action,
    action_class,
    source_key,
    props_by_key,
    paths,
    stats,
    depth=0,
    visiting=None,
):
    """Wire true/else/loop/tests childGraphs from the package dump."""
    if not source_key or source_key not in props_by_key:
        return
    if depth >= MAX_NEST_DEPTH:
        stats["nested_depth_cap"] += 1
        return

    visiting = set(visiting or ())
    if source_key in visiting:
        stats["nested_cycle_skip"] += 1
        return
    visiting.add(source_key)
    try:
        bag = props_by_key[source_key]
        if action_class == "ActionIf":
            for child_key in _child_keys(bag, "trueActions"):
                child = _create_from_source_key(
                    child_key, props_by_key, paths, stats, depth, visiting, "nested_true"
                )
                if child is not None and hasattr(action, "add_true_action"):
                    action.add_true_action(child)
            for child_key in _child_keys(bag, "elseActions"):
                child = _create_from_source_key(
                    child_key, props_by_key, paths, stats, depth, visiting, "nested_else"
                )
                if child is not None and hasattr(action, "add_else_action"):
                    action.add_else_action(child)
            for child_key in _child_keys(bag, "testsOr"):
                child = _create_from_source_key(
                    child_key, props_by_key, paths, stats, depth, visiting, "nested_tests"
                )
                if child is not None and hasattr(action, "add_test"):
                    try:
                        action.add_test(child)
                    except Exception:
                        stats["nested_test_cast_fail"] += 1
        elif action_class == "ActionLoop":
            for child_key in _child_keys(bag, "loopActions"):
                child = _create_from_source_key(
                    child_key, props_by_key, paths, stats, depth, visiting, "nested_loop"
                )
                if child is not None and hasattr(action, "add_loop_action"):
                    action.add_loop_action(child)
    finally:
        visiting.discard(source_key)


def import_scripts(manifest_path, limit=None, schema_dir=None, props_path=None):
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)

    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    if not script_cls:
        raise RuntimeError("ShockScript class missing — rebuild BioShockRuntime")

    paths = schema_paths(schema_dir)
    if props_path is None:
        props_path = os.environ.get("BIOSHOCK_SCRIPT_ACTION_PROPS")
        if not props_path:
            sibling = os.path.join(
                os.path.dirname(manifest_path),
                PathStem(manifest_path) + ".script-actions.json",
            )
            # Prefer explicit Medical sidecar next to slice schemas.
            candidates = [
                os.path.join(os.path.dirname(manifest_path), "1-Medical.script-actions.json"),
                sibling,
                os.path.join(DEFAULT_SCHEMA_DIR, "1-Medical.script-actions.json"),
            ]
            props_path = next((p for p in candidates if os.path.isfile(p)), None)
    props_by_key = load_action_props(props_path)

    for _key, actor in list(_existing_by_key().items()):
        _actor_subsystem().destroy_actor(actor)

    report = {
        "manifest": manifest_path,
        "schemas": paths,
        "props_path": props_path,
        "props_loaded": len(props_by_key),
        "scripts_in_manifest": 0,
        "created": 0,
        "skipped": 0,
        "actions_mapped": 0,
        "actions_unmapped": 0,
        "unmapped_classes": {},
        "with_triggered_by": 0,
        "schema_applied": 0,
        "schema_miss": 0,
        "schema_props": 0,
        "instance_applied": 0,
        "instance_fail": 0,
        "nested_true": 0,
        "nested_else": 0,
        "nested_loop": 0,
        "nested_tests": 0,
        "nested_unmapped": 0,
        "nested_unmapped_classes": {},
        "nested_depth_cap": 0,
        "nested_cycle_skip": 0,
        "nested_test_cast_fail": 0,
        "registry_num": 0,
        "wait_seconds_sample": None,
        "wait_instance_seconds": None,
        "failures": [],
        "sample": {},
    }
    stats = report

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
            source_key = ref.get("sourceKey")
            action, _status = try_create_action(
                action_class,
                ref.get("objectName"),
                paths,
                stats,
                source_key=source_key,
                props_by_key=props_by_key,
            )
            if action is None:
                report["actions_unmapped"] += 1
                report["unmapped_classes"][action_class] = (
                    report["unmapped_classes"].get(action_class, 0) + 1
                )
                continue
            if action_class == "ActionWait":
                try:
                    seconds = float(action.get_editor_property("seconds"))
                except Exception:
                    seconds = float(getattr(action, "seconds", -1))
                if report["wait_seconds_sample"] is None:
                    report["wait_seconds_sample"] = seconds
                # Prefer a non-default instance override when present.
                if source_key and source_key in props_by_key:
                    inst = _prop(props_by_key[source_key], "Seconds")
                    if inst is not None and abs(float(inst) - 1.0) > 1e-4:
                        report["wait_instance_seconds"] = float(seconds)
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
        "imported scripts created=%s mapped=%s schema=%s instance=%s nested=%s unmapped=%s"
        % (
            report["created"],
            report["actions_mapped"],
            report["schema_applied"],
            report["instance_applied"],
            report["nested_true"]
            + report["nested_else"]
            + report["nested_loop"]
            + report["nested_tests"],
            report["actions_unmapped"],
        )
    )
    return report


def PathStem(path):
    base = os.path.basename(path)
    if base.endswith(".ue5-level.json"):
        return base[: -len(".ue5-level.json")]
    return os.path.splitext(base)[0]