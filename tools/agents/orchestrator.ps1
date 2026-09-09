# tools/agents/orchestrator.ps1
#
# Farms queued task files (tools/agents/tasks/*.md) out to coding-agent "workers" so BioShock work
# can run in PARALLEL with this Claude session and with Cursor -- each worker gets its own throwaway
# git worktree under ../BioShockHavok-agents/<task-id>, so nobody edits anyone else's files.
#
# WORKERS (see Get-WorkerSpec below)
#   chatgpt   codex exec, authenticated with the machine's ChatGPT account. Cloud; runs fully
#             parallel. This is the "use ChatGPT as a worker" path.
#   qwen      codex exec --oss --local-provider ollama -m qwen3-coder:30b   (local, free)
#   deepseek  codex exec --oss --local-provider ollama -m deepseek-coder-v2:16b  (local, free,
#             the reliable local model on this 12 GB card -- see README)
#   cursor    the standalone `cursor-agent` CLI. NOT installed yet; the row is here so it lights up
#             the moment it is (README has the install line). The Cursor GUI is unaffected -- its
#             .cursor/hooks continue-loop keeps running as its own lane.
#
# SAFETY MODEL (identical in spirit to tools/backup-agent/run.ps1)
#   - Workers NEVER commit and NEVER push. Every change lands in that worker's worktree only, is
#     captured as a patch under runs/<id>/, and waits for review.
#   - Local worktree edits are sandboxed to the worktree (codex --sandbox workspace-write).
#   - After each task the verify command (default: fast-tier tests) runs in that worktree and the
#     PASS/FAIL is recorded. A fail does not block other tasks -- they are already isolated.
#   - `apply` stages a reviewed patch into the MAIN tree for Claude/you to check and commit. It
#     still does not commit.
#
# USAGE  (run from anywhere; always operates on this checkout). This machine has Windows PowerShell
# 5.1 only and script execution is Restricted, so the invocation needs -ExecutionPolicy Bypass:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\agents\orchestrator.ps1 list
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\agents\orchestrator.ps1 run              # every pending task
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\agents\orchestrator.ps1 run -Task ai-ini # just that one
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\agents\orchestrator.ps1 status           # results table
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\agents\orchestrator.ps1 apply -Task ai-ini # git apply into main tree (no commit)
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\agents\orchestrator.ps1 clean            # remove agent worktrees
#
# A task is "pending" when tools/agents/tasks/<id>.md exists and tools/agents/tasks/<id>.done does
# not. Create the .done marker by hand once you have reviewed, applied and committed that task's
# work -- exactly the tools/backup-agent convention.

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('list', 'run', 'status', 'apply', 'clean')]
    [string]$Command = 'list',

    # Restrict run/apply to a single task id (the <id> in tasks/<id>.md).
    [string]$Task,

    # Max workers running at once. Local (ollama) workers are additionally serialised by a lock
    # regardless of this number -- one GPU.
    [int]$Parallel = 3,

    # codex --sandbox danger-full-access + no approval gate for local workers. Off by default.
    [switch]$Yolo
)

$ErrorActionPreference = 'Stop'
$repoRoot   = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$agentDir   = Join-Path $repoRoot 'tools\agents'
$taskDir    = Join-Path $agentDir 'tasks'
$runDir     = Join-Path $agentDir 'runs'
$localLock  = Join-Path $agentDir '.local.lock'
# All agent worktrees live under one folder next to the repo, not spewed across it.
$wtParent   = Join-Path (Split-Path -Parent $repoRoot) 'BioShockHavok-agents'
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
New-Item -ItemType Directory -Force -Path $wtParent | Out-Null

