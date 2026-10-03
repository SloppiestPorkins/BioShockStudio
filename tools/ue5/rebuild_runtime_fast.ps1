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
# First-time / wiped PluginBuild: run tools/ue5/seed_hostproject.ps1, then this script.
#
# The last line is always exactly one of "Result: Succeeded" or "FAILED: <reason>". UBT's own
# "Result:" line is relabelled "UBT Result:" so a grep for the verdict cannot match it.

param(
  [switch]$CleanModule
)

$ErrorActionPreference = 'Stop'

$guardPy = Join-Path $PSScriptRoot 'ue_guard.py'
$script:FailCode = 1
trap {
  try { & python $guardPy release --owner-pid $PID | Out-Null } catch {}
  Write-Host "FAILED: $($_.Exception.Message)"
  exit $script:FailCode
}

# Refuse BEFORE compiling while any Unreal process is alive: an open editor holds the plugin DLL,
# so the compile would run for minutes and then fail on the copy. Never kill it - report and stop.
# The shared lock (ue_guard.py) also keeps ue_run / capture_shot from starting mid-rebuild.
$guard = & python $guardPy acquire --for rebuild --task 'rebuild_runtime_fast' --owner-pid $PID
if ($LASTEXITCODE -ne 0) {
  Write-Host ("FAILED: " + (($guard -join ' ') -replace '^BUSY \(rebuild\): ', ''))
  exit 1
}
if ($guard) { $guard | ForEach-Object { Write-Host $_ } }

# finally (not just the trap) releases the lock: Ctrl+C skips traps but runs finally blocks, and
# an in-process run's owner pid is the interactive shell, which would otherwise hold it until closed.
try {

$EngineRoot = 'G:\Games\UE_5.7'
$UeProject = 'C:\Users\Jack\Documents\BioShockUE5'
# Resolve from this script so git worktrees sync their own BioShockRuntime, not a hardcoded main checkout.
$RepoPlugin = Join-Path $PSScriptRoot 'BioShockRuntime'
$LivePlugin = Join-Path $UeProject 'Plugins\BioShockRuntime'
$HostProject = Join-Path $UeProject 'PluginBuild\BioShockRuntime\HostProject'
$HostPlugin = Join-Path $HostProject 'Plugins\BioShockRuntime'
$Ubt = Join-Path $EngineRoot 'Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll'
$DotNet = Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\DotNet\8.0.412\win-x64\dotnet.exe'

if (-not (Test-Path $Ubt)) { throw "UBT missing: $Ubt" }
if (-not (Test-Path $HostProject)) {
  throw "HostProject missing at $HostProject - run tools/ue5/seed_hostproject.ps1, then use this script."
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
  $want = @{}
  Get-ChildItem -Path $fromSrc -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($fromSrc.Length).TrimStart('\')
    $want[$rel] = $true
    $dest = Join-Path $toSrc $rel
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    Copy-Item -Force $_.FullName $dest
  }
  # Purge stale files a previous (e.g. parallel worktree) build left behind — Copy-Item never
  # deletes, so a removed/renamed .cpp would otherwise keep compiling from the mirror.
  Get-ChildItem -Path $toSrc -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $rel = $_.FullName.Substring($toSrc.Length).TrimStart('\')
    if (-not $want.ContainsKey($rel)) { Remove-Item -Force $_.FullName }
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
  -NoHotReloadFromIDE | ForEach-Object { if ($_ -match '^\s*Result: ') { "UBT $($_.Trim())" } else { $_ } }
$ubtExit = $LASTEXITCODE
Write-Host ("UBT finished in {0:n1}s exit={1}" -f $sw.Elapsed.TotalSeconds, $ubtExit)
if ($ubtExit -ne 0) {
  $script:FailCode = $ubtExit
  throw "UBT compile failed (exit $ubtExit) - see the compiler errors above"
}

$srcBin = Join-Path $HostPlugin 'Binaries\Win64'
$dstBin = Join-Path $LivePlugin 'Binaries\Win64'
New-Item -ItemType Directory -Force -Path $dstBin | Out-Null
Copy-Item -Force (Join-Path $srcBin '*') $dstBin
Write-Host "Copied binaries -> $dstBin"
Write-Host ("Total {0:n1}s" -f $sw.Elapsed.TotalSeconds)
} finally {
  & python $guardPy release --owner-pid $PID | Out-Null
}
Write-Host 'Result: Succeeded'
exit 0
