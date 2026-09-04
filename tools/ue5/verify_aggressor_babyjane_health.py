"""Report AggressorBabyJane package health: on-disk size and load time.

Run after a forced reimport. Writes %TEMP%/bioshock_aggressor_babyjane_health.json.

    UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript ^
        -script=tools\\ue5\\verify_aggressor_babyjane_health.py -unattended -nopause -nosplash

Healthy: uasset roughly a few MB (not ~1.2 GiB), load well under 10s (not ~130s).
"""

from __future__ import annotations

import json
import os
import time

import unreal

ASSET = "/Game/BioShockCharacters/AggressorBabyJane/AggressorBabyJane"
OUT = os.environ.get(
    "BIOSHOCK_BABYJANE_HEALTH_OUT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock_aggressor_babyjane_health.json"),
)


def main():
    content = unreal.Paths.project_content_dir()
    uasset = os.path.normpath(
        os.path.join(content, "BioShockCharacters", "AggressorBabyJane", "AggressorBabyJane.uasset")
    )
    report = {
        "asset": ASSET,
        "uassetPath": uasset,
        "existsOnDisk": os.path.isfile(uasset),
        "sizeBytes": os.path.getsize(uasset) if os.path.isfile(uasset) else None,
        "loadSeconds": None,
        "loaded": False,
        "ok": False,
        "error": None,
    }
    if report["sizeBytes"] is not None:
        report["sizeMiB"] = round(report["sizeBytes"] / (1024.0 * 1024.0), 2)

    t0 = time.perf_counter()
    mesh = unreal.load_asset(ASSET)
    report["loadSeconds"] = round(time.perf_counter() - t0, 3)
    report["loaded"] = mesh is not None and isinstance(mesh, unreal.SkeletalMesh)

    # Healthy character mesh packages are a few MiB; the crashed reimport left ~1.2 GiB.
    size_ok = report["sizeBytes"] is not None and report["sizeBytes"] < 50 * 1024 * 1024
    load_ok = report["loadSeconds"] is not None and report["loadSeconds"] < 30.0
    report["ok"] = bool(report["loaded"] and size_ok and load_ok)

    unreal.log("[babyjane-health] %s" % json.dumps(report))
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if not report["ok"]:
        raise RuntimeError("AggressorBabyJane unhealthy: %s" % report)
    return report


if __name__ == "__main__":
    main()
