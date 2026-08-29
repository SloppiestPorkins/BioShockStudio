import json, os, sys, traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "script_world_state_exec_report.json"),
)
try:
    import verify_script_world_state_exec

    verify_script_world_state_exec.main(OUT)
except Exception as e:
    open(OUT, "w", encoding="utf-8").write(
        json.dumps({"error": str(e), "traceback": traceback.format_exc()}, indent=2)
    )
    raise
