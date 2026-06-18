# tide-guard — PreToolUse hook
# .tide/phase가 release가 아닌 동안 git commit/tag/push를 차단한다.
# 상태 파일이 없으면 아무것도 차단하지 않는다 (tide 미사용 프로젝트에 영향 없음).

$inputJson = [Console]::In.ReadToEnd()

# 입력 견고화 — 선두 UTF-8 BOM 제거. PS 5.1 ConvertFrom-Json은 선두 BOM에서 throw하므로,
# 일부 환경(`Set-Content -Encoding utf8` 등)이 stdin 선두에 BOM을 붙여도 견디도록 strip한다.
# UTF-8로 디코드된 BOM(U+FEFF)과 오디코드된 3바이트(U+00EF U+00BB U+00BF) 둘 다 방어. hook은
# 자기완결이어야 하므로(외부 source 금지) 여기서 최소 strip을 직접 둔다. 판정은 불변(견고화만).
if ($inputJson) { $inputJson = $inputJson -replace '^(\uFEFF|\u00EF\u00BB\u00BF)', '' }

# $cmd = 추출된 실제 셸 명령(서브커맨드 판정용). 추출 실패면 $null로 남겨 보수적 폴백을 탄다.
$cmd = $null
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

# ── git 쓰기/읽기 판정 ───────────────────────────────────────────────
# release가 아닌 phase에서 git *쓰기* 서브커맨드만 차단한다(읽기는 통과). verb는 git 서브커맨드
# 위치에서만 본다(옵션 값·경로·복합 서브커맨드 이름의 부분일치 무시). tag는 읽기 옵션만/인자
# 없음이면 목록(읽기), 쓰기 옵션이나 목록 옵션 없는 위치 인자면 생성/삭제(쓰기). sh 사본과 동일
# 판정. 단일 원본 = docs/conventions.md "tide-guard hook" 절, 집행 = tests/multi-repo.
function Test-GitWriteSegment {
    param([string]$seg)
    $toks = @($seg -split '\s+' | Where-Object { $_ -ne '' })
    $i = 0; $found = $false
    while ($i -lt $toks.Count) {
        if ($toks[$i] -match '(^|[\\/])git(\.exe)?$') { $found = $true; $i++; break }
        $i++
    }
    if (-not $found) { return $false }
    $sub = $null
    while ($i -lt $toks.Count) {
        $t = $toks[$i]
        if ($t -match '^(-C|-c|--git-dir|--work-tree|--namespace|--super-prefix|--exec-path)$') { $i += 2; continue }
        elseif ($t -like '-*') { $i++; continue }
        else { $sub = $t; $i++; break }
    }
    if (-not $sub) { return $false }
    if ($sub -eq 'commit' -or $sub -eq 'push') { return $true }
    if ($sub -ne 'tag') { return $false }
    $wopt = $false; $rlist = $false; $pos = $false
    while ($i -lt $toks.Count) {
        $t = $toks[$i]; $i++
        if ($t -match '^([0-9]*[<>]|&>)') { break }
        if ($t -match '^(-a|--annotate|-s|--sign|-u|--local-user|-m|--message|-F|--file|-e|--edit|-f|--force|-d|--delete|--create-reflog)$' -or $t -match '^-(m|F|u).+') { $wopt = $true }
        elseif ($t -match '^(-l|--list|--contains|--no-contains|--points-at|--merged|--no-merged|--column|--no-column|-i|--ignore-case|-v|--verify|--omit-empty)$' -or $t -match '^-n[0-9]*$' -or $t -match '^--sort(=.*)?$' -or $t -match '^--format(=.*)?$') { $rlist = $true }
        elseif ($t -like '-*') { }
        else { $pos = $true }
    }
    if ($wopt) { return $true }
    if ($pos -and -not $rlist) { return $true }
    return $false
}

$blockMsg = "tide-guard: '$phase' 단계에서는 git 쓰기(commit·태그 생성/삭제·push)가 차단됩니다 — 읽기는 허용됩니다. git 쓰기는 /tide:release 단계에서만 가능합니다."

$blocked = $false
if ($cmd) {
    foreach ($seg in ($cmd -split '[&|;]')) {
        if (Test-GitWriteSegment $seg) { $blocked = $true; break }
    }
} else {
    if ($inputJson -match 'git[^&|;]*[^a-zA-Z](commit|tag|push)([^a-zA-Z]|$)') { $blocked = $true }
}
if ($blocked) {
    [Console]::Error.WriteLine($blockMsg)
    exit 2
}
exit 0
