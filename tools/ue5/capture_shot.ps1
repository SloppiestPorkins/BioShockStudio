<#
.SYNOPSIS
  Photograph a prepared BioShock map from inside the running game.

.DESCRIPTION
  Every visual defect in this project so far was found by a person opening the editor, never by a
  check. The headless verifies run under -run=pythonscript with a Null RHI and cannot render a
  pixel, so a level whose every wall painted one flat average colour passed all fourteen of them.

  The -game harness already runs on D3D12. This drives AShockGameMode's -bioshockscreenshot path:
  possess as normal, wait for shaders to compile and textures to stream, take one screenshot, exit.

  The map must already carry ShockGameMode and a PlayerStart -- i.e. it has been through
  verify_possess / play_slice at least once. /Game/BioShockSlice/1-Medical qualifies.

.EXAMPLE
  .\capture_shot.ps1
  .\capture_shot.ps1 -Map /Game/BioShockLevel/1-Medical -Out C:\shots\raw.png -SettleTicks 24
#>
[CmdletBinding()]
param(
  [string]$Map = '/Game/BioShockSlice/1-Medical',
  [string]$Out = '',
  [string]$Engine = 'G:\Games\UE_5.7',
  [string]$Project = 'C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject',
  # 12 ticks x 0.5s = 6s of settle. Raise it on a cold DDC: a shot taken before the shaders finish
  # shows default materials, which looks exactly like the bug this harness is meant to catch.
  [int]$SettleTicks = 12,
  [double]$Interval = 0.5,
  [int]$TimeoutSeconds = 900,
  # Extra switches passed straight through to the game, e.g.
  #   -Extra '-bioshockvmrot=90,0,0','-bioshockvmoffset=28,10,-24'
  # Framing the viewmodel is a look-at-it judgement, and the only way to look at it headlessly is
  # this harness -- so the values worth trying must not each cost a plugin rebuild.
  [string[]]$Extra = @()
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Out)) {
  $leaf = ($Map -split '/')[-1]
  $Out = Join-Path (Split-Path $Project -Parent) "Exports\shots\$leaf.png"
}
$outDir = Split-Path $Out -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force $outDir | Out-Null }
if (Test-Path $Out) { Remove-Item $Out -Force }

$ueCmd = Join-Path $Engine 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
$log = Join-Path $outDir 'capture_shot.log'
$url = "$Map`?game=/Script/BioShockRuntime.ShockGameMode"

Write-Output "map     : $Map"
Write-Output "out     : $Out"
Write-Output "settle  : $SettleTicks ticks x ${Interval}s"

# No -nullrhi: the whole point is that this one renders.
$args = @(
  $Project, $url, '-game', '-bioshockscreenshot',
  "-bioshockshotpath=$Out",
  "-bioshockshotsettle=$SettleTicks",
  "-bioshockshotinterval=$Interval",
  '-unattended', '-nopause', '-nosplash', '-log', "-abslog=$log"
) + $Extra
if ($Extra.Count) { Write-Output "extra   : $($Extra -join ' ')" }

# NOT Minimized: a minimised game window can present an empty backbuffer, so the shot comes back
# black and reads as "the level is unlit" when it is really "nothing was drawn".
$proc = Start-Process -FilePath $ueCmd -ArgumentList $args -PassThru
if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
  Write-Output "TIMEOUT after ${TimeoutSeconds}s - killing"
  try { $proc.Kill() } catch {}
}

if (Test-Path $Out) {
  $size = [math]::Round((Get-Item $Out).Length / 1KB)

  # Refuse to call a blank frame a success. The first version of this harness reported "SHOT OK"
  # on a uniformly black PNG - the exact class of false pass it was built to eliminate. A capture
  # that renders nothing must fail loudly, or it is worse than having no capture at all.
  $stats = & python -c @"
import sys
from PIL import Image, ImageStat
im = Image.open(r'$Out').convert('RGB')
st = ImageStat.Stat(im)
print('%.3f %.3f' % (sum(st.mean)/3.0, sum(st.stddev)/3.0))
"@ 2>$null
  if ($LASTEXITCODE -eq 0 -and $stats) {
    $mean, $sd = $stats.Trim() -split '\s+'
    Write-Output "frame   : mean=$mean stddev=$sd"
    if ([double]$sd -lt 1.0) {
      Write-Output "BLANK FRAME - captured image has no variation (stddev $sd). Not a valid shot."
      exit 2
    }
  }

  Write-Output "SHOT OK  $Out  (${size} KB)"
  exit 0
}

Write-Output "NO SHOT WRITTEN - see $log"
if (Test-Path $log) {
  Select-String -Path $log -Pattern 'BIOSHOCK_SCREENSHOT|BIOSHOCK_POSSESS|Error:' |
    Select-Object -Last 15 | ForEach-Object { "  " + $_.Line }
}
exit 1
