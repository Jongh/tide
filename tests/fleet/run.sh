#!/bin/sh
# tide fleet 라이브 실증 (POSIX / Git Bash) — 자식 tide 레포 발견·분류·graceful 강등
#
# fleet은 프롬프트 스킬이라 실행 바이너리가 없다. 따라서 그 스킬이 따르는 **결정적 핵심**
# (발견 규약 + `/tide:status` 분류)을 동일 로직의 **참조 셸 절차**로 재현해 픽스처에 대해
# 검증한다 — 규약(`docs/conventions.md` "멀티 레포 오케스트레이션")이 단일 원본이고, 이
# 러너는 그 규약의 결정적 동작을 회귀 고정한다. advisory 서술 품질은 README의 세션 레벨
# 수동 절차로 분리한다(M13 앵커링 수동 절차와 동일 분리).
#
# 주의: git 차단 동사는 이 스크립트 내부 setup에만 둔다(여기선 init만 — commit 불필요).
# 러너 호출 명령줄엔 차단 패턴이 없어야 활성 tide-guard가 막지 않는다.
#
# 사용: sh tests/fleet/run.sh   (성공 시 exit 0, 하나라도 실패 시 exit 1)

set -u
SBX="${TMPDIR:-/tmp}/tide-fleet-live.$$"
rm -rf "$SBX"; mkdir -p "$SBX"
trap 'rm -rf "$SBX"' EXIT

pass=0; fail=0
chk() { # <desc> <got> <want>
    if [ "$2" = "$3" ]; then pass=$((pass + 1)); printf 'PASS  %-50s (%s)\n' "$1" "$2"
    else fail=$((fail + 1)); printf 'FAIL  %-50s (got %s, want %s)\n' "$1" "$2" "$3"; fi
}

# --- 발견 규약(참조 구현): 직속 1단계, git 레포 AND tide 산출물 ---
is_tide_repo() { # <dir>
    d="$1"
    { git -C "$d" rev-parse --show-toplevel >/dev/null 2>&1 || [ -d "$d/.git" ]; } || return 1
    [ -d "$d/docs/milestones" ] || [ -d "$d/.tide" ] || [ -f "$d/package.json" ] || \
        [ -f "$d/Cargo.toml" ] || [ -f "$d/pyproject.toml" ] || [ -f "$d/.claude-plugin/plugin.json" ]
}
discover() { # <parent> → 직속 자식 tide 레포 basename 정렬 출력
    for d in "$1"/*/ ; do
        [ -d "$d" ] || continue
        dd=${d%/}
        if is_tide_repo "$dd"; then basename "$dd"; fi
    done | sort
}

# --- 분류(참조 구현): /tide:status 다음 커맨드 판단 규칙 (라벨은 ASCII 토큰) ---
classify() { # <repo> → 라벨
    r="$1"
    ms=$(ls "$r"/docs/milestones/M*.md 2>/dev/null | sort -V | tail -1)
    [ -n "$ms" ] || { echo "milestone-needed"; return; }
    n=$(basename "$ms" .md)
    [ -f "$r/docs/reports/${n}-impl.md" ]   || { echo "impl-inprogress"; return; }
    [ -f "$r/docs/reports/${n}-review.md" ] || { echo "review-pending"; return; }
    if grep -q '불가' "$r/docs/reports/${n}-review.md"; then echo "needs-fix"; return; fi
    if grep -q '가능' "$r/docs/reports/${n}-review.md"; then echo "release-ready"; return; fi
    echo "unknown"
}

# --- 픽스처: 상위 폴더 + 서로 다른 사이클 위치의 자식들 (commit 불필요 — 발견은 init만으로 동작) ---
P="$SBX/parent"; mkdir -p "$P"
A="$P/repo-a"; mkdir -p "$A/docs/milestones" "$A/docs/reports"; git -C "$A" init -q
printf '# M1\n' > "$A/docs/milestones/M1.md"
printf '{ "version": "0.1.0" }\n' > "$A/package.json"
printf '# M1 impl\n' > "$A/docs/reports/M1-impl.md"
printf '## 릴리즈 판정\n\n**가능** — 추천 버전: **v0.2.0 (minor)**\n' > "$A/docs/reports/M1-review.md"
B="$P/repo-b"; mkdir -p "$B/docs/milestones" "$B/docs/reports"; git -C "$B" init -q
printf '# M1\n' > "$B/docs/milestones/M1.md"
printf '# M1 impl\n' > "$B/docs/reports/M1-impl.md"
C="$P/repo-c"; mkdir -p "$C/docs/milestones"; git -C "$C" init -q
printf '# M1\n' > "$C/docs/milestones/M1.md"
mkdir -p "$P/plain"; printf 'x\n' > "$P/plain/readme.txt"          # 비-git 일반 디렉터리 → 제외
ND="$P/notide"; mkdir -p "$ND"; git -C "$ND" init -q; printf 'x\n' > "$ND/file.txt"  # git이나 tide 산출물 없음 → 제외

# --- 시나리오 ---
got=$(discover "$P" | tr '\n' ',')
chk "발견: tide 레포만 (plain·notide 제외)" "$got" "repo-a,repo-b,repo-c,"
chk "분류 repo-a = release 가능"             "$(classify "$A")" "release-ready"
chk "분류 repo-b = review 대기"              "$(classify "$B")" "review-pending"
chk "분류 repo-c = impl 진행"                "$(classify "$C")" "impl-inprogress"

# graceful 강등: tide 레포 0개인 부모 → 발견 빈 결과(스킬은 단일 레포로 안내)
EMPTY="$SBX/empty"; mkdir -p "$EMPTY/just-a-folder"
e=$(discover "$EMPTY" | tr -d '\n')
chk "발견 0 → graceful 강등(빈 결과)" "${e:-EMPTY}" "EMPTY"

echo
echo "# 결과: PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ] || exit 1
echo "# fleet 발견·분류·강등 확인됨 (참조 구현 기준)"
