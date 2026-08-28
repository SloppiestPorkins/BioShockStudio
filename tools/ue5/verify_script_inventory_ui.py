"""Runner Give/RemoveItems + DisplayMap + Print + SetQuestHint."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-inventory-ui] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    give_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionGiveItemsToPlayer"
    )
    remove_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionRemoveItemsFromPlayer"
    )
    map_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionDisplayMapHUDRegion"
    )
    print_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionPrintClientMessage"
    )
    hint_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionSetQuestHint"
    )

    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("InvUiScript", "")
    player = subsystem.spawn_actor_from_class(
        player_cls, unreal.Vector(40, 0, 100), unreal.Rotator(0, 0, 0)
    )

    give = unreal.new_object(give_cls)
    give.configure_inventory("Item.Ammo", 3)
    remove = unreal.new_object(remove_cls)
    remove.configure_inventory("Item.Ammo", 1)
    map_hud = unreal.new_object(map_cls)
    map_hud.configure("Medical Pavilion")
    print_msg = unreal.new_object(print_cls)
    print_msg.configure("hello client", "Info")
    hint = unreal.new_object(hint_cls)
    hint.configure("FindKey", "LookNearDoor")

    runner = script.get_runner()
    for action in (give, remove, map_hud, print_msg, hint):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(5):
        runner.tick_execution(0.0)

    if str(give.get_last_granted_item_class()) != "Item.Ammo":
        f.append("give class %s" % give.get_last_granted_item_class())
    if int(give.get_last_granted_stack_size()) != 3:
        f.append("give stack %s" % give.get_last_granted_stack_size())
    if str(remove.get_last_removed_item_class()) != "Item.Ammo":
        f.append("remove class %s" % remove.get_last_removed_item_class())
    if not bool(map_hud.get_editor_property("bRequested")):
        f.append("map not requested")
    if str(print_msg.get_last_printed_text()) != "hello client":
        f.append("print %s" % print_msg.get_last_printed_text())
    if str(hint.get_last_hint_name()) != "LookNearDoor":
        f.append("hint %s" % hint.get_last_hint_name())
    if player is None:
        f.append("no ShockPlayer")
    else:
        stack = int(player.get_inventory_stack("Item.Ammo"))
        if stack != 3:
            f.append("inventory stack %s" % stack)
        report["ammo_stack"] = stack
    if int(give.get_last_applied_count()) != 1:
        f.append("give applied %s" % give.get_last_applied_count())
    report["inventory_ui"] = "ok"

    if player:
        subsystem.destroy_actor(player)
    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("inventory-ui:\n- " + "\n- ".join(f))
    _log("PASS inventory-ui")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_inventory_ui_report.json",
        )
    )
