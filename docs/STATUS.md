Supersedes docs/archive/HANDOFF.md, docs/archive/NEXT_SESSION.md, docs/archive/AUDIT_2026-09-06.md.

# Status — as of 28 Sept 2026

For the forward plan (systems, priority order, what's still unbuilt), see **[`docs/ROADMAP.md`](ROADMAP.md)**.
This file is the current-state snapshot: what's done and verified, what's landed but not yet
confirmed by the user in a live PIE session, what's an open bug, and what's a known-missing feature.
Where a claim below could not be confirmed against the repository (commits, task files, source), it
says **STATUS UNCLEAR — verify** rather than guessing.

## Most recent landed work (28 Sept 2026)

The most recent commits, newest first: `w20` (watchers, critical/immediate execution flush,
`TestFact`, training-message HUD, `d9e8830`), `z1` (Medical's 19 per-instance water materials,
`ffa4f5a`/`b8b6777`), `w19` (interact-trace pipeline bugs fixed + real aim-point root-cause fix,
46→36 failures, `5b6eb43`), a light-shape/rotation fix and a same-day regression fix for it
(`977f7c4`, `a7f2b41`, `8705199`), the w18 live-PIE-bug fixes (`12e8b9c`), the B12 Vita-Chamber
default fix (`a247c4c`), and the y5–y8 scripting-fidelity SDK-audit batch (`957ed72` … `fa3332b`,
25–27 Sept 2026). All are described in their own sections below.

## Active work

Nothing in flight as of this writing (28 Sept 2026, after `w20` landed) — see `docs/ROADMAP.md`
"Priority order" for what's next. If picking up new work, update this section rather than trusting
an old claim table.

---

## Done and verified

**Verified** here means: a headless verify script passed, and — for anything visual — a human looked
at it running in PIE or a capture. Where only the headless half is confirmed, it says so.

- **Asset/decode pipeline** (the C# tool): essentially complete. See `docs/QUALITY.md` for the
  current sweep figures; not re-summarized here, per `docs/ROADMAP.md`'s "Asset & decode pipeline".
- **All 21 story maps imported** into `/Game/BioShockLevel/*`, geometry/materials/UVs/collision
  correct, lighting mapped. Spot-checked visually on several maps (3-Arcadia, 6-Slums, 1-Welcome).
- **`1-Medical` playable slice** (`/Game/BioShockSlice/1-Medical`): boots menu → possess → HUD →
  weapons → plasmids → AI encounter → pickups → vendors → death/Vita-Chamber respawn. This is the
  main target for live PIE testing; the open bug list below is entirely against this slice.
- **All seven weapons + Research Camera**, ammo-type switching, holster slots — headless-verified;
  human-confirmed in the 6 Sept audit for wrench and shotgun specifically (see "Weapon viewmodels"
  below for the live caveat).
- **Six plasmids** (Electro Bolt, Incinerate, Telekinesis, Winter Blast, Insect Swarm, Enrage) —
  headless-verified (`verify_plasmid.py`, 44 checks).
- **Hacking, security devices, the hacking minigame** — headless-verified (`verify_security.py`,
  `verify_hacking_minigame.py`).
- **AI**: goal/ability brain, combat loop, navigation, hit reactions, archetype-driven spawning — all
  headless-verified (`verify_ai_combat.py`, `verify_ai_nav.py`, `verify_hit_reaction.py`,
  `verify_ai_archetypes.py`, `verify_ai_brain.py`).
- **Scripting VM**: the y5–y8 SDK-audit batch (message senders, `messageFilter`, `Global_`
  variables, per-runner timers, nested boolean/arithmetic statements, door multi-match,
  `ScriptableMover` open/close messages) all landed with headless verifies
  (`verify_scripting_fidelity.py`, `verify_scripting_movers.py`) — **not yet re-confirmed live in
  PIE** beyond what the w18 pass touched.
- **Runtime audio**: weapon fire, footsteps, looping ambient sound with distance falloff and a
  dedicated Ambient sound-mix class. Landed 8 Sept 2026 (`8b29ac8`, `5f4e14e`) and refined 28 Sept
  2026 (`1ff4b04`, fixing ambient water blaring from 40 m everywhere). **This directly contradicts a
  stale note in `docs/ENGINEERING_RULES.md` §60** claiming runtime audio is "a separate, untouched
  gap" — see "Contradictions" below.
- **UI**: every screen (HUD, radial, full select, status/pause, all five station UIs, hacking
  minigame widget, main menu/frontend) recreated in UMG with the game's own decoded art. Headless
  verifies all green; visual likeness confirmed close-to-1:1 for HUD, main menu, and pause menu in
  the 6 Sept audit capture pass (`hud_hud.png`, etc.) — the other screens are headless-verified only,
  visual correctness not separately re-confirmed since.
- **Lighting**: light shape/rotation import (spot vs. sun/directional vs. point, from the authored
  `effect` byte) landed 28 Sept 2026 (`1b4d2db`), including a same-day fix for a regression it
  introduced (multiple scene-wide `DirectionalLight`s spawning, `977f7c4`) and a false-pass in the
  light-effect-drives-animation verify (`8705199`, `a7f2b41`).
- **Vita-Chambers**: fixed 28 Sept 2026 (`a247c4c`) to start inactive until the player approaches —
  previously both Medical chambers were usable from spawn with no player action, because `bActive`
  defaulted true and was force-set again by the importer.

## Landed but not yet PIE-confirmed by the user

Everything in this section has a green headless verify but has **not** had a human look at it running
in the actual editor/PIE session since it landed. Per this project's own standing rule ("a numeric
check cannot see a wrong quantity that is still present" — `docs/archive/NEXT_SESSION.md`), treat
these as provisional until someone plays them:

- The y5–y8 scripting-fidelity fixes (message fields, timers, movers, nested statements) — headless
  only.
- The 28 Sept light-shape/rotation import — headless only; the regression it introduced and its
  fix were both also caught and re-verified headlessly, not by a human looking at the result in PIE.
- The w18 fixes below **were** re-verified against the real Medical slice by the landing session
  (not just the sandboxed worker pass) — see the w18 entry for what was actually re-checked and what
  wasn't.

## Open bugs — the live PIE bug list

The user played the `1-Medical` slice live on 28 Sept 2026 and reported three groups of problems.
Cursor's investigation is `docs/research/w18-pie-regressions.md`; the fix commit is `12e8b9c`.

| Bug | Status | Detail |
|---|---|---|
| Gun impacts not registering on walls | **Fixed** | Root cause: Grenade Launcher / Crossbow projectiles never called into the impact-FX path at all (`AShockProjectile::Detonate`). Re-verified against the real slice, not just the sandboxed pass — the original verify script itself was checking the wrong return value and always failed; fixed and all 6 weapons now genuinely pass. |
| Ragdolls not activating | **Fixed** | `StartRagdoll` now re-pulls the physics asset from the skeletal mesh instead of trusting a possibly-stale component pointer. |
| Nothing interactable | **Mostly fixed, 36 interact-trace failures remain (was 46)** | Root cause 1 (fixed): pickup collision ignored `ECC_Visibility` on every channel except a Pawn overlap, so the interact trace (which uses `ECC_Visibility`) could never hit a pickup. Fixed for newly-spawned actors; the 147 already-placed pickups in the live slice were destroyed and respawned to pick up the fix. Root cause 2 (w19, fixed): the verify harness's `FaceActor` aimed at a flat `actor location + (0,0,40)` point regardless of the target's actual collision size — for a pickup sitting flush under a shelf (e.g. `ShockConsumablePickup_12`, sphere center Z=8095, sphere top Z=8143, shelf underside Z=8142.5) that fixed offset landed within a few uu of the shelf's own collision, so the trace sometimes clipped the shelf instead depending on stand angle. Switched to `GetActorBounds(true)`'s collision-only origin (the true center of whatever collision volume blocks the trace) — 46 → 36 failures, confirmed by a real headless re-run, not guessed. **Still failing (36, unchanged after a w21 attempt): 20 `wrong_mesh_or_blocker`, 9 `no_hit`, 7 `wrong_interactable`** (stacked loot — confirmed cause, first-hit-wins is a deliberate behaviour not changed). w21 measured real per-case collision overlap for all 29 in-scope cases and tried a single-axis placement nudge on the 3 with a genuine flush overlap (8.5uu, 3.3uu, 2.1uu) — the nudge didn't close the gap (moving `ShockConsumablePickup_12` traded one flush graze for a different one; the other two just made `FaceActor`'s multi-candidate ring probe pick a different stand point, still blocked) and was reverted rather than left as an unvalidated position drift. Real finding: the interact-trace failure and the measured collision overlap are not as tightly coupled as they looked — `FaceActor`'s ring probe is sensitive enough to uu-scale position changes that fixing the geometry doesn't reliably fix the trace outcome. See `docs/research/w19-remaining-interact-fails.md` and `docs/research/w21-interact-trace-placement-nudge.md`. Next real attempt needs either a placement search that checks clearance against *all* nearby geometry (not just the one reported blocker) or a `FaceActor` strategy that isn't ring-probe-sensitive — both bigger than either task's scope so far. |
| Wrench viewmodel position | **No regression found — needs a live screenshot to confirm, not a code question** | `docs/archive/AUDIT_2026-09-06.md` (6 Sept) recorded the wrench viewmodel as fixed (`35f459c`, held by the handle, head up-forward); the same day `d479fbe` moved that correction onto the hands-rig socket via the manifest and removed the now-redundant component-level hack. Later viewmodel commits (`d256b09`, `41c0e1a`) and w18 (`12e8b9c`) never touched socket/wrench orientation code. No later commit undoes the manifest socket rotation. If it still looks wrong live, it's a fresh capture needed against the current socketed mesh (headless attach verifies can't see grip orientation), not a known bug to fix blind. |
| Bathysphere room water/stairs | **STATUS UNCLEAR — verify** | No tracked doc describes this specific room or bug. Medical does contain a bathysphere pavilion with `FX_StairWater_C` instances and nearby `FluidVolume`/`CascadingWaterVolume` actors (see `docs/research/w19-remaining-interact-fails.md` §3 for the actor census), and `FX_StairWater` is deliberately kept non-colliding by `restore_floor_prop_hulls.py` (matched the `_FLOOR` regex) — a known prior fix for a different problem, not evidence this room's complaint is fixed. Still unknown without a live screenshot: whether the complaint is water material look, a colliding water sheet, a missing walkable stair hull, or something else near the airlock. |
| FisheriesAccordian locked-gate question | **Resolved — the gate is real and correctly gated, just not on the flag first suspected** | `AccordianGateDoor1` (`FisheriesAccordian`) unlocks via `ActionUnlockDoor18`/`ActionOpenDoor6` on Script label `quarswitched`, gated by `ActionIf929` testing `BooleanStatement61`: an **inventory item-count check** (`Get Number of Items in Inventory == 1`, quarantine-key style), not a global flag. `Global_Med_OpenedMedicalGate` is a real flag but is only ever read once (a quest-hint on label `NeedSteinmansKey`) and never assigned anywhere in the exported script data — it does not gate this door. See `docs/research/w19-remaining-interact-fails.md` §4 for the full trace. |

