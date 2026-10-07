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
from snapshot import SnapshotProc

EXPORTS = "C:/Users/Jack/Documents/BioShockUE5/Exports"


def manifest_for(level):
    """The level's export from tools/livegame/prepare_map.sh, else (Medical) the slice export."""
    for path in (os.path.join(EXPORTS, "live", level, level, level + ".ue5-level.json"),
                 os.path.join(EXPORTS, "slice", level, level + ".ue5-level.json")):
        if os.path.exists(path):
            return path
    return None


def current_level(w, objs):
    """The loaded map package: the one owning a LevelInfo0 that is not the Entry level."""
    for name in objs:
        if name.endswith(".LevelInfo0") and name.count(".") == 1 and not name.startswith("Entry."):
            return name.split(".")[0]
    return None
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


class Overlay:
    """Keep the UE live view's window exactly over the game's client area: borderless, topmost,
    click-through and never activated, so the player sees UE5 while keyboard and mouse stay with the
    original game (which only advances while it has focus). ROADMAP Phase 1 item 6."""

    GWL_STYLE, GWL_EXSTYLE = -16, -20
    WS_CAPTION, WS_THICKFRAME, WS_POPUP = 0x00C00000, 0x00040000, 0x80000000
    EX = 0x00080000 | 0x00000020 | 0x00000008 | 0x08000000 | 0x00000080  # LAYERED|TRANSPARENT|TOPMOST|NOACTIVATE|TOOLWINDOW

    def __init__(self, game_hwnd):
        self.game = game_hwnd
        self.ue = None
        user32.GetWindowLongW.restype = ctypes.c_long
        user32.SetWindowLongW.argtypes = [wt.HWND, ctypes.c_int, ctypes.c_long]

    def _find_ue(self):
        import subprocess
        out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq UnrealEditor-Cmd.exe", "/FO", "CSV", "/NH"],
                             capture_output=True, text=True).stdout
        pids = {int(l.split('","')[1]) for l in out.splitlines() if l.startswith('"UnrealEditor-Cmd')}
        found = []

        @ctypes.WINFUNCTYPE(wt.BOOL, wt.HWND, wt.LPARAM)
        def cb(hwnd, _):
            pid = wt.DWORD()
            user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
            r = wt.RECT()
            user32.GetWindowRect(hwnd, ctypes.byref(r))
            if pid.value in pids and user32.IsWindowVisible(hwnd) and (r.right - r.left) > 200:
                found.append(hwnd)
            return True
        user32.EnumWindows(cb, 0)
        return found[0] if found else None

    def update(self):
        if not self.ue:
            self.ue = self._find_ue()
            if not self.ue:
                return False
            style = user32.GetWindowLongW(self.ue, self.GWL_STYLE)
            user32.SetWindowLongW(self.ue, self.GWL_STYLE, (style & ~(self.WS_CAPTION | self.WS_THICKFRAME)) | self.WS_POPUP)
            ex = user32.GetWindowLongW(self.ue, self.GWL_EXSTYLE)
            user32.SetWindowLongW(self.ue, self.GWL_EXSTYLE, ex | self.EX)
            user32.SetLayeredWindowAttributes(self.ue, 0, 255, 2)  # LWA_ALPHA, opaque
            print("overlay: attached to UE window", hex(self.ue), flush=True)
            # UE took focus when its window opened; the game only runs while focused.
            user32.SetForegroundWindow(self.game)
        cr = wt.RECT()
        user32.GetClientRect(self.game, ctypes.byref(cr))
        pt = wt.POINT(0, 0)
        user32.ClientToScreen(self.game, ctypes.byref(pt))
        # HWND_TOPMOST; SWP_NOACTIVATE | SWP_SHOWWINDOW
        user32.SetWindowPos(self.ue, wt.HWND(-1), pt.x, pt.y, cr.right, cr.bottom, 0x0010 | 0x0040)
        return True


