"""Batch45: BooleanStatement — final referenced action from census probe."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch45] %s" % m)


def main(out, scripting):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockBooleanStatement")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "BooleanStatement"))
    if not apply.get("ok") or int(a.get_logic_op()) != 2:
        f.append("BoolStmt defaults")
    a.configure(2, "a", "a")
    if not bool(a.test_evaluate()):
        f.append("BoolStmt eval")
    a.configure(3, "a", "b")
    if not bool(a.test_evaluate()):
        f.append("BoolStmt neq")
    report["bool_stmt"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch45:\n- " + "\n- ".join(f))
    _log("PASS batch45")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_ACTION_OUT"],
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
    )
