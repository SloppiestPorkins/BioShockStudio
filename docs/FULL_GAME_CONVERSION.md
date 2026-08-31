# Converting BioShock to UE5 in full — the plan from here

> Supersedes the "prove one slice first" framing of `UE5_FULL_PORT_PLAN.md` §5 Phase 0.
> That precondition is now **met**: `1-Medical` runs end to end in UE5 — menu → possess →
> a 3-enemy encounter that navigates, shoots, staggers and dies → HUD → player death →
> respawn (`play_slice.ps1`, verified 31 Aug 2026: `possess=ok fire=1 health 100→75
> failures=[]`). The integration problems the old plan feared have been found and paid for
> on the slice. **So the strategy now flips to breadth: convert the whole game mechanically,
> then fix it as we go.**
>
> `UE5_FULL_PORT_PLAN.md` stays the reference for *why* (the three-layer argument, the
> decompiler-defect asymmetry, the risks). This document is *what next and in what order*.

---

## 0. The shape of the problem, restated

Three layers, and where each one actually stands:

| Layer | What it is | State | Method |
|---|---|---|---|
| **A — Assets** | meshes, skeletons, animations, textures, materials, BSP, lights | **decode complete; import proven on every rig category; only `1-Medical` actually imported** | mechanical — run the pipeline at scale |
| **B — Data** | class schemas, `defaultproperties`, placed actors, zones, script graphs, AI archetypes | **exporters built; manifest v4 carries it; script-graph import proven on Medical only** | mechanical — run at scale, fix per-map gaps |
| **C — Behaviour** | function bodies, the 103 `ShockAI` states, weapons, plasmids, hacking, the ~186 `Action*` classes | **~23 actions execute; a first-slice combat/weapon/damage/HUD/death runtime exists; the state machines are untouched** | hand-written against the decompiled source, census-ordered |

Layers A and B are a **grind, not research** — the hard decode work is done (see
`docs/research/open-questions.md`: almost everything CLOSED). Layer C is the multi-year part.

**"Make the runtime work"** is Layer C, phases C1–C5 below. It is not a separate track.

Permanent cut lines (do not spend time here): Havok joint limits (licence-blocked), the
18 door meshes that don't decode, exact original damage/balance numbers where a
`defaultproperties` value isn't present. Audio is blocked *pending* the data-location
find, not permanently — see D4.

---

## Phase A — Convert every map and asset into a real UE5 project

Goal: **you can open the UE5 project and walk through all 21 Rapture maps**, lit, textured,
with the placed static/skeletal geometry, even before any of it is a "game".

### A1. Batch level conversion — all 21 maps ✅ scaffolded (4-map proof, 31 Aug 2026)

**Status:** `tools/ue5/import_all_levels.py` + `run_import_all_levels.py` landed. Proof run on
four maps into `/Game/BioShockLevel/<map>` (geometry-only rig policy: `BIOSHOCK_IMPORT_RIGS=none`;
character rigs deferred to A2). Report: `%TEMP%/bioshock_import_all_levels.json`.

| Map | Imported | Idempotent re-run | Created / updated / skipped / unsupported | Notes |
|---|---|---|---|---|
| `0-Lighthouse` | ✅ | ✅ (~0 s second pass) | 1,865 / 436 / 0 / 395 | Matches prior single-map proof (1,274 instances, 0 mesh skipped). Unsupported = gameplay/dec FX classes → tagged `TargetPoint`s. |
| `1-Medical` | ✅ | ✅ (~0 s second pass) | 8,075 / 1,132 / 0 / 2,910 | Slice map; unsupported dominated by `Script`, spawners, FX emitters, Havok constraint stubs. |
| `2-Fisheries` | ✅ | — | 11,354 / 0 / 0 / 4,011 | Largest proof map (~11 min export+import). Extra unsupported vs Medical: door classes (`FishFreezerDoor*`), Fisheries-specific spawners/annotations. |
| `7-BossFight` | ✅ | — | 1,699 / 0 / 0 / 490 | Set-piece map; smallest unsupported tail of the four. |

