# tide-guard — PreToolUse hook
# .tide/phase가 release가 아닌 동안 git commit/tag/push를 차단한다.
# 상태 파일이 없으면 아무것도 차단하지 않는다 (tide 미사용 프로젝트에 영향 없음).

$inputJson = [Console]::In.ReadToEnd()

$cmd = $inputJson
$cwd = $null
try {
    $parsed = $inputJson | ConvertFrom-Json
    if ($parsed.tool_input -and $parsed.tool_input.command) { $cmd = $parsed.tool_input.command }
    if ($parsed.cwd) { $cwd = $parsed.cwd }
} catch {}

# 명령이 실제 실행되는 작업 디렉터리(cwd)의 git 레포 루트에서 .tide/phase를 읽는다.
# 1) 훅 입력 JSON의 cwd → 2) git -C $cwd rev-parse --show-toplevel →
# 3) 못 구하면 기존 동작으로 폴백($env:CLAUDE_PROJECT_DIR). 폴백해도 phase 없으면 무차단.
$root = $null
if ($cwd) {
    try {
        $top = & git -C $cwd rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $top) { $root = ($top | Select-Object -First 1).Trim() }
    } catch {}
}
if (-not $root) {
    $root = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { "." }
}

$phaseFile = Join-Path $root ".tide/phase"
if (-not (Test-Path $phaseFile)) { exit 0 }

$phase = (Get-Content $phaseFile -TotalCount 1).Trim()
if ($phase -eq "release") { exit 0 }

if ($cmd -match 'git[^&|;]*[^a-zA-Z](commit|tag|push)([^a-zA-Z]|$)') {
    [Console]::Error.WriteLine("tide-guard: '$phase' 단계에서는 git commit/tag/push가 차단됩니다. git 작업은 /tide:release 단계에서만 허용됩니다.")
    exit 2
}

exit 0
