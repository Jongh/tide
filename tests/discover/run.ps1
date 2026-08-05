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
# Part C (M30) enforces one more drift of the same class -- several files declaring ONE fact, where
# fixing only one lets them silently diverge (isomorphic to Part B's command count). Targets: the debug
# item STATUS SET (conventions + debug SKILL + debug template) and the change-summary BASELINE
# (milestone + impl + debug templates).
#
# Part F (M33) enforces what a document says ABOUT ITSELF -- the harness case count (this harness's own
# README 'cases: N' declaration vs its actual case count) and command ROLE ANCHORS (canonical
# 'role-anchors:' map -> canonical table row presence + consumer propagation). Single source:
# conventions "document self-description consistency".
#
# Part G (M34, generalized in M35) enforces the REFERENCES BETWEEN documents -- it extracts the citations
# in the living docs and checks each one PER FILE against the ## / ### anchors of the conventions
# DOCUMENT SET (glob 'docs/conventions*.md'), plus empty-extraction, set-wide duplicate-name and
# wrapped-citation controls. Single source: the "cross-reference integrity" clause of the same section.
#
# ASCII-only source (BOM-independent). Korean tokens (the counter <jong> U+C885, the status values, the
# baseline) are built from code points so the source carries no byte > 127. git mutating verbs live only
# in setup (init only).
#
# Usage: & tests\discover\run.ps1   (exit 0 if all pass, exit 1 if any fail)

$ErrorActionPreference = 'SilentlyContinue'

# Korean counter suffix "<jong>" (U+C885) -- e.g. the "11<jong>" command-count declaration.
$JONG = [string][char]0xC885

# Same rule for multi-syllable tokens: build them from code points so this source stays ASCII-only.
# NOTE: do not name this helper 'Cp' -- that is a built-in alias for Copy-Item, and aliases outrank
# functions in PowerShell command resolution, so the token would silently become empty.
function Uni { param([int[]]$Points) return (-join ($Points | ForEach-Object { [string][char]$_ })) }

# debug item status values -- the four-value set of conventions "debug session" (romanized in comments).
$ST_FIXED   = Uni 0xC218,0xC815,0xD568                        # su-jeong-ham       = fixed
$ST_OPEN    = Uni 0xBBF8,0xD574,0xACB0                        # mi-hae-gyeol       = unresolved
$ST_CAUSE   = Uni 0xC6D0,0xC778,0xB9CC,0x0020,0xADDC,0xBA85   # won-in-man gyu-myeong = cause identified only
$ST_CONFIRM = Uni 0xD655,0xC778,0xD568                        # hwak-in-ham        = confirmed
$ST_BOGUS   = Uni 0xBCF4,0xB958,0xD568                        # bo-ryu-ham         = "on hold" -- NOT a real
                                                              #   status (negative control, like N+1<jong>)
$BASELINE   = Uni 0xAE30,0xC900,0xC120                        # gi-jun-seon        = baseline

# Resolve repo root from the script location (like tests/fleet).
$ROOT = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $ROOT 'tests\lib\discover.ps1')

