# Engineering rules

**This is the canonical copy.** `CLAUDE.md` in the repository root points here and is what an agent
loads automatically; this file is what it should read in full.

Two other documents carry rules and neither is superseded by this one:

- **`docs/HANDOFF.md` §7 "Working rules"** — the project's own reverse-engineering rules (no
  hypothesis becomes a hardcoded parser; every structure gets a regression test against real bytes;
  confidence labels; fail honestly; correct the record when wrong). §4 "Landmines" is the list of
  things that have already cost real time.
- **§60 below** — standing instructions the user has given directly, which are not in either.

---

## 0. Mission

You are working on a long-running BioShock reverse-engineering, decoding, inspection, conversion, and
export project.

This project may involve:

- BioShock / Unreal package formats
- BSM and package data
- Unreal object/property structures
- FCompactIndex values
- skeletal meshes
- static meshes
- materials
- textures
- animations
- animation events
- Havok data
- HKX data
- audio references
- Blender export
- FBX / glTF export
- GUI tooling
- asset inspection
- relationship graphs
- batch processing
- reverse-engineering research

Your primary responsibility is:

**Make the smallest correct, tested change necessary to accomplish the user's current task while
preserving everything that already works.**

The goal is NOT to produce the most code.
The goal is NOT to investigate everything that looks interesting.

The goal is: correctness + evidence + controlled scope + reproducibility + preservation of existing
functionality.

## 1. Absolute priorities

1. Data integrity
2. Correctness
3. Explicit user instructions
4. Preservation of existing functionality
5. Evidence-backed reverse engineering
6. Testability
7. Maintainability
8. Performance
9. Convenience
10. Agent curiosity

If two rules conflict, the higher-priority rule wins. In particular: **user scope beats agent
curiosity.**

## 2. Explicit user instructions are authoritative

Treat explicit instructions as hard requirements: "write this up and move on", "stop working on
audio", "continue with 1C", "don't touch X", "leave that for later", "only fix this", "don't rewrite
it", "document this", "just test it", "don't change the GUI".

These are not suggestions. They define the task boundary.

If the user says *"Document the finding and continue with 1C"*:

1. Document the finding.
2. Perform only necessary validation.
3. Stop working on that subsystem.
4. Start 1C.

Do NOT continue investigating the old subsystem because a new clue appeared.

## 3. Discoveries are valuable — but discoveries do not expand scope

Use `DISCOVER → VERIFY → RECORD → DEFER → CONTINUE`,
not `DISCOVER → INVESTIGATE EVERYTHING → EXPAND SCOPE`.

If investigation establishes `ReloadPistolOne` → `EventResponse_SoundEffectsSubsystem` →
`HandsReloadPistolOne` → `weapons_pistol_reload_one`, and the sample data location is still unknown:
that is a successful discovery. Document the exact finding, evidence, bytes, packages tested,
confidence and unknowns — then continue with the requested task. Do not begin searching the entire
game for the missing sample data.

## 4. Byte-exact findings must be preserved

Finding something can itself be the important result. Do not discard a finding merely because the
complete system is not understood.

Record: source file, package, object, offset, bytes, decoded value, interpretation, evidence,
confidence, unresolved questions. A partial reverse-engineering result is still a valid result.

## 5. Never turn a hypothesis into a fact

Use explicit confidence levels: **VERIFIED**, **HIGH CONFIDENCE**, **MEDIUM CONFIDENCE**,
**LOW CONFIDENCE**, **HYPOTHESIS**, **UNKNOWN**.

Never describe LOW CONFIDENCE or HYPOTHESIS information as established behaviour.

> This repository's research notes use an older but equivalent scale — `CONFIRMED_BYTES`,
> `CONFIRMED_EXTERNAL`, `CORROBORATED`, `LIKELY`, `HYPOTHESIS`, `UNKNOWN`. Either is acceptable;
> what matters is that the label is present and honest.

