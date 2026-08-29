# Seed (or refresh) the BioShockRuntime HostProject used by rebuild_runtime_fast.ps1.
#
# RunUAT BuildPlugin creates HostProject under -Package, then deletes it unless
# -NoDeleteHostProject is set (UE 5.7 BuildPluginCommand.Automation.cs). This script
# always passes that flag so PluginBuild\BioShockRuntime\HostProject stays warm.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools/ue5/seed_hostproject.ps1
#   powershell -ExecutionPolicy Bypass -File tools/ue5/seed_hostproject.ps1 -Force
#
# Idempotent: if HostProject.uproject exists, Intermediate is warm, and Source+uplugin
# match the repo plugin, prints that and exits 0. -Force rebuilds anyway.

param(
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

$EngineRoot = 'G:\Games\UE_5.7'
$UeProject = 'C:\Users\Jack\Documents\BioShockUE5'
# Same SoT path as rebuild_runtime_fast.ps1 (keep in lockstep).
$RepoPlugin = 'C:\Users\Jack\Documents\BioshockHavok\tools\ue5\BioShockRuntime'
$PackageDir = Join-Path $UeProject 'PluginBuild\BioShockRuntime'
$HostProject = Join-Path $PackageDir 'HostProject'
$HostPlugin = Join-Path $HostProject 'Plugins\BioShockRuntime'
$HostUproject = Join-Path $HostProject 'HostProject.uproject'
$RunUat = Join-Path $EngineRoot 'Engine\Build\BatchFiles\RunUAT.bat'
$Uplugin = Join-Path $RepoPlugin 'BioShockRuntime.uplugin'
$LogDir = Join-Path $env:TEMP 'BioShockHostProjectSeed'
$LogFile = Join-Path $LogDir ("seed_hostproject_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

function Get-SourceFingerprint {
  param([string]$PluginRoot)
  $src = Join-Path $PluginRoot 'Source'
  $uplugin = Join-Path $PluginRoot 'BioShockRuntime.uplugin'
  if (-not (Test-Path $src)) { return $null }
  $parts = New-Object System.Collections.Generic.List[string]
  if (Test-Path $uplugin) {
    $fi = Get-Item $uplugin
    $parts.Add(("uplugin|{0}|{1}" -f $fi.Length, $fi.LastWriteTimeUtc.Ticks))
  }
  Get-ChildItem -Path $src -Recurse -File | Sort-Object FullName | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length).TrimStart('\').ToLowerInvariant()
    $parts.Add(("{0}|{1}|{2}" -f $rel, $_.Length, $_.LastWriteTimeUtc.Ticks))
  }
  return ($parts -join "`n")
}

function Test-HostProjectWarm {
  if (-not (Test-Path $HostUproject)) { return $false }
  if (-not (Test-Path (Join-Path $HostPlugin 'BioShockRuntime.uplugin'))) { return $false }
  $intermediate = Join-Path $HostPlugin 'Intermediate\Build'
  if (-not (Test-Path $intermediate)) { return $false }
  # Need at least one object under Intermediate so UBT has a warm cache.
  $any = Get-ChildItem -Path $intermediate -Recurse -File -ErrorAction SilentlyContinue |
    Select-Object -First 1
  return ($null -ne $any)
}

if (-not (Test-Path $RunUat)) { throw "RunUAT missing: $RunUat" }
if (-not (Test-Path $Uplugin)) { throw "Plugin missing: $Uplugin" }

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

if (-not $Force -and (Test-HostProjectWarm)) {
  $repoFp = Get-SourceFingerprint -PluginRoot $RepoPlugin
  $hostFp = Get-SourceFingerprint -PluginRoot $HostPlugin
  if ($repoFp -and $hostFp -and ($repoFp -eq $hostFp)) {
    Write-Host "HostProject already valid and Source unchanged at $HostProject"
    Write-Host 'Nothing to do (use -Force to re-run BuildPlugin).'
    exit 0
  }
  if ($repoFp -ne $hostFp) {
    Write-Host 'HostProject exists but Source differs from repo plugin; re-seeding...'
  }
}
elseif (-not $Force) {
  Write-Host "HostProject missing or Intermediate cold at $HostProject; seeding..."
}
else {
  Write-Host 'Force: re-running BuildPlugin to refresh HostProject...'
}

# -NoDeleteHostProject: keep HostProject after packaging (UE 5.7 BuildPlugin).
# -NoTargetPlatforms: editor host build only — enough for rebuild_runtime_fast.ps1;
#   skips UnrealGame Dev/Shipping per platform (~much faster seed).
$pluginArg = "-Plugin=`"$Uplugin`""
$packageArg = "-Package=`"$PackageDir`""
$uatArgs = @(
  'BuildPlugin',
  $pluginArg,
  $packageArg,
  '-NoDeleteHostProject',
  '-NoTargetPlatforms',
  '-HostPlatforms=Win64'
)

Write-Host "RunUAT $($uatArgs -join ' ')"
Write-Host "Log: $LogFile"
$sw = [System.Diagnostics.Stopwatch]::StartNew()
& cmd.exe /c "`"$RunUat`" $($uatArgs -join ' ') 2>&1" | Tee-Object -FilePath $LogFile
$uatExit = $LASTEXITCODE
Write-Host ("BuildPlugin finished in {0:n1}s exit={1}" -f $sw.Elapsed.TotalSeconds, $uatExit)
if ($uatExit -ne 0) {
  throw "RunUAT BuildPlugin failed (exit $uatExit). See $LogFile"
}

if (-not (Test-Path $HostUproject)) {
  throw "BuildPlugin completed but HostProject.uproject missing at $HostUproject (NoDeleteHostProject may have failed)."
}
if (-not (Test-HostProjectWarm)) {
  throw "HostProject exists but Intermediate is still cold at $HostPlugin\Intermediate\Build"
}

Write-Host "HostProject ready: $HostProject"
Write-Host 'Next: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1'
exit 0
