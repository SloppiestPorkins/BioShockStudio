#!/bin/bash
# Start BioShock Remastered straight into a level and get it playing, unattended:
#   bash tools/livegame/start_game.sh [map]        (default 1-Medical; add MUTE=1 to mute it)
# The game pauses (and stops presenting) while unfocused, and its intro videos only advance with
# focus, so this keeps focusing it, skips the intros with Esc, and resumes if a pause menu opens.
set -u
MAP="${1:-1-Medical}"
HERE="$(cd "$(dirname "$0")" && pwd)"
GAME='G:/SteamLibrary/steamapps/common/BioShock Remastered/Build/Final'
key() { powershell -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$HERE/game_input.ps1")" -Key "$1" -HoldMs "${2:-80}" > /dev/null; }
if ! tasklist | grep -qi bioshockhd; then
  (cd "$GAME" && ./BioshockHD.exe "$MAP" > /dev/null 2>&1 &)
  for i in $(seq 1 30); do tasklist | grep -qi bioshockhd && break; sleep 2; done
fi
[ "${MUTE:-0}" = 1 ] && (powershell -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$HERE/mute_app.ps1")" -Seconds 14400 > /dev/null 2>&1 &)
for i in $(seq 1 120); do
  tasklist | grep -qi bioshockhd || { echo "game exited"; exit 1; }
  powershell -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$HERE/dismiss_crash_prompt.ps1")" | grep -v "no prompt"
  PYTHONIOENCODING=utf-8 python "$HERE/game_state.py" "$MAP" > /dev/null 2>&1; rc=$?
  [ $rc -eq 0 ] && { echo "playing $MAP"; exit 0; }
  if [ $rc -eq 2 ]; then key Enter; else key Esc; fi   # 2: in the level but stopped -> resume
  sleep 3
done
echo "gave up waiting for $MAP"; exit 1