## 6. Reverse engineering rule

Never guess when the bytes can be inspected. Do not invent offsets, field meanings, lengths,
compression formats, serialization layouts, object relationships, coordinate systems, quaternion
conventions, version behaviour, Havok structures, Unreal structures or animation formats.

If uncertain: inspect, compare, test, document, and implement only when sufficiently supported.

## 7. Never trust a single sample

Test against multiple real samples whenever practical: different packages, different assets,
different object types, empty/non-empty, small/large, known edge cases.

## 8. Byte-level evidence

Record absolute offset, relative offset, byte sequence, length, datatype, endianness, decoded value,
source package, object context, interpretation and confidence.

```text
Offset:       0x1234
Bytes:        82 16
Encoding:     FCompactIndex
Decoded:      2820
Package:      0-Lighthouse
Meaning:      weapons_pistol_reload_one
Confidence:   HIGH
```

Record enough for somebody else to reproduce the finding.

## 9. Document important discoveries immediately

Update the appropriate document under `docs/research/`. Do not leave important discoveries only in
chat, terminal output, temporary files, comments or agent memory.

## 10. Preserve negative results

Record findings such as "no matching sample found in the 65 shipped FSB5 banks", "these banks contain
10,882 samples but no weapon foley", "the same object is unresolved in Lighthouse", "the surrounding
template bytes differ between packages". Negative evidence prevents future agents repeating the
investigation.

## 11. Deferred research

Record useful research that is outside the current task as deferred work. Do not execute it unless
the user asks or the current task genuinely requires it.

## 12. Task boundary

Determine **Requested**, **Required**, **Validation** and **Deferred**. Only
REQUESTED + REQUIRED + VALIDATION work should normally be performed. Do not silently promote
DEFERRED work into active work.

## 13. Stop conditions

Every task must have a stopping condition. Once reached: **stop**. Do not continue because the
problem is interesting.

## 14. Curiosity control

Noticing interesting things is encouraged. Investigating every interesting thing is not. Ask: "Is
this required to complete the current task?" If no — document it and move on. This matters most in
reverse engineering, binary parsing, Havok, audio, animation and package analysis, which generate
infinite rabbit holes.

## 15. Inspect before modifying

Locate files, read the surrounding implementation, understand the architecture, search for callers
and related implementations, find existing tests, read documentation, identify assumptions and risks
— then modify.

`UNDERSTAND → ISOLATE → PLAN → MODIFY → TEST → REVIEW`

## 16. Never rewrite working code without a reason

Preserve working implementations. Avoid unnecessary parser, exporter, GUI, serialization,
architecture or dependency rewrites. A rewrite requires explicit justification: why incremental fixes
will not do, what is replaced, what may regress, how compatibility is preserved, how it is tested.

## 17. Minimum change principle

Prefer the smallest change that correctly solves the problem. Do not modify unrelated code, clean up
nearby code, rename unrelated variables, refactor unrelated architecture, reformat unrelated files or
"improve" unrelated GUI behaviour.

## 18. Scope lock

One task, one primary objective. A task about animation events does not simultaneously redesign
audio, materials, GUI, exporters or package parsing.

## 19. Change budget

Estimate files affected, functions/classes affected, expected behavioural changes, tests required and
potential regressions. If implementation becomes substantially larger than expected: **stop and
re-evaluate.**

## 20. Do not delete data to make a test pass

Never silently drop bones, animations, events, materials, textures, vertices, properties, unknown
chunks or malformed records to make processing succeed. Preserve what cannot be decoded, or report it
clearly.

## 21. Source file safety

`SOURCE → READ → PROCESS → OUTPUT`, never modify in place. Never automatically delete source assets,
extracted packages, previous exports, backups, caches or research data. Destructive actions require
explicit approval.

## 22. Testing is part of implementation

A change is not complete because it compiles. Build, run relevant existing tests, run new tests, test
representative real assets, test failure cases, inspect the diff. Real project data is preferred over
synthetic fixtures.

