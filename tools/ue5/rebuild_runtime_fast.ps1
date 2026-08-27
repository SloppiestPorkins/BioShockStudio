# Fast incremental rebuild of BioShockRuntime for the throwaway UE5.7 project.
# Prefer this over RunUAT BuildPlugin (~10 min full package) during iteration.
#
# Usage:
#   powershell -File tools/ue5/rebuild_runtime_fast.ps1
#   powershell -File tools/ue5/rebuild_runtime_fast.ps1 -CleanModule   # ~50s full module recompile
#
# Typical times (Win64 Development, HostProject Intermediate warm):
#   no C++ change:     ~5-10s  (UBT up-to-date + binary copy)
#   1-3 .cpp edits:    ~15-40s (incremental)
#   -CleanModule:      ~50s    (all BioShockRuntime TUs)
#   RunUAT BuildPlugin: ~10min (do NOT use for daily C++ tweaks)
#
# First-time / wiped PluginBuild: run BuildPlugin once to seed HostProject, then this script.

param(
  [switch]$CleanModule
)

$ErrorActionPreference = 'Stop'

$EngineRoot = 'G:\Games\UE_5.7'
$UeProject = 'C:\Users\Jack\Documents\BioShockUE5'
$RepoPlugin = 'C:\Users\Jack\Documents\BioshockHavok\tools\ue5\BioShockRuntime'
$LivePlugin = Join-Path $UeProject 'Plugins\BioShockRuntime'
$HostProject = Join-Path $UeProject 'PluginBuild\BioShockRuntime\HostProject'
$HostPlugin = Join-Path $HostProject 'Plugins\BioShockRuntime'
$Ubt = Join-Path $EngineRoot 'Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll'
$DotNet = Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\DotNet\8.0.412\win-x64\dotnet.exe'

if (-not (Test-Path $Ubt)) { throw "UBT missing: $Ubt" }
if (-not (Test-Path $HostProject)) {
  throw "HostProject missing at $HostProject - run RunUAT BuildPlugin once, then use this script."
}

# Refuse to run if a leftover BuildPlugin still owns HostProject (causes hung file copies).
$lockers = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
  $_.CommandLine -and ($_.CommandLine -match 'AutomationTool.*BuildPlugin' -or $_.CommandLine -match 'HostProject.*BioShockRuntime')
}
if ($lockers) {
  $ids = ($lockers | ForEach-Object { $_.ProcessId }) -join ', '
  throw "BuildPlugin / HostProject process still running (pids $ids). Kill it, then retry."
}

function Sync-SourceTree {
  param([string]$FromRoot, [string]$ToRoot)
  $fromSrc = Join-Path $FromRoot 'Source'
  $toSrc = Join-Path $ToRoot 'Source'
  if (-not (Test-Path $fromSrc)) { throw "Missing source: $fromSrc" }
  New-Item -ItemType Directory -Force -Path $toSrc | Out-Null
  Get-ChildItem -Path $fromSrc -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($fromSrc.Length).TrimStart('\')
    $dest = Join-Path $toSrc $rel
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    Copy-Item -Force $_.FullName $dest
  }
  Copy-Item -Force (Join-Path $FromRoot 'BioShockRuntime.uplugin') (Join-Path $ToRoot 'BioShockRuntime.uplugin')
}

Write-Host 'Sync Source -> live plugin...'
Sync-SourceTree -FromRoot $RepoPlugin -ToRoot $LivePlugin
Write-Host 'Sync Source -> HostProject plugin...'
Sync-SourceTree -FromRoot $RepoPlugin -ToRoot $HostPlugin

if ($CleanModule) {
  $modBuild = Join-Path $HostPlugin 'Intermediate\Build'
  if (Test-Path $modBuild) {
    Write-Host 'CleanModule: removing HostProject plugin Intermediate\Build...'
    Remove-Item -Recurse -Force $modBuild
  }
}

$HostUproject = Join-Path $HostProject 'HostProject.uproject'
$HostUplugin = Join-Path $HostPlugin 'BioShockRuntime.uplugin'
$sw = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host 'UBT UnrealEditor Win64 Development (incremental)...'
& $DotNet $Ubt UnrealEditor Win64 Development `
  "-Project=$HostUproject" `
  "-plugin=$HostUplugin" `
  -noubtmakefiles `
  -NoHotReloadFromIDE
$ubtExit = $LASTEXITCODE
Write-Host ("UBT finished in {0:n1}s exit={1}" -f $sw.Elapsed.TotalSeconds, $ubtExit)
if ($ubtExit -ne 0) { exit $ubtExit }

$srcBin = Join-Path $HostPlugin 'Binaries\Win64'
$dstBin = Join-Path $LivePlugin 'Binaries\Win64'
New-Item -ItemType Directory -Force -Path $dstBin | Out-Null
Copy-Item -Force (Join-Path $srcBin '*') $dstBin
Write-Host "Copied binaries -> $dstBin"
Write-Host ("Total {0:n1}s" -f $sw.Elapsed.TotalSeconds)
exit 0
