#!/bin/sh
# tide fleet-cycle 라이브 실증 (POSIX / Git Bash) — 교차 사이클 자동화의 결정적 핵심
#
# fleet-cycle은 프롬프트 스킬이라 실제 사이클 실행(milestone→impl→review)은 LLM 행위다.
# 따라서 그 스킬이 따르는 **결정적 핵심**(처리 순서=위상정렬 / release 제외 불변 / 계약
# upstream-behind contract-blocked / 실패 시 downstream skip)을 동일 로직의 **참조 셸 절차**로
# 재현해 픽스처에 대해 회귀 고정한다 — 단일 원본은 `docs/conventions.md` "멀티 레포
# 오케스트레이션" 절이며, 실제 사이클 실행 품질은 README의 세션 레벨 수동 절차로 분리한다.
#
# 주의: git 차단 동사는 이 스크립트 내부 setup에만 둔다(여기선 init만 — commit 불필요).
# 러너 호출 명령줄엔 차단 패턴이 없어야 활성 tide-guard가 막지 않는다. **release·git은
# 자동화 대상이 아니다** — 이 러너는 release가 자동 계획에 없음을 적극 검증한다.
#
# 사용: sh tests/fleet-cycle/run.sh   (성공 시 exit 0, 하나라도 실패 시 exit 1)

set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# source 순서: discover → deps → toposort (toposort가 read_deps를 호출하므로 deps가 먼저).
. "$ROOT/tests/lib/discover.sh"   # is_tide_repo + discover (단일 원본)
. "$ROOT/tests/lib/deps.sh"       # read_deps + strip_bom + dep_name (단일 원본)
. "$ROOT/tests/lib/toposort.sh"   # toposort (단일 원본; read_deps는 tests/lib/deps.sh가 정의)
SBX="${TMPDIR:-/tmp}/tide-fleet-cycle-live.$$"
rm -rf "$SBX"; mkdir -p "$SBX"
trap 'rm -rf "$SBX"' EXIT

pass=0; fail=0
chk() { # <desc> <got> <want>
    if [ "$2" = "$3" ]; then pass=$((pass + 1)); printf 'PASS  %-56s (%s)\n' "$1" "$2"
    else fail=$((fail + 1)); printf 'FAIL  %-56s (got %s, want %s)\n' "$1" "$2" "$3"; fi
}

# is_tide_repo + discover는 tests/lib/discover.sh로 이관(단일 원본). 위에서 source.