# --- task file parsing -------------------------------------------------------------------------
# Format: a YAML-ish frontmatter block between --- lines, then the free-text prompt.
#   ---
#   worker: chatgpt
#   base: main
#   verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
#   lane: src/**, tests/**, docs/research/**
#   ---
#   <instructions for the worker>
function Read-Task {
    param([string]$Path)
    $id    = [IO.Path]::GetFileNameWithoutExtension($Path)
    $lines = Get-Content -LiteralPath $Path
    $meta  = @{
        worker = 'chatgpt'
        base   = 'main'
        verify = 'dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast'
        lane   = ''
    }
    $body = $lines
    if ($lines.Count -ge 2 -and $lines[0].Trim() -eq '---') {
        $end = 1
        while ($end -lt $lines.Count -and $lines[$end].Trim() -ne '---') { $end++ }
        for ($i = 1; $i -lt $end; $i++) {
            if ($lines[$i] -match '^\s*([A-Za-z_]+)\s*:\s*(.+?)\s*$') {
                $meta[$Matches[1].ToLower()] = $Matches[2]
            }
        }
        $body = if ($end + 1 -lt $lines.Count) { $lines[($end + 1)..($lines.Count - 1)] } else { @() }
    }
    [pscustomobject]@{
        Id     = $id
        Path   = $Path
        Worker = $meta.worker.ToLower()
        Base   = $meta.base
        Verify = $meta.verify
        Lane   = $meta.lane
        Prompt = ($body -join "`n").Trim()
        Done   = Test-Path ([IO.Path]::ChangeExtension($Path, '.done'))
    }
}

function Get-PendingTasks {
    if (-not (Test-Path $taskDir)) { return @() }
    Get-ChildItem -Path $taskDir -Filter '*.md' |
        Where-Object { $_.Name -ne '_TEMPLATE.md' } |
        ForEach-Object { Read-Task $_.FullName } |
        Where-Object { -not $_.Done }
}

# --- worker command builder ------------------------------------------------------------------
# Returns @{ Exe = ...; Args = @(...); Local = $bool }. The prompt is always fed on stdin.
function Get-WorkerSpec {
    param([string]$Worker, [string]$Worktree)

    $codexCommon = @('exec', '--cd', $Worktree, '--skip-git-repo-check', '--color', 'never')

    function Resolve-CursorAgent {
        $cmd = Join-Path $env:LOCALAPPDATA 'cursor-agent\cursor-agent.cmd'
        if (Test-Path $cmd) { return $cmd }
        $g = Get-Command 'cursor-agent.cmd', 'cursor-agent' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($g) { return $g.Source }
        foreach ($p in ([Environment]::GetEnvironmentVariable('PATH', 'User') -split ';')) {
            $c = Join-Path $p 'cursor-agent.cmd'
            if ($p -and (Test-Path $c)) { return $c }
        }
        throw "cursor-agent not found (looked in %LOCALAPPDATA%\cursor-agent and PATH). Install per tools/agents/README.md."
    }
    # --approve-for-me implies the workspace-write sandbox and auto-clears approval prompts, so it
    # runs unattended without the edits escaping the worktree. It is mutually exclusive with an
    # explicit --sandbox. -Yolo swaps in full access + no sandbox (don't, unless you're watching).
    $gate = if ($Yolo) { @('--dangerously-bypass-approvals-and-sandbox') }
            else        { @('--approve-for-me') }

    switch ($Worker) {
        'chatgpt' {
            # gpt-5.6-sol defaults to reasoning effort "none" under `codex exec`, which is far too
            # shallow for a whole runtime feature. Force high. (Cursor is the primary worker; this
            # path is the fallback while Cursor's quota is exhausted.)
            @{ Exe = 'codex'; Args = ($codexCommon + @('-c', 'model_reasoning_effort="high"') + $gate + '-'); Local = $false }
        }
        'qwen' {
            # qwen2.5-coder:14b: ~9 GB (fits the 12 GB card) AND exposes tool-calling, which codex
            # requires. deepseek-coder-v2 does NOT expose tools to codex -- it only works via aider
            # (tools/backup-agent), which parses its own edit blocks.
            @{ Exe = 'codex'; Args = ($codexCommon + $gate + @('--oss', '--local-provider', 'ollama', '-m', 'qwen2.5-coder:14b', '-')); Local = $true }
        }
        'qwen-big' {
            # qwen3-coder:30b: stronger, but 18 GB on a 12 GB card -- has hung 600 s+ before. Only
            # with someone watching.
            @{ Exe = 'codex'; Args = ($codexCommon + $gate + @('--oss', '--local-provider', 'ollama', '-m', 'qwen3-coder:30b', '-')); Local = $true }
        }
        'aider' {
            # deepseek-coder-v2:16b driven by aider. aider parses its own SEARCH/REPLACE blocks and
            # needs NO tool-calling -- exactly why `qwen` (codex --oss) fails here: codex requires
            # tools the local Ollama models do not reliably expose, and on 2 Sept the qwen worker
            # emitted a file as a JSON blob instead of writing it. Model, --no-auto-commits and the
            # test-cmd live in .aider.conf.yml at the repo root; this is the proven local path from
            # tools/backup-agent. Prompt goes via --message-file (aider has no stdin message mode),
            # so this spec is PromptFile and the job runs it with cwd = worktree.
            $aiderExe = Join-Path $env:USERPROFILE '.backup-agent-venv\Scripts\aider.exe'
            if (-not (Test-Path $aiderExe)) {
                throw "aider not found at $aiderExe -- create the venv per tools/backup-agent/README.md"
            }
            @{ Exe        = $aiderExe
               Args       = @('--no-pretty', '--no-stream', '--no-restore-chat-history',
                              '--no-auto-commits', '--yes-always', '--subtree-only',
                              '--message-file', '{PROMPT_FILE}')
               Local      = $true
               PromptFile = $true }
        }
        'cursor' {
            # Standalone cursor-agent CLI. Install: see tools/agents/README.md. -p = print mode
            # (non-interactive), --force lets it edit without per-tool prompts.
            # Resolve the .cmd shim explicitly: the installer's dir (%LOCALAPPDATA%\cursor-agent)
            # is on the *user* PATH but not necessarily this process's, and the bare name can
            # resolve to cursor-agent.ps1 which Restricted execution policy blocks. The .cmd shim
            # re-invokes the .ps1 with -ExecutionPolicy Bypass, so it always works.
            $cursorExe = Resolve-CursorAgent
            # cursor-agent 3.x: --workspace sets the root (no --cwd); --trust skips the
            # workspace-trust prompt; -p --force = non-interactive with all tools allowed.
            @{ Exe = $cursorExe; Args = @('--workspace', $Worktree, '--trust', '-p', '--force', '--output-format', 'text'); Local = $false }
        }
        default { throw "Unknown worker '$Worker' in task (want: chatgpt | aider | qwen | qwen-big | cursor)" }
    }
}

