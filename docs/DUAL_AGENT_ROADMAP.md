# Two-agent roadmap — Cursor and Claude Code

Added 28 Aug 2026. This is a **coordination** document: who works where, and in what order, now that
two AI agents run against this repository. It is not a status document — status lives in
[`ROADMAP.md`](ROADMAP.md) (the C# tool and decode work) and
[`UE5_FULL_PORT_PLAN.md`](UE5_FULL_PORT_PLAN.md) §9 (the UE5 port). Where this file names a task,
follow the link for the evidence and the detail; this file only says whose lane it is and where it
sits in sequence.

The standing-rule form of this is [`ENGINEERING_RULES.md`](ENGINEERING_RULES.md) §61.

---

## Why lanes, and why by file

Both agents work `main` — there is no feature branch for day-to-day work
([`NEXT_SESSION.md`](NEXT_SESSION.md), [`ENGINEERING_RULES.md`](ENGINEERING_RULES.md) §60). The only
coordination mechanism that two independently-run sessions can be expected to keep current is the
**Active work claim table** at the top of [`HANDOFF.md`](HANDOFF.md). A branch-per-track scheme was
considered and rejected on 19 Aug 2026 for exactly this reason.

So the split is by **file ownership**, chosen so the two lanes touch almost-disjoint trees:

| | **Cursor** | **Claude Code** |
|---|---|---|
| Owns | `tools/ue5/**` — Python import/verify scripts, `BioShockRuntime/` C++ plugin | `src/**`, `tests/**`, `docs/research/**`, `docs/QUALITY.md` — the C# extraction tool |
| Reads (never writes) | Exported JSON: level manifests, `*.script-actions.json` sidecars, schema JSON, rig/mesh/material exports under the throwaway project's `Exports/` | The installed game bytes |
| Produces | The imported `.umap`s and the UE5 runtime | The exports Cursor consumes |
| Drives | UE5 plan **Phase 0** (playable slice), **Phase 3** (runtime skeleton), **Phase 4** (behaviour execution) | UE5 plan **Phase 1** (finish assets), **Phase 2** (data layer); [`ROADMAP.md`](ROADMAP.md) Part 2 Gate residuals |
| Already set up for it | `.cursor/permissions.json` (robocopy plugin sync, `RunUAT BuildPlugin`, headless `UnrealEditor-Cmd`, filtered `dotnet test`); the stop-hook; the current claim row | The two-tier test discipline, the evidence rules, the CLI |

This is close to the split that already exists in practice — it had just never been written down.

---

## Cursor lane — UE5 runtime and the playable slice

Detail and dated record: [`UE5_FULL_PORT_PLAN.md`](UE5_FULL_PORT_PLAN.md) §5 (the plan) and §9 (what
has landed). Work items in order:

0. **Land the uncommitted backlog first — before any new Phase 4 work.** As of 28 Aug 2026 the
   working tree carries a large uncommitted diff that spans both lanes and is mostly Cursor's:
   `tools/ue5/import_level.py` (+335), `import_bioshock.py` (+176), `ShockGameMode.cpp` (+106),
   `ShockPlayer.cpp`, `run_vertical_slice.py`, `verify_vertical_slice.py`, plus untracked
   `tools/ue5/import_policy.py` and `tools/ue5/test_import_policy.py`. This is exactly the failure
   mode [`ROADMAP.md`](ROADMAP.md) Part 0.2 exists to stop — no rollback point exists inside it.
   Break it into logical commits by track (level import / vertical slice / runtime / import policy),
   `dotnet test --filter Tier=Fast` green, and land it. The two C#-lane files in the same diff
   (`src/BioShockStudio.Core/Export/MaterialExporter.cs`, `tests/BioShockStudio.Tests/MaterialClassTests.cs`,
   untracked `LevelImportPolicyTests.cs`) belong to Claude's lane — commit them separately, or hand
   them back via the claim table, rather than folding them into a UE5 commit.

1. **Close Phase 0 — the playable slice.** The asset half is done (26 Aug 2026: `1-Medical` +
   `Agg_BabyJane` + TommyGun into a saved `.umap`, verified from the reloaded level). The playable
   half is not. Needed: a **human PIE check on `1-Medical`** — WASD / look / Fire feel, starter
   weapon equipped and firing, one enemy archetype that spawns and takes damage. Log evidence
   (`Success - 0 error(s)`, `run_game_possess.py`) is not enough here — [`ROADMAP.md`](ROADMAP.md)
   Part 0.5 and this project's six-faults-in-one-session history are the argument for looking at the
   screen.

2. **Phase 4 execution wiring.** The census is **complete** — every `Action*` class referenced in
   the 21-map probe has a first-slice `UShockAction` (params + schema defaults + request-record),
   and `batch45`'s own note says *"Next: execution wiring / playable slice, not more census
   batches."* The remaining work is moving each stub from *record the request* to *do it in-world*,
   **most-used first per the Phase 2.2 action-usage census**, verifying each against the game. This
   is the long pole by a wide margin (`ShockAI` alone: 3,120 functions, 103 states).

3. **Phase 3 runtime depth.** Populate `AShockPawn` / `AShockAI` / `UAction` parameter blocks from
   Phase 2 data rather than hand-authoring. The three genuine UE2→UE5 design decisions
   ([`UE5_FULL_PORT_PLAN.md`](UE5_FULL_PORT_PLAN.md) §5 Phase 3): UnrealScript states → StateTree or
   a state-machine component; latent functions (`Sleep`, `FinishAnim`, latent `MoveTo`) → latent
   nodes / coroutine-style C++ tasks; Havok bodies/capsules → Chaos (joint limits stay
   licence-blocked and must be approximated).

4. **Script actor coverage beyond Medical.** The `AShockScript` import is proven on full `1-Medical`
   (300 scripts, 1,463 actions mapped, 0 nested unmapped, 27 Aug 2026). Run it on the other 20 maps
   and fix per-map decode gaps.

5. **In-editor animation playback confirmation.** Still unconfirmed
   ([`ROADMAP.md`](ROADMAP.md) Gate 5, Part 0.5 — the pistol was confirmed static-pose only).

**Do not** rewrite `Core/Level` or the BSP readers (measured clean), and do not touch `src/**`
without a claim-table row — that is Claude's lane and a shared-file change there can break the
sweep tier Cursor also depends on.

---

## Claude Code lane — extraction, the data layer, decode residuals

Detail: [`ROADMAP.md`](ROADMAP.md) Part 2 and [`UE5_FULL_PORT_PLAN.md`](UE5_FULL_PORT_PLAN.md) §5
Phases 1–2. Work items in order:

1. **Reconcile Part 0 with reality (small, first).** [`ROADMAP.md`](ROADMAP.md) Part 0.1 still reads
   *"classify the 7 failing tests"*; the four failures from the 23 Aug red stamp were fixed and
   confirmed green at `9cb53b2` (550/550), and the cause was stale bucket totals in the tests, not
   a decoder regression (see "Test health" → verification stamp). Update Part 0.1 and 0.2 to match —
   this is a Part 0.6 documentation-consolidation task, not a test emergency.

2. **Phase 1 — finish Layer A (assets):**
   - **Level-geometry materials.** The authored material graph/instance path (parents + instances,
     base-colour/normal binding, correct LOD slot index) is verified on the `WP_Pistol` **rig**
     slice only. Carry the same path onto **BSP and static-mesh level geometry**. This is explicitly
     *not* evidence that BSP/static-mesh materials are finished
     ([`UE5_FULL_PORT_PLAN.md`](UE5_FULL_PORT_PLAN.md) §5 Phase 1.2).
   - **Cubemaps → reflection captures.** 281 `CubemapProbe` actors, each naming its `Cubemap`.
     `CubemapProbe → SphereReflectionCapture` exists in `import_level.py` as of 25 Aug 2026 but is
     **not visually confirmed**.
   - **Lighting falloff exponent.** Brightness-as-scale and authored-radius-as-attenuation are
     mapped (25 Aug 2026); the falloff exponent is still `UNKNOWN`. Resolve it against game data.

3. **Phase 2 — the data layer (highest-value unbuilt work, and the interface Cursor needs).** Extend
   the level manifest to carry: the **script graph**, **AI spawner configuration**, **zone
   membership** (`Actor.Region`, already decoded), and **archetype references**. Phase 2.1 (class-
   schema exporter) and 2.2 (action-usage census) are done; this third piece is what Cursor's
   Phase 3/4 consumes. Prioritise it over the Gate residuals below.

4. **Gate residuals, in [`ROADMAP.md`](ROADMAP.md) Part 2 order:**
   - **Gate 2 physics** — Havok capsule/body/mass decode for the Chaos mapping. Cursor's Phase 3
     needs this; coordinate timing.
   - **Gate 1 kDOP collision tail** — deferred *by design* until a concrete UE5 collision/navigation
     target is chosen. If Cursor picks one, this unblocks; until then leave it (the game already
     declares collision intent in plain properties — `NeverCollide`, `UseSimpleBoxCollision`, etc. —
     which a bridge can carry without decoding the tree).
   - **Gate 3** — remaining UE2 actor systems as they come up.
   - **Gate 4 (audio) stays closed** — user instruction, [`ENGINEERING_RULES.md`](ENGINEERING_RULES.md)
     §60. Do not resume unless asked.

5. **Part 0.6 — status-doc consolidation** (ongoing, low priority). Collapse the parallel status
   tables in `README.md`, `HANDOFF.md` and `NEXT_SESSION.md` into [`ROADMAP.md`](ROADMAP.md); leave
   `QUALITY.md` and `research/*.md` as the evidence record.

**Do not** edit `tools/ue5/**` — that is Cursor's lane.

---

## The interface between the lanes

Everything Cursor reads is produced by a Claude-lane exporter. That boundary is a **contract**:

- **Manifest and sidecar schemas are versioned.** Manifest versioning + idempotent imports landed
  23 Aug 2026. A schema change is a breaking change for Cursor.
- **When Claude changes an export format:** add a note to [`HANDOFF.md`](HANDOFF.md) "Active work" /
  landmines, bump the version, and keep the previous reader working until Cursor has migrated. Do
  not change a format and a consumer in the same session across both lanes without the user relaying.
- **The sidecar is regenerated locally, never committed:** `bioshock-tool export-script-actions` →
  `<map>.script-actions.json`, then `run_import_scripts.py`. If its shape changes, both the exporter
  (Claude) and `import_scripts.py` (Cursor) move — sequence it: exporter first, announce, then
  importer.
- **Schema JSON** (Phase 2.1) is the class/`var`/`defaultproperties` source the runtime's parameter
  blocks are populated from. Additive changes are safe; renames and type changes are breaking.

---

## Coordination protocol

- **Claim table is the lock.** Add a row to [`HANDOFF.md`](HANDOFF.md) "Active work" before starting;
  check it before touching a file another row claims; remove your row when the track lands. An empty
  table means nothing is claimed *right now*, not that nobody is working — check the date.
- **Git hygiene is the safety net under the table.** Stage by filename, never `git add -A`, commit
  in small logical groups by track. This limits the blast radius of a collision when the table is
  stale ([`ENGINEERING_RULES.md`](ENGINEERING_RULES.md) §48, §60).
- **One track per chat, worked to fully done** before starting another
  ([`ENGINEERING_RULES.md`](ENGINEERING_RULES.md) §60 "Roadmap discipline").
- **Session start:** name one concrete item from this file or the resume block — not a full-repo
  re-survey ([`NEXT_SESSION.md`](NEXT_SESSION.md) §"How to start in Cursor",
  [`ENGINEERING_RULES.md`](ENGINEERING_RULES.md) §60 "Cursor session start").
- **Test economy applies to both agents:** `dotnet test --filter Tier=Fast` constantly; named sweep
  classes off the verification stamp; full sweep only when the diff reaches shared code or a
  whole-suite total is being reported ([`ENGINEERING_RULES.md`](ENGINEERING_RULES.md) §60
  "Test-run economy").
- **`docs/HANDOFF.md` before finishing any substantial task**, including failed approaches.

---

## Pointing the Cursor automation at the right work

`.cursor/hooks/continue-phase4.py` auto-submits a follow-up on every clean stop (up to 25 loops per
conversation), pulling the fenced block under "Resume here" in [`NEXT_SESSION.md`](NEXT_SESSION.md),
falling back to *"Keep going on Phase 4 census."*

**The census is done.** Both the hook's fallback text and the `NEXT_SESSION.md` resume block should
be repointed at **Phase 4 execution wiring and the Phase 0 playable slice** (Cursor lane items 1–2
above), or the automation will keep driving completed work. Update the fallback string in the hook
and the resume block together, in the Cursor lane, with a claim-table row.
