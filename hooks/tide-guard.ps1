# tide-guard — PreToolUse hook
# .tide/phase가 release가 아닌 동안 git commit/tag/push를 차단한다.
# 상태 파일이 없으면 아무것도 차단하지 않는다. 이 무차단은 두 경우를 함께 덮는다 —
#   (a) tide 미사용 프로젝트(영향 없음), (b) tide 레포인데 phase가 아직 없는 상태.
# (b)가 보호 창이다: .tide/phase는 gitignore 대상이라 fresh clone·신규 머신·플러그인 설치 직후에는
# git 쓰기 보호가 0이고, 창은 phase가 실제로 기록될 때 닫힌다 — 호출만으로는 닫히지 않는다
# (phase를 아예 쓰지 않는 커맨드가 있고, 쓰는 커맨드도 전제조건 검사에서 중단되면 기록 전에 끝난다).
# 어느 커맨드가 쓰는지·언제 쓰는지는 docs/conventions.md "상태 파일 (.tide/phase)" 절과 각 SKILL이
# 단일 원본이다 — 여기에 명단을 복제하지 않는다.
# 매처가 Bash|PowerShell이라 Edit/Write 도구 경로는 훅을 타지 않고, phase를 기록하는 주체가 LLM이라
# 기계적 가드의 전제조건 자체가 프롬프트 규율이다 — 보호는 조건부다. 창·우회 표면은 고지 후 수용이며,
# 단일 원본 = docs/conventions.md "tide-guard hook" 절, 3.0 후보 등재는 "2.0 안정성" 절.

# 입력 읽기 — stdin을 *바이트*로 받아 UTF-8로 직접 디코드한다. [Console]::In의 디코딩은 콘솔 입력
# 코드페이지를 따르므로(Git Bash에서 띄운 자식은 CP949를 물려받는다) 훅 입력의 UTF-8 바이트가
# 뭉개진다. 실측: 선두 BOM `EF BB BF`가 CP949에서 EF BB -> U+7664가 되고, 남은 BF가 뒤따르는
# `{`까지 한 무효 시퀀스로 삼켜 U+003F 하나로 바뀐다 — 즉 **여는 중괄호 자체가 사라진다**.
# 그래서 선두 형태를 열거하든 첫 '{' 앞을 버리든, 문자열로 디코드된 뒤에는 이 부류를 복구할 수
# 없다. 바이트에서 UTF-8로 직접 디코드하면 코드페이지 축이 사라져 부류 전체가 닫힌다.
# 실패 시에는 기존 읽기로 폴백해 어떤 환경에서도 훅이 죽지 않게 한다(판정 규칙은 불변).
$rawInput = $null
try {
    $stdinStream = [Console]::OpenStandardInput()
    $stdinBuf = New-Object System.IO.MemoryStream
    $stdinStream.CopyTo($stdinBuf)
    $rawInput = (New-Object System.Text.UTF8Encoding($false)).GetString($stdinBuf.ToArray())
} catch { $rawInput = $null }
if ($null -eq $rawInput) { $rawInput = [Console]::In.ReadToEnd() }

# 입력 정규화 — 선두 잡음 관용 파싱. 훅 입력은 항상 최상위 JSON *객체*이므로, 첫 '{' 앞에 붙어
# 도착한 바이트는 무엇이든 버린다. 형태를 열거하지 않고 부류 전체를 닫는 방식이라, UTF-8로
# 디코드된 선두 BOM(U+FEFF)이든 UTF-8로 유효하지 않아 U+FFFD가 된 임의의 선두 바이트든 같은 한
# 자리가 덮는다. 잡음이 없으면 무동작이고(첫 '{'가 인덱스 0), '{'가 아예 없으면 자르지 않고 기존
# 경로(파싱 실패 -> 보수적 폴백)를 그대로 탄다. 인덱스 비교는 ordinal로 고정한다 —
# String.IndexOf(string)의 기본값이 문화권 비교라서다. hook은 자기완결이어야 하므로
# (외부 source 금지) 여기서 최소 정규화를 직접 둔다.
# 판정 **규칙**은 불변이지만 **판정 자체가 불변인 것은 아니다** — 잡음 때문에 파싱에 실패하던 입력이
# 이제 성공하므로, 그 입력의 답은 **잡음 없는 같은 입력의 답과 같아진다**(= cwd가 가리킨 레포의
# phase가 판정을 끈다). 그 방향은 한쪽이 아니다: 폴백이 우연히 더 엄격했던 구성에서는 차단 -> 통과로
# 움직인다(실측 — CLAUDE_PROJECT_DIR가 비-release인데 cwd 레포가 release인 구성). 옳은 답이 되는
# 것이 근거이지 방향이 한쪽뿐이라는 것이 근거가 아니다(M42 리뷰가 앞선 판본의 단정을 반례로 무너뜨렸다).
#
# **두 사본을 나눠 든다**(M42-T09). $rawInput = 도착한 그대로의 입력, $inputJson = 정규화된 사본.
#   * $inputJson은 **구조 파싱에만** 쓴다 — 아래 ConvertFrom-Json 한 자리뿐이다.
#   * 파싱이 실패해 $cmd가 비었을 때 도는 **보수적 부분일치 스캔은 $rawInput을 훑는다.**
# 정규화한 문자열을 폴백에까지 물리면 첫 '{' 앞의 바이트가 **스캔 범위에서도** 사라진다. 실측:
# JSON이 아닌 원시 입력 `git commit -m "a{b}"`가 `{b}"`로 잘려 폴백이 git 쓰기를 못 보고 통과했다
# (수정 전 exit 0 / M42 이전 exit 2 — pwsh·sh 양쪽). 폴백의 존재 이유가 **파싱 불가 입력에서
# 과소 차단을 막는 것**이므로, 파싱을 돕자고 만든 절단이 그 자리의 시야를 좁혀서는 안 된다.
$inputJson = $rawInput
if ($inputJson) {
    $braceAt = $inputJson.IndexOf('{', [System.StringComparison]::Ordinal)
    if ($braceAt -gt 0) { $inputJson = $inputJson.Substring($braceAt) }
}

# $cmd = 추출된 실제 셸 명령(서브커맨드 판정용). 추출 실패면 $null로 남겨 보수적 폴백을 탄다.
# 구조 파싱의 입력은 **정규화된 $inputJson**이다(폴백 스캔은 $rawInput — 위 정규화 블록 주석 참조).
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
# 무차단 탈출 비교는 ordinal로 고정한다. PowerShell의 문자열 -eq는 문화권 비교라서
# 'rele<U+00AD>ase'(무시 가능 문자 삽입) 같은 값이 "release"와 같다고 판정돼 차단이 통과로
# 뒤집힐 수 있다(PS 5.1·7 양쪽에서 실측). OrdinalIgnoreCase는 기존의 대소문자 무시는 유지하고
# 문화권 축만 제거하므로, 이 자리로 판정이 움직이는 방향도 통과 -> 차단뿐이다.
if ([string]::Equals($phase, "release", [System.StringComparison]::OrdinalIgnoreCase)) { exit 0 }

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
    # 보수적 폴백 — **원본**($rawInput)을 훑는다. 정규화 사본을 쓰면 첫 '{' 앞의 git 쓰기가
    # 스캔 범위 밖으로 나간다(위 정규화 블록의 실측).
    if ($rawInput -match 'git[^&|;]*[^a-zA-Z](commit|tag|push)([^a-zA-Z]|$)') { $blocked = $true }
}
if ($blocked) {
    [Console]::Error.WriteLine($blockMsg)
    exit 2
}
exit 0
