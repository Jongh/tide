#!/bin/sh
# tide fleet-verify 라이브 실증 (POSIX / Git Bash) — 통합 검증 훅의 결정적 핵심
#
# fleet-verify는 프롬프트 스킬이라 실제 통합 훅 실행은 LLM 행위다. 따라서 그 스킬이 따르는
# **결정적 핵심**(훅 발견/파싱=BOM·주석·빈 줄 처리 / 옵트인 생략 / exit 코드→pass·fail 매핑 /
# verification-only=계획에 release·git 없음 / `.tide-fleet/` 발견 무시)을 동일 로직의 **참조 셸
# 절차**로 재현해 픽스처에 대해 회귀 고정한다 — 단일 원본은 `docs/conventions.md` "멀티 레포
# 오케스트레이션"의 통합 검증 절이며, 실제 훅 실행 품질은 README의 세션 레벨 수동 절차로 분리한다.
#
# 주의: git 차단 동사는 이 스크립트 내부 setup에만 둔다(여기선 init만 — commit 불필요). 모의
# 통합 훅은 git 동사를 쓰지 않는 이식 가능한 명령(`exit 0`/`exit 1`)이다. 러너 호출 명령줄엔
# 차단 패턴이 없어야 활성 tide-guard가 막지 않는다. **release·git은 fleet-verify의 동작이 아니다**
# (verification-only) — 이 러너는 자동 계획에 release/git이 없음을 적극 검증한다.
#
# 사용: sh tests/fleet-verify/run.sh   (성공 시 exit 0, 하나라도 실패 시 exit 1)

set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/lib/encoding.sh"   # strip_bom (단일 원본; read_hook가 사용)
. "$ROOT/tests/lib/discover.sh"   # is_tide_repo + discover (단일 원본)
SBX="${TMPDIR:-/tmp}/tide-fleet-verify-live.$$"
rm -rf "$SBX"; mkdir -p "$SBX"
trap 'rm -rf "$SBX"' EXIT

pass=0; fail=0
chk() { # <desc> <got> <want>
    if [ "$2" = "$3" ]; then pass=$((pass + 1)); printf 'PASS  %-56s (%s)\n' "$1" "$2"
    else fail=$((fail + 1)); printf 'FAIL  %-56s (got %s, want %s)\n' "$1" "$2" "$3"; fi
}

# is_tide_repo + discover는 tests/lib/discover.sh로 이관(단일 원본; .tide-fleet 숨김 무시 포함). 위에서 source.

# --- 통합 훅 파싱(참조 구현): `.tide-fleet/integration` 읽기, 선두 BOM 제거, # 주석·빈 줄 무시 ---
# strip_bom은 tests/lib/encoding.sh로 단일 원본화(위에서 source). 여기서 그 정의를 그대로 쓴다.
read_hook() { # <parent> → 유효 통합 명령 줄(들) 출력(없으면 빈)
    f="$1/.tide-fleet/integration"
    [ -f "$f" ] || return 0
    strip_bom < "$f" | while IFS= read -r line || [ -n "$line" ]; do
        trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        case "$trimmed" in ''|'#'*) continue ;; esac
        printf '%s\n' "$trimmed"
    done
}
# 훅 선언 분류: declared(유효 줄 ≥ 1) | skip(파일 없음/유효 줄 0)
hook_class() { # <parent> → declared|skip
    out=$(read_hook "$1")
    [ -n "$(printf '%s' "$out" | tr -d '[:space:]')" ] && echo declared || echo skip
}

# --- pass/fail 분류(참조 구현): 훅을 부모 cwd에서 실행 → exit 0=pass, 비0=fail ---
# 모의 통합 훅을 부모 cwd에서 실행해 exit 코드를 pass/fail로 매핑한다(release/git 미수행).
run_hook() { # <parent> → pass|fail|skip
    case "$(hook_class "$1")" in
        skip) echo skip; return 0 ;;
    esac
    # 유효 명령 줄을 부모 cwd에서 순차 실행; 첫 비0이면 fail.
    rc=0
    while IFS= read -r cmd; do
        ( cd "$1" && sh -c "$cmd" ) >/dev/null 2>&1 || { rc=$?; break; }
    done <<EOF
