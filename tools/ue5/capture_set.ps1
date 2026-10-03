<#
.SYNOPSIS
  Capture every viewpoint in a named set with capture_shot.ps1, then build a contact sheet and a
  diff against the baseline captures.

.DESCRIPTION
  A visual bug is only fixed when a rendered frame from the spot the user reported shows it fixed.
  capture_shot.ps1 takes one frame; this takes a whole set of them (tools/ue5/viewpoints/<set>.json)
  one Unreal at a time, records which ones came back ok / blank / missing / busy, and runs
  capture_report.py over the run so every frame lands on one contact sheet with its verdict.

  capture_shot.ps1 is called in-process with a real string array for -Extra. Going through
  "powershell -File capture_shot.ps1 -Extra a,b" from another shell hands it one comma-joined string
  (or rejects it), which silently drops the camera switches and photographs the PlayerStart instead.

  Captures and baselines are copyrighted game imagery. They live under the local UE project
  (C:\Users\Jack\Documents\BioShockUE5\Captures, committed there with git LFS) and never inside the
  public BioshockHavok repo; the script refuses an -OutDir or -BaselineDir inside this repo.

  Only one Unreal process may run against the project. Before each shot the script asks ue_guard.py
  (shared lock file + live Unreal/UBT processes; a scan for UnrealEditor* processes if the guard is
  unavailable) and records that viewpoint as "busy" instead of launching a second. capture_shot.ps1
  itself takes the shared lock for the length of the game process.

  Viewpoint JSON: { "set", "map" (optional), "viewpoints": [ { "name", "abs":[x,y,z],
  "look":[x,y,z] and/or "yaw"/"pitch" (degrees added to the look direction, or to the PlayerStart
  view when there is no look), "extra":[switches], "why", "validated" } ] }.

  Exit 0 when every shot is ok and capture_report.py found no blank / near-black / missing frame,
  1 otherwise.

.EXAMPLE
  # PowerShell
  .\capture_set.ps1 -Set medical
  .\capture_set.ps1 -Set medical -Only arrival-porthole-steinman,lobby-red-wash -DryRun
  .\capture_set.ps1 -Set medical -UpdateBaseline

.EXAMPLE
  # Git Bash. -Only is one comma-separated string so it survives -File.
  powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/capture_set.ps1 -Set medical
  powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/capture_set.ps1 -Set medical -Only "arrival-porthole-steinman,lobby-red-wash"
#>
[CmdletBinding()]
param(
  # A set name (tools/ue5/viewpoints/<name>.json) or a path to a viewpoint JSON file.
  [Parameter(Mandatory = $true)][string]$Set,
  # Viewpoint names to capture, comma-separated and/or as an array. Default: all of them.
  [string[]]$Only = @(),
  # Default: C:\Users\Jack\Documents\BioShockUE5\Captures\<set>\<yyyyMMdd-HHmmss>
  [string]$OutDir = '',
  # Default: C:\Users\Jack\Documents\BioShockUE5\Captures\baseline\<set>
  [string]$BaselineDir = '',
  # Floor 24 (12 s): a cold DDC still shows default materials at the capture_shot default of 12,
  # which looks exactly like the material bugs this exists to catch.
  [int]$SettleTicks = 24,
  # Copy this run's ok shots into the baseline folder after the report.
  [switch]$UpdateBaseline,
  # Print what would run; launch nothing.
  [switch]$DryRun,
  # The single-shot script. Only changed to exercise this runner without Unreal.
  [string]$ShotScript = ''
)

$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
$capturesRoot = 'C:\Users\Jack\Documents\BioShockUE5\Captures'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
$minSettle = 24

function Resolve-FullPath([string]$p) {
  [IO.Path]::GetFullPath($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p))
}

