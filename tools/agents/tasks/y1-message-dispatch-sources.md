---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**
---

# R1.3 follow-up — real message senders (MessagePawnDied first)

> **Run mode:** non-interactive, sandboxed — do NOT launch Unreal, do NOT run the UE build, do NOT
> touch `C:\Users\Jack\Documents\BioShockUE5` (the shared live project). Claude builds and runs the
> headless verify afterwards. Do NOT commit. Deliver the diff + a short RESULT note.

## Why

`UShockScriptRunner::TryStartFromMessage` now requires the script's `scriptMessageClass` to match
the dispatched class (`MatchesMessageClass`; `NAME_None` and `"Message"` are wildcards) — commit
`b2a82c8`, read `docs/research/message-class-gap.md` first. The runtime only *sends* three
classes today (`MessageLevelStarted` from `UShockScriptSubsystem::DispatchLevelEntryMessages`,
`MessageTriggerVolumeEnter` from `UShockTriggerRelayComponent::DispatchNow`, `Message` from
`ShockActionSendTriggerMessage`). So every Medical script waiting on another class is now inert.
This task adds the missing senders.

Dispatch API: `UShockScriptSubsystem::Get(World)->DispatchMessage(FName MessageClass, const
FString& SourceLabel)`. `MatchesTriggeredBy` is case-insensitive and comma-list aware.

## Medical demand (counts of scripts, from the level export — re-verify by grepping, don't trust)

| Class | Scripts | TriggeredBy seen |
|---|---|---|
| `MessagePawnDied` | 21 | AI labels (`Steinman`, `SurgeryAmbusher1`, `IncinerationAIOne`…) and one `all` |
| `MessageRAReacted` | 19 | switch / grate / blockage labels (`MedicalHallwaySwitch`, `SupplyClosetGrate`, `IceBlockage`, `ScriptedOilSlick1, ScriptedOilSlick2`…) |
| `MessageReceivedInventory` | 8 | `player` / `Player` |
| `MessageAIWeaponFired` | 5 | AI labels (`SteinmanGrenadier`, `StunTurret`…) |
| `MessagePawnTookDamage` | 5 | AI labels |

## Build, in this order (stop and report if one turns out not to fit)

1. **`MessagePawnDied`.** One central hook: `ShockDamageLibrary.cpp` sets `Pawn->bIsDead = true`
   then calls `Pawn->OnDeathFromDamage()` (~line 158). Dispatch `MessagePawnDied` with source =
   the pawn's script label (`ABaseShockAI::ScriptLabel`, else editor label — reuse the same label
   resolution `UShockPhysicsLibrary::FindActorByLabel` / `ABaseShockAI::CollectLabeled` use, and
   for the player the label `Player`), and ALSO with source `all` (scripts author
   `TriggeredBy="all"` for "any pawn"; `DispatchLevelEntryMessages` already dispatches both
   `All` and `all` — match that). Fire exactly once per death (guard against re-entry: check the
   pre-existing `bIsDead` before setting). Do it in the library, not per pawn subclass.
2. **`MessagePawnTookDamage`** — same library, on applied damage > 0 to a living pawn; same
   two-source pattern. Must not fire on the killing blow twice in a confusing order: PawnTookDamage
   first, then PawnDied.
3. **`MessageReceivedInventory`** — where `AShockPlayer` adds an item/stack to inventory
   (`AddStackToInventory` and money/ADAM equivalents if they exist): dispatch with source
   `Player` (also `player`; matching is case-insensitive so one dispatch suffices — verify).
   Must not fire for the initial loadout / save-restore paths; look for how those are separated and
   say so if there is no clean separation.
4. **`MessageAIWeaponFired`** — `ABaseShockAI` ranged-fire path and `AShockTurret`; source = the
   shooter's script label.
5. **`MessageRAReacted`** — the player Interact/use path on switches, grates and blockages
   (`TickInteractionTrace`, `AShockPlayer::Interact*`, `AShockDoor` buttons, `AShockAnimatedProp`,
   the wrench-break path, plasmid-hit path for `IceBlockage`/`ScriptedOilSlick`). Source = the
   reacted-with actor's label. Audit which actors carrying those Medical labels are which UE
   classes before touching anything; if a label maps to a plain static mesh with no interaction
   path, document it as unresolved rather than inventing a component.

Also worth doing if cheap: `UShockTriggerRelayComponent` for TriggerRadius actors should send
`MessageTriggerEnter`, and a volume/radius exit should send `MessageTriggerVolumeExit` /
`MessageTriggerExit` (4 + 4 Medical scripts). Check how the importer decides relay vs not
(`tools/ue5/import_level.py::_ensure_trigger_relay`) and what actor class a TriggerRadius becomes.

## Known gap you must NOT paper over

`messageFilter` (21% of scripts) is not implemented: a script with `TriggeredBy="all"` and a
filter such as `PawnClass=SpawnedMeleeThug` will fire for EVERY death. Do not fake filtering.
Say in `docs/research/message-class-gap.md` (update the "Still open" list) exactly which senders
now exist, and note the over-fire risk for `all`-sourced dispatches.

## Constraints

- `tools/ue5/**` + `docs/research/**` only. Additive; smallest hook in each place.
- Follow the repo's conventions: every new sender gets a logged `BIOSHOCK_MSG class=%s src=%s
  accepted=%d` line (`LogTemp, Display`) so it is greppable in PIE.
- Don't regress: `verify_script_trigger.py`, `verify_script_runner.py`, `verify_script_doors.py`,
  `verify_script_movement.py`, `verify_security.py`, `verify_hacking.py`.

## Deliverable

- The senders above.
- `tools/ue5/verify_message_senders.py` (headless, `-run=pythonscript` compatible, no sibling
  imports; see `verify_action_batch_r22.py` / `verify_reflection_actions.py` for the house style:
  `unreal.EditorLevelLibrary.get_editor_world()`, spawn throwaway actors, JSON report +
  `unreal.log("Success - ...")`). For each sender: spawn a `ShockScript` (`configure(label,
  triggered_by)`, `set_script_message_class("MessagePawnDied")`, one `ActionVariableAssignOverwrite`
  action), trigger the real gameplay event (apply lethal damage to a `BaseShockAI` etc.), tick
  the script, assert it fired — and assert a script with a DIFFERENT class on the same label did
  NOT. Use `unreal.get_editor_subsystem(unreal.EditorActorSubsystem)` /
  `spawn_actor_from_class(cls, loc, rot)` as the other verifies do. The runner API is
  `runner.ensure_variables().get_value_or_empty(name)`; `actor.tick_script(0.0)`.
- Updated `docs/research/message-class-gap.md`.
