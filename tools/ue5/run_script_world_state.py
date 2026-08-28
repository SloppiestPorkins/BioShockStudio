import json, os, sys, traceback

sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")

QUEST_OUT = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_quest_save_report.json"
INV_OUT = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_inventory_ui_report.json"
WORLD_OUT = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_world_ai_report.json"
PHYS_OUT = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_physics_timer_report.json"
LIGHT_OUT = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_light_sec_report.json"
SUMMARY_OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_world_state_report.json",
)

try:
    import verify_script_quest_save
    import verify_script_inventory_ui
    import verify_script_world_ai
    import verify_script_physics_timer
    import verify_script_light_sec

    verify_script_quest_save.main(QUEST_OUT)
    verify_script_inventory_ui.main(INV_OUT)
    verify_script_world_ai.main(WORLD_OUT)
    verify_script_physics_timer.main(PHYS_OUT)
    verify_script_light_sec.main(LIGHT_OUT)
    os.makedirs(os.path.dirname(os.path.abspath(SUMMARY_OUT)), exist_ok=True)
    with open(SUMMARY_OUT, "w", encoding="utf-8") as handle:
        json.dump({"world_state": "ok"}, handle, indent=2)
except Exception as e:
    open(SUMMARY_OUT, "w", encoding="utf-8").write(
        json.dumps({"error": str(e), "traceback": traceback.format_exc()}, indent=2)
    )
    raise