## Known-missing features

Systems that don't exist yet, not content gaps within an existing system (see `docs/ROADMAP.md` for
the per-system detail and priority order — this is a summary, not a repeat of every line):

- **Tonics** — no system at all; Gene Bank UI is plasmids-only.
- **Switches / levers** — no dedicated actor class.
- **Quest hints/content** — the state machine itself is real and live (`AShockPlayer`, see
  `docs/ROADMAP.md`'s "Inventory, economy, and player systems" for the corrected description,
  28 Sept 2026); what's actually missing is quest hint/objective text beyond a bare name, and
  nothing in script import yet calls `InitiateQuest` from real Medical script data.
- **U-Invent crafting** — runs against generic inventory stacks, no component bag or recipes.
- **Weapon/plasmid icon art** — never located in any decoded SWF; UI shows name + brass ring only.
- **Level-to-level travel at scale** — the mechanism works, proven on one synthetic test map only;
  the real 21-map bathysphere graph is unbuilt.
- **Scripted cinematic sequences** — the Medical set-pieces (doctor-killer intro, Steinman surgery,
  first Big Daddy sighting) are unbuilt; the data exists in the decoded scripts.
- **Gatherer/Protector ecology** — Little Sister harvest, Big Daddy AI, the ADAM choice. Explicitly
  its own later project.
