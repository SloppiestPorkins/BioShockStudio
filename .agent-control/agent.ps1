param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("research", "code", "test", "review", "status", "result", "diff", "list", "pipeline", "log")]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Argument = "",

    # Comma-separated, NOT a PowerShell array parameter: this script is always invoked as
    # `powershell -File agent.ps1 ...` (an external-process call), which parses raw argv
    # text rather than PowerShell array syntax - "a","b","c" arrives as the single string
    # a,b,c, not a 3-element array. Confirmed directly (23 Aug 2026): a [string[]] param
    # here silently collapsed a real 4-file dispatch into one not-found path and the coder
    # produced an empty diff. Split on comma ourselves instead of relying on PS binding.
    [string]$Files = "",
    [string]$Parent = "",
    [string]$Context = "",
    [string]$Grep = "",
    [string]$Glob = "",
    [string]$TestFilter = "",
    [int]$TimeoutMinutes = 0,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$Global:ControlRoot = $PSScriptRoot
. (Join-Path $Global:ControlRoot "lib\Controller.ps1")

$FilesArray = @()
if ($Files) { $FilesArray = @($Files -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }

$RoleForCommand = @{ research = "research"; code = "coder"; test = "tester"; review = "reviewer" }

function Format-TaskRow {
    param($T)
    $dur = if ($T.durationSeconds) { "{0}s" -f $T.durationSeconds } else { "-" }
    "{0,-28} | {1,-9} | {2,-9} | {3}" -f $T.id, $T.role, $T.status, $dur
}

switch ($Command) {

    { $_ -in @("research", "code", "test", "review") } {
        if (-not $Argument) { throw "Usage: agent.ps1 $Command `"<task description>`" [-Files a.cs,b.cs] [-Parent TASK-ID] [-Context '...'] [-Grep pattern] [-Glob *.cs] [-TestFilter Tier=Fast] [-TimeoutMinutes N] [-SkipBuild]" }
        $role = $RoleForCommand[$Command]
        $result = Invoke-AgentTask -RoleName $role -TaskText $Argument -Files $FilesArray -Parent $Parent -Context $Context `
            -Grep $Grep -Glob $Glob -TimeoutMinutesOverride $TimeoutMinutes -TestFilter $TestFilter -SkipBuild:$SkipBuild
        Write-Host ""
        Write-Host "Task ID: $($result.id)   Status: $($result.status)"
        if ($result.status -eq "COMPLETE") {
            Write-Host "Read the result with:  powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 result $($result.id)"
        }
    }

    "status" {
        $config = Get-AgentConfig
        Write-Host "TASKS" -ForegroundColor Cyan
        $tasks = Get-AllTasks
        if (-not $tasks) { Write-Host "  (none yet)" }
        foreach ($t in $tasks) { Write-Host ("  " + (Format-TaskRow $t)) }
        Write-Host ""
        Write-Host "GPU LOCK" -ForegroundColor Cyan
        if (Test-Path $Script:LockFile) {
            Write-Host ("  BUSY: " + (Get-Content -LiteralPath $Script:LockFile -ErrorAction SilentlyContinue | Select-Object -First 1))
        } else {
            Write-Host "  free"
        }
        Write-Host ""
        Write-Host "WORKTREES" -ForegroundColor Cyan
        foreach ($roleName in $config.roles.PSObject.Properties.Name) {
            $wt = $config.roles.$roleName.worktree
            $dirty = Get-WorktreeDirty -WorktreePath $wt
            $state = if ($dirty) { "DIRTY" } else { "clean" }
            $color = if ($dirty) { "Yellow" } else { "Gray" }
            Write-Host ("  {0,-10} {1,-6} {2}" -f $roleName, $state, $wt) -ForegroundColor $color
        }
    }

    "list" {
        $tasks = Get-AllTasks
        foreach ($t in $tasks) {
            Write-Host (Format-TaskRow $t)
            $taskLine = $t.task
            if ($taskLine.Length -gt 100) { $taskLine = $taskLine.Substring(0, 100) + "..." }
            Write-Host "    $taskLine" -ForegroundColor DarkGray
        }
    }

    "result" {
        if (-not $Argument) { throw "Usage: agent.ps1 result <TASK-ID>" }
        $t = Load-Task -Id $Argument
        if (-not $t) { throw "No such task: $Argument" }
        if (Test-Path -LiteralPath $t.resultPath) {
            Get-Content -Raw -LiteralPath $t.resultPath
        } else {
            $line = "No result file. Status: " + $t.status
            if ($t.error) { $line = $line + " - " + $t.error }
            Write-Host $line
        }
    }

    "log" {
        if (-not $Argument) { throw "Usage: agent.ps1 log <TASK-ID>" }
        $t = Load-Task -Id $Argument
        if (-not $t) { throw "No such task: $Argument" }
        if (Test-Path -LiteralPath $t.logPath) { Get-Content -Raw -LiteralPath $t.logPath } else { Write-Host "No log yet." }
    }

    "diff" {
        if (-not $Argument) { throw "Usage: agent.ps1 diff <TASK-ID>" }
        $t = Load-Task -Id $Argument
        if (-not $t) { throw "No such task: $Argument" }
        if ($t.role -ne "coder") { Write-Host "Task $Argument is role '$($t.role)', not coder - nothing to diff."; return }
        Write-Host "=== git status ($($t.worktree)) ===" -ForegroundColor Cyan
        & git -C $t.worktree status --short -- ":(exclude).agent"
        Write-Host ""
        Write-Host "=== diffstat ===" -ForegroundColor Cyan
        & git -C $t.worktree diff --stat
        Write-Host ""
        Write-Host "=== full diff ===" -ForegroundColor Cyan
        & git -C $t.worktree diff
    }

    "pipeline" {
        if (-not $Argument) { throw "Usage: agent.ps1 pipeline `"<goal>`"" }
        $result = Invoke-AgentTask -RoleName "research" -TaskText $Argument -Files $FilesArray -Parent $Parent -Context $Context `
            -Grep $Grep -Glob $Glob -TimeoutMinutesOverride $TimeoutMinutes
        Write-Host ""
        Write-Host "Research dispatched as $($result.id), status=$($result.status)." -ForegroundColor Cyan
        Write-Host "Pipeline stops here by design - read the evidence, then the lead decides whether to continue:"
        Write-Host "  powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 result $($result.id)"
        Write-Host "  powershell -ExecutionPolicy Bypass -File .agent-control\agent.ps1 code `"...`" -Parent $($result.id)"
    }
}
