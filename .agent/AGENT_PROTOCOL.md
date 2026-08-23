# Agent protocol

Binding working rules for every agent operating in this repository.

This sits **under** `CLAUDE.md` and `docs/ENGINEERING_RULES.md`, which remain the canonical ruleset.
Where this file repeats them it is for emphasis; where it adds anything, it adds coordination
mechanics for multiple agents, not new engineering policy. **If this file and
`docs/ENGINEERING_RULES.md` conflict, `ENGINEERING_RULES.md` wins** and the conflict should be
reported to the lead.

> **Note on §60 of `ENGINEERING_RULES.md`.** That section says "do not use subagents or workflows
> unless asked". The user asked, on 23 Aug 2026, for exactly this multi-agent setup. That standing
> instruction is therefore satisfied, not overridden — agents operate only within tasks the lead has
> issued from `TASK_QUEUE.md`.

---

## 1. General rules — all agents

- **Inspect before editing.** Read the file, and read the `KNOWN_ASSUMPTIONS.md` entry covering it.
- **Do not modify unrelated files.** A task touching `Core/Audio/` does not touch `Core/Mesh/`.
- **Do not perform broad refactors without explicit approval.** Renaming, re-layering, extracting
  interfaces, "tidying" — all require a lead decision first.
- **Do not silently change binary-format assumptions.** See §2.
- **Prefer evidence over intuition.**
- **Never claim something is proven without validation.** "Resolves correctly, sample storage not
  located" is a better sentence than "audio works".
- **Use exact paths and symbols in reports** — `src/BioShockStudio.Core/Level/PropertyValues.cs:231`,
  not "the property helper".
- **Keep changes small and reviewable.** If a diff exceeds roughly 300 lines or 6 files, stop and
  ask the lead to split the task.
- **Do not commit unless explicitly asked.** The lead commits.
- **Do not merge branches.** The lead integrates.
- **Do not delete existing evidence or research notes.** Negative results are results. Superseded
  findings are struck through and kept, never removed.
- **Do not hide failing tests.** Never relax an assertion, skip a test, or narrow a filter to get
  green. A failing test is classified (`ENGINEERING_RULES.md` §24) before anything is touched.
- **Unknown is a valid answer.** A truthful partial result beats a plausible wrong one.
- **Never trust a single sample.** A structure that works in one package may be package-local. This
  has already happened here.
- **Render it.** Numeric validation has passed on visibly wrong output in this project more than
  once. For anything visual, a picture or a round-trip is part of the evidence.

---

## 2. Reverse-engineering rules

Any change involving **binary layout, offsets, serialization, compact indices, animation formats,
Havok structures, skeleton transforms, coordinate conversion, or FBX layout** must ship with
evidence.

Acceptable evidence:

- byte-level comparison (hex, with offsets, against the actual shipped payload)
- **multiple real samples** — at minimum two packages, preferably a whole-game census
- cross-package agreement
- agreement with a reference project (`UModel-master/`, `Bioshock1REMSDK-WIP--main/`,
  `Unreal-Library-master/`, `hk2012_2_0_r1/`) — **read these before deriving from bytes**; it is
  project policy because it keeps paying
- observed engine behaviour
- an automated test against real game bytes
- known SDK documentation

**No assumption may be changed because "the output looks better."** That specific reasoning produced
two of the longest-lived bugs in this repository's history.

Two traps worth naming, because both have already caught this project:

- **Agreement with a reference implementation is not correctness.** Both can be wrong the same way —
  see `KNOWN_ASSUMPTIONS.md` A2.
- **A name-keyed lookup that misses is not proof the target is absent.** Check the encoding
  convention first — see A3.

---

## 3. Reporting

Agents write **concise, evidence-oriented reports**, not conversation transcripts. A report the lead
cannot act on without reading the agent's whole session has failed.

Every report states, in this order:

1. **What was asked** (task ID).
2. **What was found or done** — three to ten lines.
3. **Evidence** — exact paths, symbols, line numbers, byte offsets, counts, test names and results.
4. **Confidence** — `CONFIRMED_BYTES` / `CONFIRMED_EXTERNAL` / `PLAUSIBLE` / `UNKNOWN`.
5. **What was NOT done, and what is still unknown.**
6. **Recommended next step**, and which agent should take it.

Raw logs go in only where the specific lines are the evidence. No dumps.

---

## 4. Agent roles and boundaries

### Research agent

**Allowed:** repository search; code reading; documentation reading; call-graph investigation;
format investigation; binary evidence gathering; hypothesis comparison; running the CLI and
read-only probes; writing `.agent/` reports.

**Prohibited by default:** production code changes; architecture changes.

A throwaway probe outside the repository (e.g. under the session scratchpad) is allowed and
encouraged for exploration; it is never committed and never lives in `src/`.

**Output:** `.agent/reports/REPORT-<TASK-ID>.md`

### Coding agent

**Allowed:** implement the assigned task; narrow refactors *required by* that task; add relevant
tests; build.

**Prohibited:** unrelated refactors; changing format assumptions without accepted evidence;
architecture redesign unless explicitly assigned; adding a NuGet dependency to
`BioShockStudio.Core` (it currently has none — that is deliberate).

**Output:** `.agent/reports/RESULT-<TASK-ID>.md`

### Testing agent

