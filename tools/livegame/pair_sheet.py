"""Pair game_<frame>.png with the nearest ue_<frame>.png and lay the pairs out on one sheet.

    python tools/livegame/pair_sheet.py <dir> [--max-gap 20]
"""
import argparse
import glob
import os
import re

from PIL import Image, ImageDraw


def frames(d, prefix):
    out = {}
    for f in glob.glob(os.path.join(d, f"{prefix}_*.png")):
        m = re.search(rf"{prefix}_(\d+)\.png$", f)
        if m:
            out[int(m.group(1))] = f
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("--max-gap", type=int, default=20, help="frames (at the bridge rate) allowed between a pair")
    ap.add_argument("--width", type=int, default=640)
    args = ap.parse_args()
    game, ue = frames(args.dir, "game"), frames(args.dir, "ue")
    pairs = []
    for f, gpath in sorted(game.items()):
        if not ue:
            break
        best = min(ue, key=lambda u: abs(u - f))
        if abs(best - f) <= args.max_gap:
            pairs.append((f, best, gpath, ue[best]))
    print(f"game frames {len(game)}, ue frames {len(ue)}, pairs {len(pairs)}")
    if not pairs:
        return
    W = args.width
    first = Image.open(pairs[0][2])
    H = int(W * first.height / first.width)
    sheet = Image.new("RGB", (W * 2, H * len(pairs)), (0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    for i, (f, u, gp, up) in enumerate(pairs):
        sheet.paste(Image.open(gp).convert("RGB").resize((W, H)), (0, i * H))
        sheet.paste(Image.open(up).convert("RGB").resize((W, H)), (W, i * H))
        draw.text((6, i * H + 4), f"game frame {f}", fill=(255, 255, 0))
        draw.text((W + 6, i * H + 4), f"UE5 frame {u}", fill=(255, 255, 0))
    out = os.path.join(args.dir, "pairs.png")
    sheet.save(out)
    print("wrote", out)


if __name__ == "__main__":
    main()
