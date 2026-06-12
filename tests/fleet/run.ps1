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

# --- discovery reference: immediate children, skip hidden (dot) dirs, git repo AND tide artifacts ---
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

# --- classification reference: /tide:status next-command judgment (5 positions, ASCII labels) ---
function Classify($r) {
    $ms = Get-ChildItem (Join-Path $r 'docs\milestones') -Filter 'M*.md' -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -Last 1
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

# --- .tide/deps parse reference: one sibling repo name per line, skip #-comments / blanks, trim ---
# M17: strip a leading UTF-8 BOM (EF BB BF) before parsing; a dep line may carry an optional
#   `>= <version>` constraint -> `<name>[ >= <version>]`. Only `>=` supported; other operators
#   leave the constraint ignored (name only). ReadDeps emits names only (for topo sort); the
#   version constraint is queried separately via DepRequiredVersion.
function StripBom($s) {
    if ($null -ne $s -and $s.Length -gt 0 -and [int]$s[0] -eq 0xFEFF) { return $s.Substring(1) }
    return $s
}
# read raw lines with explicit BOM strip on the first line (independent of Get-Content's own handling)
function DepLines($f) {
    $lines = @(Get-Content $f)
    if ($lines.Count -gt 0) { $lines[0] = StripBom $lines[0] }
    return $lines
}
# strip a trailing `[<>=]...` operator+version clause, return the bare name
function DepName($line) {
    return ($line -replace '\s*[<>=].*$', '').Trim()
}
function ReadDeps($repoDir) {
    $f = Join-Path $repoDir '.tide\deps'
    if (-not (Test-Path $f)) { return @() }
    $out = @()
    foreach ($line in (DepLines $f)) {
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }   # blank / comment
        $out += (DepName $t)
    }
    return $out
}
# required version (>= only) for a given dep name; '' if none or unsupported operator
function DepRequiredVersion($repoDir, $depName) {
    $f = Join-Path $repoDir '.tide\deps'
    if (-not (Test-Path $f)) { return '' }
    foreach ($line in (DepLines $f)) {
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        if ((DepName $t) -ne $depName) { continue }
        $m = [regex]::Match($t, '>=\s*(\S+)')                 # only `>=`; other ops -> no match
        if ($m.Success) { return $m.Groups[1].Value }
        return ''
    }
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
# semver compare (major.minor.patch numeric, leading v optional): satisfied | violation | skip
function SemverGe($current, $required) {
    $cur = $current -replace '^v', ''
    $req = $required -replace '^v', ''
    $rx = '^\d+\.\d+\.\d+$'
    if ($cur -notmatch $rx -or $req -notmatch $rx) { return 'skip' }
    $c = $cur.Split('.'); $r = $req.Split('.')
    for ($i = 0; $i -lt 3; $i++) {
        $ci = [int]$c[$i]; $ri = [int]$r[$i]
        if ($ci -ne $ri) { if ($ci -gt $ri) { return 'satisfied' } else { return 'violation' } }
    }
    return 'satisfied'
}
# contract check: satisfied | violation | skip | none
#   none = no version constraint (name dep only); skip = version unparseable
function CheckContract($parent, $repo, $dep) {
    $req = DepRequiredVersion (Join-Path $parent $repo) $dep
    if ($req -eq '') { return 'none' }
    $cur = ReadVersion (Join-Path $parent $dep)
    if ($cur -eq '') { return 'skip' }
    return (SemverGe $cur $req)
}

# --- dependency-aware order reference: topological sort (depended-upon first) + cycle detection ---
# Names not in the discovered set are ignored (safe side). Unconsumed nodes -> cycle -> sentinel CYCLE.
function TopoSort($parent) {
    $nodes = @(Discover $parent)                              # discovered repos (sorted)
    if ($nodes.Count -eq 0) { return '' }

    # edges: keep only deps that are in the discovered set (ignore unknown names)
    $edges = @{}
    foreach ($r in $nodes) {
        $kept = @()
        foreach ($dep in (ReadDeps (Join-Path $parent $r))) {
            if ($nodes -contains $dep) { $kept += $dep }
        }
        $edges[$r] = $kept
    }

    $remaining = New-Object System.Collections.ArrayList
    [void]$remaining.AddRange($nodes)
    $order = @()
    # Kahn variant: emit nodes whose deps are all already emitted; no progress -> cycle.
    while ($remaining.Count -gt 0) {
        $progressed = $false
        $next = New-Object System.Collections.ArrayList
        foreach ($r in $remaining) {
            $ready = $true
            foreach ($dep in $edges[$r]) {
                if ($remaining -contains $dep) { $ready = $false; break }  # dep not yet emitted
            }
            if ($ready) { $order += $r; $progressed = $true } else { [void]$next.Add($r) }
        }
        if (-not $progressed) { return 'CYCLE' }
        $remaining = $next
    }
    return ($order -join ' ')
}

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

    # --- contract version comparison (M17): `>= version` constraint + semver + upstream-behind ---
    # auth (version file 0.2.0) <- dependants with different constraints / operators.
    $CT = Join-Path $sbx 'contract'; New-Item -ItemType Directory -Force -Path $CT | Out-Null
    MkRepo (Join-Path $CT 'auth'); W (Join-Path $CT 'auth\package.json') '{ "version": "0.2.0" }'  # current 0.2.0
    MkRepo (Join-Path $CT 'ok');      W (Join-Path $CT 'ok\.tide\deps')      'auth >= v0.2.0'   # satisfied
    MkRepo (Join-Path $CT 'behind');  W (Join-Path $CT 'behind\.tide\deps')  'auth >= v0.3.0'   # violation
    MkRepo (Join-Path $CT 'otherop'); W (Join-Path $CT 'otherop\.tide\deps') 'auth > v0.1.0'    # other op -> ignored
    MkRepo (Join-Path $CT 'badver');  W (Join-Path $CT 'badver\.tide\deps')  'auth >= banana'   # unparseable -> skip

    Chk "contract satisfied: auth>=0.2.0, current 0.2.0"        (CheckContract $CT 'ok' 'auth')      'satisfied'
    Chk "contract violation: auth>=0.3.0, current 0.2.0 (upstream behind)" (CheckContract $CT 'behind' 'auth') 'violation'
    Chk "other operator ignored: auth > v0.1.0 (not a violation)" (CheckContract $CT 'otherop' 'auth') 'none'
    Chk "unparseable version: auth>=banana (compare skipped)"   (CheckContract $CT 'badver' 'auth')  'skip'
    # constraint lines still topo-sort by name only (version does not break ordering)
    $ctord = TopoSort $CT
    $cia = IdxOf $ctord 'auth'; $cib = IdxOf $ctord 'behind'
    Chk "contract: version line keeps name dep in topo (auth first)" $(if ($cia -ge 0 -and $cib -ge 0 -and $cia -lt $cib) { 'yes' } else { 'no' }) 'yes'

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
Write-Host "# fleet discovery / 5-position classify / 1:1 summary / hidden-skip / degrade / topo-sort / cycle-fallback / contract-version / BOM-tolerance confirmed"
exit 0
