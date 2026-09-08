"""Headless driver for verify_audio.py."""

import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_AUDIO_VERIFY_OUT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock_audio_verify.json"),
)

result = {"error": None}
try:
    import verify_audio

    result = verify_audio.main(OUT)
except Exception as exc:  # noqa: BLE001
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