## 23. Regression tests

When fixing a bug or discovering byte-level behaviour, add a regression test. Protect against
off-by-one errors, incorrect offsets, wrong indices, incorrect FCompactIndex decoding, package-local
assumptions, coordinate errors, animation timing errors, hierarchy errors and export regressions.

## 24. Classify test failures

**A. Regression** → fix it. **B. Incorrect test** → correct the test. **C. Pre-existing** → record
it. **D. New discovery** → document it, decide whether it blocks. **E. Unrelated** → do not
automatically investigate.

## 25. Do not use testing as an excuse to expand scope

BAD: "The test passes, but Lighthouse behaves differently, so I'll investigate Lighthouse now."
GOOD: "The targeted test passes. Lighthouse differences are documented as deferred research."

## 26. Real data is the source of truth

`REAL PACKAGE + REAL OBJECT + REAL BYTES + EXPECTED RESULT`.

## 27. Parser rules

Validate bounds and lengths, detect invalid offsets, avoid buffer overruns, report malformed data,
avoid silent corruption, preserve unknown data. Never "make the parser work" by skipping validation.

## 28. Package-local data

Do not assume a byte pattern surrounding a valid structure is globally constant. When one package
differs, compare the bytes and determine which portion is actually invariant.

## 29. Compact index / indexed data

Verify byte boundaries, sign handling, continuation bits, index start offset, encoded length, name
table and object context. Never assume the index begins at a fixed offset without evidence.

## 30. Animation rules

Preserve bone hierarchy, ordering, bind pose, transforms, rotations, translations, scale, keyframe
timing, frame rate, event timing and root motion. Never alter these to make an animation *appear*
correct. Do not compensate for an unknown decoding error downstream.

## 31. Animation event rules

Events may carry multiple responses, filters, chance, state, level context, timing and package-local
references. Never assume one event = one response. Preserve all responses.

## 32. Audio research rules

A decoded audio **name** does not prove the **sample data** has been located. Distinguish
`EVENT → OBJECT → NAME` from `NAME → AUDIO SAMPLE`. If sample storage is unknown, say "reference
resolved; sample storage not yet located" — that is a valid result.

## 33. Havok rules

Never assume a Havok version from filename, extension, era, SDK availability or superficial
similarity. Validate against actual data. Separate confirmed version, likely version, SDK
compatibility, serialized format version and game-specific wrappers.

## 34. Coordinate system rules

Document handedness, up axis, forward axis, unit scale, rotation order, quaternion convention and
matrix convention. A mathematically valid transform can still be wrong for BioShock.

## 35. Exporter rules

Exports should be deterministic. Preserve geometry, normals, tangents, UVs, vertex colours,
materials, textures, skeletons, hierarchy, transforms, animation timing, curves and events. Document
any unavoidable approximation.

## 36. Blender export rules

Do not assume Blender's coordinate system matches the source. Validate orientation, scale, bone roll,
hierarchy, bind pose, playback, material slots, texture paths and UVs. A file that opens is not
proof; visual **and** structural validation are both required.

## 37. Texture/material rules

Do not assume texture names map directly to materials. Preserve dimensions, channels, alpha, UV
mapping, assignments, references and compression information. Unknown relationships stay unknown.

## 38. GUI rules

The GUI is a product, not a debugging shell. Preserve existing workflows, shortcuts, navigation,
selection, progress, cancellation, error reporting, dialogs, settings and previews. Long operations
must not block the UI. Do not create fake progress indicators.

## 39. Batch processing

Batch work must be resilient: report processed/succeeded/failed rather than aborting on one failure,
unless continuing would corrupt results. Failures must identify asset, stage, error and context.

## 40. Error messages

Errors must be actionable — package, object, offset, expected, observed — not "failed to parse".

## 41. Logging

Logs should answer what was processed, which package/asset/parser/stage, what failed, why, and how
long it took. Do not flood normal users with debug output.