function Test-UnderRepo([string]$p) {
  ($p.TrimEnd('\') + '\').StartsWith($repoRoot + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Format-Num($v) { ([double]$v).ToString('0.###', $inv) }

function Format-Vec($v, [string]$label, [string]$name) {
  $a = @($v)
  if ($a.Count -ne 3) { throw "viewpoint '$name': $label must be [x, y, z], got $($a -join ',')" }
  ($a | ForEach-Object { Format-Num $_ }) -join ','
}

function Get-ShotExtra($vp) {
  $x = New-Object System.Collections.Generic.List[string]
  if ($null -ne $vp.abs) { $x.Add('-bioshockshotabs=' + (Format-Vec $vp.abs 'abs' $vp.name)) }
  if ($null -ne $vp.look) { $x.Add('-bioshockshotlook=' + (Format-Vec $vp.look 'look' $vp.name)) }
  if ($null -ne $vp.yaw) { $x.Add('-bioshockshotyaw=' + (Format-Num $vp.yaw)) }
  if ($null -ne $vp.pitch) { $x.Add('-bioshockshotpitch=' + (Format-Num $vp.pitch)) }
  foreach ($e in @($vp.extra)) { if ($e) { $x.Add([string]$e) } }
  , $x.ToArray()
}

# One-line reason Unreal is busy, or $null when free. ue_guard.py also sees the shared lock file and
# UBT/UAT, so it is asked first; the process scan covers a checkout without it or without Python.
function Get-BusyReason {
  $guardPy = Join-Path $PSScriptRoot 'ue_guard.py'
  if (Test-Path -LiteralPath $guardPy) {
    try {
      $global:LASTEXITCODE = 0
      $out = & python $guardPy check --for capture
      if ($LASTEXITCODE -eq 0) { return $null }
      if ($LASTEXITCODE -eq 1) { return (@($out) -join ' ') }
    } catch {}
  }
  $procs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'UnrealEditor*' })
  if ($procs.Count) {
    return 'Unreal already running: ' + (($procs | ForEach-Object { "$($_.ProcessName) pid $($_.Id)" }) -join ', ')
  }
  $null
}

function Write-Utf8([string]$path, [string]$text) {
  [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding $false))
}

# --- resolve the set -------------------------------------------------------------------------------
if ($Set -match '\.json$' -or (Test-Path -LiteralPath $Set -PathType Leaf)) {
  $setPath = Resolve-FullPath $Set
} else {
  $setPath = Join-Path $PSScriptRoot "viewpoints\$Set.json"
}
if (-not (Test-Path -LiteralPath $setPath -PathType Leaf)) {
  Write-Host "No viewpoint set '$Set' ($setPath). Available:"
  Get-ChildItem (Join-Path $PSScriptRoot 'viewpoints') -Filter *.json -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Host "  $($_.BaseName)" }
  exit 1
}
$def = Get-Content -LiteralPath $setPath -Raw -Encoding UTF8 | ConvertFrom-Json
$setName = if ($def.set) { [string]$def.set } else { [IO.Path]::GetFileNameWithoutExtension($setPath) }
if ($setName -notmatch '^[A-Za-z0-9._-]+$') { Write-Host "Set name '$setName' is not a safe folder name."; exit 1 }

$all = @($def.viewpoints)
$seen = @{}
foreach ($vp in $all) {
  if (-not $vp.name -or [string]$vp.name -notmatch '^[A-Za-z0-9._-]+$') {
    Write-Host "Viewpoint name '$($vp.name)' in $setPath is missing or not a safe file name."; exit 1
  }
  if ($seen.ContainsKey([string]$vp.name)) { Write-Host "Duplicate viewpoint '$($vp.name)' in $setPath."; exit 1 }
  $seen[[string]$vp.name] = $true
}

