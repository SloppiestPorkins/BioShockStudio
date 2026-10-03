# Claude Code skills and hook for this project

Source of truth for the user-level Claude Code pieces that drive this repo. Claude Code reads the
installed copies under `~/.claude/` (sessions usually start in `C:\Users\Jack\Documents\AI Test`,
so project-level `.claude/` folders here would never load). Edit here, then reinstall.

| piece | what it does |
|---|---|
| `skills/ue-run/` | loads before any headless Unreal run, plugin rebuild or "is Unreal running" check: use `tools/ue5/ue_run.py`, read its verdict, one Unreal process at a time |
| `skills/visual-done/` | loads for any visual bug or user screenshot: done means a rendered capture from the reported spot, read by Claude (`tools/ue5/capture_shot.ps1` / `capture_set.ps1`) |
| `hooks/bioshock_repo_guard.py` | SessionStart: notes unpushed/uncommitted work and orphan worktrees. Stop: warns (once per change) about unpushed BioshockHavok commits or an uncommitted UE project |

Install or update (Git Bash, from the repo root):

```bash
mkdir -p ~/.claude/skills ~/.claude/hooks
cp -r tools/claude/skills/ue-run tools/claude/skills/visual-done ~/.claude/skills/
cp tools/claude/hooks/bioshock_repo_guard.py ~/.claude/hooks/
python tools/ue5/gen_ue_reference.py ~/.claude/skills/ue-run/references
```

The hook is registered in `~/.claude/settings.json` under `hooks.SessionStart` and `hooks.Stop` as
`python C:/Users/Jack/.claude/hooks/bioshock_repo_guard.py --mode sessionstart|stop`.
Regenerate `skills/ue-run/references/` after adding UE-Python scripts or `-bioshock*` switches.