**Decode gaps (expected, not blockers):** every map's `unsupported_classes` list is the same shape
— `Script`, `*Spawner`, `Light` (authored lights become real `PointLight`s; duplicate actor rows
still count unsupported), FX `Emitter`s, `Brush` CSG placeholders, navigation markers, Havok
constraint actors. No map failed import; no mesh-instance skips on these four.

**Lighting stopgap:** `--lighting-stopgap` (default on) applies `ShockGameMode::EnableDynamicLighting`
equivalent — force-no-precomputed-lighting, movable static meshes, fill directional + sky tagged
`BioShockSliceFill`.

**Full 21-map run needs:** ~hours unattended (export + import per map, largest ~10–15 min each);
run with editor closed; keep `BIOSHOCK_IMPORT_RIGS=none` unless doing A2 in the same pass.
`BIOSHOCK_IMPORT_RIGS=all` currently crashes UE 5.7 on large animation imports (narrowing assert
in `ImportAssetTasks` — recorded, not fixed here). One map per UE invocation recommended so a
crash does not lose the batch report.

Original scope:
`export-level` + `import_level.py` already do one map. This phase:
- A `tools/ue5/import_all_levels.py` that runs the pipeline for every shipped map into the
  project, idempotently, and writes a per-map report (`created / updated / skipped /
  unsupported`, decode-gap classes).
- Fix per-map decode gaps as they surface — most maps will "just work" (`0-Lighthouse`
  already imported clean at 1,274 instances / 0 skipped); the ones that don't get a
  targeted fix, not a rewrite.
- Bake or import-time lighting so each map is not pitch black (see D1 for the fidelity
  version; here, "good enough to see").

### A2. Bulk rig / character / weapon import
967 skeletal meshes + 8,668 static + 16,031 animations is ~140 GB fully expanded — the
plan has always deferred that as a lump. Do it as **tiers**:
- Tier 1 (do now): every character archetype the 21 maps actually *spawn* (~40–60 rigs),
  every weapon, every placed prop class. This is a bounded set from the level manifests.
- Tier 2 (later / on demand): the long tail. A content-addressed cache so a re-run is cheap.

### A3. Level-to-level travel
BioShock is a sequence of maps joined by bathyspheres and load-triggers. `ActionChangeLevel`
exists as a stub (currently skiplisted as "dangerous"). This phase makes it real:
- `AShockBathysphere` / load-trigger actors from the placed-actor data.
- `UGameplayStatics::OpenLevel` travel with player-state carry-over (health, EVE, inventory,
  plasmids, ADAM, research).
- A "New Game" flow: menu → `Welcome` (the plane-crash intro) → `1-Medical` → … in order.

### A4. Own the export — a persistent project, not the throwaway
Today everything targets `C:\Users\Jack\Documents\BioShockUE5` (the throwaway). Phase A
produces a **checked-in project skeleton** (`.uproject`, `Config/`, the plugin) plus a
`bioshock-tool export-ue5-project <dir>` that populates a fresh one reproducibly. This is
the `UE5_FULL_PORT_PLAN.md` §9 "app-facing export workflow" that was deliberately deferred
until the CLI import reproduced cleanly — it now does.

**Phase A exit:** a `BioShockUE5` project that opens, lists 21 maps, and lets you fly the
editor camera through any of them with geometry, materials and placeholder lighting.

---

## Phase B — Complete the data layer across all 21 maps

Layer B is built for Medical; this scales it.

### B1. Script-graph import on the 20 non-Medical maps
`export-script-actions` already runs clean on all 21 (`docs/research/interaction.md` §8:
3,932 scripts, 21,752 refs, 0 skipped). `import_scripts.py` is proven on Medical only. Run
it per map, record `nested_unmapped` / `unmapped_classes`, fix the mapper gaps (the last
census pass found 4 — `OrStatement`, `Hide/ShowNeedleElement`, `TrainingCondition`, fixed
`bb3fb2d`; expect a handful more across 20 maps).

### B2. AI spawner config → live spawns
`LevelSpawnerActorDocument` (global/initial/repopulation AI types, patrols, `SpawnZones`,
`Complete` flag) is in the v4 manifest and pinned for Medical's 19 `AggressorSpawner`s. This
phase makes `AShockAISpawner` actors spawn from that data on every map, on the real spawn
zones, with repopulation timing.

