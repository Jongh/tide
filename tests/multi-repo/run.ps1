# tide multi-repo live test (Windows PowerShell 5.1) -- verifies repo-root-aware hooks\tide-guard.ps1
#
# Self-contained runner: creates 2 child repos under a temp parent, invokes the modified
# hooks\tide-guard.ps1 directly with synthetic hook-input JSON fixtures, asserts exit codes,
# then cleans up. The guard reads JSON from stdin, so we inject via Start-Process
# -RedirectStandardInput and read the real exit code via -PassThru -Wait .ExitCode.
#
# NOTE: blocked verbs (commit/tag/push) appear ONLY inside this script's fixture strings.
# The command line that LAUNCHES this script must contain no block pattern, so the active
# tide-guard does not block it. (English-only output: keeps this file BOM-independent;
# the guard itself carries the Korean message and is stored as UTF-8 with BOM.)
#
# Hook-input fixtures (in.json) are written as no-BOM UTF-8: PS 5.1 `Set-Content -Encoding
# utf8` prepends a BOM, and the guard reads the fixture raw via [Console]::In (no auto
# BOM-strip), so a BOM-laden fixture broke parsing under a non-PS console and flipped 4
# scenarios (sn2). Scenario 9 deliberately re-adds a BOM to regression-test the guard's own
# leading-BOM tolerance (T03). The .tide/phase writes below keep `Set-Content -Encoding utf8`
# (harmless: the guard reads phase via Get-Content, which strips the BOM on read).
#
# Usage: & tests\multi-repo\run.ps1   (exit 0 if all pass, exit 1 if any fail)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$guard = Join-Path $repoRoot 'hooks\tide-guard.ps1'
if (-not (Test-Path $guard)) { Write-Host "guard script not found: $guard"; exit 1 }

$sbx = Join-Path ([System.IO.Path]::GetTempPath()) "tide-mr-live.$PID"
if (Test-Path $sbx) { Remove-Item -Recurse -Force $sbx }
New-Item -ItemType Directory -Path $sbx | Out-Null

$script:pass = 0
$script:fail = 0

# Completion guard (M37 rework 4) -- a runner that dies partway must never look green.
# The M37 review blocker: one PowerShell-version-only error aborted the run, most cases never ran,
# `$script:fail` was still 0, and the script printed its success banner and exited 0. Two mechanisms
# close that: the trap turns any terminating error into a loud exit 1, and the completed flag
# (set ONLY by the result line) catches every other way of skipping the end of the run.
# Keep the TRAP identical in all six run.ps1. The completed flag is in FIVE of the six -- see the
# comment in tests/site-includes/run.ps1 for why that runner deliberately carries the trap alone.
$script:completed = $false
trap {
    Write-Host "`n# ABORTED at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    Write-Host "# INCOMPLETE RUN -- the harness did not reach its result line; treat as FAIL"
    exit 1
}

