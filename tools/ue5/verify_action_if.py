"""Phase 4 census #3: ActionIf OR of TruthStatement, choose true vs else branch."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-if] %s" % message)


def _new(class_path):
    loaded = unreal.load_class(None, class_path)
    if loaded is None:
        raise RuntimeError("missing class %s" % class_path)
    obj = unreal.new_object(loaded)
    if obj is None:
        raise RuntimeError("new_object failed for %s" % class_path)
    return obj


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None, "cases": []}
    failures = []

    for name in ("ActionIf", "TruthStatement", "ActionBool"):
        if name not in classes:
            raise RuntimeError("%s missing from %s" % (name, schema_path))

    action_if = _new("/Script/BioShockRuntime.ShockActionIf")
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(action_if, schema_path, "ActionIf")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    def case(name, configure_fn, expect_branch):
        configure_fn()
        branch = str(action_if.choose_branch())
        report["cases"].append({"name": name, "branch": branch, "expected": expect_branch})
        if branch != expect_branch:
            failures.append("%s: branch %s != %s" % (name, branch, expect_branch))

    # Empty testsOr → else ("If nothing").
    def empty():
        action_if.get_editor_property("tests_or").clear()
    # TArray clear may not work that way — rebuild object per case instead.
    def fresh_if():
        return _new("/Script/BioShockRuntime.ShockActionIf")

    # Case 1: no tests → else
    a = fresh_if()
    branch = str(a.choose_branch())
    report["cases"].append({"name": "empty_tests", "branch": branch, "expected": "else"})
    if branch != "else":
        failures.append("empty_tests: %s != else" % branch)

    # Case 2: TruthStatement True → true
    a = fresh_if()
    t = _new("/Script/BioShockRuntime.ShockTruthStatement")
    t.configure("True")
    a.add_test(t)
    branch = str(a.choose_branch())
    report["cases"].append({"name": "truth_true", "branch": branch, "expected": "true"})
    if branch != "true":
        failures.append("truth_true: %s != true" % branch)

    # Case 3: TruthStatement False → else
    a = fresh_if()
    t = _new("/Script/BioShockRuntime.ShockTruthStatement")
    t.configure("False")
    a.add_test(t)
    branch = str(a.choose_branch())
    report["cases"].append({"name": "truth_false", "branch": branch, "expected": "else"})
    if branch != "else":
        failures.append("truth_false: %s != else" % branch)

    # Case 4: OR — False then True → true
    a = fresh_if()
    f = _new("/Script/BioShockRuntime.ShockTruthStatement")
    f.configure("False")
    tr = _new("/Script/BioShockRuntime.ShockTruthStatement")
    tr.configure("True")
    a.add_test(f)
    a.add_test(tr)
    branch = str(a.choose_branch())
    report["cases"].append({"name": "or_false_true", "branch": branch, "expected": "true"})
    if branch != "true":
        failures.append("or_false_true: %s != true" % branch)

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionIf failed:\n- " + "\n- ".join(failures))
    _log("PASS: ActionIf OR / true-else branch choice")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
