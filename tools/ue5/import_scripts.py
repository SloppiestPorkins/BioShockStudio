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
    "OrStatement": "ShockOrStatement",
    "ArithmeticStatement": "ShockArithmeticStatement",
    "HideNeedleElement": "ShockActionHideNeedleElement",
    "ShowNeedleElement": "ShockActionShowNeedleElement",
    "TrainingCondition": "ShockActionTrainingCondition",
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


def message_filter_fields_from_actor(actor_doc):
    """UE2 Script.messageFilter fields as (name, text) pairs, decoded by the C# exporter
    (resolvedFields on the messageFilter property -- the referenced Message* instance's own
    properties). Empty / None / 0 values are dropped by the runner, matching UE2's rule that
    empty filter fields match anything.
    """
    for prop in actor_doc.get("properties") or []:
        if prop.get("name") == "messageFilter" and prop.get("type") == "Object":
            return [(f["name"], f["text"]) for f in (prop.get("resolvedFields") or [])
                    if f.get("name") and f.get("text") is not None]
    return []


def script_message_class_from_actor(actor_doc):
    """UE2 Script.scriptMessageClass -- an Object-typed FCompactIndex package reference, not a
    plain string like TriggeredBy. The C# exporter resolves it to the real class name
    (resolvedObjectName, docs/research/message-class-gap.md) since decoding an FCompactIndex
    against the level package's export/import tables needs the exporter's own machinery, not
    something Python can do from the raw hex alone. Empty when absent/unresolved -- the
    downstream C++ wildcard default, not a guess.
    """
    for prop in actor_doc.get("properties") or []:
        if prop.get("name") == "scriptMessageClass" and prop.get("type") == "Object":
            return prop.get("resolvedObjectName") or ""
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


