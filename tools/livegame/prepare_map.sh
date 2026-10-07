#!/bin/bash
# Prepare any BioShock level for the live renderer -- the conversion layer, one command per map:
#   bash tools/livegame/prepare_map.sh 2-Fisheries
# Exports (C# CLI) then builds /Game/BioShockLive/<map>_Baked, a COPY of the level (the hand-built
# slice for 1-Medical, else /Game/BioShockLevel/<map>), with the original's baked BSP light,
# per-vertex prop light, material overrides, and the calibrated exposure. Re-runnable: every UE step
# skips work already done; headless imports that assert in Slate after saving are retried.
set -u
MAP="$1"
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
UE_EXPORTS='C:\Users\Jack\Documents\BioShockUE5\Exports'
cd "$REPO" || exit 1
step() { echo; echo "== $*"; }

cli() { dotnet run --project src/BioShockStudio.Cli -c Release -- "$@" 2>&1 | tail -2; }

ORIG="G:\\SteamLibrary\\steamapps\\common\\Bioshock\\Builds\\Release\\UmodelExport\\$MAP\\Texture"
if [ -d "$(cygpath -u "$ORIG")" ]; then export BIOSHOCK_ORIGINAL_TEXTURE_DIR="$ORIG"; else
  echo "note: no original-texture dir for $MAP; BSP UVs use the exporter's remaster-size fallback"; fi

step "export level";            cli export-level "$MAP" "$UE_EXPORTS\\live\\$MAP"
step "export baked lightmaps";  cli export-baked-lightmaps "$MAP" "$UE_EXPORTS\\baked\\$MAP"
step "export vertex lighting";  cli export-vertex-lighting "$MAP" "$UE_EXPORTS\\live\\$MAP\\vertex_lighting.json"

ue() {  # ue <script> <done-marker-regex>: run until the marker appears (max 12 tries)
  local script="$1" marker="$2" log
  for i in $(seq 1 12); do
    python tools/ue5/ue_run.py "tools/ue5/$script" --env BIOSHOCK_MAP="$MAP" --timeout 5400 > /dev/null 2>&1
    log=$(ls -t /c/Users/Jack/Documents/BioShockUE5/Saved/ue_run/*"${script%.py}".log | head -1)
    if grep -q -E "$marker" "$log"; then grep -h -o -E "$marker.*" "$log" | head -1 | cut -c1-240; return 0; fi
    local err; err=$(grep -h -o -E '[A-Za-z]+Error: .{0,160}' "$log" | head -1)
    if [ -n "$err" ]; then echo "FAILED: $err ($log)"; return 1; fi
    echo "  (run $i ended without the marker -- headless import crash after save; retrying)"
  done
  echo "FAILED: $script never completed"; return 1
}

step "missing material instances"; ue create_missing_materials.py "MISSING_MATERIALS (created|0 of)" || exit 1
step "baked world (creates the copy)"; ue import_baked_world.py "BAKED_WORLD slots" || exit 1
step "material overrides";          ue apply_material_overrides.py "MATERIAL_OVERRIDES" || exit 1
step "baked prop light";            ue apply_baked_props.py "BAKED_PROPS" || exit 1
step "live exposure";               ue setup_live_postprocess.py "LIVE_PP" || exit 1
echo; echo "$MAP ready: /Game/BioShockLive/${MAP}_Baked -- play.sh follows the game onto it automatically"
