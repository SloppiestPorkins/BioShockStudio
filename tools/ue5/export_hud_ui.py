"""Export BioShock HUD meter art PNGs for import_hud_ui.py (no Unreal required).

Writes to %TEMP%/BioShockHudUi/import by default. Uses BioShockStudio.Cli SWF commands —
does not reimplement SWF decoding.

Requires BIOSHOCK_REMASTERED_PATH (or a detectable Steam install) and a built CLI.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile


DEFAULT_OUT = os.path.join(os.environ.get("TEMP", "."), "BioShockHudUi", "import")

# Health: FrozenHealth_DangerBar sprite (radial-gradient vector arc).
# EVE: unnamed DefineShape3 id 158 (solid blue arc used in HUDCenterBox).
# Underlay: unnamed DefineShape3 id 160 (grey meter chrome arc).
HEALTH_SPRITE_ID = 98
EVE_SHAPE_ID = 158
UNDERLAY_SHAPE_ID = 160


def _repo_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def _find_cli():
    env = os.environ.get("BIOSHOCK_CLI")
    if env and os.path.isfile(env):
        return env
    candidates = [
        os.path.join(_repo_root(), "src", "BioShockStudio.Cli", "bin", "Release", "net8.0", "BioShockStudio.Cli.exe"),
        os.path.join(_repo_root(), "src", "BioShockStudio.Cli", "bin", "Release", "net8.0", "BioShockStudio.Cli.dll"),
    ]
    for path in candidates:
        if os.path.isfile(path):
            return path
    return None


def _run_cli(cli, args):
    if cli.lower().endswith(".dll"):
        cmd = ["dotnet", cli] + args
    else:
        cmd = [cli] + args
    print("+", " ".join(cmd), flush=True)
    subprocess.check_call(cmd, cwd=_repo_root())


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out",
        default=os.environ.get("BIOSHOCK_HUD_UI_EXPORT", DEFAULT_OUT),
        help="PNG output directory (default: %%TEMP%%/BioShockHudUi/import)",
    )
    parser.add_argument(
        "--cli",
        default=None,
        help="Path to BioShockStudio.Cli.exe/.dll (or set BIOSHOCK_CLI)",
    )
    parser.add_argument(
        "--size",
        type=int,
        default=512,
        help="Raster size in pixels (default 512)",
    )
    args = parser.parse_args(argv)

    cli = args.cli or _find_cli()
    if not cli:
        # Build then retry.
        print("CLI not found — building Release…", flush=True)
        subprocess.check_call(
            ["dotnet", "build", "src/BioShockStudio.Cli", "-c", "Release"],
            cwd=_repo_root(),
        )
        cli = _find_cli()
    if not cli:
        print("BioShockStudio.Cli not found after build", file=sys.stderr)
        return 1

    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)
    size = "--size=%d" % args.size

    health_png = os.path.join(out, "T_Hud_HealthArc.png")
    _run_cli(
        cli,
        ["export-swf-sprite", "HUDPC.swf", str(HEALTH_SPRITE_ID), health_png, size],
    )

    with tempfile.TemporaryDirectory(prefix="hud_shapes_") as tmp:
        _run_cli(
            cli,
            ["export-swf-shapes", "HUDPC.swf", tmp, "--id=%d" % EVE_SHAPE_ID, size],
        )
        _run_cli(
            cli,
            ["export-swf-shapes", "HUDPC.swf", tmp, "--id=%d" % UNDERLAY_SHAPE_ID, size],
        )
        eve_src = os.path.join(tmp, "shape_%d.png" % EVE_SHAPE_ID)
        under_src = os.path.join(tmp, "shape_%d.png" % UNDERLAY_SHAPE_ID)
        if not os.path.isfile(eve_src) or not os.path.isfile(under_src):
            print("shape export missing under %s" % tmp, file=sys.stderr)
            return 1
        shutil.copy2(eve_src, os.path.join(out, "T_Hud_EveArc.png"))
        shutil.copy2(under_src, os.path.join(out, "T_Hud_MeterUnderlay.png"))

    manifest = {
        "format": 1,
        "source": {
            "health": {
                "file": "HUDPC.swf",
                "characterId": HEALTH_SPRITE_ID,
                "exportName": "FrozenHealth_DangerBar",
                "png": "T_Hud_HealthArc.png",
            },
            "eve": {
                "file": "HUDPC.swf",
                "characterId": EVE_SHAPE_ID,
                "exportName": None,
                "note": (
                    "unnamed DefineShape3; solid blue arc (117,170,249) from HUDPC composition. "
                    "Canonical sharedlibrary HUD_EveBar_Frame* are Scaleform tag-512 bitmaps — blocked."
                ),
                "png": "T_Hud_EveArc.png",
            },
            "underlay": {
                "file": "HUDPC.swf",
                "characterId": UNDERLAY_SHAPE_ID,
                "exportName": None,
                "png": "T_Hud_MeterUnderlay.png",
            },
        },
        "textures": [
            {"name": "T_Hud_HealthArc", "file": "T_Hud_HealthArc.png", "srgb": True},
            {"name": "T_Hud_EveArc", "file": "T_Hud_EveArc.png", "srgb": True},
            {"name": "T_Hud_MeterUnderlay", "file": "T_Hud_MeterUnderlay.png", "srgb": True},
        ],
        "blockers": [
            (
                "sharedlibrary.swf HUD_HealthBar_Frame01..21 and HUD_EveBar_Frame01..21 use Bitmap "
                "fills backed by Scaleform tag 512 (not classic DefineBits*); export yields grey "
                "placeholders until tag-512 decode exists"
            ),
            (
                "FrozenHealth_DangerBar (id 98) has 20 frames animated via PlaceObject2 ColorTransform "
                "(not Ratio/morph); export-swf-sprite renders frame 0 only — widget maps health%/eve% "
                "to UImage opacity"
            ),
        ],
    }
    with open(os.path.join(out, "hud_ui_manifest.json"), "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
        handle.write("\n")

    print("wrote HUD UI PNGs + manifest to %s" % out, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
