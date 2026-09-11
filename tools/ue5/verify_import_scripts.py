"""Verify Script actor import from the Medical ue5-level.json."""

import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import import_scripts


def _log(m):
    unreal.log("[bioshock-import-scripts] %s" % m)


def _runtime_object(class_name, outer):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.%s" % class_name)
    if cls is None:
        raise RuntimeError("missing runtime class %s" % class_name)
    return unreal.new_object(cls, outer)


def _verify_parameter_resolution(report):
    """Synthetic execution proof for both ParameterResolveInfo source kinds."""
    actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    actor_cls = unreal.load_class(None, "/Script/Engine.TargetPoint")
    script = actor_subsystem.spawn_actor_from_class(script_cls, unreal.Vector(0, 0, 0))
    point_a = actor_subsystem.spawn_actor_from_class(actor_cls, unreal.Vector(0, 0, 0))
    point_b = actor_subsystem.spawn_actor_from_class(actor_cls, unreal.Vector(300, 0, 0))
    if script is None or point_a is None or point_b is None:
        raise RuntimeError("could not spawn parameter-resolution fixtures")
    try:
        point_a.set_actor_label("VMResolvePointA")
        point_b.set_actor_label("VMResolvePointB")
        point_a.tags = ["VMResolvePointA"]
        point_b.tags = ["VMResolvePointB"]
        script.configure("VMResolveVerify", "")
        runner = script.get_runner()

        assign_input = _runtime_object("ShockActionVariableAssignOverwrite", runner)
        assign_input.configure("MinimumInput", "9")

        random_number = _runtime_object("ShockActionRandomNumber", runner)
        random_number.configure(0.0, 9.0)
        random_number.add_variable_resolver("Minimum", "MinimumInput", "Value")

        assign_random = _runtime_object("ShockActionVariableAssignOverwrite", runner)
        assign_random.configure("Rolled", "unresolved")
        assign_random.add_action_property_resolver("Rhs", random_number, "Value", 101)

        calc_distance = _runtime_object("ShockActionCalcDistance", runner)
        calc_distance.configure("VMResolvePointA", "VMResolvePointB")

        comparison = _runtime_object("ShockBooleanStatement", runner)
        comparison.configure(1, "unresolved", "350")  # distance <= 350
        comparison.add_action_property_resolver("Lhs", calc_distance, "Value", 102)

        branch_assign = _runtime_object("ShockActionVariableAssignOverwrite", runner)
        branch_assign.configure("DistanceBranch", "true")
        if_action = _runtime_object("ShockActionIf", runner)
        if_action.add_test(comparison)
        if_action.add_true_action(branch_assign)

        for action in (assign_input, random_number, assign_random, calc_distance, if_action):
            runner.add_action(action)
        if not runner.start_execution():
            raise RuntimeError("parameter-resolution runner did not start")
        runner.tick_execution(0.0)

        variables = runner.ensure_variables()
        rolled = str(variables.get_value_or_empty("Rolled"))
        branch = str(variables.get_value_or_empty("DistanceBranch"))
        random_value = random_number.get_return_value()
        distance_value = calc_distance.get_return_value()
        checks = {
            "variable_to_parameter": abs(float(random_number.get_minimum()) - 9.0) < 0.0001,
            "random_to_assign": abs(float(rolled) - 9.0) < 0.0001,
            "distance_to_if": branch == "true" and comparison.get_lhs() not in ("", "unresolved"),
            "random_return": random_value is not None,
            "distance_return": distance_value is not None,
        }
        report["parameter_resolution"] = {
            "checks": checks,
            "rolled": rolled,
            "distance": str(distance_value.get_value()) if distance_value else None,
            "branch": branch,
        }
        for name, passed in checks.items():
            if not passed:
                report["failures"].append("parameter resolution %s" % name)
    finally:
        actor_subsystem.destroy_actor(point_b)
        actor_subsystem.destroy_actor(point_a)
        actor_subsystem.destroy_actor(script)


