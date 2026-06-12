# tide discover live test (Windows PowerShell 5.1) -- multi-repo context detection hint + command-count drift guard
#
# The status/kickoff multi-repo detection hint (M21) is a prompt-skill behavior with no executable.
# This exercises a REFERENCE of its deterministic core (fleet discovery rule reused + detection
# threshold >=2 -> hint|none) against fixtures; the single source is docs/conventions.md "multi-repo
# orchestration" (discovery) + the discoverability-hint clause. Advisory narrative -> README manual.
#
# It also closes M20-review #6 (site command-count drift, 8 <-> 11) with a guard that FAILS when the
# actual count of skills/*/SKILL.md diverges from the "N <jong>" declared by canonical docs/site pages.
#
# ASCII-only source (BOM-independent). The Korean counter token <jong> (U+C885) is built from a code
# point so the source carries no byte > 127. git mutating verbs live only in setup (init only).
#
# Usage: & tests\discover\run.ps1   (exit 0 if all pass, exit 1 if any fail)

$ErrorActionPreference = 'SilentlyContinue'

# Korean counter suffix "<jong>" (U+C885) -- e.g. the "11<jong>" command-count declaration.
$JONG = [string][char]0xC885

# Resolve repo root from the script location (like tests/fleet).
$ROOT = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$sbx = Join-Path ([System.IO.Path]::GetTempPath()) "tide-discover-live.$PID"
if (Test-Path $sbx) { Remove-Item -Recurse -Force $sbx }
New-Item -ItemType Directory -Force -Path $sbx | Out-Null

$script:pass = 0; $script:fail = 0
function Chk($desc, $got, $want) {
    if ($got -eq $want) { $script:pass++; Write-Host ("PASS  {0,-56} ({1})" -f $desc, $got) }
    else { $script:fail++; Write-Host ("FAIL  {0,-56} (got {1}, want {2})" -f $desc, $got, $want) }
}
function W($path, $text) { $d = Split-Path $path -Parent; if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }; Set-Content -Path $path -Value $text -Encoding utf8 }
function GitInit($d) { New-Item -ItemType Directory -Force -Path $d | Out-Null; & git -C $d init -q }   # dir must exist before init

# === Part A -- detection threshold =====================================

# --- discovery reference (fleet reused): immediate children, skip hidden (dot) dirs, git repo AND tide artifacts ---
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

# --- detection hint reference: count child tide repos; >=2 -> "hint N=<count>", else "none" ---
function DetectHint($parent) {
    $n = @(Discover $parent).Count
    if ($n -ge 2) { return "hint N=$n" } else { return 'none' }
}

function MkTideRepo($d) { GitInit $d; W (Join-Path $d 'docs\milestones\M1.md') '# M1' }

