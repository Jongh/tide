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

# 레포 루트는 스크립트 위치에서 해석. 공유 발견/위상정렬 라이브러리를 source한다.
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
# source 순서: discover → deps → toposort (toposort가 read_deps를 호출하므로 deps가 먼저).
. "$ROOT/tests/lib/discover.sh"
. "$ROOT/tests/lib/deps.sh"
. "$ROOT/tests/lib/toposort.sh"

SBX="${TMPDIR:-/tmp}/tide-fleet-live.$$"
rm -rf "$SBX"; mkdir -p "$SBX"
trap 'rm -rf "$SBX"' EXIT

pass=0; fail=0
chk() { # <desc> <got> <want>
    if [ "$2" = "$3" ]; then pass=$((pass + 1)); printf 'PASS  %-52s (%s)\n' "$1" "$2"
    else fail=$((fail + 1)); printf 'FAIL  %-52s (got %s, want %s)\n' "$1" "$2" "$3"; fi
}

# is_tide_repo/discover: tests/lib/discover.sh (단일 원본)

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

# read_deps/strip_bom/dep_name: tests/lib/deps.sh (단일 원본; 위에서 source). 계약 비교 전용
# 함수(dep_required_*·semver_*·eval_op·check_contract)는 추출 범위 밖이라 아래 로컬에 남는다 —
# 이들은 deps.sh의 strip_bom을 재사용한다.

