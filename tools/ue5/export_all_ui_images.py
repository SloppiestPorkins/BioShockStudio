"""Bulk-extract every BioShock FlashMovies Scaleform bitmap (tag 512) via the CLI.

Shells `export-swf-images` over every `*.swf` under FlashMovies into
`%BIOSHOCK_UI_EXPORT%` (default `%TEMP%/bioshock-ui`), one subdirectory per movie,
and writes a top-level `catalogue.json`. No Unreal — raw material for Phase U2's
`import_bioshock_ui.py`.

Requires BIOSHOCK_REMASTERED_PATH (or a detectable Steam install) and a built CLI.
Does not commit PNGs; art stays outside the repo.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone


DEFAULT_OUT = os.path.join(os.environ.get("TEMP", "."), "bioshock-ui")


def _repo_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def _find_cli():
    env = os.environ.get("BIOSHOCK_CLI")
    if env and os.path.isfile(env):
        return env
    candidates = [
        os.path.join(
            _repo_root(),
            "src",
            "BioShockStudio.Cli",
            "bin",
            "Release",
            "net8.0",
            "BioShockStudio.Cli.exe",
        ),
        os.path.join(
            _repo_root(),
            "src",
            "BioShockStudio.Cli",
            "bin",
            "Release",
            "net8.0",
            "BioShockStudio.Cli.dll",
        ),
        os.path.join(
            _repo_root(),
            "src",
            "BioShockStudio.Cli",
            "bin",
            "Debug",
            "net8.0",
            "BioShockStudio.Cli.exe",
        ),
        os.path.join(
            _repo_root(),
            "src",
            "BioShockStudio.Cli",
            "bin",
            "Debug",
            "net8.0",
            "BioShockStudio.Cli.dll",
        ),
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


def _flash_movies_dir():
    root = os.environ.get("BIOSHOCK_REMASTERED_PATH")
    if not root:
        candidates = [
            r"G:\SteamLibrary\steamapps\common\BioShock Remastered",
            r"C:\Program Files (x86)\Steam\steamapps\common\BioShock Remastered",
        ]
        for c in candidates:
            if os.path.isdir(c):
                root = c
                break
    if not root:
        raise SystemExit(
            "BioShock Remastered not found — set BIOSHOCK_REMASTERED_PATH"
        )
    movies = os.path.join(root, "ContentBaked", "pc", "FlashMovies")
    if not os.path.isdir(movies):
        raise SystemExit(f"FlashMovies directory missing: {movies}")
    return movies


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out",
        default=os.environ.get("BIOSHOCK_UI_EXPORT", DEFAULT_OUT),
        help="Root output directory (default: %%TEMP%%/bioshock-ui)",
    )
    parser.add_argument(
        "--cli",
        default=None,
        help="Path to BioShockStudio.Cli.exe/.dll (or set BIOSHOCK_CLI)",
    )
    args = parser.parse_args(argv)

    cli = args.cli or _find_cli()
    if not cli:
        print("CLI not found — building Release…", flush=True)
        subprocess.check_call(
            ["dotnet", "build", "src/BioShockStudio.Cli", "-c", "Release"],
            cwd=_repo_root(),
        )
        cli = _find_cli()
    if not cli:
        print("BioShockStudio.Cli not found after build", file=sys.stderr)
        return 1

    movies = _flash_movies_dir()
    out_root = os.path.abspath(args.out)
    os.makedirs(out_root, exist_ok=True)

    catalogue = {
        "generated": datetime.now(timezone.utc).isoformat(),
        "flashMovies": movies,
        "outRoot": out_root,
        "movies": [],
    }

    swfs = sorted(
        f
        for f in os.listdir(movies)
        if f.lower().endswith(".swf") and not f.lower().endswith(".swf.gsc")
    )
    for name in swfs:
        stem = os.path.splitext(name)[0]
        movie_out = os.path.join(out_root, stem)
        os.makedirs(movie_out, exist_ok=True)
        swf_path = os.path.join(movies, name)
        try:
            _run_cli(cli, ["export-swf-images", swf_path, movie_out])
        except subprocess.CalledProcessError as ex:
            print(f"FAILED {name}: {ex}", file=sys.stderr)
            catalogue["movies"].append(
                {"file": name, "out": movie_out, "ok": False, "error": str(ex)}
            )
            continue

        manifest_path = os.path.join(movie_out, "swf_images_manifest.json")
        images = []
        if os.path.isfile(manifest_path):
            with open(manifest_path, encoding="utf-8") as fh:
                images = json.load(fh)
        catalogue["movies"].append(
            {
                "file": name,
                "out": movie_out,
                "ok": True,
                "imageCount": len(images),
                "manifest": manifest_path,
            }
        )
        print(f"{name}: {len(images)} image(s) -> {movie_out}", flush=True)

    catalogue_path = os.path.join(out_root, "catalogue.json")
    with open(catalogue_path, "w", encoding="utf-8") as fh:
        json.dump(catalogue, fh, indent=2)
    total = sum(m.get("imageCount", 0) for m in catalogue["movies"] if m.get("ok"))
    print(
        f"done: {len(catalogue['movies'])} movie(s), {total} image(s); "
        f"catalogue {catalogue_path}",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
