# START HERE

Coordination layer for the research / coding / testing / review agent team. **Read only what your
role needs** — the table below is a budget, not a suggestion. Local workers run at a 32k context
window and the full `.agent/` set is ~22k tokens; reading it all leaves no room to work.

`docs/` is ~11,900 lines. **Do not read it wholesale.** These files exist so you don't have to.

## Reading budget by role

| Role | Read | ≈ tokens |
|---|---|---|
| **Research** | `PROJECT_STATE.md` §1–5, `KNOWN_ASSUMPTIONS.md` (only your area's entries), your task in `TASK_QUEUE.md`, the one `OPEN_QUESTIONS.md` entry | ~6k |
| **Coder** | `KNOWN_ASSUMPTIONS.md` (your area), `ARCHITECTURE.md` §2–3 (your module only), your task, the accepted research report | ~6k |
| **Tester** | `PROJECT_STATE.md` §6 (baseline), `ARCHITECTURE.md` §5 (test structure), `AGENT_PROTOCOL.md` §7 (test-run economy), your task | ~5k |
| **Reviewer** | the diff, `KNOWN_ASSUMPTIONS.md` (touched areas), `AGENT_PROTOCOL.md` §8 (definition of done) | ~5k |

Everyone: `AGENT_PROTOCOL.md` §1–3 is the short rules core. If you read one thing beyond your task,
read that.

## The files

| File | What it is | Size |
|---|---|---|
| `PROJECT_STATE.md` | what works, what is broken, measured build/test baseline, repo map, priority | ~4.1k |
| `KNOWN_ASSUMPTIONS.md` | **the guardrail.** 21 things not to change casually, each with evidence and a safe-to-change verdict | ~4.9k |
| `AGENT_PROTOCOL.md` | role boundaries, evidence rules, reporting format, lead workflow, context rules, definition of done | ~2.8k |
| `TASK_QUEUE.md` | the work. Take a task; do not invent one | ~3.7k |
| `ARCHITECTURE.md` | module map, pipelines, exact paths, Agent Impact Map | ~3.7k |
| `OPEN_QUESTIONS.md` | 10 unresolved questions, each with next step and suited agent | ~2.7k |
| `CHANGELOG_AGENT.md` | who did what, under which task, accepted or not | ~0.4k |
| `reports/` | per-task agent reports | — |

## The four rules that matter most

1. **Read the `KNOWN_ASSUMPTIONS.md` entry for what you are about to touch, first.** Several of
   those cost multiple sessions to establish and at least two were originally wrong in a way that
   looked right.
2. **No assumption changes because "the output looks better."** Binary-format work needs byte-level
   evidence and more than one sample.
3. **Do not hide a failing test.** Never relax an assertion or edit an expected number to get green.
   Classify first (`docs/ENGINEERING_RULES.md` §24).
4. **Unknown is a valid answer.** A truthful partial result beats a plausible wrong one.

## Current state in one line

Build clean; Fast tier 243/243; **full suite 546/550 — 4 failing, see TASK-000, which is the first
task and blocks the rest.**

---

`docs/ENGINEERING_RULES.md` remains the canonical ruleset and wins on any conflict with these files.
`.agent-control/` is the user's launcher setup and is not part of this layer.