$wanted = @($Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$viewpoints = $all
if ($wanted.Count) {
  $unknown = @($wanted | Where-Object { -not $seen.ContainsKey($_) })
  if ($unknown.Count) {
    Write-Host "Unknown viewpoint(s): $($unknown -join ', '). In '$setName': $(($all | ForEach-Object { $_.name }) -join ', ')"
    exit 1
  }
  $viewpoints = @($all | Where-Object { $wanted -contains [string]$_.name })
}
if (-not $viewpoints.Count) { Write-Host "Set '$setName' has no viewpoints."; exit 1 }

# --- paths and settings ----------------------------------------------------------------------------
if (-not $OutDir) { $OutDir = Join-Path $capturesRoot "$setName\$((Get-Date).ToString('yyyyMMdd-HHmmss'))" }
if (-not $BaselineDir) { $BaselineDir = Join-Path $capturesRoot "baseline\$setName" }
$OutDir = Resolve-FullPath $OutDir
$BaselineDir = Resolve-FullPath $BaselineDir
foreach ($pair in @(@('-OutDir', $OutDir), @('-BaselineDir', $BaselineDir))) {
  if (Test-UnderRepo $pair[1]) {
    Write-Host "$($pair[0]) $($pair[1]) is inside the public repo $repoRoot. Captures are copyrighted game"
    Write-Host "imagery and belong under $capturesRoot (the local UE repo, git LFS)."
    exit 1
  }
}
if (-not $ShotScript) { $ShotScript = Join-Path $PSScriptRoot 'capture_shot.ps1' }
$ShotScript = Resolve-FullPath $ShotScript
$reportScript = Join-Path $PSScriptRoot 'capture_report.py'
if ($SettleTicks -lt $minSettle) {
  Write-Host "settle  : $SettleTicks raised to $minSettle (a cold DDC still shows default materials before then)"
  $SettleTicks = $minSettle
}
$map = if ($def.map) { [string]$def.map } else { '' }

Write-Host "set      : $setName ($setPath)"
Write-Host "shots    : $($viewpoints.Count) of $($all.Count)"
Write-Host "out      : $OutDir"
Write-Host "baseline : $BaselineDir$(if (-not (Test-Path -LiteralPath $BaselineDir)) { ' (none yet)' })"
Write-Host "settle   : $SettleTicks ticks"
if ($map) { Write-Host "map      : $map" }
if ($DryRun) { Write-Host 'DRY RUN - nothing is launched' }

if (-not $DryRun) { New-Item -ItemType Directory -Force $OutDir | Out-Null }

# --- capture, strictly one Unreal at a time ---------------------------------------------------------
$results = New-Object System.Collections.Generic.List[object]
$i = 0
foreach ($vp in $viewpoints) {
  $i++
  $name = [string]$vp.name
  $png = Join-Path $OutDir "$name.png"
  $extra = Get-ShotExtra $vp
  $shotArgs = @{ Out = $png; SettleTicks = $SettleTicks; Extra = $extra }
  if ($map) { $shotArgs.Map = $map }

  $shown = "& '$ShotScript' -Out '$png' -SettleTicks $SettleTicks"
  if ($map) { $shown += " -Map '$map'" }
  $shown += " -Extra @(" + (($extra | ForEach-Object { "'$_'" }) -join ', ') + ')'
  Write-Host ''
  Write-Host "[$i/$($viewpoints.Count)] $name$(if ($vp.validated -eq $false) { '  (not yet validated)' })"
  Write-Host "  $shown"
  if ($DryRun) { continue }

  $started = Get-Date
  $lines = New-Object System.Collections.Generic.List[string]
  $code = $null
  $busy = Get-BusyReason
  if ($busy) {
    $status = 'busy'
    $lines.Add($busy)
    Write-Host "  BUSY - $busy"
    Write-Host '  Not launching a second Unreal.'
  } else {
    $global:LASTEXITCODE = 0
    # 'Continue' so an error-stream line from the shot script is recorded rather than ending the
    # whole set; anything that really throws still lands in the catch.
    $ErrorActionPreference = 'Continue'
    try {
      & $ShotScript @shotArgs 2>&1 | ForEach-Object { $s = "$_"; $lines.Add($s); Write-Host "    $s" }
      $code = $LASTEXITCODE
    } catch {
      $lines.Add("capture_shot threw: $_")
      Write-Host "    capture_shot threw: $_"
      $code = -1
    }
    $ErrorActionPreference = 'Stop'
    $text = $lines -join "`n"
    if ($code -eq 0 -and (Test-Path -LiteralPath $png)) { $status = 'ok' }
    elseif ($code -eq 2) { $status = 'blank' }
    elseif ($code -eq -1) { $status = 'error' }
    # Only capture_shot's own refusal line counts as busy (anchored), never words inside the UE
    # log tail it echoes on a failed shot ("device busy" there is a render failure, not contention).
    elseif ($text -match '(?im)^BUSY \(capture\):') { $status = 'busy' }
    elseif (-not (Test-Path -LiteralPath $png)) { $status = 'no shot' }
    else { $status = 'error' }
  }

  # capture_shot writes capture_shot.log next to the PNG; keep one log per viewpoint.
  $log = Join-Path $OutDir 'capture_shot.log'
  $vpLog = $null
  if (Test-Path -LiteralPath $log) {
    $vpLog = Join-Path $OutDir "$name.log"
    Move-Item -LiteralPath $log -Destination $vpLog -Force
  }

  $results.Add([pscustomobject]@{
    name      = $name
    status    = $status
    exitCode  = $code
    png       = $(if (Test-Path -LiteralPath $png) { $png } else { $null })
    log       = $vpLog
    extra     = @($extra)
    validated = $vp.validated
    seconds   = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
  })
  Write-Host "  -> $status"
}

$reportCmd = "python '$reportScript' '$OutDir'"
if (Test-Path -LiteralPath $BaselineDir) { $reportCmd += " --baseline '$BaselineDir'" }
if ($DryRun) {
  Write-Host ''
  Write-Host "then     : $reportCmd"
  if ($UpdateBaseline) { Write-Host "then     : copy the ok shots into $BaselineDir" }
  exit 0
}

Write-Utf8 (Join-Path $OutDir 'capture_set.json') ((@{
  set         = $setName
  setFile     = $setPath
  map         = $map
  settleTicks = $SettleTicks
  baselineDir = $BaselineDir
  finishedAt  = (Get-Date).ToString('s')
  viewpoints  = $results.ToArray()
}) | ConvertTo-Json -Depth 6)

# --- report ---------------------------------------------------------------------------------------
Write-Host ''
Write-Host "report   : $reportCmd"
$reportArgs = @($reportScript, $OutDir)
if (Test-Path -LiteralPath $BaselineDir) { $reportArgs += @('--baseline', $BaselineDir) }
$global:LASTEXITCODE = 0
# Windows PowerShell turns each redirected stderr line of a native command into a terminating
# error under 'Stop', so a single Python warning would abort the run here.
$ErrorActionPreference = 'Continue'
try {
  & python @reportArgs 2>&1 | ForEach-Object { Write-Host "  $_" }
  $reportCode = $LASTEXITCODE
} catch {
  Write-Host "  capture_report.py could not run: $_"
  $reportCode = -1
}
$ErrorActionPreference = 'Stop'

$failedByReport = @()
$reportJson = Join-Path $OutDir 'report.json'
if (Test-Path -LiteralPath $reportJson) {
  $failedByReport = @((Get-Content -LiteralPath $reportJson -Raw -Encoding UTF8 | ConvertFrom-Json).failed)
}

# --- baseline -------------------------------------------------------------------------------------
if ($UpdateBaseline) {
  New-Item -ItemType Directory -Force $BaselineDir | Out-Null
  $copied = 0
  foreach ($r in $results) {
    if ($r.status -eq 'ok' -and $r.png -and ($failedByReport -notcontains $r.name)) {
      Copy-Item -LiteralPath $r.png -Destination (Join-Path $BaselineDir "$($r.name).png") -Force
      $copied++
    }
  }
  Write-Host ''
  Write-Host "baseline : $copied shot(s) copied to $BaselineDir"
  Write-Host '           commit them in the UE repo (git LFS), never in BioshockHavok.'
}

# --- summary --------------------------------------------------------------------------------------
Write-Host ''
Write-Host 'SUMMARY'
foreach ($r in $results) {
  $note = if ($failedByReport -contains $r.name -and $r.status -eq 'ok') { '  (report: near-black)' } else { '' }
  Write-Host ("  {0,-34} {1}{2}" -f $r.name, $r.status, $note)
}
$bad = @($results | Where-Object { $_.status -ne 'ok' })
Write-Host "contact sheet: $(Join-Path $OutDir 'contact_sheet.png')"
Write-Host 'Read the PNGs before calling anything fixed: a frame that is not blank is not a frame that looks right.'
if ($bad.Count -or $reportCode -ne 0) {
  Write-Host "CAPTURE SET FAILED - $($bad.Count) shot(s) not ok$(if ($reportCode -ne 0) { ", report exit $reportCode" })"
  exit 1
}
Write-Host "CAPTURE SET OK - $($results.Count) shot(s)"
exit 0
