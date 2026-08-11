#!/bin/sh
# tide 멀티 레포 라이브 실증 (POSIX / Git Bash) — repo-root 인식 tide-guard 검증
#
# 자기완결형 러너: 임시 상위 폴더 아래 자식 레포 2개를 만들고, 수정된 hooks/tide-guard.sh를
# 합성 훅 입력(JSON 픽스처)으로 직접 호출해 exit 코드를 검증한 뒤 정리한다.
#
# 주의: 차단 동사(commit/tag/push)는 이 스크립트 "내부"의 픽스처 문자열에만 둔다.
# 이 스크립트를 호출하는 명령줄에는 차단 패턴이 없어야 활성 tide-guard가 막지 않는다.
# (가드는 도구 호출의 command 문자열만 검사하며, 스크립트 내부 서브프로세스는 보지 않는다.)
#
# 사용: sh tests/multi-repo/run.sh   (성공 시 exit 0, 하나라도 실패 시 exit 1)

set -u

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
GUARD="$REPO_ROOT/hooks/tide-guard.sh"
[ -f "$GUARD" ] || { echo "가드 스크립트를 찾을 수 없음: $GUARD" >&2; exit 1; }

SBX="${TMPDIR:-/tmp}/tide-mr-live.$$"
rm -rf "$SBX"; mkdir -p "$SBX"
trap 'rm -rf "$SBX"' EXIT

# --- 사전 점검 ---
if command -v jq >/dev/null 2>&1; then JQ="jq 있음(자동 이스케이프 경로)"; else JQ="jq 없음(sed 폴백 경로)"; fi
echo "# tide 멀티 레포 라이브 실증"
echo "# 가드: $GUARD"
echo "# 추출 경로: $JQ"
echo "# 샌드박스: $SBX"
echo

# 자식 레포 2개 생성 (commit 불필요 — rev-parse --show-toplevel는 빈 레포에서도 동작)
A_DIR="$SBX/child-a"; B_DIR="$SBX/child-b"
mkdir -p "$A_DIR" "$B_DIR"
git -C "$A_DIR" init -q
git -C "$B_DIR" init -q
# rev-parse 정규화 경로로 통일 (심볼릭/경로 정규화 불일치 방지)
A=$(git -C "$A_DIR" rev-parse --show-toplevel)
B=$(git -C "$B_DIR" rev-parse --show-toplevel)
mkdir -p "$A/.tide" "$B/.tide" "$A/sub"
PLAIN="$SBX/plain"; mkdir -p "$PLAIN"   # git 레포 아님

# 차단 동사 픽스처 (스크립트 내부에만 존재)
BLOCK='git commit -m x'
TAG='git tag v1.0.0'
SAFE='git status'
# 파싱 불가 입력용 원시 픽스처(M42-T09) — JSON이 아니고, 첫 `{`가 **명령 문자열 한가운데** 있다.
RAWBLOCK='git commit -m "a{b}"'

