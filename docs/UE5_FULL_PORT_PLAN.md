# Porting BioShock to UE5 in full — a strategy

**Written 23 Aug 2026, at the user's request: import the entire game into UE5, including game
logic and AI.**

This is a plan, not a claim of work done. Every number in it is measured from this repository or
from the shipped game; where something is a judgement call it says so.

---

## 1. The bottom line, first

**The assets are a solved problem in principle and a grind in practice. The game logic is readable
but not portable automatically. The gap between those two facts is what this plan is built around.**

One measured asymmetry decides the whole strategy:

| What decompiles | Quality | Usable as |
|---|---|---|
| Class hierarchy, names, `var` declarations | **Clean** | Machine input |
| `defaultproperties` blocks | **Clean** — `CollisionRadius=50.0`, `bPrefersRangedAttack=true` | Machine input |
| Function bodies, state machines | **Degraded** — control-flow artifacts, `__NFUN_<id>__` placeholders, occasional statement errors | Human documentation |

So: **port the data mechanically, reimplement the behaviour by hand, and use the decompiled source
as the specification while doing it.** Anything that tries to transpile UnrealScript function bodies
into C++ or Blueprint will faithfully encode the decompiler's own defects, and will be harder to
debug than a hand-written implementation read from the same source.

**Do not attempt an automatic UnrealScript-to-UE5 transpiler.** It is the obvious idea and it is the
wrong one, for the reason above.

---

## 2. Three layers, three strategies

### Layer A — Assets. Mechanical. Extend what exists.

Meshes, skeletons, animations, textures, levels. Already imports into UE5.7 today
(`tools/ue5/import_bioshock.py`, `import_level.py`). Bounded work, not research.

### Layer B — Data. Mechanical, and mostly not built yet.

Every class's schema and defaults; every placed actor's transform, zone, tags and references; every
`Script` actor's `Actions` array; every AI archetype's tuning numbers. **This is the highest-value
unbuilt piece**, because it is pure data, it decompiles cleanly, and it is what makes Layer C
tractable rather than open-ended.

### Layer C — Behaviour. Hand-written, prioritised by measured usage.

Function bodies, state machines, native calls. Reimplemented in UE5 C++ against the decompiled
source as a spec. **Bounded by data**: this project can measure which classes the shipped levels
actually use, so the work is prioritised by evidence rather than by guessing.

---

## 3. What already exists (measured, not estimated)

**Assets:** 8,668 static meshes, 967 skeletal meshes (99.9% resolving section tables), 16,031
animations (0 decode failures), 30,831 textures plus 287 cubemaps, 14,328 materials. UE5 import
works end to end: meshes, skeletons, animations, textures with correct sRGB and compression,
idempotent re-runs.

**Levels:** 21 map packages. BSP world, 118,919 placed actors across 764 classes, 1,042 zones with
connectivity, 2,386 portals with their zone pairs, 465+ lights per map, 281 cubemap probes.

**Physics:** Havok ragdolls decoded — 207 rigs, 1,426 rigid bodies with world transforms, masses,
inertia, friction, restitution; capsule shapes; the full constraint graph. **Joint limits are not
decoded and will not be** (declined on Havok licence grounds, `docs/research/havok-physics.md`).

**Game logic:** **1,445 classes decompile with 0 hard failures** across `ShockGame.U` (654),
`ShockAI.U` (540), `Scripting.U` (99) and seven smaller packages. `Engine.U` does not decompile (a
UELib version-gating bug) but is mostly stock engine classes. `ShockAI.U` alone is 64,698 lines,
3,120 functions, **103 state machines** and **66 Action classes**.

**Audio:** the chain is decoded down to sound names, but **where the sound data lives is still
UNKNOWN** and is the standing blocker (`docs/research/audio.md` section 4).

---

## 4. The insight that makes the AI tractable

BioShock's AI and scripting is **data-driven**, and both halves are already partly in hand:

- **The level side:** `Script` actors (3,942 game-wide) carry `Actions` arrays, and
  `LevelAnalyzer.ScriptActions` **already resolves them to typed class and object references**.
- **The code side:** those references name `Action*` classes — `ActionAttackTarget`,
  `ActionHackTurret`, `ActionAssignNextProtectorVent` — each a small class with typed parameters
  (`var travel name AILabel; var travel name TargetLabel; var travel bool bAttackOnSight;`).

So a level's scripted behaviour is **a graph of parameterised action nodes**, and this project can
already read the graph. What is missing is the implementations — 66 of them in `ShockAI`.

**That reframes "port the AI" from an unbounded research problem into a countable list**, and the
list can be ordered by how often each action actually appears in the shipped maps. That census does
not exist yet and is cheap to build.

The same argument applies to enemy tuning: `RangedAggressor`'s `defaultproperties` already give
collision size, locomotion flags, ranged-attack preference and a damage-resistance set name. Every
archetype has such a block, and they extract cleanly.

---

## 5. The plan

### Phase 0 — Prove the whole stack on one vertical slice (do this first)