## 42. Performance

Correctness first. Before optimizing: identify a real problem, measure, find the bottleneck, make a
targeted change, re-measure, confirm correctness.

## 43. Dependencies

Before adding one: search existing dependencies, check for equivalent functionality, consider build
environments, offline operation, licensing and maintenance.

## 44. External research

Distinguish **primary** evidence (source, SDK docs, official documentation, binary samples,
executable behaviour) from **secondary** (reverse-engineering research, articles, community docs)
from **weak** (forum speculation, unverified claims, guesses). Never present weak evidence as fact.

## 45. Repository documentation is project memory

Discoveries must not depend on the current agent remembering them. Another agent should be able to
continue without repeating previous investigations.

## 46. Do not repeat solved investigations

Search `docs/`, `research/`, `README`, `CLAUDE.md`, source comments, tests and decision records
first. If the repository already establishes an answer, use it unless new evidence contradicts it.

## 47. Decision log

Record decision, reason, evidence, alternatives, consequences and confidence.

## 48. Git / diff discipline

Understand the state before, inspect the diff after. Look for accidental edits, unrelated changes,
deleted code, debug code, generated or temporary files and formatting churn. Prefer small logical
commits.

## 49. Never claim success without evidence

Do not say "fixed", "complete", "working", "fully supported", "decoded" or "compatible" unless
evidence supports it. Prefer "the parser now passes the regression test for the verified event
structure" or "the reference resolves correctly, but sample data location remains unknown".

## 50. Do not hide failures

Do not suppress errors, weaken validation, fabricate results, pretend an incomplete feature is
complete, silently skip problematic data or silently downgrade accuracy. A partial implementation
with known limitations beats a falsely complete one.

## 51. User questions should be minimal

Ask only when requirements conflict, interpretations differ materially, action is destructive, data
could be lost, architecture must be rewritten, compatibility would break, essential evidence is
missing, or the task cannot proceed safely. Otherwise make the safest evidence-backed decision and
continue.

## 52. Do not over-engineer

Prefer simple, understandable implementations. Complexity must have a reason.

## 53. Agent workflow

**RECON** → **PLAN** (goal, files, changes, risks, tests, stopping condition, deferred discoveries) →
**IMPLEMENT** (smallest correct change) → **TEST** → **REVIEW** → **REPORT** (completed, evidence,
discoveries, deferred, limitations, next).

## 54. Task transition protocol

`OLD TASK → complete requested work → minimal validation → record discoveries → CLOSE → NEW TASK`.
Never reopen the old task unless explicitly instructed.

## 55. Example of correct behaviour

User: *"Write up the audio discovery and continue with 1C."*

Correct:

```text
1. Update docs/research/audio.md.
2. Include byte-exact evidence.
3. Record that sample storage remains unknown.
4. Run the directly affected test/build.
5. Confirm the repository is not left broken.
6. Stop audio work.
7. Begin 1C.
```

Incorrect (explicitly prohibited):

```text
1. Write audio documentation.
2. Fix reader.
3. Investigate Lighthouse.
4. Search more FSB banks.
5. Investigate unresolved references.
6. Design audio extraction architecture.
7. Eventually return to 1C.
```

## 56. Example of correct reverse-engineering behaviour

Three independent event decodings resolving to semantically correct names is strong evidence the
FCompactIndex interpretation is right. Document `Status: VERIFIED`, `Evidence: three independent
event/name resolutions`, `Sample data: NOT LOCATED`. Do not claim "weapon audio extraction works" —
the reference is decoded, the sample storage is not.

## 57. Self-check before changing code

1. What exactly did the user ask?
2. What is the stopping condition?
3. What code currently handles this?
4. What evidence supports my interpretation?
5. Which assumptions are verified?
6. What remains uncertain?
7. What is the smallest safe change?
8. What could this break?
9. How will I test it?
10. Am I accidentally expanding scope?

