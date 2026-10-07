"""First-person probe: what the game draws near the camera (hands, weapon, plasmid FX) and whether
the live bridge would pick it up. Run with BioShock in a level, weapon out:
  python tools/livegame/fp_probe.py
Prints every mesh-drawing actor within 300 units of the player's eye, with the facts discover()
filters on (outer = level package, DrawType 2/8, mesh) plus bHidden, owner, and bone count.
"""
import math
import struct
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bsobj import World  # noqa: E402

w = World()
p = w.p
objs = {w.full_name(o): o for o in w.obj_ptrs if o}
off = lambda n: p.u32(objs[n] + 0x74)
O_LOC, O_FLAGS = off("Engine.Actor.Location"), off("Engine.Actor.bHidden")
HID = p.u32(objs["Engine.Actor.bHidden"] + 0x9C)
O_DT, O_SM, O_SK = off("Engine.Actor.DrawType"), off("Engine.Actor.StaticMesh"), off("Engine.Actor.Mesh")
O_OWNER = off("Engine.Actor.Owner")
O_PAWN, O_EYE = off("Engine.Controller.Pawn"), off("Engine.Pawn.EyeHeight")
actor_cls = objs["Engine.Actor"]
level = next(k.split(".")[0] for k in objs if k.endswith(".ShockPlayerController0"))
pc = objs[f"{level}.ShockPlayerController0"]
pawn = p.u32(pc + O_PAWN)
px, py, pz = struct.unpack("<3f", p.read(pawn + O_LOC, 12))
eye = (px, py, pz + struct.unpack("<f", p.read(pawn + O_EYE, 4))[0])
print(f"level {level}; pawn {w.obj_name(pawn)} eye {eye[0]:.0f} {eye[1]:.0f} {eye[2]:.0f}")
for prop in [k for k in objs if k.startswith(("Engine.Pawn.Weapon", "ShockGame.ShockPlayer.")) and k.count(".") == 2
             and any(t in k for t in ("Weapon", "Hands", "FirstPerson", "View"))][:20]:
    try:
        v = p.u32(pawn + off(prop))
        print(f"  {prop:55s} -> {w.full_name(v) if v and v in set(w.obj_ptrs) else hex(v)}")
    except Exception:
        pass


def is_actor(c):
    for _ in range(40):
        if not c:
            return False
        if c == actor_cls:
            return True
        c = p.u32(c + 0x40)
    return False


level_pkg = objs[level]
rows = []
for o in w.obj_ptrs:
    if not o:
        continue
    h = w.header(o)
    if not h or not is_actor(h["cls"]):
        continue
    b = p.read(o + O_LOC, 12)
    if not b or len(b) < 12:
        continue
    x, y, z = struct.unpack("<3f", b)
    d = math.dist((x, y, z), eye)
    if d > 300:
        continue
    dt = (p.read(o + O_DT, 1) or b"\0")[0]
    mesh = p.u32(o + (O_SM if dt == 8 else O_SK)) if dt in (2, 8) else 0
    si = p.u32(o + 0x3FC) if dt == 2 else 0
    nb = struct.unpack("<I", p.read(si + 0x4C, 4))[0] if si else 0
    flags = struct.unpack("<I", p.read(o + O_FLAGS, 4))[0]
    owner = p.u32(o + O_OWNER)
    rows.append((d, w.full_name(o), w.class_name(o), dt, w.obj_name(mesh) if mesh else "-", nb,
                 bool(flags & HID), h["outer"] == level_pkg, w.obj_name(owner) if owner else "-"))
print(f"\n{'dist':>5} {'actor':45s} {'class':24s} dt {'mesh':28s} bones hidden inLevel owner")
for r in sorted(rows):
    print(f"{r[0]:5.0f} {r[1][:45]:45s} {r[2][:24]:24s} {r[3]:2d} {r[4][:28]:28s} {r[5]:5d} {str(r[6]):6s} {str(r[7]):7s} {r[8]}")