pass=0; fail=0
# chk <설명> <CLAUDE_PROJECT_DIR> <cwd> <command> <기대exit> [입력형태]
#   cwd 빈 문자열이면 입력 JSON에 cwd 필드를 넣지 않는다(폴백 경로 검증).
#   6번째 인자 = **입력 형태(fixture shape)**. 빈 값이면 평범한 JSON 픽스처다.
#     `bom`   — 온전한 UTF-8 BOM을 앞에 붙인 JSON
#     `noise` — **가드가 형태로 아는 어느 것도 아닌** 선두 바이트(뭉갠 BOM 부류, M42)를 붙인 JSON
#     `raw`   — **JSON 래핑 없는 원시 바이트**. `<command>` 문자열 자체가 입력 전부다(M42-T09).
#   앞의 둘은 선두 잡음 모드라 판정을 바꾸지 못해야 하고, `raw`는 아예 **파싱 불가 입력**을 만들어
#   가드의 보수적 폴백 스캔 경로를 밟게 한다(그 경로 전용 픽스처라 cwd 인자는 쓰이지 않는다).
chk() {
    _desc="$1"; _cpd="$2"; _cwd="$3"; _cmd="$4"; _want="$5"; _bom="${6:-}"
    if [ "$_bom" = raw ]; then
        printf '%s' "$_cmd" > "$SBX/in.json"
    elif [ -n "$_cwd" ]; then
        printf '{"cwd":"%s","tool_input":{"command":"%s"}}' "$_cwd" "$_cmd" > "$SBX/in.json"
    else
        printf '{"tool_input":{"command":"%s"}}' "$_cmd" > "$SBX/in.json"
    fi
    case "$_bom" in
        bom)
            { printf '\357\273\277'; cat "$SBX/in.json"; } > "$SBX/in.bom.json"
            mv "$SBX/in.bom.json" "$SBX/in.json" ;;
        noise)
            { printf '\357\273?'; cat "$SBX/in.json"; } > "$SBX/in.bom.json"
            mv "$SBX/in.bom.json" "$SBX/in.json" ;;
    esac
    CLAUDE_PROJECT_DIR="$_cpd" sh "$GUARD" < "$SBX/in.json" >/dev/null 2>&1
    _got=$?
    if [ "$_got" = "$_want" ]; then
        pass=$((pass + 1)); printf 'PASS  %-58s (exit %s)\n' "$_desc" "$_got"
    else
        fail=$((fail + 1)); printf 'FAIL  %-58s (got %s, want %s)\n' "$_desc" "$_got" "$_want"
    fi
}

# 시나리오 1: 비-release 자식에서 차단 (핵심 차단)
printf 'impl\n' > "$A/.tide/phase"
chk "A(impl) commit 차단" "$SBX" "$A" "$BLOCK" 2
chk "A(impl) tag 차단"    "$SBX" "$A" "$TAG"   2

# 시나리오 2: release 자식에서 통과
printf 'release\n' > "$A/.tide/phase"
chk "A(release) commit 통과" "$SBX" "$A" "$BLOCK" 0

# 시나리오 3: 레포별 격리 — A=release인 같은 시점에 B(impl)는 여전히 차단
printf 'impl\n' > "$B/.tide/phase"
chk "B(impl) commit 차단 (A=release여도 B 독립)" "$SBX" "$B" "$BLOCK" 2

# 시나리오 4: 레포 하위 디렉터리 cwd → 레포 루트 phase로 해석
printf 'impl\n' > "$A/.tide/phase"
chk "A/sub(impl) commit 차단 (하위 dir→루트 해석)" "$SBX" "$A/sub" "$BLOCK" 2

# 시나리오 5: 안전 명령은 어떤 phase에서도 통과
chk "A(impl) git status 통과 (차단 대상 아님)" "$SBX" "$A" "$SAFE" 0

# 시나리오 6: 폴백 — cwd 없음 + CLAUDE_PROJECT_DIR=A(impl) → 폴백 차단
chk "cwd 없음 → CLAUDE_PROJECT_DIR(A,impl) 폴백 차단" "$A" "" "$BLOCK" 2

# 시나리오 7: 폴백 — non-repo cwd + phase 없는 CPD → 무차단(안전 측, 누수 아님)
chk "non-repo cwd + phase 없음 → 무차단" "$PLAIN" "$PLAIN" "$BLOCK" 0

# 시나리오 8: 단일 레포 회귀 — cwd=레포 루트(현행 동작과 동일)
printf 'release\n' > "$A/.tide/phase"
chk "단일 레포 회귀: A(release) 루트 cwd commit 통과" "$A" "$A" "$BLOCK" 0
printf 'impl\n' > "$A/.tide/phase"
chk "단일 레포 회귀: A(impl) 루트 cwd commit 차단" "$A" "$A" "$BLOCK" 2

