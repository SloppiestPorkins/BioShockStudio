<#
.SYNOPSIS
  Run the UE5 slice as a live view of the original game (UShockLiveBridge), offscreen by default.

.EXAMPLE
  .\live_view.ps1 -Seconds 120 -CaptureDir C:\shots\live
  (then run tools/livegame/live_bridge.py against the running BioshockHD.exe)
#>
[CmdletBinding()]
param(
  [string]$Map = '/Game/BioShockSlice/1-Medical',
  [int]$Port = 7781,
  [double]$Seconds = 120,
  [string]$CaptureDir = '',
  [double]$CaptureEvery = 1.0,
  [string]$Engine = 'G:\Games\UE_5.7',
  [string]$Project = 'C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject',
  [switch]$Visible,
  # With -Visible: the window's size (the bridge's --overlay then lays it over the game window).
  [int]$ResX = 0,
  [int]$ResY = 0
)
$ErrorActionPreference = 'Stop'
$guardPy = Join-Path $PSScriptRoot '..\ue5\ue_guard.py'
$busy = & python $guardPy check --for capture
if ($LASTEXITCODE -ne 0) { Write-Output ($busy -join ' '); exit 1 }

$ueCmd = Join-Path $Engine 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
$logDir = if ($CaptureDir) { $CaptureDir } else { Join-Path $env:TEMP 'bioshock-live' }
New-Item -ItemType Directory -Force $logDir | Out-Null
$log = Join-Path $logDir 'live_view.log'
# A plain GameModeBase: this project's own gameplay (ShockGameMode, AI, scripts) must not fight
# the original game, which is the one actually playing.
$url = "$Map`?game=/Script/Engine.GameModeBase"
$args = @($Project, $url, '-game', "-bioshocklive=$Port", "-bioshockliveseconds=$Seconds",
  '-unattended', '-nopause', '-nosplash', '-nosound', '-log', "-abslog=$log")
if ($CaptureDir) { $args += @("-bioshocklivecapture=$CaptureDir", "-bioshocklivecapevery=$CaptureEvery") }
if (-not $Visible) { $args += @('-RenderOffscreen', '-ResX=1280', '-ResY=720') }
elseif ($ResX -gt 0 -and $ResY -gt 0) { $args += @('-windowed', "-ResX=$ResX", "-ResY=$ResY") }

$held = & python $guardPy acquire --for capture --task "live_view $Map" --owner-pid $PID
if ($LASTEXITCODE -ne 0) { Write-Output ($held -join ' '); exit 1 }
try {
  $proc = Start-Process -FilePath $ueCmd -ArgumentList $args -PassThru
  try { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal } catch {}
} catch {
  & python $guardPy release --owner-pid $PID | Out-Null
  throw
}
& python $guardPy adopt --owner-pid $PID --new-pid $proc.Id | Out-Null
$proc.WaitForExit(([int]$Seconds + 600) * 1000) | Out-Null
if (-not $proc.HasExited) { try { $proc.Kill() } catch {} ; $proc.WaitForExit(60000) | Out-Null }
& python $guardPy release --owner-pid $proc.Id | Out-Null
Select-String -Path $log -Pattern 'BIOSHOCK_LIVE' | Select-Object -Last 8 | ForEach-Object { $_.Line }
