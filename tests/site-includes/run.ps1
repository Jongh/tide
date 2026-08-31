# tide site-include resolution live test (Windows PowerShell 5.1)
#
# Verifies, WITHOUT invoking mkdocs, that the MkDocs snippet includes in the site shells
# actually resolve: include target exists, the referenced section marker pair is balanced
# (exactly one start/end, start before end), and the marker-delimited body region (what
# becomes site content) carries ZERO excluded terms. This is a deterministic static proxy
# for the release-preflight "build-output excluded-term 0" manual scan, so the local blind
# spot (snippet target / marker / term-leak) is closed without a full build.
#
# SCOPE BOUNDARY (important): this harness is NOT a substitute for `mkdocs build --strict`.
# It checks include-target resolution + section-marker balance + a static excluded-term
# guard only. Real render / nav / link breakage / mkdocs-config regression stays CI's job
# (.github/workflows/deploy-pages.yml). It also does NOT duplicate `tests/discover` Part B2
# (which only checks that a site page IS a snippet shell) -- T02 goes further by resolving
# the include targets/section markers and scanning the body region for excluded terms.
#
# Excluded-term single source: the term list is NOT hardcoded here (which would itself leak
# it into the source / drift from the convention). Per docs/conventions.md ("meta-term leak
# prevention" / "release build-output verification"), the excluded term is the external
# attribution kept OUT of the snippet body. We derive it from the masthead intro region that
# lives OUTSIDE the body markers (README.md / docs/conventions.md line-3 "<TERM>... methodology"
# pattern) -- pulling the rule from the convention's intent, self-updating, no duplicated list.
# A positive-control then re-confirms each derived term LITERALLY occurs in that masthead
# region -- otherwise a mis-extracted token (absent from the body) would pass the term scan
# vacuously (green for the wrong reason); this proves the scanner handles a REAL string.
#
# ASCII-only source, no BOM, no byte > 127: the Korean "methodology" phrase used to locate
# the term is built from code points, so this file carries no hardcoded excluded term.
#
# Usage: & tests\site-includes\run.ps1   (exit 0 if all pass, exit 1 if any fail)

$ErrorActionPreference = 'SilentlyContinue'

# Resolve repo root from the script location (like tests/fleet|discover).
$ROOT = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$script:pass = 0; $script:fail = 0

# Completion guard (M37 rework 4) -- a runner that dies partway must never look green.
# The M37 review blocker: one PowerShell-version-only error aborted the run, most cases never ran,
# `$script:fail` was still 0, and the script printed its success banner and exited 0. Two mechanisms
# close that: the trap turns any terminating error into a loud exit 1.
# THIS RUNNER CARRIES THE TRAP ONLY -- deliberately, and it is the one of the six that differs.
# The other five wrap their body in try/finally, so a `$script:completed` flag set only by the result
# line detects a run that skipped the end. Here the body is top-level and the result line is the
# statement directly before the exit logic, so such a flag could never be observed false: it would be
# a self-vacuous assertion, the very class this guard exists to prevent. The trap is the real guard.
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
    if ([string]::Equals([string]$got, [string]$want, [System.StringComparison]::Ordinal)) { $script:pass++; Write-Host ("PASS  {0,-60} ({1})" -f $desc, $got) }
    else { $script:fail++; Write-Host ("FAIL  {0,-60} (got {1}, want {2})" -f $desc, $got, $want) }
}

