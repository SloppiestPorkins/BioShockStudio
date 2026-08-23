
$ErrorActionPreference = "Stop"


$env:ANTHROPIC_AUTH_TOKEN = "ollama"

$env:ANTHROPIC_BASE_URL =
    "http://127.0.0.1:11434"


Set-Location -LiteralPath "C:\Users\Jack\Documents\BioshockHavok"


Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " LOCAL CLAUDE CODE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Model:"
Write-Host "qwen3-coder:30b" -ForegroundColor Green

Write-Host ""

Write-Host "Repository:"
Write-Host "C:\Users\Jack\Documents\BioshockHavok" -ForegroundColor Green

Write-Host ""


claude 
    --model "qwen3-coder:30b"

