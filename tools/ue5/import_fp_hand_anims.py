"""Import the NEWPlayerHands first-person hand-animation clips for the weapons h8 never landed:
Shotgun, ChemicalThrower, Wrench, GrenadeLauncher.

The clips exist in-game on the UAPW_NEWPlayerHands rig (owners Shotgun / ChemicalThrower /
Wrench / GrenadeLauncher, ~8-12 clips each) but only Pistol / TommyGun / Crossbow were ever
imported. Without them EquipWrench / FidgetShotgun / FireStartChem / etc. don't exist as
UAnimSequence assets and AShockPlayer::TryGetViewHandsAnimNames has nothing to load.

Export first (no Unreal needed), one dir per owner:

  bioshock-tool export-fbx 0-Lighthouse UAPW_NEWPlayerHands <out>/Shotgun         Shotgun
  bioshock-tool export-fbx 0-Lighthouse UAPW_NEWPlayerHands <out>/ChemicalThrower ChemicalThrower
  bioshock-tool export-fbx 0-Lighthouse UAPW_NEWPlayerHands <out>/Wrench          Wrench
  bioshock-tool export-fbx 0-Lighthouse UAPW_NEWPlayerHands <out>/GrenadeLauncher GrenadeLauncher

export-firstperson can't be used here: it takes ONE string for both the owner filter and the
hands socket name, and these weapons' sockets are Chem / Launcher / (none) not the owner name.

Then run this under UnrealEditor-Cmd -run=pythonscript (see run_import_fp_hand_anims.py).
Anims land at /Game/BioShockWeapons/NEWPlayerHands/Animations/ alongside the existing ones.
"""
import json
import os
import sys

import unreal

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import import_bioshock

EXPORT_ROOT = os.environ.get(
    "BIOSHOCK_FPANIM_EXPORT",
    os.path.join(os.environ.get("TEMP", "."), "bioshock-fpanim"),
)
OUT = os.environ.get(
    "BIOSHOCK_FPANIM_OUT",
    os.path.join(os.environ.get("TEMP", "."), "fp_hand_anims_import_report.json"),
)
OWNERS = ["Shotgun", "ChemicalThrower", "Wrench", "GrenadeLauncher"]
ANIM_DIR = "/Game/BioShockWeapons/NEWPlayerHands/Animations"


def main(export_root=None, out=None):
    export_root = export_root or EXPORT_ROOT
    out = out or OUT
    report = {"exportRoot": export_root, "imported": {}, "failures": []}

    for owner in OWNERS:
        d = os.path.join(export_root, owner)
        if not os.path.isfile(os.path.join(d, "ue5_manifest.json")):
            report["failures"].append("%s: no ue5_manifest.json under %s" % (owner, d))
            continue
        try:
            res = import_bioshock.main(d, content_root="/Game/BioShockWeapons")
        except Exception as exc:  # noqa: BLE001
            report["failures"].append("%s: import raised: %s" % (owner, exc))
            continue
        report["imported"][owner] = {
            k: (v.get_path_name() if hasattr(v, "get_path_name") else str(v))
            for k, v in (res or {}).items()
        }

    landed = sorted(
        p.split("/")[-1].split(".")[0]
        for p in (unreal.EditorAssetLibrary.list_assets(ANIM_DIR, recursive=False, include_folder=False) or [])
    )
    report["animationsOnDisk"] = landed
    report["animationCount"] = len(landed)
    report["errorCount"] = len(report["failures"])
    report["fp_hand_anims"] = "ok" if not report["failures"] else "fail"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as h:
        json.dump(report, h, indent=2)
    unreal.log("[fp-hand-anims] imported=%d failures=%d anims_now=%d" % (
        len(report["imported"]), len(report["failures"]), len(landed)))
    for f in report["failures"]:
        unreal.log_error("[fp-hand-anims] FAIL %s" % f)
    if report["failures"]:
        raise RuntimeError("fp-hand-anims: " + "; ".join(report["failures"]))
    return report


if __name__ == "__main__":
    main()