# === supported launch context (M38-T05) =================================
# DIAGNOSIS. This runner used to score 29/1 when started from a Git Bash host and 30/0 from a native
# PowerShell host (both PS versions). The single failing case was scenario 9, "blocks commit [BOM
# input -> cwd, not CPD]". Cause, measured: the guard reads its hook input with [Console]::In, whose
# decoding comes from [Console]::InputEncoding -- i.e. the CONSOLE INPUT CODE PAGE, which a child
# process inherits from the launching host. Measured on the same machine:
#   * native PowerShell host -> child console input CP 65001 (UTF-8): the 3 BOM bytes are absorbed
#     by the UTF-8 decoder, the guard sees a clean '{' and parses.
#   * Git Bash host          -> child console input CP 949 (the ANSI page): EF BB decodes as ONE
#     double-byte char (U+7664) and BF as U+003F, so the leading characters are neither U+FEFF nor
#     U+00EF U+00BB U+00BF -- the two forms the guard strips. ConvertFrom-Json then throws, $cwd
#     stays null, the guard falls back to CLAUDE_PROJECT_DIR (which has NO phase) and ALLOWS.
# So the axis is the LAUNCH CONTEXT (console input code page), not the BOM and not $OutputEncoding.
#
# DISPOSITION (b): declare + enforce. Option (a) -- make any host give the same verdict -- would
# mean either hardening the guard's BOM strip (the hook is UNTOUCHED this cycle by milestone
# invariant) or having this runner rewrite the shared console's code page (a side effect on the
# user's terminal that would also HIDE the guard's real fragility). So the supported launch context
# is declared in this harness's README and enforced HERE: the runner probes its own delivery channel
# before asserting anything, and refuses loudly outside it. It must not quietly return a different
# verdict -- that silent divergence is the entire class M38 exists to remove.
# The guard-side robustness gap (a BOM mangled by a non-UTF-8 console page) is recorded as carried
# forward, not fixed here.
#
# The probe is BEHAVIOURAL, not a code-page allowlist: it sends EF BB BF + '{}' down the very same
# Start-Process stdin path and asks whether the leading BOM arrived in a form the guard strips.
# Hardcoding "CP must be 65001" would red the CI legs that pass today for the right reason.
function Test-StdinChannel {
    $probeIn = Join-Path $sbx 'probe-in.json'
    [System.IO.File]::WriteAllBytes($probeIn,
        ([byte[]](0xEF, 0xBB, 0xBF) + [System.Text.Encoding]::ASCII.GetBytes('{}')))
    $probePs = Join-Path $sbx 'probe-stdin.ps1'
    # ok = after removing whatever the leading BOM became, the payload is intact '{}'. Three shapes
    # are acceptable because all three leave the guard able to parse:
    #   * nothing left of it   -- the UTF-8 decoder absorbed the preamble (CP 65001 hosts)
    #   * one U+FEFF           -- decoded as the BOM character
    #   * U+00EF U+00BB U+00BF -- byte-preserving single-byte page; the guard strips this form too
    # Anything else (e.g. CP 949 turning EF BB into one U+7664) means the channel mangles bytes.
    # The probe compares CODE POINTS, never a literal BOM: this file stays ASCII-only (0 bytes > 127).
    $probeBody = @'
$s = [Console]::In.ReadToEnd()
$c = @($s.ToCharArray())
$i = 0
if ($c.Count -ge 1 -and [int]$c[0] -eq 0xFEFF) { $i = 1 }
elseif ($c.Count -ge 3 -and [int]$c[0] -eq 0xEF -and [int]$c[1] -eq 0xBB -and [int]$c[2] -eq 0xBF) { $i = 3 }
if ($c.Count -eq ($i + 2) -and $c[$i] -eq '{' -and $c[$i + 1] -eq '}') {
    Write-Output 'ok'
} else {
    Write-Output 'mangled'
}
'@
    [System.IO.File]::WriteAllText($probePs, $probeBody, (New-Object System.Text.UTF8Encoding($false)))
    $probeOut = Join-Path $sbx 'probe-out.txt'
    Start-Process -FilePath 'powershell' `
        -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$probePs `
        -RedirectStandardInput $probeIn -RedirectStandardOutput $probeOut `
        -NoNewWindow -Wait | Out-Null
    if (-not (Test-Path $probeOut)) { return 'mangled' }
    return ((Get-Content $probeOut -Raw) -replace '\s', '')
}

$channel = Test-StdinChannel
if ($channel -ne 'ok') {
    Write-Host "# UNSUPPORTED LAUNCH CONTEXT -- stdin byte channel is mangled (probe: '$channel')"
    Write-Host "# console input code page: $([Console]::InputEncoding.CodePage) ($([Console]::InputEncoding.WebName))"
    Write-Host "# This harness feeds hooks\tide-guard.ps1 through stdin, and the guard decodes stdin with"
    Write-Host "# the CONSOLE INPUT code page inherited from the launching host. On a non-UTF-8 page the"
    Write-Host "# BOM regression case (scenario 9) silently flips instead of failing, so this runner"
    Write-Host "# refuses to produce a verdict here. Launch it from a native PowerShell/pwsh host"
    Write-Host "# (see tests/multi-repo/README.md, 'supported launch context'), not from Git Bash."
    Remove-Item -Recurse -Force $sbx -ErrorAction SilentlyContinue
    exit 1
}

function Invoke-Guard($cpd, $cwd, $cmd, $bom = $false) {
    $obj = @{ tool_input = @{ command = $cmd } }
    if ($cwd) { $obj['cwd'] = $cwd }
    $fixture = Join-Path $sbx 'in.json'
    # Write the hook-input fixture as no-BOM UTF-8. PS 5.1 `Set-Content -Encoding utf8`
    # prepends a BOM, and PS 5.1 ConvertFrom-Json THROWS on a leading BOM when the guard
    # is run under a non-PowerShell console (e.g. Git Bash/MSYS) -- which silently flipped
    # 4 scenarios (sn2). The guard reads this fixture raw via [Console]::In (not Get-Content,
    # so no auto BOM-strip), so the fixture must be clean. When $bom is set we DELIBERATELY
    # prepend a BOM to regression-test the guard's own BOM tolerance (T03 strip).
    $json = $obj | ConvertTo-Json -Compress -Depth 5
    [System.IO.File]::WriteAllText($fixture, $json, (New-Object System.Text.UTF8Encoding($false)))
    if ($bom) {
        $bytes = [byte[]](0xEF, 0xBB, 0xBF) + [System.IO.File]::ReadAllBytes($fixture)
        [System.IO.File]::WriteAllBytes($fixture, $bytes)
    }
    $out = Join-Path $sbx 'out.txt'; $err = Join-Path $sbx 'err.txt'
    $prev = $env:CLAUDE_PROJECT_DIR
    if ($cpd) { $env:CLAUDE_PROJECT_DIR = $cpd } else { Remove-Item Env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
    try {
        $p = Start-Process -FilePath 'powershell' `
            -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$guard `
            -RedirectStandardInput $fixture -RedirectStandardOutput $out -RedirectStandardError $err `
            -NoNewWindow -Wait -PassThru
        return $p.ExitCode
    } finally {
        if ($null -ne $prev) { $env:CLAUDE_PROJECT_DIR = $prev } else { Remove-Item Env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
    }
}

