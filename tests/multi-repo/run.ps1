# tide multi-repo live test (Windows PowerShell 5.1) -- verifies repo-root-aware hooks\tide-guard.ps1
#
# Self-contained runner: creates 2 child repos under a temp parent, invokes the modified
# hooks\tide-guard.ps1 directly with synthetic hook-input JSON fixtures, asserts exit codes,
# then cleans up. The guard reads JSON from stdin, so we inject via Start-Process
# -RedirectStandardInput and read the real exit code via -PassThru -Wait .ExitCode.
#
# NOTE: blocked verbs (commit/tag/push) appear ONLY inside this script's fixture strings.
# The command line that LAUNCHES this script must contain no block pattern, so the active
# tide-guard does not block it. (English-only output: keeps this file BOM-independent;
# the guard itself carries the Korean message and is stored as UTF-8 with BOM.)
#
# Usage: & tests\multi-repo\run.ps1   (exit 0 if all pass, exit 1 if any fail)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$guard = Join-Path $repoRoot 'hooks\tide-guard.ps1'
if (-not (Test-Path $guard)) { Write-Host "guard script not found: $guard"; exit 1 }

$sbx = Join-Path ([System.IO.Path]::GetTempPath()) "tide-mr-live.$PID"
if (Test-Path $sbx) { Remove-Item -Recurse -Force $sbx }
New-Item -ItemType Directory -Path $sbx | Out-Null

$script:pass = 0
$script:fail = 0

function Invoke-Guard($cpd, $cwd, $cmd) {
    $obj = @{ tool_input = @{ command = $cmd } }
    if ($cwd) { $obj['cwd'] = $cwd }
    $fixture = Join-Path $sbx 'in.json'
    ($obj | ConvertTo-Json -Compress -Depth 5) | Set-Content -Path $fixture -Encoding utf8
    $out = Join-Path $sbx 'out.txt'; $err = Join-Path $sbx 'err.txt'
    $prev = $env:CLAUDE_PROJECT_DIR
    if ($cpd) { $env:CLAUDE_PROJECT_DIR = $cpd } else { Remove-Item Env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
    try {
        $p = Start-Process -FilePath 'powershell' `
            -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$guard `
            -RedirectStandardInput $fixture -RedirectStandardOutput $out -RedirectStandardError $err `
            -NoNewWindow -Wait -PassThru
        return $p.ExitCode
    } finally {
        if ($null -ne $prev) { $env:CLAUDE_PROJECT_DIR = $prev } else { Remove-Item Env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
    }
}

function Check($desc, $cpd, $cwd, $cmd, $want) {
    $got = Invoke-Guard $cpd $cwd $cmd
    if ($got -eq $want) {
        $script:pass++; Write-Host ("PASS  {0,-50} (exit {1})" -f $desc, $got)
    } else {
        $script:fail++; Write-Host ("FAIL  {0,-50} (got {1}, want {2})" -f $desc, $got, $want)
    }
}

try {
    Write-Host "# tide multi-repo live test (PowerShell)"
    Write-Host "# guard: $guard"
    Write-Host "# sandbox: $sbx`n"

    $A = Join-Path $sbx 'child-a'; $B = Join-Path $sbx 'child-b'; $PLAIN = Join-Path $sbx 'plain'
    New-Item -ItemType Directory -Path $A, $B, $PLAIN | Out-Null
    & git -C $A init -q | Out-Null
    & git -C $B init -q | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $A '.tide'), (Join-Path $B '.tide'), (Join-Path $A 'sub') | Out-Null
    $Aphase = Join-Path $A '.tide\phase'; $Bphase = Join-Path $B '.tide\phase'

    $BLOCK = 'git commit -m x'
    $TAG = 'git tag v1.0.0'
    $SAFE = 'git status'

    # 1: non-release child blocks
    'impl' | Set-Content $Aphase -Encoding utf8
    Check "A(impl) blocks commit" $sbx $A $BLOCK 2
    Check "A(impl) blocks tag" $sbx $A $TAG 2
    # 2: release child allows
    'release' | Set-Content $Aphase -Encoding utf8
    Check "A(release) allows commit" $sbx $A $BLOCK 0
    # 3: per-repo isolation
    'impl' | Set-Content $Bphase -Encoding utf8
    Check "B(impl) still blocked while A=release" $sbx $B $BLOCK 2
    # 4: subdir cwd -> repo root resolution
    'impl' | Set-Content $Aphase -Encoding utf8
    Check "A\sub(impl) blocked (subdir->root)" $sbx (Join-Path $A 'sub') $BLOCK 2
    # 5: safe command always allowed
    Check "A(impl) git status allowed" $sbx $A $SAFE 0
    # 6: fallback -- no cwd + CPD=A(impl)
    Check "no cwd -> CPD(A,impl) fallback blocks" $A $null $BLOCK 2
    # 7: fallback -- non-repo + no phase
    Check "non-repo cwd + no phase -> allow" $PLAIN $PLAIN $BLOCK 0
    # 8: single-repo regression
    'release' | Set-Content $Aphase -Encoding utf8
    Check "single-repo: A(release) root cwd allows" $A $A $BLOCK 0
    'impl' | Set-Content $Aphase -Encoding utf8
    Check "single-repo: A(impl) root cwd blocks" $A $A $BLOCK 2

    Write-Host "`n# result: PASS=$($script:pass) FAIL=$($script:fail)"
}
finally {
    Remove-Item -Recurse -Force $sbx -ErrorAction SilentlyContinue
}

if ($script:fail -ne 0) { exit 1 }
Write-Host "# all scenarios passed -- repo-root aware / isolation / fallback confirmed (ps1)"
exit 0