# --- the per-task job -----------------------------------------------------------------------------
# Runs inside a background job. Creates the worktree, runs the worker, captures the patch, verifies.
$jobBody = {
    param($RepoRoot, $WtParent, $RunDir, $LocalLock, $Task, $WorkerSpec, $ScriptRoot)

    $ErrorActionPreference = 'Continue'
    $env:PYTHONIOENCODING = 'utf-8'; $env:PYTHONUTF8 = '1'

    $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
    $outDir = Join-Path $RunDir $Task.Id
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    $log    = Join-Path $outDir "$stamp.log"
    $patch  = Join-Path $outDir 'changes.patch'
    $vout   = Join-Path $outDir 'verify.txt'
    $result = Join-Path $outDir 'RESULT.json'
    $wt     = Join-Path $WtParent $Task.Id

    function Log($m) { $line = "[{0:HH:mm:ss}] {1}" -f (Get-Date), $m; $line | Tee-Object -FilePath $log -Append | Out-Host }

    $started = Get-Date
    $status  = 'error'
    try {
        # Fresh worktree off the task's base. Remove any stale one first: shut down the build
        # servers (they keep handles into bin/ that make the remove fail "resource busy"), drop the
        # artifacts junction (via its own Delete(), so git never recurses into the real artifacts),
        # then remove.
        if (Test-Path $wt) {
            dotnet build-server shutdown 2>&1 | Out-Null
            $j = Join-Path $wt 'artifacts'
            if (Test-Path $j) { try { (Get-Item $j).Delete() } catch {} }
            git -C $RepoRoot worktree remove --force $wt 2>&1 | Out-Null
            if (Test-Path $wt) { Remove-Item -Recurse -Force $wt -ErrorAction SilentlyContinue }
        }
        Log "worktree add -> $wt (base $($Task.Base))"
        git -C $RepoRoot worktree add --detach $wt $Task.Base 2>&1 | Tee-Object -FilePath $log -Append | Out-Null
        if (-not (Test-Path $wt)) { throw "worktree was not created" }

        # artifacts/ is gitignored build output (FmodFsbDecoder.exe et al.) that the App project's
        # build step copies -- a fresh worktree has none, so dotnet test fails to build. Junction the
        # main checkout's artifacts/ in so verify sees the prebuilt tools. It stays ignored.
        $srcArtifacts = Join-Path $RepoRoot 'artifacts'
        if (Test-Path $srcArtifacts) {
            New-Item -ItemType Junction -Path (Join-Path $wt 'artifacts') -Target $srcArtifacts -ErrorAction SilentlyContinue | Out-Null
        }

        $baseSha = (git -C $wt rev-parse HEAD).Trim()

        # Local (ollama) workers share one GPU -- take an exclusive lock, wait up to 40 min.
        $lockHandle = $null
        if ($WorkerSpec.Local) {
            Log "waiting for local GPU lock..."
            $deadline = (Get-Date).AddMinutes(40)
            while ($true) {
                try { $lockHandle = [IO.File]::Open($LocalLock, 'OpenOrCreate', 'ReadWrite', 'None'); break }
                catch { if ((Get-Date) -gt $deadline) { throw "timed out waiting for local GPU lock" }; Start-Sleep 15 }
            }
            Log "got GPU lock"
        }

        try {
            $prompt = "You are running NON-INTERACTIVELY with no human on the other end. " +
                      "Do NOT enter plan mode. Do NOT call CreatePlan, AskQuestion, or any tool that waits " +
                      "for user approval -- there is nobody to approve it and the run will end with zero changes. " +
                      "Do your research, pick the sensible default wherever the task says 'ask' or leaves a choice, " +
                      "then IMPLEMENT the change directly with file edits. Leave your reasoning in the code / a " +
                      "docs/research note, not in a plan.`n`n" +
                      "You are working in an isolated git worktree for the BioShock->UE5 project. " +
                      "Follow docs/ENGINEERING_RULES.md and CLAUDE.md. Make ONLY the change described below. " +
                      "Do not commit, do not push, do not touch files outside the stated lane. When done, stop.`n" +
                      "Write any scratch / build / export output to `$env:TEMP, NOT into the worktree -- " +
                      "everything left in the worktree is captured as the review patch.`n`n" +
                      "LANE (stay inside): $($Task.Lane)`n`n--- TASK ---`n$($Task.Prompt)"
            Log "worker: $($WorkerSpec.Exe) $($WorkerSpec.Args -join ' ')"
            $prompt | Out-File -LiteralPath (Join-Path $outDir 'prompt.txt') -Encoding utf8

            # codex writes its agent transcript to stdout and only diagnostics to stderr. Keep
            # stderr OUT of the pipeline (-> its own file): merged in, PS 5.1 turns each stderr line
            # into an ErrorRecord that crosses the job boundary as a RemoteException and spams the
            # console. stdout is teed to the log live.
            $errFile = Join-Path $outDir 'worker.stderr.log'

            if ($WorkerSpec.PromptFile) {
                # aider has no stdin-message mode: hand it the prompt file and run with the
                # worktree as cwd (aider keys off cwd for the git repo; no --cd/--workspace).
                $promptPath = Join-Path $outDir 'prompt.txt'
                $specArgs   = $WorkerSpec.Args | ForEach-Object { $_ -replace '\{PROMPT_FILE\}', $promptPath }
                $env:OLLAMA_API_BASE = 'http://localhost:11434'
                Push-Location $wt
                & $WorkerSpec.Exe @($specArgs) 2>$errFile | Tee-Object -FilePath $log -Append
                $workerExit = $LASTEXITCODE
                Pop-Location
            }
            else {
                $prompt | & $WorkerSpec.Exe @($WorkerSpec.Args) 2>$errFile | Tee-Object -FilePath $log -Append
                $workerExit = $LASTEXITCODE
            }
            if (Test-Path $errFile) { "--- worker stderr ---`n$(Get-Content $errFile -Raw)" | Out-File -LiteralPath $log -Append -Encoding utf8 }
            Log "worker exit: $workerExit"
        }
        finally {
            if ($lockHandle) { $lockHandle.Close(); $lockHandle.Dispose(); Log "released GPU lock" }
        }

        # Capture everything the worker changed, including new files (-N = intent-to-add so they
        # show in the diff and git apply can recreate them). `--output=` makes git write the file
        # itself -- piping through PS 5.1 re-encodes via the console codepage and mangles any
        # non-ASCII (em-dash -> "ΓÇö"), which then applies as garbage.
        git -C $wt add -A -N 2>&1 | Out-Null
        git -C $wt diff HEAD --output=$patch
        $diffStat = (git -C $wt diff --shortstat HEAD | Out-String).Trim()
        $changed  = (git -C $wt diff --name-only HEAD | Where-Object { $_ }).Count
        Log "changes: $diffStat"
        $patchMB = [math]::Round((Get-Item $patch).Length / 1MB, 1)
        if ($patchMB -ge 5) {
            Log "WARNING: patch is ${patchMB} MB -- the worker likely wrote build/export output"
            Log "         into the worktree. Review before apply; do NOT apply blind."
        }

        if ($changed -eq 0) {
            $status = 'no-change'
            Log "worker produced no changes -- check the log"
        }
        else {
            Log "verify: $($Task.Verify)"
            Push-Location $wt
            $vtext = & cmd /c "$($Task.Verify) 2>&1" | ForEach-Object { "$_" }
            $verifyExit = $LASTEXITCODE
            Pop-Location
            $vtext | Out-File -LiteralPath $vout -Encoding utf8
            $vtext | Select-Object -Last 8 | ForEach-Object { Log "  | $_" }
            $status = if ($verifyExit -eq 0) { 'pass' } else { 'fail' }
            Log "verify -> $status (exit $verifyExit)"
        }
    }
    catch {
        $status = 'error'
        Log "ERROR: $_"
    }
    finally {
        [pscustomobject]@{
            id        = $Task.Id
            worker    = $Task.Worker
            base      = $Task.Base
            baseSha   = $baseSha
            worktree  = $wt
            patch     = $patch
            status    = $status
            diffstat  = $diffStat
            filesChanged = $changed
            started   = $started.ToString('o')
            finished  = (Get-Date).ToString('o')
            minutes   = [math]::Round(((Get-Date) - $started).TotalMinutes, 1)
        } | ConvertTo-Json | Out-File -LiteralPath $result -Encoding utf8
        Log "RESULT: $status  (worktree left at $wt for review)"
    }
}

