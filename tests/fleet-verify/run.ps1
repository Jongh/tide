# tide fleet-verify live test (Windows PowerShell 5.1) -- integration-verify hook deterministic core
#
# fleet-verify is a prompt skill; the actual integration-hook run is LLM behavior. This exercises a
# REFERENCE of its deterministic core (hook discovery/parse = BOM/comment/blank handling / opt-in
# skip / exit code -> pass|fail mapping / verification-only = no release|git stage in the plan /
# .tide-fleet hidden -> discovery ignores it) against fixtures. The single source is
# docs/conventions.md "multi-repo orchestration" integration-verify section; the actual hook run
# quality is split into README's session-level manual procedure.
#
# ASCII-only source (BOM-independent). git mutating verbs live only in setup (init only -- no
# commits). Mock integration hooks use portable commands (exit 0 / exit 1), never git verbs.
# release/git are NOT fleet-verify behavior (verification-only) -- this runner actively asserts
# release/git are absent from the automated plan.
#
# Usage: & tests\fleet-verify\run.ps1   (exit 0 if all pass, exit 1 if any fail)

$ErrorActionPreference = 'SilentlyContinue'

$ROOT = Split-Path (Split-Path $PSScriptRoot)
. (Join-Path $ROOT 'tests\lib\encoding.ps1')   # StripBom (single source; used by ReadHook)
. (Join-Path $ROOT 'tests\lib\discover.ps1')   # IsTideRepo + Discover (single source)

$sbx = Join-Path ([System.IO.Path]::GetTempPath()) "tide-fleet-verify-live.$PID"
if (Test-Path $sbx) { Remove-Item -Recurse -Force $sbx }
New-Item -ItemType Directory -Force -Path $sbx | Out-Null

$script:pass = 0; $script:fail = 0

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
# M42-T03: verdict pinned to ORDINAL -- PowerShell's `-eq` on strings is CULTURE comparison
# (and `-ceq` is case-sensitive but still culture-aware, so it is no substitute), while the .sh
# twin's `[ "$got" = "$want" ]` is byte-exact. The [string] casts also stop an ARRAY $got from
# passing vacuously (`-eq` on an array returns the filtered subarray, which is truthy when non-empty).
function Chk($desc, $got, $want) {
    if ([string]::Equals([string]$got, [string]$want, [System.StringComparison]::Ordinal)) { $script:pass++; Write-Host ("PASS  {0,-56} ({1})" -f $desc, $got) }
    else { $script:fail++; Write-Host ("FAIL  {0,-56} (got {1}, want {2})" -f $desc, $got, $want) }
}
function W($path, $text) { $d = Split-Path $path -Parent; if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }; Set-Content -Path $path -Value $text -Encoding utf8 }
function GitInit($d) { New-Item -ItemType Directory -Force -Path $d | Out-Null; & git -C $d init -q }   # dir must exist before init

# IsTideRepo + Discover moved to tests\lib\discover.ps1 (single source; .tide-fleet hidden-skip included); dot-sourced at top.

# --- integration hook parse reference: read .tide-fleet/integration, strip leading BOM, skip #/blank ---
# StripBom is single-sourced in tests\lib\encoding.ps1 (dot-sourced above); ReadHook uses it as-is.
function ReadHook($parent) {
    $f = Join-Path $parent '.tide-fleet\integration'
    if (-not (Test-Path $f)) { return @() }
    $lines = @(Get-Content $f)
    if ($lines.Count -gt 0) { $lines[0] = StripBom $lines[0] }
    $out = @()
    foreach ($line in $lines) {
        $t = $line.Trim()
        # (M42-T03) ordinal StartsWith -- culture StartsWith matches through ignorable characters, so a
        # hook line the .sh twin treats as a command would be dropped as a comment here.
        if ($t -eq '' -or $t.StartsWith('#', [System.StringComparison]::Ordinal)) { continue }
        $out += $t
    }
    return $out
}
function HookClass($parent) {
    $out = @(ReadHook $parent)
    if ($out.Count -ge 1) { return 'declared' } else { return 'skip' }
}

# --- pass/fail reference: run hook at parent cwd -> exit 0 = pass, non-zero = fail (no git verbs) ---
function RunHook($parent) {
    if ((HookClass $parent) -eq 'skip') { return 'skip' }
    $rc = 0
    $prev = Get-Location
    Set-Location $parent
    foreach ($cmd in (ReadHook $parent)) {
        & cmd.exe /c $cmd 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $rc = $LASTEXITCODE; break }
    }
    Set-Location $prev
    if ($rc -eq 0) { return 'pass' } else { return 'fail' }
}

