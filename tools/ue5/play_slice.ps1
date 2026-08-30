# Prep the 1-Medical playable slice, then tell you what to do next.
# Run with the UE editor CLOSED (it rebuilds BioShockRuntime and the editor locks the DLL).
# PowerShell 5.1, execution policy Restricted -> invoke as:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\ue5\play_slice.ps1

$Engine = 'G:\Games\UE_5.7'
$UeProject = 'C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject'
$UeCmd = Join-Path $Engine 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
$Ue5Dir = $PSScriptRoot
$Log = Join-Path $env:TEMP ('play_slice_{0:yyyyMMdd_HHmmss}.log' -f (Get-Date))

function Invoke-UeScript([string]$ScriptName) {
  $script = Join-Path $Ue5Dir $ScriptName
  # UE's stderr becomes ErrorRecords under PS; keep it out of the failure path.
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  & $UeCmd $UeProject '-run=pythonscript' "-script=$script" '-unattended' '-nopause' '-nosplash' 2>&1 |
    Tee-Object -FilePath $Log -Append | Out-Host
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  return $code
}

$editor = Get-Process UnrealEditor -ErrorAction SilentlyContinue
if ($editor) {
  Write-Warning "UnrealEditor is running (pid $($editor.Id)). Close it, then re-run."
  exit 1
}

Write-Host '== 1/3  Rebuild BioShockRuntime ============================='
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Ue5Dir 'rebuild_runtime_fast.ps1')
if ($LASTEXITCODE -ne 0) { Write-Host "rebuild failed ($LASTEXITCODE)" -ForegroundColor Red; exit 1 }

Write-Host "`n== 2/3  Prep the slice (archetypes, menu, Fire/Reload, textures) ="
$setupCode = Invoke-UeScript 'setup_playable_slice.py'
$report = Join-Path $env:TEMP 'bioshock_slice_setup_report.json'
if (Test-Path $report) {
  $r = Get-Content $report -Raw | ConvertFrom-Json
  foreach ($s in $r.steps) {
    $mark = if ($s.ok) { 'ok  ' } else { 'FAIL' }
    Write-Host ("   {0}  {1}" -f $mark, $s.step)
  }
  Write-Host ("   -> {0} ok / {1} failed" -f $r.ok, $r.failed)
}

Write-Host "`n== 3/3  End-to-end check (headless -game launch of 1-Medical) ="
$null = Invoke-UeScript 'run_game_possess.py'
$vrp = 'C:\Users\Jack\Documents\BioShockUE5\Exports\slice\game_possess_report.json'
if (Test-Path $vrp) {
  $vr = Get-Content $vrp -Raw | ConvertFrom-Json
  Write-Host ("   possess={0}  fire={1}  health {2}->{3}  failures=[{4}]" -f `
    $vr.possessPrep, $vr.slice.fire, $vr.slice.health_before, $vr.slice.health_after, ($vr.failures -join ','))
}

Write-Host ''
Write-Host @'
NEXT:
  1. Open the editor:
     & "G:\Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor.exe" "C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject"
  2. Let it finish compiling shaders / the plugin (bottom-right progress).
  3. It should open the MainMenu map. Play In Editor (Alt+P), click Play on the menu.
     (Or open /Game/BioShockSlice/1-Medical from the Content Browser and Alt+P.)
  4. WASD move / mouse look / LMB fire / R reload. Enemies spawn ~1.5s apart.

If it still misbehaves: right after the bad Play, send
  C:\Users\Jack\Documents\BioShockUE5\Saved\Logs\BioShockUE5.log
'@
Write-Host "`nFull log: $Log"