# PS 5.1 Get-Content mis-decodes UTF-8-without-BOM; read with explicit UTF-8 so multibyte
# content (Korean intro, markers) matches byte-correctly.
function ReadUtf8($file) {
    if (-not (Test-Path $file)) { return $null }
    return [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
}

# Korean "methodology" phrase "<eui> <gaebal> <bangbeomnon>" built from code points so the
# source carries no byte > 127 and no hardcoded excluded term (parity with the .sh twin).
$KO = -join @(0xC758, 0x0020, 0xAC1C, 0xBC1C, 0x0020, 0xBC29, 0xBC95, 0xB860 | ForEach-Object { [char]$_ })

# --- derive the excluded term(s) from the masthead intro (outside body markers) --
# The external attribution sits in the line-3 intro of README/conventions, in the form
# "<TERM>... <KO>". That intro is deliberately kept OUTSIDE [start:body], so the term must
# never appear inside the body region. Extract the ASCII word immediately preceding $KO.
function ExtractTerm($file) {
    $raw = ReadUtf8 $file
    if ($null -eq $raw) { return $null }
    $pat = '([A-Za-z][A-Za-z0-9_-]*)' + [regex]::Escape($KO)
    $m = [regex]::Match($raw, $pat)
    if ($m.Success) { return $m.Groups[1].Value } else { return $null }
}

# The masthead intro is line 3 of each source (the line we extract the term from). We keep
# that exact source region so a positive-control can re-confirm the derived term LITERALLY
# occurs in it (not a fabricated / mis-extracted token).
function MastheadRegion($file) {
    $raw = ReadUtf8 $file
    if ($null -eq $raw) { return '' }
    $lines = $raw -split "`n"
    if ($lines.Count -ge 3) { return $lines[2] } else { return '' }
}

$TERMS = @()
$MASTHEAD = ''   # accumulated masthead intro text across the scanned sources
foreach ($src in @((Join-Path $ROOT 'README.md'), (Join-Path $ROOT 'docs\conventions.md'))) {
    $t = ExtractTerm $src
    if (-not $t) { continue }
    $MASTHEAD = $MASTHEAD + "`n" + (MastheadRegion $src)
    # (M42-T03) ordinal dedupe -- `-notcontains` is culture-aware AND case-insensitive, so two excluded
    # terms differing only in case would collapse into one and the body scan would stop looking for the
    # dropped one. The .sh twin dedupes with `case " $TERMS " in *" $t "*)`, which is byte-exact.
    $dup = $false
    foreach ($x in $TERMS) { if ([string]::Equals([string]$x, [string]$t, [System.StringComparison]::Ordinal)) { $dup = $true; break } }
    if (-not $dup) { $TERMS += $t }
}

# Sanity: at least one excluded term derived, else the term scan would be vacuous.
Chk "term: derived >=1 excluded term from masthead intro" $(if ($TERMS.Count -ge 1) { 'ok' } else { 'no' }) 'ok'

# Positive-control: each derived term must LITERALLY occur in the masthead region it was
# extracted from. If a derived term is absent there, extraction fabricated / mis-extracted a
# token -- which would never appear in the body, making the term scan pass VACUOUSLY (green
# for the wrong reason). This proves the scanner handles a REAL string. Handles >1 token.
$ctrlMissing = 0
foreach ($term in $TERMS) {
    if ($MASTHEAD.IndexOf($term) -lt 0) { $ctrlMissing++ }
}
Chk "term: each derived term literally present in masthead region" $ctrlMissing 0

# --- count full pymdownx snippet markers "--8<-- [start|end:<section>]" in a target ----
# Match the FULL marker (with the "--8<-- " prefix inside an HTML comment), not just the
# "[start:<section>]" substring -- the latter also appears in explanatory comments / prose,
# which are not real markers. Returns @(count, firstLineIndex) where index is 0-based or -1.
function MarkerStat($raw, $kind, $section) {
    if ($null -eq $raw) { return @(0, -1) }
    $needle = '--8<-- [' + $kind + ':' + $section + ']'
    $lines = $raw -split "`n"
    $count = 0; $first = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Contains($needle)) {
            $count++
            if ($first -lt 0) { $first = $i }
        }
    }
    return @($count, $first)
}

# --- enumerate snippet shells and their include directives --------------------
# An include line looks like:  --8<-- "<target>:<section>"
# A "snippet shell" = a site/docs/*.md with >=1 such include. Discover by scanning (do not
# hardcode the 4) so new shells are caught. Hand-written pages (index/concepts/
# getting-started) have 0 includes and are simply not shells.
$includeRe = '--8<--\s*"([^"]*):([^"]*)"'

$shells = 0
$includesTotal = 0