def _resolve_infos(bag):
    return list((bag or {}).get("resolveInfo") or (bag or {}).get("resolve_info") or [])


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
        # Per-instance bIsGameCritical from the script-actions sidecar (22 Medical rows carry it).
        crit = _prop(bag, "bIsGameCritical")
        if crit is not None and hasattr(action, "set_editor_property"):
            try:
                action.set_editor_property("b_is_game_critical", bool(crit))
                stats["instance_applied"] += 1
            except Exception:
                pass
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
        if action_class == "ActionOpenDoor":
            door = _prop(bag, "DoorLabel")
            stay = _prop(bag, "StayOpen", "OpenAndHold", "bStayOpen")
            if door is not None and hasattr(action, "configure"):
                action.configure(door, bool(stay) if stay is not None else False)
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionCloseDoor":
            door = _prop(bag, "DoorLabel")
            force = _prop(bag, "ForceClose", "bForceClose")
            if door is not None and hasattr(action, "configure"):
                action.configure(door, bool(force) if force is not None else False)
                stats["instance_applied"] += 1
                return True
        if action_class in ("ActionLockDoor", "ActionUnlockDoor"):
            door = _prop(bag, "DoorLabel")
            if door is not None and hasattr(action, "configure"):
                action.configure(door)
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
        if action_class == "ActionGetProperty":
            obj = _prop(bag, "Object")
            prop = _prop(bag, "Property")
            if obj is not None and prop is not None and hasattr(action, "configure"):
                action.configure(obj, str(prop))
                stats["instance_applied"] += 1
                return True
        if action_class in (
            "ActionVariableAdd",
            "ActionVariableSubtract",
            "ActionVariableMultiply",
            "ActionVariableDivide",
        ):
            lhs = _prop(bag, "lhs", "Lhs")
            rhs = _prop(bag, "rhs", "Rhs")
            if lhs is not None and rhs is not None and hasattr(action, "configure"):
                action.configure(lhs, str(rhs))
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionCalcDistance":
            actor_one = _prop(bag, "actorOne", "ActorOne")
            actor_two = _prop(bag, "actorTwo", "ActorTwo")
            if actor_one is not None and actor_two is not None and hasattr(action, "configure"):
                action.configure(actor_one, actor_two)
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionUnlockBathysphereDestination":
            # Without this the action kept MapName=None and RequestUnlock() refused, so Medical's
            # ToFisheries script never unlocked 2-Fisheries (found by verify_medical_critical_path).
            # BathysphereSystem falls back to the class default from ShockGame.schema.
            map_name = _prop(bag, "MapName", "mapName")
            system = _prop(bag, "BathysphereSystem", "bathysphereSystem") or "BioshockBathyspheres"
            if map_name is not None and hasattr(action, "configure"):
                action.configure(str(map_name), str(system))
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionGetNumItemsInPlayersInventory":
            item_class = _prop(bag, "ItemClass", "itemClass")
            if item_class is not None and hasattr(action, "configure"):
                action.configure(str(item_class))
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionRandomNumber":
            minimum = _prop(bag, "minimum", "Minimum")
            maximum = _prop(bag, "maximum", "Maximum")
            if (minimum is not None or maximum is not None) and hasattr(action, "configure"):
                action.configure(
                    float(minimum) if minimum is not None else 0.0,
                    float(maximum) if maximum is not None else 1.0,
                )
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionGetMessageValue":
            prop = _prop(bag, "Property")
            if prop is not None and hasattr(action, "configure"):
                action.configure(prop)
                stats["instance_applied"] += 1
                return True
        if action_class == "BooleanStatement":
            op = _prop(bag, "logicOp", "LogicOp")
            lhs = _prop(bag, "lhs", "Lhs")
            rhs = _prop(bag, "rhs", "Rhs")
            if (lhs is not None or rhs is not None) and hasattr(action, "configure"):
                action.configure(
                    int(op) if op is not None else 2,
                    str(lhs or ""),
                    str(rhs or ""),
                )
                stats["instance_applied"] += 1
                return True
        if action_class == "TruthStatement":
            value = _prop(bag, "Value")
            if value is not None and hasattr(action, "configure"):
                action.configure(value)
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
                if hasattr(action, "set_wait_for_completion"):
                    action.set_wait_for_completion(
                        bool(_prop(bag, "bWaitForCompletion") or False))
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
        if action_class == "OrStatement":
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
        if action_class == "ArithmeticStatement":
            op = _prop(bag, "ArithmeticOp", "arithmeticOp")
            lhs = _prop(bag, "lhs", "Lhs")
            rhs = _prop(bag, "rhs", "Rhs")
            if hasattr(action, "configure"):
                op_i = 0
                if op is not None:
                    text = str(op)
                    if "SUBTRACT" in text.upper() or text == "1":
                        op_i = 1
                    elif "MULTIPLY" in text.upper() or text == "2":
                        op_i = 2
                    elif "DIVIDE" in text.upper() or text == "3":
                        op_i = 3
                    elif text.isdigit():
                        op_i = int(text)
                action.configure(op_i, str(lhs or ""), str(rhs or ""))
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
        if action_class in ("ActionEnableWatcher", "ActionDisableWatcher"):
            script = _prop(bag, "scriptName", "ScriptName")
            watcher = _prop(bag, "watcherName", "WatcherName")
            if watcher is not None and hasattr(action, "configure"):
                action.configure(script or "", watcher)
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionCreateWatcher":
            # Nested Watcher object carries watcherName/enabled; scalar fallbacks if present.
            watcher = _prop(bag, "watcherName", "WatcherName")
            enabled = _prop(bag, "enabled", "Enabled")
            if watcher is not None and hasattr(action, "configure"):
                action.configure(
                    watcher, None, bool(enabled) if enabled is not None else True)
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionPropertyTest":
            label = _prop(bag, "Label")
            path = _prop(bag, "propertyPath", "PropertyPath")
            value = _prop(bag, "Value")
            op = _prop(bag, "opTest", "OpTest")
            passes = _prop(bag, "maxPasses", "MaxPasses")
            if (label is not None or path is not None) and hasattr(action, "configure"):
                action.configure(
                    label or "",
                    str(path or ""),
                    str(value or ""),
                    int(op) if op is not None else 2,
                    int(passes) if passes is not None else -1,
                )
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionFor":
            counter = _prop(bag, "counterName", "CounterName")
            begin = _prop(bag, "beginValue", "BeginValue")
            end = _prop(bag, "EndValue", "endValue")
            idx = _prop(bag, "CurrentIndex", "currentIndex")
            if counter is not None and hasattr(action, "configure"):
                action.configure(
                    counter,
                    float(begin) if begin is not None else 0.0,
                    float(end) if end is not None else 0.0,
                    int(idx) if idx is not None else -1,
                )
                stats["instance_applied"] += 1
                return True
        if action_class == "ActionDisplayMapHUDRegion":
            desc = _prop(bag, "MapHUDRegionDescription")
            if desc is not None and hasattr(action, "configure"):
                action.configure(str(desc))
                stats["instance_applied"] += 1
                return True
    except Exception:
        stats["instance_fail"] += 1
        return False
    return False


