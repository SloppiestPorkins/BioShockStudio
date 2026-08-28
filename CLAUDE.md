# CLAUDE.md

**Read `docs/ENGINEERING_RULES.md` in full before changing anything.** It is the canonical ruleset;
this file is the entry point, and it is deliberately short so the two cannot drift apart.

**Starting a Cursor chat:** do not re-survey the whole repo. Use the pattern in
`docs/NEXT_SESSION.md` §"How to start in Cursor" — one Gate item named in the first message, Fast
tier only, claim table before touching shared files. Full rule: `ENGINEERING_RULES.md` §60
"Cursor session start".

**Two agents, split by file.** `docs/DUAL_AGENT_ROADMAP.md` (`ENGINEERING_RULES.md` §61): Cursor
owns `tools/ue5/**` and the UE5 runtime; Claude Code owns `src/**` / `tests/**` and the C# tool.
Stay in your lane; the `docs/HANDOFF.md` claim table still governs any shared file.

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