# 시나리오 9: 선두 BOM 입력 내성 — no-BOM과 동일 판정 (sn2 / T03 가드 BOM strip)
# 판별 셋업: cwd=A(phase 설정)가 판정을 끌고, CPD=$SBX엔 phase 없음 → 선두 BOM이 cwd 추출을
# 깨면 폴백($SBX, phase 없음)으로 판정이 뒤집힌다. jq 경로는 BOM에서 throw하므로 특히 판별적이고
# (현재 환경은 sed 폴백이라 BOM-내성), 가드가 선두 BOM을 strip하므로 양 경로 모두 동일 판정.
printf 'impl\n' > "$A/.tide/phase"
chk "A(impl) commit 차단 [BOM 입력→cwd, CPD 아님]" "$SBX" "$A" "$BLOCK" 2 bom
printf 'release\n' > "$A/.tide/phase"
chk "A(release) commit 통과 [BOM 입력→cwd, CPD 아님]" "$SBX" "$A" "$BLOCK" 0 bom

# 시나리오 9b: **뭉갠 BOM**(가드가 형태로 아는 어느 것도 아닌 선두 바이트) 내성 — M42.
# 배경(M38-T05 실측): ps1 가드는 stdin 디코딩이 콘솔 입력 코드페이지를 따라, Git Bash에서 띄우면
# 선두 BOM이 U+7664 + U+003F로 뭉개져 **형태 열거가 통하지 않았고** cwd가 비어 폴백으로 빠져
# **차단이 통과로 뒤집혔다**. M42가 두 사본을 "첫 `{` 앞은 무엇이든 버린다"로 바꿔 부류를 닫았다.
# 셋업은 시나리오 9와 같은 판별형이다 — 선두 잡음이 cwd 추출을 깨면 판정이 뒤집힌다.
# **이 셸에서의 정직 표기(실측)**: POSIX 가드의 두 추출 경로가 **원래 갈려 있었다**(M42-T01이 jq를
# 임시로 설치해 양쪽을 실제로 돌렸다) — `sed` 폴백은 선두 잡음에 둔감해 수정 전에도 exit 2였고,
# `jq` 경로는 `noise`·`EF BB`·`FF FE` 선두에서 **exit 0으로 뒤집혔다**(잡음이 붙으면 유효 JSON이
# 아니라 jq가 실패 → cwd 빔 → 폴백 통과). 즉 이 구멍은 ps1만의 것이 아니었다. 수정 후 두 경로의
# 판정이 전 케이스에서 일치한다. 이 기계에는 jq가 없어 **여기서 도는 것은 sed 경로**다 —
# 그래서 이 케이스는 이 환경에서 회귀 가드이지 수정의 실증이 아니다(실증은 위 T01 실측이다).
printf 'impl\n' > "$A/.tide/phase"
chk "A(impl) commit 차단 [뭉갠 BOM 선두 잡음]"  "$SBX" "$A" "$BLOCK" 2 noise
printf 'release\n' > "$A/.tide/phase"
chk "A(release) commit 통과 [뭉갠 BOM 선두 잡음]" "$SBX" "$A" "$BLOCK" 0 noise

# 시나리오 9c: **파싱 불가 입력의 보수적 폴백**(M42-T09 회귀) — 정규화가 폴백의 시야를 좁히면 안 된다.
# 가드는 `cmd` 추출에 실패하면 부분일치 스캔으로 폴백해 과소 차단을 막는다. M42가 넣은 입력 정규화
# ("첫 `{` 앞은 무엇이든 버린다")를 **그 폴백 스캔에도** 물리면, 첫 `{`가 명령 한가운데 있는 파싱 불가
# 입력에서 git 쓰기가 스캔 범위 밖으로 나간다. 실측: 원시 입력 `git commit -m "a{b}"`가 `{b}"`로 잘려
# **sh·pwsh 양쪽에서 exit 2 → 0으로 뒤집혔다**(M42 이전 2 / T09 이전 0 / T09 이후 2). T09은 정규화한
# 사본을 **구조 파싱에만** 쓰고 폴백은 원본을 훑게 해 되돌렸다. 판별 셋업: 폴백 루트(CPD)에 phase가
# 있어야 이 자리를 밟는다 — cwd는 JSON이 없으니 애초에 뽑히지 않는다.
# 두 번째 케이스는 음성 통제다 — 같은 원시 픽스처 경로가 **읽기는 통과**시킨다(폴백이 무조건
# 차단하는 것이 아니라 실제로 동사를 보고 있음을 고정한다).
printf 'impl\n' > "$A/.tide/phase"
chk "원시 입력(파싱 불가·중괄호 포함) commit 차단" "$A" "" "$RAWBLOCK" 2 raw
chk "원시 입력(파싱 불가) git status 통과 [음성 통제]" "$A" "" "$SAFE"  0 raw