def _source_keys_by_export_index(props_by_key):
    result = {}
    for source_key, bag in (props_by_key or {}).items():
        index = (bag or {}).get("exportIndex")
        if index is None:
            index = (bag or {}).get("export_index")
        if index is not None:
            result[int(index)] = source_key
    return result


def apply_resolve_info(
    action,
    source_key,
    props_by_key,
    source_keys_by_index,
    paths,
    stats,
    depth,
    visiting,
    outer,
    action_cache,
):
    """Thread sidecar v3 ParameterResolveInfo records onto one runtime action."""
    bag = props_by_key.get(source_key) if source_key else None
    for info in _resolve_infos(bag):
        property_name = info.get("propertyName") or info.get("property_name")
        source_kind = info.get("sourceKind") or info.get("source_kind")
        source_property = (
            info.get("sourcePropertyName") or info.get("source_property_name") or "Value"
        )
        if not property_name:
            stats["resolve_invalid"] += 1
            continue
        try:
            if source_kind == "variable":
                variable_name = info.get("variableName") or info.get("variable_name")
                if not variable_name:
                    stats["resolve_invalid"] += 1
                    continue
                action.add_variable_resolver(property_name, variable_name, source_property)
                stats["resolve_variable"] += 1
                continue

            if source_kind == "actionProp":
                source_index = info.get("sourceActionIndex")
                if source_index is None:
                    source_index = info.get("source_action_index")
                producer_key = source_keys_by_index.get(int(source_index)) if source_index is not None else None
                producer_bag = props_by_key.get(producer_key) if producer_key else None
                if not producer_bag:
                    stats["resolve_action_missing"] += 1
                    continue
                producer_class = producer_bag.get("className") or producer_bag.get("class_name") or ""
                producer_name = producer_bag.get("objectName") or producer_bag.get("object_name") or producer_key
                producer, _status = try_create_action(
                    producer_class,
                    producer_name,
                    paths,
                    stats,
                    source_key=producer_key,
                    props_by_key=props_by_key,
                    source_keys_by_index=source_keys_by_index,
                    depth=depth + 1,
                    visiting=visiting,
                    outer=outer,
                    action_cache=action_cache,
                )
                if producer is None:
                    stats["resolve_action_missing"] += 1
                    continue
                action.add_action_property_resolver(
                    property_name, producer, source_property, int(source_index)
                )
                stats["resolve_action_prop"] += 1
                continue

            stats["resolve_invalid"] += 1
        except Exception:
            stats["resolve_invalid"] += 1


