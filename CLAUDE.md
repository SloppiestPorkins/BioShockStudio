# CLAUDE.md

**Read `docs/ENGINEERING_RULES.md` in full before changing anything.** It is the canonical ruleset;
this file is the entry point, and it is deliberately short so the two cannot drift apart.

Then read, in this order:

1. `docs/HANDOFF.md` — the project's institutional memory. Authoritative and current. §4 is the list
   of landmines that have already cost real time; §7 is the project's own working rules.
2. `docs/research/ANIMATION_COORDINATE_SYSTEM.md` — the basis policy. Every transform depends on it.
3. `docs/research/README.md`, then the research note for whatever you are touching.
4. `docs/research/reference-comparison.md` — what each reference project says about the structures we
   read, and where they disagree. **Read the reference projects before deriving from bytes.**

## The rules that get broken most often

Full text in `docs/ENGINEERING_RULES.md`; these are the ones worth having in front of you.

- **Make the smallest correct, tested change.** Not the most code, not the most investigation.
- **User scope beats agent curiosity.** "Write it up and move on" means stop, document, and move on —
  not keep pulling the thread because a new clue appeared. §55 has a worked example of getting this
  exactly wrong.
- **Work a roadmap in order — no jumping around.** Take the next undone item in `docs/ROADMAP.md`
  Part 2 sequentially and finish it *fully* before starting another. §60 "Roadmap discipline".
- **Capture discoveries; do not chase them.** `DISCOVER → VERIFY → RECORD → DEFER → CONTINUE`.
- **Never guess when the bytes can be inspected**, and never promote a hypothesis to a fact. Label
  confidence, always.
- **Never trust a single sample.** A structure that works in one package may be package-local — this
  has already happened.
- **Every reverse-engineered structure gets a regression test against real game bytes.** There are no
  synthetic fixtures.
- **Render it.** Numeric validation has passed on visibly wrong output more than once here.
- **Unknown is a valid answer.** A truthful partial result beats a plausible wrong one.
- **Never claim success without evidence.** "Resolves correctly, sample storage not located" is a
  better sentence than "audio works".

## Baseline

The suite is split into two tiers, because a ten-minute suite changes how carefully changes get
verified:

```bash
dotnet build
dotnet test --filter Tier=Fast                       # ~40s — run this constantly, while working
dotnet test --filter "FullyQualifiedName~<Class>"    # minutes — the sweep classes your diff touches
dotnet test --filter Tier=Sweep                      # ~19min — only when the diff reaches shared code
dotnet test                                          # both; only when reporting a whole-suite total
```

**Do not re-run the full suite to re-confirm a figure another session just measured.** Standing user
instruction — `docs/ENGINEERING_RULES.md` §60 "Test-run economy". Read the verification stamp at the
top of `docs/ROADMAP.md` "Test health" first: it names the commit the suite was last green at, so
`git diff --stat <stamp>..HEAD` tells you the only thing that needs re-running. An unrun tier is
reported as unrun, never as passing.

**The split is by how much real data a test reads, never by faking any.** There are no synthetic
fixtures and this does not introduce one: a fast test still reads real shipped bytes, just from one
package instead of all 33. Every test class declares its tier and `TierCoverageTests` fails if one
does not, so nothing can fall out of both tiers and stop running.

Tests read the installed game. Close the app before `dotnet publish` — a running instance locks the
DLLs. Do not commit unless asked.
