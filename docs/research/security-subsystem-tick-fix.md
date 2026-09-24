# `UShockSecuritySubsystem` was never ticked during real gameplay

Found during the same guide cross-reference pass as `message-class-gap.md` and
`action-exit-script-fix.md`.

`UShockSecuritySubsystem` (`UWorldSubsystem`) owns two time-based behaviors: despawning alarm
bots some seconds after the alarm clears (`TickBotDespawn`/`BotDespawnRemaining`), and — not
implemented before this — the alarm auto-expiring on its own after a fixed duration. Both need
something to call a `Tick`-style method with `DeltaSeconds` every frame.

**Nothing did, outside the headless verify harness.** `UWorldSubsystem` is not
`UTickableWorldSubsystem` — UE5 never calls `Tick` on it automatically. The only caller of the
bot-despawn timer anywhere in the codebase was `AdvanceSecurityForVerify`, a
`UFUNCTION(BlueprintCallable)` that only exists for `verify_security.py`'s Python-driven headless
tests to call explicitly. In an actual PIE session or the shipped game, that method is never
invoked by anything — the timer logic was correct, but dormant.

Confirmed against `31-Security.md`: "The alarm lasts 60 seconds." during a live alarm, the game
auto-clears it even if the player never reaches a Bot Shutdown Panel. That auto-expiry didn't
exist in the runtime at all before this session — there was no code path for it to hang off of.

## Fix

- `UShockSecuritySubsystem` gained `AlarmDurationSeconds` (60.0f, guide-confirmed) and
  `AlarmRemainingSeconds`/`AlarmPlayer` tracking: `OnAlarmStateChanged` starts the countdown when
  an alarm turns on and clears it when the alarm turns off (by any means — script, panel, or the
  new auto-expiry itself).
- The shared per-tick logic (`TickBotDespawn` + the new alarm countdown) was extracted into a
  private `AdvanceSecurity(DeltaSeconds)`, called by both the existing `AdvanceSecurityForVerify`
  (headless tests — also still separately drives each bot's own verify-only per-bot advance) and
  a new public `TickSecurity(DeltaSeconds)`.
- `TickSecurity` is called every frame from `AShockPlayer::Tick` — the player already owns the
  alarm's on/off flag (`bSecurityAlarmOn`) and already ticks reliably every frame, matching this
  codebase's established pattern of an owning actor driving its own subsystem work (the same
  shape as `AShockScript::Tick` driving `UShockScriptRunner`, or `AShockSecurityCamera::TickDevice`
  driving its own alert buildup) rather than making the subsystem self-tick.
- Deliberately did **not** convert `UShockSecuritySubsystem` to `UTickableWorldSubsystem` — that
  would be a bigger, less-consistent change (no other subsystem in this codebase self-ticks) for
  the same result the player-driven call already gives cleanly.

## Verify

`verify_security.py` gained `alarm_auto_expires`: sets a short 1-second
`AlarmDurationSeconds` for the test, starts an alarm with nothing ever explicitly stopping it,
confirms it's still on at 0.5s and off by 1.2s. The existing `alarm_clear_despawns_bot` case
(now routed through the same shared `AdvanceSecurity`) still passes unchanged. Full suite green:
`verify_security.py` (11/11), `verify_script_runner.py`, `verify_reflection_actions.py`,
`verify_action_batch_r22.py`, `run_verify_audio.py`.