**One level, one enemy archetype, one weapon, playable end to end.** Not the best-looking slice; the
*thinnest* one that exercises every layer. The point is to find the integration problems while they
are cheap.

This project's own history is the argument. Every UE5 item worked on so far had a defect that only
appeared when the pipeline was actually run: a manifest that did not carry texture intent, an
importer with textures switched off, a level importer that spawned 465 duplicate lights. Breadth
before a working slice multiplies that class of problem by 21 maps.

### Phase 1 — Finish Layer A (assets)

1. **Level geometry as real UE5 meshes.** Today the BSP world exports as OBJ and the level importer
   places `TargetPoint` placeholders where geometry should be. The single biggest visible gap.
2. **Materials as UE5 material instances.** Bindings, intent and animators are decoded; no UE5
   material graph is generated. Build one master material per shader class, then instance it.
3. **Cubemaps as reflection captures**, using the `CubemapProbe` actors' positions (281 of them,
   each naming its `Cubemap`).
4. **Lighting.** 465+ lights per map already export with colour and brightness. Brightness has no
   established photometric mapping; calibrate once against the game, then apply uniformly.

### Phase 2 — Build Layer B, the data layer (highest-value unbuilt work)

1. **A class-schema exporter.** Run the decompiler over all 1,445 classes and emit structured JSON:
   class, parent, `var` declarations with types, and the full `defaultproperties` tree. Mechanical,
   decompiles cleanly, and **nothing else in this plan is efficient without it**.
2. **An action-usage census.** For every `Action*` class, how many times it appears across the 21
   maps' `Script` actors. This orders Phase 4.
3. **Extend the level manifest** to carry the script graph, AI spawner configuration, zone
   membership (already decoded via `Actor.Region`) and archetype references.

### Phase 3 — A runtime skeleton in UE5 C++

Mirror the parts of the class tree that matter as real UE5 classes: `AShockPawn`, `AShockAI`,
`UAction` with a parameter block populated from Phase 2 data, `UActionSet`, the weapon and plasmid
bases. Populate instances from exported data rather than hand-authoring them.

**Where UE2 and UE5 genuinely differ** — these need design decisions, not translation:

- **UnrealScript states** (103 in ShockAI) have no UE5 equivalent. Map to a state-machine component
  or to StateTree / behaviour-tree nodes.
- **Latent functions** (`Sleep`, `FinishAnim`, latent `MoveTo`) are VM-level in UE2. In UE5 they
  become latent nodes or C++ coroutine-style tasks.
- **Havok to Chaos.** Bodies, masses, capsules and the constraint graph are decoded; joint limits
  are not, and are licence-blocked, so ragdoll constraints must be re-authored or approximated.

### Phase 4 — Implement the behaviour library, in measured priority order

Work the action list from Phase 2's census, most-used first. For each: read the decompiled `.uc`,
implement in C++, verify against the game.

**Budget this honestly.** `ShockAI` alone is 3,120 functions and 103 state machines; `ShockGame` is
larger again. This is the long pole by a wide margin, and no tooling removes it.

### Phase 5 — Audio (blocked, not on the critical path)

Sound names resolve; the sound data location is UNKNOWN. Ambient placement is already decoded
(`AmbientSound` actors name sounds by `Tag`, `SoundMarker` carries `ambience_*` schema names), so
the moment the data is located, placement is ready. Until then the port runs silent.

---

## 6. Risks, stated plainly

| Risk | Assessment |
|---|---|
| **Scale** | ~1,445 classes. A multi-year effort at hobby pace. The vertical slice is what keeps it honest. |
| **`__NFUN_<id>__` natives** | Only a partial ID-to-name map exists. Each unresolved native is a small research task at implementation time. |
| **`Engine.U` will not decompile** | Mostly stock classes; a real problem only if a specific base class turns out to matter. |
| **Havok joint limits** | Licence-blocked, permanently. Ragdolls need re-authored constraints. |
| **Audio data** | Genuinely unknown; may stay blocked indefinitely. |
| **Fidelity drift** | Hand-written behaviour will diverge from the original. Decide early whether the goal is *faithful* or *playable* — they are different projects. |

## 7. Constraints

This repository already forbids committing game-derived data, and that applies here: decompiled
UnrealScript, extracted assets and any UE5 project built from them are derived from a commercial
game. This plan assumes a personally-owned copy and no redistribution. Havok's licence separately
prohibits the reverse engineering that joint limits would require — already declined twice, and it
stays declined.

## 8. What to do next, concretely

In order, smallest first:

1. **The class-schema and `defaultproperties` exporter** (Phase 2.1). Mechanical, self-contained,
   and everything downstream gets cheaper once it exists.
2. **The action-usage census** (Phase 2.2). Cheap, and it turns "port the AI" into an ordered list.
3. **Level geometry as real meshes** (Phase 1.1). The biggest visible gap in what already imports.
4. **Then the vertical slice**, using the three above.

Items 1 and 2 are the ones to start with: small, pure data, and they convert the open-ended part of
this project into something countable.
