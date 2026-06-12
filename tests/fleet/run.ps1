# tide fleet live test (Windows PowerShell 5.1) -- discovery / 5-position classify / summary / degrade
#
# fleet is a prompt skill with no executable. This exercises a REFERENCE of its deterministic
# core (discovery rule + /tide:status classification + canonical 5-position taxonomy summary)
# against fixtures; the single source is docs/conventions.md "multi-repo orchestration".
# Advisory narrative quality -> README manual.
#
# ASCII-only source (BOM-independent). Korean release verdict tokens are built from code points.
# git mutating verbs live only in this script's setup (init only -- no commits needed).
#
# Usage: & tests\fleet\run.ps1   (exit 0 if all pass, exit 1 if any fail)

$ErrorActionPreference = 'SilentlyContinue'

$OK  = [string]([char]0xAC00 + [char]0xB2A5)   # "가능" (release-able)
$BAD = [string]([char]0xBD88 + [char]0xAC00)   # "불가" (blocked)

$sbx = Join-Path ([System.IO.Path]::GetTempPath()) "tide-fleet-live.$PID"
if (Test-Path $sbx) { Remove-Item -Recurse -Force $sbx }
New-Item -ItemType Directory -Force -Path $sbx | Out-Null

$script:pass = 0; $script:fail = 0
function Chk($desc, $got, $want) {
    if ($got -eq $want) { $script:pass++; Write-Host ("PASS  {0,-52} ({1})" -f $desc, $got) }
    else { $script:fail++; Write-Host ("FAIL  {0,-52} (got {1}, want {2})" -f $desc, $got, $want) }
}
function W($path, $text) { $d = Split-Path $path -Parent; if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }; Set-Content -Path $path -Value $text -Encoding utf8 }
function GitInit($d) { New-Item -ItemType Directory -Force -Path $d | Out-Null; & git -C $d init -q }   # dir must exist before init

# --- discovery reference: immediate children, skip hidden (dot) dirs, git repo AND tide artifacts ---
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
        Where-Object { $_.Name -notlike '.*' -and (IsTideRepo $_.FullName) } | ForEach-Object { $_.Name } | Sort-Object
}

# --- classification reference: /tide:status next-command judgment (5 positions, ASCII labels) ---
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
# --- cross-summary reference: 1:1 position counts (canonical 5 buckets, no lumping) ---
function Summarize($parent) {
    $rel=0;$rev=0;$imp=0;$mil=0;$fix=0
    foreach ($name in (Discover $parent)) {
        switch (Classify (Join-Path $parent $name)) {
            'release-ready'    { $rel++ }
            'review-pending'   { $rev++ }
            'impl-inprogress'  { $imp++ }
            'milestone-needed' { $mil++ }
            'needs-fix'        { $fix++ }
        }
    }
    "release=$rel review=$rev impl=$imp milestone=$mil fix=$fix"
}

try {
    Write-Host "# tide fleet live test (PowerShell)"
    Write-Host "# sandbox: $sbx`n"

    $P = Join-Path $sbx 'parent'; New-Item -ItemType Directory -Force -Path $P | Out-Null

    $A = Join-Path $P 'repo-a'; GitInit $A            # release-ready
    W (Join-Path $A 'docs\milestones\M1.md') '# M1'
    W (Join-Path $A 'package.json') '{ "version": "0.1.0" }'
    W (Join-Path $A 'docs\reports\M1-impl.md') '# M1 impl'
    W (Join-Path $A 'docs\reports\M1-review.md') ("## release verdict`n`n**" + $OK + "** -- rec: **v0.2.0 (minor)**`n")

    $B = Join-Path $P 'repo-b'; GitInit $B            # review-pending
    W (Join-Path $B 'docs\milestones\M1.md') '# M1'
    W (Join-Path $B 'docs\reports\M1-impl.md') '# M1 impl'

    $C = Join-Path $P 'repo-c'; GitInit $C            # impl-inprogress
    W (Join-Path $C 'docs\milestones\M1.md') '# M1'

    $D = Join-Path $P 'repo-d'; GitInit $D            # needs-fix (blocked verdict)
    W (Join-Path $D 'docs\milestones\M1.md') '# M1'
    W (Join-Path $D 'docs\reports\M1-impl.md') '# M1 impl'
    W (Join-Path $D 'docs\reports\M1-review.md') ("## release verdict`n`n**" + $BAD + "** (test failed) -- needs fix`n")

    $E = Join-Path $P 'repo-e'; GitInit $E            # milestone-needed
    W (Join-Path $E 'package.json') '{ "version": "0.1.0" }'
    W (Join-Path $E '.tide\phase') 'idle'

    W (Join-Path $P 'plain\readme.txt') 'x'           # non-git -> excluded
    $ND = Join-Path $P 'notide'; GitInit $ND; W (Join-Path $ND 'file.txt') 'x'   # no tide artifacts -> excluded
    $H = Join-Path $P '.hidden-svc'; GitInit $H; W (Join-Path $H 'docs\milestones\M1.md') '# M1'  # hidden -> excluded

    # --- scenarios ---
    Chk "discover: tide repos only (plain/notide/.hidden excluded)" ((Discover $P) -join ',') 'repo-a,repo-b,repo-c,repo-d,repo-e'
    Chk "classify repo-a = release-ready"    (Classify $A) 'release-ready'
    Chk "classify repo-b = review-pending"   (Classify $B) 'review-pending'
    Chk "classify repo-c = impl-inprogress"  (Classify $C) 'impl-inprogress'
    Chk "classify repo-d = needs-fix (blocked)" (Classify $D) 'needs-fix'
    Chk "classify repo-e = milestone-needed" (Classify $E) 'milestone-needed'
    Chk "hidden dir (.hidden-svc) not discovered" ([bool]((Discover $P) -match 'hidden')).ToString() 'False'
    Chk "cross-summary 5 buckets 1:1" (Summarize $P) 'release=1 review=1 impl=1 milestone=1 fix=1'

    $EMPTY = Join-Path $sbx 'empty'; New-Item -ItemType Directory -Force -Path (Join-Path $EMPTY 'just-a-folder') | Out-Null
    $e = (Discover $EMPTY) -join ','
    Chk "discover 0 -> graceful degrade (empty)" $(if ($e) { $e } else { 'EMPTY' }) 'EMPTY'

    Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail)"
}
finally {
    Remove-Item -Recurse -Force $sbx -ErrorAction SilentlyContinue
}

if ($script:fail -ne 0) { exit 1 }
Write-Host "# fleet discovery / 5-position classify / 1:1 summary / hidden-skip / degrade confirmed"
exit 0
