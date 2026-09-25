# Global_ script variables — implementation note (SCR-B03 / SCR-G06 / SCR-G18)

**Re-verified before change:** `grep -ri global_ tools/ue5/BioShockRuntime/Source` was empty;
each `UShockScriptRunner` owned a private `UShockVariableScope`. Medical’s `Global_*` flags
(cross-script story state) could not be seen by other runners. Confirmed.

## What landed

| Piece | Where |
| --- | --- |
| Shared store on game instance | `UShockGameInstance::GlobalVariables` + `EnsureGlobalVariables()` |
| Process fallback (headless) | `UShockVariableScope::GetOrCreateFallbackGlobals` via `TStrongObjectPtr` |
| Transparent routing | `UShockVariableScope` Contains/TryGet/GetValueOrEmpty/Set/Find |
| Cross-script local read | `ScriptLabel.varname` via bound `UShockScriptRegistry` (assign refused) |
| Temp cleanup | `StartExecution` already clears return values; Finish wipe skipped (verify reads) |
| Verify | `tools/ue5/verify_global_variables.py` |
| Docs | `docs/research/script-vm.md` § Global_ variables |

## Save/load (follow-up, not invented here)

`UShockSaveGame` / `ShockSaveLoadMenu` persist carry state, inventory, difficulty, level path.
They do **not** yet persist script variables. Globals survive map travel with the game instance
but are lost on process quit / slot load until a save field is added deliberately.

## SCR-G18 (temps)

Checked: return values sit on action objects; `StartExecution` already clears them before a new
run. Clearing in `FinishExecution` would break `verify_import_scripts.py` (reads returns after
finish). No scope/Global leak. Left as-is with a note in `script-vm.md`.