# read_deps/strip_bom/dep_name: tests/lib/deps.sh (단일 원본; 위에서 source). 계약 비교 전용
# 함수(dep_required_version·semver_ge·check_contract)는 추출 범위 밖이라 아래 로컬에 남는다 —
# dep_required_version은 deps.sh의 strip_bom을 재사용한다.
dep_required_version() { # <repo-dir> <dep-name> → 요구 버전(>=만, 없으면 빈)
    f="$1/.tide/deps"
    [ -f "$f" ] || return 0
    strip_bom < "$f" | while IFS= read -r line || [ -n "$line" ]; do
        line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        case "$line" in ''|'#'*) continue ;; esac
        name=$(printf '%s' "$line" | sed 's/[[:space:]]*[<>=].*$//' | sed 's/[[:space:]]*$//')
        [ "$name" = "$2" ] || continue
        case "$line" in
            *'>='*)
                ver=$(printf '%s' "$line" | sed 's/^.*>=[[:space:]]*//' | sed 's/[[:space:]].*$//')
                printf '%s\n' "$ver"
                ;;
        esac
        return 0
    done
}
read_version() { # <repo-dir> → X.Y.Z (없으면 빈)
    f="$1/package.json"
    [ -f "$f" ] || return 0
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -1
}
semver_ge() { # <current> <required> → satisfied|violation|skip
    cur=$(printf '%s' "$1" | sed 's/^v//'); req=$(printf '%s' "$2" | sed 's/^v//')
    echo "$cur" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo skip; return 0; }
    echo "$req" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo skip; return 0; }
    cmaj=${cur%%.*}; crest=${cur#*.}; cmin=${crest%%.*}; cpat=${crest#*.}
    rmaj=${req%%.*}; rrest=${req#*.}; rmin=${rrest%%.*}; rpat=${rrest#*.}
    if [ "$cmaj" -ne "$rmaj" ]; then [ "$cmaj" -gt "$rmaj" ] && echo satisfied || echo violation; return 0; fi
    if [ "$cmin" -ne "$rmin" ]; then [ "$cmin" -gt "$rmin" ] && echo satisfied || echo violation; return 0; fi
    if [ "$cpat" -ne "$rpat" ]; then [ "$cpat" -gt "$rpat" ] && echo satisfied || echo violation; return 0; fi
    echo satisfied
}
check_contract() { # <parent> <repo> <dep> → satisfied|violation|skip|none
    req=$(dep_required_version "$1/$2" "$3")
    [ -n "$req" ] || { echo none; return 0; }
    cur=$(read_version "$1/$3")
    [ -n "$cur" ] || { echo skip; return 0; }
    semver_ge "$cur" "$req"
}

# toposort는 tests/lib/toposort.sh로 이관(단일 원본; read_deps는 tests/lib/deps.sh가 정의). 상단에서 source.
idx_of() { # <order-string> <name> → 0-based 인덱스(없으면 -1)
    i=0
    for w in $1; do
        if [ "$w" = "$2" ]; then echo "$i"; return 0; fi
        i=$((i+1))
    done
    echo "-1"
}

# === fleet-cycle 고유 결정적 핵심 =========================================

# --- (1) 자동화 처리 계획 단계열(참조 구현): release 제외 불변 ---
# fleet-cycle은 각 레포에서 milestone→impl→review만 자동 체이닝한다. release는 절대 자동
# 계획에 포함하지 않는다(부수효과 분리 불변, tide-guard가 phase≠release에서 git 차단).
# 이 참조는 자동화가 산출하는 레포별 단계열을 만든다 — release가 결코 들어가지 않음을 표상.
plan_stages() { # → 공백 구분 자동화 단계열
    echo "milestone impl review"
}
# 단계열에 release가 있으면 yes, 없으면 no
plan_has_release() { # <stages> → yes|no
    for s in $1; do
        [ "$s" = "release" ] && { echo yes; return 0; }
    done
    echo no
}

# --- (2) release 핸드오프 분류(참조 구현): 자동화가 아닌 별도 핸드오프 목록 ---
# review "가능"이면서 계약 위반(upstream-behind)이 없으면 release-ready, 계약 위반이면
# contract-blocked(보류). 자동화는 여기까지 산출만 하고 release를 실행하지 않는다.
# <parent> <repo> <dep> → release-ready|contract-blocked
handoff_class() {
    case "$(check_contract "$1" "$2" "$3")" in
        violation) echo "contract-blocked" ;;
        *)         echo "release-ready" ;;
    esac
}

# --- (3) 실패 시 downstream skip(참조 구현): 전이적 의존자 도달성 ---
# 발견 집합에서 dep 그래프를 만들고, "중단" 레포에 (직접·전이적으로) 의존하는 레포를 skip으로
# 분류한다. 무관한 독립 레포는 ok. 역방향 도달성(reverse reachability)을 BFS로 계산한다.
# dependents_of: <parent> <failed-repo> → failed에 의존하는(전이 포함) 레포 정렬 목록
dependents_of() { # <parent> <failed>
    parent="$1"; failed="$2"
    nodes=$(discover "$parent")
    reached="$failed"          # 결과 집합(자신 포함, 마지막에 제외)
    frontier="$failed"
    while [ -n "$(printf '%s' "$frontier" | tr -d '[:space:]')" ]; do
        next=""
        for r in $nodes; do
            # r이 이미 reached면 건너뜀
            already=0
            for x in $reached; do [ "$x" = "$r" ] && { already=1; break; }; done
            [ "$already" -eq 0 ] || continue
            # r의 의존 중 frontier에 든 것이 있으면 r은 새로 도달
            for dep in $(read_deps "$parent/$r"); do
                for fr in $frontier; do
                    if [ "$dep" = "$fr" ]; then
                        reached="$reached $r"; next="$next $r"; break
                    fi
                done
            done
        done
        frontier="$next"
    done
    # reached에서 failed 자신 제외, 정렬 출력
    for x in $reached; do [ "$x" = "$failed" ] || echo "$x"; done | sort | tr '\n' ' ' | sed 's/[[:space:]]*$//'
}
# classify_on_failure: <parent> <failed> <repo> → skip|ok|failed
classify_on_failure() {
    [ "$3" = "$2" ] && { echo "failed"; return 0; }
    for d in $(dependents_of "$1" "$2"); do
        [ "$d" = "$3" ] && { echo "skip"; return 0; }
    done
    echo "ok"
}

