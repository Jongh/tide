# tests/mutation -- does a case actually bite its own subject? (M47)
#
# What it does: for each `# mutates:` declaration in the target runner (tests/discover/run.ps1),
#   (1) copy the tree, (2) BREAK the declared token in the declared file, (3) run the target
#   harness, (4) check whether the declared CASE shows up in the FAIL list.
# If it does not, that case is a TAUTOLOGY -- a control that stays green while the verdict is
# destroyed is not a control (conventions, "blocking-grade precedents" section, M47 generalization).
#
# Why this shape (measured in M47-T01):
#   - Prefix identifiers (F15, D6, ...) CANNOT be the key: only 72 of discover's 172 cases (42%)
#     have a unique prefix, and 6 of the 9 cases M46 added share prefixes. The label prefix up to
#     the first interpolation IS unique (161/161 in both copies), so that is the key. The two
#     copies use different label languages, so EACH COPY READS ITS OWN LABELS.
#   - SCOPE NOW REACHES VERDICT CODE (M63). The previous version limited the subject to data-file
#     declaration tokens and handed code-side coverage to "the per-case revert measurement (a human)".
#     M62 MEASURED THAT HANDOFF FAILING: a human revert table only perturbs ARTIFACTS, so no row ever
#     aimed at the runner itself, and one adversarial control sat there DEAD (delete its predicate and
#     both axes stayed fully green). What blocked code tokens was not the principle but the GRAMMAR --
#     tokens were restricted to alphanumerics and hyphens, so a code literal could not be written down.
#   - THEREFORE THE REPLACE MUST BE LITERAL. A widened token carries `.`, `*`, `[`, `|`, which `sed`
#     reads as regex metacharacters. This copy already used `String.Replace` (literal), so THE TWO
#     COPIES WERE ALREADY SPLIT (measured in M63); `LitReplace` + `X6` pin them together -- BUT ONLY
#     FOR SINGLE-LINE, LF CONTENT. The .sh twin's `awk` strips CR and appends a missing final newline,
#     so ON A CRLF FILE OR A FILE WITH NO FINAL NEWLINE THE TWO COPIES STILL DIVERGE (measured by the
#     M63 review -- `docs/conventions.md`, which two of the declarations target, is CRLF here).
#     Not a regression: the previous `sed` path stripped CR too. The single source for that boundary
#     is the "two copies" section of `tests/mutation/README.md`.
#   - Cost decides scope: one mutation = copy + one full target run. MEASURED ON THIS MACHINE (M63):
#     the sh copy of discover takes 407-679s and this copy ~19s (20x+ asymmetry -- Windows process
#     spawn). THE CONDITION THE NUMBER WAS TAKEN UNDER MATTERS: those are values with no other heavy
#     job running; under contention the same axis reached 1652-1932s (M62). EVEN WITHOUT CONTENTION
#     THE SAME AXIS SWINGS 1.7x (M63 review, same tree and session: Git Bash `sh` 679s, `dash` 448s),
#     so THIS HAS TO BE A RANGE, NOT A POINT -- a point goes stale on the very next measurement,
#     which is why M63 had to edit this line twice. The previous note said
#     "~72s", a value from when discover had 172 cases -- 6x stale. A full sweep is infeasible
#     locally; CI ubuntu is much faster, so the full sweep belongs there.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ROOT       = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$TARGET_REL = 'tests\discover\run.ps1'
$TARGET     = Join-Path $ROOT $TARGET_REL
$README     = Join-Path $PSScriptRoot 'README.md'
$SBX        = Join-Path ([IO.Path]::GetTempPath()) ("tide-mutation-" + [Guid]::NewGuid().ToString('N'))

# Completion guard (M37 rework 4 form, added to this runner in M47 review round 3) -- a runner that
# dies partway must never look green. The trap turns any terminating error into a LOUD exit 1 with the
# canonical marker, and the completed flag (set ONLY by the result line) catches every other way of
# skipping the end of the run. The comment in tests/discover/run.ps1 states the repo-wide requirement:
# "Keep the TRAP identical in all six run.ps1" -- this is the seventh, and it was missing both halves.
# Measured before the fix: an injected mid-run error exited 1 with no success banner (so the M37
# failure mode did NOT reproduce) but printed a raw PowerShell exception instead of this marker.
$script:completed = $false
trap {
    Write-Host "`n# ABORTED at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    Write-Host "# INCOMPLETE RUN -- the harness did not reach its result line; treat as FAIL"
    exit 1
}

$script:pass = 0
$script:fail = 0
function Chk([string]$desc, [string]$got, [string]$want) {
    # M57: the verdict is pinned to ORDINAL. M42-T03 pinned every OTHER runner and this one was
    # left out -- the claim "every assertion flows through here" held for five of seven copies.
    # PowerShell's `-eq` on strings is a CULTURE comparison while the .sh twin's `[ "$2" = "$3" ]`
    # is byte-exact, so a case-only or canonically-equivalent difference would pass here and fail
    # there. Part Q of tests/discover now bites any verdict site that is neither pinned nor
    # DECLARED exempt.
    if ([string]::Equals([string]$got, [string]$want, [System.StringComparison]::Ordinal)) { $script:pass++; "PASS  {0,-56} ({1})" -f $desc, $got | Write-Host }
    else { $script:fail++; "FAIL  {0,-56} (got {1}, want {2})" -f $desc, $got, $want | Write-Host }
}

