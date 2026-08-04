# tide fleet-cycle live test (Windows PowerShell 5.1) -- cross-cycle automation deterministic core
#
# fleet-cycle is a prompt skill; the actual cycle run (milestone->impl->review) is LLM behavior.
# This exercises a REFERENCE of its deterministic core (processing order = topo sort / release
# EXCLUSION invariant / contract upstream-behind -> contract-blocked / downstream skip on failure)
# against fixtures. The single source is docs/conventions.md "multi-repo orchestration"; the
# actual cross-cycle run quality is split into README's session-level manual procedure.
#
# ASCII-only source (BOM-independent). git mutating verbs live only in setup (init only -- no
# commits). release/git are NOT automation targets -- this runner actively asserts release is
# absent from the automated plan.
#
# Usage: & tests\fleet-cycle\run.ps1   (exit 0 if all pass, exit 1 if any fail)

$ErrorActionPreference = 'SilentlyContinue'

$ROOT = Split-Path (Split-Path $PSScriptRoot)
# source order: encoding -> discover -> deps -> toposort
# (ReadDeps calls StripBom and TopoSort calls ReadDeps, so encoding/deps must come first).
. (Join-Path $ROOT 'tests\lib\encoding.ps1')   # StripBom (single source)
. (Join-Path $ROOT 'tests\lib\discover.ps1')   # IsTideRepo + Discover (single source)
. (Join-Path $ROOT 'tests\lib\deps.ps1')       # ReadDeps + DepName (single source; StripBom from encoding.ps1)
. (Join-Path $ROOT 'tests\lib\toposort.ps1')   # TopoSort (single source; ReadDeps from tests\lib\deps.ps1)

$sbx = Join-Path ([System.IO.Path]::GetTempPath()) "tide-fleet-cycle-live.$PID"
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
function Chk($desc, $got, $want) {
    if ($got -eq $want) { $script:pass++; Write-Host ("PASS  {0,-56} ({1})" -f $desc, $got) }
    else { $script:fail++; Write-Host ("FAIL  {0,-56} (got {1}, want {2})" -f $desc, $got, $want) }
}
function W($path, $text) { $d = Split-Path $path -Parent; if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }; Set-Content -Path $path -Value $text -Encoding utf8 }
function GitInit($d) { New-Item -ItemType Directory -Force -Path $d | Out-Null; & git -C $d init -q }   # dir must exist before init

# IsTideRepo + Discover moved to tests\lib\discover.ps1 (single source); dot-sourced at top.

# ReadDeps/DepLines/DepName: tests\lib\deps.ps1, StripBom: tests\lib\encoding.ps1 (single source;
# dot-sourced above). Contract-comparison-only functions below (DepRequiredVersion / SemverGe /
# CheckContract) are out of extraction scope and stay local; DepRequiredVersion reuses DepLines/DepName.
function DepRequiredVersion($repoDir, $depName) {
    $f = Join-Path $repoDir '.tide\deps'
    if (-not (Test-Path $f)) { return '' }
    foreach ($line in (DepLines $f)) {
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        if ((DepName $t) -ne $depName) { continue }
        $m = [regex]::Match($t, '>=\s*(\S+)')
        if ($m.Success) { return $m.Groups[1].Value }
        return ''
    }
    return ''
}
function ReadVersion($repoDir) {
    $f = Join-Path $repoDir 'package.json'
    if (-not (Test-Path $f)) { return '' }
    $m = [regex]::Match((Get-Content $f -Raw), '"version"\s*:\s*"([^"]*)"')
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
}
function SemverGe($current, $required) {
    $cur = $current -replace '^v', ''; $req = $required -replace '^v', ''
    $rx = '^\d+\.\d+\.\d+$'
    if ($cur -notmatch $rx -or $req -notmatch $rx) { return 'skip' }
    $c = $cur.Split('.'); $r = $req.Split('.')
    for ($i = 0; $i -lt 3; $i++) {
        $ci = [int]$c[$i]; $ri = [int]$r[$i]
        if ($ci -ne $ri) { if ($ci -gt $ri) { return 'satisfied' } else { return 'violation' } }
    }
    return 'satisfied'
}
function CheckContract($parent, $repo, $dep) {
    $req = DepRequiredVersion (Join-Path $parent $repo) $dep
    if ($req -eq '') { return 'none' }
    $cur = ReadVersion (Join-Path $parent $dep)
    if ($cur -eq '') { return 'skip' }
    return (SemverGe $cur $req)
}

# TopoSort moved to tests\lib\toposort.ps1 (single source; ReadDeps from tests\lib\deps.ps1); dot-sourced at top.
function IdxOf($orderStr, $name) {
    $arr = @($orderStr -split '\s+' | Where-Object { $_ -ne '' })
    for ($i = 0; $i -lt $arr.Count; $i++) { if ($arr[$i] -eq $name) { return $i } }
    return -1
}

