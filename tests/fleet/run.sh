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

# --- .tide/deps 파싱(참조 구현): 한 줄에 형제 레포명 하나, # 주석·빈 줄 무시, 트림 ---
read_deps() { # <repo-dir> → 의존 형제명 줄 출력 (없으면 빈 출력)
    f="$1/.tide/deps"
    [ -f "$f" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        # 앞뒤 공백 트림
        line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        case "$line" in ''|'#'*) continue ;; esac           # 빈 줄·주석 무시
        echo "$line"
    done < "$f"
}

# --- 의존성 인식 순서(참조 구현): 위상정렬(피의존 우선) + 순환 감지 폴백 ---
# 발견 집합에 없는 이름은 무시(안전 측). 모든 노드를 소비 못하면 순환 → 센티넬 CYCLE.
toposort() { # <parent> → "depA depB ..."(공백 구분, 피의존 먼저) | "CYCLE"
    parent="$1"
    nodes=$(discover "$parent")                              # 발견된 레포(정렬됨)
    [ -n "$nodes" ] || { echo ""; return 0; }

    # edges_<repo> = 발견 집합에 든 의존 대상만(미존재명 무시)
    set -- $nodes
    for r in $nodes; do
        kept=""
        for dep in $(read_deps "$parent/$r"); do
            for n in $nodes; do                              # 발견 집합 멤버십 검사
                if [ "$dep" = "$n" ]; then kept="$kept $dep"; break; fi
            done
        done
        eval "edges_$r=\"$kept\""
    done

    remaining="$nodes"
    order=""
    # Kahn 변형: 미해결 의존이 0인 노드를 발견 순서대로 방출, 진전 없으면 순환.
    while [ -n "$(printf '%s' "$remaining" | tr -d '[:space:]')" ]; do
        progressed=0
        next_remaining=""
        for r in $remaining; do
            eval "deps=\$edges_$r"
            ready=1
            for dep in $deps; do
                # dep이 아직 remaining에 있으면(아직 미방출) 이 노드는 대기
                for rem in $remaining; do
                    if [ "$dep" = "$rem" ]; then ready=0; break; fi
                done
                [ "$ready" -eq 1 ] || break
            done
            if [ "$ready" -eq 1 ]; then
                order="$order $r"; progressed=1
            else
                next_remaining="$next_remaining $r"
            fi
        done
        if [ "$progressed" -eq 0 ]; then echo "CYCLE"; return 0; fi
        remaining="$next_remaining"
    done
    # 선두 공백 제거
    printf '%s\n' "$order" | sed 's/^[[:space:]]*//'
}

# 순서 문자열에서 어떤 레포가 다른 레포보다 앞에 오는지(인덱스 비교)
idx_of() { # <order-string> <name> → 0-based 인덱스(없으면 -1)
    i=0
    for w in $1; do
        if [ "$w" = "$2" ]; then echo "$i"; return 0; fi
        i=$((i+1))
    done
    echo "-1"
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

# --- 의존성 인식 순서 픽스처/시나리오 (M16: .tide/deps 위상정렬·폴백) ---

# 위상정렬: auth(무의존) ← orders(→auth) ← gateway(→auth) ← solo(미선언 독립)
TP="$SBX/topo"; mkdir -p "$TP"
mk_repo() { mkdir -p "$1/docs/milestones"; git -C "$1" init -q; printf '# M1\n' > "$1/docs/milestones/M1.md"; }
mk_repo "$TP/auth"
mk_repo "$TP/orders";  mkdir -p "$TP/orders/.tide";  printf 'auth\n'        > "$TP/orders/.tide/deps"
mk_repo "$TP/gateway"; mkdir -p "$TP/gateway/.tide"; printf '# dep\nauth\n' > "$TP/gateway/.tide/deps"  # 주석+의존
mk_repo "$TP/solo"                                                                                       # 미선언 독립
# 미존재명: nowhere는 발견 집합에 없음 → 무시되어야 함
printf '  auth  \nnowhere\n' > "$TP/orders/.tide/deps"  # 트림·미존재명 무시 동시 검증

tord=$(toposort "$TP")
ia=$(idx_of "$tord" auth); io=$(idx_of "$tord" orders); ig=$(idx_of "$tord" gateway); is=$(idx_of "$tord" solo)
chk "토포: 순환 아님(CYCLE 아님)" "$([ "$tord" = "CYCLE" ] && echo yes || echo no)" "no"
chk "토포: auth가 orders보다 앞"  "$([ "$ia" -ge 0 ] && [ "$io" -ge 0 ] && [ "$ia" -lt "$io" ] && echo yes || echo no)" "yes"
chk "토포: auth가 gateway보다 앞" "$([ "$ia" -ge 0 ] && [ "$ig" -ge 0 ] && [ "$ia" -lt "$ig" ] && echo yes || echo no)" "yes"
chk "미선언 독립: solo가 순서에 존재" "$([ "$is" -ge 0 ] && echo yes || echo no)" "yes"
chk "미존재명 무시: 순서가 4개 노드(NaN/크래시 없음)" "$(echo $tord | wc -w | tr -d ' ')" "4"

# 순환 폴백: a→b, b→a → CYCLE 센티넬
CY="$SBX/cycle"; mkdir -p "$CY"
mk_repo "$CY/a"; mkdir -p "$CY/a/.tide"; printf 'b\n' > "$CY/a/.tide/deps"
mk_repo "$CY/b"; mkdir -p "$CY/b/.tide"; printf 'a\n' > "$CY/b/.tide/deps"
chk "순환 폴백: a↔b 순환 감지(CYCLE)" "$(toposort "$CY")" "CYCLE"

echo
echo "# 결과: PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ] || exit 1
echo "# fleet 발견·5분류·1:1 요약·숨김 무시·강등·위상정렬·순환 폴백 확인됨 (참조 구현 기준)"
