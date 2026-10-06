"""Phase 0 step 2 (snapshot form): render our UE5 Medical from the original game's live camera.

Reads the camera from the running BioshockHD.exe (pawn Location + EyeHeight, controller Rotation,
DesiredFOV), grabs the game's own frame with PrintWindow, renders the UE5 slice offscreen from the
same camera, and writes both side by side.
"""
import json
import math
import os
import struct
import subprocess
import sys

from PIL import Image

from bsobj import World

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("BIOSHOCK_SBS_OUT", os.path.join(os.environ.get("TEMP", HERE), "bioshock-sbs"))
os.makedirs(OUT, exist_ok=True)
tag = sys.argv[1] if len(sys.argv) > 1 else "shot"

w = World()
objs = {w.full_name(o): o for o in w.obj_ptrs if o}
props = {}


def prop_off(name):
    if name not in props:
        props[name] = w.p.u32(objs[name] + 0x74)  # UProperty::Offset, found 6 Oct 2026
    return props[name]


pc = objs["1-Medical.ShockPlayerController0"]
pawn = w.p.u32(pc + prop_off("Engine.Controller.Pawn"))
loc = struct.unpack("<3f", w.p.read(pawn + prop_off("Engine.Actor.Location"), 12))
eye = struct.unpack("<f", w.p.read(pawn + prop_off("Engine.Pawn.EyeHeight"), 4))[0]
pitch, yaw, roll = struct.unpack("<3i", w.p.read(pc + prop_off("Engine.Actor.Rotation"), 12))
fov = struct.unpack("<f", w.p.read(pc + prop_off("Engine.PlayerController.DesiredFOV"), 4))[0]
to_deg = lambda u: ((u & 0xFFFF) / 65536.0) * 360.0
p, y = to_deg(pitch), to_deg(yaw)
p = p - 360 if p > 180 else p
cam = (loc[0], loc[1], loc[2] + eye)
fwd = (math.cos(math.radians(p)) * math.cos(math.radians(y)), math.cos(math.radians(p)) * math.sin(math.radians(y)),
       math.sin(math.radians(p)))
look = tuple(c + 1000 * f for c, f in zip(cam, fwd))
info = {"cam": cam, "pitch": p, "yaw": y, "fov": fov, "look": look}
print(json.dumps(info))

# The game's own frame (works while the window is unfocused).
game_png = os.path.join(OUT, f"{tag}_game.png")
subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                os.path.join(HERE, "grab_game.ps1"), "-Out", game_png], check=True)
g = Image.open(game_png)
W, H = g.size

ue_png = os.path.join(OUT, f"{tag}_ue5.png")
# BioShock's FOV is horizontal at 4:3 and widens with the window (Hor+); UE5's FOVAngle is the
# horizontal angle of the actual frame.
hfov = math.degrees(2 * math.atan(math.tan(math.radians(fov / 2)) * (W / H) / (4 / 3)))
info["hfov"] = hfov
sw, sh = 1280, int(round(1280 * H / W))
extra = [f"-bioshockshotabs={cam[0]:.0f},{cam[1]:.0f},{cam[2]:.0f}",
         f"-bioshockshotlook={look[0]:.0f},{look[1]:.0f},{look[2]:.0f}",
         f"-bioshockshotfov={hfov:.2f}", f"-bioshockshotwidth={sw}", f"-bioshockshotheight={sh}"]
ps = ("& 'C:/Users/Jack/Documents/BioshockHavok/tools/ue5/capture_shot.ps1' -SettleTicks 60 "
      f"-Out '{ue_png}' -Extra @({','.join(repr(e) for e in extra)})")
r = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps],
                   capture_output=True, text=True)
print("\n".join(l for l in r.stdout.splitlines() if any(k in l for k in ("SHOT", "frame", "NO SHOT", "BLANK", "busy"))))

u = Image.open(ue_png).resize((W, H))
sbs = Image.new("RGB", (W * 2, H))
sbs.paste(g.convert("RGB"), (0, 0))
sbs.paste(u.convert("RGB"), (W, 0))
sbs.save(os.path.join(OUT, f"{tag}_side_by_side.png"))
json.dump(info, open(os.path.join(OUT, f"{tag}.json"), "w"), indent=1)
print("wrote", os.path.join(OUT, f"{tag}_side_by_side.png"))
