"""Headless driver: Medical per-archetype ragdoll coverage (w18)."""

import json
import os
import sys
import traceback

sys.path.append(r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5")

SCHEMA = os.environ.get(
    "BIOSHOCK_RUNTIME_SCHEMA",
    r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json",
)
OUT = os.environ.get(
    "BIOSHOCK_RAGDOLL_COVERAGE_OUT",
    os.path.join(os.environ.get("TEMP", "."), "ragdoll_coverage_report.json"),
)

result = {"error": None}
try:
    import verify_ragdoll_coverage

    result = verify_ragdoll_coverage.main(SCHEMA, OUT)
except Exception as exc:  # noqa: BLE001
    # main() may already have written a full report to OUT before raising --
    # merge the error/traceback into it instead of clobbering that data (w19 fix).
    merged = result
    if os.path.isfile(OUT):
        try:
            with open(OUT, "r", encoding="utf-8") as existing:
                merged = json.load(existing)
        except Exception:  # noqa: BLE001 -- fall back to the stub result on unreadable JSON
            merged = result
    merged["error"] = str(exc)
    merged["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(merged, handle, indent=2)
    raise
