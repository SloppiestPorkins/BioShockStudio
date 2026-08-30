"""Headless driver for verify_weapon_ammo.py."""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "weapon_ammo_report.json"),
)

try:
    import verify_weapon_ammo

    verify_weapon_ammo.main(OUT)
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    payload = {"error": str(exc), "traceback": traceback.format_exc()}
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
    raise