# 시나리오 9d: **폴백 루트에 phase가 있는 구성**(M42-T09) — cwd가 폴백을 이긴다.
# 위 잡음 케이스(9·9b)는 전부 CPD에 phase가 없어 "cwd 추출이 깨지면 무차단"이라는 한 방향만 밟는다.
# 여기서는 **CPD=A(impl)** 로 두어 폴백이 살아 있게 한다 — 선두 잡음이 cwd 추출을 깨면 폴백이 A(impl)를
# 집어 판정이 **통과 → 차단**으로 뒤집힌다. 기대값은 실측으로 정했다(sh·pwsh 모두 exit 0):
# **cwd가 가리키는 레포의 phase가 판정을 끄는 것이 멀티 레포 격리 규약**이므로, cwd=B(release)면
# CPD 쪽 phase와 무관하게 통과가 옳다. 잡음 없는 같은 입력(첫 케이스)이 대조군이며 두 값이 같아야
# "잡음이 판정을 바꾸지 못한다"가 성립한다.
printf 'impl\n' > "$A/.tide/phase"
printf 'release\n' > "$B/.tide/phase"
chk "cwd=B(release) 통과 [CPD=A(impl) 폴백 살아있음]"      "$A" "$B" "$BLOCK" 0
chk "cwd=B(release) 통과 [같은 구성 + 뭉갠 BOM 선두 잡음]" "$A" "$B" "$BLOCK" 0 noise

# 시나리오 10: 읽기/쓰기 구분 (M28) — 비-release에서 git *읽기*는 통과, *쓰기*만 차단.
# 같은 impl phase에서 읽기 통과 + 쓰기 차단을 함께 단언해 "가드가 살아 있으면서 읽기만 통과"임을
# 고정한다(음성 통제). verb는 서브커맨드 위치에서만 본다(옵션 값·경로·복합 이름 부분일치 무시).
printf 'impl\n' > "$A/.tide/phase"
# 읽기(통과, exit 0)
chk "A(impl) git tag -l 통과 (태그 목록=읽기)"          "$SBX" "$A" "git tag -l"                   0
chk "A(impl) git tag -l 패턴 통과 (목록 옵션→위치=패턴)" "$SBX" "$A" "git tag -l 'v2.*'"            0
chk "A(impl) git tag --contains 통과 (태그 조회)"        "$SBX" "$A" "git tag --contains HEAD"      0
chk "A(impl) git log --grep=commit 통과 (옵션 값)"       "$SBX" "$A" "git log --grep=commit"        0
chk "A(impl) git show HEAD:path 통과 (경로 부분일치)"    "$SBX" "$A" "git show HEAD:src/tag.rs"     0
chk "A(impl) git cat-file commit 통과 (비-서브커맨드)"   "$SBX" "$A" "git cat-file commit HEAD"     0
chk "A(impl) git commit-graph 통과 (복합 서브커맨드)"    "$SBX" "$A" "git commit-graph verify"      0
chk "A(impl) git tag 리다이렉트 통과 (목록>파일=읽기)"   "$SBX" "$A" "git tag > /tmp/t.txt"         0
# 쓰기(차단, exit 2)
chk "A(impl) git tag 생성 차단 (위치 인자=생성)"         "$SBX" "$A" "git tag v2.6.0"               2
chk "A(impl) git tag -d 삭제 차단"                       "$SBX" "$A" "git tag -d v1"                2
chk "A(impl) git push --tags 차단"                       "$SBX" "$A" "git push --tags"              2
chk "A(impl) git -C .. commit 차단 (전역 옵션 접두)"     "$SBX" "$A" "git -C ../other commit -m x"  2

