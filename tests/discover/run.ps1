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
. (Join-Path $ROOT 'tests\lib\discover.ps1')

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

# IsTideRepo/Discover: tests\lib\discover.ps1 (single source)

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

    # === Part B -- single-source freeze: canonical catalog + drift guard ====
    # (M22) the command catalog is single-sourced in docs/commands.md; the site page is a snippet shell.
    # The guard checks (B1) count-declaration consistency, (B2) the site catalog page is a shell (not a
    # re-duplication), (B3) catalog completeness (each command name present). Extends M20-review #6.

    # actual command skill count = number of skills/*/SKILL.md files
    $N = @(Get-ChildItem (Join-Path $ROOT 'skills') -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }).Count
    Chk "B: actual command skill count measured (>0)" $(if ($N -gt 0) { 'ok' } else { 'no' }) 'ok'

    $README    = Join-Path $ROOT 'README.md'
    $CONV      = Join-Path $ROOT 'docs\conventions.md'
    $CANON_CMD = Join-Path $ROOT 'docs\commands.md'        # new canonical command catalog (single source)
    $SITE_CMD  = Join-Path $ROOT 'site\docs\commands.md'   # site shell (snippet include)
    $SITE_GS   = Join-Path $ROOT 'site\docs\getting-started.md'

    # PS 5.1 Get-Content mis-decodes UTF-8-without-BOM; read with explicit UTF-8 so the Korean counter
    # token (U+C885) and other multibyte content match byte-correctly.
    function ReadUtf8($file) {
        if (-not (Test-Path $file)) { return $null }
        return [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
    }

    # (B1) count-declaration consistency -- "N<jong>" sites match the actual skill count; divergence -> FAIL.
    #      site/docs/commands.md is now a shell (no count) -> replaced by canonical docs/commands.md.
    function DeclaredHasCount($file, $count) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return 'no' }
        if ($raw.Contains("$count$JONG")) { return 'yes' } else { return 'no' }
    }
    Chk "B1: docs/commands.md declares N$JONG (canonical)" (DeclaredHasCount $CANON_CMD $N) 'yes'
    Chk "B1: README.md declares N$JONG"                    (DeclaredHasCount $README $N)    'yes'
    Chk "B1: docs/conventions.md declares N$JONG"          (DeclaredHasCount $CONV $N)      'yes'
    Chk "B1: site/docs/getting-started.md declares N$JONG" (DeclaredHasCount $SITE_GS $N)   'yes'

    # (B2) the site catalog page is a snippet shell -- has the include AND re-declares neither the count
    #      nor the catalog table. Re-duplication (catalog regression) -> FAIL, enforcing single-sourcing.
    function IsSnippetShell($file, $count) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return 'no' }
        if (-not $raw.Contains('8<-- "docs/commands.md:body"')) { return 'no' }   # include present
        if ($raw.Contains("$count$JONG")) { return 'no' }                          # count re-declared
        if ($raw.Contains('|---|---|---|---|')) { return 'no' }                     # catalog table re-declared
        return 'yes'
    }
    Chk "B2: site/docs/commands.md is a snippet shell (not re-duplicated)" (IsSnippetShell $SITE_CMD $N) 'yes'

    # (B3) catalog completeness -- each command name appears as /tide:<name> in the canonical catalog.
    #      Catches name-level drift (missing/renamed command) that the count-only guard could not.
    #      Require a boundary after the name (not a letter/hyphen) so /tide:fleet is NOT satisfied by
    #      /tide:fleet-cycle alone (fleet != fleet-cycle) -- the assertion targets intent, not substring.
    function HasCommand($file, $name) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return 'no' }
        $pat = '/tide:' + $name + '([^a-z-]|$)'
        if ($raw -match $pat) { return 'yes' } else { return 'no' }
    }
    $allNamesOk = 'yes'
    foreach ($d in Get-ChildItem (Join-Path $ROOT 'skills') -Directory -ErrorAction SilentlyContinue) {
        if (Test-Path (Join-Path $d.FullName 'SKILL.md')) {
            if ((HasCommand $CANON_CMD $d.Name) -ne 'yes') { $allNamesOk = 'no' }
        }
    }
    Chk "B3: all command names appear in docs/commands.md catalog" $allNamesOk 'yes'

    # name negative control: a bogus command (/tide:bogus) must NOT appear (name check discriminates).
    Chk "B3: name control -- /tide:bogus not in catalog" (HasCommand $CANON_CMD 'bogus') 'no'

    # count negative control: a different count (N+1) must NOT appear in any count-declaration file.
    $WRONG = $N + 1
    Chk "B1: drift control -- docs/commands.md has no $WRONG$JONG"     (DeclaredHasCount $CANON_CMD $WRONG) 'no'
    Chk "B1: drift control -- README has no $WRONG$JONG"               (DeclaredHasCount $README $WRONG)    'no'
    Chk "B1: drift control -- conventions has no $WRONG$JONG"          (DeclaredHasCount $CONV $WRONG)      'no'
    Chk "B1: drift control -- site/getting-started has no $WRONG$JONG" (DeclaredHasCount $SITE_GS $WRONG)   'no'

    Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail) (actual command skills N=$N)"
}
finally {
    Remove-Item -Recurse -Force $sbx -ErrorAction SilentlyContinue
}

if ($script:fail -ne 0) { exit 1 }
Write-Host "# discover detection threshold (>=2->hint / <2->none / single-repo->none / hidden-not-counted) + single-source freeze (B1 count / B2 site shell / B3 catalog completeness, canonical=docs/commands.md) confirmed"
exit 0
