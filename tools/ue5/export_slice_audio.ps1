param(
    [string]$Package = "1-Medical",
    [string]$OutDir = "C:\Users\Jack\Documents\BioShockUE5\Exports\slice\1-Medical\Audio"
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$project = Join-Path $repo "src\BioShockStudio.Cli"
$logDir = Join-Path $env:TEMP "bioshock_audio_export"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if (Get-Process UnrealEditor, UnrealEditor-Cmd -ErrorAction SilentlyContinue) {
    throw "Close Unreal Editor before exporting/importing slice audio."
}

Write-Host "Exporting $Package audio to $OutDir"
& dotnet run --project $project -c Release -- `
    export-audio $Package $OutDir --locate 2>&1 |
    Tee-Object -FilePath (Join-Path $logDir "$Package.log")
if ($LASTEXITCODE -ne 0) {
    throw "export-audio failed with exit code $LASTEXITCODE"
}

$manifest = Join-Path $OutDir "ue5_audio_manifest.json"
if (-not (Test-Path $manifest)) {
    throw "export-audio did not write $manifest"
}

# English VO is stored in the map's `_int` package. `export-audio --locate` records its
# container but deliberately does not copy another package's payloads, so materialize that
# package beside the slice-native waves for the UE importer.
$waveDir = Join-Path $OutDir "waves"
& dotnet run --project $project -c Release -- `
    export-sounds "${Package}_int" $waveDir 2>&1 |
    Tee-Object -FilePath (Join-Path $logDir "${Package}_int.log")
if ($LASTEXITCODE -ne 0) {
    throw "English localized audio export failed with exit code $LASTEXITCODE"
}

Write-Host "Audio export ready: $manifest"
