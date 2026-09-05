"""Headless driver for import_fp_hand_anims.py.

Export first (outside the editor), one dir per owner under %TEMP%/bioshock-fpanim/:

  for W in Shotgun ChemicalThrower Wrench GrenadeLauncher; do
    bioshock-tool export-fbx 0-Lighthouse UAPW_NEWPlayerHands %TEMP%/bioshock-fpanim/$W $W
  done

Then:

  UnrealEditor-Cmd.exe <project>.uproject -run=pythonscript \\
      -script=<repo>/tools/ue5/run_import_fp_hand_anims.py -unattended -nopause -nosplash
"""
import json
import os
import sys
import traceback

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

OUT = os.environ.get(
    "BIOSHOCK_FPANIM_OUT",
    os.path.join(os.environ.get("TEMP", "."), "fp_hand_anims_import_report.json"),
)

result = {"error": None}
try:
    import import_fp_hand_anims

    result = import_fp_hand_anims.main(out=OUT)
except Exception as exc:  # noqa: BLE001 -- commandlet must still write the file
    result["error"] = str(exc)
    result["traceback"] = traceback.format_exc()
    os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    raise