$sbx = Join-Path ([System.IO.Path]::GetTempPath()) "tide-discover-live.$PID"
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
    #
    # (M38-T04) The dot filter is the MEANING, not an implementation detail: a directory whose name
    # starts with '.' is NOT a command skill. `run.sh` gets that for free -- its POSIX glob
    # `skills/*/SKILL.md` never matches a leading-dot component -- while `Get-ChildItem -Directory`
    # DOES return `.spare`, so without this filter the two shells scan different sets. Measured
    # divergence before the fix, with a single `skills/.spare/SKILL.md` present: sh 85/0 exit 0 vs
    # ps1 79/6 exit 1. Part G of this same runner already carried the dot filter, so the two parts
    # of ONE runner disagreed on the same question. Ordinal per M38-T03 (culture comparison skips
    # ignorable characters, which would make ps1 scan LESS than the glob).
    $N = @(Get-ChildItem (Join-Path $ROOT 'skills') -Directory -ErrorAction SilentlyContinue |
        Where-Object { -not $_.Name.StartsWith('.', [System.StringComparison]::Ordinal) } |
        Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }).Count
    Chk "B: actual command skill count measured (>0)" $(if ($N -gt 0) { 'ok' } else { 'no' }) 'ok'

    $README    = Join-Path $ROOT 'README.md'
    $CONV      = Join-Path $ROOT 'docs\conventions.md'
    $CANON_CMD = Join-Path $ROOT 'docs\commands.md'        # new canonical command catalog (single source)
    $SITE_CMD  = Join-Path $ROOT 'site\docs\commands.md'   # site shell (snippet include)
    $SITE_GS   = Join-Path $ROOT 'site\docs\getting-started.md'
    $ORCH      = Join-Path $ROOT 'docs\orchestration.md'      # included into the site body; carries a count declaration

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
    Chk "B1: docs/orchestration.md declares N$JONG"        (DeclaredHasCount $ORCH $N)      'yes'

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
    # same dot filter as the count above (M38-T04) -- one meaning, both places.
    foreach ($d in (Get-ChildItem (Join-Path $ROOT 'skills') -Directory -ErrorAction SilentlyContinue |
                    Where-Object { -not $_.Name.StartsWith('.', [System.StringComparison]::Ordinal) })) {
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
    Chk "B1: drift control -- orchestration has no $WRONG$JONG"        (DeclaredHasCount $ORCH $WRONG)      'no'

    # === Part C -- declaration-consistency drift guard ======================
    # (M30) Part B enforces drift across documents declaring the same fact (command count); these two are
    # exactly the same class -- several files declare one fact and fixing only one lets them diverge.
    # (C1) the debug item status set (four values) appears in conventions + debug SKILL + debug template;
    # (C2) the change-summary baseline appears in the milestone/impl/debug templates.
    # Single source: docs/conventions.md "debug session" (item status) + "change-summary baseline". The
    # guard binds the DECLARATION's presence (not prose quality), pinning divergence as a regression.

    $DBG_SKILL = Join-Path $ROOT 'skills\debug\SKILL.md'
    $DBG_TPL   = Join-Path $ROOT 'skills\debug\template.md'
    $MS_TPL    = Join-Path $ROOT 'skills\milestone\template.md'
    $IMPL_TPL  = Join-Path $ROOT 'skills\impl\template.md'

    function HasToken($file, $token) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return 'no' }
        if ($raw.Contains($token)) { return 'yes' } else { return 'no' }
    }
    function InAllThree($token, $f1, $f2, $f3) {
        foreach ($f in @($f1, $f2, $f3)) { if ((HasToken $f $token) -ne 'yes') { return 'no' } }
        return 'yes'
    }

    # (C1) status-set consistency -- all four values in all three files; fixing only one -> FAIL.
    foreach ($st in @($ST_FIXED, $ST_OPEN, $ST_CAUSE, $ST_CONFIRM)) {
        Chk "C1: status '$st' in all three files" (InAllThree $st $CONV $DBG_SKILL $DBG_TPL) 'yes'
    }

    # status negative control: a non-existent status ($ST_BOGUS) must appear in NONE of the three files,
    # proving the guard discriminates -- same intent as B1's N+1<jong> absence control.
    Chk "C1: status control -- conventions has no '$ST_BOGUS'"    (HasToken $CONV $ST_BOGUS)      'no'
    Chk "C1: status control -- debug SKILL has no '$ST_BOGUS'"    (HasToken $DBG_SKILL $ST_BOGUS) 'no'
    Chk "C1: status control -- debug template has no '$ST_BOGUS'" (HasToken $DBG_TPL $ST_BOGUS)   'no'

    # (C2) baseline-declaration consistency -- the three templates sharing the add/modify/delete table all
    #      state the baseline. Fixing one template alone splits the table's meaning per file (the drift).
    Chk "C2: skills/milestone/template.md declares '$BASELINE'" (HasToken $MS_TPL $BASELINE)   'yes'
    Chk "C2: skills/impl/template.md declares '$BASELINE'"      (HasToken $IMPL_TPL $BASELINE) 'yes'
    Chk "C2: skills/debug/template.md declares '$BASELINE'"     (HasToken $DBG_TPL $BASELINE)  'yes'

    # (C3) phase-writing command ROSTER (M37) -- conventions declares its own "state file" section the
    # SOLE place enumerating this roster, with the published page site/docs/concepts.md as the ONLY
    # exception. This part enforces that declaration. Background: M36 got this fact wrong THREE times on
    # the same axis because the roster was replicated in five files and each round fixed only some.
    # The conventions declaration covers BOTH lists (the six that write phase and the six that do not),
    # so the enforcement covers both as well -- declaration width == enforcement width (M37 review
    # blocker #1).
    #   - WRITER roster line = one line holding all six command names AND the word 'phase'
    #     (command-catalog rows are not phase context, so they do not match).
    #   - NON-WRITER roster = prose spread over SEVERAL lines in both files, so it is extracted as the
    #     SHORTEST run of consecutive lines (window, max 4) holding all six names.
    # The canonical NAMES ARE written in this runner as needles (writer names below, non-writer names in
    # $NONWRITER_NEEDLES). The drift surface did not disappear -- it MOVED here (renaming a command means
    # fixing both runner copies too). What the runner does not do is DECLARE the roster: it only probes,
    # and if a name drifts the extraction drops to 0 and the count cases fail loudly (no vacuous pass).
    # Checks: counts, set equality across the two files, the set of enumerating files, writer/non-writer
    # disjointness, and negative controls.
    $CONCEPTS = Join-Path $ROOT 'site\docs\concepts.md'
    $ROSTER_NEEDLES = @('phase','milestone','impl','review','release','debug','cycle')
    $NONWRITER_NEEDLES = @('`status`','`fleet`','`retro`','`fleet-verify`','`kickoff`','`fleet-cycle`')

    function RosterLine($file) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return '' }
        foreach ($ln in ($raw -split "`r?`n")) {
            $ok = $true
            foreach ($n in $ROSTER_NEEDLES) { if (-not $ln.Contains($n)) { $ok = $false; break } }
            if ($ok) { return $ln }
        }
        return ''
    }
    function RosterSet($file) {
        $ln = RosterLine $file
        if ($ln -eq '') { return '' }
        $names = @()
        foreach ($m in [regex]::Matches($ln, '`([a-z][a-z-]*)`')) { $names += $m.Groups[1].Value }
        if ($names.Count -eq 0) { return '' }
        return (($names | Sort-Object -Unique -CaseSensitive) -join ' ')
    }
    function RosterCount($file) {
        $s = RosterSet $file
        if ($s -eq '') { return 0 }
        return ($s -split ' ').Count
    }
    function RosterHas($file, $name) {
        if ((' ' + (RosterSet $file) + ' ') -like ('* ' + $name + ' *')) { return 'yes' } else { return 'no' }
    }
    # C-3's own scan set (living docs + skills + hooks) -- BOTH rosters sweep the SAME range. The name is
    # deliberately NOT 'LivingDocs': Part G defines its own LivingDocs with a DIFFERENT range
    # (tests/*/README.md in, hooks out), and two same-named functions would make C-3's range depend on
    # which definition ran last (M37 review recommendation #2). The range means RECURSIVE PLUS
    # DOT-EXCLUDED PLUS CASE-SENSITIVE '.md' -- the axes measured to agree in both shells are: dot names,
    # dot directories (nested included), a dot component ABOVE the repo root, the Hidden attribute, and
    # extension case. Each is listed in tests/discover/README.md's range table; nothing here claims axes
    # beyond those. Per branch:
    #   - docs and site\docs (flat): -Force plus a NAME check mirrors the POSIX glob in run.sh -- a glob
    #     does not match '.foo.md' but Get-ChildItem does, and a glob DOES match Hidden-attribute files
    #     but Get-ChildItem without -Force does not. The ordinal EndsWith('.md') is there because
    #     -Filter is CASE-INSENSITIVE on Windows while the glob and find are not: without it 'X.MD'
    #     would be scanned here and skipped by run.sh.
    #   - skills (recursive): mirrors run.sh's `find ... -name '.*' -prune`. The check runs on the path
    #     RELATIVE TO $ROOT, one segment at a time. Testing $_.FullName instead was the M37 review
    #     blocker: a dot directory ANYWHERE ABOVE the repo (~/.config, .worktrees, CI caches) dropped
    #     the whole skills subtree from the scan and this runner went silently green while run.sh failed.
    # docs/milestones and docs/reports are point-in-time records and are not in the range.
    function RosterScanFiles {
        $cands = @((Join-Path $ROOT 'README.md'))
        foreach ($d in @('docs', 'site\docs')) {
            $dir = Join-Path $ROOT $d
            if (Test-Path -LiteralPath $dir) {
                $cands += (Get-ChildItem -LiteralPath $dir -Filter '*.md' -File -Force -ErrorAction SilentlyContinue |
                            Where-Object { -not $_.Name.StartsWith('.', [System.StringComparison]::Ordinal) -and $_.Name.EndsWith('.md', [System.StringComparison]::Ordinal) } |
                            ForEach-Object { $_.FullName })
            }
        }
        $sk = Join-Path $ROOT 'skills'
        if (Test-Path -LiteralPath $sk) {
            $cands += (Get-ChildItem -LiteralPath $sk -Recurse -Filter '*.md' -File -Force -ErrorAction SilentlyContinue |
                        Where-Object {
                            $rel = $_.FullName.Substring($ROOT.Length + 1)
                            $_.Name.EndsWith('.md', [System.StringComparison]::Ordinal) -and
                                @($rel -split '[\\/]' | Where-Object { $_.StartsWith('.', [System.StringComparison]::Ordinal) }).Count -eq 0
                        } | ForEach-Object { $_.FullName })
        }
        # Nested two-arg Join-Path, NOT the three-arg form: -AdditionalChildPath is PowerShell 6+, and
        # this file's declared runtime is Windows PowerShell 5.1, where a third argument is a binding
        # error. That was the M37 rework 3 blocker -- it aborted the run and still exited 0.
        $hooks = Join-Path $ROOT 'hooks'
        $cands += (Join-Path $hooks 'tide-guard.sh')
        $cands += (Join-Path $hooks 'tide-guard.ps1')
        $out = @()
        foreach ($f in $cands) { if (Test-Path -LiteralPath $f) { $out += $f } }
        return $out
    }
    function RelPath($f) { return (($f.Substring($ROOT.Length + 1)).Replace([string][char]92, '/')) }
    function RosterFiles {
        $hits = @()
        foreach ($f in (RosterScanFiles)) {
            if ((RosterLine $f) -ne '') { $hits += (RelPath $f) }
        }
        if ($hits.Count -eq 0) { return '' }
        return (($hits | Sort-Object -Unique -CaseSensitive) -join ' ')
    }

    # Non-writer roster -- shortest window (max 4 consecutive lines) holding all six names. Measured
    # spans: conventions 2 lines, published page 3. Beyond the bound the window is NOT found and the
    # count case fails loudly -- the bound is the enforced boundary, identical in both runners.
    # The bound variable is NOT named $W: PowerShell variable names are CASE-INSENSITIVE, so $W and the
    # loop's $w would be ONE variable, the condition would always hold and the window would grow to the
    # whole file (M37 review blocker #1 -- run.sh's awk is case-sensitive, so the two shells split).
    # Unrelated backtick tokens on the window's lines (e.g. `.gitignore`) are dropped by the extraction
    # regex below, not by the window being minimal.
    function NonWriterWindow($file) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return '' }
        foreach ($n in $NONWRITER_NEEDLES) { if (-not $raw.Contains($n)) { return '' } }
        $L = @($raw -split "`r?`n")
        $WMAX = 4
        for ($w = 1; $w -le $WMAX; $w++) {
            for ($i = 0; ($i + $w) -le $L.Count; $i++) {
                $s = ($L[$i..($i + $w - 1)] -join "`n")
                $ok = $true
                foreach ($n in $NONWRITER_NEEDLES) { if (-not $s.Contains($n)) { $ok = $false; break } }
                if ($ok) { return $s }
            }
        }
        return ''
    }
    function NonWriterSet($file) {
        $win = NonWriterWindow $file
        if ($win -eq '') { return '' }
        $names = @()
        foreach ($m in [regex]::Matches($win, '`([a-z][a-z-]*)`')) { $names += $m.Groups[1].Value }
        if ($names.Count -eq 0) { return '' }
        return (($names | Sort-Object -Unique -CaseSensitive) -join ' ')
    }
    function NonWriterCount($file) {
        $s = NonWriterSet $file
        if ($s -eq '') { return 0 }
        return ($s -split ' ').Count
    }
    function NonWriterHas($file, $name) {
        if ((' ' + (NonWriterSet $file) + ' ') -like ('* ' + $name + ' *')) { return 'yes' } else { return 'no' }
    }
    function NonWriterFiles {
        $hits = @()
        foreach ($f in (RosterScanFiles)) {
            if ((NonWriterWindow $f) -ne '') { $hits += (RelPath $f) }
        }
        if ($hits.Count -eq 0) { return '' }
        return (($hits | Sort-Object -Unique -CaseSensitive) -join ' ')
    }
    # Set equality -- BOTH empty must be 'no'. '' -eq '' is true, so the day extraction breaks entirely
    # this assertion would pass vacuously (M37 review minor #4).
    function SetsEqual($a, $b) {
        if ($a -ne '' -and $a -eq $b) { return 'yes' } else { return 'no' }
    }
    # Writer and non-writer rosters must be DISJOINT -- if either extractor grabs the wrong side, the
    # count and set-equality cases still pass but this one catches it.
    function RostersDisjoint($file) {
        $a = RosterSet $file
        $b = NonWriterSet $file
        if ($a -eq '' -or $b -eq '') { return 'no' }
        foreach ($n in ($b -split ' ')) {
            if ((' ' + $a + ' ') -like ('* ' + $n + ' *')) { return 'no' }
        }
        return 'yes'
    }

    Chk "C3: conventions roster holds 6 names"    (RosterCount $CONV)     6
    Chk "C3: published page roster holds 6 names" (RosterCount $CONCEPTS) 6
    Chk "C3: the two rosters are identical" (SetsEqual (RosterSet $CONV) (RosterSet $CONCEPTS)) 'yes'
    Chk "C3: only conventions + published page enumerate" (RosterFiles) 'docs/conventions.md site/docs/concepts.md'

    # The non-writer half is bitten at the same width -- the conventions declaration binds both lists.
    Chk "C3: conventions non-writer roster holds 6 names"    (NonWriterCount $CONV)     6
    Chk "C3: published page non-writer roster holds 6 names" (NonWriterCount $CONCEPTS) 6
    Chk "C3: the two non-writer rosters are identical" (SetsEqual (NonWriterSet $CONV) (NonWriterSet $CONCEPTS)) 'yes'
    Chk "C3: only conventions + published page enumerate non-writers" (NonWriterFiles) 'docs/conventions.md site/docs/concepts.md'
    Chk "C3: conventions writer/non-writer rosters are disjoint"    (RostersDisjoint $CONV)     'yes'
    Chk "C3: published page writer/non-writer rosters are disjoint" (RostersDisjoint $CONCEPTS) 'yes'

    # Negative control -- a non-existent name is in neither roster (same intent as C1's bogus status).
    Chk "C3: roster control -- conventions has no 'phantom-cmd'"    (RosterHas $CONV 'phantom-cmd')     'no'
    Chk "C3: roster control -- published page has no 'phantom-cmd'" (RosterHas $CONCEPTS 'phantom-cmd') 'no'
    Chk "C3: non-writer control -- conventions has no 'phantom-cmd'"    (NonWriterHas $CONV 'phantom-cmd')     'no'
    Chk "C3: non-writer control -- published page has no 'phantom-cmd'" (NonWriterHas $CONCEPTS 'phantom-cmd') 'no'

    # === Part D -- cross-branch collaboration safety (M31) declaration consistency ==========
    # (M31) Same class as Part B/C -- bind the conventions single source and the skill that wires it.
    # The two checks (release coverage / milestone number pre-warning) are prompt discipline, so runtime
    # firing is not harness-enforceable, but the conventions<->skill DECLARATION consistency is. Enforced
    # via ASCII mechanism tokens (git read commands), keeping this source ASCII-only.
    # (D1) release coverage check: 'git diff --name-only' in BOTH conventions and release SKILL;
    # (D2) milestone number pre-warning: 'git log --all' in BOTH conventions and milestone SKILL.
    # (D3/M39) the coverage check's UNCOMMITTED half: 'git status --porcelain' in BOTH conventions and
    # release SKILL. Without it the check sees only the committed diff while release stages the working
    # tree into the tag -- what the check looks at and what actually ships would diverge (the origin of
    # M39). It is a separate token from D1 because D1 alone passes even if scope (2) is dropped whole.

    $REL_SKILL = Join-Path $ROOT 'skills\release\SKILL.md'
    $MS_SKILL  = Join-Path $ROOT 'skills\milestone\SKILL.md'
    $CONV_REL  = Join-Path $ROOT 'docs\conventions-release.md'   # conventions FRAGMENT (M35 split)
    $COV_TOK  = 'git diff --name-only'
    $UNCOMMITTED_TOK = 'git status --porcelain'
    $WARN_TOK = 'git log --all'
    $PRCI_TOK = 'gh pr checks'

    Chk "D1: conventions declares coverage check ($COV_TOK)"      (HasToken $CONV $COV_TOK)      'yes'
    Chk "D1: release SKILL wires coverage check"                  (HasToken $REL_SKILL $COV_TOK) 'yes'
    Chk "D2: conventions declares number pre-warning ($WARN_TOK)" (HasToken $CONV $WARN_TOK)     'yes'
    Chk "D2: milestone SKILL wires number pre-warning"            (HasToken $MS_SKILL $WARN_TOK) 'yes'
    Chk "D3: conventions declares uncommitted scope ($UNCOMMITTED_TOK)" (HasToken $CONV $UNCOMMITTED_TOK)      'yes'
    Chk "D3: release SKILL wires uncommitted scope"                     (HasToken $REL_SKILL $UNCOMMITTED_TOK) 'yes'

    # (D4/M39 review rec.2) the user-facing CANONICAL CATALOG must declare the same scope. M39 fixed the
    # conventions and the skill but left the catalog on the old scope, so the published page (the site
    # includes this body) went stale -- the conventions<->skill binding (D1/D3) could not see it. Binding
    # the consumer doc closes that class (same intent as Part F's role-anchor consumer propagation).
    Chk "D4: canonical catalog declares uncommitted scope" (HasToken $CANON_CMD $UNCOMMITTED_TOK) 'yes'

    # (D5/M40 review rec.1) The `workflow-syntax` axis wiring (the `pr` finalize PR-CI lookup) is the
    # same conventions<->skill class as D1..D4, but M40 added the prose without the binding -- measured:
    # deleting the wiring from the release skill still scored 107/0 green. The conventions single source
    # here is a FRAGMENT (conventions-release.md), so only the bound file differs; the technique is D1's.
    Chk "D5: conventions fragment declares PR CI check ($PRCI_TOK)" (HasToken $CONV_REL $PRCI_TOK)  'yes'
    Chk "D5: release SKILL wires PR CI check"                       (HasToken $REL_SKILL $PRCI_TOK) 'yes'

    # cross control: each mechanism must be ABSENT from the opposite skill (token discriminates).
    Chk "D: control -- milestone SKILL has no coverage token"  (HasToken $MS_SKILL $COV_TOK)  'no'
    Chk "D: control -- milestone SKILL has no uncommitted-scope token" (HasToken $MS_SKILL $UNCOMMITTED_TOK) 'no'
    Chk "D: control -- release SKILL has no number-warn token" (HasToken $REL_SKILL $WARN_TOK) 'no'
    Chk "D: control -- milestone SKILL has no PR CI token"      (HasToken $MS_SKILL $PRCI_TOK) 'no'

    # negative control: a bogus mechanism token must NOT appear in conventions (guard discriminates).
    Chk "D: control -- conventions has no bogus token" (HasToken $CONV 'git diff --bogus-only') 'no'

    # === Part E -- review verification discipline (M32) declaration consistency =============
    # (M32) Same class as Part C/D -- bind the conventions single source to the skill AND template that
    # wire it. Whether the refutation pass is actually dispatched at runtime is prompt discipline and not
    # harness-enforceable, but the conventions <-> skill <-> template DECLARATION consistency is (same
    # split as Part C/D). The tokens are the ASCII spellings decided in conventions "review verification
    # discipline", so this ps1 copy anchors them directly -- no code-point assembly needed (ASCII-only).
    # (E1) refutation pass: 'refutation' in BOTH conventions and review SKILL;
    # (E2) verdict metrics: 'in-review' in conventions + review SKILL + review template;
    # (E3) rework round: 'rework' in conventions + review template + impl template.
    # (E6) precedent class (M36): 'vacuous-pass' in BOTH conventions and review SKILL;
    # (E7) precedent waiver (M36): 'precedent-waiver' in conventions + review SKILL + review template.

    $REV_SKILL  = Join-Path $ROOT 'skills\review\SKILL.md'
    $REV_TPL    = Join-Path $ROOT 'skills\review\template.md'
    $REFUT_TOK    = 'refutation'
    $MEAS_TOK     = 'in-review'
    $REWORK_TOK   = 'rework'
    $REVERIFY_TOK = 're-verify'
    $VACUOUS_TOK  = 'vacuous-pass'
    $WAIVER_TOK   = 'precedent-waiver'

    function InBoth($token, $f1, $f2) {
        foreach ($f in @($f1, $f2)) { if ((HasToken $f $token) -ne 'yes') { return 'no' } }
        return 'yes'
    }

    # (E1) the refutation mechanism is declared in BOTH the convention and the review skill.
    Chk "E1: refutation ($REFUT_TOK) conventions <-> review SKILL" (InBoth $REFUT_TOK $CONV $REV_SKILL) 'yes'

    # (E2) the metrics token is declared in all three (the metrics line needs a slot in the template too).
    Chk "E2: verdict metrics ($MEAS_TOK) in all three files" (InAllThree $MEAS_TOK $CONV $REV_SKILL $REV_TPL) 'yes'

    # (E3) review metrics line and impl overview carry the same rework value -> three-way declaration bind.
    Chk "E3: rework round ($REWORK_TOK) in all three files" (InAllThree $REWORK_TOK $CONV $REV_TPL $IMPL_TPL) 'yes'

    # (E4) metrics-line FORMAT consistency -- token presence anywhere in the file is not enough. During the
    # M32 implementation the three files actually diverged into two spellings of the same fixed line (with
    # and without the '(rework)' ASCII gloss) while E1-E3 all passed, and a human caught it. Bind the ASCII
    # SKELETON of the fixed line ('in-review' and '(rework)' on the SAME single line) to catch that drift --
    # no Korean body text is anchored, so this ps1 copy stays ASCII-only.
    function SameLine($file, $tokA, $tokB) {   # yes if some ONE line holds both tokens
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return 'no' }
        foreach ($line in ($raw -split "`r?`n")) {
            if ($line.Contains($tokA) -and $line.Contains($tokB)) { return 'yes' }
        }
        return 'no'
    }
    foreach ($pair in @(@('conventions', $CONV), @('review SKILL', $REV_SKILL), @('review template', $REV_TPL))) {
        Chk "E4: metrics-line skeleton ($MEAS_TOK...($REWORK_TOK)) in $($pair[0])" (SameLine $pair[1] $MEAS_TOK "($REWORK_TOK)") 'yes'
    }

    # (E5) re-verify rule declaration consistency -- 'in-review' alone cannot anchor this rule: that token
    # also lives in the metrics line (dual use), so DELETING the whole re-verify clause still passes E2
    # (proven on a scratch copy by the M32 review's refutation pass). Bind the dedicated ASCII gloss instead.
    Chk "E5: re-verify ($REVERIFY_TOK) in all three files" (InAllThree $REVERIFY_TOK $CONV $REV_SKILL $REV_TPL) 'yes'

    # (E6) blocking-grade precedent (M36) -- the precedent class name is declared in BOTH the convention
    # (the criterion) and the review skill (the procedure). Same two-way layer as E1's refutation: the
    # report template gets no slot for it, so no duplicate declaration is added needlessly.
    Chk "E6: precedent class ($VACUOUS_TOK) conventions <-> review SKILL" (InBoth $VACUOUS_TOK $CONV $REV_SKILL) 'yes'

    # (E7) precedent waiver (M36) -- the waiver only actually gets recorded if all three carry it:
    # conventions (the duty), review SKILL (the procedure), review template (the record slot). Deleting it
    # from the template ALONE must bite here (same three-way bind as E2/E5).
    Chk "E7: precedent waiver ($WAIVER_TOK) in all three files" (InAllThree $WAIVER_TOK $CONV $REV_SKILL $REV_TPL) 'yes'

    # negative control: a bogus precedent token must NOT appear in conventions (same shape as the bogus
    # refutation token control -- proves this guard discriminates rather than passing vacuously).
    Chk "E: control -- conventions has no bogus precedent token" (HasToken $CONV "$VACUOUS_TOK-bogus") 'no'

    # cross control: refutation is a review asset -> must be ABSENT from the impl template (discriminates).
    Chk "E: control -- impl template has no refutation token" (HasToken $IMPL_TPL $REFUT_TOK) 'no'

    # cross control: the metrics line is a review asset -> the impl template carries only the rework value.
    Chk "E: control -- impl template has no metrics-line skeleton" (SameLine $IMPL_TPL $MEAS_TOK "($REWORK_TOK)") 'no'

    # negative control: a bogus token must NOT appear in conventions (same intent as B1's N+1 absence).
    Chk "E: control -- conventions has no bogus refutation token" (HasToken $CONV "$REFUT_TOK-bogus") 'no'

    # === Part F -- document self-description consistency (M33) ==============
    # (M33) Part B-E enforce drift ACROSS documents declaring one fact; this part enforces what a document
    # says ABOUT ITSELF -- the two layers that had no guard at all.
    # (F2) role-anchor propagation: EXTRACT anchors from the canonical 'role-anchors:' map in
    #      docs/commands.md, then assert (a) the anchor really lives on that command's canonical table row
    #      and (b) every consumer doc (README, site getting-started) that MENTIONS the command also carries
    #      the anchor. Data-driven, so no Korean literal enters this source (ASCII-only rule preserved) --
    #      same shape as the term extraction in tests/site-includes.
    # (F3) controls: zero extracted anchors -> FAIL (empty-pass guard, the M27 positive-control precedent);
    #      map names must be real command skills; a bogus anchor must be absent.
    # (F1) case-count self-consistency: this harness compares its OWN README declaration ('cases: N') with
    #      its OWN actual case count. F1 is itself a case, so F1 runs LAST and compares against
    #      'running total + 1' (the chosen route, restated in the README). Extraction failure is a FAIL,
    #      never a silent skip. Single source: conventions "document self-description consistency".

    $DISC_README = Join-Path $ROOT 'tests\discover\README.md'

    # anchor map extraction -- '<!-- role-anchors: name=token ... -->' on one line.
    function AnchorPairs() {
        $raw = ReadUtf8 $CANON_CMD
        if ($null -eq $raw) { return @() }
        $m = [regex]::Match($raw, 'role-anchors:([^>]*)')
        if (-not $m.Success) { return @() }
        return @($m.Groups[1].Value -split '\s+' | Where-Object { $_ -match '^[a-z-]+=[A-Za-z-]+$' })
    }

    # anchors are matched on letter/hyphen boundaries so a short anchor (gh) cannot hit inside a word.
    function HasAnchor($file, $token) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return 'no' }
        $pat = '(^|[^A-Za-z-])' + [regex]::Escape($token) + '([^A-Za-z-]|$)'
        if ($raw -match $pat) { return 'yes' } else { return 'no' }
    }

    # canonical self-consistency -- the anchor must live on that command's TABLE ROW (line starts with '|').
    function CanonRowHas($name, $token) {
        $raw = ReadUtf8 $CANON_CMD
        if ($null -eq $raw) { return 'no' }
        $namePat = '/tide:' + $name + '([^a-z-]|$)'
        $tokPat  = '(^|[^A-Za-z-])' + [regex]::Escape($token) + '([^A-Za-z-]|$)'
        foreach ($line in ($raw -split "`r?`n")) {
            if ($line.StartsWith('|', [System.StringComparison]::Ordinal) -and ($line -match $namePat) -and ($line -match $tokPat)) { return 'yes' }
        }
        return 'no'
    }

    # consumer propagation -- if the file MENTIONS the command it must carry the anchor (else not a target).
    function ConsumerOk($file, $name, $token) {
        if (-not (Test-Path $file)) { return 'no' }
        if ((HasCommand $file $name) -eq 'yes') { return (HasAnchor $file $token) }
        return 'yes'
    }

    $pairs = AnchorPairs
    foreach ($p in $pairs) {
        $aname = $p.Split('=')[0]; $atok = $p.Split('=')[1]
        Chk "F2: anchor '$atok' on canonical /tide:$aname row" (CanonRowHas $aname $atok)          'yes'
        Chk "F2: README propagation ($aname=$atok, if mentioned)"       (ConsumerOk $README $aname $atok)  'yes'
        Chk "F2: site getting-started propagation ($aname=$atok, if mentioned)" (ConsumerOk $SITE_GS $aname $atok) 'yes'
    }

    # positive control -- with zero anchors extracted the loop above passes vacuously (extraction = FAIL).
    Chk "F3: anchor extraction positive control (>0)" $(if (@($pairs).Count -gt 0) { 'ok' } else { 'no' }) 'ok'

    # map hygiene -- every declared anchor name must be a real command skill (typo / removed command).
    $namesReal = 'yes'
    foreach ($p in $pairs) {
        if (-not (Test-Path (Join-Path $ROOT ('skills\' + $p.Split('=')[0] + '\SKILL.md')))) { $namesReal = 'no' }
    }
    Chk "F3: anchor map names are all real command skills" $namesReal 'yes'

    # negative control -- a bogus anchor must NOT appear in the canonical catalog (same intent as B1 N+1).
    Chk "F3: control -- canonical has no bogus anchor" (HasAnchor $CANON_CMD 'bogusanchor') 'no'

    # === Part G -- cross-reference integrity (M34; generalized to a FILE SET in M35) =====
    # (M34) Part F enforces what a document says ABOUT ITSELF; Part G enforces the REFERENCES BETWEEN
    # documents -- the layer that had no guard at all (two citations really did point at names that do
    # not exist as headings, and nothing caught it). Single source: conventions "cross-reference
    # integrity".
    # (M35) The conventions are no longer ONE file but a DOCUMENT SET (the body plus per-topic
    #      fragments). So this part (1) DISCOVERS the set with the glob 'docs/conventions*.md' (never a
    #      hardcoded list -- adding a fragment must not require editing this runner), (2) keys the
    #      anchors PER FILE, and (3) picks the anchor set to compare against from the conventions file
    #      name(s) that appear ON THE CITATION LINE. Move a section into a fragment without updating the
    #      citation and the guard bites. A line naming two of them passes if EITHER set has the name
    #      (safe side -- never manufacture a false positive). With no fragment present the set is just
    #      the body, so the verdict is identical to the pre-generalization one (regression freeze).
    # (G1) EXTRACT citations (quoted spans on lines that mention a conventions file name) from the
    #      living docs and assert every one exists in THAT FILE's heading set (## / ###, whitespace
    #      removed for comparison).
    # (G2) controls: zero extracted citations or anchors -> FAIL (empty-pass guard); a bogus name must be
    #      absent from the whole set; heading names must be unique ACROSS THE WHOLE SET after
    #      normalization (a split must not put the same name in two files).
    # Data-driven, so no Korean literal enters this source (ASCII-only rule preserved) -- same shape as F2.

    # living docs -- docs/milestones/* and docs/reports/* are historical records and NOT targets
    # (the docs/*.md glob does not descend into subdirectories, so they drop out naturally).
    # NOTE: skip dot-directories AND use -Force on the file listings. Get-ChildItem hides files with
    # the Windows Hidden/System attribute unless -Force is given, while a POSIX glob matches them; the
    # explicit dot-name filter then removes what the glob would NOT match. Both halves keep the two
    # shells scanning the same set.
    # skip dot-directories explicitly: A POSIX glob ('skills/*/*.md') never matches them, but
    # Get-ChildItem -Directory DOES list '.foo' on Windows (a leading dot is not the Hidden attribute),
    # so without this filter the two shells would scan different file sets and could disagree.
    function LivingDocs() {
        $out = @()
        foreach ($d in (Get-ChildItem (Join-Path $ROOT 'skills') -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith('.', [System.StringComparison]::Ordinal) })) {
            $out += @(Get-ChildItem $d.FullName -Filter '*.md' -File -Force -ErrorAction SilentlyContinue |
                    Where-Object { -not $_.Name.StartsWith('.', [System.StringComparison]::Ordinal) } | ForEach-Object { $_.FullName })
        }
        $out += @(Get-ChildItem (Join-Path $ROOT 'docs') -Filter '*.md' -File -Force -ErrorAction SilentlyContinue |
                    Where-Object { -not $_.Name.StartsWith('.', [System.StringComparison]::Ordinal) } | ForEach-Object { $_.FullName })
        $out += @($README)
        $out += @(Get-ChildItem (Join-Path $ROOT 'site\docs') -Filter '*.md' -File -Force -ErrorAction SilentlyContinue |
                    Where-Object { -not $_.Name.StartsWith('.', [System.StringComparison]::Ordinal) } | ForEach-Object { $_.FullName })
        foreach ($d in (Get-ChildItem (Join-Path $ROOT 'tests') -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith('.', [System.StringComparison]::Ordinal) })) {
            $r = Join-Path $d.FullName 'README.md'
            if (Test-Path $r) { $out += @($r) }
        }
        return @($out | Where-Object { Test-Path $_ })
    }

    # conventions DOCUMENT SET -- discovered with the glob 'docs/conventions*.md' (never hardcoded).
    # Match the POSIX glob exactly with ordinal Starts/EndsWith, and sort ORDINAL so this walks the set
    # in the same order as run.sh ('LC_ALL=C sort').
    function ConvFiles() {
        # -Force: without it Get-ChildItem skips files carrying the Windows Hidden/System attribute,
        # while the POSIX glob 'docs/conventions*.md' matches them -- the two shells would then scan
        # different sets. A leading-dot name still cannot pass StartsWith('conventions'), so -Force does
        # not over-match relative to the glob either.
        $fs = @(Get-ChildItem (Join-Path $ROOT 'docs') -File -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name.StartsWith('conventions', [System.StringComparison]::Ordinal) -and
                               $_.Name.EndsWith('.md', [System.StringComparison]::Ordinal) } |
                ForEach-Object { $_.FullName })
        $lst = New-Object 'System.Collections.Generic.List[string]'
        foreach ($f in $fs) { [void]$lst.Add($f) }
        $lst.Sort([System.StringComparer]::Ordinal)
        return @($lst.ToArray())
    }

    # anchor set of ONE conventions file -- ## / ### headings only, spaces removed (so "A - B" and
    # "A-B" compare equal). CR is already gone because the split is on \r?\n.
    function AnchorSetOf($path) {
        $raw = ReadUtf8 $path
        if ($null -eq $raw) { return @() }
        $out = @()
        foreach ($line in ($raw -split "`r?`n")) {
            if ($line -match '^#{2,3} ') { $out += (($line -replace '^#+ ', '') -replace ' ', '') }
        }
        return $out
    }

    # ordinal (case-sensitive) sets so both shells judge identically -- PowerShell's -contains and
    # hashtable keys are case-INsensitive by default, which would diverge from grep -x.
    # $gAnchorSets is parallel to $gConvFiles (one HashSet per file); $gAnchors is the flat list over the
    # WHOLE set, used by the positive control and the set-wide duplicate check.
    $gConvFiles  = @(ConvFiles)
    $gConvBases  = @($gConvFiles | ForEach-Object { Split-Path $_ -Leaf })
    $gAnchorSets = @()
    $gAnchors    = @()
    foreach ($p in $gConvFiles) {
        $s = New-Object 'System.Collections.Generic.HashSet[string]'
        foreach ($a in (AnchorSetOf $p)) { [void]$s.Add($a); $gAnchors += $a }
        $gAnchorSets += ,$s
    }

    # citation candidate lines -- lines naming ANY file of the set; each quoted span is remembered
    # together with the INDEXES of the files named on its line (its owners). Snippet-include directive
    # lines ('8<--') are not citations.
    $gLines      = @()
    $gCites      = @()
    $gCiteOwners = @()
    foreach ($f in (LivingDocs)) {
        $raw = ReadUtf8 $f
        if ($null -eq $raw) { continue }
        foreach ($line in ($raw -split "`r?`n")) {
            $owners = @()
            for ($i = 0; $i -lt $gConvBases.Count; $i++) {
                if ($line.Contains($gConvBases[$i])) { $owners += $i }
            }
            if ($owners.Count -eq 0) { continue }
            if ($line.Contains('8<--')) { continue }
            $gLines += $line
            foreach ($m in [regex]::Matches($line, '"([^"]*)"')) {
                $q = $m.Groups[1].Value
                if ($q -match '[{}]') { continue }        # skeleton placeholder, not a citation
                $q = ($q -replace ' ', '')
                if ($q.Length -eq 0) { continue }         # blank span -- the shell drops it as an empty line
                $gCites      += $q
                $gCiteOwners += ,$owners
            }
        }
    }
    # unterminated quote on a candidate line = the citation wrapped to the next line and would be
    # silently skipped by line-wise extraction (see G3).
    $gOdd = 0
    foreach ($line in $gLines) { if ((([regex]::Matches($line, '"')).Count % 2) -eq 1) { $gOdd++ } }

    # $aset = union over the whole set (bogus-name control); $dset = names appearing in more than one
    # place (uniqueness is a WHOLE-SET rule: a split must not put the same name in two files).
    $aset = New-Object 'System.Collections.Generic.HashSet[string]'
    $dset = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($a in $gAnchors) { if (-not $aset.Add($a)) { [void]$dset.Add($a) } }
    # a citation is OK when it resolves in the anchor set of ANY file named on its line (safe side).
    $gMiss = 0
    for ($i = 0; $i -lt $gCites.Count; $i++) {
        $ok = $false
        foreach ($k in $gCiteOwners[$i]) { if ($gAnchorSets[$k].Contains($gCites[$i])) { $ok = $true } }
        if (-not $ok) { $gMiss++ }
    }

    Chk "G1: every live citation resolves to a real anchor" ([string]$gMiss) '0'
    Chk "G2: citation extraction positive control (>0)" $(if ($gCites.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "G2: anchor extraction positive control (>0)"   $(if ($gAnchors.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "G2: control -- bogus anchor name (bogus-section) absent" $(if ($aset.Contains('bogus-section')) { 'yes' } else { 'no' }) 'no'
    Chk "G2: anchor names unique after normalization" ([string]$dset.Count) '0'
    Chk "G3: citation lines have balanced quotes (no wrapped citation)" ([string]$gOdd) '0'

    # === Part H -- execution-environment axis declaration consistency (M38-T06) =====
    # The convention NAMES each axis of the execution environment (single source: the
    # execution-environment axis section of docs/conventions.md) and records what enforces it.
    # What this part bites is EXACTLY five things: (1) each declared axis name really occurs in a
    # ROW of the convention's table, (2) the axis-name SET matches the one declared in
    # tests/discover/README.md (same set-equality technique as Part C), (3) each `job:<name>` token in
    # the table really exists as a job key in .github/workflows/tests.yml, (4) that token sits in a
    # row carrying a DECLARED axis (an orphan token in an undeclared row FAILs), and (5) conversely,
    # every job that really EXISTS in the workflow is either REGISTERED by some axis row's `job:`
    # token or DECLARED EXEMPT (coverage -- registration is not opt-in).
    # (M39) The mapping's single source moved from the `env-axis-ci-jobs:` line to the table's
    # `job:<name>` tokens -- two declaration sites became one. That changed (4)'s meaning: it used to
    # ask "is the mapped job also in the table row" which, now that the table IS the source, would be
    # a TAUTOLOGY (a vacuous pass); it now asks "is the table's job token in a DECLARED axis row".
    # It does not claim more. THREE things are not asked by any machine: (a) whether an enforcement
    # cell that names NO CI job (the runner's own probe, "only a real push" + the `pr` finalize CI
    # lookup) is still true; (b) whether the REST of a job-naming cell's prose ("3 OS", "matrix")
    # matches reality; (c) PROSE in an enforcement cell claiming a job that does not exist (below).
    # That layer is the human review's; the convention's "what the machine does not ask" notice is
    # the single source.
    # (M40) The former fourth item -- an UNDECLARED table row -- is closed. The `axis:` notation
    # (H14..H16) plus DATA ROW COUNT == NOTATION COUNT (H17) lets axes be counted from the TABLE side
    # too, so the comparison is bidirectional. Before deleting the item, three attacks were measured
    # in both shells: an undeclared row WITH a notation (H15 fails), a pure-prose row with NO notation
    # (H17b fails), and a declared axis whose notation is removed (H2/H15/H17b fail). Shrinking the
    # notice on the strength of "the notation exists" alone would itself be the `vacuous-pass` class.
    # What `job:` closed AND did not close: enforcement cells used to be prose, so a NON-EXISTENT name
    # written as if it were a job never reached the check (no machine can tell whether an arbitrary
    # backticked token is a job reference -- the M38 review measured this with `nowhere`). The `job:`
    # prefix removes that ambiguity for references it MARKS, and (3) then bites their existence.
    # PROSE claims survive untouched -- measured by the M39 review in both shells: keeping the token
    # and appending "CI `nowhere` also enforces" stays green, and replacing a token-less axis cell with
    # "CI `nowhere` enforces" stays green. The DEFINITION of what counts as a job reference changed;
    # the misleading surface did not disappear. That is why (c) stays in the notice.
    # The M38 review measured the overclaim TWICE: before (3)/(4), deleting the `posix` job outright
    # and leaving the table untouched still scored 90/0 green; before (5), a DECLARED but unmapped
    # axis naming a real job escaped the check. That is why (3)(4)(5) exist.
    # Axis and job names are ASCII co-terms, so this is data-driven like Part F's role anchors --
    # no Korean literal in the source.
    function EnvAxes($file) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return '' }
        $line = ($raw -split "`r?`n" | Where-Object { $_.Contains('env-axes:') } | Select-Object -First 1)
        if ($null -eq $line) { return '' }
        $tail = $line.Substring($line.IndexOf('env-axes:') + 9)
        $cut = $tail.IndexOf('-->')
        if ($cut -ge 0) { $tail = $tail.Substring(0, $cut) }
        $names = @($tail -split '\s+' | Where-Object { $_ -match '^[a-z][a-z-]*$' })
        return (($names | Sort-Object -CaseSensitive) -join ' ')
    }
    $convAxes = EnvAxes $CONV
    $readAxes = EnvAxes $DISC_README
    $nAxes = @($convAxes -split ' ' | Where-Object { $_ -ne '' }).Count

    # (H14..H16 / M40) `axis:<name>` -- the RESOLVABLE notation for axis names. Before it, every check
    # started from the `env-axes:` declaration, so a table row NOT in the declaration escaped all of
    # them (M38 measured it: an undeclared `ghost-axis` row naming a real job stayed green). Counting
    # axes from the TABLE side too makes the comparison BIDIRECTIONAL -- declared-but-unwritten and
    # written-but-undeclared both FAIL. Same shape as `job:`, so the extractor is the same shape too.
    function TableAxisTokens($file) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return '' }
        $rows = @(($raw -split "`r?`n") | Where-Object { $_.StartsWith('|', [System.StringComparison]::Ordinal) })
        $tok = @()
        foreach ($row in $rows) {
            foreach ($m in [regex]::Matches($row, 'axis:[a-z][a-z-]*')) { $tok += $m.Value.Substring(5) }
        }
        return ((@($tok | Sort-Object -CaseSensitive -Unique)) -join ' ')
    }
    $convAxisTokens = TableAxisTokens $CONV
    $nAxisTok = @($convAxisTokens -split ' ' | Where-Object { $_ -ne '' }).Count

    # (H17) Set equality alone cannot see a row carrying NO notation -- it contributes nothing to the
    # set and passes quietly (that is exactly the "prose inside the axis table" seat). So the DATA ROW
    # COUNT is compared with the NOTATION COUNT. The table's range is anchored on the `env-axes:`
    # declaration line (the first markdown table after it): anchoring on the Korean header would break
    # this file's ASCII-only source discipline, so an ASCII declaration line is the anchor instead.
    function AxisTableDataRows($file) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return @() }
        $out = @(); $f = 0
        foreach ($line in ($raw -split "`r?`n")) {
            $isRow = $line.StartsWith('|', [System.StringComparison]::Ordinal)
            if ($f -eq 0) { if ($line.Contains('env-axes:')) { $f = 1 }; continue }
            if ($f -eq 1) { if ($isRow) { $f = 2 }; continue }
            if ($f -eq 2) { if ($isRow) { $f = 3 }; continue }
            if ($f -eq 3) { if ($isRow) { $out += $line; continue } else { break } }
        }
        return $out
    }
    $axisDataRows = @(AxisTableDataRows $CONV)
    $nAxisRows = $axisDataRows.Count
    $nAxisRowTok = @($axisDataRows | Where-Object { $_ -match 'axis:[a-z]' }).Count

    # (H2) every declared axis must occur in a TABLE ROW (line starting with '|') of the convention --
    # declaring an axis without wiring it into the table is the "claims enforcement it does not have"
    # class this milestone exists to remove.
    $axisRowMiss = 0
    $convLines = @((ReadUtf8 $CONV) -split "`r?`n")
    foreach ($a in @($convAxes -split ' ' | Where-Object { $_ -ne '' })) {
        $needle = '`axis:' + $a + '`'
        $hit = @($convLines | Where-Object { $_.StartsWith('|', [System.StringComparison]::Ordinal) -and $_.Contains($needle) }).Count
        if ($hit -eq 0) { $axisRowMiss++ }
    }
    function HasAxis($set, $name) {
        if ((" $set " ).Contains(" $name ")) { return 'yes' } else { return 'no' }
    }

    # (H6..H9) Rows whose enforcement cell points at a CI JOB are pinned down to the job's existence.
    # (M39) The mapping's single source is the TABLE ROW's `job:<name>` tokens (no separate line); the
    # job NAMES are DISCOVERED from the workflow's `jobs:` block (no hardcoded roster). H8 checks the
    # token sits in a DECLARED axis row, closing the opposite drift (hiding a token in an undeclared row).
    $axisRows = @($convLines | Where-Object { $_.StartsWith('|', [System.StringComparison]::Ordinal) })
    function RowJobTokens($row) {
        return @([regex]::Matches($row, 'job:[a-z][a-z0-9-]*') | ForEach-Object { $_.Value.Substring(4) })
    }
    function RowAxisNames($row, $axes) {
        return @($axes | Where-Object { $row.Contains('`axis:' + $_ + '`') })
    }
    function EnvAxisJobs($rows, $axes) {
        $pairs = @()
        foreach ($row in $rows) {
            if (-not $row.Contains('job:')) { continue }
            foreach ($j in (RowJobTokens $row)) {
                foreach ($a in (RowAxisNames $row $axes)) { $pairs += ($a + '=' + $j) }
            }
        }
        return ((@($pairs | Sort-Object -CaseSensitive -Unique)) -join ' ')
    }
    function EnvExemptJobs($file) {
        # jobs deliberately declared NOT to be environment axes (e.g. the repo-consistency `pairing`
        # job). Exemption is a DECLARATION, not silence -- adding a CI job forces the axis/exempt call.
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return '' }
        $line = ($raw -split "`r?`n" | Where-Object { $_.Contains('env-axis-exempt-jobs:') } | Select-Object -First 1)
        if ($null -eq $line) { return '' }
        $tail = $line.Substring($line.IndexOf('env-axis-exempt-jobs:') + 21)
        $cut = $tail.IndexOf('-->')
        if ($cut -ge 0) { $tail = $tail.Substring(0, $cut) }
        $names = @($tail -split '\s+' | Where-Object { $_ -match '^[a-z][a-z0-9-]*$' })
        return (($names | Sort-Object -CaseSensitive) -join ' ')
    }
    function CiJobNames($file) {
        # job keys = 2-space-indented keys INSIDE the `jobs:` block (so the keys under `on:` -- push,
        # pull_request, workflow_dispatch -- are not mistaken for jobs).
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return '' }
        $out = @(); $inJobs = $false
        foreach ($line in ($raw -split "`r?`n")) {
            if ($line -match '^jobs:') { $inJobs = $true; continue }
            if ($inJobs -and $line -match '^[A-Za-z]') { $inJobs = $false }
            if ($inJobs -and $line -match '^  ([a-z][a-z0-9-]*):[ \t]*$') { $out += $matches[1] }
        }
        return (($out | Sort-Object -CaseSensitive) -join ' ')
    }
    $WF = Join-Path $ROOT '.github\workflows\tests.yml'
    $axesList = @($convAxes -split ' ' | Where-Object { $_ -ne '' })
    $axisJobs = EnvAxisJobs $axisRows $axesList
    $ciJobs = CiJobNames $WF
    $exemptJobs = EnvExemptJobs $CONV
    $nAxisJobs = @($axisJobs -split ' ' | Where-Object { $_ -ne '' }).Count

    $axisJobMiss = 0
    foreach ($pair in @($axisJobs -split ' ' | Where-Object { $_ -ne '' })) {
        $j = $pair.Substring($pair.IndexOf('=') + 1)
        if ((HasAxis $ciJobs $j) -ne 'yes') { $axisJobMiss++ }
    }

    # (H8) orphan `job:` tokens -- a token written in a row that carries no DECLARED axis.
    $jobTokenOrphan = 0
    foreach ($row in $axisRows) {
        if (-not $row.Contains('job:')) { continue }
        if ((RowAxisNames $row $axesList).Count -eq 0) { $jobTokenOrphan++ }
    }

    # (H12) declared axes carrying NO `job:` token (non-CI enforcement / unenforced) -- absence of a
    # token is the honest notation for "no CI job enforces this", so that path must stay alive.
    $noJobAxes = 0
    foreach ($a in $axesList) {
        if (-not (" $axisJobs ").Contains(" $a=")) { $noJobAxes++ }
    }

    # (H13) a stale exemption (job deleted or renamed while the declaration lingers) must FAIL.
    $exemptJobMiss = 0
    foreach ($j in @($exemptJobs -split ' ' | Where-Object { $_ -ne '' })) {
        if ((HasAxis $ciJobs $j) -ne 'yes') { $exemptJobMiss++ }
    }

    Chk "H1: axis-name extraction positive control (>0)" $(if ($nAxes -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "H2: every declared axis has a convention table row" ([string]$axisRowMiss) '0'
    Chk "H3: axis-name sets equal (conventions vs discover README)" $(if ($convAxes -ne '' -and $convAxes -eq $readAxes) { 'yes' } else { 'no' }) 'yes'
    Chk "H4: control -- bogus axis name (bogus-axis) absent in conventions" (HasAxis $convAxes 'bogus-axis') 'no'
    Chk "H5: control -- bogus axis name (bogus-axis) absent in README" (HasAxis $readAxes 'bogus-axis') 'no'
    # (H10/H11) COVERAGE -- registration is not opt-in. Every job DISCOVERED in the workflow must be
    # registered by some axis row's `job:` token, or declared exempt; otherwise simply staying out of
    # the table buys an exemption from H7/H8 (the side door the M38 review opened by measurement:
    # an unmapped axis naming a nonexistent job still scored 94/0). Nothing is hardcoded -- both the
    # job names and the axis names are discovered.
    $coverHits = 0
    $coverMiss = 0
    foreach ($j in @($ciJobs -split ' ' | Where-Object { $_ -ne '' })) {
        if ((" $axisJobs ").Contains("=$j ")) { $coverHits++; continue }
        if ((" $exemptJobs ").Contains(" $j ")) { continue }
        $coverMiss++
    }

    Chk "H6: table job: token extraction positive control (>0)" $(if ($nAxisJobs -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "H7: every job named by the table exists in the workflow" ([string]$axisJobMiss) '0'
    Chk "H8: every job: token sits in a declared axis row (orphans 0)" ([string]$jobTokenOrphan) '0'
    Chk "H9: control -- bogus job name (bogus-job) absent in workflow" (HasAxis $ciJobs 'bogus-job') 'no'
    Chk "H10: coverage scan positive control (>0)" $(if ($coverHits -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "H11: every workflow job is registered by an axis row or declared exempt" ([string]$coverMiss) '0'
    Chk "H12: declared axes without a job: token exist, positive control (>0)" $(if ($noJobAxes -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "H13: every exempt-declared job exists in the workflow" ([string]$exemptJobMiss) '0'
    # (H14..H16 / M40) `axis:` notation -- extraction positive control + BIDIRECTIONAL set equality.
    # One direction alone is half the job: declared-but-missing-row is already H2's, but a token that
    # exists WITHOUT a declaration (an undeclared row) is caught here for the first time.
    Chk "H14: axis: notation extraction positive control (>0)" $(if ($nAxisTok -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "H15: axis: token set == env-axes declaration set" $(if ($convAxisTokens -ne '' -and $convAxisTokens -eq $convAxes) { 'yes' } else { 'no' }) 'yes'
    Chk "H16: control -- bogus axis notation (bogus-axis) absent in table" (HasAxis $convAxisTokens 'bogus-axis') 'no'
    # (H17) A data row without a notation is prose inside the table. Row count must equal notation
    # count; the row-count positive control keeps 0==0 from passing vacuously.
    Chk "H17a: axis table data-row extraction positive control (>0)" $(if ($nAxisRows -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "H17b: axis table data-row count == axis: notation count" $(if ($nAxisRows -eq $nAxisRowTok) { 'yes' } else { 'no' }) 'yes'

    function DeclaredCases() {
        # FIRST match, deliberately -- the sh side now pins the same end (M38 review minor 4: sed's
        # greedy leading `.*` took the LAST `cases:` on a line while .NET takes the FIRST).
        $raw = ReadUtf8 $DISC_README
        if ($null -eq $raw) { return '' }
        $m = [regex]::Match($raw, 'cases:[^0-9\r\n]*([0-9]+)')
        if ($m.Success) { return $m.Groups[1].Value } else { return '' }
    }

    # (F1b) per-part breakdown sums to the declared total -- F1 only checks the TOTAL. Bumping the total
    # while leaving the breakdown ('Part A 7 + Part B 14 + ...') stale splits the same line silently (one
    # layer below the self-description drift F1 catches). The breakdown is an ASCII skeleton, so both
    # shells sum it identically. Scope the sum to the DECLARATION LINE: scanning the whole file also
    # picks up the same skeleton quoted in the README prose (that really happened in review: 83 vs 62).
    function PartSum() {
        $raw = ReadUtf8 $DISC_README
        if ($null -eq $raw) { return '' }
        $line = ($raw -split "`r?`n" | Where-Object { $_.Contains('cases:') } | Select-Object -First 1)
        if ($null -eq $line) { return '' }
        $s = 0
        foreach ($m in [regex]::Matches($line, 'Part [A-Z] ([0-9]+)')) { $s += [int]$m.Groups[1].Value }
        return [string]$s
    }
    Chk "F1b: per-part breakdown sums to declared total" (PartSum) (DeclaredCases)

    # (F1) LAST case -- own README declaration ('cases: N') vs actual case count (running total + this one).
    Chk "F1: README cases declaration == actual case count" (DeclaredCases) ([string]($script:pass + $script:fail + 1))

    Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail) (actual command skills N=$N) [runtime: PowerShell $($PSVersionTable.PSVersion) $($PSVersionTable.PSEdition)]"
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
Write-Host "# discover detection threshold (>=2->hint / <2->none / single-repo->none / hidden-not-counted) + single-source freeze (B1 count / B2 site shell / B3 catalog completeness, canonical=docs/commands.md) + declaration consistency (C1 four statuses x three files + absence control / C2 baseline x three templates / C3 phase roster both lists (writer + non-writer) conventions<->published page set equality, sole enumerator, disjointness, negative control / D cross-branch coverage (committed-diff + uncommitted-scope tokens; conventions<->skill<->canonical catalog)+number-warn conventions<->skill + PR-CI-check fragment<->skill / E review verification discipline refutation+metrics+rework conventions<->skill<->template plus metrics-line skeleton format plus re-verify declaration plus cross and negative controls / F document self-description = role-anchor extraction, canonical-row presence, consumer propagation plus case-count self-consistency / G cross-reference integrity = citation extraction vs real anchors plus empty-extraction, name-uniqueness and wrapped-citation controls / H execution-environment axis declaration = axis-name extraction, convention table row, set equality, table job: tokens exist in the workflow and sit in declared axis rows (orphans 0), coverage (every real job registered or declared exempt), exemption freshness, no-token axis control, axis: notation bidirectional equality, data-row count, negative controls -- cells naming no CI job, and the rest of a job-naming cell's prose, are the human review's layer, not asked here) confirmed"
exit 0
