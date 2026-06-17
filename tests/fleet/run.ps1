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

# Resolve repo root from the script location; dot-source the shared discovery/topo libraries.
$ROOT = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
# source order: discover -> deps -> toposort (TopoSort calls ReadDeps, so deps must come first).
. (Join-Path $ROOT 'tests\lib\discover.ps1')
. (Join-Path $ROOT 'tests\lib\deps.ps1')
. (Join-Path $ROOT 'tests\lib\toposort.ps1')

$OK  = [string]([char]0xAC00 + [char]0xB2A5)   # ga-neung U+AC00 U+B2A5 (release-able)
$BAD = [string]([char]0xBD88 + [char]0xAC00)   # bul-ga  U+BD88 U+AC00 (blocked)

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

# IsTideRepo/Discover: tests\lib\discover.ps1 (single source)

# --- classification reference: /tide:status next-command judgment (5 positions, ASCII labels) ---
function Classify($r) {
    # natural sort on the numeric milestone index (M10 > M9, multi-digit safe; sh uses `sort -V`)
    $ms = Get-ChildItem (Join-Path $r 'docs\milestones') -Filter 'M*.md' -ErrorAction SilentlyContinue |
        Sort-Object { [int]([regex]::Match($_.BaseName, '\d+').Value) } | Select-Object -Last 1
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

# ReadDeps/StripBom/DepLines/DepName: tests\lib\deps.ps1 (single source; dot-sourced above).
# Contract-comparison-only functions below (DepRequired* / Semver* / EvalOp / CheckContract) are
# out of extraction scope and stay local; they reuse DepLines/DepName from deps.ps1.

# required constraint (operator + version) for a given dep name; '' if no constraint.
# M20: full operators -> `>=`, `>`, `=`(`==`), `<=`, `<`. Returns "<op> <ver>" (single string).
#   op = 2nd whitespace token, ver = 3rd; an unknown/absent 2nd token -> '' (none, name dep only).
function DepRequiredConstraint($repoDir, $depName) {
    $f = Join-Path $repoDir '.tide\deps'
    if (-not (Test-Path $f)) { return '' }
    foreach ($line in (DepLines $f)) {
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        if ((DepName $t) -ne $depName) { continue }
        $tok = $t -split '\s+'
        if ($tok.Count -ge 3 -and (@('>=','<=','==','=','>','<') -contains $tok[1])) {
            return ($tok[1] + ' ' + $tok[2])
        }
        return ''   # name-only or unknown operator -> none
    }
    return ''
}
# back-compat alias: emit version only when the constraint is `>=` (keeps prior callers/expectations)
function DepRequiredVersion($repoDir, $depName) {
    $c = DepRequiredConstraint $repoDir $depName
    if ($c -like '>= *') { return $c.Substring(3) }
    return ''
}
# current version of a repo (package.json "version"); '' if absent
function ReadVersion($repoDir) {
    $f = Join-Path $repoDir 'package.json'
    if (-not (Test-Path $f)) { return '' }
    $m = [regex]::Match((Get-Content $f -Raw), '"version"\s*:\s*"([^"]*)"')
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
}
# semver 3-way compare (major.minor.patch numeric, leading v optional): gt | lt | eq | skip
function SemverCmp($current, $required) {
    $cur = $current -replace '^v', ''
    $req = $required -replace '^v', ''
    $rx = '^\d+\.\d+\.\d+$'
    if ($cur -notmatch $rx -or $req -notmatch $rx) { return 'skip' }
    $c = $cur.Split('.'); $r = $req.Split('.')
    for ($i = 0; $i -lt 3; $i++) {
        $ci = [int]$c[$i]; $ri = [int]$r[$i]
        if ($ci -ne $ri) { if ($ci -gt $ri) { return 'gt' } else { return 'lt' } }
    }
    return 'eq'
}
# operator eval: <op> <current> <required> -> satisfied | violation | skip | none
#   supported: >= > = == <= < . Unknown operator -> none (ignored, not a violation).
#   non-standard version (unparseable) -> skip.
function EvalOp($op, $current, $required) {
    $c = SemverCmp $current $required
    if ($c -eq 'skip') { return 'skip' }
    switch ($op) {
        '>='    { if ($c -eq 'gt' -or $c -eq 'eq') { return 'satisfied' } else { return 'violation' } }
        '>'     { if ($c -eq 'gt')                 { return 'satisfied' } else { return 'violation' } }
        '='     { if ($c -eq 'eq')                 { return 'satisfied' } else { return 'violation' } }
        '=='    { if ($c -eq 'eq')                 { return 'satisfied' } else { return 'violation' } }
        '<='    { if ($c -eq 'lt' -or $c -eq 'eq') { return 'satisfied' } else { return 'violation' } }
        '<'     { if ($c -eq 'lt')                 { return 'satisfied' } else { return 'violation' } }
        default { return 'none' }                  # unknown operator -> ignore
    }
}
# back-compat alias: 2-arg `>=` semver compare (satisfied | violation | skip)
function SemverGe($current, $required) {
    return (EvalOp '>=' $current $required)
}
# contract check: satisfied | violation | skip | none
#   none = no version constraint / unknown operator (name dep only); skip = version unparseable
function CheckContract($parent, $repo, $dep) {
    $c = DepRequiredConstraint (Join-Path $parent $repo) $dep
    if ($c -eq '') { return 'none' }
    $op = $c.Split(' ')[0]; $req = $c.Substring($op.Length + 1)
    $cur = ReadVersion (Join-Path $parent $dep)
    if ($cur -eq '') { return 'skip' }
    return (EvalOp $op $cur $req)
}

# TopoSort: tests\lib\toposort.ps1 (single source; ReadDeps defined by tests\lib\deps.ps1, sourced first)

# index of <name> in a space-joined order string (-1 if absent)
function IdxOf($orderStr, $name) {
    $arr = @($orderStr -split '\s+' | Where-Object { $_ -ne '' })
    for ($i = 0; $i -lt $arr.Count; $i++) { if ($arr[$i] -eq $name) { return $i } }
    return -1
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

    # --- multi-digit milestone (M10+) fixture (M14 minor#4): natural sort picks M10 over M9/M2 ---
    # With M2/M9/M10 present, the latest milestone must be M10 (a lexical sort would wrongly pick M9).
    $MD = Join-Path $sbx 'multidigit'; GitInit $MD
    W (Join-Path $MD 'docs\milestones\M2.md')  '# M2'
    W (Join-Path $MD 'docs\milestones\M9.md')  '# M9'
    W (Join-Path $MD 'docs\milestones\M10.md') '# M10'
    $latest = Get-ChildItem (Join-Path $MD 'docs\milestones') -Filter 'M*.md' |
        Sort-Object { [int]([regex]::Match($_.BaseName, '\d+').Value) } | Select-Object -Last 1
    Chk "multi-digit: latest milestone = M10 (not M9)" $latest.BaseName 'M10'
    # classification keys off the latest (M10): only M10-impl present, no M10-review -> review-pending
    W (Join-Path $MD 'docs\reports\M10-impl.md') '# M10 impl'
    Chk "multi-digit: classify keyed on M10 (review-pending)" (Classify $MD) 'review-pending'
    # even with completed M9 artifacts, M10 is latest so classification is unaffected
    W (Join-Path $MD 'docs\reports\M9-impl.md') '# M9 impl'
    W (Join-Path $MD 'docs\reports\M9-review.md') ("## release verdict`n`n**" + $OK + "**`n")
    Chk "multi-digit: M9-complete artifacts ignored, classify is M10 (review-pending)" (Classify $MD) 'review-pending'

    # --- dependency-aware order fixtures/scenarios (M16: .tide/deps topo sort / fallback) ---

    function MkRepo($d) { GitInit $d; W (Join-Path $d 'docs\milestones\M1.md') '# M1' }

    # topo: auth(no deps) <- orders(->auth) <- gateway(->auth) <- solo(undeclared independent)
    $TP = Join-Path $sbx 'topo'; New-Item -ItemType Directory -Force -Path $TP | Out-Null
    MkRepo (Join-Path $TP 'auth')
    MkRepo (Join-Path $TP 'orders')
    # trim + unknown-name ignore in one file: leading/trailing spaces around auth, plus non-existent 'nowhere'
    W (Join-Path $TP 'orders\.tide\deps') "  auth  `nnowhere"
    MkRepo (Join-Path $TP 'gateway')
    W (Join-Path $TP 'gateway\.tide\deps') "# dep`nauth"        # comment + dependency
    MkRepo (Join-Path $TP 'solo')                                # undeclared independent

    $tord = TopoSort $TP
    $ia = IdxOf $tord 'auth'; $io = IdxOf $tord 'orders'; $ig = IdxOf $tord 'gateway'; $is = IdxOf $tord 'solo'
    $nodeCount = @($tord -split '\s+' | Where-Object { $_ -ne '' }).Count
    Chk "topo: not a cycle (not CYCLE)" $(if ($tord -eq 'CYCLE') { 'yes' } else { 'no' }) 'no'
    Chk "topo: auth before orders"  $(if ($ia -ge 0 -and $io -ge 0 -and $ia -lt $io) { 'yes' } else { 'no' }) 'yes'
    Chk "topo: auth before gateway" $(if ($ia -ge 0 -and $ig -ge 0 -and $ia -lt $ig) { 'yes' } else { 'no' }) 'yes'
    Chk "undeclared independent: solo present in order" $(if ($is -ge 0) { 'yes' } else { 'no' }) 'yes'
    Chk "unknown name ignored: order has 4 nodes (no crash)" "$nodeCount" '4'

    # cycle fallback: a->b, b->a -> CYCLE sentinel
    $CY = Join-Path $sbx 'cycle'; New-Item -ItemType Directory -Force -Path $CY | Out-Null
    MkRepo (Join-Path $CY 'a'); W (Join-Path $CY 'a\.tide\deps') 'b'
    MkRepo (Join-Path $CY 'b'); W (Join-Path $CY 'b\.tide\deps') 'a'
    Chk "cycle fallback: a<->b cycle detected (CYCLE)" (TopoSort $CY) 'CYCLE'

    # --- contract version comparison (M17 -> M20): full operators + semver + upstream-behind ---
    # auth (version file 0.2.0) <- dependants with different constraints / operators.
    # M20: `>=`, `>`, `=`(`==`), `<=`, `<` each satisfied/violation; unknown op -> ignored (none);
    #      non-standard version -> skip. Existing `>=` scenarios retained.
    $CT = Join-Path $sbx 'contract'; New-Item -ItemType Directory -Force -Path $CT | Out-Null
    MkRepo (Join-Path $CT 'auth'); W (Join-Path $CT 'auth\package.json') '{ "version": "0.2.0" }'  # current 0.2.0
    function MkDep($name, $line) { MkRepo (Join-Path $CT $name); W (Join-Path $CT "$name\.tide\deps") $line }
    MkDep 'ge_ok'   'auth >= v0.2.0'   # >= satisfied (0.2.0 >= 0.2.0)
    MkDep 'ge_bad'  'auth >= v0.3.0'   # >= violation (upstream behind)
    MkDep 'gt_ok'   'auth > v0.1.0'    # >  satisfied (0.2.0 > 0.1.0)
    MkDep 'gt_bad'  'auth > v0.2.0'    # >  violation (0.2.0 > 0.2.0)
    MkDep 'eq_ok'   'auth = v0.2.0'    # =  satisfied
    MkDep 'eq_bad'  'auth = v0.3.0'    # =  violation
    MkDep 'eqeq_ok' 'auth == v0.2.0'   # == synonym satisfied
    MkDep 'eqeq_bad' 'auth == v0.3.0'  # == synonym violation
    MkDep 'le_ok'   'auth <= v0.2.0'   # <= satisfied (0.2.0 <= 0.2.0)
    MkDep 'le_bad'  'auth <= v0.1.0'   # <= violation
    MkDep 'lt_ok'   'auth < v0.3.0'    # <  satisfied (0.2.0 < 0.3.0)
    MkDep 'lt_bad'  'auth < v0.2.0'    # <  violation (0.2.0 < 0.2.0)
    MkDep 'unkop'   'auth ~> v0.1.0'   # unknown operator (with symbol) -> ignored (none), name kept
    MkDep 'unksym'  'auth ~ v0.1.0'    # unknown operator (no symbol)   -> ignored (none), name kept
    MkDep 'badver'  'auth >= banana'   # non-standard version -> skip

    Chk "contract >= satisfied: auth>=0.2.0, current 0.2.0"   (CheckContract $CT 'ge_ok' 'auth')   'satisfied'
    Chk "contract >= violation: auth>=0.3.0 (upstream behind)" (CheckContract $CT 'ge_bad' 'auth') 'violation'
    Chk "contract > satisfied: auth>0.1.0, current 0.2.0"     (CheckContract $CT 'gt_ok' 'auth')   'satisfied'
    Chk "contract > violation: auth>0.2.0, current 0.2.0"     (CheckContract $CT 'gt_bad' 'auth')  'violation'
    Chk "contract = satisfied: auth=0.2.0, current 0.2.0"     (CheckContract $CT 'eq_ok' 'auth')   'satisfied'
    Chk "contract = violation: auth=0.3.0, current 0.2.0"     (CheckContract $CT 'eq_bad' 'auth')  'violation'
    Chk "contract == satisfied: auth==0.2.0 (= synonym)"      (CheckContract $CT 'eqeq_ok' 'auth') 'satisfied'
    Chk "contract == violation: auth==0.3.0, current 0.2.0"   (CheckContract $CT 'eqeq_bad' 'auth') 'violation'
    Chk "contract <= satisfied: auth<=0.2.0, current 0.2.0"   (CheckContract $CT 'le_ok' 'auth')   'satisfied'
    Chk "contract <= violation: auth<=0.1.0, current 0.2.0"   (CheckContract $CT 'le_bad' 'auth')  'violation'
    Chk "contract < satisfied: auth<0.3.0, current 0.2.0"     (CheckContract $CT 'lt_ok' 'auth')   'satisfied'
    Chk "contract < violation: auth<0.2.0, current 0.2.0"     (CheckContract $CT 'lt_bad' 'auth')  'violation'
    Chk "unknown operator ignored: auth ~> v0.1.0 (not a violation)" (CheckContract $CT 'unkop' 'auth') 'none'
    Chk "unknown operator ignored: auth ~ v0.1.0 (no symbol, not a violation)" (CheckContract $CT 'unksym' 'auth') 'none'
    # unknown operator still keeps the name dep -> ReadDeps must emit the bare name (edge not dropped)
    Chk "unknown op (~>) keeps name dep: ReadDeps=auth" ((ReadDeps (Join-Path $CT 'unkop')) -join ',') 'auth'
    Chk "unknown op (~) keeps name dep: ReadDeps=auth"  ((ReadDeps (Join-Path $CT 'unksym')) -join ',') 'auth'
    Chk "non-standard version: auth>=banana (compare skipped)" (CheckContract $CT 'badver' 'auth') 'skip'
    # constraint lines still topo-sort by name only (version does not break ordering)
    $ctord = TopoSort $CT
    $cia = IdxOf $ctord 'auth'; $cib = IdxOf $ctord 'ge_bad'
    Chk "contract: version line keeps name dep in topo (auth first)" $(if ($cia -ge 0 -and $cib -ge 0 -and $cia -lt $cib) { 'yes' } else { 'no' }) 'yes'
    # unknown-operator lines keep their topo edge too: unkop/unksym after auth (auth dep retained)
    $ciu = IdxOf $ctord 'unkop'; $cis = IdxOf $ctord 'unksym'
    Chk "unknown op (~>) keeps topo edge (auth before unkop)" $(if ($cia -ge 0 -and $ciu -ge 0 -and $cia -lt $ciu) { 'yes' } else { 'no' }) 'yes'
    Chk "unknown op (~) keeps topo edge (auth before unksym)" $(if ($cia -ge 0 -and $cis -ge 0 -and $cia -lt $cis) { 'yes' } else { 'no' }) 'yes'

    # --- BOM tolerance (M17): a .tide/deps written WITH a leading UTF-8 BOM parses correctly ---
    # Set-Content -Encoding utf8 (the W helper) emits a BOM in PS 5.1, so these files carry a BOM.
    # First line a `#` comment, second a dependency -> comment skipped + dep name matched.
    $BM = Join-Path $sbx 'bom'; New-Item -ItemType Directory -Force -Path $BM | Out-Null
    MkRepo (Join-Path $BM 'auth'); W (Join-Path $BM 'auth\package.json') '{ "version": "0.2.0" }'
    MkRepo (Join-Path $BM 'svc'); W (Join-Path $BM 'svc\.tide\deps') "# dep file`nauth >= v0.2.0"  # BOM + comment + dep
    Chk "BOM tolerance: BOM+comment first line skipped, dep parsed" ((ReadDeps (Join-Path $BM 'svc')) -join ',') 'auth'
    Chk "BOM tolerance: contract compare on BOM'd line (satisfied)" (CheckContract $BM 'svc' 'auth') 'satisfied'
    # first line itself a BOM+dependency name (no comment) -> BOM does not break name match
    $BM2 = Join-Path $sbx 'bom2'; New-Item -ItemType Directory -Force -Path $BM2 | Out-Null
    MkRepo (Join-Path $BM2 'auth')
    MkRepo (Join-Path $BM2 'svc'); W (Join-Path $BM2 'svc\.tide\deps') 'auth'   # BOM + dep name (no comment)
    Chk "BOM tolerance: BOM+dep-name first line matches" ((ReadDeps (Join-Path $BM2 'svc')) -join ',') 'auth'

    Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail)"
}
finally {
    Remove-Item -Recurse -Force $sbx -ErrorAction SilentlyContinue
}

if ($script:fail -ne 0) { exit 1 }
Write-Host "# fleet discovery / 5-position classify / 1:1 summary / hidden-skip / degrade / multi-digit-milestone / topo-sort / cycle-fallback / full-operator contract / BOM-tolerance confirmed"
exit 0
