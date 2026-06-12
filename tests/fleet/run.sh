#!/bin/sh
# tide fleet 라이브 실증 (POSIX / Git Bash) — 자식 tide 레포 발견·분류·요약·강등
#
# fleet은 프롬프트 스킬이라 실행 바이너리가 없다. 따라서 그 스킬이 따르는 **결정적 핵심**
# (발견 규약 + `/tide:status` 분류 + 정규 taxonomy 요약)을 동일 로직의 **참조 셸 절차**로
# 재현해 픽스처에 대해 검증한다 — 단일 원본은 `docs/conventions.md` "멀티 레포 오케스트레이션"
# 절이고, 이 러너는 그 정규 taxonomy(5 position·1:1 요약·숨김 무시)를 회귀 고정한다.
# advisory 서술 품질은 README의 세션 레벨 수동 절차로 분리한다.
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
    if [ "$2" = "$3" ]; then pass=$((pass + 1)); printf 'PASS  %-52s (%s)\n' "$1" "$2"
    else fail=$((fail + 1)); printf 'FAIL  %-52s (got %s, want %s)\n' "$1" "$2" "$3"; fi
}

# --- 발견 규약(참조 구현): 직속 1단계, 숨김(.) 무시, git 레포 AND tide 산출물 ---
is_tide_repo() { # <dir>
    d="$1"
    { git -C "$d" rev-parse --show-toplevel >/dev/null 2>&1 || [ -d "$d/.git" ]; } || return 1
    [ -d "$d/docs/milestones" ] || [ -d "$d/.tide" ] || [ -f "$d/package.json" ] || \
        [ -f "$d/Cargo.toml" ] || [ -f "$d/pyproject.toml" ] || [ -f "$d/.claude-plugin/plugin.json" ]
}
discover() { # <parent> → 직속 자식 tide 레포 basename 정렬 출력
    for d in "$1"/*/ ; do
        [ -d "$d" ] || continue
        base=$(basename "${d%/}")
        case "$base" in .*) continue ;; esac          # 숨김(dot) 디렉터리 무시
        if is_tide_repo "${d%/}"; then echo "$base"; fi
    done | sort
}

# --- 분류(참조 구현): /tide:status 다음 커맨드 판단 규칙 (5 position, ASCII 라벨) ---
classify() { # <repo> → 라벨
    r="$1"
    ms=$(ls "$r"/docs/milestones/M*.md 2>/dev/null | sort -V | tail -1)
    [ -n "$ms" ] || { echo "milestone-needed"; return; }       # milestone 필요
    n=$(basename "$ms" .md)
    [ -f "$r/docs/reports/${n}-impl.md" ]   || { echo "impl-inprogress"; return; }  # impl 진행
    [ -f "$r/docs/reports/${n}-review.md" ] || { echo "review-pending"; return; }   # review 대기
    if grep -q '불가' "$r/docs/reports/${n}-review.md"; then echo "needs-fix"; return; fi      # 보완 필요
    if grep -q '가능' "$r/docs/reports/${n}-review.md"; then echo "release-ready"; return; fi  # release 가능
    echo "unknown"
}
# --- 교차 요약(참조 구현): position 1:1 카운트 (정규 5버킷, 합산 금지) ---
summarize() { # <parent> → "release=N review=N impl=N milestone=N fix=N"
    rel=0; rev=0; imp=0; mil=0; fix=0
    for b in $(discover "$1"); do
        case "$(classify "$1/$b")" in
            release-ready)   rel=$((rel+1));;
            review-pending)  rev=$((rev+1));;
            impl-inprogress) imp=$((imp+1));;
            milestone-needed) mil=$((mil+1));;
            needs-fix)       fix=$((fix+1));;
        esac
    done
    echo "release=$rel review=$rev impl=$imp milestone=$mil fix=$fix"
}

# --- 픽스처: 5 position을 각각 두는 자식들 + 제외 케이스(commit 불필요) ---
P="$SBX/parent"; mkdir -p "$P"
A="$P/repo-a"; mkdir -p "$A/docs/milestones" "$A/docs/reports"; git -C "$A" init -q   # release 가능
printf '# M1\n' > "$A/docs/milestones/M1.md"; printf '{ "version": "0.1.0" }\n' > "$A/package.json"
printf '# M1 impl\n' > "$A/docs/reports/M1-impl.md"
printf '## release verdict\n\n**가능** — 추천: **v0.2.0 (minor)**\n' > "$A/docs/reports/M1-review.md"
B="$P/repo-b"; mkdir -p "$B/docs/milestones" "$B/docs/reports"; git -C "$B" init -q   # review 대기
printf '# M1\n' > "$B/docs/milestones/M1.md"; printf '# M1 impl\n' > "$B/docs/reports/M1-impl.md"
C="$P/repo-c"; mkdir -p "$C/docs/milestones"; git -C "$C" init -q                     # impl 진행
printf '# M1\n' > "$C/docs/milestones/M1.md"
D="$P/repo-d"; mkdir -p "$D/docs/milestones" "$D/docs/reports"; git -C "$D" init -q   # 보완 필요(불가)
printf '# M1\n' > "$D/docs/milestones/M1.md"; printf '# M1 impl\n' > "$D/docs/reports/M1-impl.md"
printf '## release verdict\n\n**불가**(테스트 실패) — 보완 필요\n' > "$D/docs/reports/M1-review.md"
E="$P/repo-e"; mkdir -p "$E/.tide"; git -C "$E" init -q                               # milestone 필요
printf '{ "version": "0.1.0" }\n' > "$E/package.json"; printf 'idle\n' > "$E/.tide/phase"
mkdir -p "$P/plain"; printf 'x\n' > "$P/plain/readme.txt"                             # 비-git → 제외
NDr="$P/notide"; mkdir -p "$NDr"; git -C "$NDr" init -q; printf 'x\n' > "$NDr/file.txt"  # tide 산출물 없음 → 제외
H="$P/.hidden-svc"; mkdir -p "$H/docs/milestones"; git -C "$H" init -q                # 숨김 → 제외(tide 산출물 있어도)
printf '# M1\n' > "$H/docs/milestones/M1.md"

# --- 시나리오 ---
got=$(discover "$P" | tr '\n' ',')
chk "발견: tide 레포만 (plain·notide·.hidden 제외)" "$got" "repo-a,repo-b,repo-c,repo-d,repo-e,"
chk "분류 repo-a = release 가능"  "$(classify "$A")" "release-ready"
chk "분류 repo-b = review 대기"   "$(classify "$B")" "review-pending"
chk "분류 repo-c = impl 진행"     "$(classify "$C")" "impl-inprogress"
chk "분류 repo-d = 보완 필요(불가)" "$(classify "$D")" "needs-fix"
chk "분류 repo-e = milestone 필요" "$(classify "$E")" "milestone-needed"
chk "숨김 디렉터리(.hidden-svc) 미발견" "$(discover "$P" | grep -c hidden)" "0"
chk "교차 요약 5버킷 1:1" "$(summarize "$P")" "release=1 review=1 impl=1 milestone=1 fix=1"

# graceful 강등: tide 레포 0개인 부모
EMPTY="$SBX/empty"; mkdir -p "$EMPTY/just-a-folder"
e=$(discover "$EMPTY" | tr -d '\n')
chk "발견 0 → graceful 강등(빈 결과)" "${e:-EMPTY}" "EMPTY"

echo
echo "# 결과: PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ] || exit 1
echo "# fleet 발견·5분류·1:1 요약·숨김 무시·강등 확인됨 (참조 구현 기준)"
