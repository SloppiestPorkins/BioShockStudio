
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " NVIDIA GPU" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

nvidia-smi

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " OLLAMA RUNNING MODELS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

ollama ps

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " INSTALLED MODELS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

ollama list

Write-Host ""