### B3. Archetype resolution — close the `UNKNOWN`
`OverriddenAiArchetypeNames` and `*AiTypes` are carried as raw name strings.
`AiArchetypeCatalog` resolves 267 shipped `AIArchetype` exports; the rest and the
resistance-set values live in `ConfigINI.IBF` (`IniBundle` reads it). Wire
`document.archetypes` + `Weapons.ini` `[*ResistanceSet]` → the `UShockAiArchetype` data
assets (`is_ranged`, health, mesh, loadout, resistances) for **all** archetypes, not just
Medical's 23.

### B4. `defaultproperties` → class defaults, game-wide
The class-schema exporter (Phase 2.1, done) emits every class's `defaultproperties` tree.
Phase B feeds those into the C++ classes' constructors / a data-asset per class, so
`RangedAggressor`'s collision size, `bPrefersRangedAttack`, damage-resistance-set, etc.
come from data rather than hand-typed constants. This is the bridge into Phase C.

**Phase B exit:** every map's scripts, spawners and archetypes are live data in the project;
opening any map and pressing Play spawns the right enemies in the right places (even if
their behaviour is still thin).

---

## Phase C — Make the runtime a game

The first-slice runtime (`BioShockRuntime`: combat FSM, hitscan weapon + ammo, damage
library, HUD, death/respawn, nav, hit reactions, ~23 actions) becomes the real thing.

### C1. A data-driven action VM — stop writing one-off stubs
There are ~186 `Action*` classes and ~66 in `ShockAI` alone. Wiring each by hand
(`ApplyInWorld()` per class) does not scale. Build:
- `UShockActionVM`: reads the `Action*` schema + parameters from Phase B data and dispatches
  through a **registry of handlers** — a handler covers a *family* (state setters, AI
  commands, spawn ops, timers, flow control) rather than one class each.
- Keep the census order: the top 20 actions are 73% of all scripted behaviour, top 50 is
  90%. Handlers for those families first.
- Latent actions (`Wait`, `FinishAnim`, latent `MoveTo`) → C++ coroutine-style tasks on the
  VM, not per-frame polling.

### C2. The `ShockAI` state machines — the architecture decision
103 UnrealScript states, decompiled cleanly enough to read as spec. This needs the call
`UE5_FULL_PORT_PLAN.md` §5 Phase 3 flagged and never made:
- **Recommendation: a lightweight C++ state-machine component** (`UShockStateMachine`) that
  mirrors UnrealScript state semantics (labels, `GotoState`, state-scoped functions,
  `Begin:` blocks, latent `Sleep`) directly — *not* StateTree/BT, which would force a
  translation and lose the 1:1 mapping to the source. Generate a skeleton per state from
  the decompiler output; fill bodies census-ordered.
- Prove it on the two enemies the slice already spawns (Thug/melee splicer + a Leadhead),
  then the Big Daddy (the set-piece), then the tail.

### C3. Player systems
Census/spec order, each its own sub-project:
- Health / EVE, first-aid kits, EVE hypos.
- **Plasmids** — `EquipPlasmid` / `UnEquipAllPlasmids` stubs exist. Electro Bolt →
  Incinerate → Telekinesis → the rest. Plasmid = a `UShockPlasmid` with a cost, a cooldown,
  a targeting mode, an effect (damage / status / physics / spawn).
- **Hacking** — `HackSecuritySystem` / `HackTurret` / `UnHackSecuritySystem` stubs exist.
  The pipe minigame or the modern "hack tool" — pick one, faithful-first says the minigame.
- Inventory, ammo types (AP / anti-personnel / incendiary per weapon), U-Invent, Gene Banks,
  the Research Camera, ADAM / Gene Tonics.

### C4. Weapons — all seven
Wrench, Pistol, Machine Gun, Shotgun, Grenade Launcher, Chemical Thrower, Crossbow, plus the
Research Camera and the Rivet Gun-adjacent bits. Each: fire modes, ammo types, the upgrade
stations. The hitscan `AShockWeapon` generalises to a `UShockWeaponDef` data asset +
projectile/beam/hitscan strategies.