# --- git-verb guardrail reference (M20 advisory): warn if a hook command carries git/release ---
# fleet-verify is verification-only, so a hook legitimately needing git commit/tag/push or release
# is rare (major-safe). Before running the hook, flag such tokens so the user notices cross-repo git
# leakage (advisory, not a hard block). The token match is a regex over FIXTURE strings only -- these
# tokens are never executed (they live in fixture files, not on the runner command line).
function HasGitVerb($cmd) {
    # allow args between `git` and the mutating verb so cross-repo forms `git -C <dir> push` /
    # `git --git-dir=... commit` are flagged too (M20-review #5), not just the bare `git <verb>` form.
    if ($cmd -match '(^|[^a-zA-Z])git[^a-zA-Z].*(commit|tag|push)([^a-zA-Z]|$)') { return 'yes' }
    if ($cmd -match '(^|\s)release([^a-zA-Z]|$)') { return 'yes' }
    return 'no'
}
# hook guardrail class: warn if any valid hook line has a git-verb, else ok (>=1 valid line), skip if none.
function HookGuardrail($parent) {
    if ((HookClass $parent) -eq 'skip') { return 'skip' }
    foreach ($cmd in (ReadHook $parent)) {
        if ((HasGitVerb $cmd) -eq 'yes') { return 'warn' }
    }
    return 'ok'
}

# --- verification-only reference: automated plan stage sequence has no release/git stage ---
# fleet-verify runs only the integration hook (verify/test). The automated plan NEVER includes a
# release/git stage (side-effect separation invariant; tide-guard blocks git at phase != release).
function PlanStages { return @('discover', 'hook', 'report') }
function PlanHas($stages, $needle) {
    # (M42-T03) ordinal -- the .sh twin's `[ "$s" = "$2" ]` is byte-exact; this is the assertion that
    # says the automated plan carries no release/git stage, so it must not be case-blind.
    foreach ($s in $stages) { if ([string]::Equals([string]$s, [string]$needle, [System.StringComparison]::Ordinal)) { return 'yes' } }
    return 'no'
}

function MkRepo($d) { GitInit $d; W (Join-Path $d 'docs\milestones\M1.md') '# M1' }

