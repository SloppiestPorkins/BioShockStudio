"""Verify Script actor import from the Medical ue5-level.json."""

import json
import os

import unreal

import import_scripts


def _log(m):
    unreal.log("[bioshock-import-scripts] %s" % m)


def main(out, manifest=None):
    report = {"failures": []}
    f = report["failures"]

    if manifest is None:
        manifest = os.environ.get(
            "BIOSHOCK_LEVEL_JSON",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json",
        )
    if not os.path.isfile(manifest):
        f.append("missing manifest %s" % manifest)
        raise RuntimeError("no manifest")

    # Decode unit test (no UE spawn)
    hex_player = "0770006C0061007900650072000000"
    if import_scripts.decode_triggered_by_hex(hex_player) != "player":
        f.append("decode player")
    hex_all = "0441006C006C000000"
    if import_scripts.decode_triggered_by_hex(hex_all) != "All":
        f.append("decode All")
    report["decode"] = "ok"

    # Full Medical import is large; cap for headless time unless BIOSHOCK_SCRIPT_LIMIT unset.
    limit_env = os.environ.get("BIOSHOCK_SCRIPT_LIMIT", "40")
    limit = int(limit_env) if limit_env else None
    imported = import_scripts.import_scripts(manifest, limit=limit)
    report["import"] = imported

    if int(imported.get("created", 0)) < 1:
        f.append("created none")
    if int(imported.get("registry_num", 0)) < 1:
        f.append("registry empty")
    if int(imported.get("actions_mapped", 0)) < 1:
        f.append("no actions mapped")

    sample = imported.get("sample") or {}
    if sample.get("label") == "TipUnlock1-Medical":
        if sample.get("triggeredBy") != "All":
            f.append("TipUnlock TriggeredBy=%s" % sample.get("triggeredBy"))
        if int(sample.get("dispatch_accepted", 0)) < 1:
            f.append("TipUnlock dispatch %s" % sample.get("dispatch_accepted"))
    else:
        # TipUnlock may be past the limit — still require some TriggeredBy scripts.
        if int(imported.get("with_triggered_by", 0)) < 1:
            f.append("no TriggeredBy in imported set")

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("import-scripts:\n- " + "\n- ".join(f))
    _log("PASS import scripts created=%s" % imported.get("created"))
    return report


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\import_scripts_report.json",
        )
    )