try {
    Write-Host "# tide discover live test (PowerShell)"
    Write-Host "# sandbox: $sbx`n"

    # (A1) parent with 2 child tide repos -> hint N=2
    $P2 = Join-Path $sbx 'parent2'; New-Item -ItemType Directory -Force -Path $P2 | Out-Null
    MkTideRepo (Join-Path $P2 'svc-auth')
    MkTideRepo (Join-Path $P2 'svc-orders')

    # (A2) parent with 1 child tide repo -> none
    $P1 = Join-Path $sbx 'parent1'; New-Item -ItemType Directory -Force -Path $P1 | Out-Null
    MkTideRepo (Join-Path $P1 'only-svc')

    # (A3) parent with 0 child tide repos -> none (non-tide folder only)
    $P0 = Join-Path $sbx 'parent0'; New-Item -ItemType Directory -Force -Path (Join-Path $P0 'just-a-folder') | Out-Null
    W (Join-Path $P0 'just-a-folder\readme.txt') 'x'

    # (A4) single repo root whose children are src/ etc (non-tide) -> none (normal single-repo session)
    $SR = Join-Path $sbx 'single-repo'; GitInit $SR
    W (Join-Path $SR 'docs\milestones\M1.md') '# M1'
    W (Join-Path $SR 'src\index.ts') 'export const x = 1;'
    # the single repo IS a tide repo, but its immediate children (src/docs) are not git+tide repos.

    # (A5) parent with 2 child tide repos + a hidden tide child (.hidden-svc) -> hint N=2 (hidden NOT counted)
    $PH = Join-Path $sbx 'parenthidden'; New-Item -ItemType Directory -Force -Path $PH | Out-Null
    MkTideRepo (Join-Path $PH 'svc-a')
    MkTideRepo (Join-Path $PH 'svc-b')
    MkTideRepo (Join-Path $PH '.hidden-svc')    # hidden (dot) -> excluded from discovery

    Chk "A: 2 child tide repos -> hint N=2"            (DetectHint $P2) 'hint N=2'
    Chk "A: 1 child tide repo -> none"                (DetectHint $P1) 'none'
    Chk "A: 0 child tide repos -> none"               (DetectHint $P0) 'none'
    Chk "A: single repo root (children src etc, non-tide) -> none" (DetectHint $SR) 'none'
    Chk "A: 2 children + hidden tide child -> hint N=2 (hidden not counted)" (DetectHint $PH) 'hint N=2'
    Chk "A: hidden child (.hidden-svc) not discovered" ([bool]((Discover $PH) -match 'hidden')).ToString() 'False'
    Chk "A: discover = svc-a,svc-b (hidden excluded)" ((Discover $PH) -join ',') 'svc-a,svc-b'

    # === Part B -- command-count drift guard =============================

    # actual command skill count = number of skills/*/SKILL.md files
    $N = @(Get-ChildItem (Join-Path $ROOT 'skills') -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }).Count
    Chk "B: actual command skill count measured (>0)" $(if ($N -gt 0) { 'ok' } else { 'no' }) 'ok'

    # canonical declaration sites must declare "N<jong>" (e.g. 11<jong>); divergence -> FAIL.
    function DeclaredHasCount($file, $count) {
        if (-not (Test-Path $file)) { return 'no' }
        # PS 5.1 Get-Content mis-decodes UTF-8-without-BOM; read with explicit UTF-8 so the Korean
        # counter token (U+C885) matches the canonical "N<jong>" declaration byte-correctly.
        $raw = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
        if ($raw.Contains("$count$JONG")) { return 'yes' } else { return 'no' }
    }
    $README   = Join-Path $ROOT 'README.md'
    $CONV     = Join-Path $ROOT 'docs\conventions.md'
    $SITE_CMD = Join-Path $ROOT 'site\docs\commands.md'
    $SITE_GS  = Join-Path $ROOT 'site\docs\getting-started.md'

    Chk "B: README.md declares N$JONG"                 (DeclaredHasCount $README $N)   'yes'
    Chk "B: docs/conventions.md declares N$JONG"       (DeclaredHasCount $CONV $N)     'yes'
    Chk "B: site/docs/commands.md declares N$JONG"     (DeclaredHasCount $SITE_CMD $N) 'yes'
    Chk "B: site/docs/getting-started.md declares N$JONG" (DeclaredHasCount $SITE_GS $N) 'yes'

    # negative control: a different count (N+1) must NOT appear in any canonical file (drift would be caught).
    $WRONG = $N + 1
    Chk "B: drift control -- README has no $WRONG$JONG"            (DeclaredHasCount $README $WRONG)   'no'
    Chk "B: drift control -- conventions has no $WRONG$JONG"       (DeclaredHasCount $CONV $WRONG)     'no'
    Chk "B: drift control -- site/commands has no $WRONG$JONG"     (DeclaredHasCount $SITE_CMD $WRONG) 'no'
    Chk "B: drift control -- site/getting-started has no $WRONG$JONG" (DeclaredHasCount $SITE_GS $WRONG) 'no'

    Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail) (actual command skills N=$N)"
}
finally {
    Remove-Item -Recurse -Force $sbx -ErrorAction SilentlyContinue
}

if ($script:fail -ne 0) { exit 1 }
Write-Host "# discover detection threshold (>=2->hint / <2->none / single-repo->none / hidden-not-counted) + command-count drift guard (actual == canonical declaration) confirmed"
exit 0