def try_create_action(
    action_class,
    object_name,
    paths,
    stats,
    source_key=None,
    props_by_key=None,
    source_keys_by_index=None,
    depth=0,
    visiting=None,
    outer=None,
    action_cache=None,
):
    action_cache = action_cache if action_cache is not None else {}
    if source_key and source_key in action_cache:
        return action_cache[source_key], "ok-cached"
    shock_name = shock_action_class_name(action_class)
    if not shock_name:
        return None, "bad-name"
    cls = unreal.load_class(None, "/Script/BioShockRuntime.%s" % shock_name)
    if not cls:
        return None, "missing-class"
    try:
        # Outer to the owning Runner so the action serialises INTO the map package — without
        # this the action lands in the transient package and resolves to null after the map is
        # saved and reloaded for play (Runner->Actions became [null,...] → StartExecution
        # bailed → LoadRoomDoor et al never ran).
        action = unreal.new_object(cls, outer) if outer is not None else unreal.new_object(cls)
    except Exception:
        return None, "abstract-or-fail"

    # Cache before following resolveInfo/child edges so malformed cycles terminate on identity.
    if source_key:
        action_cache[source_key] = action

    ok, _path, applied = apply_schema_defaults(action, action_class, paths)
    if ok:
        stats["schema_applied"] += 1
        stats["schema_props"] += len(applied)
    else:
        stats["schema_miss"] += 1

    apply_instance_props(action, action_class, source_key, props_by_key or {}, stats)

    apply_resolve_info(
        action,
        source_key,
        props_by_key or {},
        source_keys_by_index or {},
        paths,
        stats,
        depth,
        visiting,
        outer,
        action_cache,
    )

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
        source_keys_by_index or {},
        paths,
        stats,
        depth=depth,
        visiting=visiting,
        outer=outer,
        action_cache=action_cache,
    )
    return action, "ok"


