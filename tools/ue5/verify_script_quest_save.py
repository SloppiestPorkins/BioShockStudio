"""Runner Initiate/Complete/Fail quest + AutoSave."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-quest-save] %s" % m)


def main(out):
    report = {"failures": []}
    f = report["failures"]

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    init_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionInitiateQuest")
    obj_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionCompleteQuestObjective"
    )
    complete_cls = unreal.load_class(
        None, "/Script/BioShockRuntime.ShockActionCompleteQuest"
    )
    fail_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionFailQuest")
    save_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAutoSave")

    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")

    script = subsystem.spawn_actor_from_class(
        script_cls, unreal.Vector(0, 0, 220), unreal.Rotator(0, 0, 0)
    )
    script.configure("QuestSaveScript", "")
    player = subsystem.spawn_actor_from_class(
        player_cls, unreal.Vector(40, 0, 100), unreal.Rotator(0, 0, 0)
    )

    init_q = unreal.new_object(init_cls)
    init_q.configure("FindKey", True, True, "New quest")
    obj_q = unreal.new_object(obj_cls)
    obj_q.configure("FindKey", True, 1)
    complete_q = unreal.new_object(complete_cls)
    complete_q.configure("FindKey", True)
    fail_q = unreal.new_object(fail_cls)
    fail_q.configure("OtherQuest", "failed")
    save = unreal.new_object(save_cls)
    save.configure("savegame autosave")

    runner = script.get_runner()
    for action in (init_q, obj_q, complete_q, fail_q, save):
        runner.add_action(action)
    if not runner.start_execution():
        f.append("StartExecution")
    for _ in range(5):
        runner.tick_execution(0.0)

    if str(init_q.get_last_quest_name()) != "FindKey":
        f.append("init %s" % init_q.get_last_quest_name())
    if str(obj_q.get_last_quest_name()) != "FindKey":
        f.append("obj %s" % obj_q.get_last_quest_name())
    if str(complete_q.get_last_quest_name()) != "FindKey":
        f.append("complete %s" % complete_q.get_last_quest_name())
    if str(fail_q.get_last_quest_name()) != "OtherQuest":
        f.append("fail %s" % fail_q.get_last_quest_name())
    if str(save.get_last_saved_command()) != "savegame autosave":
        f.append("save %s" % save.get_last_saved_command())
    if player is None:
        f.append("no ShockPlayer")
    else:
        find_state = int(player.get_quest_state("FindKey"))
        if find_state != 2:
            f.append("FindKey state %s" % find_state)
        obj_count = int(player.get_quest_objective_count("FindKey"))
        if obj_count != 1:
            f.append("FindKey objectives %s" % obj_count)
        fail_state = int(player.get_quest_state("OtherQuest"))
        if fail_state != 3:
            f.append("OtherQuest state %s" % fail_state)
        cmd = str(player.get_auto_save_command())
        if cmd != "savegame autosave":
            f.append("player autosave %s" % cmd)
        report["find_key_state"] = find_state
        report["find_key_objectives"] = obj_count
        report["other_quest_state"] = fail_state
    report["quest_save"] = "ok"

    if player:
        subsystem.destroy_actor(player)
    subsystem.destroy_actor(script)

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("quest-save:\n- " + "\n- ".join(f))
    _log("PASS quest-save")
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_quest_save_report.json",
        )
    )