# === fleet-cycle specific deterministic core ============================

# --- (1) automated plan stage sequence reference: release-exclusion invariant ---
# fleet-cycle auto-chains only milestone->impl->review per repo. release is NEVER in the auto
# plan (side-effect separation invariant; tide-guard blocks git at phase != release).
function PlanStages { return @('milestone', 'impl', 'review') }
function PlanHasRelease($stages) {
    foreach ($s in $stages) { if ($s -eq 'release') { return 'yes' } }
    return 'no'
}

# --- (2) release handoff classification reference: a separate handoff list, not automation ---
# review "able" + no contract violation -> release-ready; contract violation (upstream-behind)
# -> contract-blocked (held). Automation only produces this list; it does not run release.
function HandoffClass($parent, $repo, $dep) {
    switch (CheckContract $parent $repo $dep) {
        'violation' { return 'contract-blocked' }
        default     { return 'release-ready' }
    }
}

# --- (3) downstream skip on failure reference: transitive dependents (reverse reachability) ---
function DependentsOf($parent, $failed) {
    $nodes = @(Discover $parent)
    $reached = New-Object System.Collections.ArrayList
    [void]$reached.Add($failed)
    $frontier = @($failed)
    while ($frontier.Count -gt 0) {
        $nextArr = New-Object System.Collections.ArrayList
        foreach ($r in $nodes) {
            if ($reached -contains $r) { continue }
            foreach ($dep in (ReadDeps (Join-Path $parent $r))) {
                if ($frontier -contains $dep) { [void]$reached.Add($r); [void]$nextArr.Add($r); break }
            }
        }
        $frontier = @($nextArr.ToArray())
    }
    $res = @($reached | Where-Object { $_ -ne $failed } | Sort-Object)
    return ($res -join ' ')
}
function ClassifyOnFailure($parent, $failed, $repo) {
    if ($repo -eq $failed) { return 'failed' }
    $deps = @((DependentsOf $parent $failed) -split '\s+' | Where-Object { $_ -ne '' })
    if ($deps -contains $repo) { return 'skip' }
    return 'ok'
}

function MkRepo($d) { GitInit $d; W (Join-Path $d 'docs\milestones\M1.md') '# M1' }

