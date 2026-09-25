---
worker: cursor
base: main
verify: git status --short
lane: docs/research/**
---

# y2-sdk-audit-scripting: SDK cross-reference audit — Chapters 20-23 (scripting basics, logic/variables, the full action reference, worked examples) and 37 (glossary)

> **Run mode:** non-interactive. This is a READ-AND-REPORT audit: change NO code. Do NOT launch
> Unreal, do NOT build, do NOT touch `C:\Users\Jack\Documents\BioShockUE5` (shared live project).
> Do NOT commit. Your only output is ONE new markdown file (named below) plus a short RESULT note.

## What this is

BioshockHavok is a UE5.7 port of BioShock 1 Remastered (repo = your worktree; runtime plugin in
`tools/ue5/BioShockRuntime/Source/BioShockRuntime/{Public,Private}`, importers/verifies in
`tools/ue5/*.py`, C# extractor in `src/BioShockStudio.Core` + `src/BioShockStudio.Cli`, research notes
in `docs/research/*.md`). The runtime was built from decompiled UnrealScript. A real BioShock SDK
guide (a 38-chapter document written by the SDK's users) is now available. It is ground truth for
how the original systems behave. Your job: **cross-reference the guide chapters listed below
against what we actually built, and find every place they disagree or that we never built.** In a
prior pass this method found real bugs (e.g. `ActionWaitForGoal` returning the wrong code for a
missing goal, `ActionExitScript` ignoring its target, a Health Station charging an invented
scaled price instead of a flat 16/10, hack failures able to kill the player, a security subsystem
that never ticked outside tests). Find more of that class: **silently wrong, not just missing.**

## Where the guide is (READ-ONLY, outside the repo)

`C:\Users\Jack\AppData\Local\Temp\claude\C--Users-Jack-Documents-AI-Test\c7be037f-fb45-4801-8732-1d5df17a8bb3\scratchpad\unrealed-guide-mirror` — one `NN-Title.md` per chapter. Read the chapters assigned to you IN FULL, not by grep.

## COPYRIGHT — hard rule

The guide has no licence and this repo is PUBLIC. **Never copy or closely paraphrase the guide's
prose into the repo.** Facts are fine (a field name, an enum value, a number, a return code, a
class relationship, "X happens when Y"); sentences are not. Write everything in your own words,
cite by chapter number + section heading only, and keep any quoted phrase under ~8 words. Do not
copy tables or ini listings.

## How to audit

For every mechanic/number/field/behaviour a chapter states, locate the implementing code (or
confirm none exists) and READ it. Do not assume; do not trust comments in our code or old docs
(`docs/research/*.md` are hypotheses — several were already wrong). Classify each item:

- **BUG** — we implemented it and behaviour contradicts the guide.
- **GAP** — the guide describes a mechanic/field we have not built or only partly built.
- **OK** — verified match (list briefly; proves you looked).
- **UNKNOWN** — cannot tell without running the game / data we don't have.

Already fixed this session (do NOT re-report): ActionSetProperty `enabled`/`Disabled` routing,
ActionWaitForGoal no-goal=0, ActionExitScript TargetScript, message-class names + `scriptMessageClass`
gating + real senders for PawnDied/TookDamage/ReceivedInventory/AIWeaponFired/trigger enter-exit,
security subsystem tick + 60 s alarm expiry, hack-failure non-lethal cap, Health Station 16/10.
Known open, don't re-report as new: `messageFilter` decoding, switch/grate interact paths,
LootTables.ini weighted rolls, spawn-manager/archetype system, EffectsSystemContext per-actor
semantics, ActionToggleAIReactions 7 of 9 switches, ActionSpawnAI missing fields, Gatherer ecology.

## Output

Write `docs/research/sdk-crossref-scripting.md` with:
1. A one-paragraph summary + counts (BUG / GAP / OK / UNKNOWN).
2. **BUG table first**, ordered by player-visible impact: `id | what the guide says (your words) |
   guide ref (chapter + heading) | our code (file:line) | what we do instead | proposed fix | effort S/M/L`.
3. GAP table, same columns (no "what we do instead").
4. OK list (one line each).
5. UNKNOWN list with what would resolve each.
Be specific and verifiable — every BUG needs a file:line a reviewer can open in seconds.

## Your chapters (read every one fully)

- `20-Scripting-Basics.md`
- `21-Scripting-Logic-and-Variables.md`
- `22-Scripting-Action-Reference.md`
- `23-Scripting-Examples.md`
- `37-Glossary.md`

## Where to look in our code

Our side: `tools/ue5/BioShockRuntime/.../ShockScriptRunner.*`, `ShockScriptRegistry.*`, `ShockScript*.*`, every `ShockAction*.h/.cpp` (~200; chapter 22 lists each action's fields, defaults, return values and whether it waits / uses first-match vs all-matches — check EACH action we implemented against its entry: field set, defaults, return contract, blocking behaviour, behaviour with an empty label), `ShockVariable*`, `ShockBoolean*`, `tools/ue5/import_scripts.py`, and `src/BioShockStudio.Cli/Program.cs` `ExportScriptActions`. Also check the chapter 20/21 machinery: message classes and the base-class wildcard, `TriggeredBy` lists, callee scripts and blocking/non-blocking execution, queueing of messages while a script runs, the `Global_` variable prefix (persistence across levels/saves), variable typing/comparison rules, timers and watchers, `bIsGameCritical`, `enabled` semantics, label matching rules (case-insensitivity, first-match vs all-match per action). Chapter 23's fourteen worked examples are effectively test cases: for each, say whether our runtime would produce the described behaviour.