foreach ($page in Get-ChildItem (Join-Path $ROOT 'site\docs') -Filter '*.md' -File) {
    $raw = ReadUtf8 $page.FullName
    if ($null -eq $raw) { continue }
    $incs = [regex]::Matches($raw, $includeRe)
    if ($incs.Count -lt 1) { continue }   # not a shell (0 includes) -> hand-written page
    $shells++

    Chk "shell $($page.Name): include count >=1" $(if ($incs.Count -ge 1) { 'ok' } else { 'no' }) 'ok'

    foreach ($inc in $incs) {
        $includesTotal++
        $target  = $inc.Groups[1].Value
        $section = $inc.Groups[2].Value
        $label   = "$target`:$section"
        $tfile   = Join-Path $ROOT ($target -replace '/', '\')

        # (2a) target file exists (path is repo-root-relative)
        Chk "shell $($page.Name) -> ${label}: target file exists" $(if (Test-Path $tfile) { 'ok' } else { 'no' }) 'ok'

        $traw = ReadUtf8 $tfile
        $s = MarkerStat $traw 'start' $section
        $e = MarkerStat $traw 'end'   $section
        $ns = $s[0]; $ls = $s[1]
        $ne = $e[0]; $le = $e[1]

        # (2b/3) exactly one balanced marker pair (start before end)
        Chk "target $label`: start marker count == 1" $ns 1
        Chk "target $label`: end marker count == 1"   $ne 1
        $balanced = if (($ns -eq 1) -and ($ne -eq 1) -and ($ls -ge 0) -and ($le -ge 0) -and ($ls -lt $le)) { 'ok' } else { 'bad' }
        Chk "target $label`: balanced pair (start before end)" $balanced 'ok'

        # (4) excluded-term scan inside the marker-delimited body region
        $leak = 0
        if ($balanced -eq 'ok') {
            $lines = $traw -split "`n"
            for ($i = $ls + 1; $i -lt $le; $i++) {
                foreach ($term in $TERMS) {
                    $idx = 0
                    while (($idx = $lines[$i].IndexOf($term, $idx)) -ge 0) { $leak++; $idx += $term.Length }
                }
            }
        }
        Chk "body $label`: excluded-term occurrences == 0" $leak 0
    }
}

# At least one shell must exist (the site is snippet-driven); 0 shells = drift.
Chk "site: discovered >=1 snippet shell" $(if ($shells -ge 1) { 'ok' } else { 'no' }) 'ok'
Chk "site: discovered >=1 include directive" $(if ($includesTotal -ge 1) { 'ok' } else { 'no' }) 'ok'

# === case-count self-consistency (M38-T01) ==============================
# The completion guard (M37) catches a runner that ABORTS; it does not catch one that stays alive
# and RUNS LESS -- and this harness is DISCOVERY-DRIVEN (shells x include targets), so "found
# fewer shells than last time" is exactly the silent shrink it must not survive. The expected
# case count has a single declaration site -- this harness's README (convention: the document
# self-description section of docs/conventions.md) -- never hardcoded here. If the declaration
# cannot be read (file missing / no `cases` token) the extraction is empty and this FAILS:
# "could not read it, so skip the check and pass" is the very class this kills.
# The case is itself a case, so it goes LAST and compares running-total + 1 (same shape as
# tests/discover F1; identical assertion name and verdict in both shells).
function DeclaredCases($path) {
    if (-not (Test-Path $path)) { return '' }
    $raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($raw, 'cases:[^0-9\r\n]*([0-9]+)')
    if ($m.Success) { return $m.Groups[1].Value } else { return '' }
}
# --- sandbox (M57 -- workflow fixtures live here) -----------------------
$sbx = Join-Path ([System.IO.Path]::GetTempPath()) "tide-site-includes-live.$PID"
if (Test-Path $sbx) { Remove-Item -Recurse -Force $sbx }
New-Item -ItemType Directory -Force -Path $sbx | Out-Null

# === CI build-output scan wiring (M57) ==================================
# Of the shares the convention declares, only the CI scan step bites the BUILD OUTPUT's
# excluded terms -- (1) is a human, (2) is render only, (3) is this harness on the SOURCE.
# If that step is dropped, or slides AFTER the upload, it stops being a gate -- and until
# now nothing reddened either way. What is bitten here is the WIRING: does the step exist
# and is the order right. It is located NOT by step name but by the fact that it reads the
# single source of the term derivation (names change; the file it reads is the contract).
$PAGES_WF = Join-Path $ROOT '.github/workflows/deploy-pages.yml'
$SCAN_REF = 'tests/lib/excluded-terms.sh'
$UPLOAD_REF = 'upload-pages-artifact'

function WfLine([string]$path, [string]$token) {
    # -> 1-based line number of the token's first occurrence on a NON-COMMENT line, 0 when absent.
    # A comment is not wiring (opened by adversarial axis `adv-scan-commented`: commenting the
    # scan line out left the token in place and the harness stayed green at 41/0). Separate the
    # lines that TALK about the token from the lines that USE it. Inside a YAML `run: |` block a
    # leading `#` is a shell comment, so the same rule holds on both sides.
    if (-not (Test-Path $path)) { return 0 }
    $lines = [System.IO.File]::ReadAllLines($path)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimStart().StartsWith('#', [System.StringComparison]::Ordinal)) { continue }
        if ($lines[$i].IndexOf($token, [System.StringComparison]::Ordinal) -ge 0) { return ($i + 1) }
    }
    return 0
}
function WfOrder([string]$path) {
    # -> 'ok' when the scan precedes the upload; 'no' when either is missing or out of order.
    $sc = WfLine $path $SCAN_REF
    $up = WfLine $path $UPLOAD_REF
    if ($sc -le 0 -or $up -le 0) { return 'no' }
    if ($sc -lt $up) { return 'ok' }
    return 'no'
}
function WfFixture([string]$mode) {
    # drop: remove the scan / after: move it past the upload / noise: add an unrelated step.
    $f = Join-Path $sbx ('pages-' + $mode + '.yml')
    $out = New-Object System.Collections.ArrayList
    $held = ''
    foreach ($l in [System.IO.File]::ReadAllLines($PAGES_WF)) {
        if ($l.IndexOf($SCAN_REF, [System.StringComparison]::Ordinal) -ge 0) {
            if ($mode -eq 'drop') { continue }
            if ($mode -eq 'after') { $held = $l; continue }
        }
        if ($mode -eq 'after' -and $held -ne '' -and $l.IndexOf($UPLOAD_REF, [System.StringComparison]::Ordinal) -ge 0) {
            [void]$out.Add($l); [void]$out.Add($held); $held = ''; continue
        }
        [void]$out.Add($l)
    }
    if ($mode -eq 'noise') { [void]$out.Add('      - run: echo zzz-unrelated-step') }
    [System.IO.File]::WriteAllLines($f, $out.ToArray(), (New-Object System.Text.UTF8Encoding($false)))
    return $f
}
Chk "ci-scan: workflow reads the excluded-term single source" $(if ((WfLine $PAGES_WF $SCAN_REF) -gt 0) { 'ok' } else { 'no' }) 'ok'
Chk "ci-scan: the scan sits BEFORE the artifact upload" (WfOrder $PAGES_WF) 'ok'
# Fixture controls -- the REAL verdict runs on the copy (M46 precedent), two directions.
Chk "ci-scan: control -- removing the scan step is caught" (WfOrder (WfFixture 'drop')) 'no'
Chk "ci-scan: control -- moving it after the upload is caught" (WfOrder (WfFixture 'after')) 'no'
# False-positive direction -- unrelated steps do not change the wiring.
Chk "ci-scan: false-positive direction -- an unrelated step passes" (WfOrder (WfFixture 'noise')) 'ok'
# A hardcoded term in the workflow would be a SECOND declaration site and leak into the source.
$wfLiteral = 0
$wfText = [System.IO.File]::ReadAllText($PAGES_WF, [System.Text.Encoding]::UTF8)
foreach ($term in $TERMS) {
    $i = $wfText.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase)
    while ($i -ge 0) { $wfLiteral++; $i = $wfText.IndexOf($term, $i + 1, [System.StringComparison]::OrdinalIgnoreCase) }
}
Chk "ci-scan: no excluded-term literal in the workflow" ([string]$wfLiteral) '0'

