import json, os, sys, traceback
sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")
OUT = os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\action_batch41_report.json")
try:
    import verify_action_batch41
    verify_action_batch41.main(
        OUT,
        os.environ.get("BIOSHOCK_SHOCKGAME_SCHEMA", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json"),
        os.environ.get("BIOSHOCK_SHOCKAI_SCHEMA", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockAI.schema.json"),
    )
except Exception as e:
    open(OUT, "w", encoding="utf-8").write(json.dumps({"error": str(e), "traceback": traceback.format_exc()}, indent=2))
    raise