# --- commands ---------------------------------------------------------------------------------
function Invoke-List {
    $pending = Get-PendingTasks
    if (-not $pending) { Write-Host "No pending tasks in $taskDir"; return }
    Write-Host "Pending tasks:`n"
    $pending | Format-Table Id, Worker, Base, @{ n = 'Lane'; e = { $_.Lane } } -AutoSize
    Write-Host "Run them with:  powershell -NoProfile -ExecutionPolicy Bypass -File tools\agents\orchestrator.ps1 run"
}

function Invoke-Run {
    $pending = Get-PendingTasks
    if ($Task) { $pending = $pending | Where-Object { $_.Id -eq $Task } }
    if (-not $pending) { Write-Host "Nothing to run."; return }

    # Preflight: workers referenced must exist.
    $needCursor = $pending.Worker -contains 'cursor'
    if ($needCursor) {
        $cursorCmd = Join-Path $env:LOCALAPPDATA 'cursor-agent\cursor-agent.cmd'
        if (-not (Test-Path $cursorCmd) -and -not (Get-Command cursor-agent.cmd, cursor-agent -ErrorAction SilentlyContinue)) {
            throw "A task wants worker 'cursor' but cursor-agent was not found (%LOCALAPPDATA%\cursor-agent or PATH). See tools/agents/README.md."
        }
    }
    if (($pending.Worker | Where-Object { $_ -ne 'cursor' }) -and -not (Get-Command codex -ErrorAction SilentlyContinue)) {
        throw "codex CLI not found on PATH."
    }

    Write-Host ("Dispatching {0} task(s), up to {1} in parallel. Worktrees under {2}\`n" -f $pending.Count, $Parallel, $wtParent)

    $jobs = @()
    foreach ($t in $pending) {
        while (@(Get-Job -State Running).Count -ge $Parallel) {
            Start-Sleep 3
            $jobs | Receive-Job -ErrorAction SilentlyContinue 2>$null
        }
        $spec = Get-WorkerSpec -Worker $t.Worker -Worktree (Join-Path $wtParent $t.Id)
        Write-Host "  -> $($t.Id)  [$($t.Worker)]"
        $jobs += Start-Job -Name "agent-$($t.Id)" -ScriptBlock $jobBody -ArgumentList `
            $repoRoot, $wtParent, $runDir, $localLock, $t, $spec, $PSScriptRoot
    }

    Write-Host "`nWaiting for workers to finish (Ctrl-C is safe -- jobs keep running; re-check with 'status')...`n"
    $jobs | Wait-Job | Out-Null
    $jobs | Receive-Job -ErrorAction SilentlyContinue 2>$null
    $jobs | Remove-Job -Force
    Write-Host ""
    Invoke-Status
    # Workers' stderr can leave $? false even when every job finished and wrote a RESULT -- the
    # status table above is the real outcome. Don't let that surface as a scary script exit code.
    $global:LASTEXITCODE = 0
}

function Invoke-Status {
    if (-not (Test-Path $runDir)) { Write-Host "No runs yet."; return }
    $rows = Get-ChildItem $runDir -Directory | ForEach-Object {
        $r = Join-Path $_.FullName 'RESULT.json'
        if (Test-Path $r) { Get-Content $r -Raw | ConvertFrom-Json }
    }
    if (-not $rows) { Write-Host "No completed runs."; return }
    $rows | Sort-Object finished | Format-Table `
        @{ n = 'Task'; e = { $_.id } },
        @{ n = 'Worker'; e = { $_.worker } },
        @{ n = 'Status'; e = { $_.status } },
        @{ n = 'Files'; e = { $_.filesChanged } },
        @{ n = 'Diff'; e = { $_.diffstat } },
        @{ n = 'Min'; e = { $_.minutes } } -AutoSize
    Write-Host "Patches: $runDir\<task>\changes.patch"
    Write-Host "Apply a reviewed one into the main tree (no commit):  ...orchestrator.ps1 apply -Task <id>"
}

function Invoke-Apply {
    if (-not $Task) { throw "apply needs -Task <id>" }
    $patch = Join-Path $runDir "$Task\changes.patch"
    if (-not (Test-Path $patch)) { throw "no patch at $patch -- run the task first" }
    if ((git -C $repoRoot status --porcelain).Length -gt 0) {
        Write-Warning "Main tree is dirty. Apply anyway? Ctrl-C to abort."
        Start-Sleep 4
    }
    Write-Host "git apply --3way $patch"
    git -C $repoRoot apply --3way --whitespace=nowarn $patch
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nApplied. Review with 'git -C `"$repoRoot`" diff', then commit by hand and create tools/agents/tasks/$Task.done"
    } else {
        throw "git apply failed -- inspect $patch and the worktree at $wtParent\$Task"
    }
}

