[CmdletBinding()]
param(
  [string]$Repo = 'C:\Users\Jack\Documents\BioshockHavok',
  [string]$Map = '1-Medical',
  [string]$ExportRoot = 'C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\Rigs'
)

# The character / animated-prop rig textures on disk are stale 64x64 stubs, exported before the
# bulk-catalog fix (commit a8aa54a). export-fbx now recovers the real 2048 top mips from
# ContentBaked/pc/BulkContent. Re-run it for every SkeletalMesh the slice places, writing over
# the existing Rigs/<name>/ dirs, then import_rig_textures.py re-imports the PNGs into UE.

$ErrorActionPreference = 'Stop'
$dll = Join-Path $Repo 'src\BioShockStudio.Cli\bin\Release\net8.0\BioShockStudio.Cli.dll'
$manifest = 'C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\1-Medical.ue5-level.json'

$assets = (Get-Content $manifest -Raw | ConvertFrom-Json).assets |
  Where-Object { $_.kind -eq 'SkeletalMesh' -and $_.group }

$ok = 0; $failed = @()
foreach ($a in $assets) {
  $dir = Join-Path $ExportRoot $a.name
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  Write-Host "export-fbx $($a.name) (UAPW_$($a.group))"
  & dotnet $dll export-fbx $Map "UAPW_$($a.group)" $dir --mesh $a.name 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) { $ok++ } else { $failed += $a.name }
}
Write-Host "re-exported $ok rigs, failed: $($failed -join ', ')"
if ($failed.Count -gt 0) { exit 1 }
