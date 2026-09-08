[CmdletBinding()]
param(
  [string]$Engine = 'G:\Games\UE_5.7',
  [string]$Project = 'C:\Users\Jack\Documents\BioShockUE5\BioShockUE5.uproject'
)

$ErrorActionPreference = 'Stop'
$ue = Join-Path $Engine 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
$script = Join-Path $PSScriptRoot 'repair_ragdoll_physics.py'
$manifest = Join-Path (Split-Path $Project -Parent) 'Exports\slice\1-Medical\1-Medical.ue5-level.json'
$report = Join-Path $env:TEMP 'repair_ragdoll_physics.json'

# One rig per editor process. UE5.7's async loader can assert when a second skeletal reimport
# follows deletion/replacement of the first rig's packages in the same commandlet.
$rigs = @(
  'Agg_Doctor_Mesh',
  'Agg_LadySmith',
  'CorpseCrispy',
  'CorpseFemale',
  'CorpseMale',
  # Restore the combat mesh last. All source exports unfortunately call their FBX object
  # AggressorBabyJane; unique folder overrides above prevent them from overwriting this package.
  'Agg_BabyJane'
)

foreach ($rig in $rigs) {
  $env:BIOSHOCK_RAGDOLL_MANIFEST = $manifest
  $env:BIOSHOCK_RAGDOLL_IMPORT_RIG = $rig
  $log = Join-Path $env:TEMP "repair_ragdoll_import_$rig.log"
  & $ue $Project -run=pythonscript "-script=$script" -unattended -nopause -nosplash -nullrhi "-abslog=$log"
  if ($LASTEXITCODE -ne 0) {
    throw "ragdoll rig import failed for $rig (exit $LASTEXITCODE; $log)"
  }
  Copy-Item $report (Join-Path $env:TEMP "repair_ragdoll_import_$rig.json") -Force
}

Remove-Item Env:BIOSHOCK_RAGDOLL_IMPORT_RIG -ErrorAction SilentlyContinue
& $ue $Project -run=pythonscript "-script=$script" -unattended -nopause -nosplash -nullrhi `
  "-abslog=$(Join-Path $env:TEMP 'repair_ragdoll_physics.log')"
if ($LASTEXITCODE -ne 0) {
  throw "ragdoll placement repair failed (exit $LASTEXITCODE)"
}