$(read_hook "$1")
EOF
    [ "$rc" -eq 0 ] && echo pass || echo fail
}

# --- git-verb 가드라일(참조 구현, M20 advisory): 훅 명령에 git/release 토큰이 있으면 경고 ---
# fleet-verify는 verification-only라 통합 훅에 git commit/tag/push·release가 합법적으로 필요한
# 변형은 드물다(major-safe). 훅 실행 전 명령에 그런 토큰이 있으면 경고로 인지시킨다(차단 아님).
# 토큰 매칭은 FIXTURE 문자열에 대한 grep일 뿐 — 이 토큰들은 실행되지 않는다(러너 명령줄 밖).
has_git_verb() { # <command-line> → yes(가드라일 플래그)|no
    # `git` 토큰과 변이 동사(commit/tag/push) 사이에 인자가 있어도 잡는다 — 정석 cross-repo 형태
    # `git -C <dir> push`·`git --git-dir=… commit`가 빠져나가지 않도록(M20-review #5). release 토큰도.
    printf '%s' "$1" | grep -Eiq '(^|[^a-z])git[^a-z].*(commit|tag|push)([^a-z]|$)|[[:space:]]release([^a-z]|$)|^release([^a-z]|$)' \
        && echo yes || echo no
}
# 훅 가드라일 분류: 유효 훅 줄 중 하나라도 git-verb면 warn, 아니면(유효 줄 ≥1) ok, 미선언이면 skip.
hook_guardrail() { # <parent> → ok|warn|skip
    case "$(hook_class "$1")" in skip) echo skip; return 0 ;; esac
    flag=no
    while IFS= read -r cmd; do
        [ "$(has_git_verb "$cmd")" = yes ] && { flag=yes; break; }
    done <<EOF
$(read_hook "$1")
EOF
    [ "$flag" = yes ] && echo warn || echo ok
}

# --- verification-only 표상(참조 구현): 자동 계획 단계열에 release/git 단계 없음 ---
# fleet-verify는 통합 훅(검증/테스트)만 실행한다. 자동 계획은 결코 release/git 단계를 포함하지
# 않는다(부수효과 분리 불변, tide-guard가 phase≠release에서 git 차단). 이 참조는 그 부재를 표상.
plan_stages() { # → 공백 구분 자동화 단계열
    echo "discover hook report"
}
plan_has() { # <stages> <needle> → yes|no
    for s in $1; do [ "$s" = "$2" ] && { echo yes; return 0; }; done
    echo no
}

# --- 픽스처 헬퍼 ---
mk_repo() { mkdir -p "$1/docs/milestones"; git -C "$1" init -q; printf '# M1\n' > "$1/docs/milestones/M1.md"; }

# === 시나리오 ============================================================

# --- (1) 훅 발견/파싱: BOM 제거·주석/빈 줄 무시 → 명령 줄만 추출 ---
HP="$SBX/parse"; mkdir -p "$HP/.tide-fleet"
# 선두 BOM + 주석 + 빈 줄 + 명령 2줄
# BOM 바이트는 **팔진**(`\357\273\277`)으로 쓴다 — `\xHH`는 POSIX printf에 없는 확장이라
# dash(우분투의 `/bin/sh`)가 이스케이프를 해석하지 않고 `\xEF\xBB\xBF` **글자 그대로** 내보낸다.
# 그러면 이 픽스처에 BOM이 아예 들어가지 않아 아래 BOM 케이스 4개가 FAIL한다(M37 재작업 4의
# CI 첫 실행이 우분투 레그에서 잡은 결함 — 로컬 Git Bash는 sh=bash라 일곱 라운드 동안 보이지 않았다).
printf '\357\273\277# integration hook\n\ndocker compose up -d\nnpm run integration-test\n# trailing comment\n' \
    > "$HP/.tide-fleet/integration"
parsed=$(read_hook "$HP" | tr '\n' '|' | sed 's/|$//')
chk "훅 파싱: BOM·주석·빈 줄 제거 후 명령 2줄" "$parsed" "docker compose up -d|npm run integration-test"
chk "훅 파싱: 분류 = declared"                "$(hook_class "$HP")" "declared"