def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=7781)
    ap.add_argument("--hz", type=float, default=30)
    ap.add_argument("--seconds", type=float, default=60)
    ap.add_argument("--grab-dir", default="")
    ap.add_argument("--grab-every", type=float, default=2.0)
    ap.add_argument("--ambient-scale", type=float, default=8.0,
                    help="UE AmbientCubemapIntensity per unit of BioShock zone ambient (multiplier/40); 8 matched the game frame within 0.4 EV at the Medical Pavilion sign (6 Oct 2026)")
    ap.add_argument("--ambient-sweep", default="",
                    help="comma list of --ambient-scale values, each held --sweep-hold s (calibration)")
    ap.add_argument("--sweep-hold", type=float, default=12.0)
    ap.add_argument("--baked-ambient", type=float, default=4.0,
                    help="ZoneAmbient on the baked world = zone colour x (multiplier/40) x this; 4 matched the game within 0.3 EV (7 Oct 2026)")
    ap.add_argument("--baked-ambient-sweep", default="", help="comma list of --baked-ambient values, each held --sweep-hold s")
    ap.add_argument("--baked-exposure", type=float, default=1.0,
                    help="BakedExposure for maps with the original's baked BSP light (import_baked_world.py)")
    ap.add_argument("--baked-sweep", default="", help="comma list of --baked-exposure values, each held --sweep-hold s")
    ap.add_argument("--baked-debug-sweep", default="",
                    help="semicolon list of debug modes (e.g. '1,0,0;0,1,0;0,0,0'), each held --sweep-hold s")
    ap.add_argument("--baked-debug", default="", help="useBase,useLightmap (debug: 1,0 = base colour only; 0,1 = baked light only)")
    ap.add_argument("--keep-game-world", action="store_true",
                    help="let the game keep drawing its world (default: the proxy suppresses it and streams the HUD)")
    ap.add_argument("--no-snapshot", action="store_true", help="read game memory directly even if the proxy dxgi.dll is loaded")
    ap.add_argument("--overlay", action="store_true",
                    help="place the (visible) UE live view over the game window, click-through; the game keeps input")
    ap.add_argument("--camera-target", default="",
                    help="debug: frame this spawned actor (e.g. dyn:SpawnedRangedAggressorPistol0) instead of following the player")
    ap.add_argument("--ambient-tint", default="", help="override r,g,b (0-1) instead of the zone colour (calibration)")
    return ap.parse_args()


SUPPRESS = os.path.join(os.environ.get("TEMP", "."), "bioshock-suppress")


def main():
    args = parse_args()
    end = time.perf_counter() + args.seconds
    # Track E3/E4: with the proxy dxgi.dll loaded, the game skips drawing its world (h) and shadows
    # (s) while UE renders, and streams its own HUD to UE instead. Restored on exit.
    if not args.keep_game_world:
        with open(SUPPRESS, "w") as f:
            f.write("hs")
    try:
        while True:
            args.seconds = end - time.perf_counter()
            if args.seconds <= 1 or run(args) != "level-changed":
                break
    finally:
        if not args.keep_game_world and os.path.exists(SUPPRESS):
            os.remove(SUPPRESS)


