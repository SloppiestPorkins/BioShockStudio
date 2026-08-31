---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C1 of `docs/FULL_GAME_CONVERSION.md`: turn the per-class `Cast<>` dispatch in
`UShockScriptRunner` into a polymorphic action model, so adding a leaf action no longer touches
the runner. This is the refactor that makes the remaining ~115 unimplemented actions cheap.

## Current state (read this first)
- `UShockAction` base (`ShockAction.h`) is just `ActionClassName` + `Parameters` map — no virtual.
- 82 of 199 `ShockAction*.cpp` have an ad-hoc `ApplyInWorld(UWorld*)` (or `RequestX` +
  `ApplyInWorld`) with no common signature.
- `UShockScriptRunner::ExecuteAction` (`ShockScriptRunner.cpp` ~line 452+) is a ~50-branch
  `if (UShockActionX* X = Cast<UShockActionX>(Action)) { ... }` chain. Flow-control actions
  (Wait / If / Loop / For / ExitScript / ExitLoop / ExecuteScript / SendTriggerMessage /
  VariableAssign / VariableIncrement / VariableDecrement) manipulate the runner's own queue and
  variable scope — those stay special-cased. Every other branch just calls
  `X->ApplyInWorld(World)` (sometimes after a `RequestX()`).

## Do
1. **`FShockActionContext`** (struct, in `ShockAction.h` or its own header): `UWorld* World`,
   `AActor* OwnerActor` (the runner's outer actor), `UShockVariableScope* Variables`,
   `AActor* Instigator`, `FName SourceLabel`. Built once per `ExecuteAction` call.
2. **`UShockAction` gains a virtual**:
   `virtual bool ApplyInWorld(const FShockActionContext& Ctx) { return false; }`
   — `false` = not implemented / no-op (the honest default for the ~115 stubs).
3. **Migrate the 82 existing `ApplyInWorld`** to `override` the virtual. Mechanical:
   - signature → `bool ApplyInWorld(const FShockActionContext& Ctx) override;`
   - inside, `World` → `Ctx.World`, `GetOuter()`-actor fishing → `Ctx.OwnerActor`, instigator →
     `Ctx.Instigator`. Return `true` when it did something, `false` when it couldn't
     (missing target etc.).
   - Where an action currently has `RequestX()` + `ApplyInWorld()`, keep `RequestX()` (tests use
     it) and have `ApplyInWorld` call it.
4. **`UShockScriptRunner::ExecuteAction`**: keep the flow-control branches; delete every leaf
   `Cast<>` branch and replace the lot with one
   `bool bApplied = Action->ApplyInWorld(Ctx);` + the existing per-action logging
   (`BIOSHOCK_ACTION <class> applied=<0/1>`). Keep `UShockActionHideOrShowActor` etc. working —
   they just become overrides now.
5. Adding a leaf action from here = write its `ApplyInWorld` override, nothing in the runner.
   Note that in `ShockAction.h`'s class comment and in `docs/FULL_GAME_CONVERSION.md` C1.
6. `run_script_action_vm.py` / `verify_script_action_vm.py`: headless — a script with a mix of
   implemented + unimplemented + flow-control actions runs to completion; implemented ones take
   effect; unimplemented ones no-op and log `applied=0` (not crash); Wait/If/Loop still work.
   `Success - N error(s)`.

## Constraints
- `tools/ue5/**` + one `FULL_GAME_CONVERSION.md` C1 line. No `src/**`, `tests/**`. No commit/push.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile** — 82 files change, a typo in one
  fails the build; fix it before finishing.
- Do NOT change what any action *does*, the damage/combat/weapon/HUD systems, or the
  flow-control semantics. This is dispatch plumbing only.
- Keep every existing `run_script_*` / `verify_script_*` passing — the migrated actions must
  behave identically.
- If the 82-file migration is too much for one pass, do the **runner + base + the ~25
  highest-census actions**, leave the rest on their current ad-hoc `ApplyInWorld` (the runner
  can call both during transition), and record what's left. A partial that compiles and keeps
  every verify green beats a broken whole.
- `docs/ENGINEERING_RULES.md`: smallest correct change per file, verify each claim.
