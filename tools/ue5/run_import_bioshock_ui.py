"""Headless driver for import_bioshock_ui.py.

Stages HUD/Radial/Status/Pause/Station/Hacking/Deco crops via system Python (Pillow),
then imports into /Game/BioShockUI/{HUD,Radial,Status,Pause,Station,Hacking,Deco}.
"""

import json
import os
import subprocess
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_UI_IMPORT_OUT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock_ui_import_report.json"),
)
STAGING = os.environ.get(
    "BIOSHOCK_UI_HUD_STAGING",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-hud-staging"),
)
RADIAL_STAGING = os.environ.get(
    "BIOSHOCK_UI_RADIAL_STAGING",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-radial-staging"),
)
STATUS_STAGING = os.environ.get(
    "BIOSHOCK_UI_STATUS_STAGING",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-status-staging"),
)
PAUSE_STAGING = os.environ.get(
    "BIOSHOCK_UI_PAUSE_STAGING",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-pause-staging"),
)
STATION_STAGING = os.environ.get(
    "BIOSHOCK_UI_STATION_STAGING",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-station-staging"),
)
HACKING_STAGING = os.environ.get(
    "BIOSHOCK_UI_HACKING_STAGING",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-hacking-staging"),
)
DECO_STAGING = os.environ.get(
    "BIOSHOCK_UI_DECO_STAGING",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-deco-staging"),
)
EXPORT = os.environ.get(
    "BIOSHOCK_UI_EXPORT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-ui"),
)

result = {"error": None}
try:
    # Prepare outside Unreal's limited Python (needs Pillow).
    prep = subprocess.run(
        [
            "py",
            "-3",
            os.path.join(os.path.dirname(os.path.abspath(__file__)), "import_bioshock_ui.py"),
            "--prepare",
            "--export",
            EXPORT,
            "--staging",
            STAGING,
            "--radial-staging",
            RADIAL_STAGING,
            "--status-staging",
            STATUS_STAGING,
            "--pause-staging",
            PAUSE_STAGING,
            "--station-staging",
            STATION_STAGING,
            "--hacking-staging",
            HACKING_STAGING,
            "--deco-staging",
            DECO_STAGING,
        ],
        capture_output=True,
        text=True,
    )
    if prep.returncode != 0:
        raise RuntimeError(
            "prepare failed (%s): %s" % (prep.returncode, prep.stderr or prep.stdout)
        )

    import import_bioshock_ui

    result = import_bioshock_ui.main(
        staging_dir=STAGING,
        radial_staging_dir=RADIAL_STAGING,
        status_staging_dir=STATUS_STAGING,
        pause_staging_dir=PAUSE_STAGING,
        station_staging_dir=STATION_STAGING,
        hacking_staging_dir=HACKING_STAGING,
        deco_staging_dir=DECO_STAGING,
        out=OUT,
        prepare_if_needed=False,
    )
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