function Check($desc, $cpd, $cwd, $cmd, $want, $bom = $false) {
    $got = Invoke-Guard $cpd $cwd $cmd $bom
    if ($got -eq $want) {
        $script:pass++; Write-Host ("PASS  {0,-50} (exit {1})" -f $desc, $got)
    } else {
        $script:fail++; Write-Host ("FAIL  {0,-50} (got {1}, want {2})" -f $desc, $got, $want)
    }
}

try {
    Write-Host "# tide multi-repo live test (PowerShell)"
    Write-Host "# guard: $guard"
    Write-Host "# sandbox: $sbx`n"

    $A = Join-Path $sbx 'child-a'; $B = Join-Path $sbx 'child-b'; $PLAIN = Join-Path $sbx 'plain'
    New-Item -ItemType Directory -Path $A, $B, $PLAIN | Out-Null
    & git -C $A init -q | Out-Null
    & git -C $B init -q | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $A '.tide'), (Join-Path $B '.tide'), (Join-Path $A 'sub') | Out-Null
    $Aphase = Join-Path $A '.tide\phase'; $Bphase = Join-Path $B '.tide\phase'

    $BLOCK = 'git commit -m x'
    $TAG = 'git tag v1.0.0'
    $SAFE = 'git status'

    # 1: non-release child blocks
    'impl' | Set-Content $Aphase -Encoding utf8
    Check "A(impl) blocks commit" $sbx $A $BLOCK 2
    Check "A(impl) blocks tag" $sbx $A $TAG 2
    # 2: release child allows
    'release' | Set-Content $Aphase -Encoding utf8
    Check "A(release) allows commit" $sbx $A $BLOCK 0
    # 3: per-repo isolation
    'impl' | Set-Content $Bphase -Encoding utf8
    Check "B(impl) still blocked while A=release" $sbx $B $BLOCK 2
    # 4: subdir cwd -> repo root resolution
    'impl' | Set-Content $Aphase -Encoding utf8
    Check "A\sub(impl) blocked (subdir->root)" $sbx (Join-Path $A 'sub') $BLOCK 2
    # 5: safe command always allowed
    Check "A(impl) git status allowed" $sbx $A $SAFE 0
    # 6: fallback -- no cwd + CPD=A(impl)
    Check "no cwd -> CPD(A,impl) fallback blocks" $A $null $BLOCK 2
    # 7: fallback -- non-repo + no phase
    Check "non-repo cwd + no phase -> allow" $PLAIN $PLAIN $BLOCK 0
    # 8: single-repo regression
    'release' | Set-Content $Aphase -Encoding utf8
    Check "single-repo: A(release) root cwd allows" $A $A $BLOCK 0
    'impl' | Set-Content $Aphase -Encoding utf8
    Check "single-repo: A(impl) root cwd blocks" $A $A $BLOCK 2

    # 9: BOM-prefixed input tolerated -- same verdict as no-BOM (sn2 / T03 guard BOM strip).
    # Discriminating setup: cwd=A(phase set) must drive the verdict; CPD=$sbx has NO phase, so
    # if a leading BOM broke cwd extraction (pre-T03, as happens under a non-PS console) the
    # guard would fall back to $sbx and FLIP (block->allow / allow->block). Asserting the
    # cwd-driven verdict under BOM input therefore pins the guard's BOM tolerance. (In a pure
    # PowerShell console the BOM is absorbed by [Console]::In so this also passes pre-strip;
    # under Git Bash/MSYS it is genuinely discriminating -- that is where sn2 surfaced.)
    'impl' | Set-Content $Aphase -Encoding utf8
    Check "A(impl) blocks commit [BOM input -> cwd, not CPD]" $sbx $A $BLOCK 2 $true
    'release' | Set-Content $Aphase -Encoding utf8
    Check "A(release) allows commit [BOM input -> cwd, not CPD]" $sbx $A $BLOCK 0 $true

    # 10: read/write discrimination (M28) -- non-release blocks git *writes* only; *reads* pass.
    # Same impl phase asserts reads-allow AND writes-block together, pinning "guard is alive yet
    # reads pass" (negative control). The verb is judged at the git *subcommand* position only
    # (substring matches in option values / paths / compound subcommand names are ignored).
    'impl' | Set-Content $Aphase -Encoding utf8
    # reads (allow, exit 0)
    Check "A(impl) git tag -l allowed (tag list=read)" $sbx $A 'git tag -l' 0
    Check "A(impl) git tag -l pattern allowed (list opt->positional=pattern)" $sbx $A "git tag -l 'v2.*'" 0
    Check "A(impl) git tag --contains allowed (tag query)" $sbx $A 'git tag --contains HEAD' 0
    Check "A(impl) git log --grep=commit allowed (option value)" $sbx $A 'git log --grep=commit' 0
    Check "A(impl) git show HEAD:path allowed (path substring)" $sbx $A 'git show HEAD:src/tag.rs' 0
    Check "A(impl) git cat-file commit allowed (not subcommand)" $sbx $A 'git cat-file commit HEAD' 0
    Check "A(impl) git commit-graph allowed (compound subcommand)" $sbx $A 'git commit-graph verify' 0
    Check "A(impl) git tag redirect allowed (list>file=read)" $sbx $A 'git tag > /tmp/t.txt' 0
    # writes (block, exit 2)
    Check "A(impl) git tag create blocked (positional=create)" $sbx $A 'git tag v2.6.0' 2
    Check "A(impl) git tag -d delete blocked" $sbx $A 'git tag -d v1' 2
    Check "A(impl) git push --tags blocked" $sbx $A 'git push --tags' 2
    Check "A(impl) git -C .. commit blocked (global-opt prefix)" $sbx $A 'git -C ../other commit -m x' 2

    # 11: phase=debug guard regression (M29 decision 2) -- debug is phase!=release, so the
    # EXISTING rules apply with the guard left unmodified: writes block, reads pass.
    # As in scenario 10, reads-allow AND writes-block are asserted together in the same phase
    # (negative control -- without it a debug branch that killed the guard outright would still
    # leave the read cases green).
    'debug' | Set-Content $Aphase -Encoding utf8
    # reads (allow, exit 0)
    Check "A(debug) git log allowed (history read)" $sbx $A 'git log' 0
    Check "A(debug) git tag -l allowed (tag list=read)" $sbx $A 'git tag -l' 0
    Check "A(debug) git show HEAD:path allowed (history file read)" $sbx $A 'git show HEAD:README.md' 0
    # writes (block, exit 2)
    Check "A(debug) git commit blocked (guard unmodified)" $sbx $A $BLOCK 2
    Check "A(debug) git push blocked (guard unmodified)" $sbx $A 'git push' 2
    Check "A(debug) git tag -a blocked (annotated tag create=write)" $sbx $A 'git tag -a v1 -m x' 2

    # === case-count self-consistency (M38-T01) ==========================
    # The completion guard (M37) catches a runner that ABORTS; it does not catch one that stays
    # alive and RUNS LESS (a branch skipping a scenario, a non-terminating error walking past a
    # case). The expected case count has a single declaration site -- this harness's README
    # (convention: the document self-description section of docs/conventions.md) -- never
    # hardcoded here. If the declaration cannot be read (file missing / no `cases` token) the
    # extraction is empty and this FAILS: "could not read it, so skip and pass" is the class
    # this kills. The case is itself a case, so it goes LAST and compares running-total + 1
    # (same shape as `tests/discover` F1; identical assertion name and verdict in both shells).
    # `Check` here is exit-code-only, so this asserts inline against the same counters.
    $ccPath = Join-Path $repoRoot 'tests\multi-repo\README.md'
    $ccGot = ''
    if (Test-Path $ccPath) {
        $ccRaw = [System.IO.File]::ReadAllText($ccPath, [System.Text.Encoding]::UTF8)
        $ccM = [regex]::Match($ccRaw, 'cases:[^0-9\r\n]*([0-9]+)')
        if ($ccM.Success) { $ccGot = $ccM.Groups[1].Value }
    }
    $ccDesc = 'case-count: README cases declaration == actual'
    $ccWant = [string]($script:pass + $script:fail + 1)
    if ($ccGot -eq $ccWant) {
        $script:pass++; Write-Host ("PASS  {0,-50} ({1})" -f $ccDesc, $ccGot)
    } else {
        $script:fail++; Write-Host ("FAIL  {0,-50} (got {1}, want {2})" -f $ccDesc, $ccGot, $ccWant)
    }

    Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail) [runtime: PowerShell $($PSVersionTable.PSVersion) $($PSVersionTable.PSEdition)]"
    $script:completed = $true
}
finally {
    Remove-Item -Recurse -Force $sbx -ErrorAction SilentlyContinue
}

if (-not $script:completed) {
    Write-Host "# INCOMPLETE RUN -- the harness did not reach its result line; treat as FAIL"
    exit 1
}
if ($script:fail -ne 0) { exit 1 }
Write-Host "# all scenarios passed -- repo-root aware / isolation / fallback / phase=debug confirmed (ps1)"
exit 0
