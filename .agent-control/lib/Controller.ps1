# Controller.ps1 - shared functions for agent.ps1.
# Dot-sourced by agent.ps1, which sets $Global:ControlRoot before sourcing this file.

$ErrorActionPreference = "Stop"

$Script:ConfigPath = Join-Path $Global:ControlRoot "agent-config.json"
$Script:TasksDir   = Join-Path $Global:ControlRoot "tasks"
$Script:ResultsDir = Join-Path $Global:ControlRoot "results"
$Script:LogsDir    = Join-Path $Global:ControlRoot "logs"
$Script:LockFile   = Join-Path $Global:ControlRoot ".gpu.lock"

foreach ($d in @($Script:TasksDir, $Script:ResultsDir, $Script:LogsDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

$Script:ProtocolCore = @"
Binding rules (condensed from .agent/AGENT_PROTOCOL.md - the full file is the canonical version):
- Inspect before editing. Do not modify any file outside what this task names.
- Do not perform broad refactors. The smallest correct change for the stated goal only.
- Never silently change a binary-format / reverse-engineering assumption without byte-level evidence
  from THIS task's own context. If you were not given the evidence, say the assumption is unverified
  rather than changing it.
- Disclose uncertainty explicitly. "Unknown" or "not verified here" is a valid, preferred answer over
  a guess stated as fact.
- Never claim success without evidence. If you were not given real test/build output, say so - do not
  invent it.
- Do not attempt to commit, merge, push, or run any destructive git command. You have no shell access
  in this call; do not narrate running commands you did not actually run.
- This is a SINGLE non-interactive turn. You cannot ask a follow-up question, run a tool, or read a
  file that was not included in your context below. Work only from what is given; state plainly what
  you could not check.
"@

function Get-AgentConfig {
    Get-Content -Raw -LiteralPath $Script:ConfigPath | ConvertFrom-Json
}

function Test-SafeRelativePath {
    param([string]$RelPath)
    if ([string]::IsNullOrWhiteSpace($RelPath)) { return $false }
    if ($RelPath -match '\.\.') { return $false }
    if ($RelPath -match '^[a-zA-Z]:') { return $false }
    if ($RelPath.StartsWith('\') -or $RelPath.StartsWith('/')) { return $false }
    return $true
}

function New-TaskId {
    param([string]$Role)
    $roleTag = switch ($Role) {
        "research" { "RES" }
        "coder"    { "COD" }
        "tester"   { "TST" }
        "reviewer" { "REV" }
        default    { $Role.Substring(0, [Math]::Min(3, $Role.Length)).ToUpper() }
    }
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $id = "TASK-$stamp-$roleTag"
    $taskPath = Join-Path $Script:TasksDir "$id.json"
    if (Test-Path $taskPath) {
        $id = "$id-$([guid]::NewGuid().ToString('N').Substring(0,4))"
    }
    return $id
}

function Save-Task {
    param($Task)
    $path = Join-Path $Script:TasksDir "$($Task.id).json"
    ($Task | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $path -Encoding utf8
}

function Load-Task {
    param([string]$Id)
    $path = Join-Path $Script:TasksDir "$Id.json"
    if (-not (Test-Path $path)) { return $null }
    Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
}

function Get-AllTasks {
    Get-ChildItem -Path $Script:TasksDir -Filter "*.json" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime |
        ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json }
}

# ---------------------------------------------------------------------------
# GPU lock - serializes heavy local inference so only one worker generates at
# a time (single-GPU machine). File-created-exclusively is the mutex.
# ---------------------------------------------------------------------------

function Acquire-GpuLock {
    param([string]$TaskId, [int]$TimeoutSeconds)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $reportedWaiting = $false
    while ($true) {
        try {
            $fs = [System.IO.File]::Open($Script:LockFile, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            $sw = New-Object System.IO.StreamWriter($fs)
            $sw.WriteLine("$TaskId|$PID|$(Get-Date -Format o)")
            $sw.Flush(); $sw.Close(); $fs.Close()
            return $true
        } catch {
            if (Test-Path $Script:LockFile) {
                $ownerLine = Get-Content -LiteralPath $Script:LockFile -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($ownerLine) {
                    $ownerPid = ($ownerLine -split '\|')[1]
                    $proc = Get-Process -Id $ownerPid -ErrorAction SilentlyContinue
                    if (-not $proc) {
                        Remove-Item -LiteralPath $Script:LockFile -Force -ErrorAction SilentlyContinue
                        continue
                    }
                    if (-not $reportedWaiting) {
                        Write-Host "[$TaskId] GPU busy ($ownerLine) - waiting..." -ForegroundColor DarkYellow
                        $reportedWaiting = $true
                    }
                }
            }
            if ((Get-Date) -gt $deadline) { return $false }
            Start-Sleep -Seconds 5
        }
    }
}

function Release-GpuLock {
    Remove-Item -LiteralPath $Script:LockFile -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Ollama
# ---------------------------------------------------------------------------

function Invoke-OllamaChat {
    param([string]$BaseUrl, [string]$Model, [string]$SystemPrompt, [string]$UserPrompt, [int]$TimeoutSeconds, [int]$NumCtx = 32768, [double]$Temperature = 0.2)
    $uri = "$BaseUrl/api/chat"
    $bodyObj = @{
        model    = $Model
        stream   = $false
        options  = @{ num_ctx = $NumCtx; temperature = $Temperature }
        messages = @(
            @{ role = "system"; content = $SystemPrompt }
            @{ role = "user"; content = $UserPrompt }
        )
    }
    $body = $bodyObj | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json; charset=utf-8" -TimeoutSec $TimeoutSeconds
}

# ---------------------------------------------------------------------------
# Timed external process (dotnet build/test) with a real kill-on-timeout.
# ---------------------------------------------------------------------------

function Invoke-TimedProcess {
    # Deliberately NOT Start-Process -PassThru: tested directly (23 Aug 2026) and confirmed
    # its returned Process object leaves .ExitCode empty even when .HasExited is true - a
    # known Windows PowerShell 5.1 quirk, not something specific to dotnet.exe. Owning the
    # Process object from construction (rather than via the Start-Process cmdlet wrapper)
    # makes ExitCode reliable.
    #
    # Also deliberately NOT Register-ObjectEvent/BeginOutputReadLine: also tested directly -
    # a single blocking WaitForExit(ms) call never yields the thread back to the PowerShell
    # engine, so queued event actions run late and unreliably (confirmed losing the tail of
    # a real dotnet test run's output, mid-line, on two separate reruns). ReadToEndAsync()
    # started on BOTH streams before waiting avoids that PowerShell-specific issue, and
    # avoids the classic single-stream deadlock (KNOWN_ASSUMPTIONS.md A10: a large stdout
    # response can fill the OS pipe buffer and block the child while the parent is blocked
    # reading only stderr, or vice versa) because both streams drain concurrently from the
    # moment the process starts, never both waiting on one one before touching the other.
    param([string]$FilePath, [string[]]$ArgumentList, [string]$WorkingDirectory, [int]$TimeoutSeconds)

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    # Windows PowerShell 5.1 runs on .NET Framework, which never got
    # ProcessStartInfo.ArgumentList (.NET Core-only) - build the classic quoted
    # Arguments string by hand instead.
    $quotedArgs = foreach ($a in $ArgumentList) { if ($a -match '\s') { '"' + $a + '"' } else { $a } }
    $psi.Arguments = ($quotedArgs -join ' ')
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    try {
        [void]$proc.Start()
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()

        $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
        while (-not $proc.HasExited -and (Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 150
        }
        if (-not $proc.HasExited) {
            try { $proc.Kill() } catch {}
            [System.Threading.Tasks.Task]::WaitAll(@($stdoutTask, $stderrTask), 3000) | Out-Null
            $stdout = if ($stdoutTask.IsCompleted) { $stdoutTask.Result } else { "" }
            $stderr = if ($stderrTask.IsCompleted) { $stderrTask.Result } else { "" }
            return [ordered]@{ TimedOut = $true; ExitCode = -1; StdOut = $stdout; StdErr = $stderr }
        }

        [System.Threading.Tasks.Task]::WaitAll(@($stdoutTask, $stderrTask), 30000) | Out-Null
        return [ordered]@{ TimedOut = $false; ExitCode = $proc.ExitCode; StdOut = $stdoutTask.Result; StdErr = $stderrTask.Result }
    } finally {
        $proc.Dispose()
    }
}

function Invoke-DotnetBuild {
    # ArgumentList elements go into ProcessStartInfo.ArgumentList, which does its own
    # escaping - unlike Start-Process -ArgumentList, entries must NOT be pre-quoted.
    param([string]$WorktreePath, [int]$TimeoutSeconds)
    $sln = Join-Path $WorktreePath "BioShockStudio.sln"
    Invoke-TimedProcess -FilePath "dotnet" -ArgumentList @("build", $sln, "-nologo") -WorkingDirectory $WorktreePath -TimeoutSeconds $TimeoutSeconds
}

function Invoke-DotnetTest {
    param([string]$WorktreePath, [string]$Filter, [int]$TimeoutSeconds)
    $sln = Join-Path $WorktreePath "BioShockStudio.sln"
    Invoke-TimedProcess -FilePath "dotnet" -ArgumentList @("test", $sln, "--filter", $Filter, "-nologo") -WorkingDirectory $WorktreePath -TimeoutSeconds $TimeoutSeconds
}

# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------

function Invoke-GitCommand {
    # `2>&1` on a native command under $ErrorActionPreference = "Stop" wraps every stderr
    # line in a terminating NativeCommandError, even on a purely informational git warning
    # (confirmed directly, 23 Aug 2026: a harmless CRLF-normalization warning from `git add
    # -N` crashed a live coder dispatch mid-task). Every git call that wants stderr merged
    # into its captured output goes through here instead, with EAP relaxed just for the
    # call, so a warning is data, not a crash.
    param([string[]]$GitArgs)
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & git @GitArgs 2>&1
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

function Get-WorktreeDirty {
    # Every agent worktree carries a pre-existing untracked .agent/ scaffolding
    # folder (role file, launcher script) that is not repository content and
    # not this task's work - it is excluded from the dirty check by pathspec
    # so it never false-blocks a dispatch.
    param([string]$WorktreePath)
    $st = Invoke-GitCommand -GitArgs @("-C", $WorktreePath, "status", "--porcelain", "--", ":(exclude).agent")
    return [bool]$st
}

function Get-GitDiffInfo {
    param([string]$WorktreePath, [string[]]$TouchedFiles)
    foreach ($f in $TouchedFiles) {
        & git -C $WorktreePath ls-files --error-unmatch -- $f *>$null
        if ($LASTEXITCODE -ne 0) {
            Invoke-GitCommand -GitArgs @("-C", $WorktreePath, "add", "-N", "--", $f) | Out-Null
        }
    }
    $stat = Invoke-GitCommand -GitArgs (@("-C", $WorktreePath, "diff", "--stat", "--") + $TouchedFiles)
    $full = Invoke-GitCommand -GitArgs (@("-C", $WorktreePath, "diff", "--") + $TouchedFiles)
    return [ordered]@{ Stat = ($stat -join "`n"); Diff = ($full -join "`n") }
}

function Sync-CoderChangesToTester {
    # Applies the coder's still-uncommitted working-tree diff into the tester
    # worktree so the tester can build/test the real change, WITHOUT merging
    # or committing anything. Always paired with Undo-CoderChangesInTester.
    param($CoderTask, [string]$TesterWorktree)
    if (-not $CoderTask -or $CoderTask.role -ne "coder") { return $null }
    if (-not $CoderTask.filesChanged -or $CoderTask.filesChanged.Count -eq 0) { return $null }

    if (Get-WorktreeDirty -WorktreePath $TesterWorktree) {
        throw "Tester worktree ($TesterWorktree) is dirty; refusing to apply the coder's patch onto it."
    }

    $diffInfo = Get-GitDiffInfo -WorktreePath $CoderTask.worktree -TouchedFiles $CoderTask.filesChanged
    if (-not $diffInfo.Diff) { return $null }

    $patchFile = Join-Path $Script:LogsDir "$($CoderTask.id)-to-tester.patch"
    $diffInfo.Diff | Set-Content -LiteralPath $patchFile -Encoding utf8

    # --ignore-whitespace: this repo checks out CRLF (core.autocrlf=true) but `git diff`
    # always emits LF-normalized patches - without it, a hunk whose context lines carry an
    # embedded \r the patch doesn't expect fails to match. Confirmed directly (23 Aug 2026)
    # on a real patch: 3 of 4 files in the same patch applied fine and the 4th failed with
    # "patch does not apply" despite an exactly matching base blob hash, purely from this.
    $applyOut = Invoke-GitCommand -GitArgs @("-C", $TesterWorktree, "apply", "--whitespace=nowarn", "--ignore-whitespace", $patchFile)
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply coder patch $($CoderTask.id) to tester worktree: $applyOut"
    }
    return @{ PatchFile = $patchFile; Diff = $diffInfo.Diff; Files = $CoderTask.filesChanged }
}

function Undo-CoderChangesInTester {
    # `git apply -R` alone was confirmed (23 Aug 2026) to leave a file behind with a
    # content-identical but line-ending-flipped residue (CRLF -> LF) after a successful
    # --ignore-whitespace forward apply - `git diff` on it was empty but `git status`
    # still showed it modified. A hard `git checkout --` on exactly the files we touched
    # is the actual guarantee of a clean worktree; the reverse-apply is just the fast path.
    param([string]$TesterWorktree, [string]$PatchFile, [string[]]$Files = @())
    if (-not $PatchFile) { return }
    Invoke-GitCommand -GitArgs @("-C", $TesterWorktree, "apply", "-R", "--whitespace=nowarn", "--ignore-whitespace", $PatchFile) | Out-Null
    if ($Files.Count -gt 0) {
        Invoke-GitCommand -GitArgs (@("-C", $TesterWorktree, "checkout", "--") + $Files) | Out-Null
    }
    $residual = Invoke-GitCommand -GitArgs @("-C", $TesterWorktree, "status", "--porcelain", "--", ":(exclude).agent")
    if ($residual) {
        Write-Host "WARNING: tester worktree not fully clean after reverting the coder patch:" -ForegroundColor Yellow
        Write-Host ($residual -join "`n") -ForegroundColor Yellow
        Write-Host "Inspect manually: git -C `"$TesterWorktree`" status" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# Context assembly
# ---------------------------------------------------------------------------

function Get-FileContextBlock {
    param([string]$WorktreePath, [string[]]$Files, [int]$CharBudget)
    $sb = New-Object System.Text.StringBuilder
    $used = 0
    foreach ($f in $Files) {
        if (-not (Test-SafeRelativePath $f)) {
            [void]$sb.AppendLine("### $f - REJECTED (unsafe path, not read)")
            continue
        }
        $full = Join-Path $WorktreePath $f
        if (-not (Test-Path -LiteralPath $full)) {
            [void]$sb.AppendLine("### FILE NOT FOUND: $f")
            continue
        }
        $content = Get-Content -Raw -LiteralPath $full -ErrorAction SilentlyContinue
        if ($null -eq $content) { $content = "" }
        $remaining = $CharBudget - $used
        if ($remaining -le 0) {
            [void]$sb.AppendLine("### $f - SKIPPED (context budget exhausted)")
            continue
        }
        if ($content.Length -gt $remaining) {
            $content = $content.Substring(0, $remaining) + "`n...TRUNCATED (file is $($content.Length) chars total)..."
        }
        $used += $content.Length
        [void]$sb.AppendLine("### FILE: $f")
        [void]$sb.AppendLine('```')
        [void]$sb.AppendLine($content)
        [void]$sb.AppendLine('```')
    }
    return $sb.ToString()
}

function Get-ReportText {
    # Local 30B-class models sometimes echo the literal "<<<REPORT>>>...report
    # text...<<<END REPORT>>>" instruction back verbatim (in addition to, or
    # instead of, actually filling it in) rather than treating it as a
    # fill-in-the-blank template. Only trust a matched REPORT block if it has
    # real content; otherwise fall back to the whole response with any
    # placeholder echo stripped out, so a good answer is never discarded.
    param([string]$ResponseText)
    $reportMatch = [regex]::Match($ResponseText, '(?s)<<<REPORT>>>\r?\n?(.*?)<<<END REPORT>>>')
    if ($reportMatch.Success) {
        $candidate = $reportMatch.Groups[1].Value.Trim()
        if ($candidate.Length -gt 20 -and $candidate -notmatch '^\.\.\.\s*report') {
            return $candidate
        }
    }
    $cleaned = [regex]::Replace($ResponseText, '(?s)<<<REPORT>>>.*?<<<END REPORT>>>', '')
    return $cleaned.Trim()
}

function Get-TruncatedText {
    param([string]$Text, [int]$MaxChars)
    if ([string]::IsNullOrEmpty($Text)) { return $Text }
    if ($Text.Length -le $MaxChars) { return $Text }
    return $Text.Substring(0, $MaxChars) + "`n...TRUNCATED ($($Text.Length) chars total)..."
}

# ---------------------------------------------------------------------------
# Prompt construction
# ---------------------------------------------------------------------------

function Build-SystemPrompt {
    param($RoleConfig, [string]$RoleName)
    $roleFilePath = Join-Path $RoleConfig.worktree $RoleConfig.roleFile
    $roleText = Get-Content -Raw -LiteralPath $roleFilePath -ErrorAction SilentlyContinue
    if (-not $roleText) { $roleText = "You are the $RoleName agent for this repository." }

    if ($RoleName -eq "coder") {
        $outputInstructions = @"

OUTPUT FORMAT - read carefully, this is a single non-interactive call with no further turns.
For every file you create or modify, output its COMPLETE new contents (not a diff), one block per
file, in exactly this form:
<<<FILE: relative/path/from/repo/root.cs>>>
...full file content...
<<<END FILE>>>
Use paths relative to the repository root. Do not wrap file blocks in markdown code fences. Only
include files this task actually requires changing - do not touch anything else.
After all file blocks, write your report using the "# Implementation Result" template from your role
instructions above, wrapped exactly as:
<<<REPORT>>>
...report text...
<<<END REPORT>>>
"@
    } else {
        $outputInstructions = @"

OUTPUT FORMAT - this is a single non-interactive call: you cannot run a command or read a file that
was not already included below. Write your full report using the template from your role
instructions above, wrapped exactly as:
<<<REPORT>>>
...report text...
<<<END REPORT>>>
"@
    }

    return "$roleText`n`n$($Script:ProtocolCore)$outputInstructions"
}

function Build-UserPrompt {
    param($Task, $Config, [string]$DiffForReview = $null, $ControllerCheck = $null)
    $parts = New-Object System.Collections.Generic.List[string]
    [void]$parts.Add("Task ID: $($Task.id)")
    [void]$parts.Add("Role: $($Task.role)")
    [void]$parts.Add("Worktree: $($Task.worktree)  (branch: $($Task.branch))")
    [void]$parts.Add("`n## Task`n$($Task.task)")

    if ($Task.parent) {
        $parentResultPath = Join-Path $Script:ResultsDir "$($Task.parent).md"
        if (Test-Path -LiteralPath $parentResultPath) {
            $ptext = Get-TruncatedText -Text (Get-Content -Raw -LiteralPath $parentResultPath) -MaxChars 8000
            [void]$parts.Add("`n## Evidence from parent task $($Task.parent)`n$ptext")
        }
    }

    if ($Task.context) {
        [void]$parts.Add("`n## Additional context supplied by the lead`n$($Task.context)")
    }

    if ($Task.grep) {
        $hits = & git -C $Task.worktree grep -n -I -e $Task.grep 2>$null
        if ($hits) {
            $hitsText = (($hits | Select-Object -First 200) -join "`n")
            [void]$parts.Add("`n## git grep '$($Task.grep)' results (first 200 lines)`n``````n$hitsText`n``````")
        } else {
            [void]$parts.Add("`n## git grep '$($Task.grep)' - no matches")
        }
    }

    if ($Task.glob) {
        $globMatches = Get-ChildItem -Path $Task.worktree -Recurse -File -Filter $Task.glob -ErrorAction SilentlyContinue |
            Select-Object -First 200 |
            ForEach-Object { $_.FullName.Substring($Task.worktree.Length + 1) }
        if ($globMatches) {
            [void]$parts.Add("`n## Files matching glob '$($Task.glob)'`n" + ($globMatches -join "`n"))
        }
    }

    if ($DiffForReview) {
        [void]$parts.Add("`n## Diff under review (this is the actual, unmerged change - do not trust any other description of it)`n``````diff`n$(Get-TruncatedText -Text $DiffForReview -MaxChars 20000)`n``````")
    }

    if ($ControllerCheck) {
        [void]$parts.Add("`n## Controller-run build/test output - GROUND TRUTH, trust this over any claim, including your own`n$ControllerCheck")
    }

    if ($Task.files -and $Task.files.Count -gt 0) {
        $ctx = Get-FileContextBlock -WorktreePath $Task.worktree -Files $Task.files -CharBudget $Config.contextCharBudget
        [void]$parts.Add("`n## Relevant file contents (read-only reference - only change what the task asks)`n$ctx")
    }

    return ($parts -join "`n")
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------

function Invoke-AgentTask {
    param(
        [string]$RoleName,
        [string]$TaskText,
        [string[]]$Files = @(),
        [string]$Parent = "",
        [string]$Context = "",
        [string]$Grep = "",
        [string]$Glob = "",
        [int]$TimeoutMinutesOverride = 0,
        [string]$TestFilter = "",
        [switch]$SkipBuild
    )

    $config = Get-AgentConfig
    $roleConfig = $config.roles.$RoleName
    if (-not $roleConfig) { throw "Unknown role: $RoleName" }

    foreach ($f in $Files) {
        if (-not (Test-SafeRelativePath $f)) { throw "Unsafe file path rejected: $f" }
    }

    $worktree = $roleConfig.worktree
    if (-not (Test-Path -LiteralPath $worktree)) { throw "Worktree not found: $worktree" }

    # Inherit file list (and, for tester/reviewer, the coder's diff) from the parent task.
    $parentTask = $null
    $diffForReview = $null
    if ($Parent) {
        $parentTask = Load-Task -Id $Parent
        if (-not $parentTask) { throw "Parent task not found: $Parent" }
        if ((-not $Files -or $Files.Count -eq 0)) {
            if ($parentTask.filesChanged -and $parentTask.filesChanged.Count -gt 0) { $Files = $parentTask.filesChanged }
            elseif ($parentTask.files -and $parentTask.files.Count -gt 0) { $Files = $parentTask.files }
        }
        if ($RoleName -eq "reviewer" -and $parentTask.role -eq "coder" -and $parentTask.filesChanged.Count -gt 0) {
            $di = Get-GitDiffInfo -WorktreePath $parentTask.worktree -TouchedFiles $parentTask.filesChanged
            $diffForReview = $di.Diff
        }
    }

    $id = New-TaskId -Role $RoleName
    $timeoutMinutes = if ($TimeoutMinutesOverride -gt 0) { $TimeoutMinutesOverride } else { $roleConfig.timeoutMinutes }

    $task = [ordered]@{
        id = $id; role = $RoleName; task = $TaskText
        files = $Files; parent = $Parent; context = $Context
        grep = $Grep; glob = $Glob
        worktree = $worktree; branch = $roleConfig.branch; model = $roleConfig.model
        timeoutMinutes = $timeoutMinutes
        status = "QUEUED"; createdAt = (Get-Date -Format o)
        startedAt = $null; endedAt = $null; durationSeconds = $null
        exitCode = $null; error = $null
        resultPath = (Join-Path $Script:ResultsDir "$id.md")
        logPath = (Join-Path $Script:LogsDir "$id.log")
        filesChanged = @(); gitDiffStat = $null
        controllerBuildExit = $null; controllerTestExit = $null
    }
    Save-Task -Task $task

    if (Get-WorktreeDirty -WorktreePath $worktree) {
        $task.status = "BLOCKED"
        $task.error = "Worktree already dirty before dispatch - refusing to start (possible unmerged prior agent work). Inspect: git -C `"$worktree`" status"
        Save-Task -Task $task
        Write-Host "[$id] BLOCKED - $worktree is dirty. Not dispatching." -ForegroundColor Red
        & git -C $worktree status --short
        return (Load-Task -Id $id)
    }

    Write-Host "[$id] queued, role=$RoleName, model=$($roleConfig.model)" -ForegroundColor Cyan
    $lockTimeoutSeconds = [Math]::Max($timeoutMinutes * 60, 120)
    $gotLock = Acquire-GpuLock -TaskId $id -TimeoutSeconds $lockTimeoutSeconds
    if (-not $gotLock) {
        $task.status = "TIMEOUT"
        $task.error = "Timed out waiting for the GPU inference lock."
        Save-Task -Task $task
        return (Load-Task -Id $id)
    }

    $patchApplied = $null
    try {
        $task.status = "RUNNING"; $task.startedAt = (Get-Date -Format o)
        Save-Task -Task $task
        Write-Host "[$id] running..." -ForegroundColor Cyan

        # Tester: pull the coder's uncommitted patch onto this worktree so the
        # test run reflects the real change. Always reversed in `finally`.
        if ($RoleName -eq "tester" -and $parentTask -and $parentTask.role -eq "coder") {
            $patchApplied = Sync-CoderChangesToTester -CoderTask $parentTask -TesterWorktree $worktree
            if ($patchApplied) {
                $diffForReview = $patchApplied.Diff
                Write-Host "[$id] applied $($parentTask.id)'s patch onto the tester worktree for validation." -ForegroundColor DarkCyan
            }
        }

        # Controller-run build/test - ground truth the model cannot fabricate,
        # because this worker gets no shell access of its own.
        $controllerCheckText = $null
        if ($RoleName -eq "tester" -and -not $SkipBuild) {
            $buildRes = Invoke-DotnetBuild -WorktreePath $worktree -TimeoutSeconds $config.buildTimeoutSeconds
            $task.controllerBuildExit = $buildRes.ExitCode
            $lines = @("dotnet build: exit=$($buildRes.ExitCode) timedOut=$($buildRes.TimedOut)")
            $lines += (Get-TruncatedText -Text $buildRes.StdOut -MaxChars 4000)
            if ($buildRes.ExitCode -eq 0) {
                $filter = if ($TestFilter) { $TestFilter } else { $config.defaultTestFilter }
                $testRes = Invoke-DotnetTest -WorktreePath $worktree -Filter $filter -TimeoutSeconds $config.testTimeoutSeconds
                $task.controllerTestExit = $testRes.ExitCode
                $lines += "`ndotnet test --filter `"$filter`": exit=$($testRes.ExitCode) timedOut=$($testRes.TimedOut)"
                $lines += (Get-TruncatedText -Text $testRes.StdOut -MaxChars 6000)
            } else {
                $lines += "`n(tests skipped - build failed)"
            }
            $controllerCheckText = $lines -join "`n"
        }

        $systemPrompt = Build-SystemPrompt -RoleConfig $roleConfig -RoleName $RoleName
        $taskForPrompt = Load-Task -Id $id
        $userPrompt = Build-UserPrompt -Task $taskForPrompt -Config $config -DiffForReview $diffForReview -ControllerCheck $controllerCheckText

        $logLines = New-Object System.Collections.Generic.List[string]
        [void]$logLines.Add("=== SYSTEM PROMPT ===`n$systemPrompt")
        [void]$logLines.Add("=== USER PROMPT ===`n$userPrompt")

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $timedOut = $false
        $responseText = $null
        $errMsg = $null
        try {
            $resp = Invoke-OllamaChat -BaseUrl $config.ollama.baseUrl -Model $roleConfig.model `
                -SystemPrompt $systemPrompt -UserPrompt $userPrompt `
                -TimeoutSeconds ($timeoutMinutes * 60) -NumCtx $config.ollama.numCtx -Temperature $config.ollama.temperature
            $responseText = $resp.message.content
        } catch {
            $msg = $_.Exception.Message
            if ($msg -match "(?i)time.?out") { $timedOut = $true }
            $errMsg = $msg
        }
        $sw.Stop()

        [void]$logLines.Add("=== RAW RESPONSE ===`n$responseText")
        if ($errMsg) { [void]$logLines.Add("=== ERROR ===`n$errMsg") }
        ($logLines -join "`n`n") | Set-Content -LiteralPath $task.logPath -Encoding utf8

        $task.durationSeconds = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        $task.endedAt = (Get-Date -Format o)

        if ($timedOut) {
            $task.status = "TIMEOUT"; $task.exitCode = -1; $task.error = $errMsg
            Save-Task -Task $task
            Write-Host "[$id] TIMEOUT after $($task.durationSeconds)s" -ForegroundColor Yellow
            return (Load-Task -Id $id)
        }
        if (-not $responseText) {
            $task.status = "FAILED"; $task.exitCode = 1
            $task.error = if ($errMsg) { $errMsg } else { "Model returned an empty response." }
            Save-Task -Task $task
            Write-Host "[$id] FAILED: $($task.error)" -ForegroundColor Red
            return (Load-Task -Id $id)
        }

        $filesChanged = @()
        if ($RoleName -eq "coder") {
            $fileMatches = [regex]::Matches($responseText, '(?s)<<<FILE:\s*(.+?)\s*>>>\r?\n(.*?)<<<END FILE>>>')
            foreach ($m in $fileMatches) {
                $relPath = $m.Groups[1].Value.Trim()
                $content = $m.Groups[2].Value
                if (-not (Test-SafeRelativePath $relPath)) {
                    Write-Host "[$id] REJECTED unsafe path from model output: $relPath" -ForegroundColor Red
                    continue
                }
                $resolvedRoot = [System.IO.Path]::GetFullPath($worktree)
                $resolvedFull = [System.IO.Path]::GetFullPath((Join-Path $worktree $relPath))
                if (-not $resolvedFull.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
                    Write-Host "[$id] REJECTED path escaping worktree: $relPath" -ForegroundColor Red
                    continue
                }
                $dir = Split-Path -Parent $resolvedFull
                if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
                # Windows PowerShell's `Set-Content -Encoding utf8` always writes a BOM,
                # unlike this repo's existing source files - confirmed directly (23 Aug
                # 2026), it silently prepended a BOM to every coder-written file, showing
                # up as spurious noise on line 1 of every diff. Write UTF-8 without BOM.
                # This repo checks out with core.autocrlf=true (confirmed, 23 Aug 2026), so
                # every existing tracked file is CRLF on disk. A model response normally
                # comes back LF-only; writing it as-is produced a real patch-apply failure
                # against the tester worktree ("patch does not apply") because the diff's
                # unchanged context lines differed from the tester's CRLF checkout only in
                # line-ending bytes. Normalize to CRLF unconditionally before writing.
                $normalized = $content -replace "`r`n", "`n" -replace "`n", "`r`n"
                [System.IO.File]::WriteAllText($resolvedFull, $normalized, (New-Object System.Text.UTF8Encoding($false)))
                $filesChanged += $relPath
            }
        }
        $task.filesChanged = $filesChanged

        $responseForReport = $responseText
        if ($RoleName -eq "coder") {
            $responseForReport = [regex]::Replace($responseForReport, '(?s)<<<FILE:.*?<<<END FILE>>>', '')
        }
        $reportText = Get-ReportText -ResponseText $responseForReport

        $diffInfo = $null
        if ($filesChanged.Count -gt 0) {
            $diffInfo = Get-GitDiffInfo -WorktreePath $worktree -TouchedFiles $filesChanged
            $task.gitDiffStat = $diffInfo.Stat
        }

        if ($RoleName -eq "coder" -and $filesChanged.Count -gt 0 -and -not $SkipBuild) {
            $buildRes = Invoke-DotnetBuild -WorktreePath $worktree -TimeoutSeconds $config.buildTimeoutSeconds
            $task.controllerBuildExit = $buildRes.ExitCode
        }

        $resultMd = New-Object System.Text.StringBuilder
        [void]$resultMd.AppendLine("# Result: $id")
        [void]$resultMd.AppendLine("")
        [void]$resultMd.AppendLine("- Role: $RoleName")
        [void]$resultMd.AppendLine("- Model: $($roleConfig.model)")
        [void]$resultMd.AppendLine("- Worktree: $worktree (branch $($roleConfig.branch))")
        [void]$resultMd.AppendLine("- Duration: $($task.durationSeconds)s")
        [void]$resultMd.AppendLine("- Parent: $(if ($Parent) { $Parent } else { 'none' })")
        if ($filesChanged.Count -gt 0) {
            [void]$resultMd.AppendLine("- Files changed: $($filesChanged -join ', ')")
            [void]$resultMd.AppendLine("- Controller-verified build exit code: $($task.controllerBuildExit) (0 = success; null = not run)")
        }
        if ($null -ne $task.controllerTestExit) {
            [void]$resultMd.AppendLine("- Controller-verified test exit code: $($task.controllerTestExit) (0 = all passed)")
        }
        [void]$resultMd.AppendLine("")
        [void]$resultMd.AppendLine("## Task")
        [void]$resultMd.AppendLine($TaskText)
        [void]$resultMd.AppendLine("")
        [void]$resultMd.AppendLine("## Worker report")
        [void]$resultMd.AppendLine($reportText)
        if ($diffInfo) {
            [void]$resultMd.AppendLine("")
            [void]$resultMd.AppendLine("## Git diffstat (live in the worktree, not committed)")
            [void]$resultMd.AppendLine('```')
            [void]$resultMd.AppendLine($diffInfo.Stat)
            [void]$resultMd.AppendLine('```')
        }
        if ($controllerCheckText) {
            [void]$resultMd.AppendLine("")
            [void]$resultMd.AppendLine("## Controller-run build/test (ground truth)")
            [void]$resultMd.AppendLine('```')
            [void]$resultMd.AppendLine((Get-TruncatedText -Text $controllerCheckText -MaxChars 4000))
            [void]$resultMd.AppendLine('```')
        }
        $resultMd.ToString() | Set-Content -LiteralPath $task.resultPath -Encoding utf8

        $task.status = "COMPLETE"; $task.exitCode = 0
        Save-Task -Task $task
        Write-Host "[$id] COMPLETE in $($task.durationSeconds)s -> $($task.resultPath)" -ForegroundColor Green
        if ($filesChanged.Count -gt 0) {
            Write-Host "[$id] Files changed (uncommitted, in $worktree): $($filesChanged -join ', ')" -ForegroundColor Green
        }
        return (Load-Task -Id $id)
    } finally {
        if ($patchApplied) {
            Undo-CoderChangesInTester -TesterWorktree $worktree -PatchFile $patchApplied.PatchFile -Files $patchApplied.Files
        }
        Release-GpuLock
    }
}
