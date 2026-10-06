# A short scripted walk for live-bridge tests: forward, look around, forward again, back.
$gi = Join-Path $PSScriptRoot 'game_input.ps1'
$steps = @(
  @{ Key = 'W'; HoldMs = 3000; MouseDX = 0 },
  @{ Key = 'W'; HoldMs = 0; MouseDX = 1200 },
  @{ Key = 'W'; HoldMs = 3000; MouseDX = 0 },
  @{ Key = 'W'; HoldMs = 0; MouseDX = -2400 },
  @{ Key = 'W'; HoldMs = 4000; MouseDX = 0 },
  @{ Key = 'D'; HoldMs = 1500; MouseDX = 600 },
  @{ Key = 'S'; HoldMs = 2500; MouseDX = 0 },
  @{ Key = 'W'; HoldMs = 0; MouseDX = 1800 },
  @{ Key = 'W'; HoldMs = 4000; MouseDX = 0 }
)
foreach ($s in $steps) {
  & $gi -Key $s.Key -HoldMs $s.HoldMs -MouseDX $s.MouseDX | Out-Null
  Start-Sleep -Milliseconds 1500
}