try {
    Write-Host "# tide fleet-cycle live test (PowerShell)"
    Write-Host "# sandbox: $sbx`n"

    # --- (1) processing order = topo sort (depended-upon first) ---
    # auth(no deps) <- orders(->auth) <- gateway(->auth) <- notify(->orders)
    $TP = Join-Path $sbx 'topo'; New-Item -ItemType Directory -Force -Path $TP | Out-Null
    MkRepo (Join-Path $TP 'auth')
    MkRepo (Join-Path $TP 'orders');  W (Join-Path $TP 'orders\.tide\deps')  'auth'
    MkRepo (Join-Path $TP 'gateway'); W (Join-Path $TP 'gateway\.tide\deps') 'auth'
    MkRepo (Join-Path $TP 'notify');  W (Join-Path $TP 'notify\.tide\deps')  'orders'

    $tord = TopoSort $TP
    $ia = IdxOf $tord 'auth'; $io = IdxOf $tord 'orders'; $ig = IdxOf $tord 'gateway'; $inf = IdxOf $tord 'notify'
    $nodeCount = @($tord -split '\s+' | Where-Object { $_ -ne '' }).Count
    Chk "order: not a cycle (not CYCLE)" $(if ($tord -eq 'CYCLE') { 'yes' } else { 'no' }) 'no'
    Chk "order: auth before orders (depended-upon first)" $(if ($ia -ge 0 -and $io -ge 0 -and $ia -lt $io) { 'yes' } else { 'no' }) 'yes'
    Chk "order: auth before gateway" $(if ($ia -ge 0 -and $ig -ge 0 -and $ia -lt $ig) { 'yes' } else { 'no' }) 'yes'
    Chk "order: orders before notify (transitive)" $(if ($io -ge 0 -and $inf -ge 0 -and $io -lt $inf) { 'yes' } else { 'no' }) 'yes'
    Chk "order: auth before notify (transitive)" $(if ($ia -ge 0 -and $inf -ge 0 -and $ia -lt $inf) { 'yes' } else { 'no' }) 'yes'
    Chk "order: all 4 discovered nodes present" "$nodeCount" '4'

    # --- (2) release exclusion (invariant): no release stage in the automated plan ---
    $stages = PlanStages
    Chk "release-excl: auto stages = milestone impl review" ($stages -join ' ') 'milestone impl review'
    Chk "release-excl: no release stage in auto plan" (PlanHasRelease $stages) 'no'
    Chk "release-excl: auto stages start at milestone" $stages[0] 'milestone'
    Chk "release-excl: auto stages end at review (not release)" $stages[$stages.Count - 1] 'review'

    # --- (2b) couple release-exclusion to the SKILL artifact: forbidden prose must be present ---
    # The plan-stage check above is a representation; this fails if the skill prose that actually
    # enforces the invariant (forbidden list / phase=release backstop+pre-scan) regresses.
    # ASCII substrings only (keeps this source ASCII; the skill carries the Korean).
    $skillFile = Join-Path (Split-Path (Split-Path $PSScriptRoot)) 'skills\fleet-cycle\SKILL.md'
    $skillText = Get-Content $skillFile -Raw
    Chk "release-excl(skill-coupled): forbidden-list prose present" $(if ($skillText -like '*release / git commit / git tag / git push / cross-repo git*') { 'yes' } else { 'no' }) 'yes'
    Chk "release-excl(skill-coupled): phase=release backstop/pre-scan prose present" $(if ($skillText -like '*phase=release*') { 'yes' } else { 'no' }) 'yes'

    # --- (3) contract-blocked: upstream-behind dep -> held in handoff ---
    # auth(0.2.0) <- orders(auth >= v0.3.0 -> upstream behind) / gateway(auth >= v0.2.0 -> satisfied)
    $CT = Join-Path $sbx 'contract'; New-Item -ItemType Directory -Force -Path $CT | Out-Null
    MkRepo (Join-Path $CT 'auth'); W (Join-Path $CT 'auth\package.json') '{ "version": "0.2.0" }'
    MkRepo (Join-Path $CT 'orders');  W (Join-Path $CT 'orders\.tide\deps')  'auth >= v0.3.0'
    MkRepo (Join-Path $CT 'gateway'); W (Join-Path $CT 'gateway\.tide\deps') 'auth >= v0.2.0'
    Chk "contract-blocked: orders(auth>=0.3.0, cur 0.2.0) -> held" (HandoffClass $CT 'orders' 'auth') 'contract-blocked'
    Chk "release-ready: gateway(auth>=0.2.0, cur 0.2.0) -> able"   (HandoffClass $CT 'gateway' 'auth') 'release-ready'

    # --- (4) downstream skip on failure: auth failed -> all dependents skip, independent ok ---
    # auth <- orders(->auth) <- gateway(->auth) <- notify(->orders) , solo(independent)
    $FL = Join-Path $sbx 'fail'; New-Item -ItemType Directory -Force -Path $FL | Out-Null
    MkRepo (Join-Path $FL 'auth')
    MkRepo (Join-Path $FL 'orders');  W (Join-Path $FL 'orders\.tide\deps')  'auth'
    MkRepo (Join-Path $FL 'gateway'); W (Join-Path $FL 'gateway\.tide\deps') 'auth'
    MkRepo (Join-Path $FL 'notify');  W (Join-Path $FL 'notify\.tide\deps')  'orders'
    MkRepo (Join-Path $FL 'solo')

    Chk "downstream: auth dependents (transitive) = gateway notify orders" (DependentsOf $FL 'auth') 'gateway notify orders'
    Chk "downstream: auth failed -> orders=skip"  (ClassifyOnFailure $FL 'auth' 'orders')  'skip'
    Chk "downstream: auth failed -> gateway=skip" (ClassifyOnFailure $FL 'auth' 'gateway') 'skip'
    Chk "downstream: auth failed -> notify=skip (transitive)" (ClassifyOnFailure $FL 'auth' 'notify') 'skip'
    Chk "downstream: auth failed -> solo=ok (independent kept)" (ClassifyOnFailure $FL 'auth' 'solo') 'ok'
    Chk "downstream: auth itself=failed" (ClassifyOnFailure $FL 'auth' 'auth') 'failed'
    Chk "downstream: orders failed -> notify=skip" (ClassifyOnFailure $FL 'orders' 'notify') 'skip'
    Chk "downstream: orders failed -> gateway=ok (unrelated)" (ClassifyOnFailure $FL 'orders' 'gateway') 'ok'
    Chk "downstream: orders failed -> solo=ok" (ClassifyOnFailure $FL 'orders' 'solo') 'ok'

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
    Chk "case-count: README cases declaration == actual" (DeclaredCases (Join-Path $ROOT 'tests\fleet-cycle\README.md')) ([string]($script:pass + $script:fail + 1))

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
Write-Host "# fleet-cycle processing-order / release-exclusion / contract-blocked / downstream-skip confirmed"
exit 0
