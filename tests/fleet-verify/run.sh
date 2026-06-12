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
SBX="${TMPDIR:-/tmp}/tide-fleet-verify-live.$$"
rm -rf "$SBX"; mkdir -p "$SBX"
trap 'rm -rf "$SBX"' EXIT

pass=0; fail=0
chk() { # <desc> <got> <want>
    if [ "$2" = "$3" ]; then pass=$((pass + 1)); printf 'PASS  %-56s (%s)\n' "$1" "$2"
    else fail=$((fail + 1)); printf 'FAIL  %-56s (got %s, want %s)\n' "$1" "$2" "$3"; fi
}

# --- 발견 규약(참조 구현): 직속 1단계, 숨김(.) 무시, git 레포 AND tide 산출물 (fleet 재사용) ---
# `.tide-fleet/`는 숨김(dot) 디렉터리라 자식 레포로 잡히지 않는다(통합 훅 보관소, 자식 아님).
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
        case "$base" in .*) continue ;; esac          # 숨김(dot) 디렉터리 무시(.tide-fleet 포함)
        if is_tide_repo "${d%/}"; then echo "$base"; fi
    done | sort
}

# --- 통합 훅 파싱(참조 구현): `.tide-fleet/integration` 읽기, 선두 BOM 제거, # 주석·빈 줄 무시 ---
strip_bom() { sed '1s/^\xEF\xBB\xBF//'; }
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
printf '\xEF\xBB\xBF# integration hook\n\ndocker compose up -d\nnpm run integration-test\n# trailing comment\n' \
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
printf '\xEF\xBB\xBF# only comments\n\n   \n' > "$EH/.tide-fleet/integration"
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
echo "# fleet-verify 훅 발견/파싱·옵트인 생략·pass/fail 분류·verification-only(무릴리즈/무git)·.tide-fleet 발견 무시 확인됨 (참조 구현 기준)"