# 특정 의존 대상의 요구 제약(연산자+버전) 추출. 없으면 빈 출력(제약 없음).
# M20: 전체 연산자 지원 — `>=`·`>`·`=`(`==`)·`<=`·`<`. 출력 형식: "<op> <ver>" (한 줄).
#   연산자 토큰을 길이 우선(>=, <=, ==, =, >, <)으로 인식한다.
dep_required_constraint() { # <repo-dir> <dep-name> → "<op> <ver>"(없으면 빈)
    f="$1/.tide/deps"
    [ -f "$f" ] || return 0
    strip_bom < "$f" | while IFS= read -r line || [ -n "$line" ]; do
        line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        case "$line" in ''|'#'*) continue ;; esac
        name=$(printf '%s' "$line" | awk '{print $1}' | sed -E 's/(>=|<=|==|=|>|<).*$//')
        [ "$name" = "$2" ] || continue
        # 연산자=둘째 토큰, 버전=셋째 토큰(공백 구분 — 규약 포맷 `<name> <op> <ver>`).
        # 둘째 토큰이 알려진 연산자가 아니면(부재/`~>` 등) 제약 없음 = none(이름 의존만 — 토포 보존).
        op=$(printf '%s' "$line" | awk '{print $2}')
        ver=$(printf '%s' "$line" | awk '{print $3}')
        case "$op" in
            '>='|'<='|'=='|'='|'>'|'<') printf '%s %s\n' "$op" "$ver" ;;
            *) ;;                                           # 미지/부재 연산자 → none
        esac
        return 0
    done
}
# 하위 호환 별칭: `>=` 제약일 때만 버전을 방출(기존 호출부·기대 유지).
dep_required_version() { # <repo-dir> <dep-name> → 요구 버전(>=만, 없으면 빈)
    c=$(dep_required_constraint "$1" "$2")
    case "$c" in '>= '*) printf '%s\n' "${c#'>= '}" ;; esac
}
# 레포의 현재 버전(package.json "version" 필드). 없으면 빈.
read_version() { # <repo-dir> → X.Y.Z (없으면 빈)
    f="$1/package.json"
    [ -f "$f" ] || return 0
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -1
}
# semver 3원 비교: 현재 vs 요구(major.minor.patch 숫자, 선행 v 선택).
# 반환: gt | lt | eq | skip(파싱 불가). echo로 결과 문자열.
semver_cmp() { # <current> <required> → gt|lt|eq|skip
    cur=$(printf '%s' "$1" | sed 's/^v//')
    req=$(printf '%s' "$2" | sed 's/^v//')
    echo "$cur" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo skip; return 0; }
    echo "$req" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo skip; return 0; }
    cmaj=${cur%%.*}; crest=${cur#*.}; cmin=${crest%%.*}; cpat=${crest#*.}
    rmaj=${req%%.*}; rrest=${req#*.}; rmin=${rrest%%.*}; rpat=${rrest#*.}
    if [ "$cmaj" -ne "$rmaj" ]; then [ "$cmaj" -gt "$rmaj" ] && echo gt || echo lt; return 0; fi
    if [ "$cmin" -ne "$rmin" ]; then [ "$cmin" -gt "$rmin" ] && echo gt || echo lt; return 0; fi
    if [ "$cpat" -ne "$rpat" ]; then [ "$cpat" -gt "$rpat" ] && echo gt || echo lt; return 0; fi
    echo eq
}
# 연산자 평가: <op> <current> <required> → satisfied|violation|skip|none
#   지원: >= > = == <= < . 알 수 없는 연산자 → none(무시, 위반 단정 안 함).
#   비표준 버전(파싱 불가) → skip.
eval_op() { # <op> <current> <required>
    c=$(semver_cmp "$2" "$3")
    [ "$c" = skip ] && { echo skip; return 0; }
    case "$1" in
        '>=') { [ "$c" = gt ] || [ "$c" = eq ]; } && echo satisfied || echo violation ;;
        '>')  [ "$c" = gt ]                       && echo satisfied || echo violation ;;
        '='|'==') [ "$c" = eq ]                   && echo satisfied || echo violation ;;
        '<=') { [ "$c" = lt ] || [ "$c" = eq ]; } && echo satisfied || echo violation ;;
        '<')  [ "$c" = lt ]                        && echo satisfied || echo violation ;;
        *)    echo none ;;                         # 알 수 없는 연산자 → 무시
    esac
}
# 하위 호환 별칭: `>=` 의미의 2항 semver 비교(satisfied|violation|skip).
semver_ge() { # <current> <required> → satisfied|violation|skip
    eval_op '>=' "$1" "$2"
}
# 계약 검사: <parent> <dependant-repo> <dep-name> → satisfied|violation|skip|none
# none = 버전 제약 없음/알 수 없는 연산자(이름 의존만). skip = 버전 파싱 불가.
check_contract() { # <parent> <repo> <dep>
    c=$(dep_required_constraint "$1/$2" "$3")
    [ -n "$c" ] || { echo none; return 0; }
    op=${c%% *}; req=${c#* }
    cur=$(read_version "$1/$3")
    [ -n "$cur" ] || { echo skip; return 0; }
    eval_op "$op" "$cur" "$req"
}

# toposort: tests/lib/toposort.sh (단일 원본; read_deps는 tests/lib/deps.sh가 정의 — deps가 먼저 source됨)

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

# --- 다중 자리 마일스톤(M10+) 픽스처 (M14 사소4): sort -V가 M10 > M9 > M2를 올바로 선택 ---
# M2·M9·M10이 공존할 때 최신 마일스톤이 M10(다중 자리)으로 집혀야 한다(단순 사전순이면 M9가 잘못 집힘).
MD="$SBX/multidigit"; mkdir -p "$MD/docs/milestones" "$MD/docs/reports"; git -C "$MD" init -q
printf '# M2\n'  > "$MD/docs/milestones/M2.md"
printf '# M9\n'  > "$MD/docs/milestones/M9.md"
printf '# M10\n' > "$MD/docs/milestones/M10.md"
latest=$(ls "$MD"/docs/milestones/M*.md 2>/dev/null | sort -V | tail -1)
chk "다중 자리: 최신 마일스톤 = M10 (M9 아님)" "$(basename "$latest" .md)" "M10"
# 분류도 최신(M10)을 기준으로 한다: M10-impl만 있고 M10-review 없음 → review 대기.
printf '# M10 impl\n' > "$MD/docs/reports/M10-impl.md"
chk "다중 자리: 분류는 M10 기준(review 대기)" "$(classify "$MD")" "review-pending"
# M9 산출물이 있어도 M10이 최신이라 분류에 영향 없음(정렬이 M10을 집음).
printf '# M9 impl\n' > "$MD/docs/reports/M9-impl.md"
printf '## release verdict\n\n**가능**\n' > "$MD/docs/reports/M9-review.md"
chk "다중 자리: M9 완료 산출물이 있어도 분류는 M10(review 대기)" "$(classify "$MD")" "review-pending"

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

# --- 계약 버전 비교(M17→M20): 전체 연산자 제약 + semver 비교 + upstream behind 경고 ---
# auth(버전 파일 0.2.0) ← 의존측들이 서로 다른 제약/연산자로 의존.
# M20: `>=`·`>`·`=`(`==`)·`<=`·`<` 각각 satisfied/violation, 알 수 없는 연산자 → 무시(none),
#      비표준 버전 → skip. 기존 `>=` 시나리오는 그대로 유지한다.
CT="$SBX/contract"; mkdir -p "$CT"
mk_repo "$CT/auth"; printf '{ "version": "0.2.0" }\n' > "$CT/auth/package.json"   # 현재 0.2.0
mkdep() { mkdir -p "$CT/$1/.tide"; mk_repo "$CT/$1"; printf '%s\n' "$2" > "$CT/$1/.tide/deps"; }
# >= : 만족(현재 0.2.0 >= 0.2.0) / 위반(현재 0.2.0 >= 0.3.0, upstream behind)
mkdep ge_ok     'auth >= v0.2.0'
mkdep ge_bad    'auth >= v0.3.0'
# >  : 만족(0.2.0 > 0.1.0) / 위반(0.2.0 > 0.2.0)
mkdep gt_ok     'auth > v0.1.0'
mkdep gt_bad    'auth > v0.2.0'
# =  : 만족(0.2.0 = 0.2.0) / 위반(0.2.0 = 0.3.0). `==` 동의어도 만족 확인.
mkdep eq_ok     'auth = v0.2.0'
mkdep eq_bad    'auth = v0.3.0'
mkdep eqeq_ok   'auth == v0.2.0'
mkdep eqeq_bad  'auth == v0.3.0'
# <= : 만족(0.2.0 <= 0.2.0) / 위반(0.2.0 <= 0.1.0)
mkdep le_ok     'auth <= v0.2.0'
mkdep le_bad    'auth <= v0.1.0'
# <  : 만족(0.2.0 < 0.3.0) / 위반(0.2.0 < 0.2.0)
mkdep lt_ok     'auth < v0.3.0'
mkdep lt_bad    'auth < v0.2.0'
# 알 수 없는 연산자(`~>`, 기호 포함) → 무시(none, 위반 단정 안 함). 이름 의존은 보존(토포 엣지 유지).
mkdep unkop     'auth ~> v0.1.0'
# 알 수 없는 연산자(`~`, 기호 없음) → 무시(none). 이름 의존 보존(M20-review #1/#4 근원 수정 회귀 고정).
mkdep unksym    'auth ~ v0.1.0'
# 비표준 버전: auth >= banana → 비교 생략(skip)
mkdep badver    'auth >= banana'

chk "계약 >= 만족: auth>=0.2.0, 현재 0.2.0"     "$(check_contract "$CT" ge_ok auth)"   "satisfied"
chk "계약 >= 위반: auth>=0.3.0(upstream behind)" "$(check_contract "$CT" ge_bad auth)" "violation"
chk "계약 > 만족: auth>0.1.0, 현재 0.2.0"       "$(check_contract "$CT" gt_ok auth)"   "satisfied"
chk "계약 > 위반: auth>0.2.0, 현재 0.2.0"       "$(check_contract "$CT" gt_bad auth)"  "violation"
chk "계약 = 만족: auth=0.2.0, 현재 0.2.0"       "$(check_contract "$CT" eq_ok auth)"   "satisfied"
chk "계약 = 위반: auth=0.3.0, 현재 0.2.0"       "$(check_contract "$CT" eq_bad auth)"  "violation"
chk "계약 == 만족: auth==0.2.0(= 동의어)"       "$(check_contract "$CT" eqeq_ok auth)" "satisfied"
chk "계약 == 위반: auth==0.3.0, 현재 0.2.0"     "$(check_contract "$CT" eqeq_bad auth)" "violation"
chk "계약 <= 만족: auth<=0.2.0, 현재 0.2.0"     "$(check_contract "$CT" le_ok auth)"   "satisfied"
chk "계약 <= 위반: auth<=0.1.0, 현재 0.2.0"     "$(check_contract "$CT" le_bad auth)"  "violation"
chk "계약 < 만족: auth<0.3.0, 현재 0.2.0"       "$(check_contract "$CT" lt_ok auth)"   "satisfied"
chk "계약 < 위반: auth<0.2.0, 현재 0.2.0"       "$(check_contract "$CT" lt_bad auth)"  "violation"
chk "알 수 없는 연산자 무시: auth ~> v0.1.0(위반 아님)" "$(check_contract "$CT" unkop auth)" "none"
chk "알 수 없는 연산자 무시: auth ~ v0.1.0(기호 없음, 위반 아님)" "$(check_contract "$CT" unksym auth)" "none"
# 미지 연산자라도 이름 의존은 보존 — read_deps가 바른 이름(auth)을 방출해야 한다(엣지 유실 금지).
chk "미지 연산자(~>) 이름 의존 보존: read_deps=auth" "$(read_deps "$CT/unkop" | tr '\n' ',')" "auth,"
chk "미지 연산자(~) 이름 의존 보존: read_deps=auth"  "$(read_deps "$CT/unksym" | tr '\n' ',')" "auth,"
chk "비표준 버전: auth>=banana(비교 생략)"      "$(check_contract "$CT" badver auth)"  "skip"
# 제약 줄도 위상정렬엔 이름만 반영(버전이 토포를 깨지 않음)
ctord=$(toposort "$CT")
cia=$(idx_of "$ctord" auth); cib=$(idx_of "$ctord" ge_bad)
chk "계약: 버전 제약 줄도 토포 이름 의존 유지(auth 먼저)" "$([ "$cia" -ge 0 ] && [ "$cib" -ge 0 ] && [ "$cia" -lt "$cib" ] && echo yes || echo no)" "yes"
# 미지 연산자 줄도 토포 엣지 보존: unkop·unksym이 auth보다 뒤(auth 의존 유지)
ciu=$(idx_of "$ctord" unkop); cis=$(idx_of "$ctord" unksym)
chk "미지 연산자(~>) 토포 엣지 보존(auth가 unkop보다 앞)" "$([ "$cia" -ge 0 ] && [ "$ciu" -ge 0 ] && [ "$cia" -lt "$ciu" ] && echo yes || echo no)" "yes"
chk "미지 연산자(~) 토포 엣지 보존(auth가 unksym보다 앞)" "$([ "$cia" -ge 0 ] && [ "$cis" -ge 0 ] && [ "$cia" -lt "$cis" ] && echo yes || echo no)" "yes"

# --- BOM 내성(M17): 선두 UTF-8 BOM(EF BB BF) 붙은 .tide/deps의 첫 줄이 올바로 파싱 ---
# 첫 줄이 BOM+주석, 둘째가 의존명 → 주석 무시 + 의존명 정상 인식.
BM="$SBX/bom"; mkdir -p "$BM"
mk_repo "$BM/auth"; printf '{ "version": "0.2.0" }\n' > "$BM/auth/package.json"
mk_repo "$BM/svc"; mkdir -p "$BM/svc/.tide"
printf '\357\273\277# dep file\nauth >= v0.2.0\n' > "$BM/svc/.tide/deps"   # 선두 BOM + 주석 + 의존
chk "BOM 내성: BOM+주석 첫 줄 무시, 의존명 정상 파싱" "$(read_deps "$BM/svc" | tr '\n' ',')" "auth,"
chk "BOM 내성: BOM 붙은 줄의 계약 비교 정상(satisfied)" "$(check_contract "$BM" svc auth)" "satisfied"
# 첫 줄 자체가 BOM+의존명인 경우(주석 없이)도 BOM이 이름 매칭을 깨지 않음.
BM2="$SBX/bom2"; mkdir -p "$BM2"
mk_repo "$BM2/auth"
mk_repo "$BM2/svc"; mkdir -p "$BM2/svc/.tide"
printf '\357\273\277auth\n' > "$BM2/svc/.tide/deps"   # 선두 BOM + 의존명(주석 없음)
chk "BOM 내성: BOM+의존명 첫 줄 이름 매칭" "$(read_deps "$BM2/svc" | tr '\n' ',')" "auth,"

echo
echo "# 결과: PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ] || exit 1
echo "# fleet 발견·5분류·1:1 요약·숨김 무시·강등·다중 자리 마일스톤·위상정렬·순환 폴백·전체 연산자 계약 비교·BOM 내성 확인됨 (참조 구현 기준)"
