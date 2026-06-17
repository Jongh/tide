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
#
# ASCII-only source (BOM present, no byte > 127): the Korean "methodology" phrase used to
# locate the term is built from code points, so this file carries no hardcoded excluded term.
#
# Usage: & tests\site-includes\run.ps1   (exit 0 if all pass, exit 1 if any fail)

$ErrorActionPreference = 'SilentlyContinue'

# Resolve repo root from the script location (like tests/fleet|discover).
$ROOT = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$script:pass = 0; $script:fail = 0
function Chk($desc, $got, $want) {
    if ($got -eq $want) { $script:pass++; Write-Host ("PASS  {0,-60} ({1})" -f $desc, $got) }
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

$TERMS = @()
foreach ($src in @((Join-Path $ROOT 'README.md'), (Join-Path $ROOT 'docs\conventions.md'))) {
    $t = ExtractTerm $src
    if ($t -and ($TERMS -notcontains $t)) { $TERMS += $t }
}

# Sanity: at least one excluded term derived, else the term scan would be vacuous.
Chk "term: derived >=1 excluded term from masthead intro" $(if ($TERMS.Count -ge 1) { 'ok' } else { 'no' }) 'ok'

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

Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail) (shells=$shells includes=$includesTotal terms=[$($TERMS -join ',')])"
if ($script:fail -ne 0) { exit 1 }
Write-Host "# site-include resolution (target exists + balanced [start]/[end] marker pair + excluded-term 0 in body) confirmed -- NOT a mkdocs --strict substitute (render/nav/link = CI)"
exit 0