- **Glass, god rays** — decal/particle stand-ins exist for some effects; glass/god-rays are not yet
  real UE5 material work. Water is done (`z1`, 28 Sept 2026) — Medical's 19 `FluidShader` surfaces
  now carry their own decoded textures/pan values, not one generic stand-in.
- **Watchers, critical/immediate script execution mode, `TestFact`, training-message HUD** — all
  landed 28 Sept 2026 (`w20`). Still open: `ActionEnableOrDisableTrainingMessages` (a global mute
  gate, out of `w20`'s scope) and nested-loop critical-sub-action expansion during a travel flush
  (the flush walks the flat remaining run queue only).
- **Menu stubs** — Options, Credits, Director's Commentary, Museum, Challenge Rooms.
- **HUD liquid-fill material** (`M_Hud_LiquidFill`) — renders invisible, flat-tint fallback forced.
- **Audio diaries, music, per-language audio routing** — audio playback exists for weapons/footsteps/
  ambience; diaries and music are not wired.

## Never dispatched (queued in an old plan, superseded, not completed under that name)

`docs/archive/FULL_GAME_CONVERSION.md`'s task queue named `x1`–`x12`. Only `x1`, `x3`, `x5`, `x6`,
`x7` were ever created and landed (prop-mesh import, VM param resolution, actions reflection,
actions visibility/AI/items, the EffectsSystem subsystem). **`x2`, `x4`, `x8`, `x9`, `x10`, `x11`,
`x12` were never dispatched under those names** (confirmed: no `tools/agents/tasks/x2*` etc. file and
no "queue x2" commit exists). Their underlying goals were partially reached by later, differently-named
work:

- `x2` (material-slot fixes) — substantially covered by the later `g4`/`h9`/`d`-series texture work.
- `x4` (VM watchers/timers) — timers landed (`y6`); watchers landed (`w20`, 28 Sept 2026).
- `x8` (effects stand-in FX pack) — partially covered by `w15` (impact FX) and `w9` (plasmid VFX);
  not confirmed as a complete stand-in pack.
- `x9` (skeletal-prop idle animation) — **STATUS UNCLEAR — verify**, no evidence found either way.
- `x10` (latent AI actions / cinematic sequences) — **not done**; see "Scripted sequences /
  cinematic AI" in `docs/ROADMAP.md`.
- `x11` (security goals) — substantially covered: `AShockSecurityBot`/`AShockSecurityCamera`/
  `UShockSecuritySubsystem` all landed under different task names. Patrol/protect/return-home goal
  paths for bots are still open.
- `x12` (Gatherer ecology) — **not started**, confirmed as its own later project.

## Contradictions found between the old docs (flag to the user)

1. **Runtime audio.** `docs/ENGINEERING_RULES.md` §60 "Audio — current standing state" says (dated
   "noted 6 Sept 2026"): *"Runtime audio is a separate, untouched gap... do not start wiring runtime
   audio unless the user asks."* This was already false two days later: `w1-runtime-audio` landed
   8 Sept 2026 (`8b29ac8`, weapon fire/footsteps/ambience/vocals) and was refined again 28 Sept 2026
   (`1ff4b04`). **This is stale status embedded in a rules document** — flagged per the consolidation
   task's instructions rather than silently edited, since `ENGINEERING_RULES.md` itself was out of
   scope for this pass.
2. **The `1-Medical` "unsupported" actor count.** `docs/archive/UE5_FULL_PORT_PLAN.md` and
   `docs/archive/ROADMAP.md` both quote 7,337 unsupported actors on `1-Medical` in several places;
   `docs/archive/UE5_FULL_PORT_PLAN.md` §9 itself later corrects this to 2,018, identifying the
   7,337 figure as a double-counting bug in `import_level.py` present since the importer was first
   written. Both documents keep the wrong 7,337 figure in earlier sections after the correction is
   recorded later in the same document — not fixed retroactively in the old docs (they are now
   archived unmodified). Use 2,018 as the correct historical figure if it comes up.
3. **Cursor-lane task-list currency.** `docs/archive/DUAL_AGENT_ROADMAP.md` says its own "Cursor
   lane" work-item list is a stale 28 Aug snapshot not re-derived against
   `docs/archive/FULL_GAME_CONVERSION.md`'s Phase A/B/C/D structure, and to treat it as historical
   framing rather than a live queue. It was left in the document rather than removed. No action
   needed — already self-flagged in the source, noted here only for completeness.
4. **`docs/archive/HANDOFF.md` §6.0c vs. `docs/archive/ROADMAP.md` Gate 2 item 1** both describe the
   54-track bone-collapse animation family and reach the same conclusion (blocked on missing Havok SDK
   function bodies, declined on licence grounds) — not a contradiction, but the same investigation is
   fully duplicated across two files. Read either; they agree.

## Where the process/rules docs are accurate vs. stale

Per this consolidation task's scope, `docs/ENGINEERING_RULES.md`, `docs/QUALITY.md`,
`docs/EFFICIENCY_RULES.md` and `docs/GUI.md` were read but not modified or merged — they are process
docs, not status docs. One stale-status-in-a-rule was found and is recorded above (runtime audio).
No other embedded status claims were found to be contradicted by current repository state in the
sections reviewed; `docs/QUALITY.md` in particular is an evidence/measurement record (pinned by
`DocumentedFiguresTests`) and is explicitly treated elsewhere as authoritative over prose status docs
— that role is unchanged by this consolidation.
