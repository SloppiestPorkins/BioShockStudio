"""Click BioShock's client area at (x, y) in client pixels (physical, as grab_game.ps1 captures).
  python tools/livegame/game_click.py 1275 720 [--hover]
The menus highlight what the cursor is over but ignore synthetic clicks: hover, then send Enter
with game_input.ps1 -Key Enter.
"""
import ctypes
import ctypes.wintypes as wt
import sys
import time

u = ctypes.WinDLL("user32")
u.SetProcessDPIAware()
h = u.FindWindowW(None, "Bioshock")
u.ShowWindow(h, 9)
u.SetForegroundWindow(h)
time.sleep(0.5)
pt = wt.POINT(int(sys.argv[1]), int(sys.argv[2]))
u.ClientToScreen(h, ctypes.byref(pt))
u.SetCursorPos(pt.x, pt.y)
time.sleep(0.2)
if "--hover" in sys.argv:
    print("hovered", pt.x, pt.y)
    sys.exit(0)
u.mouse_event(0x0002, 0, 0, 0, 0)
time.sleep(0.08)
u.mouse_event(0x0004, 0, 0, 0, 0)
print("clicked", pt.x, pt.y)
