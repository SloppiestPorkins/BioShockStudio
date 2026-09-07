# 1-Medical level-entry scripted sequence

Confidence labels follow `doors.md`.

## Dispatch model

**CONFIRMED_RUNTIME.** After world begin play, `UShockScriptSubsystem` waits one tick so saved
`AShockScript` actors can re-register with the world's registry. It then dispatches level-entry
messages for `1-Medical` and the global `All`/`all` labels. A runner starts when its
`scriptMessageClass` and `TriggeredBy` match the dispatched message.

This is fan-out, not one global cutscene queue. Scripts triggered by the same level-entry message
may run concurrently. Their relative cross-script order must not be used as synchronization.
Action order inside one script is authoritative.

`Present_LevelStartedCheck` (`TriggeredBy=All`), applicable training scripts, bathysphere-station
scripts, and `LoadRoomDoor` can consequently begin in the same level-entry wave. There is no
decoded execute-script or trigger dependency from `LoadRoomDoor` to bathysphere docking.

## The load-room beat

**CONFIRMED_BYTES.** Script `Script56`, label `LoadRoomDoor`, has
`TriggeredBy="1-Medical"` and exactly three actor-owned actions in this order:

1. `ActionWait322`: `Seconds=0.5`.
2. `ActionPlayAnimation25`: target `MedicalLoadRoomDoor`, animation
   `LoadRoomDoor_OPEN`, `bWaitForCompletion=true`.
3. `ActionPlayAnimation18`: target `MedicalLoadRoomDoor`, animation
   `LoadRoomDoor_OPENED`.

Therefore the intended timeline is:

```text
world begin
  -> deferred level-entry dispatch
  -> wait 0.5 s
  -> play six-second OPEN transition (lever, then panel slide)
  -> wait for OPEN to finish
  -> play OPENED hold
```

The initial half-second is the only prerequisite encoded in this script. The door does not wait
for a nearby trigger volume, a bathysphere callback, or `Present_LevelStartedCheck`.

## Completion semantics

`bWaitForCompletion` belongs to `ActionPlayAnimation`, not to the following action. Applying the
action starts its effect once; the runner then retains it as `PendingAnimation` and ticks child
runners while polling completion. It must not re-apply the action each frame.

For `AShockDoor`, completion is semantic:

- an `OPEN` transition completes at `IsFullyOpen()`;
- a `CLOSE` transition completes at `IsFullyClosed()`;
- hold clips (`OPENED`, `CLOSED`) are not confused with transitions by substring matching.

Only after the pending transition completes does the runner increment `ActionsCompleted` and
advance to `_OPENED`. This avoids the former collapse where `_OPENED` was applied in the same tick
as `_OPEN`.

**CONFIRMED_RUNTIME.** `verify_script_doors.py` exercises `LoadRoomDoor_OPEN` followed by
`LoadRoomDoor_OPENED` with waiting enabled. It verifies that the second action does not run early,
then advances time and requires: two actions completed, runner stopped, door fully open, and
blocking collision disabled.

## Import requirements

`import_scripts.py` must copy the decoded `bWaitForCompletion` property onto
`UShockActionPlayAnimation`; omitting it silently changes sequence timing. Actions remain outered
to their runner so they survive map save/load.

`import_slice_doors.py` runs before script import. It provides the label-addressable
`MedicalLoadRoomDoor`, exact source-door replacement, attachment leaves, and trigger relays.
`import_slice_scripts.py` then saves the scripts that target those labels.

## Ordering limits

**CONFIRMED_BYTES.** The three load-room actions and their properties are exact export data.

**CONFIRMED_RUNTIME.** Their local ordering and wait behavior are deterministic.

**UNKNOWN.** A total ordering among every script in the initial `1-Medical`/`All` fan-out is not
present in the decoded data and should not be invented. If a later beat needs cross-script
synchronization, it must use an explicit message, fact, action wait, or execute-script edge.
