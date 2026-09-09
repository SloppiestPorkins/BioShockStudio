<#
  Export the 1-Medical pickup / container / mover / station prop meshes (FBX + textures) so
  import_slice_prop_meshes.py can bring them in and the placeholder marker spheres go away.

  Run OUTSIDE the editor (dotnet only). Names come from docs/research/runtime-brain.md §8 /
  the manifest `staticMesh` fields on the placeholder actors.
#>
param(
  [string]$Repo = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
  [string]$Map  = "1-Medical",
  [string]$OutRoot = "C:\Users\Jack\Documents\BioShockUE5\Exports\props"
)

$dll = Join-Path $Repo 'src\BioShockStudio.Cli\bin\Release\net8.0\BioShockStudio.Cli.dll'
if (-not (Test-Path $dll)) {
  Write-Host "building CLI..."
  & dotnet build (Join-Path $Repo 'src\BioShockStudio.Cli') -c Release | Out-Null
}

$meshes = @(
  'bio_bandages','Ammo_Pickup_JHP','Ammo_HighExplosiveBuck','Log','Med','PU_credits',
  'register_closed','plasmid_pickup','Health','tommygun_ammo_standard','tommygun_ammo_frozen',
  'PotatoChips_DownMarket','powerbar_moxie','autohack_device','Lowend','Highend','Whiskey',
  'WP_AI_Pistol','Beer_Bottle','Cakes_UpMarket','Single_Wine_Bottle','coffee_thermos',
  'decor_fridgedoorsmall','decor_fridgedoorbig','Turret_Cover','MA_plasmidgrowth_DropBox',
  'key_card','bottle_gin','PU_TommyGunMESH','4_poster_cover_front','Pickup'
)

$ok = 0; $fail = @()
foreach ($m in $meshes) {
  $dir = Join-Path $OutRoot $m
  Write-Host "export-staticmesh $Map $m"
  & dotnet $dll export-staticmesh $Map $m $dir 2>&1 | Out-Null
  if (Test-Path (Join-Path $dir 'ue5_manifest.json')) { $ok++ } else { $fail += $m }
}
Write-Host "exported $ok / $($meshes.Count)"
if ($fail.Count) { Write-Host "FAILED: $($fail -join ', ')" }
