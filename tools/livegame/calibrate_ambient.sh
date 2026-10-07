#!/bin/bash
# Ambient calibration: game paused at one view, UE renders each --ambient-sweep scale.
#   SWEEP=0,1,4 bash tools/livegame/calibrate_ambient.sh <out-dir-windows-path> [stream-seconds]
set -u
OUT_WIN="$1"; STREAM="${2:-90}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$(cygpath -u "$OUT_WIN")"; mkdir -p "$OUT"
LOG="$OUT/live_view.log"; rm -f "$LOG"
MSYS_NO_PATHCONV=1 powershell -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$HERE/live_view.ps1")" ${MAP:+-Map $MAP} -Seconds $((STREAM + 240)) -CaptureDir "$OUT_WIN" -CaptureEvery 1 > "$OUT/live_view.out" 2>&1 &
VIEW=$!
for i in $(seq 1 300); do
  if [ -f "$LOG" ] && grep -q "BIOSHOCK_LIVE start" "$LOG"; then break; fi
  if ! kill -0 $VIEW 2>/dev/null; then echo "live view exited early"; cat "$OUT/live_view.out"; exit 1; fi
  sleep 2
done
grep "BIOSHOCK_LIVE start" "$LOG" || { echo "no BIOSHOCK_LIVE start after 600s"; exit 1; }
sleep 30   # let shaders/textures settle before frames are judged
: no walk during calibration
PYTHONIOENCODING=utf-8 python "$HERE/live_bridge.py" --seconds "$STREAM" --grab-dir "$OUT_WIN" --grab-every 100000 ${SWEEP:+--ambient-sweep $SWEEP} --sweep-hold 10 ${TINT:+--ambient-tint $TINT} ${BSWEEP:+--baked-sweep $BSWEEP} ${AMB:+--ambient-scale $AMB} ${BDEBUG:+--baked-debug $BDEBUG} ${BDSWEEP:+--baked-debug-sweep "$BDSWEEP"} ${BASWEEP:+--baked-ambient-sweep $BASWEEP} ${CAMTARGET:+--camera-target $CAMTARGET}
wait $VIEW
cat "$OUT/live_view.out"
