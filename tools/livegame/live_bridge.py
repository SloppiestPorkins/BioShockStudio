"""Stream the running original game's camera and moving actors to UE5 (UShockLiveBridge).

    python tools/livegame/live_bridge.py --seconds 60 --grab-dir <dir> --grab-every 2

Reads BioshockHD.exe read-only (bsobj.World), sends UDP text to 127.0.0.1:<port> at --hz. Static
actors (Actor.bStatic) are never sent: the import already placed them. --grab-dir also saves the
game's own frame as game_<frame>.png, to pair with UE's ue_<frame>.png captures.
"""
import argparse
import ctypes
import ctypes.wintypes as wt
import json
import math
import os
import socket
import struct
import time

from bsobj import World

MANIFEST = r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json"
ROT = 360.0 / 65536.0
BSTATIC_MASK = 0x20  # Engine.Actor.bStatic bit in the dword at bHidden's offset (BoolProperty +0x9C)

user32 = ctypes.WinDLL("user32")
gdi32 = ctypes.WinDLL("gdi32")
user32.SetProcessDPIAware()


def deg(u):
    u &= 0xFFFF
    return (u - 65536 if u >= 32768 else u) * ROT


class Grabber:
    """PrintWindow of the game's client area, in physical pixels."""

    def __init__(self, hwnd):
        self.hwnd = hwnd

    def size(self):
        r = wt.RECT()
        user32.GetClientRect(self.hwnd, ctypes.byref(r))
        return r.right, r.bottom

    def grab(self, path):
        from PIL import Image
        wr, cr = wt.RECT(), wt.RECT()
        user32.GetWindowRect(self.hwnd, ctypes.byref(wr))
        user32.GetClientRect(self.hwnd, ctypes.byref(cr))
        pt = wt.POINT(0, 0)
        user32.ClientToScreen(self.hwnd, ctypes.byref(pt))
        ww, wh = wr.right - wr.left, wr.bottom - wr.top
        hdc = user32.GetDC(self.hwnd)
        mdc = gdi32.CreateCompatibleDC(hdc)
        bmp = gdi32.CreateCompatibleBitmap(hdc, ww, wh)
        gdi32.SelectObject(mdc, bmp)
        user32.PrintWindow(self.hwnd, mdc, 2)

        class BIH(ctypes.Structure):
            _fields_ = [("biSize", wt.DWORD), ("biWidth", ctypes.c_long), ("biHeight", ctypes.c_long),
                        ("biPlanes", wt.WORD), ("biBitCount", wt.WORD), ("biCompression", wt.DWORD),
                        ("biSizeImage", wt.DWORD), ("biXPelsPerMeter", ctypes.c_long),
                        ("biYPelsPerMeter", ctypes.c_long), ("biClrUsed", wt.DWORD), ("biClrImportant", wt.DWORD)]
        bih = BIH(ctypes.sizeof(BIH), ww, -wh, 1, 32, 0, 0, 0, 0, 0, 0)
        buf = ctypes.create_string_buffer(ww * wh * 4)
        gdi32.GetDIBits(mdc, bmp, 0, wh, buf, ctypes.byref(bih), 0)
        gdi32.DeleteObject(bmp)
        gdi32.DeleteDC(mdc)
        user32.ReleaseDC(self.hwnd, hdc)
        img = Image.frombuffer("RGBA", (ww, wh), buf, "raw", "BGRA", 0, 1).convert("RGB")
        ox, oy = pt.x - wr.left, pt.y - wr.top
        img.crop((ox, oy, ox + cr.right, oy + cr.bottom)).save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=7781)
    ap.add_argument("--hz", type=float, default=30)
    ap.add_argument("--seconds", type=float, default=60)
    ap.add_argument("--grab-dir", default="")
    ap.add_argument("--grab-every", type=float, default=2.0)
    args = ap.parse_args()

    w = World()
    p = w.p
    objs = {w.full_name(o): o for o in w.obj_ptrs if o}
    off = lambda n: p.u32(objs[n] + 0x74)  # UProperty::Offset
    O_LOC, O_ROT = off("Engine.Actor.Location"), off("Engine.Actor.Rotation")
    O_FLAGS = off("Engine.Actor.bHidden")
    HIDDEN_MASK = p.u32(objs["Engine.Actor.bHidden"] + 0x9C)
    O_PAWN, O_EYE = off("Engine.Controller.Pawn"), off("Engine.Pawn.EyeHeight")
    O_FOV, O_TIME = off("Engine.PlayerController.DesiredFOV"), off("Engine.LevelInfo.TimeSeconds")

    level = "1-Medical"
    manifest = json.load(open(MANIFEST, encoding="utf-8"))
    by_name = {a["name"]: a for a in manifest["actors"]}
    pc = objs[f"{level}.ShockPlayerController0"]
    li = objs[f"{level}.LevelInfo0"]

    moving = []  # (obj, key, baseline line)
    for full, o in objs.items():
        if not full.startswith(level + ".") or full.count(".") != 1:
            continue
        a = by_name.get(full[len(level) + 1:])
        if not a:
            continue
        flags = struct.unpack("<I", p.read(o + O_FLAGS, 4))[0]
        if flags & BSTATIC_MASK:
            continue
        lx, ly, lz = a["location"]
        rp, ry, rr = a["rotation"]
        moving.append((o, a["key"], f"B {a['key']} {lx:.2f} {ly:.2f} {lz:.2f} {deg(rp):.4f} {deg(ry):.4f} {deg(rr):.4f}"))
    print(f"streaming camera + {len(moving)} non-static actors at {args.hz} Hz to :{args.port}", flush=True)

    hwnd = user32.FindWindowW(None, "Bioshock")
    grabber = Grabber(hwnd) if hwnd else None
    if args.grab_dir:
        os.makedirs(args.grab_dir, exist_ok=True)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    dest = ("127.0.0.1", args.port)

    def send(lines):
        chunk, size = [], 0
        for ln in lines:
            if size + len(ln) + 1 > 8000:
                sock.sendto("\n".join(chunk).encode(), dest)
                chunk, size = [], 0
            chunk.append(ln)
            size += len(ln) + 1
        if chunk:
            sock.sendto("\n".join(chunk).encode(), dest)

    last = {}
    frame, t0, next_base, next_grab = 0, time.perf_counter(), 0.0, 0.0
    period = 1.0 / args.hz
    while True:
        now = time.perf_counter() - t0
        if now >= args.seconds:
            break
        frame += 1
        lines = []
        gt = struct.unpack("<f", p.read(li + O_TIME, 4))[0]
        lines.append(f"F {frame} {gt:.3f}")
        pawn = p.u32(pc + O_PAWN)
        if pawn:
            x, y, z = struct.unpack("<3f", p.read(pawn + O_LOC, 12))
            eye = struct.unpack("<f", p.read(pawn + O_EYE, 4))[0]
            cp, cy, cr = struct.unpack("<3i", p.read(pc + O_ROT, 12))
            fov = struct.unpack("<f", p.read(pc + O_FOV, 4))[0]
            cw, ch = grabber.size() if grabber else (16, 9)
            hfov = math.degrees(2 * math.atan(math.tan(math.radians(fov / 2)) * (cw / max(ch, 1)) / (4 / 3)))
            lines.append(f"C {x:.2f} {y:.2f} {z + eye:.2f} {deg(cp):.4f} {deg(cy):.4f} {deg(cr):.4f} {hfov:.3f}")
        if now >= next_base:
            next_base = now + 2.0
            lines += [b for _, _, b in moving]
            last.clear()  # resend every pose after a baseline refresh
        for o, key, _ in moving:
            b = p.read(o + O_LOC, 24)
            if not b or len(b) < 24:
                continue
            flags = struct.unpack("<I", p.read(o + O_FLAGS, 4))[0]
            state = (b, bool(flags & HIDDEN_MASK))
            if last.get(key) == state:
                continue
            last[key] = state
            x, y, z, rp, ry, rr = struct.unpack("<3f3i", b)
            lines.append(f"A {key} {x:.2f} {y:.2f} {z:.2f} {deg(rp):.4f} {deg(ry):.4f} {deg(rr):.4f} {int(state[1])}")
        send(lines)
        if grabber and args.grab_dir and now >= next_grab:
            next_grab = now + args.grab_every
            grabber.grab(os.path.join(args.grab_dir, f"game_{frame:06d}.png"))
        sleep = period - ((time.perf_counter() - t0) - now)
        if sleep > 0:
            time.sleep(sleep)
    print(f"sent {frame} frames in {time.perf_counter() - t0:.1f}s", flush=True)


if __name__ == "__main__":
    main()
