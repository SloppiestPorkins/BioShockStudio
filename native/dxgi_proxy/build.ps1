# Build the E1 proxy dxgi.dll (32-bit) into native/dxgi_proxy/bin/. Binaries are not committed.
#   powershell -File native/dxgi_proxy/build.ps1
# Install / remove next to the game:
#   powershell -File native/dxgi_proxy/build.ps1 -Install
#   powershell -File native/dxgi_proxy/build.ps1 -Uninstall
param([switch]$Install, [switch]$Uninstall,
  [string]$GameDir = 'G:\SteamLibrary\steamapps\common\BioShock Remastered\Build\Final')
$ErrorActionPreference = 'Stop'
$target = Join-Path $GameDir 'dxgi.dll'
if ($Uninstall) {
  if (Test-Path $target) { Remove-Item $target; "removed $target" } else { "nothing installed" }
  exit 0
}
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vs = & $vswhere -latest -property installationPath
if (-not $vs) { throw "Visual Studio not found" }
$here = $PSScriptRoot
$bin = Join-Path $here 'bin'
New-Item -ItemType Directory -Force $bin | Out-Null
$cmd = "`"$vs\VC\Auxiliary\Build\vcvars32.bat`" >nul && cl /nologo /O2 /MT /EHsc /W3 /LD `"$here\dxgi_proxy.cpp`" /Fe:`"$bin\dxgi.dll`" /Fo:`"$bin\\`" /link /DEF:`"$here\dxgi.def`" /SAFESEH:NO"
cmd /c $cmd
if ($LASTEXITCODE -ne 0) { throw "build failed" }
"built $bin\dxgi.dll"
if ($Install) {
  Copy-Item -Force (Join-Path $bin 'dxgi.dll') $target
  "installed $target"
}
