import json, os, sys, traceback
sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")
OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_inventory_ui_report.json",
)
try:
    import verify_script_inventory_ui
    verify_script_inventory_ui.main(OUT)
except Exception as e:
    open(OUT, "w", encoding="utf-8").write(
        json.dumps({"error": str(e), "traceback": traceback.format_exc()}, indent=2)
    )
    raise
