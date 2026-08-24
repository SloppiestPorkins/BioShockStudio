# Backup agent: runs the queued tasks in tools/backup-agent/task-*.md through aider, driven by the
# local Ollama models, so BioshockHavok work can continue when Claude usage runs out.
#
# SAFETY MODEL: aider never commits (--no-auto-commits, set in ../.aider.conf.yml). Every task's
# edits land in the working tree only. Review the diff yourself (or wait for Claude) before
# committing anything. auto-test runs the fast tier after each edit so an obviously broken change
# is visible immediately, but it does not replace a real review.
#
# Usage: run from anywhere; it always operates on this checkout of BioshockHavok.
#   powershell -File tools\backup-agent\run.ps1
#
# Runs tasks in filename order (task-01-*, task-02-*, ...) and stops if one leaves the tree with a
# failing fast-tier run, rather than piling a second task's edits on top of a broken one.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$aider = "C:\Users\Jack\.backup-agent-venv\Scripts\aider.exe"
$logDir = Join-Path $repoRoot "tools\backup-agent\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

Set-Location $repoRoot
$env:OLLAMA_API_BASE = "http://localhost:11434"

$tasks = Get-ChildItem -Path (Join-Path $repoRoot "tools\backup-agent") -Filter "task-*.md" | Sort-Object Name

foreach ($task in $tasks) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFile = Join-Path $logDir "$($task.BaseName)-$stamp.log"
    Write-Host "=== Running $($task.Name) -- log: $logFile ==="

    & $aider --message-file $task.FullName *>&1 | Tee-Object -FilePath $logFile

    $status = git status --short
    if ([string]::IsNullOrWhiteSpace($status)) {
        Write-Host "=== $($task.Name) made no changes -- check the log, something may have gone wrong ==="
    } else {
        Write-Host "=== $($task.Name) finished. Uncommitted changes are waiting for review: ==="
        git status --short
    }

    $testResult = dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast 2>&1
    $testResult | Out-File -Append $logFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "=== Fast tier failed after $($task.Name). Stopping here rather than starting the next task on a broken tree. ==="
        Write-Host "=== Review $logFile and the working tree before continuing. ==="
        exit 1
    }
}

Write-Host "=== All queued tasks attempted. Nothing was committed -- review tools/backup-agent/logs and 'git diff' before committing anything. ==="