# --- 픽스처 헬퍼 ---
mk_repo() { mkdir -p "$1/docs/milestones"; git -C "$1" init -q; printf '# M1\n' > "$1/docs/milestones/M1.md"; }

# === 시나리오 ============================================================

# --- (1) 처리 순서 = 위상정렬 (피의존 먼저) ---
# auth(무의존) ← orders(→auth) ← gateway(→auth) ← notify(→orders)
TP="$SBX/topo"; mkdir -p "$TP"
mk_repo "$TP/auth"
mk_repo "$TP/orders";  mkdir -p "$TP/orders/.tide";  printf 'auth\n'   > "$TP/orders/.tide/deps"
mk_repo "$TP/gateway"; mkdir -p "$TP/gateway/.tide"; printf 'auth\n'   > "$TP/gateway/.tide/deps"
mk_repo "$TP/notify";  mkdir -p "$TP/notify/.tide";  printf 'orders\n' > "$TP/notify/.tide/deps"

tord=$(toposort "$TP")
ia=$(idx_of "$tord" auth); io=$(idx_of "$tord" orders); ig=$(idx_of "$tord" gateway); inf=$(idx_of "$tord" notify)
chk "처리 순서: 순환 아님(CYCLE 아님)" "$([ "$tord" = "CYCLE" ] && echo yes || echo no)" "no"
chk "처리 순서: auth가 orders보다 앞(피의존 먼저)"  "$([ "$ia" -ge 0 ] && [ "$io" -ge 0 ] && [ "$ia" -lt "$io" ] && echo yes || echo no)" "yes"
chk "처리 순서: auth가 gateway보다 앞"             "$([ "$ia" -ge 0 ] && [ "$ig" -ge 0 ] && [ "$ia" -lt "$ig" ] && echo yes || echo no)" "yes"
chk "처리 순서: orders가 notify보다 앞(전이)"      "$([ "$io" -ge 0 ] && [ "$inf" -ge 0 ] && [ "$io" -lt "$inf" ] && echo yes || echo no)" "yes"
chk "처리 순서: auth가 notify보다 앞(전이)"        "$([ "$ia" -ge 0 ] && [ "$inf" -ge 0 ] && [ "$ia" -lt "$inf" ] && echo yes || echo no)" "yes"
chk "처리 순서: 발견 4노드 전부 순서에 존재"        "$(echo $tord | wc -w | tr -d ' ')" "4"

# --- (2) release 제외(불변): 자동 계획에 release 단계 없음 ---
stages=$(plan_stages)
chk "release 제외: 자동 단계열 = milestone impl review" "$stages" "milestone impl review"
chk "release 제외: 자동 계획에 release 단계 없음"        "$(plan_has_release "$stages")" "no"
chk "release 제외: 자동 단계열이 milestone으로 시작"     "$(echo $stages | cut -d' ' -f1)" "milestone"
chk "release 제외: 자동 단계열이 review로 종료(릴리즈 아님)" "$(echo $stages | awk '{print $NF}')" "review"