# 선두 BOM이 첫 명령에 섞이지 않음(BOM 내성)
first=$(read_hook "$HP" | head -1)
chk "훅 파싱: 첫 줄 선두 BOM 제거됨" "$first" "docker compose up -d"

# --- (2) 옵트인 생략: 훅 파일 없음 / 빈 파일 → skip ---
NH="$SBX/nohook"; mkdir -p "$NH"
chk "옵트인 생략: 훅 파일 없음 → skip" "$(hook_class "$NH")" "skip"
EH="$SBX/emptyhook"; mkdir -p "$EH/.tide-fleet"
printf '\357\273\277# only comments\n\n   \n' > "$EH/.tide-fleet/integration"   # 팔진 — 위 주석 참조
chk "옵트인 생략: 주석·빈 줄뿐(유효 0) → skip" "$(hook_class "$EH")" "skip"
chk "옵트인 생략: skip이면 실행 분류도 skip"    "$(run_hook "$EH")" "skip"

# --- (3) pass/fail 분류: 모의 훅 exit 코드 → pass/fail (git 동사 미사용) ---
OK="$SBX/passhook"; mkdir -p "$OK/.tide-fleet"
printf 'exit 0\n' > "$OK/.tide-fleet/integration"
chk "pass/fail: 훅이 exit 0 → pass" "$(run_hook "$OK")" "pass"
BAD="$SBX/failhook"; mkdir -p "$BAD/.tide-fleet"
printf 'exit 1\n' > "$BAD/.tide-fleet/integration"
chk "pass/fail: 훅이 exit 1 → fail" "$(run_hook "$BAD")" "fail"
# 다단계: 첫 명령 성공, 둘째 명령 실패 → 전체 fail
MULTI="$SBX/multifail"; mkdir -p "$MULTI/.tide-fleet"
printf 'exit 0\nexit 1\n' > "$MULTI/.tide-fleet/integration"
chk "pass/fail: 다단계 중 하나라도 비0 → fail" "$(run_hook "$MULTI")" "fail"

# --- (4) verification-only 표상: 자동 계획에 release/git 단계 없음 ---
stages=$(plan_stages)
chk "verification-only: 자동 단계열 = discover hook report" "$stages" "discover hook report"
chk "verification-only: 자동 계획에 release 단계 없음"      "$(plan_has "$stages" release)" "no"
chk "verification-only: 자동 계획에 git 단계 없음"          "$(plan_has "$stages" git)" "no"
chk "verification-only: 자동 단계열이 report로 종료(릴리즈 아님)" "$(echo $stages | awk '{print $NF}')" "report"

# --- (4b) verification-only를 SKILL 아티팩트에 결합 — 금지 산문이 회귀하면 fail (적대 리뷰 대응) ---
# 위 (4)는 자동 단계열 표상일 뿐이라, 불변을 실제로 강제하는 스킬 산문(금지 목록·verification-only/
# phase=release 백스톱)이 삭제되면 fail하도록 실제 SKILL.md를 grep해 결합한다.
SKILL_FILE="$(cd "$(dirname "$0")/../.." && pwd)/skills/fleet-verify/SKILL.md"
chk "verification-only(스킬 결합): 금지 목록 산문 존재" \
    "$([ -f "$SKILL_FILE" ] && grep -qF 'release / git commit / git tag / git push / cross-repo git' "$SKILL_FILE" && echo yes || echo no)" "yes"
chk "verification-only(스킬 결합): verification-only 산문 존재" \
    "$([ -f "$SKILL_FILE" ] && grep -qF 'verification-only' "$SKILL_FILE" && echo yes || echo no)" "yes"

