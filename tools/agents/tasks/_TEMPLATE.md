---
worker: chatgpt
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: src/**, tests/**, docs/research/**
---
Copy this file to tasks/<short-id>.md and replace this text with the instructions for the worker.

Frontmatter keys:
  worker   chatgpt | qwen | deepseek | cursor      (deepseek is the reliable local one here)
  base     branch or sha the worktree is cut from  (usually main)
  verify   command run in the worktree after the edit; its exit code becomes PASS/FAIL
  lane     glob(s) the worker must stay inside; also written into the prompt

Write the task the way you would brief a competent engineer who cannot ask questions:
  - the exact file(s) to create or change
  - the shape of the result (types, method names, what it returns)
  - one or two concrete values to check against
  - what NOT to touch

Keep one task = one landable change. The orchestrator captures the diff as a patch; you review it
with `orchestrator.ps1 status`, apply the good ones with `apply -Task <id>`, commit by hand, then
create tasks/<id>.done so it is not re-run.