# --- (2b) release 제외 불변을 SKILL 아티팩트에 결합 — 금지 산문이 회귀하면 fail (적대 리뷰 대응) ---
# 위 (2)는 자동 단계열 표상일 뿐이라, 불변을 실제로 강제하는 스킬 산문(금지 목록·phase=release
# 백스톱/사전점검)이 삭제되면 fail하도록 실제 SKILL.md를 grep해 결합한다.
SKILL_FILE="$(cd "$(dirname "$0")/../.." && pwd)/skills/fleet-cycle/SKILL.md"
chk "release 제외(스킬 결합): 금지 목록 산문 존재" \
    "$(grep -qF 'release / git commit / git tag / git push / cross-repo git' "$SKILL_FILE" && echo yes || echo no)" "yes"
chk "release 제외(스킬 결합): phase=release 백스톱/사전점검 산문 존재" \
    "$(grep -qF 'phase=release' "$SKILL_FILE" && echo yes || echo no)" "yes"

# --- (3) contract-blocked: upstream-behind 의존을 둔 레포는 핸드오프에서 보류 ---
# auth(0.2.0) ← orders(auth >= v0.3.0 → upstream behind) / gateway(auth >= v0.2.0 → 만족)
CT="$SBX/contract"; mkdir -p "$CT"
mk_repo "$CT/auth"; printf '{ "version": "0.2.0" }\n' > "$CT/auth/package.json"
mk_repo "$CT/orders";  mkdir -p "$CT/orders/.tide";  printf 'auth >= v0.3.0\n' > "$CT/orders/.tide/deps"
mk_repo "$CT/gateway"; mkdir -p "$CT/gateway/.tide"; printf 'auth >= v0.2.0\n' > "$CT/gateway/.tide/deps"
chk "contract-blocked: orders(auth>=0.3.0, 현재 0.2.0) → 보류" "$(handoff_class "$CT" orders auth)" "contract-blocked"
chk "release-ready: gateway(auth>=0.2.0, 현재 0.2.0) → 가능"   "$(handoff_class "$CT" gateway auth)" "release-ready"

# --- (4) downstream skip on failure: auth 중단 → 의존자 전부 skip, 독립 레포 ok ---
# auth(무의존) ← orders(→auth) ← gateway(→auth) ← notify(→orders) , solo(독립)
FL="$SBX/fail"; mkdir -p "$FL"
mk_repo "$FL/auth"
mk_repo "$FL/orders";  mkdir -p "$FL/orders/.tide";  printf 'auth\n'   > "$FL/orders/.tide/deps"
mk_repo "$FL/gateway"; mkdir -p "$FL/gateway/.tide"; printf 'auth\n'   > "$FL/gateway/.tide/deps"
mk_repo "$FL/notify";  mkdir -p "$FL/notify/.tide";  printf 'orders\n' > "$FL/notify/.tide/deps"
mk_repo "$FL/solo"

deps_chain=$(dependents_of "$FL" auth)
chk "downstream: auth 의존자(전이) = gateway notify orders" "$deps_chain" "gateway notify orders"
chk "downstream: auth 중단 시 orders=skip"  "$(classify_on_failure "$FL" auth orders)"  "skip"
chk "downstream: auth 중단 시 gateway=skip" "$(classify_on_failure "$FL" auth gateway)" "skip"
chk "downstream: auth 중단 시 notify=skip(전이)" "$(classify_on_failure "$FL" auth notify)" "skip"
chk "downstream: auth 중단 시 solo=ok(독립 유지)" "$(classify_on_failure "$FL" auth solo)" "ok"
chk "downstream: auth 자신=failed"          "$(classify_on_failure "$FL" auth auth)"    "failed"
# orders만 중단되면 notify만 skip, gateway/solo는 ok(부분 진행)
chk "downstream: orders 중단 시 notify=skip" "$(classify_on_failure "$FL" orders notify)" "skip"
chk "downstream: orders 중단 시 gateway=ok(무관 독립)" "$(classify_on_failure "$FL" orders gateway)" "ok"
chk "downstream: orders 중단 시 solo=ok"     "$(classify_on_failure "$FL" orders solo)"   "ok"

echo
echo "# 결과: PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ] || exit 1
echo "# fleet-cycle 처리 순서(위상정렬)·release 제외(자동 계획 무릴리즈)·contract-blocked 핸드오프·downstream skip 확인됨 (참조 구현 기준)"
