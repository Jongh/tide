# tide fleet live test (Windows PowerShell 5.1) -- discovery / classification / graceful degrade
#
# fleet is a prompt skill with no executable. This exercises a REFERENCE of its deterministic
# core (discovery rule + /tide:status classification) against fixtures; the single source is
# docs/conventions.md "multi-repo orchestration". Advisory narrative quality -> README manual.
#
# ASCII-only source (BOM-independent, per the project's PS 5.1 encoding rule). The Korean
# release verdict tokens are built from code points so this file stays ASCII. git mutating
# verbs live only in this script's setup (init only -- commits not needed for discovery).
#
# Usage: & tests\fleet\run.ps1   (exit 0 if all pass, exit 1 if any fail)

$ErrorActionPreference = 'SilentlyContinue'   # native git stderr must not terminate

# Korean verdict tokens via code points (keeps this source ASCII):
$OK  = [string]([char]0xAC00 + [char]0xB2A5)   # "가능" (release-able)
$BAD = [string]([char]0xBD88 + [char]0xAC00)   # "불가" (blocked)

$sbx = Join-Path ([System.IO.Path]::GetTempPath()) "tide-fleet-live.$PID"
if (Test-Path $sbx) { Remove-Item -Recurse -Force $sbx }
New-Item -ItemType Directory -Force -Path $sbx | Out-Null

$script:pass = 0; $script:fail = 0
function Chk($desc, $got, $want) {
    if ($got -eq $want) { $script:pass++; Write-Host ("PASS  {0,-50} ({1})" -f $desc, $got) }
    else { $script:fail++; Write-Host ("FAIL  {0,-50} (got {1}, want {2})" -f $desc, $got, $want) }
}

# --- discovery reference: immediate children, git repo AND tide artifacts ---
function IsTideRepo($d) {
    $isGit = Test-Path (Join-Path $d '.git')
    if (-not $isGit) { & git -C $d rev-parse --show-toplevel 2>$null | Out-Null; $isGit = ($LASTEXITCODE -eq 0) }
    if (-not $isGit) { return $false }
    foreach ($m in @('docs\milestones', '.tide', 'package.json', 'Cargo.toml', 'pyproject.toml', '.claude-plugin\plugin.json')) {
        if (Test-Path (Join-Path $d $m)) { return $true }
    }
    return $false
}
function Discover($parent) {
    Get-ChildItem -Directory $parent -ErrorAction SilentlyContinue |
        Where-Object { IsTideRepo $_.FullName } | ForEach-Object { $_.Name } | Sort-Object
}

# --- classification reference: /tide:status next-command judgment (ASCII labels) ---
function Classify($r) {
    $ms = Get-ChildItem (Join-Path $r 'docs\milestones') -Filter 'M*.md' -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -Last 1
    if (-not $ms) { return 'milestone-needed' }
    $n = $ms.BaseName
    $rep = Join-Path $r 'docs\reports'
    if (-not (Test-Path (Join-Path $rep ($n + '-impl.md')))) { return 'impl-inprogress' }
    $rev = Join-Path $rep ($n + '-review.md')
    if (-not (Test-Path $rev)) { return 'review-pending' }
    $c = Get-Content $rev -Raw
    if ($c.Contains($BAD)) { return 'needs-fix' }
    if ($c.Contains($OK))  { return 'release-ready' }
    return 'unknown'
}

try {
    Write-Host "# tide fleet live test (PowerShell)"
    Write-Host "# sandbox: $sbx`n"

    $P = Join-Path $sbx 'parent'; New-Item -ItemType Directory -Force -Path $P | Out-Null

    # repo-a: release-ready (milestone + impl + review verdict OK + version file)
    $A = Join-Path $P 'repo-a'
    New-Item -ItemType Directory -Force -Path (Join-Path $A 'docs\milestones'), (Join-Path $A 'docs\reports') | Out-Null
    & git -C $A init -q
    Set-Content (Join-Path $A 'docs\milestones\M1.md') '# M1' -Encoding utf8
    Set-Content (Join-Path $A 'package.json') '{ "version": "0.1.0" }' -Encoding utf8
    Set-Content (Join-Path $A 'docs\reports\M1-impl.md') '# M1 impl' -Encoding utf8
    Set-Content (Join-Path $A 'docs\reports\M1-review.md') ("verdict: " + $OK + " v0.2.0") -Encoding utf8

    # repo-b: review-pending (impl present, review absent)
    $B = Join-Path $P 'repo-b'
    New-Item -ItemType Directory -Force -Path (Join-Path $B 'docs\milestones'), (Join-Path $B 'docs\reports') | Out-Null
    & git -C $B init -q
    Set-Content (Join-Path $B 'docs\milestones\M1.md') '# M1' -Encoding utf8
    Set-Content (Join-Path $B 'docs\reports\M1-impl.md') '# M1 impl' -Encoding utf8

    # repo-c: impl-inprogress (milestone only)
    $C = Join-Path $P 'repo-c'
    New-Item -ItemType Directory -Force -Path (Join-Path $C 'docs\milestones') | Out-Null
    & git -C $C init -q
    Set-Content (Join-Path $C 'docs\milestones\M1.md') '# M1' -Encoding utf8

    # plain: non-git folder -> excluded
    New-Item -ItemType Directory -Force -Path (Join-Path $P 'plain') | Out-Null
    Set-Content (Join-Path $P 'plain\readme.txt') 'x' -Encoding utf8

    # notide: git repo but no tide artifacts -> excluded
    $ND = Join-Path $P 'notide'; New-Item -ItemType Directory -Force -Path $ND | Out-Null
    & git -C $ND init -q
    Set-Content (Join-Path $ND 'file.txt') 'x' -Encoding utf8

    # --- scenarios ---
    $got = (Discover $P) -join ','
    Chk "discover: tide repos only (plain/notide excluded)" $got 'repo-a,repo-b,repo-c'
    Chk "classify repo-a = release-ready" (Classify $A) 'release-ready'
    Chk "classify repo-b = review-pending" (Classify $B) 'review-pending'
    Chk "classify repo-c = impl-inprogress" (Classify $C) 'impl-inprogress'

    # graceful degrade: parent with zero tide repos -> empty discovery
    $EMPTY = Join-Path $sbx 'empty'; New-Item -ItemType Directory -Force -Path (Join-Path $EMPTY 'just-a-folder') | Out-Null
    $e = (Discover $EMPTY) -join ','
    Chk "discover 0 -> graceful degrade (empty)" $(if ($e) { $e } else { 'EMPTY' }) 'EMPTY'

    Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail)"
}
finally {
    Remove-Item -Recurse -Force $sbx -ErrorAction SilentlyContinue
}

if ($script:fail -ne 0) { exit 1 }
Write-Host "# fleet discovery/classification/degrade confirmed (reference impl)"
exit 0