def _create_from_source_key(
    child_key,
    props_by_key,
    source_keys_by_index,
    paths,
    stats,
    depth,
    visiting,
    nest_bucket,
    outer=None,
    action_cache=None,
):
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
        source_keys_by_index=source_keys_by_index,
        depth=depth + 1,
        visiting=visiting,
        outer=outer,
        action_cache=action_cache,
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
    source_keys_by_index,
    paths,
    stats,
    depth=0,
    visiting=None,
    outer=None,
    action_cache=None,
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
                    child_key, props_by_key, source_keys_by_index, paths, stats, depth, visiting,
                    "nested_true", outer=outer, action_cache=action_cache)
                if child is not None and hasattr(action, "add_true_action"):
                    action.add_true_action(child)
            for child_key in _child_keys(bag, "elseActions"):
                child = _create_from_source_key(
                    child_key, props_by_key, source_keys_by_index, paths, stats, depth, visiting,
                    "nested_else", outer=outer, action_cache=action_cache)
                if child is not None and hasattr(action, "add_else_action"):
                    action.add_else_action(child)
            for child_key in _child_keys(bag, "testsOr"):
                child = _create_from_source_key(
                    child_key, props_by_key, source_keys_by_index, paths, stats, depth, visiting,
                    "nested_tests", outer=outer, action_cache=action_cache)
                if child is not None and hasattr(action, "add_test"):
                    try:
                        action.add_test(child)
                    except Exception:
                        stats["nested_test_cast_fail"] += 1
        elif action_class == "ActionLoop":
            for child_key in _child_keys(bag, "loopActions"):
                child = _create_from_source_key(
                    child_key, props_by_key, source_keys_by_index, paths, stats, depth, visiting,
                    "nested_loop", outer=outer, action_cache=action_cache)
                if child is not None and hasattr(action, "add_loop_action"):
                    action.add_loop_action(child)
        elif action_class == "ActionFor":
            for child_key in _child_keys(bag, "forActions"):
                child = _create_from_source_key(
                    child_key, props_by_key, source_keys_by_index, paths, stats, depth, visiting,
                    "nested_for", outer=outer, action_cache=action_cache)
                if child is not None and hasattr(action, "add_for_action"):
                    action.add_for_action(child)
        elif action_class == "ActionCreateWatcher":
            # newWatcher is a WatcherBase (not a UShockAction); pull scalars + nested
            # watchedExpression from its bag. watchedExpression may also sit on CreateWatcher.
            for child_key in _child_keys(bag, "newWatcher", "watchedExpression"):
                child_bag = props_by_key.get(child_key) or {}
                child_class = (child_bag.get("className") or child_bag.get("class") or "")
                # Nested boolean tree (TruthStatement / BooleanStatement / …).
                if child_class and child_class != "Watcher" and child_class != "WatcherBase":
                    child = _create_from_source_key(
                        child_key, props_by_key, source_keys_by_index, paths, stats, depth,
                        visiting, "nested_watcher", outer=outer, action_cache=action_cache)
                    if child is not None and hasattr(action, "set_watched_expression"):
                        action.set_watched_expression(child)
                wname = _prop(child_bag, "watcherName", "WatcherName")
                wen = _prop(child_bag, "enabled", "Enabled")
                if wname is not None and hasattr(action, "configure"):
                    expr = getattr(action, "watched_expression", None)
                    action.configure(wname, expr, bool(wen) if wen is not None else True)
                for expr_key in _child_keys(child_bag, "watchedExpression"):
                    expr = _create_from_source_key(
                        expr_key, props_by_key, source_keys_by_index, paths, stats, depth + 1,
                        visiting, "nested_watcher_expr", outer=outer, action_cache=action_cache)
                    if expr is not None and hasattr(action, "set_watched_expression"):
                        action.set_watched_expression(expr)
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
            # Prefer the sibling of *this* manifest; Medical is a last-resort default only.
            candidates = [
                sibling,
                os.path.join(os.path.dirname(manifest_path), "1-Medical.script-actions.json"),
                os.path.join(DEFAULT_SCHEMA_DIR, "1-Medical.script-actions.json"),
            ]
            props_path = next((p for p in candidates if os.path.isfile(p)), None)
    props_by_key = load_action_props(props_path)
    source_keys_by_index = _source_keys_by_export_index(props_by_key)

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
        "resolve_variable": 0,
        "resolve_action_prop": 0,
        "resolve_action_missing": 0,
        "resolve_invalid": 0,
        "nested_true": 0,
        "nested_else": 0,
        "nested_loop": 0,
        "nested_for": 0,
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
    sample_class = "Message"
    world = unreal.EditorLevelLibrary.get_editor_world()
    if world is not None and hasattr(unreal, "ShockScriptSubsystem"):
        try:
            registry = unreal.ShockScriptSubsystem.get_registry_for_world(world)
        except Exception:
            registry = None

    for actor_doc in scripts:
        key = actor_doc.get("key") or ("Script_%s" % actor_doc.get("exportIndex"))
        label = actor_doc.get("label") or actor_doc.get("name") or key
        triggered_by = triggered_by_from_actor(actor_doc)
        if triggered_by:
            report["with_triggered_by"] += 1
        script_message_class = script_message_class_from_actor(actor_doc)
        if script_message_class:
            report["with_script_message_class"] = report.get("with_script_message_class", 0) + 1

        location = actor_doc.get("location") or [0, 0, 0]
        loc = unreal.Vector(float(location[0]), float(location[1]), float(location[2]))
        actor = _actor_subsystem().spawn_actor_from_class(script_cls, loc, unreal.Rotator(0, 0, 0))
        if actor is None:
            report["skipped"] += 1
            continue
        report["created"] += 1
        # BioShockLabel= lets packaged (non-WITH_EDITOR) builds resolve the script by label.
        actor.tags = [KEY_TAG_PREFIX + key, "BioShockLabel=" + str(label)]
        actor.set_actor_label(str(label))
        actor.configure(label, triggered_by)
        if registry is None:
            registry = actor.ensure_registry()
        else:
            actor.set_registry(registry)

        runner = actor.get_runner()
        if script_message_class:
            runner.set_script_message_class(unreal.Name(script_message_class))
        for fname, ftext in message_filter_fields_from_actor(actor_doc):
            runner.set_message_filter_field(fname, ftext)
            report["message_filter_fields"] = report.get("message_filter_fields", 0) + 1
        action_cache = {}
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
                source_keys_by_index=source_keys_by_index,
                outer=runner,
                action_cache=action_cache,
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
            sample_class = script_message_class or "Message"
            report["sample"] = {
                "label": str(label),
                "triggeredBy": triggered_by,
                "action_stubs": action_count,
            }

    if registry is not None:
        report["registry_num"] = int(registry.num())

    if registry is not None and sample_actor is not None and sample_tb:
        accepted = int(registry.dispatch_message(sample_class, sample_tb))
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
            + report["nested_for"]
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