# === Workflow block-scalar integrity (M57 -- opened by measurement during impl) =========
# A LITERAL newline inside a command argument in a `run: |` block forces the next line to
# start at COLUMN 0. That ends the YAML block scalar right there and the WHOLE workflow
# fails to parse. That state actually entered the tree once, and all six wiring cases above
# stayed GREEN -- "the step exists and precedes the upload" was true while the workflow
# would not load at all, so there was NO gate. That is this cycle's class exactly.
# A YAML parser cannot be required of all four runtimes, so the COLUMN-0 rule is bitten
# instead: a non-empty line at column 0 is either a top-level key or a comment.
function WfCol0Bad([string]$path) {
    if (-not (Test-Path $path)) { return 999 }
    $n = 0
    foreach ($l in [System.IO.File]::ReadAllLines($path)) {
        $s = $l.TrimEnd([char]13)
        if ($s.Length -eq 0) { continue }
        if ($s.StartsWith(' ', [System.StringComparison]::Ordinal)) { continue }
        if ($s.StartsWith([string][char]9, [System.StringComparison]::Ordinal)) { continue }
        if ($s.StartsWith('#', [System.StringComparison]::Ordinal)) { continue }
        if ($s -cmatch '^[A-Za-z_][A-Za-z0-9_.-]*:') { continue }
        $n++
    }
    return $n
}
function WfCol0Keys([string]$path) {
    if (-not (Test-Path $path)) { return 0 }
    $n = 0
    foreach ($l in [System.IO.File]::ReadAllLines($path)) {
        if ($l.TrimEnd([char]13) -cmatch '^[A-Za-z_][A-Za-z0-9_.-]*:') { $n++ }
    }
    return $n
}
function WfWorkflows() { @(Get-ChildItem -Path (Join-Path $ROOT '.github/workflows') -Filter '*.yml' -File | ForEach-Object { $_.FullName }) }
function WfCol0Total() { $n = 0; foreach ($f in WfWorkflows) { $n += (WfCol0Bad $f) }; return $n }
function WfKeyTotal() { $n = 0; foreach ($f in WfWorkflows) { $n += (WfCol0Keys $f) }; return $n }
function WfYamlFixture([string]$mode) {
    # break: plant a column-0 line inside the run block / addkey: append a legit top-level key
    $f = Join-Path $sbx ('pages-yaml-' + $mode + '.yml')
    $out = New-Object System.Collections.ArrayList
    $hit = $false
    foreach ($l in [System.IO.File]::ReadAllLines($PAGES_WF)) {
        [void]$out.Add($l)
        if ($mode -eq 'break' -and -not $hit -and $l.IndexOf('run: |', [System.StringComparison]::Ordinal) -ge 0) {
            [void]$out.Add('zzz-broken-continuation'); $hit = $true
        }
    }
    if ($mode -eq 'addkey') { [void]$out.Add('zzz-extra-key: 1') }
    [System.IO.File]::WriteAllLines($f, $out.ToArray(), (New-Object System.Text.UTF8Encoding($false)))
    return $f
}
Chk "wf-yaml: top-level key extraction positive-control(>0)" $(if ((WfKeyTotal) -gt 0) { 'ok' } else { 'no' }) 'ok'
Chk "wf-yaml: no column-0 line outside the YAML top level" ([string](WfCol0Total)) '0'
# Fixture control -- the REAL verdict runs on the copy (M46 precedent); a broken block reddens.
Chk "wf-yaml: control -- a column-0 continuation is caught" ([string](WfCol0Bad (WfYamlFixture 'break'))) '1'
# False-positive direction -- a legitimate new top-level key stays green.
Chk "wf-yaml: false-positive direction -- a new top-level key passes" ([string](WfCol0Bad (WfYamlFixture 'addkey'))) '0'

Chk "case-count: README cases declaration == actual" (DeclaredCases (Join-Path $ROOT 'tests\site-includes\README.md')) ([string]($script:pass + $script:fail + 1))

Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail) (shells=$shells includes=$includesTotal terms=[$($TERMS -join ',')]) [runtime: PowerShell $($PSVersionTable.PSVersion) $($PSVersionTable.PSEdition)]"
if ($script:fail -ne 0) { exit 1 }
Write-Host "# site-include resolution (target exists + balanced [start]/[end] marker pair + excluded-term 0 in body + derived terms real in masthead) confirmed -- NOT a mkdocs --strict substitute (render/nav/link = CI)"
exit 0
