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

ue() {  # ue <script> <done-marker-regex> [KEY=VALUE env ...]: run until the marker appears
  # Headless imports save an asset and then assert in Slate, so each run makes progress and a
  # relaunch resumes. A run that saved nothing taught nothing: stop after two of those in a row
  # (Fisheries once burned 10 identical relaunches).
  local script="$1" marker="$2" log stall=0 stamp; shift 2
  local extra=(); for kv in "$@"; do extra+=(--env "$kv"); done
  stamp=$(mktemp)
  for i in $(seq 1 30); do
    touch "$stamp"
    python tools/ue5/ue_run.py "tools/ue5/$script" --env BIOSHOCK_MAP="$MAP" "${extra[@]}" --timeout 7200 > /dev/null 2>&1
    log=$(ls -t /c/Users/Jack/Documents/BioShockUE5/Saved/ue_run/*"${script%.py}".log | head -1)
    if grep -q -E "$marker" "$log"; then grep -h -o -E "$marker.*" "$log" | head -1 | cut -c1-240; rm -f "$stamp"; return 0; fi
    # Python exceptions only: the post-save Slate crash also logs "GetLastError: ...".
    local err; err=$(grep -h -o -E '(Value|Type|Key|Attribute|Runtime|Index|Name|FileNotFound|Assertion|OS)Error: .{0,160}' "$log" | head -1)
    if [ -n "$err" ]; then echo "FAILED: $err ($log)"; rm -f "$stamp"; return 1; fi
    if [ -n "$(find /c/Users/Jack/Documents/BioShockUE5/Content -name '*.uasset' -newer "$stamp" -print -quit)" ]; then
      stall=0; echo "  (run $i saved assets, then the headless import crash; resuming)"
    else
      stall=$((stall + 1)); echo "  (run $i saved nothing)"
      if [ "$stall" -ge 2 ]; then echo "FAILED: $script made no progress in two runs ($log)"; rm -f "$stamp"; return 1; fi
    fi
  done
  rm -f "$stamp"; echo "FAILED: $script never completed"; return 1
}

step "missing material instances"; ue create_missing_materials.py "MISSING_MATERIALS (created|0 of)" || exit 1
step "baked world (creates the copy)"; ue import_baked_world.py "BAKED_WORLD slots" || exit 1
# Base maps were imported before the struct-array reader fix and lack actors (Fisheries had lost its
# central staircase). Bring the copy's actors up to the fresh export -- materials additive only, so
# instances shared with the hand-built slice are never re-configured.
LIVE_JSON="C:/Users/Jack/Documents/BioShockUE5/Exports/live/$MAP/$MAP/$MAP.ue5-level.json"
step "sync actors to the fresh export"; ue reimport_slice_level.py "\[reimport-slice-level\]"   BIOSHOCK_SLICE_MAP="/Game/BioShockLive/${MAP}_Baked" BIOSHOCK_LEVEL_JSON="$LIVE_JSON" BIOSHOCK_MATERIALS_ADDITIVE=1 || exit 1
step "baked world again (re-hide the compiled world)"; ue import_baked_world.py "BAKED_WORLD slots" || exit 1
step "material overrides";          ue apply_material_overrides.py "MATERIAL_OVERRIDES" || exit 1
VL="$(cygpath -u "$UE_EXPORTS")/live/$MAP/vertex_lighting.json"
if [ -f "$VL" ]; then step "baked prop light"; ue apply_baked_props.py "BAKED_PROPS" || exit 1
else echo; echo "== baked prop light SKIPPED: no vertex lighting export for $MAP (props keep their lit materials)"; fi
step "live exposure";               ue setup_live_postprocess.py "LIVE_PP" || exit 1
echo; echo "$MAP ready: /Game/BioShockLive/${MAP}_Baked -- play.sh follows the game onto it automatically"
