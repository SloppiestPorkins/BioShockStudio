#!/bin/bash
# Convert every imported level for the live renderer, one after another (hours; run unattended):
#   bash tools/livegame/prepare_all.sh [map ...]     (default: every /Game/BioShockLevel/<map>)
# One log per map in $TEMP/bioshock-prepare/<map>.log; a summary line per map on stdout.
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$(cygpath -u "$TEMP")/bioshock-prepare"; mkdir -p "$OUT"
MAPS=("$@")
[ ${#MAPS[@]} -eq 0 ] && MAPS=($(ls /c/Users/Jack/Documents/BioShockUE5/Content/BioShockLevel/ | grep -v '\.umap$'))
for m in "${MAPS[@]}"; do
  start=$(date +%s)
  bash "$HERE/prepare_map.sh" "$m" > "$OUT/$m.log" 2>&1
  mins=$(( ($(date +%s) - start) / 60 ))
  echo "$m: $(grep -E 'ready:|FAILED' "$OUT/$m.log" | tail -1 | cut -c1-160) (${mins} min)"
done