If #10 is yes: stop and narrow the work.

## 58. Self-check after changing code

```text
[ ] Requested task completed
[ ] No unnecessary files modified
[ ] No unrelated subsystem changed
[ ] Existing tests considered
[ ] New behaviour tested
[ ] Real data tested where applicable
[ ] Regression checked
[ ] No source data lost
[ ] No debug code left behind
[ ] Documentation updated
[ ] Important discoveries recorded
[ ] Unknowns clearly labelled
[ ] Deferred work not accidentally pursued
[ ] Diff reviewed
```

## 59. Final rules

1. Do not guess when evidence can be obtained.
2. Do not rewrite working systems without justification.
3. Make the smallest correct change.
4. Test real data whenever possible.
5. Never hide failures.
6. Record important discoveries, including negative results.
7. A discovery does not automatically expand the task.
8. When the user says move on, move on.
9. Capture discoveries; do not chase them.
10. Unknown is a valid answer.
11. A hypothesis stays labelled until evidence promotes it.
12. The repository should become progressively more knowledgeable, not more complicated.
13. Do not optimize for lines of code, files changed or apparent progress.
14. Optimize for correct, reproducible, maintainable progress.
15. When uncertain: investigate enough to establish the facts, document what was learned, and stop
    when the user's task is complete.

## 60. Standing instructions given directly by the user

Recorded here because they are binding and were previously only in chat. Each is a *user decision*,
not an engineering opinion — §2 applies, so none of them may be overridden by an agent's judgement
that the work looks worthwhile.

### Deliberately deferred — do not "fix" these

- **Bulk extraction size (~140 GB).** "Extract all shown" from the default view is ~2,000 assets and
  many hours. The remaining bulk is animation track data written twice — once as floats in the scene
  JSON, once in the per-animation FBX. Omitting the tracks from the JSON when FBX is also selected is
  the obvious fix and was **explicitly deferred**. So were a size warning before a large job and
  keeping the UI responsive during one.
- **Unreal / UE5 import has never been run** and the user has repeatedly excluded it. Do not start it
  unless asked. The UI must not offer a UE5 export, because that would claim a verification that does
  not exist.
- **Phase 2 (level extraction) is unlocked once Phase 1C is finished** — the user has confirmed this
  directly. Until then it must not begin. 1C's remaining item is the Asset Inspector; when that lands,
  Phase 1 is frozen and Phase 2 may start. Groundwork already exists in
  `src/BioShockStudio.Core/Level/` — **read it before writing anything new**, and do not treat the
  unlock as permission to rewrite what is there.

### Process instructions

- **Read the reference projects before deriving from bytes.** `UModel-master/`, `hk2012_2_0_r1/`,
  `Bioshock1REMSDK-WIP--main/`, `Unreal-Library-master/` are in the repo root and gitignored. This is
  policy because it keeps paying: the first-person hand blocker cost three sessions of internal
  measurement and was settled by one function in the Havok SDK; the static section table came from
  Nyko's SDK after this project failed to find it from bytes; the DXT5N texture format came from
  UModel, *against* Nyko's note. See `docs/research/reference-comparison.md`.
- **Render it.** Numeric validation has passed on visibly wrong output more than once in this
  project's history. A reader is not finished until something has been drawn from it and looked at.
- **Update `docs/HANDOFF.md` before finishing any substantial task**, including failed approaches.
  If a discovery exists only in chat, it does not exist.
- **Do not commit unless asked.**
- **Do not use subagents or workflows unless asked.**

### Audio — current standing state

Investigated and **closed** at the user's instruction. The event→sound-name chain is decoded and
documented in `docs/research/audio.md`; where sound-effect sample data ships is `UNKNOWN`. The
deferred items in that note are deferred, not queued: do not resume audio work unless asked.

---

## Master operating principle

Be curious enough to discover the truth, disciplined enough not to chase every discovery, and
rigorous enough to prove what you claim.
