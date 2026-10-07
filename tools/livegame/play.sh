#!/bin/bash
# Play BioShock with UE5 drawing it: start BioShock Remastered (Medical) first, then run
#   bash tools/livegame/play.sh [minutes]
# UE opens over the game window (borderless, click-through); keyboard and mouse stay with the game.
# Ctrl+C here ends it. Uses the live-view map copy with the original's baked lighting.
set -u
MIN="${1:-60}"; SECS=$((MIN * 60))
HERE="$(cd "$(dirname "$0")" && pwd)"
read W H < <(python - <<'PY'
import ctypes, ctypes.wintypes as wt
u = ctypes.WinDLL("user32"); u.SetProcessDPIAware()
h = u.FindWindowW(None, "Bioshock"); r = wt.RECT(); u.GetClientRect(h, ctypes.byref(r)); print(r.right, r.bottom)
PY
)
[ "${W:-0}" -gt 0 ] || { echo "BioShock window not found - start the game first"; exit 1; }
LOG="$(cygpath -u "$TEMP")/bioshock-live/live_view.log"; rm -f "$LOG"
MSYS_NO_PATHCONV=1 powershell -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$HERE/live_view.ps1")" \
  -Map "${MAP:-/Game/BioShockLive/1-Medical_Baked}" -Seconds $((SECS + 60)) -Visible -ResX "$W" -ResY "$H" > /dev/null 2>&1 &
VIEW=$!
echo "starting UE5 at ${W}x${H} ..."
for i in $(seq 1 300); do
  [ -f "$LOG" ] && grep -q "BIOSHOCK_LIVE start" "$LOG" && break
  kill -0 $VIEW 2>/dev/null || { echo "UE exited early - see $LOG"; exit 1; }
  sleep 2
done
echo "live - playing for $MIN min (Ctrl+C to stop)"
PYTHONIOENCODING=utf-8 python "$HERE/live_bridge.py" --seconds "$SECS" --overlay
wait $VIEW