try {
    Write-Host "# tide fleet-verify live test (PowerShell)"
    Write-Host "# sandbox: $sbx`n"

    # --- (1) hook discovery/parse: strip BOM, skip comments/blanks -> commands only ---
    $HP = Join-Path $sbx 'parse'; New-Item -ItemType Directory -Force -Path (Join-Path $HP '.tide-fleet') | Out-Null
    # leading BOM + comment + blank + 2 command lines + trailing comment
    $bom = [char]0xFEFF
    $hookText = "$bom# integration hook`n`ndocker compose up -d`nnpm run integration-test`n# trailing comment"
    Set-Content -Path (Join-Path $HP '.tide-fleet\integration') -Value $hookText -Encoding utf8
    $parsed = ((ReadHook $HP) -join '|')
    Chk "hook parse: BOM/comment/blank stripped, 2 cmds" $parsed 'docker compose up -d|npm run integration-test'
    Chk "hook parse: class = declared" (HookClass $HP) 'declared'
    Chk "hook parse: first line BOM stripped" (@(ReadHook $HP)[0]) 'docker compose up -d'

    # --- (2) opt-in skip: no hook file / empty hook -> skip ---
    $NH = Join-Path $sbx 'nohook'; New-Item -ItemType Directory -Force -Path $NH | Out-Null
    Chk "opt-in skip: no hook file -> skip" (HookClass $NH) 'skip'
    $EH = Join-Path $sbx 'emptyhook'; New-Item -ItemType Directory -Force -Path (Join-Path $EH '.tide-fleet') | Out-Null
    Set-Content -Path (Join-Path $EH '.tide-fleet\integration') -Value "$bom# only comments`n`n   " -Encoding utf8
    Chk "opt-in skip: comments/blanks only (0 valid) -> skip" (HookClass $EH) 'skip'
    Chk "opt-in skip: skip class -> run also skip" (RunHook $EH) 'skip'

    # --- (3) pass/fail classification: mock hook exit code -> pass/fail (no git verbs) ---
    $OK = Join-Path $sbx 'passhook'; New-Item -ItemType Directory -Force -Path (Join-Path $OK '.tide-fleet') | Out-Null
    Set-Content -Path (Join-Path $OK '.tide-fleet\integration') -Value 'exit 0' -Encoding utf8
    Chk "pass/fail: hook exit 0 -> pass" (RunHook $OK) 'pass'
    $BAD = Join-Path $sbx 'failhook'; New-Item -ItemType Directory -Force -Path (Join-Path $BAD '.tide-fleet') | Out-Null
    Set-Content -Path (Join-Path $BAD '.tide-fleet\integration') -Value 'exit 1' -Encoding utf8
    Chk "pass/fail: hook exit 1 -> fail" (RunHook $BAD) 'fail'
    $MULTI = Join-Path $sbx 'multifail'; New-Item -ItemType Directory -Force -Path (Join-Path $MULTI '.tide-fleet') | Out-Null
    Set-Content -Path (Join-Path $MULTI '.tide-fleet\integration') -Value "exit 0`nexit 1" -Encoding utf8
    Chk "pass/fail: any non-zero among stages -> fail" (RunHook $MULTI) 'fail'

    # --- (4) verification-only: no release/git stage in automated plan ---
    $stages = PlanStages
    Chk "verification-only: auto stages = discover hook report" ($stages -join ' ') 'discover hook report'
    Chk "verification-only: no release stage in auto plan" (PlanHas $stages 'release') 'no'
    Chk "verification-only: no git stage in auto plan" (PlanHas $stages 'git') 'no'
    Chk "verification-only: auto stages end at report (not release)" $stages[$stages.Count - 1] 'report'

    # --- (4b) couple verification-only to the SKILL artifact: forbidden prose must be present ---
    # The plan-stage check above is a representation; this fails if the skill prose that actually
    # enforces the invariant (forbidden list / verification-only + phase=release backstop) regresses.
    # ASCII substrings only (keeps this source ASCII; the skill carries the Korean).
    $skillFile = Join-Path (Split-Path (Split-Path $PSScriptRoot)) 'skills\fleet-verify\SKILL.md'
    $skillText = if (Test-Path $skillFile) { Get-Content $skillFile -Raw } else { '' }
    # (M42-T03) ordinal substring, not `-like`: the .sh twin is `grep -qF` (byte-exact, case-sensitive)
    # while `-like` is culture-aware and case-insensitive -- as `-like` this would stay green on prose
    # the shell twin calls a regression. String.Contains(string) is ordinal by definition.
    Chk "verification-only(skill-coupled): forbidden-list prose present" $(if ($skillText.Contains('release / git commit / git tag / git push / cross-repo git')) { 'yes' } else { 'no' }) 'yes'
    Chk "verification-only(skill-coupled): verification-only prose present" $(if ($skillText.Contains('verification-only')) { 'yes' } else { 'no' }) 'yes'

    # --- (4c) integration-hook git-verb guardrail (M20 advisory): git/release -> warn, clean -> ok ---
    # The git tokens inside hook commands are FIXTURE strings, never executed (guardrail = pre-run check).
    $GV = Join-Path $sbx 'guardrail-git'; New-Item -ItemType Directory -Force -Path (Join-Path $GV '.tide-fleet') | Out-Null
    Set-Content -Path (Join-Path $GV '.tide-fleet\integration') -Value 'git push' -Encoding utf8   # git-leak hook (fixture)
    Chk "guardrail: hook with git push -> warn" (HookGuardrail $GV) 'warn'
    Chk "guardrail: HasGitVerb(git push)=yes" (HasGitVerb 'git push') 'yes'
    $GR = Join-Path $sbx 'guardrail-release'; New-Item -ItemType Directory -Force -Path (Join-Path $GR '.tide-fleet') | Out-Null
    Set-Content -Path (Join-Path $GR '.tide-fleet\integration') -Value 'npm run release' -Encoding utf8   # release token (fixture)
    Chk "guardrail: hook with release token -> warn" (HookGuardrail $GR) 'warn'
    $CL = Join-Path $sbx 'guardrail-clean'; New-Item -ItemType Directory -Force -Path (Join-Path $CL '.tide-fleet') | Out-Null
    Set-Content -Path (Join-Path $CL '.tide-fleet\integration') -Value "# verify only`nnpm test`ndocker compose up -d" -Encoding utf8   # clean hook
    Chk "guardrail: clean hook (npm test) -> ok" (HookGuardrail $CL) 'ok'
    Chk "guardrail: HasGitVerb(npm test)=no" (HasGitVerb 'npm test') 'no'
    # canonical cross-repo form (args between git and verb) must also be flagged (M20-review #5)
    $CR = Join-Path $sbx 'guardrail-crossrepo'; New-Item -ItemType Directory -Force -Path (Join-Path $CR '.tide-fleet') | Out-Null
    Set-Content -Path (Join-Path $CR '.tide-fleet\integration') -Value 'git -C ../svc-auth push' -Encoding utf8   # cross-repo git (fixture)
    Chk "guardrail: hook with git -C <dir> push -> warn" (HookGuardrail $CR) 'warn'
    Chk "guardrail: HasGitVerb(git -C dir push)=yes" (HasGitVerb 'git -C ../svc-auth push') 'yes'
    Chk "guardrail: HasGitVerb(git --git-dir=... commit)=yes" (HasGitVerb 'git --git-dir=svc/.git commit -m x') 'yes'
    # read-only git (git status) has no mutating verb -> not flagged (false-positive guard)
    Chk "guardrail: HasGitVerb(git status)=no (read-only)" (HasGitVerb 'git -C ../svc status') 'no'
    # any git-verb among multiple lines -> whole hook warns (leak noticed even when mixed with clean lines)
    $MX = Join-Path $sbx 'guardrail-mixed'; New-Item -ItemType Directory -Force -Path (Join-Path $MX '.tide-fleet') | Out-Null
    Set-Content -Path (Join-Path $MX '.tide-fleet\integration') -Value "npm test`ngit commit -m x" -Encoding utf8   # clean+git mix (fixture)
    Chk "guardrail: clean+git mix -> warn" (HookGuardrail $MX) 'warn'
    Chk "guardrail: undeclared hook -> skip" (HookGuardrail $NH) 'skip'

    # --- (5) .tide-fleet/ discovery-ignore: hidden dir is never a child repo ---
    $DS = Join-Path $sbx 'discover'; New-Item -ItemType Directory -Force -Path $DS | Out-Null
    MkRepo (Join-Path $DS 'auth')
    MkRepo (Join-Path $DS 'orders')
    New-Item -ItemType Directory -Force -Path (Join-Path $DS '.tide-fleet') | Out-Null
    Set-Content -Path (Join-Path $DS '.tide-fleet\integration') -Value 'exit 0' -Encoding utf8
    # even with fake tide artifacts inside .tide-fleet, hidden-skip must keep it out
    MkRepo (Join-Path $DS '.tide-fleet')
    $disc = ((Discover $DS) -join ' ')
    $discCount = @(Discover $DS).Count
    # (M42-T03) ordinal substring -- `-like` is culture-aware and case-insensitive, so this negative
    # control would also fire on a '.TIDE-FLEET' directory that the .sh twin's `case`/`grep` would not
    # see. Making the control ordinal keeps the two copies asserting the same thing.
    $hasFleet = if ((@(Discover $DS) | Where-Object { ([string]$_).Contains('tide-fleet') }).Count -gt 0) { 'yes' } else { 'no' }
    Chk "discovery-ignore: children only = auth orders" $disc 'auth orders'
    Chk "discovery-ignore: .tide-fleet not included" $hasFleet 'no'
    Chk "discovery-ignore: 2 nodes (hidden excluded)" "$discCount" '2'

    # === case-count self-consistency (M38-T01) ==========================
    # The completion guard (M37) catches a runner that ABORTS; it does not catch one that stays
    # alive and RUNS LESS (a branch skipping a part, a discovery scan finding zero). The expected
    # case count has a single declaration site -- this harness's README (convention: the
    # document self-description section of docs/conventions.md) -- never hardcoded here.
    # If the declaration cannot be read (file missing / no `cases` token) the extraction is empty
    # and this FAILS: "could not read it, so skip the check and pass" is the very class this kills.
    # This case is itself a case, so it goes LAST and compares against running-total + 1 (same
    # shape as `tests/discover` F1; identical assertion name and verdict in both shells).
    function DeclaredCases($path) {
        if (-not (Test-Path $path)) { return '' }
        $raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        $m = [regex]::Match($raw, 'cases:[^0-9\r\n]*([0-9]+)')
        if ($m.Success) { return $m.Groups[1].Value } else { return '' }
    }
    Chk "case-count: README cases declaration == actual" (DeclaredCases (Join-Path $ROOT 'tests\fleet-verify\README.md')) ([string]($script:pass + $script:fail + 1))

    Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail) [runtime: PowerShell $($PSVersionTable.PSVersion) $($PSVersionTable.PSEdition)]"
    $script:completed = $true
}
finally {
    Set-Location $sbx -ErrorAction SilentlyContinue
    Set-Location ([System.IO.Path]::GetTempPath()) -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $sbx -ErrorAction SilentlyContinue
}

if (-not $script:completed) {
    Write-Host "# INCOMPLETE RUN -- the harness did not reach its result line; treat as FAIL"
    exit 1
}
if ($script:fail -ne 0) { exit 1 }
Write-Host "# fleet-verify hook-discovery/parse / opt-in-skip / pass-fail / verification-only / git-verb-guardrail / .tide-fleet-ignore confirmed"
exit 0