def main(out, manifest=None):
    report = {"failures": []}
    f = report["failures"]

    if manifest is None:
        manifest = os.environ.get(
            "BIOSHOCK_LEVEL_JSON",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json",
        )
    if not os.path.isfile(manifest):
        f.append("missing manifest %s" % manifest)
        raise RuntimeError("no manifest")

    # Decode unit test (no UE spawn)
    hex_player = "0770006C0061007900650072000000"
    if import_scripts.decode_triggered_by_hex(hex_player) != "player":
        f.append("decode player")
    hex_all = "0441006C006C000000"
    if import_scripts.decode_triggered_by_hex(hex_all) != "All":
        f.append("decode All")
    report["decode"] = "ok"

    # Full Medical import is large; include ActionFor at idx 59 (SpawnBall).
    limit_env = os.environ.get("BIOSHOCK_SCRIPT_LIMIT", "70")
    limit = int(limit_env) if limit_env else None
    imported = import_scripts.import_scripts(manifest, limit=limit)
    report["import"] = imported

    if int(imported.get("created", 0)) < 1:
        f.append("created none")
    if int(imported.get("registry_num", 0)) < 1:
        f.append("registry empty")
    if int(imported.get("actions_mapped", 0)) < 1:
        f.append("no actions mapped")
    if int(imported.get("schema_applied", 0)) < 1:
        f.append("schema defaults not applied")
    if int(imported.get("props_loaded", 0)) < 1:
        f.append("script-actions props sidecar not loaded")
    if int(imported.get("instance_applied", 0)) < 200:
        f.append("instance props applied %s (expected >= 200 after widen)" % imported.get("instance_applied"))
    nested_bodies = (
        int(imported.get("nested_true", 0))
        + int(imported.get("nested_else", 0))
        + int(imported.get("nested_loop", 0))
        + int(imported.get("nested_for", 0))
    )
    if nested_bodies < 1:
        f.append(
            "nested If/Loop/For bodies %s (true=%s else=%s loop=%s for=%s)"
            % (
                nested_bodies,
                imported.get("nested_true"),
                imported.get("nested_else"),
                imported.get("nested_loop"),
                imported.get("nested_for"),
            )
        )
    nested_unmapped = imported.get("nested_unmapped_classes") or {}
    for missing in (
        "AndStatement",
        "NotStatement",
        "ActionTestFact",
        "ActionPropertyTest",
        "ActionDisplayMapHUDRegion",
    ):
        if nested_unmapped.get(missing):
            f.append("nested still missing %s (%s)" % (missing, nested_unmapped.get(missing)))
    if int(imported.get("nested_for", 0)) < 1 and int(imported.get("created", 0)) >= 70:
        f.append("expected nested_for>=1 at limit>=70, got %s" % imported.get("nested_for"))
    wait_s = imported.get("wait_seconds_sample")
    if wait_s is None or float(wait_s) <= 0:
        f.append("Wait Seconds sample %s" % wait_s)
    wait_inst = imported.get("wait_instance_seconds")
    if wait_inst is None or abs(float(wait_inst) - 1.0) < 1e-4:
        f.append("expected non-default Wait instance Seconds, got %s" % wait_inst)
    if imported.get("unmapped_classes"):
        f.append("unmapped %s" % imported.get("unmapped_classes"))

    sample = imported.get("sample") or {}
    if sample.get("label") == "TipUnlock1-Medical":
        if sample.get("triggeredBy") != "All":
            f.append("TipUnlock TriggeredBy=%s" % sample.get("triggeredBy"))
        if int(sample.get("dispatch_accepted", 0)) < 1:
            f.append("TipUnlock dispatch %s" % sample.get("dispatch_accepted"))
    else:
        if int(imported.get("with_triggered_by", 0)) < 1:
            f.append("no TriggeredBy in imported set")

    _verify_parameter_resolution(report)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("import-scripts:\n- " + "\n- ".join(f))
    _log("PASS import scripts created=%s" % imported.get("created"))
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\import_scripts_report.json",
        )
    )