function Invoke-Clean {
    dotnet build-server shutdown 2>&1 | Out-Null
    # Every registered agent worktree (new layout: under BioShockHavok-agents\ ; old layout:
    # sibling BioShockHavok-agent-* dirs — both matched).
    git -C $repoRoot worktree list --porcelain | Select-String '^worktree (.+[\\/](BioShockHavok-agents[\\/].+|BioShockHavok-agent-.+))$' | ForEach-Object {
        $wt = $_.Matches[0].Groups[1].Value
        Write-Host "worktree remove $wt"
        # Drop the artifacts junction via Delete() (not rmdir/Remove-Item -Recurse, which would
        # follow it into the real artifacts) so 'worktree remove' doesn't walk into the main tree.
        $j = Join-Path $wt 'artifacts'
        if (Test-Path $j) { try { (Get-Item $j).Delete() } catch {} }
        git -C $repoRoot worktree remove --force $wt 2>&1 | Out-Null
        if (Test-Path $wt) { Remove-Item -Recurse -Force $wt -ErrorAction SilentlyContinue }
    }
    git -C $repoRoot worktree prune
    # Orphaned dirs git no longer tracks (old sibling layout, or a killed run).
    Get-ChildItem -Directory (Split-Path -Parent $repoRoot) -Filter 'BioShockHavok-agent-*' -ErrorAction SilentlyContinue | ForEach-Object {
        $j = Join-Path $_.FullName 'artifacts'
        if (Test-Path $j) { try { (Get-Item $j).Delete() } catch {} }
        Write-Host "rm orphan $($_.FullName)"
        Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue
    }
    if (Test-Path $wtParent) {
        Get-ChildItem -Directory $wtParent -ErrorAction SilentlyContinue | Where-Object {
            -not (git -C $repoRoot worktree list --porcelain | Select-String ([regex]::Escape($_.FullName)))
        } | ForEach-Object { Write-Host "rm orphan $($_.FullName)"; Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue }
    }
    Write-Host "Done. runs/ logs and patches are kept -- delete tools/agents/runs/<id> by hand if you want them gone."
}

switch ($Command) {
    'list'   { Invoke-List }
    'run'    { Invoke-Run }
    'status' { Invoke-Status }
    'apply'  { Invoke-Apply }
    'clean'  { Invoke-Clean }
}
