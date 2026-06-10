# tide-guard — PreToolUse hook
# .tide/phase가 release가 아닌 동안 git commit/tag/push를 차단한다.
# 상태 파일이 없으면 아무것도 차단하지 않는다 (tide 미사용 프로젝트에 영향 없음).

$inputJson = [Console]::In.ReadToEnd()

$root = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { "." }
$phaseFile = Join-Path $root ".tide/phase"
if (-not (Test-Path $phaseFile)) { exit 0 }

$phase = (Get-Content $phaseFile -TotalCount 1).Trim()
if ($phase -eq "release") { exit 0 }

$cmd = $inputJson
try {
    $parsed = $inputJson | ConvertFrom-Json
    if ($parsed.tool_input -and $parsed.tool_input.command) { $cmd = $parsed.tool_input.command }
} catch {}

if ($cmd -match 'git[^&|;]*[^a-zA-Z](commit|tag|push)([^a-zA-Z]|$)') {
    [Console]::Error.WriteLine("tide-guard: git commit/tag/push is blocked during phase '$phase'. Git operations are allowed only in /tide-release.")
    exit 2
}

exit 0