### C5. The behaviour library — breadth then depth
Everything else `Action*` / native, worked from the census, most-used first, each verified
against the running game. This is the long pole and no tooling removes it — but by this
point the VM, the state machine and the data layer make each one small.

**Phase C exit:** you can start a New Game and play `Welcome` → `1-Medical` → `1-Welcome`
→ … through to the end, with real (if rough) enemy AI, working plasmids and weapons, hacking,
and the level-to-level story beats.

---

## Phase D — Fidelity

Runs *alongside* C once the game is playable end to end. Not blocking.

- **D1. Lighting & lightmaps.** The decode is done (39,288 descriptors, atlas binding on 20
  maps, `LayerLighting.hlsl` recovered — `docs/ROADMAP.md` Gate 0.3). Bring baked light into
  the UE5 maps properly instead of the dynamic-fill stopgap.
- **D2. Material graphs.** Panner / timeline / switch node values already copy onto the
  manifest; build the actual UE5 material graphs that consume them (water, force fields,
  screens, the `MaterialSwitch` chains).
- **D3. Animation.** Import the 16,031 `AnimSequence`s at scale (currently enemies slide —
  no anims), build the AnimBlueprints (locomotion blendspaces, upper/lower split, the
  weapon poses), wire `PlayAnimation` / scripted-hand animations for real.
- **D4. Audio.** Blocked on the data-location find (`docs/research/audio.md` §4). Placement
  is *ready* (`AmbientSound` / `SoundMarker` decoded). The day the FSB/bank location is
  found, this unblocks in bulk.
- **D5. Reflections, post, water, particles** — the Rapture look.

---

## How to run this — "fix as we go"

Every phase item is a task for `tools/agents/orchestrator.ps1`. The loop:

1. **Scaffold** — write the batch tool (`import_all_levels.py`, the VM skeleton, a state
   generator). One task.
2. **Run it wide** — over all 21 maps / all archetypes / the census head. It surfaces
   concrete gaps.
3. **Fan out the fixes** — one agent task per gap, in parallel worktrees, each with a
   headless verify.
4. **Land the green ones**, re-run wide, repeat until the gap list is dry.
5. **Play it** (`play_slice.ps1` generalised to `play_game.ps1`) and log what's wrong —
   that list is the next round.

Parallelism: Layer A/B tasks (Python, per-map) fan out freely. Layer C tasks touch
`BioShockRuntime` C++ and must be **serialised** (shared HostProject — see
`155d133`). Run non-C++ work alongside C++ work, not two C++ tasks at once.

Workers: `cursor` for `tools/ue5/**` + runtime, `codex` for `src/**` decode/exporter work
and report-only audits, local `qwen` for nothing multi-step (it can't drive these).

---

## Honest sizing

This is still, per `UE5_FULL_PORT_PLAN.md` §6, a **multi-year effort at hobby pace**. What
changes with this plan is the *order of visible payoff*:

- **Phase A** (weeks): the whole city is walkable in the editor.
- **Phase B** (weeks): every map spawns the right enemies and runs its scripts.
- **Phase C1–C2** (months): the AI actually fights across the game.
- **Phase C3–C5 + D** (years, tapering): plasmids, hacking, the full weapon set, animation,
  audio, the look.

"Done enough to play through" (rough AI, core plasmids, weapons, no audio) is a **Phase C2 +
partial C3/C4** milestone. "Faithful" is the whole thing and is a different project — decide
which one this is before Phase C3 (`UE5_FULL_PORT_PLAN.md` §6 "fidelity drift").

---

## Immediate next tasks (in order)

1. ~~`import_all_levels.py` + a first wide run~~ — **4-map proof done** (A1 above); full 21 next.
2. `import_scripts.py` wide run (B1) — the 20 non-Medical maps, record the gaps.
3. The Tier-1 archetype/weapon bulk import (A2) — bounded set from the manifests.
4. `UShockActionVM` skeleton + the state-setter and AI-command handler families (C1).
5. ~~`import_all_levels` lighting-stopgap~~ — shipped in A1 (`--lighting-stopgap`, default on).

1 and 2 are pure Python, fan out immediately, and turn "convert the game" into a concrete
gap list — same move that Phase 2.1/2.2 made for the AI.
