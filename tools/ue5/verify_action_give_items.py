"""Phase 4 census #16: ActionGiveItemsToPlayer grant-request record (no inventory)."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-action-give-items] %s" % message)


def main(schema_path, report_path):
    with open(schema_path, encoding="utf-8") as handle:
        rows = json.load(handle)
    classes = {row["name"]: row for row in rows}
    report = {"schema": schema_path, "error": None}
    failures = []

    for name in ("ActionGiveItemsToPlayer", "ActionShockInventory"):
        if name not in classes:
            raise RuntimeError("%s missing from %s" % (name, schema_path))

    action_class = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionGiveItemsToPlayer")
    if action_class is None:
        raise RuntimeError("ShockActionGiveItemsToPlayer missing")

    action = unreal.new_object(action_class)
    raw = unreal.ShockSchemaLibrary.apply_action_defaults(
        action, schema_path, "ActionGiveItemsToPlayer")
    apply = json.loads(raw) if isinstance(raw, str) else {"ok": False, "error": str(raw)}
    report["applyOk"] = bool(apply.get("ok"))
    report["applied"] = apply.get("applied") or []
    if not apply.get("ok"):
        failures.append("ApplyActionDefaults failed: %s" % apply.get("error"))

    # StackSize default 1 is on ActionShockInventory; walk may apply via inheritance Lookup
    report["stackDefault"] = int(action.get_stack_size())
    if report["stackDefault"] != 1:
        failures.append("StackSize default should be 1 (got %s)" % report["stackDefault"])

    action.configure_inventory("PistolAmmo", 12)
    if not action.request_give():
        failures.append("RequestGive returned false")
    report["lastItem"] = str(action.get_last_granted_item_class())
    report["lastStack"] = int(action.get_last_granted_stack_size())
    if report["lastItem"] != "PistolAmmo" or report["lastStack"] != 12:
        failures.append("grant record mismatch")

    empty = unreal.new_object(action_class)
    if empty.request_give():
        failures.append("empty ItemClass should fail")
    empty.configure_inventory("PistolAmmo", 0)
    if empty.request_give():
        failures.append("StackSize 0 should fail")

    report["failures"] = failures
    os.makedirs(os.path.dirname(os.path.abspath(report_path)), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("ActionGiveItemsToPlayer failed:\n- " + "\n- ".join(failures))
    _log("PASS: GiveItemsToPlayer records grant request")
    return report


if __name__ == "__main__":
    main(os.environ["BIOSHOCK_ACTION_SCHEMA"], os.environ["BIOSHOCK_ACTION_OUT"])
