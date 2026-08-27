"""Batch42: AutoSave, CorpseFadeout, PrintClientMessage, ToggleQuestVisibility."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-action-batch42] %s" % m)


def main(out, shockgame, shockai, scripting):
    report = {"failures": []}
    f = report["failures"]

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionAutoSave")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionAutoSave"))
    if not apply.get("ok") or "autosave" not in str(a.get_command()):
        f.append("AutoSave defaults")
    if not a.request_save():
        f.append("AutoSave")
    report["autosave"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionSetCorpseFadeoutTime")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionSetCorpseFadeoutTime"))
    if not apply.get("ok") or abs(float(a.get_fade_out_duration()) - 3.0) > 0.01:
        f.append("CorpseFade defaults")
    a.configure("Thug_A", 5.0)
    if not a.request_fade():
        f.append("CorpseFade")
    report["corpse_fade"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionPrintClientMessage")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, scripting, "ActionPrintClientMessage"))
    if not apply.get("ok"):
        f.append("PrintMsg defaults")
    a.configure("Hello", "Event")
    if not a.request_print():
        f.append("PrintMsg")
    report["print_msg"] = "ok"

    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionToggleQuestVisibility")
    a = unreal.new_object(cls)
    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionToggleQuestVisibility"))
    if not apply.get("ok"):
        f.append("ToggleQuest defaults")
    a.configure("Quest_A")
    if not a.request_toggle():
        f.append("ToggleQuest")
    report["toggle_quest"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("batch42:\n- " + "\n- ".join(f))
    _log("PASS batch42")
    return report


if __name__ == "__main__":
    main(
        os.environ["BIOSHOCK_ACTION_OUT"],
        os.environ["BIOSHOCK_SHOCKGAME_SCHEMA"],
        os.environ["BIOSHOCK_SHOCKAI_SCHEMA"],
        os.environ["BIOSHOCK_SCRIPTING_SCHEMA"],
    )
