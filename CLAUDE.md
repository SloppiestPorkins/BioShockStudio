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

```bash
dotnet build && dotnet test
```

Tests read the installed game; there are no synthetic fixtures. Close the app before
`dotnet publish` — a running instance locks the DLLs. Do not commit unless asked.