**Allowed:** reproduce bugs; run tests; add narrowly scoped regression tests; inspect outputs;
compare real samples.

**Prohibited:** feature implementation; **silently fixing code while testing** — if a fix is
obvious, report it and let the lead assign it; introducing any synthetic fixture (A15).

**Output:** `.agent/reports/TEST_REPORT-<TASK-ID>.md`

### Review agent

**Allowed:** inspect diffs; inspect surrounding code; identify risks; check assumptions against
`KNOWN_ASSUMPTIONS.md`; check for missing tests; recommend approval or rejection.

**Prohibited:** modifying production code unless explicitly asked.

A review must **not** rely on the coder's summary. Read the diff and the code around it.

**Output:** `.agent/reports/REVIEW-<TASK-ID>.md`

> Reports are per-task files under `.agent/reports/`. The generic names in the original spec
> (`REPORT.md`, `RESULT.md`, `TEST_REPORT.md`, `REVIEW.md`) are kept as **symlink-free aliases**:
> an agent may write `.agent/REPORT.md` for a one-off, but anything belonging to a queued task goes
> in `reports/` with the task ID, so parallel agents cannot overwrite each other.

---

## 5. Lead engineer workflow

1. Lead identifies a problem.
2. Lead decomposes it into a narrow task in `TASK_QUEUE.md`.
3. **Research agent investigates when uncertainty exists.**
4. Lead evaluates the evidence.
5. Coder implements **only the approved interpretation**.
6. Tester independently validates.
7. Reviewer inspects the diff and the assumptions.
8. Lead approves, rejects, or requests another iteration.
9. **Only approved work is integrated**, and only the lead integrates it.

**For any risky reverse-engineering work, Research happens before Coding.** "Risky" means anything
in §2's list. A coder handed such a task without an accepted research report should refuse it and
say so.

---

## 6. Concurrency and conflict avoidance

This repository has already lost time to two agents editing the same files with no coordination.

- **Claim before you touch.** Add a row to the "Active work" table at the top of `docs/HANDOFF.md`
  before starting; remove it when the task lands or you stop. Check it before touching a file
  another row claims.
- **One task, one agent, one area.** Tasks in `TASK_QUEUE.md` are scoped so their file sets do not
  overlap. If two READY tasks touch the same file, only one is dispatched.
- **Stage by filename. Never `git add -A`.** The reference projects and `artifacts/` are gitignored
  but a sweeping add is still how a 4.5 GB accident happens.
- **Small, frequent commits, by track.** A single 57-file, 2,800-insertion diff sat uncommitted for
  over a week here; there was no rollback point inside it.
- Current branch is `feature/fbx-materials-gui`, **37 commits ahead of `origin`**. A second worktree
  exists at `C:\Users\Jack\Documents\BioshockHavok-fbxtest` (detached HEAD). Agents work in the main
  worktree unless the lead says otherwise.

---

## 7. Context-efficiency rules

`docs/` is ~11,900 lines. Reading it all, per agent, per task, is the single largest avoidable cost
in this setup. The `.agent/` directory exists to be read **instead of** most of it.

- **Start from `.agent/PROJECT_STATE.md` and `.agent/KNOWN_ASSUMPTIONS.md`.** They are written to be
  sufficient for scoping. Go to `docs/` only for the specific note your task names.
- **Read the task's named files, not the module.** `TASK_QUEUE.md` lists likely files per task for
  exactly this reason.
- **Use targeted search** (`Grep` with a path or glob) over reading whole files. Read a range, not a
  2,000-line document.
- **Do not re-read a document another agent has already summarised.** Check `.agent/reports/` first.
- **Do not re-derive a closed finding.** `docs/research/open-questions.md` marks many CLOSED and
  `docs/HANDOFF.md` §8c lists failed approaches — both exist to stop exactly this.
- **Summarise; cite paths and symbols.** Do not paste code the lead can open.
- **Never dump raw logs** unless the specific lines are the evidence.
- **Test-run economy is binding** (`ENGINEERING_RULES.md` §60):
  - `dotnet test --filter Tier=Fast` (~52 s) constantly while working.
  - Before any sweep run, read the verification stamp in `docs/ROADMAP.md` "Test health", then
    `git diff --stat <stamp>..HEAD` to see what could have moved, and run **only** the sweep classes
    covering that, by name: `dotnet test --filter "FullyQualifiedName~<Class>"`.
  - Run the whole suite only when the diff reaches shared machinery (package reading, the property
    walker, the catalogue, the coordinate basis), when the stamp is many commits stale, or when a
    handover reports the whole-suite total — **and move the stamp forward in the same commit.**
  - **An unrun tier is reported as unrun, never as passing.**

---

## 8. Definition of done

A task is done when **all** of these hold:

- the change is the smallest correct one for the stated goal;
- `dotnet build` is clean (0 warnings — the tree is currently at 0 and should stay there);
- the Fast tier is green, and every sweep class the diff could have moved has been run **by name**
  and is green;
- new behaviour has a regression test **against real game bytes**;
- any new or changed figure appears in a test, not only in prose;
- the relevant `docs/research/*.md` note and `docs/ROADMAP.md` are updated in the same change;
- confidence is labelled explicitly;
- a report exists under `.agent/reports/`;
- the lead has approved it.

"Mostly working" is not done. An item with an open sub-part is either finished or explicitly
recorded as blocked.
