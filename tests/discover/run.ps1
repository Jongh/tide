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
# Part G (M34) enforces the REFERENCES BETWEEN documents -- it extracts the citations in the living docs
# and checks each one against the conventions ## / ### anchors (plus empty-extraction, duplicate-name and
# wrapped-citation controls). Single source: the "cross-reference integrity" clause of the same section.
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

    # === Part D -- cross-branch collaboration safety (M31) declaration consistency ==========
    # (M31) Same class as Part B/C -- bind the conventions single source and the skill that wires it.
    # The two checks (release coverage / milestone number pre-warning) are prompt discipline, so runtime
    # firing is not harness-enforceable, but the conventions<->skill DECLARATION consistency is. Enforced
    # via ASCII mechanism tokens (git read commands), keeping this source ASCII-only.
    # (D1) release coverage check: 'git diff --name-only' in BOTH conventions and release SKILL;
    # (D2) milestone number pre-warning: 'git log --all' in BOTH conventions and milestone SKILL.

    $REL_SKILL = Join-Path $ROOT 'skills\release\SKILL.md'
    $MS_SKILL  = Join-Path $ROOT 'skills\milestone\SKILL.md'
    $COV_TOK  = 'git diff --name-only'
    $WARN_TOK = 'git log --all'

    Chk "D1: conventions declares coverage check ($COV_TOK)"      (HasToken $CONV $COV_TOK)      'yes'
    Chk "D1: release SKILL wires coverage check"                  (HasToken $REL_SKILL $COV_TOK) 'yes'
    Chk "D2: conventions declares number pre-warning ($WARN_TOK)" (HasToken $CONV $WARN_TOK)     'yes'
    Chk "D2: milestone SKILL wires number pre-warning"            (HasToken $MS_SKILL $WARN_TOK) 'yes'

    # cross control: each mechanism must be ABSENT from the opposite skill (token discriminates).
    Chk "D: control -- milestone SKILL has no coverage token"  (HasToken $MS_SKILL $COV_TOK)  'no'
    Chk "D: control -- release SKILL has no number-warn token" (HasToken $REL_SKILL $WARN_TOK) 'no'

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

    $REV_SKILL  = Join-Path $ROOT 'skills\review\SKILL.md'
    $REV_TPL    = Join-Path $ROOT 'skills\review\template.md'
    $REFUT_TOK    = 'refutation'
    $MEAS_TOK     = 'in-review'
    $REWORK_TOK   = 'rework'
    $REVERIFY_TOK = 're-verify'

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
            if ($line.StartsWith('|') -and ($line -match $namePat) -and ($line -match $tokPat)) { return 'yes' }
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

    # === Part G -- cross-reference integrity (M34) ==========================
    # (M34) Part F enforces what a document says ABOUT ITSELF; Part G enforces the REFERENCES BETWEEN
    # documents -- the layer that had no guard at all (two citations really did point at names that do
    # not exist as headings, and nothing caught it). Single source: conventions "cross-reference
    # integrity".
    # (G1) EXTRACT citations (quoted spans on lines that mention the conventions file name) from the
    #      living docs and assert every one exists in the conventions heading set (## / ###, whitespace
    #      removed for comparison).
    # (G2) controls: zero extracted citations or anchors -> FAIL (empty-pass guard); a bogus name must be
    #      absent; heading names must be unique after normalization.
    # Data-driven, so no Korean literal enters this source (ASCII-only rule preserved) -- same shape as F2.

    # living docs -- docs/milestones/* and docs/reports/* are historical records and NOT targets
    # (the docs/*.md glob does not descend into subdirectories, so they drop out naturally).
    # NOTE: skip dot-directories explicitly. A POSIX glob ('skills/*/*.md') never matches them, but
    # Get-ChildItem -Directory DOES list '.foo' on Windows (a leading dot is not the Hidden attribute),
    # so without this filter the two shells would scan different file sets and could disagree.
    function LivingDocs() {
        $out = @()
        foreach ($d in (Get-ChildItem (Join-Path $ROOT 'skills') -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith('.') })) {
            $out += @(Get-ChildItem $d.FullName -Filter '*.md' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        }
        $out += @(Get-ChildItem (Join-Path $ROOT 'docs') -Filter '*.md' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        $out += @($README)
        $out += @(Get-ChildItem (Join-Path $ROOT 'site\docs') -Filter '*.md' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        foreach ($d in (Get-ChildItem (Join-Path $ROOT 'tests') -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith('.') })) {
            $r = Join-Path $d.FullName 'README.md'
            if (Test-Path $r) { $out += @($r) }
        }
        return @($out | Where-Object { Test-Path $_ })
    }

    # anchor set -- ## / ### headings only, spaces removed (so "A - B" and "A-B" compare equal).
    function AnchorSet() {
        $raw = ReadUtf8 $CONV
        if ($null -eq $raw) { return @() }
        $out = @()
        foreach ($line in ($raw -split "`r?`n")) {
            if ($line -match '^#{2,3} ') { $out += (($line -replace '^#+ ', '') -replace ' ', '') }
        }
        return $out
    }

    # citation candidate lines -- lines naming the conventions file. Snippet-include directive lines
    # ('8<--') are not citations.
    function CitationLines() {
        $out = @()
        foreach ($f in (LivingDocs)) {
            $raw = ReadUtf8 $f
            if ($null -eq $raw) { continue }
            foreach ($line in ($raw -split "`r?`n")) {
                if (-not $line.Contains('conventions.md')) { continue }
                if ($line.Contains('8<--')) { continue }
                $out += $line
            }
        }
        return $out
    }

    # ordinal (case-sensitive) sets so both shells judge identically -- PowerShell's -contains and
    # hashtable keys are case-INsensitive by default, which would diverge from grep -x.
    $gAnchors = @(AnchorSet)
    $gLines   = @(CitationLines)
    $gCites   = @()
    foreach ($line in $gLines) {
        foreach ($m in [regex]::Matches($line, '"([^"]*)"')) {
            $q = $m.Groups[1].Value
            if ($q -match '[{}]') { continue }        # skeleton placeholder, not a citation
            $q = ($q -replace ' ', '')
            if ($q.Length -eq 0) { continue }         # blank span -- the shell drops it as an empty line
            $gCites += $q
        }
    }
    # unterminated quote on a candidate line = the citation wrapped to the next line and would be
    # silently skipped by line-wise extraction (see G3).
    $gOdd = 0
    foreach ($line in $gLines) { if ((([regex]::Matches($line, '"')).Count % 2) -eq 1) { $gOdd++ } }

    $aset = New-Object 'System.Collections.Generic.HashSet[string]'
    $dset = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($a in $gAnchors) { if (-not $aset.Add($a)) { [void]$dset.Add($a) } }
    $gMiss = 0
    foreach ($c in $gCites) { if (-not $aset.Contains($c)) { $gMiss++ } }

    Chk "G1: every live citation resolves to a real anchor" ([string]$gMiss) '0'
    Chk "G2: citation extraction positive control (>0)" $(if ($gCites.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "G2: anchor extraction positive control (>0)"   $(if ($gAnchors.Count -gt 0) { 'ok' } else { 'no' }) 'ok'
    Chk "G2: control -- bogus anchor name (bogus-section) absent" $(if ($aset.Contains('bogus-section')) { 'yes' } else { 'no' }) 'no'
    Chk "G2: anchor names unique after normalization" ([string]$dset.Count) '0'
    Chk "G3: citation lines have balanced quotes (no wrapped citation)" ([string]$gOdd) '0'

    function DeclaredCases() {
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

    Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail) (actual command skills N=$N)"
}
finally {
    Remove-Item -Recurse -Force $sbx -ErrorAction SilentlyContinue
}

if ($script:fail -ne 0) { exit 1 }
Write-Host "# discover detection threshold (>=2->hint / <2->none / single-repo->none / hidden-not-counted) + single-source freeze (B1 count / B2 site shell / B3 catalog completeness, canonical=docs/commands.md) + declaration consistency (C1 four statuses x three files + absence control / C2 baseline x three templates / D cross-branch coverage+number-warn conventions<->skill / E review verification discipline refutation+metrics+rework conventions<->skill<->template plus metrics-line skeleton format plus re-verify declaration plus cross and negative controls / F document self-description = role-anchor extraction, canonical-row presence, consumer propagation plus case-count self-consistency / G cross-reference integrity = citation extraction vs real anchors plus empty-extraction, name-uniqueness and wrapped-citation controls) confirmed"
exit 0
