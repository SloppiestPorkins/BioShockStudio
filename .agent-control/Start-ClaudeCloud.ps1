$ErrorActionPreference = "Stop"

# Remove Ollama routing ONLY from this process so Claude Code
# connects normally to Anthropic.
Remove-Item -Path "Env:ANTHROPIC_BASE_URL" -ErrorAction SilentlyContinue
Remove-Item -Path "Env:ANTHROPIC_AUTH_TOKEN" -ErrorAction SilentlyContinue
Remove-Item -Path "Env:ANTHROPIC_API_KEY" -ErrorAction SilentlyContinue

Set-Location -LiteralPath "C:\Users\Jack\Documents\BioshockHavok"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " REAL ANTHROPIC CLAUDE CODE - LEAD AGENT" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "Repository:" -ForegroundColor Gray
Write-Host "C:\Users\Jack\Documents\BioshockHavok" -ForegroundColor Green
Write-Host ""

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Claude Code was not found in PATH." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host "Starting Anthropic Claude Code..." -ForegroundColor Cyan
Write-Host ""

& claude

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Claude Code exited with code $LASTEXITCODE" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to close"
