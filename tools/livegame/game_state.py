"""Exit 0 when BioShock is in <map> (default 1-Medical) with a player pawn and a running clock.
  python tools/livegame/game_state.py [map]     prints: level, pawn, clock advance over 1.5 s
Exit 2 when the level is loaded but the clock is stopped (paused, unfocused or a menu is open).
"""
import os
import struct
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bsobj import World  # noqa: E402

level = sys.argv[1] if len(sys.argv) > 1 else "1-Medical"
try:
    w = World()
except Exception:
    sys.exit(1)
p = w.p
objs = {w.full_name(o): o for o in w.obj_ptrs if o}
off = lambda n: p.u32(objs[n] + 0x74)
li = objs.get(f"{level}.LevelInfo0")
pc = next((o for k, o in objs.items() if k.startswith(f"{level}.ShockPlayerController") and k[-1].isdigit()), None)
if not li or not pc:
    sys.exit(1)
pawn = p.u32(pc + off("Engine.Controller.Pawn"))
t = lambda: struct.unpack("<f", p.read(li + off("Engine.LevelInfo.TimeSeconds"), 4))[0]
t0 = t()
time.sleep(1.5)
t1 = t()
print(f"{level} pawn {pawn:#x} clock {t0:.1f} -> {t1:.1f}")
sys.exit(0 if pawn and t1 > t0 + 0.5 else 2)