# --- (4c) 통합 훅 git-verb 가드라일(M20 advisory): git/release 토큰 → warn, 클린 훅 → ok ---
# 훅 명령 내부의 git 토큰은 FIXTURE 문자열일 뿐 실행되지 않는다(가드라일은 실행 전 점검·경고).
GV="$SBX/guardrail-git"; mkdir -p "$GV/.tide-fleet"
printf 'git push\n' > "$GV/.tide-fleet/integration"     # git 누수 가능 훅(FIXTURE) → 경고
chk "가드라일: 훅에 git push → warn"          "$(hook_guardrail "$GV")" "warn"
chk "가드라일: has_git_verb(git push)=yes"    "$(has_git_verb 'git push')" "yes"
GR="$SBX/guardrail-release"; mkdir -p "$GR/.tide-fleet"
printf 'npm run release\n' > "$GR/.tide-fleet/integration"  # release 토큰(FIXTURE) → 경고
chk "가드라일: 훅에 release 토큰 → warn"      "$(hook_guardrail "$GR")" "warn"
CL="$SBX/guardrail-clean"; mkdir -p "$CL/.tide-fleet"
printf '# verify only\nnpm test\ndocker compose up -d\n' > "$CL/.tide-fleet/integration"  # 클린 훅
chk "가드라일: 클린 훅(npm test) → ok"        "$(hook_guardrail "$CL")" "ok"
chk "가드라일: has_git_verb(npm test)=no"     "$(has_git_verb 'npm test')" "no"
# 정석 cross-repo 형태(git과 동사 사이 인자)도 잡아야 한다(M20-review #5 회귀 고정).
CR="$SBX/guardrail-crossrepo"; mkdir -p "$CR/.tide-fleet"
printf 'git -C ../svc-auth push\n' > "$CR/.tide-fleet/integration"   # cross-repo git(FIXTURE) → 경고
chk "가드라일: 훅에 git -C <dir> push → warn"  "$(hook_guardrail "$CR")" "warn"
chk "가드라일: has_git_verb(git -C dir push)=yes" "$(has_git_verb 'git -C ../svc-auth push')" "yes"
chk "가드라일: has_git_verb(git --git-dir=… commit)=yes" "$(has_git_verb 'git --git-dir=svc/.git commit -m x')" "yes"
# 읽기 전용 git(git status)은 변이 동사가 없으므로 경고하지 않는다(오탐 방지).
chk "가드라일: has_git_verb(git status)=no(읽기 전용)" "$(has_git_verb 'git -C ../svc status')" "no"
# 다단계 중 하나라도 git-verb면 전체 warn(클린 줄과 혼합돼도 누수 인지).
MX="$SBX/guardrail-mixed"; mkdir -p "$MX/.tide-fleet"
printf 'npm test\ngit commit -m x\n' > "$MX/.tide-fleet/integration"   # 클린+git 혼합(FIXTURE)
chk "가드라일: 클린+git 혼합 → warn"          "$(hook_guardrail "$MX")" "warn"
# 미선언이면 가드라일도 skip(옵트인 불변)
chk "가드라일: 훅 미선언 → skip"              "$(hook_guardrail "$NH")" "skip"

# --- (5) `.tide-fleet/` 발견 무시: 숨김 디렉터리라 자식 레포로 안 잡힘 ---
DS="$SBX/discover"; mkdir -p "$DS"
mk_repo "$DS/auth"
mk_repo "$DS/orders"
mkdir -p "$DS/.tide-fleet"; printf 'exit 0\n' > "$DS/.tide-fleet/integration"
# .tide-fleet 안에 가짜 tide 산출물을 둬도(숨김 무시라) 발견되면 안 됨
mkdir -p "$DS/.tide-fleet/docs/milestones"; git -C "$DS/.tide-fleet" init -q 2>/dev/null
disc=$(discover "$DS" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
chk "발견 무시: 자식 레포만 = auth orders" "$disc" "auth orders"
chk "발견 무시: .tide-fleet 미포함"        "$(discover "$DS" | grep -c '\.tide-fleet')" "0"
chk "발견 무시: 발견 2노드(숨김 제외)"     "$(discover "$DS" | wc -l | tr -d ' ')" "2"

echo
echo "# 결과: PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ] || exit 1
echo "# fleet-verify 훅 발견/파싱·옵트인 생략·pass/fail 분류·verification-only(무릴리즈/무git)·git-verb 가드라일·.tide-fleet 발견 무시 확인됨 (참조 구현 기준)"
