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
#   - Scope is limited to declaration-token cases: breaking a literal token in a data file
#     generalizes, but disabling verdict CODE takes a different edit every time and does not fit a
#     declaration. Code-side coverage stays with the per-case revert measurement the conventions require.
#   - Cost decides scope: one mutation = copy + one full target run. On this machine the sh copy of
#     discover takes ~72s and this copy ~6s (12x asymmetry -- Windows process spawn). A full sweep is
#     infeasible locally; CI ubuntu is ~13x faster, so the full sweep belongs there.
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

try {
    New-Item -ItemType Directory -Path $SBX -Force | Out-Null

    # --- declarations ----------------------------------------------------
    # form: `# mutates: <file> :: <token> :: <stable case-label prefix> :: <caught|missed>`
    $ann = @([IO.File]::ReadAllLines($TARGET) | Where-Object { $_ -match '^# mutates:' })

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

    # --- mutation loop ---------------------------------------------------
    $i = 0
    foreach ($line in $ann) {
        $i++
        $parts = ($line -replace '^# mutates:', '') -split ' :: '
        $f    = $parts[0].Trim()
        $tok  = $parts[1].Trim()
        $lab  = $parts[2].Trim()
        $want = $parts[3].Trim()

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
            [IO.File]::WriteAllText($mf, $txt.Replace($tok, 'MUTATED-BY-tide-mutation'))
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