# 시나리오 11: phase=debug 가드 회귀 (M29 결정 2) — debug는 phase≠release이므로 가드 코드를
# 수정하지 않아도 기존 규칙이 그대로 적용된다: 쓰기는 차단, 읽기는 통과.
# 시나리오 10과 동일 취지로 읽기 통과 + 쓰기 차단을 같은 phase에서 함께 단언한다(음성 통제 —
# 통제가 없으면 가드에 debug 분기가 생겨 통째로 죽어도 읽기 케이스만 green이 된다).
printf 'debug\n' > "$A/.tide/phase"
# 읽기(통과, exit 0)
chk "A(debug) git log 통과 (이력 읽기)"                  "$SBX" "$A" "git log"                     0
chk "A(debug) git tag -l 통과 (태그 목록=읽기)"          "$SBX" "$A" "git tag -l"                  0
chk "A(debug) git show HEAD:path 통과 (이력 파일 읽기)"  "$SBX" "$A" "git show HEAD:README.md"     0
# 쓰기(차단, exit 2)
chk "A(debug) git commit 차단 (가드 무수정)"             "$SBX" "$A" "$BLOCK"                      2
chk "A(debug) git push 차단 (가드 무수정)"               "$SBX" "$A" "git push"                    2
chk "A(debug) git tag -a 차단 (주석 태그 생성=쓰기)"     "$SBX" "$A" "git tag -a v1 -m x"          2

# === 케이스 수 자기 정합 (M38-T01) ======================================
# 완주 가드(M37)는 러너가 **중단**되는 것을 잡지, 죽지 않고 **덜 도는** 것을 잡지 않는다 —
# 조건 분기가 시나리오를 건너뛰거나 비종료 오류가 케이스를 지나가면 아무도 모른다. 기대 케이스
# 수의 **단일 선언처는 이 하니스의 README**이며(규약: `docs/conventions.md`의 "문서 자기서술 정합"),
# 러너에 수를 하드코딩하지 않는 것이 요점이다. 선언을 못 읽으면(파일 없음·`cases` 토큰 없음)
# 추출이 빈 문자열이 되어 **FAIL**이다 — "못 읽어서 대조를 건너뛰고 통과"는 두지 않는다(자기 공허 금지).
# 이 케이스 자신도 한 건이라 계수가 순환하므로 **마지막 케이스**로 두고 `누계 + 1`과 비교한다
# (`tests/discover`의 F1과 동형 — 단언 이름·판정은 양 셸이 같다).
# 이 하니스의 `chk`는 훅 exit 코드 전용 시그니처라 여기서는 같은 계수기·같은 출력 골격으로
# 직접 판정한다(별도 단언 헬퍼를 만들지 않는다).
HARNESS_README="$REPO_ROOT/tests/multi-repo/README.md"
CC_DESC="case-count: README cases declaration == actual"
# **첫 매치 고정** — sed의 선행 `.*`는 탐욕이라 한 줄에 `cases:`가 둘이면 **마지막**을 집는데
# ps1의 `[regex]::Match`는 **첫 번째**를 집는다(M38 리뷰 사소 4의 실측: 같은 입력에 sed 7 ↔ .NET 42).
# `grep -o`는 매치를 파일·줄 순서대로 내므로 `head -1`이 곧 첫 매치다 — 양 셸 동형.
CC_GOT=$(grep -o 'cases:[^0-9]*[0-9][0-9]*' "$HARNESS_README" 2>/dev/null | head -1 |
         grep -o '[0-9][0-9]*' | head -1)
CC_WANT=$((pass + fail + 1))
if [ "$CC_GOT" = "$CC_WANT" ]; then
    pass=$((pass + 1)); printf 'PASS  %-58s (%s)\n' "$CC_DESC" "$CC_GOT"
else
    fail=$((fail + 1)); printf 'FAIL  %-58s (got %s, want %s)\n' "$CC_DESC" "$CC_GOT" "$CC_WANT"
fi

echo
echo "# 결과: PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ] || exit 1
echo "# 모든 시나리오 통과 — repo-root 인식·격리·폴백·읽기/쓰기 구분·phase=debug 확인됨"