def run(args):
    """One session on one level; returns "level-changed" when the game travels."""
    w = World()
    p = w.p
    # Track E2: with the proxy dxgi.dll loaded, per-frame reads come from one game frame's snapshot.
    snap = None if args.no_snapshot else SnapshotProc.attach(p)
    print("state feed: " + ("proxy snapshot (frame-consistent)" if snap else "live memory reads"), flush=True)
    objs = {w.full_name(o): o for o in w.obj_ptrs if o}
    off = lambda n: p.u32(objs[n] + 0x74)  # UProperty::Offset
    O_LOC, O_ROT = off("Engine.Actor.Location"), off("Engine.Actor.Rotation")
    O_FLAGS = off("Engine.Actor.bHidden")
    HIDDEN_MASK = p.u32(objs["Engine.Actor.bHidden"] + 0x9C)
    O_PAWN, O_EYE = off("Engine.Controller.Pawn"), off("Engine.Pawn.EyeHeight")
    O_HP, O_MAXHP = off("Engine.Pawn.Health"), off("ShockGame.ShockPawn.MaxHealth")
    O_EVE, O_MAXEVE, O_ADAM = off("ShockGame.ShockPlayer.BioAmmo"), off("ShockGame.ShockPlayer.MaxBioAmmo"), off("ShockGame.ShockPlayer.ADAM")
    # Consumables: ShockPlayer.InventoryManager -> ItemInventory -> ItemSlots (fixed array of
    # InventoryItemStack: ItemClass, StackSize). MedHypo = first-aid kit, BioAmmoHypo = EVE hypo.
    O_INVMGR = off("ShockGame.ShockPlayer.InventoryManager")
    O_ITEMINV = off("ShockGame.InventoryManager.ItemInventory")
    O_SLOTS = off("ShockGame.Inventory.ItemSlots")
    O_STACK_CLS, O_STACK_N = off("ShockGame.ItemStack.ItemClass"), off("ShockGame.ItemStack.StackSize")
    item_name_cache = {}

    def consumables(pawn):
        kits = hypos = 0
        im = p.u32(pawn + O_INVMGR)
        inv = p.u32(im + O_ITEMINV) if im else 0
        if not inv:
            return 0, 0
        raw = p.read(inv + O_SLOTS, 4 * 120) or b""
        for i in range(len(raw) // 4):
            st = struct.unpack_from("<I", raw, i * 4)[0]
            if not st:
                continue
            cls = p.u32(st + O_STACK_CLS)
            if cls not in item_name_cache:
                item_name_cache[cls] = w.obj_name(cls) if cls else None
            name = item_name_cache[cls]
            if name == "MedHypo":
                kits += p.u32(st + O_STACK_N) or 0
            elif name == "BioAmmoHypo":
                hypos += p.u32(st + O_STACK_N) or 0
        return kits, hypos
    O_FOV, O_TIME = off("Engine.PlayerController.DesiredFOV"), off("Engine.LevelInfo.TimeSeconds")
    O_FGFOV = off("Engine.Controller.ForegroundFovAngle")
    O_REGION = off("Engine.Actor.Region")  # FPointRegion; Zone is its first field
    O_AMB_COL = off("Engine.ZoneInfo.CurrentAmbientColorHigh")
    O_AMB_MUL = off("Engine.ZoneInfo.CurrentAmbientColorHighMultiplier")
    sweep = [float(v) for v in args.ambient_sweep.split(",") if v.strip()]
    bsweep = [float(v) for v in args.baked_sweep.split(",") if v.strip()]
    sweep_log = []
    printed_amb = set()

    level = current_level(w, objs)
    mpath = manifest_for(level) if level else None
    if not mpath:
        print(f"no export for level {level!r} - run tools/livegame/prepare_map.sh {level}; waiting", flush=True)
        time.sleep(3)
        return "level-changed"
    print(f"level {level}: {mpath}", flush=True)
    manifest = json.load(open(mpath, encoding="utf-8"))
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

    # Actors the level file lacks (spawned at runtime: enemies, door leaves, pickups, or missing from
    # an old export): found by scanning new objects, sent as S (spawn), D (pose), X (destroyed).
    O_DT = off("Engine.Actor.DrawType")
    O_SMESH, O_SKMESH = off("Engine.Actor.StaticMesh"), off("Engine.Actor.Mesh")
    O_DSCALE = off("Engine.Actor.DrawScale")  # DrawScale3D follows it (0x2AC, 0x2B0)
    level_pkg = objs[level]
    actor_cls = objs["Engine.Actor"]
    pawn_cls = objs["Engine.Pawn"]
    O_CHEIGHT = off("Engine.Actor.CollisionHeight")
    O_OWNER = off("Engine.Actor.Owner")
    first_person = set()  # keys of actors the player owns (hands, held weapon): UE draws them as first person
    is_actor_cache = {}

    def derives(cls, base):
        c, n = cls, 0
        while c and n < 40:
            if c == base:
                return True
            c = p.u32(c + 0x40)
            n += 1
        return False

    def is_actor(cls):
        if cls in is_actor_cache:
            return is_actor_cache[cls]
        c, n, r = cls, 0, False
        while c and n < 40:
            if c == actor_cls:
                r = True
                break
            c = p.u32(c + 0x40)  # UStruct::SuperField
            n += 1
        is_actor_cache[cls] = r
        return r

    dyn = {}           # obj -> (key, kind, mesh)
    # Pawns: Location is the collision cylinder's centre and the mesh origin is at its base, so
    # the stand-in drops by CollisionHeight (a Lady Smith otherwise floated 76 units up).
    pawns = set()
    seen_ptrs = set()

    def discover():
        w.refresh()
        current = set(x for x in w.obj_ptrs if x)
        out = []
        for o in current - seen_ptrs:
            h = w.header(o)
            if not h or h["outer"] != level_pkg:
                continue
            name = w._fname(h)
            if name in by_name or not is_actor(h["cls"]):
                continue
            dt = p.read(o + O_DT, 1)
            if not dt or dt[0] not in (2, 8):
                continue
            mesh = p.u32(o + (O_SMESH if dt[0] == 8 else O_SKMESH))
            mname = w.obj_name(mesh) if mesh else None
            if not mname:
                continue
            dyn[o] = ("dyn:" + name, "static" if dt[0] == 8 else "skel", mname)
            if p.u32(o + O_OWNER) == p.u32(pc + O_PAWN):
                first_person.add("dyn:" + name)
            if dt[0] == 2 and derives(h["cls"], pawn_cls):
                pawns.add(o)
        gone = [o for o in dyn if o not in current]
        for o in gone:
            out.append(f"X {dyn.pop(o)[0]}")
        seen_ptrs.clear()
        seen_ptrs.update(current)
        return out

    # Level actors whose mesh comes from class defaults (vending machines, first-aid kits, keypads):
    # the export records no staticMesh for them, so the import placed nothing. Treat them as stand-ins.
    for a in manifest["actors"]:
        if a.get("staticMesh") or a.get("mesh") or a.get("skeletalMesh"):
            continue
        o = objs.get(f"{level}.{a['name']}")
        dt = p.read(o + O_DT, 1) if o else None
        if not dt or dt[0] not in (2, 8):
            continue
        mesh = p.u32(o + (O_SMESH if dt[0] == 8 else O_SKMESH))
        mname = w.obj_name(mesh) if mesh else None
        if mname:
            dyn[o] = ("dyn:" + a["name"], "static" if dt[0] == 8 else "skel", mname)
    print(f"{len(dyn)} level actors drawn from class-default meshes", flush=True)
    # Every non-static level actor the game draws becomes a stand-in the game drives (pose, bones,
    # visibility, destruction), replacing the placed copies - the import's rest-pose skeletal
    # actors and the old slice's hand-built gameplay actors (a closed ShockDoor sat across Medical's
    # load-room door, 7 Oct 2026). UE hides the copies only once the stand-in exists.
    replaces = {}
    moving_keys = {k for _, k, _ in moving}
    for a in manifest["actors"]:
        o = objs.get(f"{level}.{a['name']}")
        if not o or a["key"] not in moving_keys or o in dyn:
            continue
        dt = p.read(o + O_DT, 1)
        if not dt or dt[0] not in (2, 8):
            continue
        mesh = p.u32(o + (O_SMESH if dt[0] == 8 else O_SKMESH))
        mname = w.obj_name(mesh) if mesh else None
        if not mname:
            continue
        dyn[o] = ("dyn:" + a["name"], "static" if dt[0] == 8 else "skel", mname)
        replaces["dyn:" + a["name"]] = a["key"]
        if dt[0] == 2 and derives(w.header(o)["cls"], pawn_cls):
            pawns.add(o)
    print(f"{len(replaces)} moving level actors replaced by game-driven stand-ins", flush=True)
    # Game skeletal-mesh names are often the rig folder (LoadRoomDoorMESH, BHBuckle_Mesh) while the
    # UE asset is named after the rig (LoadRoomDoorAnim, BHDoorBuckle): map them from the manifests.
    mesh_alias = {}
    for root in (os.path.join(os.path.dirname(mpath), "Rigs"),
                 os.path.join(r"C:/Users/Jack/Documents/BioShockUE5/Exports/slice", level, "Rigs")):
        if not os.path.isdir(root):
            continue
        for folder in os.listdir(root):
            mf = os.path.join(root, folder, "ue5_manifest.json")
            try:
                rigs = json.load(open(mf, encoding="utf-8")).get("rigs") or []
            except (OSError, ValueError):
                continue
            if rigs and rigs[0].get("name") and rigs[0]["name"].lower() != folder.lower():
                mesh_alias.setdefault(folder.lower(), rigs[0]["name"])
    ue_mesh = lambda m: mesh_alias.get(m.lower(), m)
    next_discover = 0.0

    hwnd = user32.FindWindowW(None, "Bioshock")
    grabber = Grabber(hwnd) if hwnd else None
    if args.grab_dir:
        os.makedirs(args.grab_dir, exist_ok=True)

    overlay = Overlay(hwnd) if (args.overlay and hwnd) else None
    next_overlay = 0.0
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
    last_consumables = (0, 0)
    frame, t0, next_base, next_grab = 0, time.perf_counter(), 0.0, 0.0
    period = 1.0 / args.hz
    if snap:
        p = snap  # the frame loop and its helpers now read from snapshots
    while True:
        now = time.perf_counter() - t0
        if now >= args.seconds:
            break
        frame += 1
        lines = []
        if snap:
            snap.begin_frame()
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
            # The viewmodel (hands, held weapon) has its own FOV, Controller.ForegroundFovAngle (60 vs the
            # world's 75): live hand bones projected at it land on the game's drawn hand (7 Oct).
            fgfov = math.degrees(2 * math.atan(math.tan(math.radians((struct.unpack("<f", p.read(pc + O_FGFOV, 4))[0] or fov) / 2)) * (cw / max(ch, 1)) / (4 / 3)))
            lines.append(f"C {x:.2f} {y:.2f} {z + eye:.2f} {deg(cp):.4f} {deg(cy):.4f} {deg(cr):.4f} {hfov:.3f} {fgfov:.3f}")
            hp, mhp = struct.unpack("<f", p.read(pawn + O_HP, 4))[0], struct.unpack("<f", p.read(pawn + O_MAXHP, 4))[0]
            eve, meve = struct.unpack("<f", p.read(pawn + O_EVE, 4))[0], struct.unpack("<f", p.read(pawn + O_MAXEVE, 4))[0]
            adam = struct.unpack("<i", p.read(pawn + O_ADAM, 4))[0]
            kits, hypos = consumables(pawn) if frame % 10 == 1 else last_consumables
            last_consumables = (kits, hypos)
            lines.append(f"H {hp:.1f} {mhp:.1f} {eve:.1f} {meve:.1f} {adam} {kits} {hypos}")
            zone = p.u32(pawn + O_REGION)
            if zone:
                b_, g_, r_, _ = p.read(zone + O_AMB_COL, 4)
                mul = struct.unpack("<f", p.read(zone + O_AMB_MUL, 4))[0]
                scale = args.ambient_scale
                if sweep:
                    stage = min(int(now // args.sweep_hold), len(sweep) - 1)
                    scale = sweep[stage]
                    if not sweep_log or sweep_log[-1][0] != stage:
                        sweep_log.append((stage, scale, frame))
                        print(f"sweep stage {stage}: scale {scale} from frame {frame}", flush=True)
                tint = [float(v) for v in args.ambient_tint.split(",")] if args.ambient_tint else [r_ / 255, g_ / 255, b_ / 255]
                bamb = args.baked_ambient
                if args.baked_ambient_sweep:
                    vals = [float(v) for v in args.baked_ambient_sweep.split(",") if v.strip()]
                    ast_ = min(int(now // args.sweep_hold), len(vals) - 1)
                    bamb = vals[ast_]
                    if ast_ not in printed_amb:
                        printed_amb.add(ast_)
                        print(f"baked ambient stage {ast_}: {bamb} from frame {frame}", flush=True)
                lines.append(f"Z {tint[0]:.4f} {tint[1]:.4f} {tint[2]:.4f} {mul / 40 * scale:.4f} {mul / 40 * bamb:.4f}")
        bexp = args.baked_exposure
        if bsweep:
            bstage = min(int(now // args.sweep_hold), len(bsweep) - 1)
            bexp = bsweep[bstage]
            if not sweep_log or sweep_log[-1][0] != bstage:
                sweep_log.append((bstage, bexp, frame))
                print(f"baked sweep stage {bstage}: exposure {bexp} from frame {frame}", flush=True)
        dbg = args.baked_debug
        if args.baked_debug_sweep:
            modes = [m for m in args.baked_debug_sweep.split(";") if m.strip()]
            dstage = min(int(now // args.sweep_hold), len(modes) - 1)
            dbg = modes[dstage]
            if not sweep_log or sweep_log[-1][0] != dstage:
                sweep_log.append((dstage, dbg, frame))
                print(f"debug stage {dstage}: mode {dbg} from frame {frame}", flush=True)
        lines.append(f"L {bexp:.5f}" + (" " + dbg.replace(",", " ") if dbg else ""))
        if overlay and now >= next_overlay:
            next_overlay = now + 1.0
            overlay.update()
        if now >= next_discover:
            next_discover = now + 1.0
            lines += discover()
        if frame % 30 == 0:
            hdr = w.header(li)
            if not hdr or w._fname(hdr) != "LevelInfo0" or w.obj_name(hdr["outer"]) != level:
                print(f"level {level} unloaded - re-attaching", flush=True)
                return "level-changed"
        if now >= next_base:
            next_base = now + 2.0
            lines.append(f"M {level}")
            lines += [b for _, _, b in moving]
            lines += [f"S {k} {kind} {ue_mesh(mesh)}" + (" fp" if k in first_person else "") + (f" r={replaces[k]}" if k in replaces else "")
                      for k, kind, mesh in dyn.values()]
            last.clear()  # resend every pose after a baseline refresh
        for o, (key, _, _) in list(dyn.items()):
            b = p.read(o + O_LOC, 24)
            sc = p.read(o + O_DSCALE, 16)
            fl = p.read(o + O_FLAGS, 4)
            if not b or not sc or not fl or len(b) < 24 or len(sc) < 16:
                continue
            state = (b, sc, bool(struct.unpack("<I", fl)[0] & HIDDEN_MASK))
            if last.get(key) == state:
                continue
            last[key] = state
            x, y, z, rp, ry, rr = struct.unpack("<3f3i", b)
            ds, sx, sy, sz = struct.unpack("<4f", sc)
            if o in pawns:
                z -= struct.unpack("<f", p.read(o + O_CHEIGHT, 4))[0]
            lines.append(f"D {key} {x:.2f} {y:.2f} {z:.2f} {deg(rp):.4f} {deg(ry):.4f} {deg(rr):.4f} "
                         f"{sx * ds:.4f} {sy * ds:.4f} {sz * ds:.4f} {int(state[2])}")
        # Skeletal stand-ins: the game's evaluated bones, actor +0x3FC -> native SkeletonInstance,
        # TArray<hkQsTransform> at +0x48 (48 bytes: translation, quaternion xyzw, scale), model space.
        for o, (key, kind, _) in dyn.items():
            if kind != "skel":
                continue
            si = p.u32(o + 0x3FC)
            hdr = p.read(si + 0x48, 8) if si else None
            if not hdr or len(hdr) < 8:
                continue
            bptr, nb = struct.unpack("<2I", hdr)
            if not bptr or not (0 < nb <= 256):
                continue
            raw = p.read(bptr, nb * 48)
            if not raw or len(raw) < nb * 48:
                continue
            parts = [f"P {key} {nb}"]
            for i in range(nb):
                tx, ty, tz, _, qx, qy, qz, qw = struct.unpack_from("<8f", raw, i * 48)
                parts.append(f"{tx:.2f} {ty:.2f} {tz:.2f} {qx:.4f} {qy:.4f} {qz:.4f} {qw:.4f}")
            lines.append(" ".join(parts))
        if args.camera_target:
            tgt = next((o for o, (k, _, _) in dyn.items() if k == args.camera_target), None)
            if tgt:
                tx, ty, tz, _, tyaw, _ = struct.unpack("<3f3i", p.read(tgt + O_LOC, 24))
                ya = math.radians(deg(tyaw))
                cx, cy, cz = tx + 260 * math.cos(ya), ty + 260 * math.sin(ya), tz + 30
                lines = [l for l in lines if not l.startswith("C ")]
                cyaw = math.degrees(math.atan2(ty - cy, tx - cx))
                lines.append(f"C {cx:.2f} {cy:.2f} {cz:.2f} 2 {cyaw:.3f} 0 80")
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
    if snap:
        print(f"snapshot: {snap.stats}, regions {len(snap.table)}, last lag {getattr(snap, 'lag', '?')} frames", flush=True)
    if (sweep or bsweep or args.baked_debug_sweep) and args.grab_dir:
        json.dump(sweep_log, open(os.path.join(args.grab_dir, "sweep.json"), "w"))


if __name__ == "__main__":
    main()
