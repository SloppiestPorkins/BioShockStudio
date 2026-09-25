"""Headless verify for Global_ shared script variables (SCR-B03 / SCR-G06 / SCR-G18).

Bare ShockScriptRunner objects (no world) share a process-level fallback store. Cases:
  (a) script A assigns Global_X; script B reads it via ActionIf and takes the true branch
  (b) case-insensitive name (global_x)
  (c) non-Global_ names stay local to each runner
  (d) increment of a global from two scripts accumulates
  (e) Global_ on UShockGameInstance.EnsureGlobalVariables survives a simulated travel
      (store object kept on the GI — OpenLevel itself is not driven from Python here)
  (f) ScriptLabel.varname cross-script local read (SCR-G06); dotted assign refused
"""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-global-variables] %s" % m)


def _cls(name):
    c = unreal.load_class(None, "/Script/BioShockRuntime.%s" % name)
    if c is None:
        raise RuntimeError("missing runtime class %s" % name)
    return c


def _assign(name, value):
    a = unreal.new_object(_cls("ShockActionVariableAssignOverwrite"))
    a.configure(name, value)
    return a


def _inc(name):
    a = unreal.new_object(_cls("ShockActionVariableIncrement"))
    a.configure(name)
    return a


def main(out):
    report = {"failures": [], "checks": {}, "untested": []}
    failures = report["failures"]
    checks = report["checks"]

    def check(name, ok, detail=None):
        checks[name] = bool(ok)
        if not ok:
            failures.append("%s failed%s" % (name, (" (%r)" % (detail,)) if detail is not None else ""))

    runner_cls = _cls("ShockScriptRunner")
    reg_cls = _cls("ShockScriptRegistry")
    registry = unreal.new_object(reg_cls)

    # --- (a) A writes Global_X; B ActionIf branches on it ---
    script_a = unreal.new_object(runner_cls)
    script_a.configure("GlobalWriter")
    script_a.set_registry(registry)
    script_a.add_action(_assign("Global_X", "ready"))

    script_b = unreal.new_object(runner_cls)
    script_b.configure("GlobalReader")
    script_b.set_registry(registry)

    comparison = unreal.new_object(_cls("ShockBooleanStatement"))
    comparison.configure(2, "unresolved", "ready")  # equals
    comparison.add_variable_resolver("Lhs", "Global_X", "Value")

    true_assign = _assign("Branch", "true_path")
    else_assign = _assign("Branch", "else_path")
    if_action = unreal.new_object(_cls("ShockActionIf"))
    if_action.add_test(comparison)
    if_action.add_true_action(true_assign)
    if_action.add_else_action(else_assign)
    script_b.add_action(if_action)

    if not bool(script_a.start_execution()):
        failures.append("script_a start")
    script_a.tick_execution(0.0)

    # B must see the global through its own scope before / during the If resolve.
    shared = str(script_b.ensure_variables().get_value_or_empty("Global_X"))
    check("cross_runner_read", shared == "ready", shared)

    if not bool(script_b.start_execution()):
        failures.append("script_b start")
    script_b.tick_execution(0.0)
    branch = str(script_b.ensure_variables().get_value_or_empty("Branch"))
    check("actionif_on_global", branch == "true_path", branch)

    # --- (b) case-insensitive ---
    lower = str(script_b.ensure_variables().get_value_or_empty("global_x"))
    check("case_insensitive", lower == "ready", lower)

    # --- (c) local names are NOT shared ---
    local_a = unreal.new_object(runner_cls)
    local_a.configure("LocalA")
    local_a.set_registry(registry)
    local_a.add_action(_assign("OnlyLocal", "from_a"))
    local_a.start_execution()
    local_a.tick_execution(0.0)

    local_b = unreal.new_object(runner_cls)
    local_b.configure("LocalB")
    local_b.set_registry(registry)
    seen = str(local_b.ensure_variables().get_value_or_empty("OnlyLocal"))
    check("local_not_shared", seen == "", seen)
    check(
        "local_stays_on_writer",
        str(local_a.ensure_variables().get_value_or_empty("OnlyLocal")) == "from_a",
    )

    # --- (d) increment accumulates across two scripts ---
    inc_a = unreal.new_object(runner_cls)
    inc_a.configure("IncA")
    inc_a.set_registry(registry)
    inc_a.add_action(_assign("Global_Counter", "0"))
    inc_a.add_action(_inc("Global_Counter"))
    inc_a.start_execution()
    inc_a.tick_execution(0.0)

    inc_b = unreal.new_object(runner_cls)
    inc_b.configure("IncB")
    inc_b.set_registry(registry)
    inc_b.add_action(_inc("Global_Counter"))
    inc_b.start_execution()
    inc_b.tick_execution(0.0)

    count = str(inc_b.ensure_variables().get_value_or_empty("Global_Counter"))
    check("increment_accumulates", count == "2", count)

    # --- (e) game-instance store survives "travel" (same GI object; OpenLevel not driven) ---
    gi_cls = _cls("ShockGameInstance")
    gi = unreal.new_object(gi_cls)
    gi_scope = gi.ensure_global_variables()
    gi_scope.set("Global_TravelFlag", "survived")
    # Simulate post-travel: re-fetch from the same game instance (GI outlives OpenLevel).
    after = gi.ensure_global_variables()
    travel_val = str(after.get_value_or_empty("Global_TravelFlag"))
    check("gi_store_survives_simulated_travel", travel_val == "survived", travel_val)
    report["untested"].append(
        "OpenLevel / real map travel path not driven from Python; GI-owned store only"
    )

    # Also expose GetSharedGlobals(gi) for the same store.
    shared_api = unreal.ShockVariableScope.get_shared_globals(gi)
    check(
        "get_shared_globals_from_gi",
        shared_api is not None
        and str(shared_api.get_value_or_empty("Global_TravelFlag")) == "survived",
    )

    # --- (f) SCR-G06 dotted local read; assign refused ---
    owner = unreal.new_object(runner_cls)
    owner.configure("OwnerScript")
    owner.set_registry(registry)
    owner.add_action(_assign("Secret", "42"))
    owner.start_execution()
    owner.tick_execution(0.0)

    peer = unreal.new_object(runner_cls)
    peer.configure("PeerScript")
    peer.set_registry(registry)
    peer.ensure_variables()
    dotted = str(peer.ensure_variables().get_value_or_empty("OwnerScript.Secret"))
    check("dotted_cross_script_read", dotted == "42", dotted)

    refused = bool(peer.ensure_variables().set("OwnerScript.Secret", "hacked"))
    still = str(owner.ensure_variables().get_value_or_empty("Secret"))
    check("dotted_assign_refused", refused is False and still == "42", (refused, still))

    report["checks"] = checks
    report["globalVariables"] = "ok" if not failures else "fail"
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    if failures:
        raise RuntimeError("global variables:\n- " + "\n- ".join(failures))
    _log("PASS: Global_ shared store (%d checks)" % len(checks))
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "global_variables_report.json"),
        )
    )