# --- literal replace -----------------------------------------------------
# NOT a regex. A widened token (a literal out of the verdict CODE) can carry `.`, `*`, `[`, `|`, and
# a regex path would rewrite places the declaration never named. This copy already used the literal
# `String.Replace`, while the .sh twin used `sed` -- so the two copies could answer the same
# declaration differently. `X6` pins that isomorphism; the helper exists so the case and the loop
# share one implementation (one question, one answer, per copy).
# THE ISOMORPHISM REACHES SINGLE-LINE, LF CONTENT. This copy is byte-faithful; the .sh twin is
# line-based `awk`, so it strips CR and appends a missing final newline. The replaced token itself
# comes out the same in both -- what diverges is the target file's LINE ENDINGS (M63 review).
# Boundary single source: the "two copies" section of `tests/mutation/README.md`.
function LitReplace([string]$text, [string]$tok, [string]$rep) {
    if ([string]::IsNullOrEmpty($tok)) { return $text }
    return $text.Replace($tok, $rep)
}

try {
    New-Item -ItemType Directory -Path $SBX -Force | Out-Null

    # --- declarations ----------------------------------------------------
    # two forms:
    #   `# mutates:    <file> :: <token> :: <stable case-label prefix> :: <caught|missed>`
    #   `# mutates-to: <file> :: <from> :: <to> :: <stable case-label prefix> :: <caught|missed>`
    # THE SECOND FORM ARRIVED IN M63. The first replaces the token with a FIXED nonsense string, so it
    # only asks "is this literal load-bearing". Pointed at verdict code it either (1) breaks the syntax
    # and kills the runner outright -- the named case is then absent from the FAIL list, so the result
    # is `missed` -- or (2) survives but still cannot express a regression that merely LOOSENS the
    # verdict (bold code span -> plain backtick). M62 was hit by exactly the latter. The second form
    # lets the declaration say WHAT TO PUT THERE, reproducing that regression directly.
    # THE TWO FORMS ARE SEPARATE KEYWORDS: allowing two field counts under one keyword would leave
    # `X5` unable to tell a shifted line (a separator inside a token) from a legitimate 5-field line.
    $ann = @([IO.File]::ReadAllLines($TARGET) | Where-Object { $_ -match '^# mutates(-to)?:' })

    # (X1) extraction positive-control -- with zero declarations the loop below never runs and the
    # harness passes vacuously (checklist item 1). This is the first self-hollowness to block.
    Chk "X1: mutates declaration extraction positive-control (>0)" $(if ($ann.Count -gt 0) { 'ok' } else { 'no' }) 'ok'

    # (X2a/X4a) DECLARATION-LINE UNIQUENESS (checklist item 2) -- count the declaration line BEFORE
    # reading its value. The first version took the first match only and never asked whether it was
    # unique; the review reproduced the resulting hollowness: leave the real declaration stale at
    # `cases: 99` and put `cases: 5` in prose ABOVE it (this repo really does write historical numbers
    # in prose) and the harness scored 5/0 green on a stale declaration. The conventions predict this
    # failure in words -- "without uniqueness a section order or a single prose line silently swaps the
    # whole set." Same shape as `F14` in tests/discover.
    $declLine = @([IO.File]::ReadAllLines($README) | Where-Object { $_ -match 'mutations:\s*[0-9]' })
    Chk "X2a: mutations declaration line is unique" ([string]$declLine.Count) '1'

    # (X2) declaration-count agreement -- README's `mutations:` line is the single declaration site
    # and both copies compare against it, which indirectly pins the two copies to the same count.
    $decl = if ($declLine.Count -ge 1) { [regex]::Match($declLine[0], 'mutations:\s*([0-9]+)').Groups[1].Value } else { 'none' }
    Chk "X2: README mutations declaration == measured count" $decl ([string]$ann.Count)

    # (X5) DECLARATION FIELD COUNT (M63) -- widening the token grammar leaves exactly ONE ban: the
    # field separator ` :: `. A token carrying that string splits one field too many and `$4` then
    # holds something that is not the verdict value. The previous version never asked, so the drift
    # was SILENT -- the widening edit opens that door, so the same edit closes it.
    $badFields = 0
    foreach ($line in $ann) {
        if ($line.StartsWith('# mutates-to:', [System.StringComparison]::Ordinal)) {
            $want = 5; $body = $line -replace '^# mutates-to:', ''
        } else {
            $want = 4; $body = $line -replace '^# mutates:', ''
        }
        $nf = @($body -split ' :: ').Count
        if ($nf -ne $want) { $badFields++ }
    }
    Chk "X5: field count matches the keyword's rule" ([string]$badFields) '0'

    # (X6) LITERAL-REPLACE SELF-TEST (M63) -- with a regex `a.c` also matches `abc`; literally it
    # matches only `a.c`. BOTH COPIES MUST ANSWER THE SAME on the same fixture, or the widened grammar
    # splits the axes (the .sh twin carries the same case name and the same fixture). The previous .sh
    # used `sed` (regex) and answered `Z Z` here, while this copy already used a literal replace.
    Chk "X6: literal replace -- regex metacharacter token" (LitReplace 'abc a.c' 'a.c' 'Z') 'abc Z'

    # --- mutation loop ---------------------------------------------------
    $i = 0
    foreach ($line in $ann) {
        $i++
        if ($line.StartsWith('# mutates-to:', [System.StringComparison]::Ordinal)) {
            $parts = ($line -replace '^# mutates-to:', '') -split ' :: '
            $rep  = $parts[2].Trim()
            $lab  = $parts[3].Trim()
            $want = $parts[4].Trim()
        } else {
            $parts = ($line -replace '^# mutates:', '') -split ' :: '
            $rep  = 'MUTATED-BY-tide-mutation'
            $lab  = $parts[2].Trim()
            $want = $parts[3].Trim()
        }
        $f    = $parts[0].Trim()
        $tok  = $parts[1].Trim()

        $W = Join-Path $SBX "m$i"
        New-Item -ItemType Directory -Path $W -Force | Out-Null
        # copy: .git and the site build output take no part in the verdict (cost).
        # `-Exclude` does NOT apply below the top level when combined with `-Recurse` -- measured:
        # a tree with site/_build/big.txt copied that file anyway, so this copy did tens of MB of
        # extra work per mutation while the sh copy really excluded it (review minor 5, an asymmetry
        # between the two copies). Delete the directory after the copy instead.
        Get-ChildItem -LiteralPath $ROOT -Force | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $W -Recurse -Force
        }
        $bld = Join-Path $W 'site\_build'
        if (Test-Path -LiteralPath $bld) { Remove-Item -LiteralPath $bld -Recurse -Force }

        # Break the token. REPLACE, do not append: the first sh version wrote `<tok>-MUTANT`, which
        # CONTAINS the original as a substring, so substring checks still found it and the mutation
        # was a no-op. The harness's own first run reported that as `missed` and caught it (M47).
        $mf = Join-Path $W $f
        if (Test-Path -LiteralPath $mf) {
            $txt = [IO.File]::ReadAllText($mf)
            [IO.File]::WriteAllText($mf, (LitReplace $txt $tok $rep))
        }

        $out = & pwsh -NoProfile -File (Join-Path $W $TARGET_REL) 2>&1 | Out-String
        $hit = @($out -split "`n" | Where-Object { $_ -match '^FAIL' -and $_.Contains($lab) })
        $r = if ($hit.Count -gt 0) { 'caught' } else { 'missed' }
        Chk "X3[$want]: $lab" $r $want
        Remove-Item -LiteralPath $W -Recurse -Force -ErrorAction SilentlyContinue
    }

    # (X4) case-count self-consistency -- compare README's `cases:` declaration against the ACTUAL
    # count. All six existing harnesses carry this and only this one lacked it (review blocker 1),
    # while the README CLAIMED the runner checks it: adding a declaration would grow the case count
    # with the declaration left stale and nothing going red. `+ 1` counts this case (discover's F1 idiom).
    $declCases = @([IO.File]::ReadAllLines($README) | Where-Object { $_ -match 'cases:\s*[0-9]' })
    Chk "X4a: cases declaration line is unique" ([string]$declCases.Count) '1'
    $dc = if ($declCases.Count -ge 1) { [regex]::Match($declCases[0], 'cases:\s*([0-9]+)').Groups[1].Value } else { 'none' }
    Chk "X4: README cases declaration == actual case count" $dc ([string]($script:pass + $script:fail + 1))

    Write-Host ""
    Write-Host ("# result: PASS={0} FAIL={1} (mutations {2}, target {3}) [runtime: PowerShell {4} {5}]" -f `
        $script:pass, $script:fail, $ann.Count, $TARGET_REL, $PSVersionTable.PSVersion, $PSVersionTable.PSEdition)
    $script:completed = $true
}
finally {
    Remove-Item -LiteralPath $SBX -Recurse -Force -ErrorAction SilentlyContinue
}

# The exit decisions sit OUTSIDE the try/finally so the completed flag is read after cleanup --
# same order as the six existing run.ps1.
if (-not $script:completed) {
    Write-Host "# INCOMPLETE RUN -- the harness did not reach its result line; treat as FAIL"
    exit 1
}
if ($script:fail -ne 0) { exit 1 }
Write-Host "# mutation: breaking a declared token must redden the declared case -- tautological-case detection (reference implementation)"
exit 0
