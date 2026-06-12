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

pass=0; fail=0
# chk <설명> <CLAUDE_PROJECT_DIR> <cwd> <command> <기대exit>
#   cwd 빈 문자열이면 입력 JSON에 cwd 필드를 넣지 않는다(폴백 경로 검증).
chk() {
    _desc="$1"; _cpd="$2"; _cwd="$3"; _cmd="$4"; _want="$5"
    if [ -n "$_cwd" ]; then
        printf '{"cwd":"%s","tool_input":{"command":"%s"}}' "$_cwd" "$_cmd" > "$SBX/in.json"
    else
        printf '{"tool_input":{"command":"%s"}}' "$_cmd" > "$SBX/in.json"
    fi
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

echo
echo "# 결과: PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ] || exit 1
echo "# 모든 시나리오 통과 — repo-root 인식·격리·폴백 확인됨"
