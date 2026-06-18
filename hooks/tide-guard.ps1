# tide-guard — PreToolUse hook
# .tide/phase가 release가 아닌 동안 git commit/tag/push를 차단한다.
# 상태 파일이 없으면 아무것도 차단하지 않는다 (tide 미사용 프로젝트에 영향 없음).

$inputJson = [Console]::In.ReadToEnd()

# 입력 견고화 — 선두 UTF-8 BOM 제거. PS 5.1 ConvertFrom-Json은 선두 BOM에서 throw하므로,
# 일부 환경(`Set-Content -Encoding utf8` 등)이 stdin 선두에 BOM을 붙여도 견디도록 strip한다.
# UTF-8로 디코드된 BOM(U+FEFF)과 오디코드된 3바이트(U+00EF U+00BB U+00BF) 둘 다 방어. hook은
# 자기완결이어야 하므로(외부 source 금지) 여기서 최소 strip을 직접 둔다. 판정은 불변(견고화만).
if ($inputJson) { $inputJson = $inputJson -replace '^(\uFEFF|\u00EF\u00BB\u00BF)', '' }

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
