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

# M42-T03: the verdict is pinned to ORDINAL. PowerShell's `-eq` on strings is CULTURE comparison
# (measured: 'A'+U+030A -eq U+00C5 is True, and so is -ceq -- `-ceq` is case-SENSITIVE but still
# culture-aware, so it is NOT an ordinal substitute), while the .sh twin's `[ "$got" = "$want" ]` is
# byte-exact. Every assertion in this file flows through here, so a case-only or
# canonically-equivalent difference between got and want would pass here and fail there.
# The [string] casts also close a second hazard: with an ARRAY $got, `-eq` returns the FILTERED
# SUBARRAY and a non-empty one is truthy -- a vacuous pass.
function Chk($desc, $got, $want) {
    if ([string]::Equals([string]$got, [string]$want, [System.StringComparison]::Ordinal)) { $script:pass++; Write-Host ("PASS  {0,-56} ({1})" -f $desc, $got) }
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
    # Ordinal sort + dedupe. Sort-Object -CaseSensitive is CULTURE-aware, not ordinal: it orders
    # 'docs/...' before 'README.md' (letter first, case second) while run.sh's `LC_ALL=C sort` is
    # byte-ordinal and puts 'README.md' first. The two copies must mean the same thing, so this helper
    # pins the ps1 side to ordinal -- the same fix M40 applied when a missing LC_ALL=C split the two
    # shells on BSD. It was latent until C-4 compared a list mixing upper- and lower-case initials.
    function OrdinalSortUnique($items) {
        $set = New-Object 'System.Collections.Generic.SortedSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($it in $items) { [void]$set.Add([string]$it) }
        return @($set)
    }
    # (M42-T03) Same ordinal pin, DUPLICATES PRESERVED -- the sibling of the above for the seats whose
    # .sh twin is `LC_ALL=C sort` WITHOUT `-u` (Part H's env-axes / exempt-jobs / ci-job-names). Folding
    # those through OrdinalSortUnique instead would silently swallow a duplicated declaration that the
    # shell twin still reports, i.e. it would make the two shells disagree -- the exact failure this
    # audit exists to remove. Same List+Ordinal idiom ConvFiles already uses below.
    function OrdinalSort($items) {
        $lst = New-Object 'System.Collections.Generic.List[string]'
        foreach ($it in $items) { [void]$lst.Add([string]$it) }
        $lst.Sort([System.StringComparer]::Ordinal)
        return @($lst.ToArray())
    }
    function RosterSet($file) {
        $ln = RosterLine $file
        if ($ln -eq '') { return '' }
        $names = @()
        foreach ($m in [regex]::Matches($ln, '`([a-z][a-z-]*)`')) { $names += $m.Groups[1].Value }
        if ($names.Count -eq 0) { return '' }
        return ((OrdinalSortUnique $names) -join ' ')
    }
    function RosterCount($file) {
        $s = RosterSet $file
        if ($s -eq '') { return 0 }
        return ($s -split ' ').Count
    }
    # M42-T03: membership is pinned to ORDINAL. `-like` is culture-aware AND case-insensitive, while
    # the .sh twin is `case " $(roster_set) " in *" $2 "*)` -- byte-exact. String.Contains(string) is
    # ordinal by definition, so it says exactly what the shell twin says. Same change in
    # NonWriterHas / StableHas / RostersDisjoint below (all four are the same idiom).
    function RosterHas($file, $name) {
        if ((' ' + (RosterSet $file) + ' ').Contains(' ' + $name + ' ')) { return 'yes' } else { return 'no' }
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
        return ((OrdinalSortUnique $hits) -join ' ')
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
        return ((OrdinalSortUnique $names) -join ' ')
    }
    function NonWriterCount($file) {
        $s = NonWriterSet $file
        if ($s -eq '') { return 0 }
        return ($s -split ' ').Count
    }
    function NonWriterHas($file, $name) {
        if ((' ' + (NonWriterSet $file) + ' ').Contains(' ' + $name + ' ')) { return 'yes' } else { return 'no' }
    }
    function NonWriterFiles {
        $hits = @()
        foreach ($f in (RosterScanFiles)) {
            if ((NonWriterWindow $f) -ne '') { $hits += (RelPath $f) }
        }
        if ($hits.Count -eq 0) { return '' }
        return ((OrdinalSortUnique $hits) -join ' ')
    }
    # Set equality -- BOTH empty must be 'no'. '' -eq '' is true, so the day extraction breaks entirely
    # this assertion would pass vacuously (M37 review minor #4).
    # (M42-T03) the equality itself is ORDINAL -- culture `-eq` would call two sets equal that the .sh
    # twin's `[ "$1" = "$2" ]` calls different. The `-ne ''` emptiness guard is left as-is: only a
    # string made purely of culture-ignorable characters can equal '', and these sets are built from
    # `[a-z][a-z-]*` tokens joined by spaces, so that class is unreachable here.
    function SetsEqual($a, $b) {
        if ($a -ne '' -and [string]::Equals($a, $b, [System.StringComparison]::Ordinal)) { return 'yes' } else { return 'no' }
    }
    # Writer and non-writer rosters must be DISJOINT -- if either extractor grabs the wrong side, the
    # count and set-equality cases still pass but this one catches it.
    function RostersDisjoint($file) {
        $a = RosterSet $file
        $b = NonWriterSet $file
        if ($a -eq '' -or $b -eq '') { return 'no' }
        foreach ($n in ($b -split ' ')) {
            if ((' ' + $a + ' ').Contains(' ' + $n + ' ')) { return 'no' }
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

    # (C4) 2.0 stable command ROSTER (M41) -- same class as C-3, so it lives in this part instead of a
    # new one. The conventions section "2.0 stability" fixes the roster's enumerators at TWO files
    # (conventions + README); every other living document points at that section instead of restating
    # the names. This case enforces that declaration.
    #   "12 commands" and "11 commands" are DIFFERENT FACTS -- the former is the actual count of
    #   skills/*/SKILL.md files (B1 counts and compares it), the latter is a FROZEN DECLARATION that no
    #   filesystem can count, so it is only enforceable by roster comparison. That is why this cannot be
    #   bolted onto B1 and needs its own extractor.
    #   Extraction unit = window (max 4 lines): the shortest run of consecutive lines holding all eleven
    #   names. Measured spans are conventions 3 lines / README 1 line; the cap is 4, same as C-3 -- go
    #   past it and the window is not found, so the count case fails loudly (that cap IS the enforcement
    #   boundary and run.sh uses the same value).
    #   Needles include the CLOSING backtick so that `/tide:fleet` cannot match inside
    #   `/tide:fleet-cycle` (same reason B3 demands boundaries).
    #   /tide:debug is NOT in the frozen set -- if it drifts into the window the count becomes 12 and
    #   this fails. Promotion is a major-version decision, and paying for it in conventions + README +
    #   this runner at the same time is the intended cost.
    $STABLE_NEEDLES = @('`/tide:kickoff`','`/tide:milestone`','`/tide:impl`','`/tide:review`',
                        '`/tide:cycle`','`/tide:release`','`/tide:retro`','`/tide:status`',
                        '`/tide:fleet`','`/tide:fleet-cycle`','`/tide:fleet-verify`')
    function StableWindow($file) {
        $raw = ReadUtf8 $file
        if ($null -eq $raw) { return '' }
        foreach ($n in $STABLE_NEEDLES) { if (-not $raw.Contains($n)) { return '' } }
        $L = @($raw -split "`r?`n")
        $WMAX = 4
        for ($w = 1; $w -le $WMAX; $w++) {
            for ($i = 0; ($i + $w) -le $L.Count; $i++) {
                $s = ($L[$i..($i + $w - 1)] -join "`n")
                $ok = $true
                foreach ($n in $STABLE_NEEDLES) { if (-not $s.Contains($n)) { $ok = $false; break } }
                if ($ok) { return $s }
            }
        }
        return ''
    }
    function StableSet($file) {
        $win = StableWindow $file
        if ($win -eq '') { return '' }
        $names = @()
        foreach ($m in [regex]::Matches($win, '`/tide:([a-z][a-z-]*)`')) { $names += $m.Groups[1].Value }
        if ($names.Count -eq 0) { return '' }
        return ((OrdinalSortUnique $names) -join ' ')
    }
    function StableCount($file) {
        $s = StableSet $file
        if ($s -eq '') { return 0 }
        return ($s -split ' ').Count
    }
    function StableHas($file, $name) {
        if ((' ' + (StableSet $file) + ' ').Contains(' ' + $name + ' ')) { return 'yes' } else { return 'no' }
    }
    function StableFiles {
        $hits = @()
        foreach ($f in (RosterScanFiles)) {
            if ((StableWindow $f) -ne '') { $hits += (RelPath $f) }
        }
        if ($hits.Count -eq 0) { return '' }
        return ((OrdinalSortUnique $hits) -join ' ')
    }

    Chk "C4: conventions stable roster holds 11 names" (StableCount $CONV)   11
    Chk "C4: README stable roster holds 11 names"      (StableCount $README) 11
    Chk "C4: the two stable rosters are identical" (SetsEqual (StableSet $CONV) (StableSet $README)) 'yes'
    Chk "C4: only conventions + README enumerate the stable roster" (StableFiles) 'README.md docs/conventions.md'
    Chk "C4: stable control -- conventions has no 'phantom-stable'" (StableHas $CONV 'phantom-stable')   'no'
    Chk "C4: stable control -- README has no 'phantom-stable'"      (StableHas $README 'phantom-stable') 'no'

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

    # (D6/D7/M46) The two MATCHING axes of the coverage check, bound conventions<->skill. D1 (scope 1)
    # and D3 (scope 2) anchor WHAT IS COLLECTED; these anchor HOW THE COLLECTED SET IS COMPARED --
    # fixing only one side makes the check narrower or wider than the conventions, and D1/D3 cannot see
    # that split because both only look at collection tokens.
    # (D6) brace expansion: without it a legitimately declared file shows up as uncovered (M46 measured:
    # all 7 uncovered entries in the v2.18.0 range were this form; 0 after expanding).
    # (D7) reverse declared-set check: files the impl report's change-file table declares but that were
    # not actually changed. The boundary (do NOT widen to report-wide prose) lives in the same section
    # (M46 measured 90% false positives for the prose axis).
    # Single source: conventions "release coverage check" section. Tokens are ASCII, matching this
    # runner's ASCII-only rule.
    $BRACE_TOK = 'brace-expansion'
    $DECL_TOK  = 'declared-change-set'

    Chk "D6: conventions declares brace expansion ($BRACE_TOK)" (HasToken $CONV $BRACE_TOK)      'yes'
    Chk "D6: release SKILL wires brace expansion"               (HasToken $REL_SKILL $BRACE_TOK) 'yes'
    Chk "D7: conventions declares reverse check ($DECL_TOK)"    (HasToken $CONV $DECL_TOK)       'yes'
    Chk "D7: release SKILL wires reverse check"                 (HasToken $REL_SKILL $DECL_TOK)  'yes'

    # cross control: each mechanism must be ABSENT from the opposite skill (token discriminates).
    Chk "D: control -- milestone SKILL has no coverage token"  (HasToken $MS_SKILL $COV_TOK)  'no'
    Chk "D: control -- milestone SKILL has no uncommitted-scope token" (HasToken $MS_SKILL $UNCOMMITTED_TOK) 'no'
    Chk "D: control -- release SKILL has no number-warn token" (HasToken $REL_SKILL $WARN_TOK) 'no'
    Chk "D: control -- milestone SKILL has no PR CI token"      (HasToken $MS_SKILL $PRCI_TOK) 'no'
    Chk "D: control -- milestone SKILL has no brace-expansion token" (HasToken $MS_SKILL $BRACE_TOK) 'no'
    Chk "D: control -- milestone SKILL has no declared-set token"    (HasToken $MS_SKILL $DECL_TOK)  'no'

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

    # (E8/E9 -- M44) The two rules M43 added to this section carried NO ASCII gloss, so this part had
    # nothing to bind and the three restatements that flatly CONTRADICTED the exit condition stayed green
    # (M43 review issue 1). M44-T01 measured that mechanism; the glosses now exist, so bind them. Layer
    # choice follows the existing rule: a rule that needs a RECORD SLOT in the report binds three files,
    # one that is only criterion+procedure binds two.
    $RESIDUAL_TOK = 'residual-risk-acceptance'
    $REACH_TOK = 'reachability-weighting'

    # (E8) the exit condition leaves an acceptance-rationale block in the review REPORT -> three-way bind
    # (same layer as E7: deleting it from the template ALONE must bite here).
    Chk "E8: exit condition ($RESIDUAL_TOK) in all three files" (InAllThree $RESIDUAL_TOK $CONV $REV_SKILL $REV_TPL) 'yes'

    # (E9) reachability weighting is grading RATIONALE -> criterion (conventions) + procedure (skill) only.
    # A template slot would add a duplicate declaration for nothing (same reasoning as E6).
    Chk "E9: reachability weighting ($REACH_TOK) conventions <-> review SKILL" (InBoth $REACH_TOK $CONV $REV_SKILL) 'yes'

    # (E10 / M46) consecutive-fallback metric. The value is a SLOT written into the review report's
    # metrics line, so it binds in three places like E8/E3 (conventions = definition, skill = procedure,
    # template = recording slot). Without an ASCII term the field could be deleted and stay green, so
    # this follows the binding rule M44 established. E4 already guards the metrics-line skeleton itself;
    # E10 guards the presence of the NEW FIELD.
    $STREAK_TOK = 'fallback-streak'
    Chk "E10: fallback streak ($STREAK_TOK) present in all three files" (InAllThree $STREAK_TOK $CONV $REV_SKILL $REV_TPL) 'yes'
    Chk "E10: metrics-line skeleton carries streak field (conventions)" (SameLine $CONV $MEAS_TOK "($STREAK_TOK)") 'yes'
    Chk "E10: metrics-line skeleton carries streak field (template)"    (SameLine $REV_TPL $MEAS_TOK "($STREAK_TOK)") 'yes'

    # negative control: a bogus exit-condition token must NOT appear in conventions (same shape as the
    # bogus precedent token control below -- proves this new bind discriminates).
    Chk "E: control -- conventions has no bogus exit-condition token" (HasToken $CONV "$RESIDUAL_TOK-bogus") 'no'

    # negative control: a bogus precedent token must NOT appear in conventions (same shape as the bogus
    # refutation token control -- proves this guard discriminates rather than passing vacuously).
    Chk "E: control -- conventions has no bogus precedent token" (HasToken $CONV "$VACUOUS_TOK-bogus") 'no'

    # cross control: refutation is a review asset -> must be ABSENT from the impl template (discriminates).
    Chk "E: control -- impl template has no refutation token" (HasToken $IMPL_TPL $REFUT_TOK) 'no'

    # cross control: the metrics line is a review asset -> the impl template carries only the rework value.
    Chk "E: control -- impl template has no metrics-line skeleton" (SameLine $IMPL_TPL $MEAS_TOK "($REWORK_TOK)") 'no'

    # negative control: a bogus streak token must NOT appear in conventions (same shape as E8's control).
    Chk "E: control -- conventions has no bogus streak token" (HasToken $CONV "$STREAK_TOK-bogus") 'no'

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
    # Comparison is ORDINAL here: HashSet[string]'s default comparer is ordinal, i.e. byte-exact.
    # The .sh twin must say the same thing with `LC_ALL=C` on both `sort` and `uniq` -- without it the
    # comparison becomes collation-based and the two shells stop meaning the same thing. That was a
    # real divergence: GNU platforms happened to agree anyway, and the BSD (macOS) leg reported 3
    # duplicates where every GNU environment reported 0 (M40, caught by this milestone's own new leg).
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
    # On failure, NAME the duplicates. A counting assertion goes red without saying why -- that is
    # exactly what stopped M40 from reproducing the BSD divergence locally, and the .sh twin prints
    # them for the same reason. (A missing/empty anchor file cannot pass vacuously here: the anchor
    # extraction positive control above fails first.)
    if ($dset.Count -ne 0) { Write-Host ("  -> duplicate anchors: " + (($dset | Sort-Object) -join ' ')) }   # locale-exempt: diagnostic-only (display order, never a verdict -- see M41 follow-up 11)
    Chk "G2: anchor names unique after normalization" ([string]$dset.Count) '0'
    Chk "G3: citation lines have balanced quotes (no wrapped citation)" ([string]$gOdd) '0'

    # (G4) SELF-references inside one file are enforced too (M41). M34 created cross-reference integrity
    # and left this layer outside the guard ("the skeleton carries no filename -- human review"), and it
    # stayed there for SIX cycles.
    # SCOPE IS LivingDocs, the same as G1. Looking only at the conventions set leaves the layer the
    # convention calls "closed" wide open in skills/, README.md and tests/*/README.md -- that is exactly
    # what got M41 round 1 blocked (measured: a broken self-reference planted outside conventions stayed
    # green).
    # Resolution is against THAT FILE'S OWN anchors -- a self-reference points at its own file by
    # definition, so comparing against the whole set would pass a reference aimed at another file (round
    # 1's safe-side choice turns into over-permission once the scope widens).
    # Four narrowing markers, all chosen from measurement (55 candidates across LivingDocs):
    #   (1) shaped '"<name>" <jeol>'. WITHOUT this marker it cannot be closed -- drop the trailing word
    #       and the conventions set alone goes 47 -> 165 candidates, 100+ of them ordinary quoted prose.
    #   (2) NO backticked file path -- that is a citation to another file, not a self-reference.
    #   (3) NO conventions filename on the line -- the markdown-link form is G1's job; without this
    #       marker those 4 lines are misread as self-references and all become false positives (measured).
    #   (4) NO conventions filename on the PREVIOUS line -- filename on one line, quoted span on the next
    #       (a WRAPPED citation) produces 3 more false positives (measured). That is precisely the blind
    #       spot G3 documents.
    # The window for (4) is ONE line. A filename two or more lines back is NOT seen, so this part treats
    # the span as a self-reference and resolves it against the file's OWN anchors -- a self-reference and
    # a WRAPPED citation are indistinguishable in principle (the filename that would tell them apart sits
    # on another line; that is exactly the blind spot G3 documents). The outcome therefore hinges on
    # whether the name happens to exist in that file too: if it does the check passes SILENTLY (measured:
    # site/docs/concepts.md carries anchors named like the convention's sections), if it does not it fails.
    # WIDENING THE WINDOW DOES NOT CLOSE THIS -- 1 -> 2 -> 3 all yield 46 candidates / 0 unresolved on the
    # live tree (measured), and with a window of N a filename N+1 lines back is still missed. The boundary
    # only moves, so the window stays at 1 and the limit is disclosed instead.
    # Four undetected classes: (1) no trailing-word marker, (2) a backticked path on the same line, (3)
    # citations to non-conventions files, (4) the wrapped-citation exception above. ALL are outside the
    # boundary, not violations, and the convention enumerates them on both sides.
    $JEOL = Uni 0xC808
    $srPathRe = '`[A-Za-z0-9_./-]+\.(md|sh|ps1|json|yml)`'
    $srRe = '"([^"]*)"[ \t]*' + $JEOL
    function HasConvBase($s) {
        if ($null -eq $s) { return $false }
        foreach ($b in $gConvBases) { if ($s.Contains($b)) { return $true } }
        return $false
    }
    $gSelf = @()
    $gSelfMiss = 0
    foreach ($p in (LivingDocs)) {
        $raw = ReadUtf8 $p
        if ($null -eq $raw) { continue }
        $own = New-Object 'System.Collections.Generic.HashSet[string]'
        foreach ($a in (AnchorSetOf $p)) { [void]$own.Add($a) }
        $prev = ''
        foreach ($line in ($raw -split "`r?`n")) {
            $skip = ($line -match $srPathRe) -or (HasConvBase $line) -or (HasConvBase $prev)
            if (-not $skip) {
                foreach ($m in [regex]::Matches($line, $srRe)) {
                    $span = ($m.Groups[1].Value -replace ' ', '')
                    if ($span -ne '' -and $span -notmatch '[{}]') {
                        $gSelf += $span
                        # On failure, NAME the file and the span -- a counting assertion goes red without
                        # saying why (same reason the duplicate-anchor check prints names). The wording
                        # names BOTH causes on purpose: an unresolved self-reference, or a citation
                        # wrapped with its filename two or more lines back (see (4) above). A human tells
                        # them apart by reading that line and the ones before it; either way something
                        # needs fixing, and naming only one cause would misdiagnose the other.
                        if (-not $own.Contains($span)) {
                            $gSelfMiss++
                            Write-Host ("  -> unresolved self-reference or wrapped citation: " + (RelPath $p) + " -> " + $span)
                        }
                    }
                }
            }
            $prev = $line
        }
    }
    $selfSet = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($s in $gSelf) { [void]$selfSet.Add($s) }

    Chk "G4: every self-reference resolves to its own file's anchor" ([string]$gSelfMiss) '0'
    Chk "G4: self-reference extraction positive control (>0)" $(if ($gSelf.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "G4: control -- bogus name (bogus-section) is not a self-reference" $(if ($selfSet.Contains('bogus-section')) { 'yes' } else { 'no' }) 'no'

    # (G5~G7 - M42) citations pointing OUTSIDE the conventions set. G1 compares only against anchors in
    # docs/conventions*.md, so a citation naming skills/*/SKILL.md or docs/*.md was seen by NO guard --
    # four cycles unaddressed (M35-impl follow-up 3), and three such citations were actually stale.
    # Generalization rationale: the skeleton NAMES the file, so resolve against THAT file's own anchors;
    # name UNIQUENESS stays scoped to the conventions set (widening it would explode on unrelated docs).
    # The skeleton particle after the path is REQUIRED -- without it a later quoted span on the same line
    # is not evidence about that path (measured false positive: a line naming a path and then pointing at
    # its OWN section, which is G4's business). A target that does not exist in the repo is NOT compared:
    # Part G asks about anchors, not about path existence.
    $UI = Uni 0xC758
    $extPathRe = '`([A-Za-z0-9_./-]+\.md)`'
    function ExtCitesOf($path) {
        $out = @()
        $raw = ReadUtf8 $path
        if ($null -eq $raw) { return $out }
        foreach ($line in ($raw -split "`r?`n")) {
            foreach ($m in [regex]::Matches($line, $extPathRe)) {
                $p = $m.Groups[1].Value
                if (HasConvBase $p) { continue }
                $rest = $line.Substring($m.Index + $m.Length)
                if (-not $rest.StartsWith($UI, [System.StringComparison]::Ordinal)) { continue }
                $mm = [regex]::Match($rest, $srRe)
                if (-not $mm.Success) { continue }
                $a = ($mm.Groups[1].Value -replace ' ', '')
                if ($a -ne '' -and $a -notmatch '[{}]') { $out += ($p + "`t" + $a) }
            }
        }
        return $out
    }
    function ExtMissOf($records) {
        $miss = @()
        foreach ($rec in $records) {
            $parts = $rec -split "`t", 2
            if ($parts.Count -lt 2) { continue }
            $p = $parts[0]; $a = $parts[1]
            if ($a -eq '') { continue }
            $tgt = Join-Path $ROOT ($p.Replace('/', [string][char]92))
            if (-not (Test-Path $tgt)) { continue }
            $set = New-Object 'System.Collections.Generic.HashSet[string]'
            foreach ($x in (AnchorSetOf $tgt)) { [void]$set.Add($x) }
            if (-not $set.Contains($a)) { $miss += ($p + ' -> ' + $a) }
        }
        return $miss
    }
    $gExtCites = @()
    foreach ($p in (LivingDocs)) { $gExtCites += @(ExtCitesOf $p) }
    $gExtMiss = @(ExtMissOf $gExtCites)
    foreach ($m in $gExtMiss) { Write-Host ("  -> broken cross-doc citation: " + $m) }
    Chk "G5: every cross-doc citation resolves to a real anchor" ([string]$gExtMiss.Count) '0'
    Chk "G6: cross-doc citation extraction positive control (>0)" $(if ($gExtCites.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    # Injection control -- a citation naming a real file but an anchor it does not carry must be caught.
    $extFx = Join-Path $sbx 'extfx.md'
    [System.IO.File]::WriteAllText($extFx, ('- `skills/impl/SKILL.md`' + $UI + ' "bogus-cross-anchor" ' + $JEOL + "`n"), (New-Object System.Text.UTF8Encoding($false)))
    Chk "G7: control -- injected broken cross-doc citation is caught" ([string](@(ExtMissOf (@(ExtCitesOf $extFx)))).Count) '1'

    # (G8 -- M44) Sub-items of a section are cited BY NAME, never by ordinal. Everything else in Part G
    # compares only as far as the SECTION ANCHOR, so a sub-index was seen by no case at all. M43 review
    # issue 5 is that class: the ledger cited an ordinal (U+2477) inside a named enumeration while that
    # ordinal was an item M40 had closed and removed -- produced by an edit that moved the item without
    # fixing its downstream pointers.
    # Single source: the cross-reference integrity section of docs/conventions.md.
    #   Rule: on a citation line (backticked `.md` path + a quote), an ordinal AFTER the section
    #         marker (U+C808) = violation.
    #   Set spec: U+2460..U+2487 (40 chars). BOTH runners assert the set themselves -- this copy asserts
    #   40 elements, run.sh asserts 40 lines / 160 bytes. Both BUILD the chars from codepoints (no literal),
    #   so the sets agree by construction; without the self-assertion one side could silently narrow.
    #   Why a PROHIBITION and not an extraction: live sites are 0, so an extraction-based case would trip
    #   the "extraction 0 = FAIL" rule and redden a clean tree. The injected fixture is what keeps this
    #   prohibition from being vacuous.
    #   Boundaries (the convention states the same three): an ordinal BEFORE the section marker is out of scope
    #   (1 live line is that shape and is legitimate) / whether a name-cited item really EXISTS is not
    #   compared (5 live sites, 0 observed defects) / a citation split across lines is missed.
    $ORD_SET = @(0x2460..0x2487 | ForEach-Object { [char]$_ })
    function CiteLinesOf($path) {   # citation lines of one doc: backticked .md path AND a quote
        if (-not (Test-Path -LiteralPath $path)) { return @() }
        return @([System.IO.File]::ReadAllLines($path) |
            Where-Object { $_ -match '`[A-Za-z0-9_./-]*\.md`' -and $_.Contains('"') })
    }
    function OrdinalAfterJeol($lines) {   # lines carrying an ordinal AFTER the section marker (U+C808)
        $hits = @()
        foreach ($l in $lines) {
            $j = $l.IndexOf($JEOL)          # ordinal comparison (String.IndexOf(String) is ordinal)
            if ($j -lt 0) { continue }
            foreach ($c in $ORD_SET) {
                $k = $l.IndexOf($c)
                if ($k -gt $j) { $hits += $l; break }
            }
        }
        return $hits
    }
    $g8Cites = @()
    foreach ($p in (LivingDocs)) { $g8Cites += @(CiteLinesOf $p) }
    $g8Hits = @(OrdinalAfterJeol $g8Cites)
    foreach ($h in $g8Hits) { Write-Host ("  -> ordinal sub-index citation: " + $h) }
    Chk "G8a: ordinal set is 40 chars (U+2460-U+2487)" ([string]$ORD_SET.Count) '40'
    # Extraction positive control -- a PROHIBITION is still vacuous if there is nothing to scan. If the
    # CiteLinesOf pattern or the LivingDocs range breaks, G8b passes as 0 == 0. Assert the corpus is
    # non-empty (checklist item 1 -- same shape as the G2/G6/G4 extraction controls). Added by the M44 review.
    Chk "G8b0: citation-line extraction positive control (>0)" $(if ($g8Cites.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "G8b: no ordinal sub-index citation after the section marker" ([string]$g8Hits.Count) '0'
    # Fixture control -- inject one violation in M43 issue 5's actual shape (U+2477) and it must be caught.
    $g8Fx = @('- `docs/conventions.md`' + $UI + ' "bogus-anchor" ' + $JEOL + ' ' + [char]0x2477)
    Chk "G8c: control -- injected ordinal sub-index citation is caught" ([string](@(OrdinalAfterJeol $g8Fx)).Count) '1'

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
        # (M42-T03) `Sort-Object -CaseSensitive` is CULTURE-aware, not ordinal -- the same thing M41
        # found in Part C. The .sh twin here is `LC_ALL=C sort` (no `-u`), so this is the
        # duplicate-preserving ordinal helper. This output is string-compared by H3/H15, so the sort
        # ORDER is part of the verdict.
        return ((OrdinalSort $names) -join ' ')
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
        return ((OrdinalSortUnique $tok) -join ' ')   # .sh twin: `LC_ALL=C sort -u` (M42-T03)
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
        return ((OrdinalSortUnique $pairs) -join ' ')   # .sh twin: `LC_ALL=C sort -u` (M42-T03)
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
        return ((OrdinalSort $names) -join ' ')   # .sh twin: `LC_ALL=C sort` (no -u) -- M42-T03
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
        return ((OrdinalSort $out) -join ' ')   # .sh twin: `LC_ALL=C sort` (no -u) -- M42-T03
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
    # (M42-T03) ORDINAL equality, like Part C's SetsEqual -- culture `-eq` would call two axis-name sets
    # equal that the .sh twin's `[ "$a" = "$b" ]` calls different. The `-ne ''` guard (both-empty must
    # be 'no') is unchanged.
    Chk "H3: axis-name sets equal (conventions vs discover README)" $(if ($convAxes -ne '' -and [string]::Equals($convAxes, $readAxes, [System.StringComparison]::Ordinal)) { 'yes' } else { 'no' }) 'yes'
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
    Chk "H15: axis: token set == env-axes declaration set" $(if ($convAxisTokens -ne '' -and [string]::Equals($convAxisTokens, $convAxes, [System.StringComparison]::Ordinal)) { 'yes' } else { 'no' }) 'yes'
    Chk "H16: control -- bogus axis notation (bogus-axis) absent in table" (HasAxis $convAxisTokens 'bogus-axis') 'no'
    # (H17) A data row without a notation is prose inside the table. Row count must equal notation
    # count; the row-count positive control keeps 0==0 from passing vacuously.
    Chk "H17a: axis table data-row extraction positive control (>0)" $(if ($nAxisRows -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "H17b: axis table data-row count == axis: notation count" $(if ($nAxisRows -eq $nAxisRowTok) { 'yes' } else { 'no' }) 'yes'

    # === Part I -- axis state-claim consistency (M42) ==============================
    # Bites the place where the TABLE says an axis is enforced and PROSE says the opposite. Counts are
    # bitten by B1/F1, rosters by C-3/C-4, citations by Part G -- but "two paragraphs assert opposite
    # facts" had no mechanism, and M41 produced THREE such defects in one cycle (two of them of the
    # axis-name class, both missed by two reviews). Single source for the rule, markers and boundary is
    # the axis state-claim consistency section of docs/conventions.md. In short:
    #   POS = the axis table's `axis:` token set (axes whose enforcement cell is alive) -- Part H's set.
    #   NEG = a live doc's BULLET BLOCK carrying both an axis name (inherited from the block head) and a
    #         `state-neg:` marker. Two exclusions: a QUOTED marker (that is the rule being stated, not a
    #         claim) and any line carrying a `state-past:` marker (history narration, not today's state).
    # The markers are DECLARED BY THE CONVENTION and only read here -- a data-driven check with no Korean
    # literal in this script, so the byte>127=0 rule holds (same shape as F2/G4/site-includes).
    # The SHAPE of a declaration line is the discriminator: a bullet, then IMMEDIATELY the key wrapped
    # in backticks (- `state-neg:` ...). A prose mention (- **rule**: ... `state-neg:` ...) does not put
    # the key at the head of the line. Those two lines are exactly what the convention calls the SOLE
    # declaration site, and both the extraction and the uniqueness check (I7..I9) read the SAME line.
    # Blank class is [ \t] -- space and tab, nothing else. The .sh twin reaches the same width by NOT
    # using a character class at all: its decl_lines is an awk LITERAL comparison (walk spaces/tabs, then
    # '-', then spaces/tabs, then the key). Two earlier revisions of this comment were wrong about that
    # twin -- first claiming a bare [[:blank:]] matched this "exactly" (it does not: under a UTF-8 locale
    # glibc's [[:blank:]] also eats U+1680 / U+2003 / U+205F / U+3000, so the same tree split 136/0 here
    # vs 135/1 there under C.UTF-8, the Ubuntu CI default), then claiming an LC_ALL=C pin on that grep
    # (the grep is gone). Describe the twin as it is, or do not describe it. (\s / [[:space:]] would
    # differ again, in both directions.)
    # `-cmatch`, NOT `-match`: PowerShell's `-match` is CASE-INSENSITIVE by default, so a case variant
    # of the key (`- ``State-Neg:`` ...`) counted as a declaration line here while the .sh twin's
    # case-sensitive grep did not -- same tree, 132/0 in sh vs 131/1 here (M42 review issue 4). Every
    # other comparison on this key is ordinal, so the case-sensitive answer is the correct one.
    function DeclLines($path, $key) {
        $raw = ReadUtf8 $path
        if ($null -eq $raw) { return @() }
        $re = '^[ \t]*-[ \t]+`' + [regex]::Escape($key) + '`'
        return @($raw -split "`r?`n" | Where-Object { $_ -cmatch $re })
    }
    function DeclCount($path, $key) { return [string](@(DeclLines $path $key)).Count }
    # The tail after the key on the declaration line -- the ONE place both the marker extraction and
    # the separator check read, so they can never see different strings. The .sh twin does the same
    # with awk index()+substr() (literal, no regex on either side).
    function DeclTail($path, $key) {
        $line = @(DeclLines $path $key) | Select-Object -First 1
        if ($null -eq $line) { return $null }
        $w = '`' + $key + '`'
        $i = $line.IndexOf($w, [System.StringComparison]::Ordinal)
        if ($i -lt 0) { return $null }
        return $line.Substring($i + $w.Length)
    }
    # SEPARATOR SET -- every character EITHER shell may treat as whitespace, minus the ASCII space.
    # .NET \s is [\f\n\r\t\v\x85\p{Z}] and \p{Z} carries NBSP / OGHAM / U+2000-200A / U+2028 / U+2029 /
    # U+202F / U+205F / U+3000. The .sh twin spells the same set as UTF-8 bytes (octal escapes).
    $SEP_RE = '[\t\v\f\r\u0085\u00A0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]'
    function BadSeps($path, $key) {
        $tail = DeclTail $path $key
        if ($null -eq $tail) { return '0' }
        if ([regex]::IsMatch($tail, $SEP_RE)) { return '1' } else { return '0' }
    }
    # FIRST match is pinned by DeclTail above on both sides (sed's greedy leading `.*` used to take the
    # LAST occurrence while IndexOf takes the FIRST -- M42 review blocker 2).
    # SPLIT WIDTH is pinned too: a single ASCII space, exactly like the .sh twin's `tr ' ' '\n'`.
    # This used to be `-split '\s+'`, which made the two shells disagree on TAB and NBSP: one trailing
    # tab on the declaration line killed the last marker in sh ONLY, and sh then stayed GREEN over a
    # real contradiction that this runner caught (M42 review blocker 1). Matching the width is not
    # enough on its own -- a character outside BOTH widths kills the marker in BOTH shells -- so
    # I10..I13 below forbid every such character outright.
    function MarkersOf($key) {
        $tail = DeclTail $CONV $key
        if ($null -eq $tail) { return @() }
        return @(($tail -replace '[`*]', '') -split ' ' | Where-Object { $_ -ne '' })
    }
    $negMarks = @(MarkersOf 'state-neg:')
    $pastMarks = @(MarkersOf 'state-past:')
    # POS set = ONLY axes whose enforcement cell is alive. Using every `axis:` token would turn the
    # convention's own MANDATED honest notation (an axis with no enforcement is written with a
    # state-neg marker) into a contradiction, so that axis's own table row would FAIL (measured in
    # review). Keep the runner exactly as wide as the convention describes.
    function LiveAxes() {
        $out = @()
        $raw = ReadUtf8 $CONV
        if ($null -eq $raw) { return $out }
        foreach ($line in ($raw -split "`r?`n")) {
            if (-not $line.StartsWith('|', [System.StringComparison]::Ordinal)) { continue }
            $cols = $line -split '\|'
            if ($cols.Count -lt 5) { continue }
            $m = [regex]::Match($cols[1], 'axis:([a-z][a-z-]*)')
            if (-not $m.Success) { continue }
            $cell = $cols[3] -replace '[ \t\r]', ''
            if ($cell -eq '') { continue }
            $dead = $false
            foreach ($n in $negMarks) { if ($n -ne '' -and $cell.Contains($n)) { $dead = $true; break } }
            if (-not $dead) { $out += $m.Groups[1].Value }
        }
        return @(OrdinalSortUnique $out)   # sh twin is `LC_ALL=C sort -u`; culture sort would split them
    }
    $axNames = @(LiveAxes)
    function ContraOf($path) {
        $out = @()
        $raw = ReadUtf8 $path
        if ($null -eq $raw) { return $out }
        $cur = New-Object 'System.Collections.Generic.HashSet[string]'
        $n = 0
        foreach ($line in ($raw -split "`r?`n")) {
            $n++
            $flat = $line -replace '[ \t\r]', ''
            if ($line.StartsWith('- ', [System.StringComparison]::Ordinal) -or
                $line.StartsWith('#', [System.StringComparison]::Ordinal) -or
                $line.StartsWith('|', [System.StringComparison]::Ordinal)) { $cur.Clear() }
            foreach ($a in $axNames) { if ($a -ne '' -and $flat.Contains($a)) { [void]$cur.Add($a) } }
            if ($flat.Contains('state-neg:') -or $flat.Contains('state-past:')) { continue }
            $hit = ''
            foreach ($m in $negMarks) { if ($m -ne '' -and $flat.Contains($m)) { $hit = $m; break } }
            if ($hit -eq '') { continue }
            if ($flat.Contains('"' + $hit + '"')) { continue }
            $past = $false
            foreach ($m in $pastMarks) { if ($m -ne '' -and $flat.Contains($m)) { $past = $true; break } }
            if ($past) { continue }
            foreach ($a in $cur) { $out += ($a + ':' + $n) }
        }
        return $out
    }
    # (I1) if the markers cannot be read every assertion below passes 0==0 VACUOUSLY -- bite extraction first.
    Chk "I1: state-neg marker extraction positive control (>0)" $(if ($negMarks.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    # (I1b) the POS set needs its own positive control: if the table layout shifts and the enforcement
    # cell stops being extracted, POS goes empty and I2 passes VACUOUSLY (0==0). H14 bites the `axis:`
    # token set, not this derived subset.
    Chk "I1b: live-enforcement axis extraction positive control (>0)" $(if ($axNames.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    # (I2) the real check. On failure NAME the axis, file and line -- a count alone does not say where.
    $contra = @()
    foreach ($p in (LivingDocs)) {
        foreach ($h in (ContraOf $p)) { $contra += $h; Write-Host ("  -> axis-state contradiction: " + $h + " (" + (Split-Path $p -Leaf) + ")") }
    }
    Chk "I2: no axis state-claim contradiction in live docs" ([string]$contra.Count) '0'
    # (I3~I6) controls -- an injected contradiction is caught; the three deliberately excluded shapes are not.
    $iAx = if ($axNames.Count -gt 0) { $axNames[0] } else { '' }
    $iNeg = if ($negMarks.Count -gt 0) { $negMarks[0] } else { '' }
    $iPast = if ($pastMarks.Count -gt 0) { $pastMarks[0] } else { '' }
    $noBom = New-Object System.Text.UTF8Encoding($false)
    $fxIn = Join-Path $sbx 'contra-inject.md'
    $fxQt = Join-Path $sbx 'contra-quoted.md'
    $fxPa = Join-Path $sbx 'contra-past.md'
    $fxNt = Join-Path $sbx 'contra-notarget.md'
    [System.IO.File]::WriteAllText($fxIn, ('- **`' + $iAx + '` axis**: ' + $iNeg + "`n"), $noBom)
    [System.IO.File]::WriteAllText($fxQt, ('- **`' + $iAx + '` axis**: "' + $iNeg + '"' + "`n"), $noBom)
    [System.IO.File]::WriteAllText($fxPa, ('- **`' + $iAx + '` axis**: ' + $iNeg + $iPast + "`n"), $noBom)
    [System.IO.File]::WriteAllText($fxNt, ('- no axis name here: ' + $iNeg + "`n"), $noBom)
    Chk "I3: control -- injected axis state contradiction is caught" ([string](@(ContraOf $fxIn)).Count) '1'
    Chk "I4: control -- a QUOTED marker (the rule itself) is not a claim" ([string](@(ContraOf $fxQt)).Count) '0'
    Chk "I5: control -- history narration (past marker) is not a claim" ([string](@(ContraOf $fxPa)).Count) '0'
    Chk "I6: control -- a marker with no target axis is not a claim" ([string](@(ContraOf $fxNt)).Count) '0'

    # (I7~I9) DECLARATION-SITE UNIQUENESS -- the convention says "the two lines below are the sole
    # declaration site of the markers", but until now both runners simply took the FIRST line where the
    # key appeared, so nothing bit that sentence (M42 review minor 8). Zero lines means the declaration
    # is gone (extraction goes empty); two or more means the site has SPLIT and which line wins depends
    # on the runner implementation -- both FAIL. These bite WHICH LINE is read; I10..I13 below bite HOW
    # THAT LINE IS SPLIT. An earlier revision claimed here that "which edit is loud and which is silent
    # stops being luck" -- that was FALSE (a trailing tab and an NBSP were still silent, M42 review
    # blocker 1). What holds now: any character in the separator set below makes BOTH shells red. The
    # marker alphabet itself (which characters may form a marker) is still NOT bitten.
    Chk "I7: exactly one state-neg declaration line in the convention" (DeclCount $CONV 'state-neg:') '1'
    Chk "I8: exactly one state-past declaration line in the convention" (DeclCount $CONV 'state-past:') '1'
    # control -- a prose mention is not a declaration site. The fixture is ASCII-only and the .sh twin
    # writes the very same three lines, so it is immediately visible whether both shells count the same.
    $fxDc = Join-Path $sbx 'contra-decl.md'
    [System.IO.File]::WriteAllText($fxDc, (
        '- `state-neg:` alpha beta' + "`n" +
        '- **rule**: the `state-neg:` marker is declared above and only mentioned here' + "`n" +
        'a prose line mentioning `state-neg:` in the middle' + "`n"), $noBom)
    Chk "I9: control -- a prose mention is not a declaration site" (DeclCount $fxDc 'state-neg:') '1'

    # (I10~I13) THE SEPARATOR ON A DECLARATION LINE IS A SINGLE ASCII SPACE (M42 review blocker 1).
    # Matching the two split widths is not enough: a character outside BOTH widths kills a marker in
    # BOTH shells and I2 goes back to passing 0==0. So the width is matched (MarkersOf) AND every other
    # separator is forbidden here. I12/I13 prove the ban is not vacuous. The fixtures are written from
    # ASCII SOURCE ([char] escapes) and the .sh twin writes the very same bytes via printf octal.
    Chk "I10: no forbidden separator in the state-neg declaration tail" (BadSeps $CONV 'state-neg:') '0'
    Chk "I11: no forbidden separator in the state-past declaration tail" (BadSeps $CONV 'state-past:') '0'
    $fxTab = Join-Path $sbx 'contra-sep-tab.md'
    $fxNbsp = Join-Path $sbx 'contra-sep-nbsp.md'
    [System.IO.File]::WriteAllText($fxTab, ('- `state-neg:` alpha' + [char]0x0009 + 'beta' + "`n"), $noBom)
    [System.IO.File]::WriteAllText($fxNbsp, ('- `state-neg:` alpha' + [char]0x00A0 + 'beta' + "`n"), $noBom)
    Chk "I12: control -- a TAB separator is caught" (BadSeps $fxTab 'state-neg:') '1'
    Chk "I13: control -- an NBSP separator is caught" (BadSeps $fxNbsp 'state-neg:') '1'

    # (I14~I15) READ THE SEPARATOR SET FROM THE CONVENTION AND CHECK THIS IMPLEMENTATION AGAINST IT
    # (M42 rework 3). The set lives in three media -- Korean names in the convention, octal bytes in the
    # .sh twin, \uXXXX here -- so no string comparison closes it, and "we read it and they matched" was
    # WRONG THREE ROUNDS RUNNING. Now the convention's `sep-cps:` line is the single source and each
    # runner builds its own fixture per code point. Crucially this runs the WHOLE extraction pipeline,
    # not just the pattern: M42 review blocker 1 was a character that sat in the set but was stripped
    # upstream, so a pattern-only comparison could not see it.
    function SepHits($cps) {
        $h = 0
        $f = Join-Path $sbx 'contra-sep-cp.md'
        foreach ($x in $cps) {
            $ch = [char]::ConvertFromUtf32([Convert]::ToInt32($x, 16))
            [System.IO.File]::WriteAllText($f, ('- `state-neg:` alpha' + $ch + 'beta' + "`n"), $noBom)
            $h += [int](BadSeps $f 'state-neg:')
        }
        return $h
    }
    $sepCps = @(MarkersOf 'sep-cps:')
    $sepOkCps = @(MarkersOf 'sep-ok-cps:')
    # (I16~I19) THE SAME GUARDS THE OTHER DECLARATION KEYS ALREADY CARRY (M42 review blocker 1).
    # I14/I15 READ the declaration to check this implementation -- so if the declaration disappears the
    # set is empty and I14 passes 0 == 0. Measured: deleting the `sep-cps:` line left all four
    # environments green at 140/0. I1/I1b/G6/F4 all guard against exactly this, and I7/I8 additionally
    # pin declaration-line uniqueness for the other two keys. Extraction (>0) and uniqueness (exactly 1).
    Chk "I16: sep-cps extraction positive control (>0)" $(if ($sepCps.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "I17: sep-ok-cps extraction positive control (>0)" $(if ($sepOkCps.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "I18: exactly one sep-cps declaration line in the convention" (DeclCount $CONV 'sep-cps:') '1'
    Chk "I19: exactly one sep-ok-cps declaration line in the convention" (DeclCount $CONV 'sep-ok-cps:') '1'
    Chk "I14: every separator the convention declares is caught" ([string](SepHits $sepCps)) ([string]$sepCps.Count)
    Chk "I15: control -- an allowed character is not caught" ([string](SepHits $sepOkCps)) '0'

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

    # (F4~F5) MACHINE-BITE THE byte>127 = 0 RULE FOR THIS FILE AND ITS SIBLINGS (M42 rework 3, self-raised).
    # The convention and this harness's README have long said the rule "holds", but NO case and no CI job
    # bit it. This round met that fact head-on: a Korean word slipped into a comment in this very file and
    # all 138 cases stayed green -- a human had to count bytes to find it. A rule that lives only in prose
    # is not a rule. F4 is the positive control: if discovery returns nothing, F5 passes 0==0 vacuously.
    # Anchor on $ROOT, never on the caller's cwd -- a relative 'tests' would scan whatever directory the
    # runner happened to be invoked from and could pass over a clean tree while the copy under test is
    # broken (measured while wiring this: the .sh twin went 139/1 and this one stayed 140/0).
    # DISCOVERY SPEC -- THE ONE DEFINITION BOTH COPIES IMPLEMENT: every regular file at any depth under
    # <dir> whose name ends in '.ps1', where (1) the extension compares CASE-SENSITIVELY ('.PS1' is NOT
    # discovered), (2) HIDDEN items are included, (3) directories are not counted. This copy used to get
    # (1) and (2) wrong: -Filter is case-insensitive on Windows and Get-ChildItem skips hidden entries
    # (and does not descend into hidden directories) without -Force. Same tree, different verdict --
    # measured in M42 review blocker 1: a non-ASCII 'extra.PS1' went sh 145/0 (green) vs 144/1 on both
    # PowerShell runtimes, and a hidden 'hid.ps1' went sh 144/1 vs 145/0 (green) on both. The convention's
    # "execution environment axis" section already rules that path-API semantics are a CODE DEFECT, not an
    # axis -- there are not two poles, one side is wrong. The .sh twin is canonical here because `find`
    # does all three by construction; this side matches it with -Force plus an ordinal EndsWith.
    # F7 bites the spec with a fixture. Taking <dir> as a parameter is what lets F7 run THIS function over
    # that fixture -- measuring a fixture with different code than the code under test proves nothing.
    function Ps1FilesIn($dir) {
        return @(Get-ChildItem -Path $dir -Recurse -Force -File |
            Where-Object { $_.Name.EndsWith('.ps1', [System.StringComparison]::Ordinal) })
    }
    function Ps1Files() { return @(Ps1FilesIn (Join-Path $ROOT 'tests')) }
    # READ BYTES, NOT LINES. ReadAllLines DECODES and strips a leading UTF-8 BOM, so a BOM -- which is
    # byte>127 itself, and which PowerShell 5.1's own default writers emit -- was invisible here while the
    # .sh twin caught it (measured: dash 139/1 vs pwsh 140/0 and PS 5.1 140/0, M42 review blocker 2).
    # Lines are split on LF over the raw bytes; CR is ignored, matching the twin's `tr -d '\r'`.
    # WIDTH IS byte>127 ON BOTH SIDES. The twin used to bite the complement of printable-ASCII-plus-tab,
    # which also caught control bytes (form feed, vertical tab) that this side does not -- same tree,
    # different verdict (M42 review recommendation 1: a form feed in a .ps1 went sh 144/1 vs 145/0 on
    # both PowerShell runtimes). The twin was narrowed to an octal byte-range class under LC_ALL=C.
    # CONSUME THROUGH A SERIALIZED LIST, exactly as the twin does. Iterating the discovery result directly
    # and then comparing that count against a fresh enumeration is an IDENTITY, not a control: it cannot
    # go red on any input (M42 review recommendation 3 -- this side was in that state). Round-tripping the
    # list through a file gives F6 a way to fail on this side for the same reason it can on the twin:
    # anything that loses a line between discovery and consumption splits the two numbers.
    function NonAsciiScan() {
        $list = Join-Path $sbx 'ps1files.txt'
        [System.IO.File]::WriteAllLines($list, @(Ps1Files | ForEach-Object { $_.FullName }),
            (New-Object System.Text.UTF8Encoding($false)))
        $checked = 0; $bad = 0
        foreach ($p in [System.IO.File]::ReadAllLines($list)) {
            if ([string]::IsNullOrEmpty($p)) { continue }
            if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { continue }
            $checked++
            $high = $false
            foreach ($b in [System.IO.File]::ReadAllBytes($p)) {
                if ($b -eq 10) { if ($high) { $bad++ }; $high = $false; continue }
                if ($b -eq 13) { continue }
                if ($b -gt 127) { $high = $true }
            }
            if ($high) { $bad++ }
        }
        return @($checked, $bad)
    }
    $ps1Scan = NonAsciiScan
    $ps1Found = (Ps1Files).Count
    Chk "F4: ps1 runner discovery positive control (>0)" $(if ($ps1Found -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "F5: no non-ASCII line in tests/**/*.ps1" ([string]$ps1Scan[1]) '0'
    # (F6) COMPARE DISCOVERY WITH CONSUMPTION -- F4 only sees "discovery returned nothing", but the failure
    # that actually happened was "discovery returned everything and consumption dropped it all".
    Chk "F6: files checked == files discovered" ([string]$ps1Scan[0]) ([string]$ps1Found)
    # (F7) BITE THE DISCOVERY SPEC WITH A FIXTURE. The three axes above (case, hidden, directories) cannot
    # be exercised by scanning the real tests/ tree -- no such file exists there, so that scan stays green
    # forever no matter how wrong the spec is. Build four files plus a decoy directory in the sandbox, run
    # the SAME function over them, and compare SORTED BASENAMES rather than a count: dropping the hidden
    # file (-1) while adding the uppercase one (+1) cancels out to the same count, and that is exactly the
    # pair of defects this side had. On Windows 'hidden' is an attribute, on POSIX it is a leading dot --
    # the fixture is dot-named on both and additionally attribute-hidden where that exists, so each runtime
    # meets its own notion. The .sh twin needs no such attribute: `find` has no concept of hidden at all,
    # which is precisely why this side is the one that had to move.
    function Ps1DiscFixture() {
        $d = Join-Path $sbx 'ps1disc'
        if (Test-Path $d) { Remove-Item $d -Recurse -Force }
        New-Item -ItemType Directory -Path (Join-Path $d 'sub') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $d 'dir.ps1') -Force | Out-Null
        foreach ($n in 'a.ps1', 'b.PS1', '.hidden.ps1', 'sub\c.ps1') {
            [System.IO.File]::WriteAllText((Join-Path $d $n), '', (New-Object System.Text.UTF8Encoding($false)))
        }
        try { (Get-Item -LiteralPath (Join-Path $d '.hidden.ps1') -Force).Attributes = 'Hidden' } catch { }
        return $d
    }
    function DiscSpec($dir) {
        $names = @(Ps1FilesIn $dir | ForEach-Object { $_.Name })
        [Array]::Sort($names, [System.StringComparer]::Ordinal)
        return ($names -join '|')
    }
    $discFix = Ps1DiscFixture
    Chk "F7: discovery spec -- case-sensitive, hidden included, directories excluded" `
        (DiscSpec $discFix) '.hidden.ps1|a.ps1|c.ps1'
    # (F8) BITE F7's HIDDEN-AXIS PRECONDITION (M43 -- disposition of M42 review recommendation 1).
    # For F7 to prove "hidden files are discovered", the fixture's hidden file must ACTUALLY be hidden.
    # Setting the attribute lives in a try/catch here, and if that step fails quietly the hidden axis
    # disappears while the runner says nothing -- measured in the M42 review: disable only the attribute
    # step and a live -Force defect still leaves both PowerShell runtimes at 146/0 green. So assert the
    # precondition: an enumeration that does NOT include hidden entries must not see that file. The test
    # holds on both platforms through each one's own notion of hidden -- a leading dot on POSIX (globs
    # skip it), the Hidden attribute on Windows (-Force-less enumeration skips it). What this case bites
    # on THIS side is whether the attribute was really set; on the .sh side it is the dot-name convention,
    # since that shell has no attribute concept. Same invariant, each side's expression of it.
    function DiscVisibleCount($dir) {
        return [string]@(Get-ChildItem -Path $dir -File |
            Where-Object { $_.Name.EndsWith('.ps1', [System.StringComparison]::Ordinal) }).Count
    }
    Chk "F8: hidden fixture stays hidden to a non-Force enumeration (F7 precondition)" `
        (DiscVisibleCount $discFix) '1'

    # ONE SEAT FOR THE COMMENT PREDICATE (M49-T02). Part F (locale pinning), Part J (variable-name
    # boundary) and Part K (shared control tokens) all need "is this line a comment?". It used to be
    # written twice on this side -- and the two seats bit DIFFERENT WIDTHS: the Part F seat was an inline
    # `TrimStart().StartsWith('#')`, and the .NET argument-less TrimStart() strips EVERY Unicode space
    # (U+00A0, U+3000, ...) while this predicate and the twin's [[:blank:]] under LC_ALL=C strip ASCII
    # SPACE AND TAB ONLY. So a .sh source whose comment line began with U+00A0 SPLIT THE TWO COPIES
    # (M48 review issue 2 measured it; F17 below pins it as a fixture). The definition sits HERE, ahead
    # of Part F, for the same reason COMMENT_RE sits ahead of locale_scan_in in the twin.
    # The predicate: the first character that is not ASCII space or tab is '#'.
    function IsCommentLine([string]$l) { return ($l -match '^[ \t]*#') }

    # (F9-F12 -- M45) LOCALE PINNING discipline -- same layer as F5 (non-ASCII lines): it bites the
    # RUNNER SOURCE, not documents. Four cycles in a row a human caught this class: M41 (Sort-Object /
    # StartsWith, 6 seats), M42 (three surfaces audited + the omission in tests/lib/discover.sh), and the
    # M44 review's issue 4 (a missing LC_ALL=C that the implementation missed and the review caught).
    # This class has TWO precedents of splitting the two shells and failing only on BSD.
    #   What it bites (spec): (1) on the .sh side only COMMAND-POSITION `sort`/`uniq` -- after start of
    #         line, a pipe, `;`, `&`, `(` or `$(`. Function-name substrings (toposort) and comments are
    #         out of scope (M45-T01 measured: 46 raw lines -> 22 command-position sites). (2) on the .ps1
    #         side only BARE `Sort-Object` -- a keyed `Sort-Object { ... }` is culture-independent
    #         (2 measured seats) and the broad APIs (-eq / -match / IndexOf) explode with false positives.
    #   Counted as pinned: same-line `LC_ALL=C` (.sh) or an ordinal helper (.ps1).
    #   Exceptions are DECLARED: a same-line `locale-exempt: <reason>` comment. Three live exceptions,
    #         two reasons -- version-sort (two `sort -V` seats M40 decided to keep) and diagnostic-only
    #         (display order, never a verdict; M41 follow-up 11 recorded the same fact).
    #   Boundaries (the convention states them too): the verdict is PER LINE, so a second command after a
    #         pipe (`LC_ALL=C sort ... | uniq`) is not asked about; calls through variables, `eval`, and
    #         other locale-sensitive tools (join, comm) are out of scope; so are the broad .ps1 APIs.
    # (M45 rework 1) THE VERDICT IS TAKEN ON THE LINE ITSELF. The first draft joined sites into
    # "path:line:body" and split them back on colons -- and on this side the path carries a DRIVE COLON,
    # so the split slid and the comment exclusion died (review blocker 1: bash skipped, pwsh false-flagged
    # the same tree). Now each file is scanned in place and the raw line is judged; the path is prefixed
    # for REPORTING only. No colon parsing remains, so that class is structurally closed.
    # SITE TERMINATORS are part of the spec too (rework 1): a site ends at blank, `)`, `;`, `|`, `#` or
    # end of line. The first draft accepted only blank/end-of-line and therefore MISSED `$(cat x | sort)`
    # and `| Sort-Object  # comment` -- that miss, not the Ordinal hatch, was the real mechanism behind
    # review blocker 2 (the attack line ended in a trailing comment, so it was never even a site).
    # The blank-space class is pinned to ASCII space+tab on BOTH sides as well
    # (sh [[:blank:]] under LC_ALL=C <-> ps1 [ \t]) -- [[:space:]] vs \s bite different widths, which is
    # itself a seed of two-shell divergence (review return item 2).
    $LOCALE_EXEMPT_TOK = 'locale-exempt:'
    $LOCALE_SITE_RE_SH = '(^|[|;&(]|\$\()[ \t]*(LC_ALL=C[ \t]+)?(sort|uniq)([ \t);|#]|$)'
    $LOCALE_SITE_RE_PS1 = 'Sort-Object[ \t]*(\||\)|#|$)'
    # The `Ordinal` escape hatch is GONE (rework 1 -- review blocker 2). The first draft treated any line
    # containing the string 'Ordinal' as pinned while the docs said "via an ordinal-only helper", so the
    # implementation was WIDER than the documentation: one word in a comment let an unpinned sort through
    # (measured). A bare Sort-Object has no pinned form at all -- fold it into a helper and it stops being
    # a site, or keep it and DECLARE it. So the only escape hatch left is the .sh `LC_ALL=C`.
    function LocaleScanIn($path, $regex) {   # unpinned AND undeclared lines -> "path:line:body"
        if (-not (Test-Path -LiteralPath $path)) { return @() }
        $out = @(); $i = 0
        foreach ($l in [System.IO.File]::ReadAllLines($path)) {
            $i++
            if ($l -notmatch $regex) { continue }
            if ($l.Contains($LOCALE_EXEMPT_TOK)) { continue }        # declared exception
            if (IsCommentLine $l) { continue }                       # comment (ONE seat -- see above)
            if ($l.Contains('LC_ALL=C ')) { continue }               # the .sh pinned form
            $out += ("{0}:{1}:{2}" -f $path, $i, $l)
        }
        return $out
    }
    function LocaleSitesCountIn($path, $regex) {   # site count only (no filtering)
        if (-not (Test-Path -LiteralPath $path)) { return 0 }
        $n = 0
        foreach ($l in [System.IO.File]::ReadAllLines($path)) { if ($l -match $regex) { $n++ } }
        return $n
    }
    $locUnfixed = @(); $nLocSh = 0; $nLocPs1 = 0
    foreach ($p in @(Get-ChildItem (Join-Path $root 'tests') -Directory | ForEach-Object { Join-Path $_.FullName 'run.sh' }) +
                   @(Get-ChildItem (Join-Path $root 'tests/lib') -Filter '*.sh' -File | ForEach-Object { $_.FullName })) {
        $locUnfixed += @(LocaleScanIn $p $LOCALE_SITE_RE_SH)
        $nLocSh += (LocaleSitesCountIn $p $LOCALE_SITE_RE_SH)
    }
    foreach ($p in @(Get-ChildItem (Join-Path $root 'tests') -Directory | ForEach-Object { Join-Path $_.FullName 'run.ps1' }) +
                   @(Get-ChildItem (Join-Path $root 'tests/lib') -Filter '*.ps1' -File | ForEach-Object { $_.FullName })) {
        $locUnfixed += @(LocaleScanIn $p $LOCALE_SITE_RE_PS1)
        $nLocPs1 += (LocaleSitesCountIn $p $LOCALE_SITE_RE_PS1)
    }
    foreach ($u in $locUnfixed) { Write-Host ("  -> locale not pinned and not declared: " + $u) }
    Chk "F9: no locale site left unpinned and undeclared" ([string]$locUnfixed.Count) '0'
    Chk "F10: sh-side site extraction positive control (>0)" $(if ($nLocSh -gt 0) { 'ok' } else { 'no' }) 'ok'
    # Counted PER FAMILY (rework 1) -- summing both families let one broken extractor stay green because
    # the other family's count remained (measured as R5 in the impl report).
    Chk "F11: ps1-side site extraction positive control (>0)" $(if ($nLocPs1 -gt 0) { 'ok' } else { 'no' }) 'ok'
    # Two fixture controls, one per family (rework 1: the first draft had only the .sh fixture, so the
    # ps1 detector had no in-harness control for its non-vacuity).
    $locFxSh = Join-Path $sbx 'locfx.sh'
    [System.IO.File]::WriteAllText($locFxSh, "x=`$(cat a b | sort -u)`n", (New-Object System.Text.UTF8Encoding($false)))
    Chk "F12: control -- an injected unpinned sh site is caught" ([string](@(LocaleScanIn $locFxSh $LOCALE_SITE_RE_SH)).Count) '1'
    $locFxPs1 = Join-Path $sbx 'locfx.ps1'
    [System.IO.File]::WriteAllText($locFxPs1, "`$s = @(1,2) | Sort-Object`n", (New-Object System.Text.UTF8Encoding($false)))
    Chk "F13: control -- an injected unpinned ps1 site is caught" ([string](@(LocaleScanIn $locFxPs1 $LOCALE_SITE_RE_PS1)).Count) '1'
    # (F17 -- M49-T02) The WIDTH of the comment predicate, pinned by fixture. This copy used to carry the
    # predicate TWICE and the two seats were not the same width: the Part F seat was an argument-less
    # TrimStart(), which strips EVERY Unicode space, while IsCommentLine and the twin's COMMENT_RE strip
    # ASCII space and tab only. A .sh source whose comment line began with U+00A0 therefore SPLIT THE TWO
    # COPIES (M48 review issue 2 measured it; no live input had that shape, so no case went red). The
    # narrow width is the correct one -- in a POSIX shell a '#' preceded by a byte that is not space or
    # tab does not start a comment. The fixture bytes must be identical on both sides: the twin writes
    # octal \302\240, this copy encodes the SAME codepoint (the ASCII-only rule of F5 forbids a literal).
    $locFxNb = Join-Path $sbx 'locfx_nb.sh'
    [System.IO.File]::WriteAllText($locFxNb, ([string][char]0x00A0) + "# x=`$(cat a b | sort -u)`n", (New-Object System.Text.UTF8Encoding($false)))
    Chk "F17: control -- '#' after a leading U+00A0 is NOT a comment (width = ASCII space+tab)" ([string](@(LocaleScanIn $locFxNb $LOCALE_SITE_RE_SH)).Count) '1'

    # (F1) LAST case -- own README declaration ('cases: N') vs actual case count (running total + this one).
    # === F14..F16 (M46) -- entry-point document line cap ==================
    # The conventions state a line cap for CLAUDE.md while also saying "machines do not check this".
    # M46-T05 measured that it CAN be closed: (1) the cap value now has a single declaration site in the
    # conventions (project-context also carried it, breaking declaration uniqueness) and (2) line
    # counting is fixed to be IDENTICAL in both runners.
    # HOW WE COUNT DECIDES THE VERDICT: `wc -l` counts NEWLINES, so a file whose last line lacks one
    # counts 1 short, while `grep -c ""` matches ReadAllLines here (measured: 3-line file with no
    # trailing newline -> wc=2, the other two =3). This copy uses ReadAllLines; the sh copy uses
    # `grep -c ""`. The declaration line is Korean prose, so the pattern is assembled from codepoints
    # (this runner is ASCII-only at source level).
    $CAP_LABEL = Uni 0xC0C1,0xD55C                    # sang-han = cap
    $CAP_UNIT  = [string][char]0xC904                 # jul      = line(s)
    $CAP_RE    = '^- \*\*' + $CAP_LABEL + '\*\*: \*\*[0-9]+' + $CAP_UNIT + '\*\*'
    $capLines  = @([IO.File]::ReadAllLines($CONV) | Where-Object { $_ -match $CAP_RE })
    $ENTRY_CAP = if ($capLines.Count -ge 1) { [int]([regex]::Match($capLines[0],'([0-9]+)' + $CAP_UNIT).Groups[1].Value) } else { 0 }
    $ENTRY_DOC = Join-Path $ROOT 'CLAUDE.md'

    # THE VERDICT LIVES IN ONE FUNCTION -- F15 (real file) and F16 (fixture) both call it. This is what
    # rework 1 fixed: the first version had F16 re-implement the comparison inline, so it never invoked
    # F15's verdict at all, and replacing that verdict outright still scored 172/0 green in BOTH copies
    # (review attack A1 -- a tautological case). Now, if the verdict breaks, the fixture stops reporting
    # 'over' and F16 goes red.
    function EntryCapVerdict([string]$path, [int]$cap) {   # -> ok | over(n/cap) | nocap | nofile
        if ($cap -le 0) { return 'nocap' }
        if (-not (Test-Path $path)) { return 'nofile' }
        $n = ([IO.File]::ReadAllLines($path)).Count
        if ($n -le $cap) { return 'ok' } else { return "over($n/$cap)" }
    }

    # (F14) extraction positive-control + declaration uniqueness -- if the regex or the conventions
    # wording breaks, the cap becomes empty and the verdict below passes vacuously.
    Chk "F14: cap declaration extraction positive-control (unique)" ([string]$capLines.Count) '1'
    # (F15) the actual verdict.
    Chk "F15: CLAUDE.md line count <= conventions cap" (EntryCapVerdict $ENTRY_DOC $ENTRY_CAP) 'ok'
    # (F16) fixture control -- feed an over-cap fixture to the SAME verdict function and require 'over'
    # (same shape as F12/F13 running `locale_scan_in` on a fixture). If this case is red, the verdict died.
    $overPath = Join-Path $SBX 'entryover.md'
    [IO.File]::WriteAllLines($overPath, @(1..($ENTRY_CAP + 1) | ForEach-Object { 'x' }))
    $entryFixR = if ((EntryCapVerdict $overPath $ENTRY_CAP) -like 'over*') { 'caught' } else { 'missed' }
    Chk "F16: control -- verdict function catches the over-cap fixture" $entryFixR 'caught'


    # === Part J (M48) -- variable-name boundary in runner sources =========
    # When a multi-byte character follows `$name` directly, SHELLS DISAGREE ON WHERE THE NAME ENDS.
    # bash 5.2 and dash on this machine stop the name there, but the bash 3.2 that macOS ships as `sh`
    # PULLS THE FOLLOWING BYTES INTO THE NAME and `set -u` kills the runner with "unbound variable".
    # On the v2.19.1 release PR only `posix (macos-latest)` went red -- all four local environments and
    # the ubuntu CI leg were green (the single source for those numbers is docs/reports/debug-2.md; they
    # are NOT copied here). A class that stays green locally forever has to be bitten by a machine, not
    # by a pair of eyes. There is exactly one fix: brace the name to make the boundary explicit.
    #
    # DISCOVERY SPEC -- THE ONE DEFINITION BOTH COPIES IMPLEMENT: every regular file at any depth under
    # $ROOT/tests and $ROOT/hooks whose name ends in '.sh' or '.ps1', where (1) the extension compares
    # CASE-SENSITIVELY ('.SH' / '.PS1' are NOT discovered), (2) HIDDEN items are included, (3)
    # directories are not counted. This is the SAME spec Ps1FilesIn already implements, widened to two
    # extensions -- this part does not invent a second spec. What F7 bites with a fixture is Ps1FilesIn,
    # NOT the RunnerSrcFilesIn this part uses; J6 closes that gap with its own fixture (M48 rework 1).
    #
    # VERDICT: (1) a line whose first non-blank character (ASCII space/tab only) is '#' is a COMMENT and
    # is not judged -- in the M48-T01 measurement ALL five raw matches were comments, and one of them is
    # the comment that EXPLAINS this very rule, so without the exclusion the place that writes the rule
    # down goes red for violating it. (2) on the remaining lines, '$' + name-start [A-Za-z_] + name-rest
    # [A-Za-z0-9_]* followed immediately by a byte > 127 is a violation. (3) the braced form cannot match
    # STRUCTURALLY, because the character after '$' is '{' -- that is the core property of this verdict
    # and J5 bites it. CR (byte 13) is ignored, matching the twin's `tr -d` seat.
    #
    # BOUNDARY (the convention states the same sentence): the verdict is STATIC, so commands assembled
    # through variables or `eval` are invisible to it. Comment lines never execute, so they are not a
    # defect and are excluded.
    #
    # THE VERDICT LIVES IN ONE FUNCTION -- the real scan (J3) and both fixture controls (J4, J5) call it.
    # M46's F16 re-implemented its verdict inline and became a tautology; the convention now requires
    # this shape.
    #
    # ASCII-ONLY SOURCE: the byte range is assembled from CODE POINTS, exactly as $CAP_UNIT and the Uni
    # helper do. Bytes are read raw and mapped 1:1 onto U+0000..U+00FF through ISO-8859-1, so the .NET
    # regex class [U+0080-U+00FF] is BYTE-EQUIVALENT to the twin's octal [\200-\377] under LC_ALL=C.
    # Matching is done with -cmatch (case-sensitive), which is what `grep -E` does on the other side.
    $LATIN1 = [System.Text.Encoding]::GetEncoding(28591)
    $VARBOUND_RE = '\$[A-Za-z_][A-Za-z0-9_]*[' + [char]0x0080 + '-' + [char]0x00FF + ']'
    function RunnerSrcFilesIn($dir) {
        if (-not (Test-Path $dir)) { return @() }
        return @(Get-ChildItem -Path $dir -Recurse -Force -File | Where-Object {
            $_.Name.EndsWith('.sh', [System.StringComparison]::Ordinal) -or
            $_.Name.EndsWith('.ps1', [System.StringComparison]::Ordinal) })
    }
    # THE SCAN ROOTS ARE DECLARED IN ONE PLACE below. What J6 bites is RunnerSrcFilesIn (the spec for a
    # single directory), so WHICH ROOTS GET WALKED is invisible to that case -- and that is exactly the
    # hole the M48 round-0 review measured (drop 'hooks' from the roots and both copies stayed green);
    # round 1's J6 did not close that axis either. So J1 asks the question PER ROOT: delete a root and
    # the composite loses a slot, which no longer equals the expected value.
    $VARBOUND_ROOTS = @('tests', 'hooks')
    function RunnerSrcFiles() {
        $acc = @()
        foreach ($vbRoot in $VARBOUND_ROOTS) { $acc += @(RunnerSrcFilesIn (Join-Path $ROOT $vbRoot)) }
        return $acc
    }
    function VarBoundRootProbe() {   # -> 'ok'/'no' per root, joined with '/'
        $acc = @()
        foreach ($vbRoot in $VARBOUND_ROOTS) {
            $acc += $(if ((@(RunnerSrcFilesIn (Join-Path $ROOT $vbRoot))).Count -gt 0) { 'ok' } else { 'no' })
        }
        return ($acc -join '/')
    }
    function VarBoundLines($path) {   # raw bytes -> Latin-1 chars -> lines, CR dropped
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return @() }
        $text = $LATIN1.GetString([System.IO.File]::ReadAllBytes($path))
        return @($text.Replace([string][char]13, '') -split "`n")
    }
    function VarBoundScanIn($path) {  # violating lines -> "path:lineno"
        $out = @(); $i = 0
        foreach ($l in (VarBoundLines $path)) {
            $i++
            if (IsCommentLine $l) { continue }
            if ($l -cmatch $VARBOUND_RE) { $out += ("{0}:{1}" -f $path, $i) }
        }
        return $out
    }
    function VarBoundProbe($path) {   # "<raw matches>/<violations>" -- before AND after comment exclusion
        $raw = 0
        foreach ($l in (VarBoundLines $path)) { if ($l -cmatch $VARBOUND_RE) { $raw++ } }
        return ("{0}/{1}" -f $raw, (@(VarBoundScanIn $path)).Count)
    }
    # CONSUME THROUGH A SERIALIZED LIST, exactly as the twin does. Iterating the discovery result directly
    # and comparing that count with a fresh enumeration is an IDENTITY, not a control -- it cannot go red
    # on any input (F6 lived in that state once).
    function VarBoundScan() {         # -> @(checked, bad)
        $list = Join-Path $sbx 'runnersrc.txt'
        [System.IO.File]::WriteAllLines($list, @(RunnerSrcFiles | ForEach-Object { $_.FullName }),
            (New-Object System.Text.UTF8Encoding($false)))
        $checked = 0; $bad = 0
        foreach ($p in [System.IO.File]::ReadAllLines($list)) {
            if ([string]::IsNullOrEmpty($p)) { continue }
            if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { continue }
            $checked++
            $bad += (@(VarBoundScanIn $p)).Count
        }
        return @($checked, $bad)
    }
    $vbScan = VarBoundScan
    $vbFound = (@(RunnerSrcFiles)).Count
    if ([string]$vbScan[1] -ne '0') {
        foreach ($vbPath in [System.IO.File]::ReadAllLines((Join-Path $sbx 'runnersrc.txt'))) {
            foreach ($vbHit in (VarBoundScanIn $vbPath)) { Write-Host ("  -> variable name boundary, brace it: " + $vbHit) }
        }
    }
    # (J1) discovery positive control -- if discovery returns nothing, everything below passes 0 == 0.
    Chk "J1: runner source discovery positive control (>0 per root)" (VarBoundRootProbe) 'ok/ok'
    # (J2) discovery vs consumption -- the axis J1 cannot see ("discovery returned everything and
    # consumption dropped it all"). Consumption re-reads the SERIALIZED list; this compares it against a
    # FRESH enumeration, so anything that loses a path splits the two numbers (same shape as F6).
    Chk "J2: files scanned == files discovered" ([string]$vbScan[0]) ([string]$vbFound)
    # (J3) the prohibition itself -- live violations are 0 (measured in M48-T01), which is exactly why the
    # two fixture controls below exist.
    Chk "J3: no variable-name boundary violation in runner sources" ([string]$vbScan[1]) '0'
    # (J4/J5) fixture controls. THE FIXTURES ARE ASSEMBLED FROM BYTES IN THE SANDBOX: writing the
    # offending string as a literal in this source would make the check BITE ITSELF (M45's F12/F13 stepped
    # on that seat and had to declare an exemption; here it is closed by not putting those bytes in the
    # source at all). The fixtures must live under the sandbox and never under tests/ or hooks/, or they
    # join the discovery set and J3 goes red. The planted byte is U+AC74 (UTF-8 EA B1 B4) -- the SAME
    # bytes the .sh twin writes with octal escapes.
    $KOBYTES = [byte[]](0xEA, 0xB1, 0xB4)
    $LFBYTE = [byte[]](0x0A)
    function AsciiBytes([string]$s) { return [System.Text.Encoding]::ASCII.GetBytes($s) }
    $varFx1 = Join-Path $sbx 'varfx1.sh'
    [System.IO.File]::WriteAllBytes($varFx1,
        [byte[]]((AsciiBytes 'echo "x $NANN') + $KOBYTES + (AsciiBytes ' y"') + $LFBYTE))
    Chk "J4: control -- a planted boundary violation is caught" ([string](@(VarBoundScanIn $varFx1)).Count) '1'
    # (J5) two axes in one case -- in the expected '1/0' the first field is the RAW match count and the
    # second is the verdict. (1) the braced line cannot match structurally, so the only raw match is the
    # comment line (a leading 2 means the brace property broke) and (2) that one match disappears through
    # the comment exclusion (a trailing 1 means the comment exclusion died). The trailing field alone
    # would stay 0 even if the scan died outright, so the leading field is what keeps this non-vacuous.
    $varFx0 = Join-Path $sbx 'varfx0.sh'
    [System.IO.File]::WriteAllBytes($varFx0,
        [byte[]]((AsciiBytes 'echo "x ${NANN}') + $KOBYTES + (AsciiBytes ' y"') + $LFBYTE +
                 (AsciiBytes '#  note $NANN') + $KOBYTES + (AsciiBytes ' tail') + $LFBYTE))
    Chk "J5: control -- braced form and comment lines are not caught" (VarBoundProbe $varFx0) '1/0'
    # (J6) BITE THE DISCOVERY SPEC WITH A FIXTURE (M48 rework 1 -- review recommendation 3). J2 measures
    # discovery and consumption with the SAME function, so nothing bit the spec itself.
    # WHAT J6 BITES IS THE SPEC FOR ONE DIRECTORY, NOT WHICH ROOTS GET WALKED -- the round-0 hole
    # (drop 'hooks' from the roots and it goes 24 -> 22 files with both copies green) is closed by J1
    # asking PER ROOT, not by this case. Run RunnerSrcFilesIn over a sandbox tree exactly as F7 runs
    # Ps1FilesIn
    # and compare SORTED BASENAMES rather than a count: dropping the hidden file (-1) while adding an
    # uppercase one (+1) cancels out to the same count, which is why F7 looks at names.
    # Hidden is expressed the way EACH PLATFORM expresses it, exactly as Ps1DiscFixture does: a leading
    # dot on POSIX, plus the Hidden attribute where that exists.
    function RunnerDiscFixture() {
        $d = Join-Path $sbx 'runnerdisc'
        if (Test-Path $d) { Remove-Item $d -Recurse -Force }
        New-Item -ItemType Directory -Path (Join-Path $d 'sub') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $d 'dir.ps1') -Force | Out-Null   # a DIRECTORY
        New-Item -ItemType Directory -Path (Join-Path $d 'dir.sh') -Force | Out-Null    # a DIRECTORY
        foreach ($rdName in 'a.sh', 'b.SH', 'c.PS1', '.hidden.ps1', 'sub\d.ps1') {
            [System.IO.File]::WriteAllText((Join-Path $d $rdName), '',
                (New-Object System.Text.UTF8Encoding($false)))
        }
        try { (Get-Item -LiteralPath (Join-Path $d '.hidden.ps1') -Force).Attributes = 'Hidden' } catch { }
        return $d
    }
    function RunnerDiscSpec($dir) {
        $names = @(RunnerSrcFilesIn $dir | ForEach-Object { $_.Name })
        [Array]::Sort($names, [System.StringComparer]::Ordinal)
        return ($names -join '|')
    }
    Chk "J6: control -- the discovery spec bitten by a fixture (case, hidden, directories)" `
        (RunnerDiscSpec (RunnerDiscFixture)) '.hidden.ps1|a.sh|d.ps1'

    # === Part K (M48) -- shared harness controls, checked against a list ===
    # A NEW HARNESS DROPS A CONTROL THE EXISTING ONES ALL HAVE -- all three M47 returns were of that
    # class, and a human did that comparison by hand every round. The single source is the conventions
    # section on the shared controls a new harness must carry; this part only READS its declaration block.
    #
    # DECLARATION EXTRACTION SPEC: a line that starts with '<!-- harness-control: ' and ends with ' -->'.
    # Fields are separated by ' :: ' (blank, colon colon, blank) in the order <name>, <sh token>,
    # <ps1 token>, <comma-separated exemptions>. TOKENS ARE COMPARED AS FIXED STRINGS, never as regexes --
    # the values contain '$', '{' and a quote, which a regex would read as syntax. '-' means "not required
    # in that shell" and 'none' means "no exemption". A declaration line must carry ALL FOUR FIELDS with
    # NONE OF THEM EMPTY (K2's trailing field) -- an empty fourth field cannot tell "no exemption" from
    # "forgot to write it", which leaves the convention's "never leave it blank" unenforced.
    #
    # TOKENS ARE COMPARED ONLY AGAINST NON-COMMENT LINES (M48 rework 1 -- review blocker 2). The predicate
    # is the SAME one Part J uses (IsCommentLine). Counting comments made 'cases:' present in EVERY ONE of
    # the seven harnesses through a copy-pasted comment, so a harness could LOSE ITS ACTUAL COMPARISON
    # CODE and still be judged as carrying the control -- which is why this part failed to stop the very
    # first of the three M47 returns it cites as its reason to exist. After the exclusion the exemption
    # set is UNCHANGED and all seven still carry every control; the single source for those numbers is
    # docs/reports/M48-impl.md.
    #
    # HARNESS DISCOVERY SPEC: a directory DIRECTLY under $ROOT/tests (depth 1) that has BOTH run.sh and
    # run.ps1. A directory with no runner (tests/lib) is not a harness. Dot-named directories are skipped
    # so this matches the POSIX glob on the twin (Get-ChildItem -Directory would otherwise include them --
    # the same divergence Part B's skills/*/SKILL.md glob already had to pin), while -Force keeps
    # attribute-hidden directories IN, which is what the twin's glob does. Order is ordinal on both
    # sides. AS HARNESSES GROW THE TARGET SET GROWS -- that is why the list is never hardcoded.
    #
    # WHY READ A DECLARATION INSTEAD OF CROSS-COMPARING HARNESSES: cross-comparison GOES STALE WITH ITS
    # REFERENCE and cannot tell "all seven dropped it" from "all seven have it". Reading a declaration
    # needs declaration-line uniqueness instead (K2), whose precedents are F14, I18 and I19.
    #
    # SELF-REFERENCE: tests/discover is itself in the target set. It carries all four controls, so there
    # is no paradox and NO SELF-EXCLUSION IS ADDED -- excluding itself would make the check vacuous
    # exactly where it lives.
    #
    # BOUNDARY (the convention states the same sentence): this bites THE PRESENCE OF A TOKEN, not whether
    # the control actually works. Leave the token in place and make it unreachable and this part stays
    # green -- that layer is covered by tests/mutation and by the per-case revert measurement (a human)
    # that the convention requires.
    $HC_DECL_PREFIX = '<!-- harness-control: '
    $HC_DECL_SUFFIX = ' -->'
    function HcLines() {
        return @([System.IO.File]::ReadAllLines($CONV) | Where-Object {
            $_.Length -ge ($HC_DECL_PREFIX.Length + $HC_DECL_SUFFIX.Length) -and
            $_.StartsWith($HC_DECL_PREFIX, [System.StringComparison]::Ordinal) -and
            $_.EndsWith($HC_DECL_SUFFIX, [System.StringComparison]::Ordinal) })
    }
    function HcField([string]$line, [int]$n) {
        $body = $line.Substring($HC_DECL_PREFIX.Length,
            $line.Length - $HC_DECL_PREFIX.Length - $HC_DECL_SUFFIX.Length)
        $f = @($body -split ' :: ')
        if ($n -ge 1 -and $n -le $f.Count) { return $f[$n - 1] } else { return '' }
    }
    # -Force PLUS THE DOT-NAME FILTER IS EXACTLY THE POSIX GLOB on the twin. `for _d in "$1"/*` skips
    # dot-named entries but has NO CONCEPT OF A HIDDEN ATTRIBUTE, so it still sees an attribute-hidden
    # directory; a -Force-less Get-ChildItem here would not, and the two copies would enumerate different
    # sets (containment is always sh > ps1, so a split is fail-loud -- but it is still a split, and the
    # sibling RunnerSrcFilesIn / Ps1FilesIn already carry -Force for the same reason). M48 review issue 7.
    function HarnessDirsIn($dir) {
        if (-not (Test-Path $dir)) { return @() }
        $out = @(Get-ChildItem -Path $dir -Directory -Force | Where-Object {
            -not $_.Name.StartsWith('.', [System.StringComparison]::Ordinal) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'run.sh') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'run.ps1') -PathType Leaf) } |
            ForEach-Object { $_.FullName })
        [Array]::Sort($out, [System.StringComparer]::Ordinal)
        return $out
    }
    function FileHasToken([string]$path, [string]$tok) {   # FIXED STRING, ordinal, COMMENT LINES SKIPPED
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
        foreach ($l in [System.IO.File]::ReadAllLines($path)) {
            if (IsCommentLine $l) { continue }
            if ($l.IndexOf($tok, [System.StringComparison]::Ordinal) -ge 0) { return $true }
        }
        return $false
    }
    # THE VERDICT TAKES THE HARNESS LIST AS A PARAMETER so the real set (K4) and the fixture (K5) run the
    # SAME code (the shape F7's Ps1FilesIn and F16's EntryCapVerdict already use). Measuring a fixture
    # with different code than the code under test proves nothing.
    function HcMissing([string[]]$dirs) {                  # -> "<harness>:<shell>:<control>"
        $out = @()
        foreach ($hd in $dirs) {
            if ([string]::IsNullOrEmpty($hd)) { continue }
            $hn = Split-Path $hd -Leaf
            foreach ($l in (HcLines)) {
                $cn = HcField $l 1; $tsh = HcField $l 2; $tps = HcField $l 3; $tex = HcField $l 4
                if ((',' + $tex + ',').Contains(',' + $hn + ',')) { continue }   # declared exemption
                if ($tsh -ne '-' -and -not (FileHasToken (Join-Path $hd 'run.sh') $tsh)) {
                    $out += ("{0}:sh:{1}" -f $hn, $cn)
                }
                if ($tps -ne '-' -and -not (FileHasToken (Join-Path $hd 'run.ps1') $tps)) {
                    $out += ("{0}:ps1:{1}" -f $hn, $cn)
                }
            }
        }
        return $out
    }
    function HcOrphanExempt([string[]]$dirs) {             # exemptions naming a harness that does not exist
        $names = @($dirs | ForEach-Object { Split-Path $_ -Leaf })
        $out = @()
        foreach ($l in (HcLines)) {
            $tex = HcField $l 4
            if ($tex -eq 'none') { continue }
            foreach ($e in @($tex -split ',')) {
                if ([string]::IsNullOrEmpty($e)) { continue }
                $hit = $false
                foreach ($n in $names) {
                    if ([string]::Equals($n, $e, [System.StringComparison]::Ordinal)) { $hit = $true }
                }
                if (-not $hit) { $out += $e }
            }
        }
        return $out
    }
    function HcWellFormed([string]$line) {   # exactly four fields, none of them empty
        $body = $line.Substring($HC_DECL_PREFIX.Length,
            $line.Length - $HC_DECL_PREFIX.Length - $HC_DECL_SUFFIX.Length)
        $fields = @($body -split ' :: ')
        if ($fields.Count -ne 4) { return $false }
        foreach ($hcFld in $fields) { if ([string]::IsNullOrEmpty($hcFld)) { return $false } }
        return $true
    }
    $hcDecls = @(HcLines)
    $harnessList = @(HarnessDirsIn (Join-Path $ROOT 'tests'))
    # ordinal dedup of the control names (a bare Sort-Object is banned and its uniqueness would be
    # culture-sensitive anyway; this sorts with an ordinal comparer and counts the runs).
    $hcNames = @($hcDecls | ForEach-Object { HcField $_ 1 })
    [Array]::Sort($hcNames, [System.StringComparer]::Ordinal)
    # NOTE: never bind a script-scope loop variable named $n here -- PowerShell variable names are
    # case-insensitive, so $n and the command-skill count $N are the SAME variable (measured: the result
    # line printed a control name instead of the count).
    $hcUniq = 0; $hcPrev = $null
    foreach ($hcNm in $hcNames) {
        if ($null -eq $hcPrev -or -not [string]::Equals([string]$hcNm, [string]$hcPrev, [System.StringComparison]::Ordinal)) { $hcUniq++ }
        $hcPrev = $hcNm
    }
    $hcWell = 0
    foreach ($hcDl in $hcDecls) { if (HcWellFormed $hcDl) { $hcWell++ } }
    $hcMiss = @(HcMissing $harnessList)
    foreach ($hcMissLine in $hcMiss) { Write-Host ("  -> harness control token missing: " + $hcMissLine) }
    # (K1) declaration extraction positive control -- if the block disappears the loop below never runs
    # and everything passes 0 == 0.
    Chk "K1: harness-control declaration extraction positive control (>0)" $(if ($hcDecls.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    # (K2) declaration NAME UNIQUENESS plus DECLARATION SHAPE (checklist item 2). A COMPOUND EXPECTATION:
    # the leading field is the unique-name count (two rows with one name and a single line of prose
    # rewrites the whole list) and the trailing field is the number of lines that carry all four fields
    # with none of them empty. Without the trailing field an EMPTY fourth field behaves EXACTLY like
    # 'none', leaving the convention's "never leave it blank" unenforced (M48 review issue 8).
    Chk "K2: control name uniqueness + declaration line shape (four fields, none empty)" `
        ("{0}/{1}" -f $hcUniq, $hcWell) ("{0}/{1}" -f $hcDecls.Count, $hcDecls.Count)
    # (K3) harness discovery positive control -- if discovery returns nothing K4 passes vacuously.
    Chk "K3: harness discovery positive control (>0)" $(if ($harnessList.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    # (K4) the check itself -- every (harness x shell) pair that is not exempt carries its token.
    Chk "K4: no missing control token across harness x shell (exemptions aside)" ([string]$hcMiss.Count) '0'
    # (K5) fixture control -- live misses are 0, so this is what keeps K4 from being vacuous. In the
    # expected '1/caught' the first field bites the DISCOVERY SPEC (a decoy directory with only one runner
    # is not a harness) and the second bites the VERDICT. The fixture harness carries EVERY DECLARED TOKEN
    # BUT ONLY INSIDE COMMENTS, so this case now bites "token missing" AND "token in a comment only" --
    # revert the comment exclusion and the trailing field flips to 'missed'. The comment lines are DERIVED
    # FROM THE DECLARATION BLOCK rather than written as literals: a literal here would put those tokens on
    # a CODE line of this very runner and loosen its own self-check (the same discipline that keeps J4/J5
    # from putting their bytes in the source).
    function HcFixture() {
        $d = Join-Path $sbx 'hcfix'
        if (Test-Path $d) { Remove-Item $d -Recurse -Force }
        New-Item -ItemType Directory -Path (Join-Path $d 'zz-fake') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $d 'zz-decoy') -Force | Out-Null
        $enc = New-Object System.Text.UTF8Encoding($false)
        $fkSh = @(); $fkPs = @()
        foreach ($hcFl in (HcLines)) {
            $fkTsh = HcField $hcFl 2; $fkTps = HcField $hcFl 3
            if ($fkTsh -ne '-') { $fkSh += ('# ' + $fkTsh + ' in a comment only') }
            if ($fkTps -ne '-') { $fkPs += ('# ' + $fkTps + ' in a comment only') }
        }
        $fkSh += 'echo hello'
        $fkPs += 'Write-Host hello'
        [System.IO.File]::WriteAllText((Join-Path $d 'zz-fake/run.sh'),
            (($fkSh -join "`n") + "`n"), $enc)
        [System.IO.File]::WriteAllText((Join-Path $d 'zz-fake/run.ps1'),
            (($fkPs -join "`n") + "`n"), $enc)
        [System.IO.File]::WriteAllText((Join-Path $d 'zz-decoy/run.sh'), "echo hello`n", $enc)   # no run.ps1
        return $d
    }
    $hcFixDirs = @(HarnessDirsIn (HcFixture))
    $hcFixR = if ((@(HcMissing $hcFixDirs)).Count -gt 0) { 'caught' } else { 'missed' }
    Chk "K5: control -- a comment-only-token fixture harness is caught by the same function" `
        ("{0}/{1}" -f $hcFixDirs.Count, $hcFixR) '1/caught'
    # (K6) exemption freshness -- a name in the exemption list must be a REAL harness. Rename or drop a
    # harness and the exemption is orphaned, quietly loosening that control (same layer as Part H's
    # exemption-freshness case).
    Chk "K6: every exempted name is a real harness (orphans 0)" ([string](@(HcOrphanExempt $harnessList)).Count) '0'

    # === Part L (M49) -- declared count vs enumerated item count ===========
    # A document that STATES A COUNT and then ENUMERATES must not disagree with its own enumeration.
    # The trigger was M48 round 0's blocker 1, which was NOT a logic defect but an EDITING ACCIDENT: one
    # line overwrote another, an item of an honesty notice vanished, and the lead-in still declared three.
    # Seven harnesses across four execution environments were ALL GREEN and no guard looked at that seat.
    # Single source: the "declared count vs enumerated items" section of docs/conventions.md.
    #   The MARKERS ARE DECLARED BY THE CONVENTION and this runner only reads them (same mechanism as
    #   `state-neg:` and `harness-control:`) -- that is how this copy runs the SAME verdict with no
    #   Korean literal in its source (the ASCII-only rule of F5).
    #   THE WINDOW IS THE CIRCLED ENUMERATOR AND NOTHING ELSE. Taking the following bullet block as the
    #   window disagrees on every live site, and taking a middle-dot inline list disagrees on most of
    #   them (in this repo the middle dot is a general separator, not an enumerator). Numbers: see
    #   docs/reports/M49-impl.md.
    #   Boundary: if an item's BODY names a sibling number that has not appeared yet, the run inflates
    #   (a false positive). Zero live sites have that shape today; the convention records the same bound.
    $cntWords = @(MarkersOf 'count-word:')
    $cntCops = @(MarkersOf 'count-copula:')
    $lWord = @(); $lVal = @()
    foreach ($t in $cntWords) {
        $p = $t.IndexOf('=', [System.StringComparison]::Ordinal)
        if ($p -gt 0) { $lWord += $t.Substring(0, $p); $lVal += [int]$t.Substring($p + 1) }
    }
    # Two SEPARATE series -- merging them in one window fuses two different enumerations into one.
    $ENUM_S1 = @(0x2460..0x2473 | ForEach-Object { [char]$_ })
    $ENUM_S2 = @(0x2474..0x2487 | ForEach-Object { [char]$_ })
    # BLANK and LIST-ITEM tests are pinned to ASCII space+tab, the same width as the twin's awk under
    # LC_ALL=C. Trim()/\s here would strip every Unicode space and split the two copies -- that is
    # exactly the class F17 above was built for, so it is not repeated here.
    function LLead([string]$s) {
        $i = 0
        while ($i -lt $s.Length -and ($s[$i] -eq ' ' -or $s[$i] -eq "`t")) { $i++ }
        return $i
    }
    function LIsList([string]$s) { return ($s -match '^[ \t]*([-*]|[0-9]+\.)[ \t]') }
    function LIsBlank([string]$s) { return ($s -notmatch '[^ \t]') }
    function LIsEnumItem([string]$s) {
        if (-not (LIsList $s)) { return $false }
        $t = $s -replace '^[ \t]*([-*]|[0-9]+\.)[ \t]*', ''
        foreach ($c in $ENUM_S1) { if ($t.StartsWith([string]$c, [System.StringComparison]::Ordinal)) { return $true } }
        foreach ($c in $ENUM_S2) { if ($t.StartsWith([string]$c, [System.StringComparison]::Ordinal)) { return $true } }
        return $false
    }
    # MARKER LEFT BOUNDARY (M49 rework 1). Searching for the marker with no word boundary means a
    # numeral sitting INSIDE ANOTHER WORD is read as a declaration -- a normal Korean word ending in the
    # syllable for ten made a correct document go red (measured, M49 review blocker 1). The rule: the
    # character right before the marker must be the LINE START or ASCII. That verdict is identical in
    # both copies: the twin runs under LC_ALL=C and looks at the preceding BYTE while this copy looks at
    # the preceding CHAR, and a non-ASCII character always ends in a byte >= 0x80 -- so "ASCII char" and
    # "ASCII byte" agree on every input.
    function LTokPos([string]$s, [string]$t) {   # first position satisfying the boundary, else -1
        $off = 0
        while ($true) {
            $p = $s.IndexOf($t, $off, [System.StringComparison]::Ordinal)
            if ($p -lt 0) { return -1 }
            if ($p -eq 0) { return $p }
            $c = [int][char]$s[$p - 1]
            if ($c -eq 9 -or ($c -ge 32 -and $c -le 126)) { return $p }
            $off = $p + 1
        }
    }
    function LMaxRun([string]$w) {   # longest run starting at 1; the two series are counted separately
        $a = 0
        while ($a -lt $ENUM_S1.Count -and $w.Contains([string]$ENUM_S1[$a])) { $a++ }
        $b = 0
        while ($b -lt $ENUM_S2.Count -and $w.Contains([string]$ENUM_S2[$b])) { $b++ }
        if ($a -gt $b) { return $a } else { return $b }
    }
    function EnumScanIn($path) {   # 'CAND' per candidate, 'BAD path:line:declared/actual' per mismatch
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return @() }
        $lines = [System.IO.File]::ReadAllLines($path)
        $out = @()
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            # The marker DECLARATION LINES themselves are not subjects (same guard as Part I).
            if ($line.Contains('count-word:') -or $line.Contains('count-copula:')) { continue }
            $base = LLead $line
            for ($w = 0; $w -lt $lWord.Count; $w++) {
                foreach ($cop in $cntCops) {
                    $tok = [string]$lWord[$w] + [string]$cop
                    $pos = LTokPos $line $tok
                    if ($pos -lt 0) { continue }
                    $win = $line.Substring($pos + $tok.Length)
                    for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                        $nl = $lines[$j]
                        if (LIsBlank $nl) { break }
                        if ((LIsList $nl) -and ((LLead $nl) -le $base) -and -not (LIsEnumItem $nl)) { break }
                        $win = $win + "`n" + $nl
                    }
                    $k = LMaxRun $win
                    if ($k -eq 0) { continue }
                    $out += 'CAND'
                    if ($k -ne $lVal[$w]) { $out += ("BAD {0}:{1}:{2}:{3}/{4}" -f $path, ($i + 1), $tok, $lVal[$w], $k) }
                }
            }
        }
        return $out
    }
    $lScan = @()
    $lLiving = @(LivingDocs)
    foreach ($p in $lLiving) { $lScan += @(EnumScanIn $p) }
    $lCand = @($lScan | Where-Object { $_ -eq 'CAND' }).Count
    $lBad = @($lScan | Where-Object { $_.StartsWith('BAD ', [System.StringComparison]::Ordinal) })
    foreach ($b in $lBad) { Write-Host ("  -> declared count vs enumerated items: " + $b.Substring(4)) }
    Chk "L1: exactly one count-word declaration line" (DeclCount $CONV 'count-word:') '1'
    Chk "L2: exactly one count-copula declaration line" (DeclCount $CONV 'count-copula:') '1'
    Chk "L3: marker extraction positive control (numerals>0, copulas>0)" `
        $(if ($lWord.Count -gt 0 -and $cntCops.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "L4: 20 enumerators in each series (each copy self-asserts)" ("{0}/{1}" -f $ENUM_S1.Count, $ENUM_S2.Count) '20/20'
    # (L5) ASK PER ROOT. "extraction is not zero" cannot see ONE ROOT DISAPPEARING -- the other roots
    # still yield documents, the count stays above zero, and the scanned range quietly shrinks. The M48
    # review returned exactly that shape (J1), so the same mistake is not repeated here. The classes are
    # derived FROM WHAT THE DISCOVERY FUNCTION RETURNED (no re-discovery -- measuring a fixture with code
    # other than the code under test proves nothing).
    function LivingRootClasses($paths) {
        $c = @{}
        foreach ($p in $paths) {
            $rel = [string]$p
            if ($rel.StartsWith($ROOT, [System.StringComparison]::Ordinal)) { $rel = $rel.Substring($ROOT.Length) }
            $rel = $rel.Replace('\', '/').TrimStart('/')
            if ($rel.StartsWith('skills/', [System.StringComparison]::Ordinal)) { $c['skills'] = 1 }
            elseif ($rel.StartsWith('site/docs/', [System.StringComparison]::Ordinal)) { $c['site'] = 1 }
            elseif ($rel.StartsWith('docs/', [System.StringComparison]::Ordinal)) { $c['docs'] = 1 }
            elseif ($rel.StartsWith('tests/', [System.StringComparison]::Ordinal)) { $c['tests'] = 1 }
            elseif ($rel -eq 'README.md') { $c['readme'] = 1 }
        }
        return $c.Count
    }
    Chk "L5: all five living-doc root classes appear (per root, not just >0)" `
        ("{0}/{1}" -f (LivingRootClasses $lLiving), $(if ($lLiving.Count -gt 0) { 'ok' } else { 'no' })) '5/ok'
    # (L6) With zero candidates L7 would pass as 0 == 0 -- ask about the extraction itself first.
    Chk "L6: declaration+enumeration candidate extraction positive control (>0)" `
        $(if ($lCand -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "L7: no declared-count vs enumerated-item mismatch in living docs" ([string]$lBad.Count) '0'
    # Two fixture controls that RUN THE REAL VERDICT on the fixture (not "does the fixture satisfy the
    # condition" -- the fourth precedent, M46 review blocker 1). Fixture strings are DERIVED FROM THE
    # MARKERS: writing the numeral and copula as literals would break the ASCII-only rule on this side.
    $lw3 = ''
    for ($x = 0; $x -lt $lVal.Count; $x++) { if ($lVal[$x] -eq 3) { $lw3 = [string]$lWord[$x]; break } }
    $lcop = if ($cntCops.Count -gt 0) { [string]$cntCops[0] } else { '' }
    $u8 = New-Object System.Text.UTF8Encoding($false)
    $lfa = Join-Path $sbx 'lfa.md'
    [System.IO.File]::WriteAllText($lfa, ($lw3 + $lcop + ': ' + $ENUM_S2[0] + ' a ' + $ENUM_S2[1] + " b`n"), $u8)
    $lfb = Join-Path $sbx 'lfb.md'
    [System.IO.File]::WriteAllText($lfb, ($lw3 + $lcop + ': ' + $ENUM_S2[0] + ' a ' + $ENUM_S2[1] + ' b ' +
        $ENUM_S2[2] + ' c ' + $ENUM_S2[3] + " d`n"), $u8)
    $lfc = Join-Path $sbx 'lfc.md'
    [System.IO.File]::WriteAllText($lfc, ($lw3 + $lcop + ": a b c`n"), $u8)
    $lfd = Join-Path $sbx 'lfd.md'
    [System.IO.File]::WriteAllText($lfd, ($lw3 + ' ' + $lcop + ': ' + $ENUM_S2[0] + ' a ' + $ENUM_S2[1] + ' b ' +
        $ENUM_S2[2] + " c`n"), $u8)
    function LBadCount($p) { return [string](@(EnumScanIn $p | Where-Object { $_.StartsWith('BAD ', [System.StringComparison]::Ordinal) })).Count }
    function LCandCount($p) { return [string](@(EnumScanIn $p | Where-Object { $_ -eq 'CAND' })).Count }
    Chk "L8: control -- a declaration that LOST an item is caught by the real verdict" (LBadCount $lfa) '1'
    Chk "L9: control -- a declaration that GAINED an item is caught by the real verdict" (LBadCount $lfb) '1'
    # (L10) Two negative controls -- without circled enumerators there is no candidate (the window is
    # that and nothing else), and a numeral NOT IMMEDIATELY followed by a declared copula is not a
    # declaration. That adjacency is what keeps the narrative form ("reduced from four to three", whose
    # particle is not in `count-copula:`) out of the candidate set.
    Chk "L10: negative controls -- no enumerator, and numeral detached from copula" `
        ("{0}/{1}" -f (LCandCount $lfc), (LCandCount $lfd)) '0/0'
    # (L11) THE WIDTH OF THE BLANK-LINE TEST. The window ends at a blank line, so "what counts as blank"
    # IS the window boundary, and if that width differs between the copies the same tree yields different
    # counts. The width is ASCII SPACE AND TAB only -- a line holding just U+00A0 is NOT blank. The
    # fixture puts two items after the declaration and a THIRD after a U+00A0 line: at the correct width
    # the window does not end there, it counts three, and reports NO mismatch; widen the width to every
    # Unicode space (which is exactly what .NET \s does) and the window ends there, counts two, and
    # reports ONE. The expectation is the compound <candidates>/<mismatches> so that a scan that died
    # altogether goes RED instead of passing as 0/0. Same layer as F17.
    $lfe = Join-Path $sbx 'lfe.md'
    [System.IO.File]::WriteAllText($lfe, ($lw3 + $lcop + ': ' + $ENUM_S2[0] + ' a ' + $ENUM_S2[1] +
        " b`n" + [string][char]0x00A0 + "`n" + $ENUM_S2[2] + " c`n"), $u8)
    Chk "L11: control -- a line holding only U+00A0 is NOT blank (window boundary width)" `
        ("{0}/{1}" -f (LCandCount $lfe), (LBadCount $lfe)) '1/0'
    # (L12) FALSE-POSITIVE-DIRECTION NEGATIVE CONTROL (M49 rework 1). Every case up to here asks "does
    # the check DIE"; not one asked "does the check OVER-BITE" -- and review blocker 1 came out of that
    # empty seat. This case is BIDIRECTIONAL: the first half asks that a numeral INSIDE A WORD is not a
    # marker (delete the boundary and it becomes 1, going red), the second that a numeral AFTER AN ASCII
    # SPACE still is one (narrow the boundary too far and it becomes 0, going red). The leading word is
    # DERIVED FROM THE MARKERS too -- no Korean literal enters this source.
    $lw4 = ''
    for ($x = 0; $x -lt $lVal.Count; $x++) { if ($lVal[$x] -eq 4) { $lw4 = [string]$lWord[$x]; break } }
    $lff = Join-Path $sbx 'lff.md'
    [System.IO.File]::WriteAllText($lff, ($lw4 + $lw3 + $lcop + ': ' + $ENUM_S2[0] + ' a ' + $ENUM_S2[1] + " b`n"), $u8)
    $lfg = Join-Path $sbx 'lfg.md'
    [System.IO.File]::WriteAllText($lfg, (' ' + $lw3 + $lcop + ': ' + $ENUM_S2[0] + ' a ' + $ENUM_S2[1] + ' b ' +
        $ENUM_S2[2] + " c`n"), $u8)
    Chk "L12: negative control -- numeral inside a word is not a marker / after a space it is" `
        ("{0}/{1}" -f (LCandCount $lff), (LCandCount $lfg)) '0/1'
    # (L13) A mismatch diagnostic NAMES THE MARKER IT MATCHED. A bare count assertion says nothing about
    # WHY it went red -- that is why M40 could not reproduce its mechanism locally (and why G2 prints the
    # duplicate anchor NAMES), and reproducing review blocker 1 showed the same gap. Not a third time.
    $lTokMark = ':' + $lw3 + $lcop + ':'
    Chk "L13: the mismatch diagnostic carries the marker it matched" `
        ([string](@(EnumScanIn $lfa | Where-Object { $_.StartsWith('BAD ', [System.StringComparison]::Ordinal) -and $_.Contains($lTokMark) })).Count) '1'

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

    # --- mutation declarations (M47) -- read by `tests/mutation` ------------
    # form: `# mutates: <file> :: <token> :: <stable case-label prefix> :: <caught|missed>`
    # Tokens are alphanumeric+hyphen only (no delimiter clash). The label is the prefix up to the
    # first interpolation and is unique among this copy's 161 labels (measured in M47-T01).
    # The sh copy carries the same declarations against its own (Korean) labels.
# mutates: docs/conventions.md :: declared-change-set :: D7: conventions declares :: caught
# mutates: docs/conventions.md :: mutation-negative-control-sentinel :: D7: conventions declares :: missed
