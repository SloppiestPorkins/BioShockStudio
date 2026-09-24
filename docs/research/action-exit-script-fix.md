# `ActionExitScript` ignored its own `TargetScript` field

Found during the same guide cross-reference pass as `message-class-gap.md`.

`UnrealScript ActionExitScript`: "end execution of `TargetScript` (a different script, looked up
by label via the registry), or the currently-executing script when `TargetScript` is empty" —
per `22-Scripting-Action-Reference.md` and the worked example in `23-Scripting-Examples.md`
(Example 13, Cohen's masterpiece): `CohenDies` (`MessagePawnDied` from `Cohen`) calls
`ActionExitScript targetScript=CohenEntrance` to abort the unrelated, still-in-flight cinematic
script `CohenEntrance` when the player kills Cohen mid-sequence.

`ShockScriptRunner::StepOne`'s handling of `ActionExitScript` always called
`FinishExecution()` on `this` (the runner currently executing the action) and never looked at
`Exit->TargetScript` at all. A cross-script abort like `CohenDies` would have silently exited the
*caller* (`CohenDies`, a one-row script that was about to finish anyway) instead of the intended
*target* (`CohenEntrance`, which would have kept running to completion regardless of the death).

Fixed: `Exit->TargetScript` empty, or equal to the runner's own `ScriptLabel` (a direct compare,
no registry needed — robust even for a runner with no registry set), resolves to `this`. Any
other value is looked up via `Registry->FindScript(...)`, matching the existing
`ActionExecuteScript` lookup pattern. A target that isn't found is a clean no-op (the action
still completes; nothing crashes or hangs), matching `RequestExit()`'s own doc comment ("still
succeeds").

## Verify

`verify_script_runner.py` gained a `cross_script_exit` case: two runners share one registry,
`CallerScript` runs `ActionExitScript targetScript=VictimScript` while `VictimScript` is
mid-`ActionWait`; asserts the victim stops immediately (never reaches its post-wait action) while
the caller continues its own remaining actions normally. The pre-existing self-exit case (a
runner naming its own label) still passes unchanged. No regressions:
`verify_script_trigger.py`, `verify_script_doors.py`, `verify_script_movement.py`,
`verify_reflection_actions.py`, `verify_action_batch_r22.py`.
