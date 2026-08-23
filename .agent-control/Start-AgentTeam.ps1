$ErrorActionPreference = "Stop"

$AgentRoot = "C:\Users\Jack\Documents\BioshockHavok-agents"

$Agents = @(
    "research",
    "coder",
    "tester",
    "reviewer"
)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " STARTING LOCAL AI TEAM" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($Agent in $Agents) {

    $Launcher = Join-Path $AgentRoot "$Agent\.agent\Start-LocalClaude.ps1"

    Write-Host "Starting $Agent agent..." -ForegroundColor Green

    if (-not (Test-Path -LiteralPath $Launcher)) {
        Write-Host "ERROR: Launcher not found:" -ForegroundColor Red
        Write-Host $Launcher -ForegroundColor Red
        continue
    }

    Start-Process `
        -FilePath "powershell.exe" `
        -ArgumentList @(
            "-NoExit",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            "`"$Launcher`""
        )

    Start-Sleep -Milliseconds 1000
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " ALL AGENT WINDOWS LAUNCHED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Research -> Local Qwen"
Write-Host "Coder    -> Local Qwen"
Write-Host "Tester   -> Local Qwen"
Write-Host "Reviewer -> Local Qwen"
Write-Host ""
Write-Host "Ollama will serialize inference for the RTX 4070."
Write-Host ""
