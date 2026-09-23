#!/bin/sh
# tide discover 라이브 실증 (POSIX / Git Bash) — 멀티 레포 맥락 감지 힌트 + 커맨드 수 드리프트 가드
#
# status·kickoff의 멀티 레포 맥락 감지 힌트(M21)는 프롬프트 스킬 행위라 실행 바이너리가 없다.
# 따라서 그 스킬이 인용하는 **결정적 핵심**(fleet 발견 규약 재사용 + 감지 임계값 ≥2 → hint|none)을
# 동일 로직의 **참조 셸 절차**로 재현해 픽스처에 대해 회귀 고정한다 — 단일 원본은
# `docs/conventions.md`의 "멀티 레포 오케스트레이션"(발견) 절 + 발견성 힌트 항목이다.
# advisory 서술 품질은 세션 레벨 수동 절차로 분리한다(README 참조).
#
# 또한 M20 리뷰 #6(사이트 커맨드 수 표류, 8종↔11종)의 회귀 고정으로, `skills/*/SKILL.md`로 존재하는
# **실제 커맨드 스킬 개수**와 캐노니컬 문서·사이트가 선언하는 "N종" 수가 어긋나면 FAIL하는 가드를 둔다.
#
# Part C(M30)는 같은 부류의 드리프트를 하나 더 집행한다 — **여러 파일이 같은 사실을 선언**할 때
# 한 곳만 고치면 조용히 갈라지는 문제다(Part B의 커맨드 수와 동형). 대상은 debug 항목 **상태값 집합**
# (conventions·debug SKILL·debug 템플릿 세 곳)과 **변경 파일 요약 기준선**(milestone·impl·debug 세 템플릿).
#
# Part F(M33)는 문서가 **자기 자신에 대해 하는 서술**을 집행한다 — 하니스 케이스 수(이 README의
# `cases: N` 선언 vs 실제 케이스 수)와 커맨드 **역할 앵커**(캐노니컬 `role-anchors:` 맵 → 캐노니컬
# 표 행 실재 + 소비자 문서 전파). 단일 원본은 conventions "문서 자기서술 정합" 절.
#
# Part G(M34 · M35 일반화)는 문서 **사이를 잇는 참조**를 집행한다 — 살아 있는 문서의 인용을 추출해
# **규약 문서 집합**(글롭 `docs/conventions*.md`)의 `##`·`###` 앵커에 실재하는지 **파일별로** 대조한다
# (+ 추출 0건·집합 전체 이름 중복·줄바꿈 인용 통제). 단일 원본은 같은 절의 "상호참조 무결성" 소절.
#
# 주의: git 차단 동사는 이 스크립트 내부 setup에만 둔다(여기선 init만 — commit 불필요).
# 러너 호출 명령줄엔 차단 패턴이 없어야 활성 tide-guard가 막지 않는다.
#
# 사용: sh tests/discover/run.sh        (전수 — 성공 시 exit 0, 하나라도 실패 시 exit 1)
#       sh tests/discover/run.sh W      (부분 — 파트 표지 하나만 돈다, M64-T03)
#
# Part 선택(M64-T03): 인자가 없으면 **현행 그대로 전수**가 돈다(하위 호환이 계약이다). 인자를 주면
# 그 파트의 케이스 계산 구간만 돌고 나머지는 **실제로 건너뛴다** — `chk` 호출만 거르면 계산이 그대로
# 돌아 절감이 0이 되므로, 가드는 `chk`가 아니라 **계산 구간**을 감싼다. 함수 정의와 파트를 건너
# 쓰이는 경로 상수는 가드 **밖**에 둔다(뒤 파트가 앞 파트의 헬퍼를 쓴다).

set -u

# 레포 루트는 스크립트 위치에서 해석(tests/fleet 규약과 동일).
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
. "$ROOT/tests/lib/discover.sh"

SBX="${TMPDIR:-/tmp}/tide-discover-live.$$"
rm -rf "$SBX"; mkdir -p "$SBX"
trap 'rm -rf "$SBX"' EXIT

pass=0; fail=0
chk() { # <desc> <got> <want>
    if [ "$2" = "$3" ]; then pass=$((pass + 1)); printf 'PASS  %-56s (%s)\n' "$1" "$2"
    else fail=$((fail + 1)); printf 'FAIL  %-56s (got %s, want %s)\n' "$1" "$2" "$3"; fi
}

# --- 파트 선택 (M64-T03) ------------------------------------------------
# 표지 명단은 **러너가 탐침으로 갖는다**(C-3의 캐노니컬 이름과 같은 형태) — 선언처는 그 하니스
# README의 `cases:` 한 줄이고, `F18`이 그 줄의 파트 표지와 이 명단을 대조한다. 명단에 없는 표지를
# 주면 **조용한 0케이스 초록이 아니라 FAIL**이다(F3·F4와 같은 positive-control 형태).
PART_SEL=${1-}
PART_LABELS='A B C D E F G H I J K L M N O P Q R S T U V W'
part_known() { # <표지> → yes|no
    case " $PART_LABELS " in
        *" $1 "*) echo yes ;;
        *)        echo no ;;
    esac
}
part_on() {   # <표지> → 선택이 없으면(전수) 참, 선택과 같으면 참
    [ -z "$PART_SEL" ] || [ "$PART_SEL" = "$1" ]
}
part_full() { [ -z "$PART_SEL" ]; }   # 전수 실행인가
# **결과 줄의 형태를 갈라 둔다**(M64-T03) — 같은 형태면 부분 총계를 그대로 보고서에 옮겨도 사람이
# 못 알아챈다. 접두가 다른 것이 그 경로를 닫고, `F20`이 그 다름을 **같은 함수로** 확인한다.
RESULT_FULL_PREFIX='# 결과:'
result_prefix() { # [표지] → 결과 줄 접두(표지가 없으면 전수 접두)
    if [ -z "${1-}" ]; then printf '%s' "$RESULT_FULL_PREFIX"
    else printf '# 부분 결과(Part %s):' "$1"; fi
}
if [ -n "$PART_SEL" ] && [ "$(part_known "$PART_SEL")" = no ]; then
    printf 'FAIL  %-56s (got %s, want one of %s)\n' "part-select: 없는 파트 표지" "$PART_SEL" "$PART_LABELS"
    echo
    echo "$(result_prefix "$PART_SEL") PASS=0 FAIL=1"
    exit 1
fi

# === Part A — 감지 임계값 (detection threshold) =========================

# is_tide_repo/discover: tests/lib/discover.sh (단일 원본)

# --- 감지 힌트(참조 구현): 자식 tide 레포 수를 세고 ≥2면 hint, 미만이면 none ---
# 출력: 발견 수 ≥ 2 → "hint N=<count>"; 0·1개 → "none". (status·kickoff advisory 임계값 재현)
detect_hint() { # <parent> → "hint N=<count>" | "none"
    n=$(discover "$1" | grep -c .)
    if [ "$n" -ge 2 ]; then echo "hint N=$n"; else echo "none"; fi
}

# --- 픽스처 헬퍼: 디렉터리 선생성 후 git init(차단 동사 없음 — init만) ---
mk_tide_repo() { # <dir> — git 레포 + tide 산출물(milestone)
    mkdir -p "$1/docs/milestones"; git -C "$1" init -q; printf '# M1\n' > "$1/docs/milestones/M1.md"
}

# --- 픽스처 ---
# (A1) 부모에 자식 tide 레포 2개 → hint N=2
if part_on A; then
P2="$SBX/parent2"; mkdir -p "$P2"
mk_tide_repo "$P2/svc-auth"
mk_tide_repo "$P2/svc-orders"

# (A2) 부모에 자식 tide 레포 1개 → none
P1="$SBX/parent1"; mkdir -p "$P1"
mk_tide_repo "$P1/only-svc"

# (A3) 부모에 자식 tide 레포 0개 → none (비-tide 폴더만)
P0="$SBX/parent0"; mkdir -p "$P0/just-a-folder"
printf 'x\n' > "$P0/just-a-folder/readme.txt"

# (A4) 단일 레포 루트 — 자식이 src/ 등 비-tide → none (일반 단일 레포 세션)
SR="$SBX/single-repo"; mkdir -p "$SR/docs/milestones" "$SR/src" "$SR/docs"; git -C "$SR" init -q
printf '# M1\n' > "$SR/docs/milestones/M1.md"
printf 'export const x = 1;\n' > "$SR/src/index.ts"
# 단일 레포 자체는 tide 레포지만, 그 직속 자식(src·docs)은 git+tide 산출물 보유 레포가 아니다.

# (A5) 부모에 자식 tide 레포 2개 + 숨김 tide 자식(.hidden-svc) → hint N=2 (숨김 미카운트)
PH="$SBX/parenthidden"; mkdir -p "$PH"
mk_tide_repo "$PH/svc-a"
mk_tide_repo "$PH/svc-b"
mk_tide_repo "$PH/.hidden-svc"     # 숨김(dot) → 발견 제외(tide 산출물 있어도)
fi

# --- Part A 시나리오 ---
if part_on A; then
chk "A: 자식 tide 레포 2개 → hint N=2"            "$(detect_hint "$P2")" "hint N=2"
chk "A: 자식 tide 레포 1개 → none"                "$(detect_hint "$P1")" "none"
chk "A: 자식 tide 레포 0개 → none"                "$(detect_hint "$P0")" "none"
chk "A: 단일 레포 루트(자식 src 등 비-tide) → none" "$(detect_hint "$SR")" "none"
chk "A: 자식 2개 + 숨김 tide 자식 → hint N=2(숨김 미카운트)" "$(detect_hint "$PH")" "hint N=2"
chk "A: 숨김 자식(.hidden-svc) 미발견"             "$(discover "$PH" | grep -c hidden)" "0"
chk "A: 발견 = svc-a,svc-b (숨김 제외)"            "$(discover "$PH" | tr '\n' ',')" "svc-a,svc-b,"
fi

# === Part B — 단일 원본 동결: 카탈로그 단일 원본 + 드리프트 가드 ==========
# (M22) 커맨드 카탈로그를 docs/commands.md 단일 원본으로 끌어오고, 사이트는 스니펫 셸이다.
# 가드는 (B1) 카운트 선언 정합, (B2) 사이트 카탈로그 페이지가 셸(재복제 아님),
# (B3) 카탈로그 완전성(각 커맨드 이름 등장)을 검증한다 — M20 리뷰 #6 회귀 고정의 확장.

# 실제 커맨드 스킬 개수 = skills/*/SKILL.md 파일 수.
# (M38-T04) 의미는 **"점으로 시작하는 디렉터리는 커맨드 스킬이 아니다"** 이고, 이 글롭이 그 의미를
# 공짜로 만족한다(POSIX 글롭은 선행 점 성분을 매치하지 않는다). ps1의 `Get-ChildItem -Directory`는
# 점 디렉터리를 **포함**하므로 그쪽에 같은 의미의 점 필터를 명시했다 — 없던 동안 `skills/.spare/SKILL.md`
# 하나로 sh 85/0 exit 0 vs ps1 79/6 exit 1로 갈렸다(같은 러너의 Part G는 점 필터를 갖고 있어
# **한 러너 안에서 파트끼리 규율이 달랐다**). 범위 표의 Part B 가지가 이 의미의 선언처다.
N=$(ls "$ROOT"/skills/*/SKILL.md 2>/dev/null | grep -c .)
if part_on B; then
chk "B: 실제 커맨드 스킬 개수 측정(>0)" "$([ "$N" -gt 0 ] && echo ok || echo no)" "ok"
fi

README="$ROOT/README.md"
CONV="$ROOT/docs/conventions.md"
CANON_CMD="$ROOT/docs/commands.md"        # 새 캐노니컬 커맨드 카탈로그(단일 원본)
if part_on B; then
SITE_CMD="$ROOT/site/docs/commands.md"    # 사이트 셸(스니펫 인클루드)
fi
SITE_GS="$ROOT/site/docs/getting-started.md"
if part_on B; then
ORCH="$ROOT/docs/orchestration.md"       # 사이트 본문으로 인클루드되는 오케스트레이션 안내(카운트 선언 보유)
fi

# (B1) 카운트 선언 정합 — "N종"(예: 11종) 선언 파일이 실제 스킬 수와 일치(불일치면 FAIL).
#      site/docs/commands.md는 이제 셸이라 카운트 비보유 → 캐노니컬 docs/commands.md로 대체.
declared_has_count() { # <file> <N> → yes|no
    [ -f "$1" ] && grep -qF "${2}종" "$1" && echo yes || echo no
}
if part_on B; then
chk "B1: docs/commands.md 가 ${N}종 선언(캐노니컬)"     "$(declared_has_count "$CANON_CMD" "$N")" "yes"
chk "B1: README.md 가 ${N}종 선언"                     "$(declared_has_count "$README" "$N")" "yes"
chk "B1: docs/conventions.md 가 ${N}종 선언"           "$(declared_has_count "$CONV" "$N")" "yes"
chk "B1: site/docs/getting-started.md 가 ${N}종 선언"  "$(declared_has_count "$SITE_GS" "$N")" "yes"
chk "B1: docs/orchestration.md 가 ${N}종 선언"          "$(declared_has_count "$ORCH" "$N")" "yes"
fi

# (B2) 사이트 카탈로그 페이지가 스니펫 셸인지 — 인클루드 보유 AND 카운트·카탈로그 표 미재선언.
#      재수기화(카탈로그 복귀) 시 FAIL → 단일 원본화를 강제한다.
is_snippet_shell() { # <file> <N> → yes|no
    [ -f "$1" ] || { echo no; return; }
    grep -qF '8<-- "docs/commands.md:body"' "$1" || { echo no; return; }   # 스니펫 인클루드 보유
    grep -qF "${2}종" "$1" && { echo no; return; }                          # 카운트 재선언 = 셸 아님
    grep -qF '|---|---|---|---|' "$1" && { echo no; return; }               # 카탈로그 표 재선언 = 셸 아님
    echo yes
}
if part_on B; then
chk "B2: site/docs/commands.md 는 스니펫 셸(재복제 아님)" "$(is_snippet_shell "$SITE_CMD" "$N")" "yes"
fi

# (B3) 카탈로그 완전성 — 각 커맨드 이름이 캐노니컬 카탈로그에 /tide:<name> 으로 등장.
#      개수만 맞고 이름이 빠지거나 바뀐 표류(개수 가드가 못 잡던 것)를 적발한다.
#      이름 뒤 경계(영문·하이픈 아님)를 요구해 prefix 오탐을 막는다 — /tide:fleet 이
#      /tide:fleet-cycle 에 substring으로 걸려 거짓 통과하지 않도록(fleet ≠ fleet-cycle).
has_command() { # <file> <name> → yes|no
    [ -f "$1" ] && grep -qE "/tide:$2([^a-z-]|$)" "$1" && echo yes || echo no
}
if part_on B; then
allnames_ok=yes
for skill in "$ROOT"/skills/*/SKILL.md; do
    name=$(basename "$(dirname "$skill")")
    [ "$(has_command "$CANON_CMD" "$name")" = yes ] || allnames_ok=no
done
chk "B3: 모든 커맨드 이름이 docs/commands.md 카탈로그에 등장" "$allnames_ok" "yes"

# 음성 통제 — 이름: 존재하지 않는 가짜 커맨드(/tide:bogus)는 카탈로그에 없어야 한다(이름 검사 구별력).
chk "B3: 이름 통제 — /tide:bogus 카탈로그에 없음" "$(has_command "$CANON_CMD" "bogus")" "no"

# 음성 통제 — 개수: 실제와 다른 수(N+1종)는 어느 카운트 선언 파일에도 없어야 한다(드리프트면 잡힘).
WRONG=$((N + 1))
chk "B1: 드리프트 통제 — docs/commands.md에 ${WRONG}종 없음" "$(declared_has_count "$CANON_CMD" "$WRONG")" "no"
chk "B1: 드리프트 통제 — README에 ${WRONG}종 없음"          "$(declared_has_count "$README" "$WRONG")" "no"
chk "B1: 드리프트 통제 — conventions에 ${WRONG}종 없음"     "$(declared_has_count "$CONV" "$WRONG")" "no"
chk "B1: 드리프트 통제 — site/getting-started에 ${WRONG}종 없음" "$(declared_has_count "$SITE_GS" "$WRONG")" "no"
chk "B1: 드리프트 통제 — orchestration에 ${WRONG}종 없음"  "$(declared_has_count "$ORCH" "$WRONG")" "no"
fi

# === Part C — 선언 정합 드리프트 가드 ====================================
# (M30) Part B가 "같은 사실을 여러 문서가 선언할 때의 드리프트"(커맨드 수)를 집행하듯, 아래 둘도
# 정확히 같은 부류다 — 여러 파일이 같은 사실을 선언하고, 한 곳만 고치면 조용히 갈라진다.
# (C1) debug 항목 **상태값 집합**(네 값)이 conventions·debug SKILL·debug 템플릿 세 곳 전부에 등장,
# (C2) **변경 파일 요약 기준선** 선언이 milestone·impl·debug 세 템플릿 전부에 등장.
# 단일 원본은 `docs/conventions.md`의 "debug 세션"(항목 상태값) 절 + "변경 파일 요약 기준선" 절이며,
# 이 러너는 선언이 갈라지는 것을 회귀로 고정한다(문구 품질이 아니라 **선언 존재**를 결합 조건으로 둔다).

DBG_SKILL="$ROOT/skills/debug/SKILL.md"
DBG_TPL="$ROOT/skills/debug/template.md"
MS_TPL="$ROOT/skills/milestone/template.md"
IMPL_TPL="$ROOT/skills/impl/template.md"

has_token() { # <file> <token> → yes|no
    [ -f "$1" ] && grep -qF "$2" "$1" && echo yes || echo no
}
in_all_three() { # <token> <f1> <f2> <f3> → yes|no
    for f in "$2" "$3" "$4"; do
        [ "$(has_token "$f" "$1")" = yes ] || { echo no; return; }
    done
    echo yes
}

# (C1) 상태값 선언 정합 — 네 값이 세 파일 전부에 등장(한 곳만 고치면 FAIL).
if part_on C; then
for st in 수정함 미해결 "원인만 규명" 확인함; do
    chk "C1: 상태값 '$st' 세 파일 전부에 등장" "$(in_all_three "$st" "$CONV" "$DBG_SKILL" "$DBG_TPL")" "yes"
done

# 음성 통제 — 상태값: 존재하지 않는 상태값(보류함)은 세 파일 **어디에도** 없어야 한다.
# 가드가 살아 있음(구별력)을 입증한다 — Part B의 `N+1종` 부재 통제와 동일 취지.
chk "C1: 상태값 통제 — conventions에 '보류함' 없음"   "$(has_token "$CONV" "보류함")" "no"
chk "C1: 상태값 통제 — debug SKILL에 '보류함' 없음"   "$(has_token "$DBG_SKILL" "보류함")" "no"
chk "C1: 상태값 통제 — debug 템플릿에 '보류함' 없음"  "$(has_token "$DBG_TPL" "보류함")" "no"

# (C2) 기준선 선언 정합 — 같은 추가/수정/삭제 표를 쓰는 세 템플릿 전부가 기준선을 명시한다.
#      한 템플릿만 고치면 표의 의미가 파일마다 갈라진다(그 자체가 드리프트).
chk "C2: skills/milestone/template.md 가 기준선 선언" "$(has_token "$MS_TPL" "기준선")" "yes"
chk "C2: skills/impl/template.md 가 기준선 선언"      "$(has_token "$IMPL_TPL" "기준선")" "yes"
chk "C2: skills/debug/template.md 가 기준선 선언"     "$(has_token "$DBG_TPL" "기준선")" "yes"

# (C3) phase 기록 커맨드 **명단**(M37) — 규약이 그 명단의 **유일한 열거처**를 자기 절로 정하고
#      발행 페이지 `site/docs/concepts.md` 하나만 예외로 뒀다. 이 케이스가 그 선언을 집행한다.
#      규약의 선언이 **두 명단**(phase를 쓰는 6종 · 쓰지 않는 6종)을 함께 걸었으므로 집행도 **둘 다**
#      문다 — 선언 범위와 집행 범위를 같은 넓이로 둔다(M37 리뷰 차단 #1).
#        - **기록 명단**: 여섯 이름이 **한 줄에 모두** 있으면서 `phase` 문맥인 줄(커맨드 카탈로그
#          행은 phase 문맥이 아니라 걸리지 않는다).
#        - **비기록 명단**: 두 파일 모두 문장으로 풀어 써 **여러 줄에 걸치므로** 여섯 이름이 모두
#          드는 **가장 짧은 연속 줄 묶음(창, 최대 4줄)** 으로 뽑는다.
#      **캐노니컬 이름은 이 러너가 탐침(needle)으로 갖는다** — 기록 6종은 `grep -F` 리터럴 연쇄,
#      비기록 6종은 awk `index` 리터럴이다. 드리프트 표면이 없어진 것이 아니라 러너로 **옮겨졌다**
#      (커맨드 이름을 바꾸면 러너 두 사본도 함께 고친다). 다만 러너는 명단을 **선언**하지 않고
#      탐침만 하므로 이름이 어긋나면 추출이 0이 되어 개수 케이스가 **크게 FAIL**한다(공허 통과 아님).
#      무는 것: 개수 · 두 파일의 집합 일치(양쪽이 다 비면 `no`) · 열거 파일이 그 둘뿐 ·
#      기록∩비기록 = 공집합 · 음성 통제.
CONCEPTS="$ROOT/site/docs/concepts.md"
fi

roster_line() { # <file> → 명단 줄(없으면 빈 출력)
    [ -f "$1" ] || return 0
    # (M50) 이전에는 `grep -F`를 **일곱 번 이어 붙이고** `head -1`을 더해 파일마다 8 프로세스를 썼다.
    # 이 함수는 파일마다 도는 루프 셋에서 불리므로 그 8이 그대로 곱해졌다. awk 한 번이 같은 판정을
    # 한다 — 일곱 토큰이 **모두 든 첫 줄**이고, `index`로 물어 **고정 문자열 검색**이라는 성질을
    # 코드에 남긴다(원래의 `grep -F`와 같은 의미다. 토큰에 정규식 메타문자가 없어 결과도 같다).
    LC_ALL=C awk '
        index($0, "phase") && index($0, "milestone") && index($0, "impl") &&
        index($0, "review") && index($0, "release") && index($0, "debug") &&
        index($0, "cycle") { print; exit }' "$1"
}
roster_set() { # <file> → 명단 줄의 백틱 토큰 집합(정렬·공백 구분)
    roster_line "$1" | grep -oE '`[a-z][a-z-]*`' | tr -d '`' | LC_ALL=C sort -u       | tr '
' ' ' | sed 's/ *$//'
}
roster_count() { # <file> → 명단 이름 개수
    roster_set "$1" | tr ' ' '
' | grep -c '[a-z]'
}
roster_has() { # <file> <name> → yes|no
    case " $(roster_set "$1") " in *" $2 "*) echo yes ;; *) echo no ;; esac
}
# C-3 자신의 훑는 대상(살아 있는 문서·스킬·훅) — 두 명단이 **같은 범위**를 훑는다. 이름을
# `living_docs`로 두지 않는다: Part G가 **다른 범위**의 동명 함수를 갖고 있어(`tests/*/README.md`
# 포함·훅 제외) 두 정의가 같은 이름이면 C-3의 범위가 **어느 정의가 나중에 실행됐는지**에 달린다
# (M37 리뷰 권장 #2). 범위의 의미는 **재귀 + 점 제외**다 — `skills/`를 양 셸 모두 재귀로 훑되
# **점(`.`)으로 시작하는 파일·디렉터리는 양쪽 다 제외**한다(여기는 `-prune`, `run.ps1`은 **레포
# 상대 경로**의 성분 검사). 러너의 다른 스캔이 전부 글롭이라 점을 자연히 제외하는 것과 같은 의미이며,
# 한쪽만 제외하면 두 셸이 다른 집합을 훑어 판정이 갈린다(M37 리뷰 차단 — 그때는 ps1이 **절대경로**를
# 봐서 레포가 점 디렉터리 아래 있으면 `skills/**`가 통째로 빠졌다).
# `docs/milestones/`·`docs/reports/`는 시점 기록물이라 여기 들지 않는다.
roster_scan_files() { # → 대상 파일 절대 경로(한 줄에 하나)
    for f in "$ROOT/README.md" "$ROOT"/docs/*.md "$ROOT"/site/docs/*.md              "$ROOT/hooks/tide-guard.sh" "$ROOT/hooks/tide-guard.ps1"; do
        [ -f "$f" ] && printf '%s
' "$f"
    done
    # `-name '.*' -prune`은 **방문 지점의 basename**만 본다 — 시작점(`$ROOT/skills`) 위쪽 경로에
    # 점 성분이 있어도 영향을 주지 않는다(레포 상대 경로 기준이라는 뜻).
    [ -d "$ROOT/skills" ] && find "$ROOT/skills" -name '.*' -prune -o -type f -name '*.md' -print
    return 0
}
roster_files() { # → 명단 줄을 가진 살아 있는 문서(레포 상대 경로, 정렬·공백 구분)
    roster_scan_files | while IFS= read -r f; do
        [ -n "$(roster_line "$f")" ] && printf '%s
' "${f#"$ROOT"/}"
    done | LC_ALL=C sort -u | tr '
' ' ' | sed 's/ *$//'
}

# 비기록 명단(phase를 쓰지 않는 6종) — 두 파일 모두 산문으로 풀어 써 **여러 줄에 걸친다**. 그래서
# 여섯 이름이 모두 드는 **가장 짧은 연속 줄 묶음(창)** 을 뽑는다(최대 4줄 — 실측 스팬은 규약 2줄·
# 발행 페이지 3줄). **상한을 넘으면 창을 찾지 못하고** 개수 케이스가 크게 FAIL한다 — 그 상한이
# 집행 경계이며 `run.ps1`과 같은 값이다(awk는 대소문자를 구분해 `W`와 `w`가 별개다 — ps1은 그렇지
# 않아 M37 리뷰 차단 #1이 났다). 창의 무관한 백틱 토큰(`.gitignore` 등)을 거르는 것은 창의
# 최소성이 아니라 아래 추출 정규식이다.
nonwriter_window() { # <file> → 창 텍스트(없으면 빈 출력)
    [ -f "$1" ] || return 0
    awk 'BEGIN { W = 4 }
        { L[NR] = $0 }
        END {
            for (w = 1; w <= W; w++)
                for (i = 1; i + w - 1 <= NR; i++) {
                    s = ""
                    for (k = i; k <= i + w - 1; k++) s = s "\n" L[k]
                    if (index(s, "`status`") && index(s, "`fleet`") && index(s, "`retro`") &&
                        index(s, "`fleet-verify`") && index(s, "`kickoff`") && index(s, "`fleet-cycle`")) {
                        print s
                        exit
                    }
                }
        }' "$1"
}
nonwriter_set() { # <file> → 창의 백틱 토큰 집합(정렬·공백 구분)
    nonwriter_window "$1" | grep -oE '`[a-z][a-z-]*`' | tr -d '`' | LC_ALL=C sort -u       | tr '
' ' ' | sed 's/ *$//'
}
nonwriter_count() { # <file> → 비기록 명단 이름 개수
    nonwriter_set "$1" | tr ' ' '
' | grep -c '[a-z]'
}
nonwriter_has() { # <file> <name> → yes|no
    case " $(nonwriter_set "$1") " in *" $2 "*) echo yes ;; *) echo no ;; esac
}
nonwriter_files() { # → 비기록 명단 창을 가진 살아 있는 문서(레포 상대 경로)
    roster_scan_files | while IFS= read -r f; do
        [ -n "$(nonwriter_window "$f")" ] && printf '%s
' "${f#"$ROOT"/}"
    done | LC_ALL=C sort -u | tr '
' ' ' | sed 's/ *$//'
}
# 집합 일치 — **양쪽이 다 비면 `no`**. 빈 문자열끼리의 `'' = ''`는 참이라 추출이 통째로 깨진 날
# 이 단언이 자기 공허하게 통과한다(M37 리뷰 사소 #4).
sets_equal() { # <a> <b> → yes|no
    if [ -n "$1" ] && [ "$1" = "$2" ]; then echo yes; else echo no; fi
}
# 기록·비기록 명단은 **서로소**여야 한다 — 창·줄 추출이 엉뚱한 쪽을 집으면 개수·집합 일치는
# 통과해도 여기서 걸린다(추출 대상 오인의 통제).
rosters_disjoint() { # <file> → yes|no
    _a=" $(roster_set "$1") "
    _b="$(nonwriter_set "$1")"
    if [ "$_a" = "  " ] || [ -z "$_b" ]; then echo no; return 0; fi
    for _n in $_b; do
        case "$_a" in *" $_n "*) echo no; return 0 ;; esac
    done
    echo yes
}

if part_on C; then
chk "C3: 규약 명단 이름 6개"        "$(roster_count "$CONV")"     "6"
chk "C3: 발행 페이지 명단 이름 6개" "$(roster_count "$CONCEPTS")" "6"
chk "C3: 두 명단 집합 일치"     "$(sets_equal "$(roster_set "$CONV")" "$(roster_set "$CONCEPTS")")" "yes"
chk "C3: 열거 파일은 규약·발행 페이지 둘뿐" "$(roster_files)"     "docs/conventions.md site/docs/concepts.md"

# 비기록 명단도 같은 넓이로 문다 — 규약의 선언이 두 목록을 함께 걸었다(리뷰 차단 #1).
chk "C3: 규약 비기록 명단 이름 6개"        "$(nonwriter_count "$CONV")"     "6"
chk "C3: 발행 페이지 비기록 명단 이름 6개" "$(nonwriter_count "$CONCEPTS")" "6"
chk "C3: 두 비기록 명단 집합 일치" "$(sets_equal "$(nonwriter_set "$CONV")" "$(nonwriter_set "$CONCEPTS")")" "yes"
chk "C3: 비기록 열거 파일은 규약·발행 페이지 둘뿐" "$(nonwriter_files)" "docs/conventions.md site/docs/concepts.md"
chk "C3: 규약의 기록·비기록 명단은 서로소"        "$(rosters_disjoint "$CONV")"     "yes"
chk "C3: 발행 페이지의 기록·비기록 명단은 서로소" "$(rosters_disjoint "$CONCEPTS")" "yes"

# 음성 통제 — 존재하지 않는 이름은 어느 명단에도 없다(C1 '보류함' 통제와 동일 취지).
chk "C3: 명단 통제 — 규약에 phantom-cmd 없음"        "$(roster_has "$CONV" phantom-cmd)"     "no"
chk "C3: 명단 통제 — 발행 페이지에 phantom-cmd 없음" "$(roster_has "$CONCEPTS" phantom-cmd)" "no"
chk "C3: 비기록 명단 통제 — 규약에 phantom-cmd 없음"        "$(nonwriter_has "$CONV" phantom-cmd)"     "no"
chk "C3: 비기록 명단 통제 — 발행 페이지에 phantom-cmd 없음" "$(nonwriter_has "$CONCEPTS" phantom-cmd)" "no"
fi

# (C4) 2.0 stable 커맨드 **명단**(M41) — C-3과 **같은 부류**라 새 파트를 만들지 않고 여기 둔다.
#      규약("2.0 안정성")이 그 명단의 열거처를 **규약과 README 둘**로 정하고, 다른 살아 있는 문서는
#      명단을 다시 적지 않고 그 절을 가리키게 했다. 이 케이스가 그 선언을 집행한다.
#      **`12종`과 `11종`은 다른 사실이다** — 전자는 실제 스킬 **파일 수**라 B1이 세어 대조하고,
#      후자는 **동결 선언**이라 파일 시스템으로 셀 수 없어 명단 대조로만 집행된다. 그래서 이 검사를
#      B1에 얹을 수 없고 별도 추출기를 둔다.
#      **추출 단위 = 창(최대 4줄)**: 열한 이름이 모두 드는 가장 짧은 연속 줄 묶음. 실측 스팬은
#      규약 3줄 · README 1줄이고 상한은 C-3과 같은 4다 — 상한을 넘으면 창을 못 찾아 개수 케이스가
#      크게 FAIL한다(집행 경계이며 `run.ps1`과 같은 값).
#      **탐침은 `` `/tide:<이름>` `` 형태로 닫는 백틱까지 포함한다** — 그래야 `` `/tide:fleet` `` 이
#      `` `/tide:fleet-cycle` `` 안에 우연히 걸리지 않는다(B3의 경계 요구와 같은 이유).
#      `/tide:debug`는 **동결 집합이 아니므로** 창에 섞여 들면 개수가 12가 되어 FAIL한다 —
#      승격은 major 사안이고, 그때 규약·README·이 러너를 함께 고치는 것이 의도된 비용이다.
stable_window() { # <file> → 창 텍스트(없으면 빈 출력)
    [ -f "$1" ] || return 0
    awk 'BEGIN { W = 4 }
        { L[NR] = $0 }
        END {
            for (w = 1; w <= W; w++)
                for (i = 1; i + w - 1 <= NR; i++) {
                    s = ""
                    for (k = i; k <= i + w - 1; k++) s = s "\n" L[k]
                    if (index(s, "`/tide:kickoff`") && index(s, "`/tide:milestone`") &&
                        index(s, "`/tide:impl`") && index(s, "`/tide:review`") &&
                        index(s, "`/tide:cycle`") && index(s, "`/tide:release`") &&
                        index(s, "`/tide:retro`") && index(s, "`/tide:status`") &&
                        index(s, "`/tide:fleet`") && index(s, "`/tide:fleet-cycle`") &&
                        index(s, "`/tide:fleet-verify`")) {
                        print s
                        exit
                    }
                }
        }' "$1"
}
# 공백 구분 문자열로 접는다. `tr`로 개행을 지우는 대신 awk로 잇는 이유는 이식성이다(BSD 환경에서
# 이 러너가 처음 돌 때 M40이 로케일 비교로 물렸다 — 정렬은 `LC_ALL=C`로 ordinal에 고정한다).
stable_set() { # <file> → 창의 `/tide:` 토큰 집합(정렬·공백 구분)
    stable_window "$1" | grep -oE '`/tide:[a-z][a-z-]*`' | sed 's/`//g; s|/tide:||'         | LC_ALL=C sort -u | awk '{ s = s (s == "" ? "" : " ") $0 } END { print s }'
}
stable_count() { # <file> → stable 명단 이름 개수
    stable_set "$1" | tr ' ' '\n' | grep -c '[a-z]'
}
stable_has() { # <file> <name> → yes|no
    case " $(stable_set "$1") " in *" $2 "*) echo yes ;; *) echo no ;; esac
}
stable_files() { # → stable 명단 창을 가진 살아 있는 문서(레포 상대 경로)
    roster_scan_files | while IFS= read -r f; do
        [ -n "$(stable_window "$f")" ] && printf '%s\n' "${f#"$ROOT"/}"
    done | LC_ALL=C sort -u | awk '{ s = s (s == "" ? "" : " ") $0 } END { print s }'
}

if part_on C; then
chk "C4: 규약 stable 명단 이름 11개"   "$(stable_count "$CONV")"   "11"
chk "C4: README stable 명단 이름 11개" "$(stable_count "$README")" "11"
chk "C4: 두 stable 명단 집합 일치" "$(sets_equal "$(stable_set "$CONV")" "$(stable_set "$README")")" "yes"
chk "C4: stable 열거 파일은 규약·README 둘뿐" "$(stable_files)" "README.md docs/conventions.md"
chk "C4: stable 명단 통제 — 규약에 phantom-stable 없음"   "$(stable_has "$CONV" phantom-stable)"   "no"
chk "C4: stable 명단 통제 — README에 phantom-stable 없음" "$(stable_has "$README" phantom-stable)" "no"
fi

# === Part D — 브랜치 간 협업 안전(M31) 선언 정합 =========================
# (M31) Part B/C와 동형 — 규약(conventions 단일 원본)과 그것을 배선하는 스킬이 같은 메커니즘을
# 선언하는지 결합한다. 두 검사(릴리즈 커버리지 체크·마일스톤 번호 사전경고)는 프롬프트 규율이라
# 런타임 발화는 하니스로 집행 못 하지만, **규약↔스킬 선언 정합**은 결정적으로 고정할 수 있다.
# ASCII 메커니즘 토큰(git 읽기 명령)으로 집행해 ps1의 ASCII-only 원본 규율과도 정합한다.
# (D1) 릴리즈 커버리지 체크: `git diff --name-only`가 conventions와 release SKILL 둘 다에 등장,
# (D2) 마일스톤 번호 사전경고: `git log --all`이 conventions와 milestone SKILL 둘 다에 등장.
# (D3·M39) 커버리지의 **미커밋 범위**: `git status --porcelain`이 conventions와 release SKILL 둘 다에
# 등장. 이 토큰이 없으면 검사는 커밋된 diff만 보는데 release는 워킹트리를 스테이징해 태그에 실으므로
# **검사가 본 자리와 실제로 실리는 자리가 갈린다**(M39의 출처가 그 갈림이다). D1과 별도 토큰인 이유는
# D1만으로는 범위 ⑵가 통째로 빠져도 통과하기 때문이다 — 한 메커니즘의 두 절반을 각각 앵커한다.
# 단일 원본은 conventions "릴리즈 커버리지 체크" 절 + "마일스톤 문서"의 번호 사전경고 항목.

REL_SKILL="$ROOT/skills/release/SKILL.md"
MS_SKILL="$ROOT/skills/milestone/SKILL.md"
CONV_REL="$ROOT/docs/conventions-release.md"   # 규약 **조각**(M35 분할) — `pr` 모드의 단일 원본
if part_on D; then
COV_TOK='git diff --name-only'
UNCOMMITTED_TOK='git status --porcelain'
WARN_TOK='git log --all'
PRCI_TOK='gh pr checks'

# (D1) 커버리지 체크 메커니즘이 규약과 스킬 둘 다에 선언(한 곳만 있으면 갈라짐 → FAIL).
chk "D1: conventions 가 커버리지 체크($COV_TOK) 선언" "$(has_token "$CONV" "$COV_TOK")" "yes"
chk "D1: release SKILL 이 커버리지 체크 배선"          "$(has_token "$REL_SKILL" "$COV_TOK")" "yes"

# (D2) 번호 사전경고 메커니즘이 규약과 스킬 둘 다에 선언.
chk "D2: conventions 가 번호 사전경고($WARN_TOK) 선언" "$(has_token "$CONV" "$WARN_TOK")" "yes"
chk "D2: milestone SKILL 이 번호 사전경고 배선"        "$(has_token "$MS_SKILL" "$WARN_TOK")" "yes"

# (D3) 커버리지의 미커밋 범위가 규약과 스킬 둘 다에 선언(한 곳만 있으면 갈라짐 → FAIL).
chk "D3: conventions 가 미커밋 범위($UNCOMMITTED_TOK) 선언" "$(has_token "$CONV" "$UNCOMMITTED_TOK")" "yes"
chk "D3: release SKILL 이 미커밋 범위 배선"                 "$(has_token "$REL_SKILL" "$UNCOMMITTED_TOK")" "yes"

# (D4·M39 리뷰 권장2) 사용자 대면 **캐노니컬 카탈로그**도 같은 범위를 선언한다. M39가 규약·스킬만
# 고치고 카탈로그를 두는 바람에 공개 페이지(사이트가 이 본문을 인클루드)가 옛 범위로 남았다 —
# 규약↔스킬 결합(D1·D3)은 그 드리프트를 못 봤다. 소비자 문서를 결합에 넣어 같은 부류를 닫는다
# (Part F의 역할 앵커 소비자 전파와 같은 취지).
chk "D4: 캐노니컬 카탈로그가 미커밋 범위 선언" "$(has_token "$CANON_CMD" "$UNCOMMITTED_TOK")" "yes"

# (D5·M40 리뷰 권장1) `workflow-syntax` 축의 확인 배선(`pr` 마무리의 PR CI 조회)도 **규약↔스킬**
# 결합이다. D1~D4와 같은 부류인데 M40이 결합 없이 문장만 넣었다 — 실측: release 스킬에서 배선을
# 통째로 지워도 **107/0 초록**이었다. 규약 쪽 단일 원본이 본체가 아니라 **조각**(`conventions-release.md`)
# 이라 결합 대상 파일만 다르고 기법은 D1~D4와 동일하다.
chk "D5: 규약 조각이 PR CI 확인($PRCI_TOK) 선언" "$(has_token "$CONV_REL" "$PRCI_TOK")" "yes"
chk "D5: release SKILL 이 PR CI 확인 배선"        "$(has_token "$REL_SKILL" "$PRCI_TOK")" "yes"

# (D6·D7·M46) 커버리지 체크의 두 축이 규약↔스킬 양쪽에 선언되는지 결합한다. D1(범위 ⑴)·D3(범위 ⑵)이
# **무엇을 모으는가**를 앵커한다면 이 둘은 **모은 것을 어떻게 대조하는가**를 앵커한다 — 한쪽만 고치면
# 검사가 규약보다 좁거나 넓어지는데 D1·D3은 그 갈림을 보지 못한다(둘 다 수집 토큰만 본다).
# (D6) 중괄호 확장 정규화: 펼치지 않으면 정당한 선언이 미상으로 뜬다(M46 실측 — v2.18.0 구간의
# 미상 7건이 전부 이 형태였고 펼친 뒤 0건).
# (D7) 역방향 선언 대조: impl 보고서의 `변경 파일 요약` 표가 선언했는데 실제로 안 바뀐 파일을 드러낸다.
# 산문 전역으로 넓히지 않는 경계도 같은 절에 있다(M46 실측 — 산문 축은 위양성 90%).
# 단일 원본은 conventions "릴리즈 커버리지 체크" 절. 토큰은 ASCII 병기어라 ps1 사본과 정합한다.
BRACE_TOK='brace-expansion'
DECL_TOK='declared-change-set'

chk "D6: conventions 가 중괄호 확장($BRACE_TOK) 선언" "$(has_token "$CONV" "$BRACE_TOK")" "yes"
chk "D6: release SKILL 이 중괄호 확장 배선"           "$(has_token "$REL_SKILL" "$BRACE_TOK")" "yes"
chk "D7: conventions 가 역방향 대조($DECL_TOK) 선언"  "$(has_token "$CONV" "$DECL_TOK")" "yes"
chk "D7: release SKILL 이 역방향 대조 배선"           "$(has_token "$REL_SKILL" "$DECL_TOK")" "yes"

# 교차 통제 — 각 메커니즘은 반대 스킬에 없어야 한다(토큰 구별력: 커버리지=release, 경고=milestone).
chk "D: 통제 — milestone SKILL 에 커버리지 토큰 없음" "$(has_token "$MS_SKILL" "$COV_TOK")" "no"
chk "D: 통제 — milestone SKILL 에 미커밋 범위 토큰 없음" "$(has_token "$MS_SKILL" "$UNCOMMITTED_TOK")" "no"
chk "D: 통제 — release SKILL 에 번호경고 토큰 없음"   "$(has_token "$REL_SKILL" "$WARN_TOK")" "no"
chk "D: 통제 — milestone SKILL 에 PR CI 토큰 없음"   "$(has_token "$MS_SKILL" "$PRCI_TOK")" "no"
chk "D: 통제 — milestone SKILL 에 중괄호 확장 토큰 없음" "$(has_token "$MS_SKILL" "$BRACE_TOK")" "no"
chk "D: 통제 — milestone SKILL 에 역방향 대조 토큰 없음" "$(has_token "$MS_SKILL" "$DECL_TOK")" "no"

# 음성 통제 — 존재하지 않는 가짜 메커니즘 토큰은 규약에 없어야 한다(가드 구별력 입증, B1의 N+1종 부재와 동형).
chk "D: 통제 — conventions에 가짜 토큰 없음" "$(has_token "$CONV" "git diff --bogus-only")" "no"
fi

# === Part E — 리뷰 검증 규율(M32) 선언 정합 ==============================
# (M32) Part C/D와 동형 — 규약(conventions 단일 원본)과 그것을 배선하는 스킬·템플릿이 같은
# 메커니즘을 선언하는지 결합한다. 반증 시도가 런타임에 실제로 디스패치되는지는 프롬프트 규율이라
# 하니스로 집행할 수 없지만, **규약↔스킬↔템플릿 선언 정합**은 결정적으로 고정할 수 있다
# (Part C·D와 같은 분담). 토큰은 전부 ASCII 병기어(conventions "리뷰 검증 규율" 절의 ASCII 병기
# 결정)라 ps1 사본이 코드포인트 조립 없이 같은 토큰을 앵커한다.
# (E1) 반증 시도: `refutation`이 conventions·review SKILL 둘 다에 등장,
# (E2) 판정 계측: `in-review`가 conventions·review SKILL·review 템플릿 세 곳 모두에 등장,
# (E3) 재작업 라운드: `rework`가 conventions·review 템플릿·impl 템플릿 세 곳 모두에 등장.
# (E6) 판례 부류(M36): `vacuous-pass`가 conventions·review SKILL 둘 다에 등장,
# (E7) 부인 기록(M36): `precedent-waiver`가 conventions·review SKILL·review 템플릿 세 곳 모두에 등장.
# 단일 원본은 conventions "리뷰 검증 규율" 절.

REV_SKILL="$ROOT/skills/review/SKILL.md"
REV_TPL="$ROOT/skills/review/template.md"
REFUT_TOK='refutation'
MEAS_TOK='in-review'
REWORK_TOK='rework'
REVERIFY_TOK='re-verify'
VACUOUS_TOK='vacuous-pass'
WAIVER_TOK='precedent-waiver'

in_both() { # <token> <f1> <f2> → yes|no
    for f in "$2" "$3"; do
        [ "$(has_token "$f" "$1")" = yes ] || { echo no; return; }
    done
    echo yes
}

# (E1) 반증 시도 메커니즘이 규약과 review 스킬 둘 다에 선언(한 곳만 있으면 갈라짐 → FAIL).
if part_on E; then
chk "E1: 반증 시도($REFUT_TOK) 규약↔review SKILL 정합"  "$(in_both "$REFUT_TOK" "$CONV" "$REV_SKILL")" "yes"

# (E2) 판정 계측 토큰이 규약·스킬·템플릿 세 곳 전부에 선언(계측 줄은 템플릿에도 자리가 있어야 한다).
chk "E2: 판정 계측($MEAS_TOK) 세 파일 전부에 등장"      "$(in_all_three "$MEAS_TOK" "$CONV" "$REV_SKILL" "$REV_TPL")" "yes"

# (E3) 재작업 라운드는 review 계측 줄과 impl 개요가 같은 값을 적으므로 세 곳 선언이 결합 조건이다.
chk "E3: 재작업 라운드($REWORK_TOK) 세 파일 전부에 등장" "$(in_all_three "$REWORK_TOK" "$CONV" "$REV_TPL" "$IMPL_TPL")" "yes"
fi

# (E4) 계측 줄 **형식** 정합 — 토큰이 파일 어딘가에 있기만 해선 부족하다. 실제로 M32 구현 중 세 파일이
# `재작업 라운드 {n}` / `재작업 라운드(rework) {n}` 두 이형으로 갈렸고(E1~E3는 전부 통과했다), 사람이
# 손으로 잡았다. 고정 형식의 **ASCII 골격**(`in-review` … `(rework)`가 같은 한 줄)을 결합해 그 이형을
# 잡는다 — 한글 본문을 앵커하지 않으므로 ps1의 ASCII-only 원본 규율도 유지된다.
same_line() { # <file> <tokA> <tokB> → yes|no  (두 토큰이 같은 한 줄에 있으면 yes)
    [ -f "$1" ] && grep -F "$2" "$1" 2>/dev/null | grep -qF "$3" && echo yes || echo no
}
if part_on E; then
for pair in "conventions:$CONV" "review SKILL:$REV_SKILL" "review 템플릿:$REV_TPL"; do
    chk "E4: 계측 줄 골격(${MEAS_TOK}…(${REWORK_TOK})) ${pair%%:*}" \
        "$(same_line "${pair#*:}" "$MEAS_TOK" "($REWORK_TOK)")" "yes"
done

# (E5) 재검증 규약 선언 정합 — `in-review`만으로는 이 규약을 앵커할 수 없다. 그 토큰은 계측 줄에도
# 있어(이중 용도) **재검증 절을 통째로 지워도 E2가 통과**한다(M32 리뷰의 반증 패스가 복사본에서 실증).
# 그래서 재검증 전용 ASCII 병기어 `re-verify`를 세 파일에 결합한다.
chk "E5: 재검증($REVERIFY_TOK) 세 파일 전부에 등장" "$(in_all_three "$REVERIFY_TOK" "$CONV" "$REV_SKILL" "$REV_TPL")" "yes"

# (E6) 차단 등급 판례(M36) — 판례 부류 이름 `vacuous-pass`가 규약과 review 스킬 둘 다에 선언.
# E1(반증 시도)과 같은 2곳 결합 층위다 — 판례는 절차 지시(스킬)와 기준(규약)에 있고, 보고서 템플릿엔
# 슬롯을 두지 않는다(복제 선언을 불필요하게 늘리지 않는다).
chk "E6: 판례 부류($VACUOUS_TOK) 규약↔review SKILL 정합" "$(in_both "$VACUOUS_TOK" "$CONV" "$REV_SKILL")" "yes"

# (E7) 부인 기록(M36) — `precedent-waiver`는 규약(의무)·스킬(절차)·템플릿(기록 슬롯) 세 곳 전부가
# 있어야 실제로 남는다. 템플릿에서만 지워도 이 단언이 물어야 한다(E2·E5와 같은 3곳 결합).
chk "E7: 부인 기록($WAIVER_TOK) 세 파일 전부에 등장" "$(in_all_three "$WAIVER_TOK" "$CONV" "$REV_SKILL" "$REV_TPL")" "yes"

# (E8·E9 · M44) M43이 이 절에 더한 두 규칙에는 **ASCII 병기어가 없었다** — 그래서 Part E가 결합할
# 대상이 없었고, 종료 조건을 **무조건으로 부정하는 재서술 세 자리**가 트리 그대로 통과했다(M43 리뷰
# 이슈 1). M44-T01이 그 기전을 실측하고 병기어를 붙였으므로 여기서 결합한다. 결합 층위는 기존 판정과
# 같은 원칙이다 — 템플릿에 **기록 슬롯이 필요한 규칙**은 3곳, 기준+절차뿐인 규칙은 2곳.
RESIDUAL_TOK='residual-risk-acceptance'
REACH_TOK='reachability-weighting'

# (E8) 종료 조건은 리뷰 **보고서에 수용 근거 블록**을 남기므로 규약·스킬·템플릿 3곳 결합이다
# (E7 `precedent-waiver`와 같은 층위 — 템플릿에서만 지워도 이 단언이 물어야 한다).
chk "E8: 종료 조건($RESIDUAL_TOK) 세 파일 전부에 등장" "$(in_all_three "$RESIDUAL_TOK" "$CONV" "$REV_SKILL" "$REV_TPL")" "yes"

# (E9) 도달 가능성 가중은 **등급 판단의 근거**라 기준(규약)과 절차(스킬) 2곳 결합이다(E6과 같은 층위 —
# 보고서 템플릿에 슬롯을 두면 복제 선언을 불필요하게 늘린다).
chk "E9: 도달 가능성($REACH_TOK) 규약↔review SKILL 정합" "$(in_both "$REACH_TOK" "$CONV" "$REV_SKILL")" "yes"

# (E10 · M46) 연속 폴백 계측. 값은 **리뷰 보고서 계측 줄에 적히는 슬롯**이므로 E8·E3과 같은 3곳 결합이다
# (규약 = 정의, 스킬 = 절차, 템플릿 = 기록 슬롯). 병기어가 없으면 이 필드를 지워도 초록이라 M44가 세운
# 결합 규율을 그대로 따른다. 계측 줄 자체의 골격은 E4가 이미 문다 — E10은 **새 필드의 존재**를 문다.
STREAK_TOK='fallback-streak'
chk "E10: 연속 폴백($STREAK_TOK) 세 파일 전부에 등장" "$(in_all_three "$STREAK_TOK" "$CONV" "$REV_SKILL" "$REV_TPL")" "yes"
# 계측 줄 골격 안에 새 필드가 실제로 들어갔는지(같은 줄) — 규약·템플릿 두 자리.
chk "E10: 계측 줄 골격에 연속 폴백 필드(규약)"   "$(same_line "$CONV" "$MEAS_TOK" "($STREAK_TOK)")" "yes"
chk "E10: 계측 줄 골격에 연속 폴백 필드(템플릿)" "$(same_line "$REV_TPL" "$MEAS_TOK" "($STREAK_TOK)")" "yes"

# (E11 · M58) 부인 기록 계측. `precedent-waiver`는 E7이 이미 **세 파일에 있는가**를 무는데,
# 그것은 `다음 단계`의 기록 슬롯이 성립하는 조건이라 **계측 줄에 들어갔는지는 보지 않는다** —
# 실제로 E7이 초록인 채로 네 사이클 동안 부인 6건이 세어지지 않았다(2026-08-31 회고의 표제 실측).
# 그래서 무는 것은 둘이다: ⑴ **계측 줄 안에** 부인 건수 필드가 있는가(E7과 층이 다르다)
# ⑵ 연속 부인 필드의 병기어가 세 파일에 있는가(E10과 같은 3곳 결합).
WAIVER_STREAK_TOK='waiver-streak'
chk "E11: 연속 부인($WAIVER_STREAK_TOK) 세 파일 전부에 등장" "$(in_all_three "$WAIVER_STREAK_TOK" "$CONV" "$REV_SKILL" "$REV_TPL")" "yes"
# 계측 줄 골격 안에 두 필드가 실제로 들어갔는지 — 규약·템플릿 두 자리(E10과 같은 형태).
chk "E11: 계측 줄 골격에 부인 건수 필드(규약)"   "$(same_line "$CONV" "$MEAS_TOK" "($WAIVER_TOK)")" "yes"
chk "E11: 계측 줄 골격에 부인 건수 필드(템플릿)" "$(same_line "$REV_TPL" "$MEAS_TOK" "($WAIVER_TOK)")" "yes"
chk "E11: 계측 줄 골격에 연속 부인 필드(규약)"   "$(same_line "$CONV" "$MEAS_TOK" "($WAIVER_STREAK_TOK)")" "yes"
chk "E11: 계측 줄 골격에 연속 부인 필드(템플릿)" "$(same_line "$REV_TPL" "$MEAS_TOK" "($WAIVER_STREAK_TOK)")" "yes"

# 음성 통제 — 가짜 종료 조건 토큰은 규약에 없어야 한다(아래 판례 토큰 통제와 동형, 구별력 입증).
chk "E: 통제 — conventions에 가짜 종료조건 토큰 없음" "$(has_token "$CONV" "${RESIDUAL_TOK}-bogus")" "no"

# 음성 통제 — 가짜 판례 토큰은 규약에 없어야 한다(E의 `refutation-bogus` 통제와 동형, 구별력 입증).
chk "E: 통제 — conventions에 가짜 판례 토큰 없음" "$(has_token "$CONV" "${VACUOUS_TOK}-bogus")" "no"

# 교차 통제 — 반증 시도는 review 자산이라 impl 템플릿에 없어야 한다(토큰 구별력, Part D 교차 통제와 동형).
chk "E: 통제 — impl 템플릿에 반증 토큰 없음" "$(has_token "$IMPL_TPL" "$REFUT_TOK")" "no"

# 교차 통제 — 계측 줄은 review 자산이라 impl 템플릿엔 골격이 없어야 한다(개요엔 rework 값만 적는다).
chk "E: 통제 — impl 템플릿에 계측 줄 골격 없음" "$(same_line "$IMPL_TPL" "$MEAS_TOK" "($REWORK_TOK)")" "no"

# 음성 통제 — 가짜 연속 폴백 토큰은 규약에 없어야 한다(E8 통제와 동형, 구별력 입증).
chk "E: 통제 — conventions에 가짜 연속폴백 토큰 없음" "$(has_token "$CONV" "${STREAK_TOK}-bogus")" "no"
chk "E: 통제 — conventions에 가짜 연속부인 토큰 없음" "$(has_token "$CONV" "${WAIVER_STREAK_TOK}-bogus")" "no"

# 음성 통제 — 존재하지 않는 가짜 토큰은 규약에 없어야 한다(B1의 N+1종 부재·Part D 가짜 토큰과 동형).
chk "E: 통제 — conventions에 가짜 반증 토큰 없음" "$(has_token "$CONV" "${REFUT_TOK}-bogus")" "no"
fi

# === Part F — 문서 자기서술 정합(M33) ====================================
# (M33) Part B~E가 "여러 문서가 같은 사실을 선언할 때의 드리프트"를 집행하듯, 이 파트는 문서가
# **자기 자신에 대해 하는 서술**을 집행한다 — 지금까지 무방비였던 두 층이다.
# (F2) 역할 앵커 전파: 캐노니컬(docs/commands.md)의 `role-anchors:` 맵에서 앵커를 **추출**해
#      ① 캐노니컬의 그 커맨드 표 행에 실재하는지 ② 소비자 문서(README·사이트 시작하기)가 그
#      커맨드를 언급하면 앵커도 있는지 검사한다. 스크립트에 한글 리터럴을 두지 않는 데이터 기반
#      검사라 ps1 사본의 ASCII-only 원본 규율과 정합한다(tests/site-includes 용어 추출과 동형).
# (F3) 통제: 추출 0건이면 FAIL(공허 통과 차단, M27 positive-control 선례) · 맵의 이름이 실제
#      커맨드 스킬인지 · 가짜 앵커 부재.
# (F1) 케이스 수 자기 정합: 이 하니스가 **자기 README의 선언**(`cases: N`)과 **자신의 실제 케이스
#      수**를 대조한다. F1 자신도 한 케이스이므로 **F1을 마지막 케이스로 두고 `누계 + 1`과 비교**한다
#      (채택 경로 — README에도 같은 문장을 적어 둔다). 추출 실패는 조용한 skip이 아니라 FAIL이다.
# 단일 원본은 `docs/conventions.md`의 "문서 자기서술 정합" 절.

DISC_README="$ROOT/tests/discover/README.md"

# 앵커 맵 추출 — `<!-- role-anchors: name=token ... -->` 한 줄에서 name=token 쌍만 뽑는다.
anchor_pairs() {
    grep -o 'role-anchors:[^>]*' "$CANON_CMD" 2>/dev/null | head -1 |
        sed 's/role-anchors://' | tr ' ' '\n' | grep -E '^[a-z-]+=[A-Za-z-]+$'
}

# 앵커는 영문·하이픈 경계로 찾는다 — 짧은 앵커(gh)가 다른 단어 안에 우연히 걸리지 않도록.
has_anchor() { # <file> <token> → yes|no
    [ -f "$1" ] && grep -qE "(^|[^A-Za-z-])$2([^A-Za-z-]|$)" "$1" && echo yes || echo no
}

# 캐노니컬 자기 정합 — 앵커가 그 커맨드의 **표 행**(`|`로 시작)에 실재해야 한다.
canon_row_has() { # <name> <token> → yes|no
    grep -E "^\|.*/tide:$1([^a-z-]|$)" "$CANON_CMD" 2>/dev/null |
        grep -qE "(^|[^A-Za-z-])$2([^A-Za-z-]|$)" && echo yes || echo no
}

# 소비자 전파 — 그 커맨드를 **언급하면** 앵커도 있어야 한다(언급 없으면 대상 아님 = yes).
consumer_ok() { # <file> <name> <token> → yes|no
    [ -f "$1" ] || { echo no; return; }
    if [ "$(has_command "$1" "$2")" = yes ]; then has_anchor "$1" "$3"; else echo yes; fi
}

if part_on F; then
npairs=0
for pair in $(anchor_pairs); do
    npairs=$((npairs + 1))
    aname=${pair%%=*}; atok=${pair#*=}
    chk "F2: 앵커 '$atok' 캐노니컬 /tide:$aname 행에 실재" "$(canon_row_has "$aname" "$atok")" "yes"
    chk "F2: README 전파($aname=$atok, 언급 시)"           "$(consumer_ok "$README" "$aname" "$atok")" "yes"
    chk "F2: 사이트 시작하기 전파($aname=$atok, 언급 시)"   "$(consumer_ok "$SITE_GS" "$aname" "$atok")" "yes"
done

# positive-control — 앵커를 하나도 못 뽑았으면 위 루프가 통째로 공허하게 통과한다(추출 실패 = FAIL).
chk "F3: 앵커 추출 positive-control(>0)" "$([ "$npairs" -gt 0 ] && echo ok || echo no)" "ok"

# 맵 위생 — 선언된 앵커 이름은 실제 커맨드 스킬이어야 한다(오타·삭제된 커맨드 잔재 적발).
names_real=yes
for pair in $(anchor_pairs); do
    [ -f "$ROOT/skills/${pair%%=*}/SKILL.md" ] || names_real=no
done
chk "F3: 앵커 맵의 이름이 전부 실제 커맨드 스킬" "$names_real" "yes"

# 음성 통제 — 존재하지 않는 가짜 앵커는 캐노니컬에 없어야 한다(B1 N+1종 부재와 동형).
chk "F3: 통제 — 캐노니컬에 가짜 앵커 없음" "$(has_anchor "$CANON_CMD" "bogusanchor")" "no"
fi

# === Part G — 상호참조 무결성(M34 · M35에서 규약 문서 **집합**으로 일반화) ====
# (M34) Part F가 문서의 **자기서술**을 집행한다면, Part G는 문서 **사이를 잇는 참조**를 집행한다 —
# 지금까지 무방비였던 층이다(실제로 `릴리즈 빌드 출력 검증`·`debug 세션 → 릴리즈 경로` 같은 인용이
# 실재하지 않는 이름을 가리킨 채 조용히 살아 있었다). 단일 원본은 conventions "상호참조 무결성" 절.
# (M35) 규약은 이제 한 파일이 아니라 **규약 문서 집합**이다(본체 + 주제별 조각). 그래서 이 파트는
#      ① 글롭 `docs/conventions*.md`로 **집합을 발견**하고(목록 하드코딩 금지 — 조각을 더해도 러너를
#      고치지 않는다) ② 앵커를 **파일별로** 묶으며 ③ 인용 후보 줄에 **등장한 규약 파일명**으로 대조할
#      앵커 집합을 고른다. 절이 조각으로 옮겨 가면 인용도 그 파일명을 가리켜야 통과한다(= 파일을 옮기고
#      인용을 안 고치면 잡힌다). 한 줄에 두 파일명이 있으면 **어느 쪽 집합에든 있으면 통과**로 본다
#      (안전 측 — 오탐을 만들지 않는다). 조각이 0개면 집합이 본체 하나뿐이라 일반화 **이전과 같은
#      판정**이 나온다(회귀 고정).
# (G1) 살아 있는 문서에서 인용 골격(규약 파일명이 든 줄의 따옴표 구획)을 **추출**해, 그 줄이 가리킨
#      파일의 `##`·`###` 제목 집합(공백 제거 정규화)에 전부 실재하는지 단언한다.
# (G2) 통제: 인용·앵커 추출 0건이면 FAIL(공허 통과 차단) · 가짜 이름이 집합 어디에도 없음 ·
#      제목 이름 유일성은 **집합 전체 기준**(파일이 갈려도 같은 이름을 두 곳에 두지 않는다).
# (G3) 줄바꿈 인용 통제: 후보 줄의 따옴표가 **미종결**(홀수)이면 인용이 다음 줄로 넘어간 것이고,
#      줄 단위 추출에서 **조용히 빠진다** — 골격을 한 줄로 쓰게 강제해 그 사각을 닫는다.
# 스크립트에 한글 리터럴을 두지 않는 **데이터 기반** 검사라 ps1의 byte>127=0 규율을 유지한다
# (F2·tests/site-includes 용어 추출과 동형).

# 살아 있는 문서 — `docs/milestones/*`·`docs/reports/*`는 역사 기록이라 대상이 아니다
# (docs/*.md 글롭이 하위 디렉터리를 잡지 않으므로 자연히 제외된다). 목록은 파일로 받는다 —
# `$(...)`를 for에 풀면 공백이 든 경로에서 쪼개진다.
living_docs() {
    ls "$ROOT"/skills/*/*.md "$ROOT"/docs/*.md "$ROOT/README.md" \
       "$ROOT"/site/docs/*.md "$ROOT"/tests/*/README.md 2>/dev/null
}
living_docs > "$SBX/living.txt"

# 규약 문서 집합 — 글롭으로 **발견**한다. `LC_ALL=C sort`로 정렬해 ps1(ordinal 정렬)과 **같은 순서**로
# 훑는다. 목록은 파일로 받는다(위와 같은 이유 — 공백이 든 경로에서 단어 분리를 타지 않게).
conv_files() {
    for f in "$ROOT"/docs/conventions*.md; do
        [ -f "$f" ] && printf '%s\n' "$f"
    done | LC_ALL=C sort
}

# 파일별 앵커 집합 — `##`·`###` 제목만, 공백 제거 정규화(`버전·CHANGELOG` ≡ `버전 · CHANGELOG`).
# CR도 함께 걷는다: CRLF로 체크아웃된 규약이면 앵커 끝에 `\r`가 붙어 전건 오탐이 된다
# (Git Bash grep은 가려 주지만 POSIX grep은 가려 주지 않는다 — 셸 간 판정이 갈리지 않게).
anchor_set() { grep -E '^#{2,3} ' "$1" 2>/dev/null | sed 's/^#* //' | tr -d ' \r'; }

# 집합을 훑어 파일마다 `anchors.<i>.txt`(그 파일의 앵커)를 만들고, 통제용으로 전체를 `anchors.txt`에
# 모은다. 키는 **인덱스**다 — 파일명을 키로 쓰면 이름에 공백이 들었을 때 레코드가 깨진다.
if part_on G; then
conv_files > "$SBX/convfiles.txt"
: > "$SBX/convbases.txt"
: > "$SBX/anchors.txt"
NCONV=0
while IFS= read -r cf; do
    NCONV=$((NCONV + 1))
    printf '%s\n' "${cf##*/}" >> "$SBX/convbases.txt"
    anchor_set "$cf" > "$SBX/anchors.$NCONV.txt"
    cat "$SBX/anchors.$NCONV.txt" >> "$SBX/anchors.txt"
done < "$SBX/convfiles.txt"
fi

# 인용 후보 줄 — 집합의 **어느 파일명이든** 든 줄. 스니펫 인클루드 지시어 줄(`8<--`)은 제외한다.
# (M50) 살아 있는 문서마다 `grep` 둘을 띄우던 것을 **awk 한 번**으로 바꿨다. 파일 목록도 awk가
# 직접 읽는다 — 목록을 인자로 펼치면 **공백이 든 경로에서 단어 분리를 탄다**(이 러너가 목록을
# 파일로 주고받는 것과 같은 이유다). 판정은 그대로다: 파일명 부분일치 · `8<--` 줄 제외.
citation_lines() {
    LC_ALL=C awk -v BASES="$SBX/convbases.txt" -v LIVING="$SBX/living.txt" '
        BEGIN {
            nb = 0
            while ((getline b < BASES) > 0) if (b != "") { nb++; B[nb] = b }
            close(BASES)
            while ((getline f < LIVING) > 0) {
                if (f == "") continue
                while ((getline l < f) > 0) {
                    if (index(l, "8<--") > 0) continue
                    for (i = 1; i <= nb; i++) if (index(l, B[i]) > 0) { print l; break }
                }
                close(f)
            }
        }' < /dev/null
}

if part_on G; then
citation_lines > "$SBX/citelines.txt"
fi
# 인용 = 후보 줄의 따옴표 구획. 골격 자리표({} 포함)와 빈 구획은 인용이 아니다(빈 줄로 떨어진다).
# 레코드 형식은 `<인덱스 목록> <인용>` — 인용은 공백 제거 후라 공백을 담지 않는다.
# 귀속은 그 줄에 등장한 규약 파일명들의 인덱스(쉼표 결합)다.
# (M50) 이전 형태는 후보 줄마다 **명령치환 하나(`line_owners`)와 파이프라인 다섯**을 띄워
# 줄당 6 프로세스였다. 지금은 **awk 한 번**이 귀속과 구획 추출을 함께 한다. 판정 규칙은 그대로다 —
# 따옴표 구획을 왼쪽부터 겹치지 않게 · 골격 자리표(`{}`)가 든 구획 제외 · 공백과 CR 제거 ·
# 빈 구획 제외. `line_owners`는 이 자리에서만 쓰이던 함수라 함께 접었다.
cite_records() {
    LC_ALL=C awk -v BASES="$SBX/convbases.txt" '
    BEGIN {
        nb = 0
        while ((getline b < BASES) > 0) if (b != "") { nb++; B[nb] = b }
        close(BASES)
    }
    {
        o = ""
        for (i = 1; i <= nb; i++) if (index($0, B[i]) > 0) o = o "," i
        if (o == "") next
        o = substr(o, 2)
        s = $0
        while (match(s, /"[^"]*"/)) {
            v = substr(s, RSTART + 1, RLENGTH - 2)
            s = substr(s, RSTART + RLENGTH)
            if (v ~ /[{}]/) continue
            gsub(/[ \r]/, "", v)
            if (v != "") print o " " v
        }
    }' "$SBX/citelines.txt"
}
if part_on G; then
cite_records > "$SBX/cites.txt"

NANCHOR=$(grep -c . "$SBX/anchors.txt")
NCITE=$(grep -c . "$SBX/cites.txt")
fi

# 귀속된 파일이 둘이면 **어느 집합에든 있으면** 통과다(안전 측).
# (M50) 이전 형태는 레코드마다 `grep -qxF`를 띄웠고, 그래서 **인용 이름이 `-`로 시작하면 grep이
# 그것을 옵션으로 읽어 stdin을 삼키는** 사고를 `--`와 `</dev/null`로 막고 있었다(M34 리뷰 차단 #1의
# 자리다 — 막지 않으면 나머지 인용이 통째로 미검사로 남고 miss가 0으로 나온다). 지금은 **awk가
# 앵커 집합을 한 번 읽어 조회**하므로 인용 이름이 **인자가 아니라 데이터**다 — 그 사고 경로 자체가
# 사라졌다. 방어를 지운 것이 아니라 **방어가 필요하던 구조를 없앤 것**이다.
# (M54) **인자를 받는다** — 그래야 같은 판정 함수를 픽스처에 걸 수 있다. 인자가 없으면 종전대로
# 살아 있는 인용 목록을 본다(호출부 의미 불변). M46 판례가 요구하는 것은 *"픽스처가 조건을
# 만족하는가"* 가 아니라 **실제 판정이 픽스처 위에서 도는가**이며, 그전까지 `G1`은 그것이 없었다.
cite_miss() { # [cites 목록 경로] → 실재하지 않는 앵커를 가리키는 인용의 수
    LC_ALL=C awk -v SBX="$SBX" '
    function loadset(i,   f, l) {
        if (i in LOADED) return
        LOADED[i] = 1
        f = SBX "/anchors." i ".txt"
        while ((getline l < f) > 0) if (l != "") A[i SUBSEP l] = 1
        close(f)
    }
    NF >= 2 {
        o = $1; c = $2
        ok = 0
        n = split(o, IDX, ",")
        for (k = 1; k <= n; k++) {
            loadset(IDX[k])
            if ((IDX[k] SUBSEP c) in A) ok = 1
        }
        if (!ok) miss++
    }
    END { print miss + 0 }' "${1:-$SBX/cites.txt}"
}
cite_fixture() { # → 인용 하나가 실재하지 않는 앵커를 가리키는 목록 파일
    # 소유자 인덱스는 **살아 있는 목록의 첫 줄에서 빌린다** — 존재하는 앵커 집합을 실제로 열고도
    # 이름이 없어서 미해소가 되는 형태여야 판정이 도는 것이 확인된다.
    _cf="$SBX/cites-fix.txt"
    LC_ALL=C awk 'NR == 1 { print $1 " zzz-bogus-anchor"; exit }' "$SBX/cites.txt" > "$_cf"
    printf '%s' "$_cf"
}
# 가짜 이름·유일성 통제는 **집합 전체**(합친 anchors.txt)를 본다.
has_anchor_name() { grep -qxF -- "$1" "$SBX/anchors.txt" </dev/null && echo yes || echo no; }
odd_quote_lines() { awk '{ n = gsub(/"/, "&"); if (n % 2 == 1) c++ } END { print c + 0 }' "$SBX/citelines.txt"; }

if part_on G; then
chk "G1: 살아 있는 인용이 전부 실재 앵커를 가리킴" "$(cite_miss)" "0"
# (M54) 픽스처 통제 — **같은 판정 함수**를 실재하지 않는 앵커를 가리키는 목록에 건다. 이것이 없으면
# `cite_miss`의 판정을 망가뜨려도 아무것도 붉지 않는다(M50 리뷰 권장 1이 연 자리, 세 사이클 이월).
chk "G1: 픽스처 통제 — 끊긴 인용을 실제로 잡는다" "$(cite_miss "$(cite_fixture)")" "1"
chk "G2: 인용 추출 positive-control(>0)"          "$([ "$NCITE" -gt 0 ] && echo ok || echo no)" "ok"
chk "G2: 앵커 추출 positive-control(>0)"          "$([ "$NANCHOR" -gt 0 ] && echo ok || echo no)" "ok"
chk "G2: 통제 — 가짜 앵커 이름(bogus-section) 부재" "$(has_anchor_name 'bogus-section')" "no"
# (M40 릴리즈 CI — external-tool 축의 첫 실측) 이 파이프라인은 이 러너에서 **유일하게 `LC_ALL=C`가
# 빠져 있던** 자리였다(다른 11곳은 전부 갖고 있었다). 로케일이 걸리면 `sort`·`uniq`의 비교가
# **바이트 동등이 아니라 collation 동등**이 되어, 서로 다른 이름이 같은 것으로 묶일 수 있다.
# ps1 사본은 `HashSet[string]` 기본 비교자 = **ordinal**이라 처음부터 바이트 동등이었고, 그래서
# 이 누락은 **두 셸의 의미를 갈라 놓은 것**이다 — GNU에서는 두 경로가 우연히 같은 답을 내 보이지
# 않다가, **BSD(macOS) 레그에서 `중복 3`으로 드러났다**(GNU 환경 전부 0). `LC_ALL=C`가 POSIX에서
# "ordinal로 비교하라"를 뜻하므로 이것이 ps1과 의미를 맞추는 표기다.
# 실패하면 **무엇이 묶였는지 이름을 출력한다** — 수를 세는 단언은 붉어져도 원인을 말해 주지 않아
# 이번에 로컬에서 기전을 재현하지 못했다(같은 일을 반복하지 않는다).
G2_DUPS=$(LC_ALL=C sort "$SBX/anchors.txt" | LC_ALL=C uniq -d)
G2_NDUP=$(printf '%s\n' "$G2_DUPS" | grep -c .)
[ "$G2_NDUP" = "0" ] || printf '  ↳ 중복 앵커: %s\n' "$(printf '%s' "$G2_DUPS" | tr '\n' ' ')"
chk "G2: 앵커 이름 유일성(정규화 후 중복 0)"       "$G2_NDUP" "0"
chk "G3: 인용 줄 따옴표 종결(줄바꿈 인용 0)"       "$(odd_quote_lines)" "0"

# (G4) 같은 파일 **안의 자기참조**도 집행한다(M41). M34가 상호참조 무결성을 신설하며 "골격에 파일명이
#      없어 가드 밖 — 사람의 리뷰 영역"으로 남긴 층이고, **여섯 사이클** 동안 그대로였다.
#      **범위는 G1과 같은 `living_docs`다** — 규약 문서 집합만 보면 규약이 "닫혔다"고 적은 층이
#      `skills/`·`README.md`·`tests/*/README.md`에서 그대로 열려 있고, 그것이 M41 라운드 1이 차단을
#      받은 자리다(실측: 규약 밖에 깨진 자기참조를 심어도 초록이었다).
#      **대조는 그 파일 자신의 앵커 집합**이다 — 자기참조는 정의상 같은 파일을 가리키므로, 집합 전체와
#      대조하면 다른 파일의 절을 가리켜도 통과해 버린다(라운드 1의 안전 측 선택이 범위를 넓히자
#      과대 허용으로 바뀐다).
#      후보를 좁히는 표지 넷 — 실측으로 정했다(living_docs 후보 55건 기준):
#        ⑴ `"…" 절` 형태일 것. **이 표지 없이는 닫을 수 없다** — 조건을 빼면 규약 문서 집합만으로도
#           후보가 47 → 165건으로 늘고 그중 100건 넘게 평범한 인용부호 산문이다(`"가능"`·`"확인했다"`).
#        ⑵ **백틱 파일 경로가 없을 것** — 있으면 자기참조가 아니라 다른 파일로의 인용이다.
#        ⑶ **줄에 규약 파일명이 없을 것** — 마크다운 링크 형태(`[docs/conventions.md](…)의 "…" 절`)는
#           G1이 이미 문다. 이 표지가 없으면 그 4건이 자기참조로 오인돼 전부 오탐이 된다(실측).
#        ⑷ **앞 줄에도 규약 파일명이 없을 것** — 파일명이 앞 줄, 따옴표 구획이 다음 줄인 **줄바꿈 인용**
#           3건이 같은 이유로 오탐이 된다(실측). G3가 잡지 못한다고 고지한 바로 그 사각이다.
#      ⑷의 창은 **한 줄**이다. 두 줄 이상 앞의 파일명은 못 보므로, 그때 이 파트는 그 구획을
#      **자기참조로 취급해 자기 파일 앵커에 대조**한다 — **자기참조와 끊긴 인용은 원리상 구별되지
#      않는다**(구별에 필요한 파일명이 다른 줄에 있다. G3가 사각으로 고지한 바로 그 성질이다).
#      그래서 결과가 **이름이 우연히 그 파일에도 있는가**에 갈린다: 있으면 **조용히 통과**하고
#      (실측 — `site/docs/concepts.md`는 규약과 같은 이름의 앵커를 갖는다), 없으면 붉어진다.
#      **창을 넓혀도 닫히지 않는다** — 1→2→3에서 후보 46·미해소 0으로 값이 같고(실측) 창이 N이면
#      N+1줄 앞은 여전히 못 본다. 경계가 옮겨질 뿐이라 창은 1로 두고 이 한계를 고지한다.
#      남는 미탐지 넷: ⑴ 표지 미사용 ⑵ 백틱 경로 동반 ⑶ 규약이 아닌 파일로의 인용 ⑷ 위의 줄바꿈
#      인용 예외. **전부 위반이 아니라 경계 밖**이며 규약이 양쪽에서 열거한다.
SELFREF_JEOL=$(printf '\354\240\210')   # U+C808 — ps1은 Uni(0xC808)로 같은 문자를 만든다(ASCII 원본 규율)
fi
# 실패하면 **어느 파일의 무엇이 안 풀렸는지 이름을 출력한다**(M40의 자기고발 조치와 같은 취지).
# 진단 문구가 **두 가지를 함께 말한다** — 해소되지 않는 자기참조이거나, 파일명이 두 줄 이상 앞에
# 있는 끊긴 인용이다(위 ⑷ 참조). 어느 쪽인지는 사람이 그 줄과 앞 줄들을 보고 가르며, 어느 쪽이든
# 고칠 것이 있다. 한쪽 이름만 찍으면 원인을 잘못 지목하게 된다.
#
# (M50) 이전 형태는 살아 있는 문서마다 `anchor_set`(3) + `selfref_of`(4) + `cat`(1)을 띄우고
# 자기참조마다 `grep -qxF` 하나를 더 띄웠다(39문서에 약 358 프로세스). 지금은 **awk 한 번**이
# 앵커 추출 · 자기참조 추출 · 소속 대조 · 진단 출력을 함께 한다. **판정 규칙은 그대로다** —
# 표지 넷 · 창은 한 줄 · 앵커는 `##`·`###` 제목의 공백과 CR을 제거한 형태.
# `--`·`</dev/null` 방어는 **필요 없어졌다**(G1과 같은 이유 — 이름이 인자가 아니라 데이터가 됐다).
# 이식성 둘을 지킨다: `{n,m}` 인터벌을 쓰지 않고(`^## `·`^### `로 나눠 쓴다 — 오래된 one-true-awk가
# 인터벌을 받지 않는다. `docs/reports/debug-1.md`와 같은 부류다), 배열 키에 **파일 접두**를 붙여
# `delete`를 반복하지 않는다.
# (M54) **스캔을 함수로 묶는다** — 목록·출력 경로를 인자로 받아야 같은 판정을 픽스처에 걸 수 있다.
# 본문은 한 글자도 바뀌지 않았고 바뀐 것은 **어디서 읽고 어디에 쓰는가**뿐이다.
selfref_scan() { # <living 목록> <자기참조 출력> <미해소 수 출력>
: > "$2"
LC_ALL=C awk -v J="$SELFREF_JEOL" -v BASES="$SBX/convbases.txt" \
    -v LIVING="$1" -v OUT="$2" \
    -v CNT="$3" -v ROOT="$ROOT/" '
function hasbase(t,   i) { for (i = 1; i <= NB; i++) if (index(t, BASE[i])) return 1; return 0 }
BEGIN {
    NB = 0
    while ((getline b < BASES) > 0) if (b != "") { NB++; BASE[NB] = b }
    close(BASES)
    pat = "\"[^\"]*\"[ \t]*" J
    miss = 0
    while ((getline lf < LIVING) > 0) {
        if (lf == "") continue
        nref = 0
        prev = ""
        while ((getline cur < lf) > 0) {
            if (cur ~ /^## / || cur ~ /^### /) {
                a = cur
                sub(/^#* /, "", a)
                gsub(/[ \r]/, "", a)
                OWN[lf SUBSEP a] = 1
            }
            skip = 0
            if (cur ~ /`[A-Za-z0-9_.\/-]+\.(md|sh|ps1|json|yml)`/) skip = 1
            else if (hasbase(cur)) skip = 1
            else if (hasbase(prev)) skip = 1
            if (!skip) {
                line = cur
                while (match(line, pat)) {
                    m = substr(line, RSTART, RLENGTH)
                    rest = substr(m, 2)
                    q = index(rest, "\"")
                    line = substr(line, RSTART + RLENGTH)
                    if (q <= 1) continue
                    v = substr(rest, 1, q - 1)
                    if (v ~ /[{}]/) continue
                    gsub(/[ \r]/, "", v)
                    if (v == "") continue
                    nref++; REF[nref] = v
                }
            }
            prev = cur
        }
        close(lf)
        rel = lf
        if (index(rel, ROOT) == 1) rel = substr(rel, length(ROOT) + 1)
        for (i = 1; i <= nref; i++) {
            print REF[i] > OUT
            if (!((lf SUBSEP REF[i]) in OWN)) {
                miss++
                printf "  ↳ 미해소 자기참조 또는 끊긴 인용: %s → %s\n", rel, REF[i]
            }
        }
    }
    close(OUT)
    print miss > CNT
    close(CNT)
}' < /dev/null
}
if part_on G; then
selfref_scan "$SBX/living.txt" "$SBX/selfrefs.txt" "$SBX/selfmiss.txt"
fi
selfref_fixture() { # → 자기참조가 자기 파일에 없는 앵커를 가리키는 사본에서의 미해소 수
    _srf="$SBX/selfref-fix.md"
    {
        printf '## zzz-real\n'
        printf '\n'
        printf 'xx "zzz-missing" %s yy\n' "$SELFREF_JEOL"
    } > "$_srf"
    printf '%s\n' "$_srf" > "$SBX/living-fix.txt"
    selfref_scan "$SBX/living-fix.txt" "$SBX/selfrefs-fix.txt" "$SBX/selfmiss-fix.txt" > /dev/null
    cat "$SBX/selfmiss-fix.txt"
}
if part_on G; then
SELF_MISS=$(cat "$SBX/selfmiss.txt")
NSELF=$(grep -c . "$SBX/selfrefs.txt")
fi
selfref_has() { grep -qxF -- "$1" "$SBX/selfrefs.txt" </dev/null && echo yes || echo no; }

if part_on G; then
chk "G4: 자기참조가 전부 자기 파일 앵커를 가리킴"   "$SELF_MISS" "0"
chk "G4: 자기참조 추출 positive-control(>0)"        "$([ "$NSELF" -gt 0 ] && echo ok || echo no)" "ok"
chk "G4: 통제 — 가짜 이름(bogus-section) 자기참조 부재" "$(selfref_has 'bogus-section')" "no"
# (M54) 픽스처 통제 — **같은 스캔**을 자기 파일에 없는 앵커를 가리키는 사본에 건다. 위 `G1`과 같은
# 사유이고 같은 반환에서 왔다(M50 리뷰 권장 1 · 부인 기록 있음 · 세 사이클 이월).
chk "G4: 픽스처 통제 — 미해소 자기참조를 실제로 잡는다" "$(selfref_fixture)" "1"
fi

# === Part H — 실행 환경 축 선언 정합 (M38-T06) ===========================
# 규약이 실행 환경의 각 축에 **이름을 붙여 선언**하고(단일 원본: `docs/conventions.md`의
# "실행 환경 축" 절) 축마다 집행처를 적는다. 이 파트가 무는 것은 **정확히 다섯**이다:
# ⑴ 선언된 각 축 이름이 **규약 표의 행**에 실재하는지 ⑵ 축 이름 **집합**이 규약과
# `tests/discover/README.md`에서 **일치**하는지(Part C의 집합 일치 기법과 동형)
# ⑶ 표의 각 `job:<이름>` 토큰이 `.github/workflows/tests.yml`에 **잡 키로 실재**하는지
# ⑷ 그 토큰이 **선언된 축의 행**에 있는지(미선언 행에 적힌 고아 토큰 = FAIL)
# ⑸ 반대로, 워크플로에 **실재하는** 잡이 어느 축 행의 `job:` 토큰으로든 **등재**돼 있는지
#    (커버리지 — 매핑은 옵트인이 아니다).
# (M39) 매핑의 단일 원본이 `env-axis-ci-jobs:` 선언 줄에서 **표의 `job:<이름>` 토큰**으로 옮겨졌다 —
# 선언처가 둘에서 하나로 줄었다. 그래서 ⑷의 의미도 바뀌었다: 예전에는 "매핑에 적은 잡이 표 행에도
# 있는가"였지만(표가 단일 원본이 된 지금 그 물음은 **항진명제**라 공허하게 통과한다), 지금은 "표의
# 잡 토큰이 **선언된 축**의 행에 있는가"를 묻는다.
# 무는 범위를 이보다 넓게 말하지 않는다 — 묻지 **않는** 것 셋: ⓐ CI 잡을 **지목하지 않는** 집행처
# (러너 자기 탐침 · "실제 푸시 뿐 + `pr` 마무리의 PR CI 조회")가 오늘도 사실인지 ⓑ 잡을 지목한 칸의
# **나머지 서술**("3 OS" 등)이 실제 구성과 맞는지 ⓒ **집행 칸의 산문이 실재하지 않는 잡을 주장하는
# 경우**(아래). 셋 다 **사람의 리뷰가 본다**(규약의 같은 절 "기계가 묻지 않는 것" 고지가 단일 원본).
# (M40) 넷째였던 **미선언 표 행**은 닫혔다 — `axis:` 표기(H14~H16)와 **데이터 행 수 == 표기 수**
# (H17)가 표 쪽에서도 축을 세게 만들어 양방향 대조가 섰다. 표기를 적은 미선언 행·표기가 없는 순수
# 산문 행·선언에만 있는 축을 각각 만들어 **셋 다 FAIL함을 양 셸에서 실측**한 뒤 항목을 지웠다
# (규약의 "고지 재산정 규율" — 표기가 생겼다는 사실만으로 줄이면 그것이 `vacuous-pass`다).
# `job:` 표기가 닫은 것과 닫지 않은 것: 예전에는 집행 칸이 산문이라 **실재하지 않는 이름을 잡인 것처럼
# 적어도** 검사에 닿지 않았다(기계는 임의 백틱 토큰이 잡 지목인지 구별할 수 없었다 — M38 리뷰가
# `nowhere`로 실증). `job:` 접두사는 그 모호함을 없애 **토큰으로 지목한 참조**를 ⑶이 물게 한다.
# 그러나 **산문 주장은 그대로 남는다** — M39 리뷰 실측: 토큰을 둔 채 같은 칸에 "CI `nowhere` 잡도
# 집행"을 덧붙여도 초록, 토큰 없는 축의 칸을 "CI `nowhere` 잡이 집행"으로 바꿔도 초록(양 셸).
# 정의가 바뀐 것이지 오도 표면이 사라진 것이 아니다 — 그래서 위 ⓒ를 고지에 남긴다.
# M38 리뷰가 이 자리를 **두 번** 실측으로 반증했다 — ⑶⑷ 이전에는 `posix` 잡을 지우고 표를 그대로
# 둬도 **90/0 초록**, ⑸ 이전에는 **선언된** 미등재 축이 실재 잡을 지목해도 초록이었다.
# 축 이름·잡 이름은 전부 **ASCII 병기어**라 ps1의 ASCII 전용 규율과 정합한다(Part F의 역할 앵커와
# 동형 — 데이터 기반이라 스크립트에 한글 리터럴을 두지 않는다).
env_axes() { # <file> → 공백 구분·정렬된 축 ASCII 이름 (선언 줄 `env-axes: …` 한 줄에서 추출)
    grep -F 'env-axes:' "$1" 2>/dev/null | head -1 |
        sed 's/.*env-axes://; s/-->.*//' |
        tr ' \011' '\n\n' | grep -E '^[a-z][a-z-]*$' |
        LC_ALL=C sort | tr '\n' ' ' | sed 's/ *$//'
}
if part_on H; then
CONV_AXES=$(env_axes "$CONV")
READ_AXES=$(env_axes "$DISC_README")
NAXES=$(printf '%s\n' "$CONV_AXES" | tr ' ' '\n' | grep -c .)
fi

# (H14~H16 · M40) 축 이름의 **해소 가능한 표기** `axis:<이름>`. 표기 이전에는 검사가 전부 `env-axes:`
# 선언을 기점으로 돌아서, **선언에 없는 표 행**은 무엇을 적든 아무 검사도 걸리지 않았다(M38 실측:
# 미선언 `ghost-axis` 행이 실재 잡을 지목해도 초록). 이제 표 쪽에서도 축을 셀 수 있으므로 **양방향**
# 대조가 선다 — 선언에 있는데 표기가 없어도, 표기가 있는데 선언에 없어도 FAIL이다.
# `job:`과 같은 형태라 추출기도 같은 모양이다(표 행에서 토큰만 긁는다).
table_axis_tokens() { # <file> → 정렬·중복제거된 표 행의 `axis:<이름>` (접두사 제거)
    grep -E '^\|' "$1" 2>/dev/null | grep -o 'axis:[a-z][a-z-]*' | sed 's/^axis://' |
        LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ *$//'
}
if part_on H; then
CONV_AXIS_TOKENS=$(table_axis_tokens "$CONV")
NAXIS_TOK=$(printf '%s\n' "$CONV_AXIS_TOKENS" | tr ' ' '\n' | grep -c .)
fi

# (H17) 집합 일치만으로는 **표기가 아예 없는 행**을 못 잡는다 — 토큰이 없으면 집합에 기여하지 않아
# 조용히 통과한다(그 행이 축 표 안의 산문으로 남는 자리다). 그래서 **데이터 행 수 == 표기 수**를
# 따로 문다. 표의 범위는 `env-axes:` 선언 줄 **뒤 첫 마크다운 표**로 잡는다 — 한글 헤더를 앵커로
# 쓰면 `run.ps1`의 ASCII 전용 원본 규율이 깨지므로 ASCII 선언 줄을 기점으로 삼는다.
axis_table_data_rows() { # <file> → 축 표의 데이터 행(헤더·구분선 제외)
    awk '
      f==0 && index($0,"env-axes:")>0 { f=1; next }
      f==1 && /^\|/ { f=2; next }
      f==2 && /^\|/ { f=3; next }
      f==3 && /^\|/ { print; next }
      f==3 { exit }
    ' "$1" 2>/dev/null
}
if part_on H; then
NAXIS_ROWS=$(axis_table_data_rows "$CONV" | grep -c .)
NAXIS_ROW_TOK=$(axis_table_data_rows "$CONV" | grep -c 'axis:[a-z]')
fi

# (H2) 선언된 축마다 규약 **표의 행**(`|`로 시작하는 줄)에 그 이름이 실재 — 선언만 늘리고 표를
# 안 고치는 것(집행 없는 축을 집행되는 것처럼 적는 부류)을 막는다.
axis_row_miss() {
    m=0
    for a in $CONV_AXES; do
        nd=$(printf '`axis:%s`' "$a")
        if grep -F -- "$nd" "$CONV" | grep -qE '^\|'; then : ; else m=$((m + 1)); fi
    done
    echo "$m"
}
has_axis() { # <집합> <이름> → yes|no
    case " $1 " in *" $2 "*) echo yes ;; *) echo no ;; esac
}

# (H6~H9) 표의 **집행 칸**이 CI 잡을 지목하는 축은 그 잡이 실제로 존재하는지까지 문다.
# (M39) 매핑의 단일 원본은 **규약 표 행의 `job:<이름>` 토큰**이고(별도 선언 줄 없음), 잡 이름 집합은
# 워크플로의 `jobs:` 블록에서 **발견**한다(목록 하드코딩 금지 — 발견형 유지). H8은 그 토큰이 **선언된
# 축의 행**에 있는지를 봐서, 미선언 행에 토큰을 숨겨 두는 반대 방향의 드리프트를 막는다.
if part_on H; then
WF="$ROOT/.github/workflows/tests.yml"
AXIS_ROWS="$SBX/axisrows.txt"
grep -E '^\|' "$CONV" 2>/dev/null > "$AXIS_ROWS"
fi

row_job_tokens() { # <행> → 그 행의 잡 이름들 (`job:<이름>` 토큰에서 접두사를 뗀 것)
    printf '%s\n' "$1" | grep -o 'job:[a-z][a-z0-9-]*' | sed 's/^job://'
}
row_axis_names() { # <행> → 그 행의 `axis:` 표기로 실재하는 **선언된** 축 이름들
    for a in $CONV_AXES; do
        na=$(printf '`axis:%s`' "$a")
        case "$1" in *"$na"*) printf '%s\n' "$a" ;; esac
    done
}
env_axis_jobs() { # <file> → 정렬된 `축=잡` 쌍 (규약 표 행의 `job:<이름>` 토큰이 단일 원본)
    while IFS= read -r row; do
        case "$row" in *'job:'*) : ;; *) continue ;; esac
        for j in $(row_job_tokens "$row"); do
            for a in $(row_axis_names "$row"); do
                printf '%s=%s\n' "$a" "$j"
            done
        done
    done < "$AXIS_ROWS" | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ *$//'
}
job_token_orphan() { # 선언된 축이 없는 행에 적힌 `job:` 토큰 수 (미선언 행에 숨겨 통과하는 것을 막는다)
    m=0
    while IFS= read -r row; do
        case "$row" in *'job:'*) : ;; *) continue ;; esac
        if [ -z "$(row_axis_names "$row")" ]; then m=$((m + 1)); fi
    done < "$AXIS_ROWS"
    echo "$m"
}
env_exempt_jobs() { # <file> → 정렬된 면제 잡 이름 (선언 줄 `env-axis-exempt-jobs: …` 한 줄에서 추출)
    grep -F 'env-axis-exempt-jobs:' "$1" 2>/dev/null | head -1 |
        sed 's/.*env-axis-exempt-jobs://; s/-->.*//' |
        tr ' \011' '\n\n' | grep -E '^[a-z][a-z0-9-]*$' |
        LC_ALL=C sort | tr '\n' ' ' | sed 's/ *$//'
}
exempt_job_miss() { # 면제 목록이 가리킨 잡이 워크플로에 실재하지 않는 건수 (낡은 면제 방지)
    m=0
    for j in $EXEMPT_JOBS; do
        case " $CI_JOBS " in *" $j "*) : ;; *) m=$((m + 1)) ;; esac
    done
    echo "$m"
}
no_job_axes() { # `job:` 토큰이 없는 **선언된** 축의 수 (미집행·비-CI 집행 축이 정상임을 보이는 통제)
    m=0
    for a in $CONV_AXES; do
        case " $AXIS_JOBS " in *" $a="*) : ;; *) m=$((m + 1)) ;; esac
    done
    echo "$m"
}
ci_job_names() { # <workflow> → 정렬된 잡 키 (`jobs:` 블록의 2칸 들여쓰기 키만 — `on:` 아래 키 제외)
    awk '/^jobs:/{f=1;next} f&&/^[A-Za-z]/{f=0} f&&/^  [a-z][a-z0-9-]*:[ \011]*$/{gsub(/[ \011:]/,"");print}' \
        "$1" 2>/dev/null | LC_ALL=C sort | tr '\n' ' ' | sed 's/ *$//'
}
if part_on H; then
AXIS_JOBS=$(env_axis_jobs "$CONV")
CI_JOBS=$(ci_job_names "$WF")
EXEMPT_JOBS=$(env_exempt_jobs "$CONV")
NAXJOBS=$(printf '%s\n' "$AXIS_JOBS" | tr ' ' '\n' | grep -c .)
fi

axis_job_miss() { # 매핑이 가리킨 잡이 워크플로에 실재하지 않는 건수
    m=0
    for pair in $AXIS_JOBS; do
        j=${pair#*=}
        case " $CI_JOBS " in *" $j "*) : ;; *) m=$((m + 1)) ;; esac
    done
    echo "$m"
}
has_job() { # <집합> <이름> → yes|no
    case " $1 " in *" $2 "*) echo yes ;; *) echo no ;; esac
}

if part_on H; then
chk "H1: 축 이름 추출 positive-control(>0)"        "$([ "$NAXES" -gt 0 ] && echo ok || echo no)" "ok"
chk "H2: 선언된 축마다 규약 표 행 실재"            "$(axis_row_miss)" "0"
chk "H3: 축 이름 집합 일치(규약 ↔ discover README)" "$([ -n "$CONV_AXES" ] && [ "$CONV_AXES" = "$READ_AXES" ] && echo yes || echo no)" "yes"
chk "H4: 통제 — 가짜 축 이름(bogus-axis) 규약 부재" "$(has_axis "$CONV_AXES" bogus-axis)" "no"
chk "H5: 통제 — 가짜 축 이름(bogus-axis) README 부재" "$(has_axis "$READ_AXES" bogus-axis)" "no"
fi
# (H10·H11) **커버리지** — 등재는 옵트인이 아니다. 워크플로에서 **발견한** 잡은 어느 축 행의
# `job:` 토큰으로든 등재돼 있어야 한다. 없으면 표에 올리지 않는 것만으로 H7·H8을 피해 갈 수 있다 —
# M38 리뷰가 그 옆문을 실측으로 열어 보였다(미등재 축의 집행 칸에 없는 잡 이름을 적어도 94/0 초록).
# 발견형이라 잡 목록도 축 목록도 하드코딩하지 않는다.
axis_job_cover() { # → "<등재된 잡 수> <미등재·미면제 잡 수>"
    n=0; m=0
    for j in $CI_JOBS; do
        case " $AXIS_JOBS " in
            *"=$j "*) n=$((n + 1)); continue ;;
        esac
        case " $EXEMPT_JOBS " in
            *" $j "*) continue ;;
            *) m=$((m + 1)) ;;
        esac
    done
    echo "$n $m"
}
if part_on H; then
COVER=$(axis_job_cover)
COVER_HITS=${COVER% *}
COVER_MISS=${COVER#* }

chk "H6: 표의 job: 토큰 추출 positive-control(>0)"  "$([ "$NAXJOBS" -gt 0 ] && echo ok || echo no)" "ok"
chk "H7: 표가 적은 CI 잡이 워크플로에 실재"        "$(axis_job_miss)" "0"
chk "H8: job: 토큰이 선언된 축 행에 있음(고아 0)"  "$(job_token_orphan)" "0"
chk "H9: 통제 — 가짜 잡 이름(bogus-job) 워크플로 부재" "$(has_job "$CI_JOBS" bogus-job)" "no"
chk "H10: 커버리지 대조 positive-control(>0)"      "$([ "$COVER_HITS" -gt 0 ] && echo ok || echo no)" "ok"
chk "H11: 워크플로의 CI 잡이 축 행 등재 또는 면제 선언" "$COVER_MISS" "0"
# (H12) 통제 — `job:` 토큰이 **없는** 선언 축(비-CI 집행·미집행)이 실재하고, 그것이 FAIL을 만들지
# 않음을 보인다. 토큰 부재가 곧 "CI 잡 집행 없음"의 정직한 표기이므로, 이 경로가 살아 있어야 한다.
chk "H12: 토큰 없는 선언 축 실재 positive-control(>0)" "$([ "$(no_job_axes)" -gt 0 ] && echo ok || echo no)" "ok"
# (H13) 면제 선언도 드리프트한다 — 잡을 지우거나 이름을 바꾸면서 면제만 남기면 낡은 선언이 된다.
chk "H13: 면제 선언된 잡이 워크플로에 실재"        "$(exempt_job_miss)" "0"
# (H14~H16 · M40) `axis:` 표기 — 추출 positive-control + **양방향** 집합 일치.
# 한쪽 방향만 걸면 반쪽이다: 선언에만 있는 축(표 행 누락)은 H2가 이미 물지만, **표기에만 있고 선언에
# 없는 축**(미선언 행)은 이 대조가 처음으로 문다. 두 집합을 문자열로 비교해 양방향을 한 번에 고정한다.
chk "H14: axis: 표기 추출 positive-control(>0)"    "$([ "$NAXIS_TOK" -gt 0 ] && echo ok || echo no)" "ok"
chk "H15: axis: 표기 집합 == env-axes 선언 집합"   "$([ -n "$CONV_AXIS_TOKENS" ] && [ "$CONV_AXIS_TOKENS" = "$CONV_AXES" ] && echo yes || echo no)" "yes"
chk "H16: 통제 — 가짜 축 표기(bogus-axis) 표 부재"  "$(has_axis "$CONV_AXIS_TOKENS" bogus-axis)" "no"
# (H17) 표기 없는 데이터 행 = 표 안의 산문. 행 수와 표기 수가 어긋나면 FAIL(추출 0건이면 두 값이
# 0==0으로 공허 통과하므로 행 수 자체의 positive-control을 함께 둔다).
chk "H17a: 축 표 데이터 행 추출 positive-control(>0)" "$([ "$NAXIS_ROWS" -gt 0 ] && echo ok || echo no)" "ok"
chk "H17b: 축 표 데이터 행 수 == axis: 표기 수"       "$([ "$NAXIS_ROWS" = "$NAXIS_ROW_TOK" ] && echo yes || echo no)" "yes"
fi

# --- Part G (이어서) — 규약 집합 밖 대상 인용 · 열거 번호 인용 ---------------
# 이 자리부터 다시 **G 케이스**다(케이스 표지가 파트다 — 파트 선택 인자가 무는 단위도 그것이다).
# `run.ps1` 사본은 이 둘을 Part G 구획 안에 두므로 **두 사본의 선택 결과가 같다**(M64-T03).
# (G5~G7 · M42) 규약 문서 집합 **밖**을 가리키는 인용. G1의 대조 집합은 `docs/conventions*.md`의 앵커
# 뿐이라 `skills/*/SKILL.md`·`docs/*.md`를 가리킨 인용은 **어느 가드도 보지 않았다** — 네 사이클 미반영
# (M35-impl 후속3)이고, M41이 그 실례를 하나 찾았다(`skills/impl/SKILL.md`의 절 이름이 인용과 어긋남).
# 일반화의 근거: 인용 골격이 **파일명을 명시**하므로 대조는 **그 파일 자신의 앵커**로 하면 되고, 이름
# **유일성은 규약 집합에만** 유지한다(살아 있는 문서 전체로 넓히면 무관한 문서 간 이름 충돌이 터진다).
# 골격은 G4와 같은 표지(`"…" 절`)를 쓴다 — 표지가 없으면 후보가 평범한 인용부호 산문으로 폭발한다.
# 대상 파일이 레포에 **없으면 대조하지 않는다**(경로 자체가 틀린 경우는 이 파트의 경계 밖 — 규약 고지).
if part_on G; then
SKEL_UI=$(printf '\354\235\230')        # U+C758 — 인용 골격의 조사(`…`의 "…" 절). ps1은 Uni(0xC758)
fi
extdoc_cites_of() { # <file> → "<경로>\t<앵커>" (규약 집합 밖 대상만)
    awk -v J="$SELFREF_JEOL" -v UI="$SKEL_UI" -v BASES="$SBX/convbases.txt" '
        BEGIN { while ((getline b < BASES) > 0) if (b != "") BASE[++NB] = b }
        function isconv(p,   i) { for (i = 1; i <= NB; i++) if (index(p, BASE[i])) return 1; return 0 }
        {
            line = $0
            while (match(line, /`[A-Za-z0-9_.\/-]+\.md`/)) {
                p = substr(line, RSTART + 1, RLENGTH - 2)
                rest = substr(line, RSTART + RLENGTH)
                pat = "\"[^\"]*\"[ \t]*" J
                # 골격의 조사(`경로`**의** "앵커" 절)를 요구한다 — 이것이 없으면 뒤따르는 인용부호가
                # 그 경로를 가리킨다는 근거가 없다(실측 오탐: 경로 뒤에 자기 파일의 절을 가리키는
                # `위 "…" 절`이 오는 줄. 그 자리는 G4가 무는 자기참조다).
                if (!isconv(p) && index(rest, UI) == 1 && match(rest, pat)) {
                    m = substr(rest, RSTART, RLENGTH); s = substr(m, 2); q = index(s, "\"")
                    if (q > 1) {
                        a = substr(s, 1, q - 1); gsub(/[ \r]/, "", a)
                        if (a != "" && a !~ /[{}]/) printf "%s\t%s\n", p, a
                    }
                }
                line = rest
            }
        }' "$1"
}
if part_on G; then
TAB=$(printf '\t')
fi
extdoc_misses() { # <레코드 파일> → 미해소 인용(사람이 읽을 형태)
    while IFS="$TAB" read -r p a; do
        [ -n "$a" ] || continue
        [ -f "$ROOT/$p" ] || continue
        anchor_set "$ROOT/$p" > "$SBX/extanchors.txt"
        grep -qxF -- "$a" "$SBX/extanchors.txt" </dev/null || printf '%s -> %s\n' "$p" "$a"
    done < "$1"
}
if part_on G; then
: > "$SBX/extcites.txt"
while IFS= read -r f; do
    [ -f "$f" ] || continue
    extdoc_cites_of "$f" >> "$SBX/extcites.txt"
done < "$SBX/living.txt"
NEXTCITE=$(grep -c . "$SBX/extcites.txt")
EXTMISS=$(extdoc_misses "$SBX/extcites.txt")
NEXTMISS=$(printf '%s\n' "$EXTMISS" | grep -c .)
[ "$NEXTMISS" = "0" ] || printf '%s\n' "$EXTMISS" | sed 's/^/  -> broken cross-doc citation: /'
chk "G5: 규약 밖 인용이 전부 실재 앵커를 가리킴"   "$NEXTMISS" "0"
chk "G6: 규약 밖 인용 추출 positive-control(>0)"   "$([ "$NEXTCITE" -gt 0 ] && echo ok || echo no)" "ok"
# 주입 통제 — 실재하는 대상 파일에 없는 앵커를 가리키는 인용을 심으면 잡아야 한다(공허 아님 실증).
printf -- '- `skills/impl/SKILL.md`%s "bogus-cross-anchor" %s\n' "$SKEL_UI" "$SELFREF_JEOL" > "$SBX/extfx.md"
extdoc_cites_of "$SBX/extfx.md" > "$SBX/extfx.txt"
chk "G7: 통제 — 주입한 깨진 규약 밖 인용을 잡는다" "$(extdoc_misses "$SBX/extfx.txt" | grep -c .)" "1"
fi

# (G8 · M44) 절 **안의 항목**을 열거 번호로 가리키는 인용을 금지한다. M43 리뷰 이슈 5가 그 부류다 —
# 원장의 인용이 `묻지 않는 것 ⑷`를 가리켰는데 그 번호는 M40이 닫아 없앤 항목이었고, 인용을 옮긴
# 편집이 하류를 함께 고치지 않아 생겼다. Part G의 나머지는 **절 앵커까지만** 대조하므로 하위 인덱스는
# 어느 케이스도 보지 않았다. 단일 원본은 `docs/conventions.md`의 "상호참조 무결성" 절.
#   판별: 인용 줄(백틱 `.md` 경로 + 따옴표)에서 `절` 표지 **뒤에** 열거 번호가 오면 위반.
#   집합: **U+2460~U+2487**(40자). 두 러너가 같은 집합을 쓰는지 각자 단언한다 — ps1은 ASCII-only
#         규율 때문에 코드포인트로 조립하고, 이 사본도 **같은 방식으로 조립**해(리터럴을 두지 않는다)
#         집합이 구성상 일치한다. `SELFREF_JEOL`(U+C808)이 이미 같은 방식으로 만들어져 있다.
#   왜 금지형인가: 살아 있는 사이트가 **0건**이라 추출형으로 세우면 "추출 0 = FAIL" 규율에 걸려
#         정상 트리가 붉어진다. 그래서 **금지형 + 픽스처 통제**로 세운다 — 픽스처가 공허를 막는다.
#   경계(규약에 함께 적혀 있다): 번호가 `절` **앞**에 오는 산문 열거 참조는 대상이 아니다(실측 1건이
#         그 형태이며 정당하다) · 이름으로 가리킨 항목의 **실재**는 대조하지 않는다 · 인용과 번호가
#         다른 줄로 갈리면 빠진다(줄 단위 추출의 알려진 한계).
circ_list() {   # U+2460..U+2487 을 한 줄에 한 자씩 — 코드포인트 조립(ASCII 원본 규율)
    _n=160; while [ "$_n" -le 191 ]; do printf "\342\221$(printf '\\%o' "$_n")\n"; _n=$((_n + 1)); done
    _n=128; while [ "$_n" -le 135 ]; do printf "\342\222$(printf '\\%o' "$_n")\n"; _n=$((_n + 1)); done
}
if part_on G; then
circ_list > "$SBX/circ.txt"
NCIRC=$(grep -c . "$SBX/circ.txt")
CIRCBYTES=$(LC_ALL=C wc -c < "$SBX/circ.txt" | tr -d ' ')
fi

cite_lines_of() { # <문서> → 인용 줄(경로:줄번호:본문)
    grep -n '`[A-Za-z0-9_./-]*\.md`' "$1" 2>/dev/null | grep '"' | sed "s|^|$1:|"
}
g8_hits() { # <인용 줄 파일> → 위반 줄 수 (절 표지 뒤 열거 번호)
    : > "$1.hits"
    while IFS= read -r _c; do
        [ -n "$_c" ] || continue
        LC_ALL=C grep -E "$SELFREF_JEOL.*$_c" "$1" >> "$1.hits" 2>/dev/null
    done < "$SBX/circ.txt"
    # `LC_ALL=C sort`: 로케일이 걸리면 비교가 바이트 동등이 아니라 collation 동등이 되어 **중복 제거
    # 결과가 두 셸에서 갈린다**(M40이 `tests/discover`에서, M42가 `tests/lib`에서 같은 부류를 잡았다).
    # ps1은 ordinal 비교이므로 이쪽도 바이트 동등으로 고정해야 의미가 같다.
    LC_ALL=C sort -u "$1.hits" | grep -c .
}

if part_on G; then
: > "$SBX/g8cites.txt"
while IFS= read -r f; do
    [ -f "$f" ] || continue
    cite_lines_of "$f" >> "$SBX/g8cites.txt"
done < "$SBX/living.txt"

NG8=$(g8_hits "$SBX/g8cites.txt")
NG8CITES=$(grep -c . "$SBX/g8cites.txt")
[ "$NG8" = "0" ] || LC_ALL=C sort -u "$SBX/g8cites.txt.hits" | sed 's/^/  -> ordinal sub-index citation: /'
chk "G8a: 열거 번호 집합 40자·160바이트(줄바꿈 포함)" "$NCIRC/$CIRCBYTES" "40/160"
# 추출 positive-control — **금지형이어도 훑을 대상이 비면 공허하다**. 위 `cite_lines_of`의 정규식이나
# `living.txt` 범위가 망가지면 G8b가 `0 == 0`으로 조용히 통과하므로, 인용 줄 자체가 하나라도 잡히는지를
# 단언한다(체크리스트 ⑴ — G2·G6·G4의 추출 통제와 동형. 이 자리가 M44 리뷰의 in-review 수정이다).
chk "G8b0: 인용 줄 추출 positive-control(>0)"        "$([ "$NG8CITES" -gt 0 ] && echo ok || echo no)" "ok"
chk "G8b: 절 표지 뒤 열거 번호 인용 0건"              "$NG8" "0"
# 픽스처 통제 — 위반 한 줄을 주입하면 잡아야 한다(살아 있는 사이트가 0건이라 이것이 공허를 막는다).
{ printf -- '- `docs/conventions.md`%s "%s" %s ' "$SKEL_UI" "bogus-anchor" "$SELFREF_JEOL"
  sed -n '24p' "$SBX/circ.txt"; } > "$SBX/g8fx.txt"
chk "G8c: 통제 — 주입한 열거 번호 인용을 잡는다"      "$(g8_hits "$SBX/g8fx.txt")" "1"
fi

# === Part I — 축 상태 주장 정합 (M42) ====================================
# 표가 **집행된다**고 적은 축을 산문이 **반대로** 적는 자리를 문다. 카운트는 B1·F1이, 명단은 C-3·C-4가,
# 인용은 Part G가 물지만 "두 문단이 반대되는 사실을 말한다"는 층에는 수단이 없었다 — M41 사이클에 이
# 부류가 **세 건** 나왔고 그중 둘이 축 이름 부류였다(리뷰가 두 번 놓쳤다).
# 규칙·표지·경계의 단일 원본은 `docs/conventions.md`의 "축 상태 주장 정합" 절이다. 요지:
#   POS = 축 표의 `axis:` 토큰 집합(집행 칸이 살아 있는 축) — Part H가 이미 추출한 것을 재사용한다.
#   NEG = 살아 있는 문서의 **불릿 블록**에 축 이름(블록 머리에서 상속)과 `state-neg:` 표지가 공존.
#   빼는 것 둘 — 인용부호에 싸인 부정어(규칙 서술)·`state-past:` 표지가 든 줄(이력 서술).
# 표지는 **규약이 단일 선언처**이고 러너는 읽기만 한다 — 스크립트에 한글 리터럴을 두지 않는 데이터
# 기반 검사라 ps1의 byte>127=0 규율을 유지한다(F2·G4·site-includes 용어 추출과 동형).
# **선언 줄의 형태**가 판별자다 — 불릿 시작 **직후**에 백틱으로 감싼 키(`` - `state-neg:` … ``).
# 산문 언급(`` - **규칙**: … `state-neg:` 표지가 … ``)은 키가 줄 앞머리에 오지 않아 걸리지 않는다.
# 규약이 *"아래 두 줄이 표지의 유일한 선언처다"*라고 적은 그 두 줄이 정확히 이 형태이며, **추출도
# 유일성 검사(I7~I9)도 같은 줄에서** 한다. 공백류는 **공백·탭 두 문자로만** 본다(ps1의 `[ \t]`와
# 같은 넓이) — 어떻게 그 넓이를 얻는지는 바로 아래 `decl_lines`가 정한다.
# 선언 줄 판별은 **정규식도 grep도 쓰지 않는다** — awk의 리터럴 비교로 한다. 이유가 둘이다.
#   ⑴ **로케일**: `grep -E`의 `[[:blank:]]`는 로케일 의존이라 UTF-8 로케일에서 U+2003·U+1680·
#      U+205F·U+3000 같은 유니코드 공백까지 먹는다(실측: `LC_ALL=C` 0 ↔ `C.UTF-8` 1 ↔
#      `en_US.UTF-8` 1). ps1 사본의 `[ \t]`는 그 넓이가 아니라 **개발 기계는 초록, 우분투
#      CI(`C.UTF-8`)는 붉음**이 된다(M42 리뷰 권장 2).
#   ⑵ **바이트 충실성**: 이 환경의 `grep`(GNU 3.0/MSYS)은 **줄 가운데 CR을 버린다** — 실측으로
#      같은 줄이 파일에 홀로 있으면 보존되고 앞에 40줄을 두면 사라졌다(`sed`·`awk`는 둘 다 보존).
#      그래서 grep을 쓰는 한 sh는 ps1이 보는 것과 **다른 바이트**를 보고, CR 부류의 검사가
#      환경에 따라 공허해진다(M42 리뷰 차단 1이 이 층이다).
# 리터럴 비교는 셋을 한꺼번에 없앤다 — 로케일 축·CR 유실·키 이스케이프(M42 리뷰 사소 6, 이제
# 이스케이프할 정규식 자체가 없다). 의미는 ps1의 `^[ \t]*-[ \t]+<Escape(키)>`와 같다.
# CR은 **줄 끝 하나만** 벗긴다(CRLF 체크아웃) — ps1의 `-split "\r?\n"`이 소비하는 범위와 같다.
decl_lines() { # <file> <키> → 선언 줄(0줄 이상)
    [ -f "$1" ] || return 0
    awk -v k="\`$2\`" -v cr="$(printf '\r')" '{
        s = $0
        if (length(s) > 0 && substr(s, length(s), 1) == cr) s = substr(s, 1, length(s) - 1)
        i = 1
        while (i <= length(s) && (substr(s, i, 1) == " " || substr(s, i, 1) == "\t")) i++
        if (substr(s, i, 1) != "-") next
        i++
        n = 0
        while (i <= length(s) && (substr(s, i, 1) == " " || substr(s, i, 1) == "\t")) { i++; n++ }
        if (n < 1) next
        if (substr(s, i, length(k)) != k) next
        print s
    }' "$1" 2>/dev/null
    return 0
}
decl_count() { # <file> <키> → 선언 줄 개수
    decl_lines "$1" "$2" | grep -c .
}
# 선언 줄에서 키 **바로 뒤 꼬리**. 표지 추출(`markers_of`)과 구분자 검사(`bad_seps`)가 **같은
# 문자열**을 보게 하는 단일 자리다. 정규식을 쓰지 않고 `index`+`substr`로 끊어 ps1 사본의
# `IndexOf`+`Substring`과 **문자 그대로 같은 의미**를 갖는다(키가 리터럴이므로 이스케이프 축이
# 아예 없어진다). 앞의 `tr -d '\r'`는 CRLF 체크아웃에서 꼬리 끝에 CR이 붙는 것을 막는다 —
# ps1은 줄을 `\r?\n`으로 쪼개 애초에 CR을 보지 않으므로 여기서 맞춘다.
decl_tail() { # <file> <키> → 꼬리 1줄(없으면 빈 출력)
    # 줄 끝 CR은 `decl_lines`가 이미 벗겼고 **줄 가운데 CR은 그대로 넘어온다** — 그래야 `bad_seps`가
    # 그것을 볼 수 있다. 앞선 판본은 여기서 `tr -d '\r'`로 **통째로 지웠고**, 그러면 ⑴ 양옆 표지가
    # **한 토큰으로 붙어** 표지를 조용히 잃고 ⑵ CR이 `SEP_RE`에 있어도 도달할 수 없어 금지가
    # 공허해진다(M42 리뷰 차단 1의 실측: sh만 136/0 초록, ps1은 134/2). **지우는 문자와 금지하는
    # 문자가 겹치면 금지는 집행되지 않는다.**
    # 정규식을 쓰지 않는다 — 첫 매치를 `index`로 끊어 ps1의 `IndexOf`+`Substring`과 같은 의미로 둔다.
    decl_lines "$1" "$2" | head -1 |
        awk -v k="\`$2\`" '{ i = index($0, k); if (i > 0) print substr($0, i + length(k)) }'
}
# **구분자 집합** — 두 셸 중 **어느 하나라도 공백으로 볼 수 있는** 문자 전부(ASCII 공백 0x20은 뺀다).
# .NET `\s` = `[\f\n\r\t\v\x85\p{Z}]`이고 `\p{Z}`가 NBSP·OGHAM·U+2000~200A·U+2028/2029·U+202F·
# U+205F·U+3000을 포함한다 — 그 합집합을 **바이트**로 적는다. 8진 이스케이프만 쓴다(dash의 `printf`가
# `\xHH`를 해석하지 않는다는 M37 실측). 비교는 `LC_ALL=C`로 고정해 바이트 매칭으로 둔다.
SEP_RE=$(printf '[\t\013\014\r]|\302[\205\240]|\341\232\200|\342\200[\200-\212\250\251\257]|\342\201\237|\343\200\200')
bad_seps() { # <file> <키> → 꼬리에 금지 구분자가 있으면 1, 없으면 0
    decl_tail "$1" "$2" | LC_ALL=C grep -Ec "$SEP_RE"
}
# **첫 매치 고정**은 이제 `decl_tail`이 `index()`로 한다(위) — 예전 구현은 `sed "s/.*$1//"`이었는데
# sed의 선행 `.*`는 탐욕이라 한 줄에 키가 둘이면 **마지막**을, ps1의 `IndexOf`는 **첫 번째**를
# 집었다(M42 리뷰 차단 2의 실측: sh 추출이 통째로 붕괴해도 I1·I3~I6이 자기정합적으로 통과하고
# **I2가 0==0으로 조용히 통과**했다).
# **쪼개는 폭도 ps1과 같아야 한다** — 여기는 **ASCII 공백 하나**로만 쪼개고 ps1 사본은 `-split ' '`다.
# 앞선 판본은 sh가 `tr ' '`, ps1이 `-split '\s+'`이라 **탭·NBSP에서 갈렸고**, 선언 줄 끝의 탭 한
# 글자에 sh만 마지막 표지를 잃고도 **조용히 초록**이었다(M42 리뷰 차단 1의 실측 — 트레일링 탭·NBSP
# 둘 다). 폭을 맞추는 것만으로는 그 조용함이 닫히지 않는다 — 폭 밖 문자가 오면 **양 셸이 나란히**
# 표지를 잃기 때문이다. 그래서 아래 **I10~I13**이 꼬리의 구분자를 ASCII 공백 하나로 못박아 그
# 부류를 **시끄럽게** 만든다.
markers_of() { # <키> → 그 키가 선언한 표지 토큰(백틱·강조 제거, 한 줄에 하나)
    decl_tail "$CONV" "$1" | tr -d '`*' | tr ' ' '\n' | grep -v '^$'
}
if part_on I; then
NEG_MARKS=$(markers_of 'state-neg:')
PAST_MARKS=$(markers_of 'state-past:')
NMARK=$(printf '%s\n' "$NEG_MARKS" | grep -c .)
# **awk `-v` 전송은 공백으로 한다 — 생 개행은 BSD awk를 죽인다.** one-true-awk(macOS `/usr/bin/awk`)는
# `-v` 값에 **생 개행**이 들어오면 `awk: newline in string …`으로 죽고 출력이 통째로 빈다. GNU awk와
# mawk는 통과하므로 **개발 기계도 우분투 CI도 초록이고 macOS 레그에서만 붉다**(debug-1 항목 1의 실측:
# `live_axes`가 빈 출력을 내 `I1b`가 `got no`, 그 파생으로 `I3`가 `got 0`). 표지는 `markers_of`가
# **공백으로 쪼개** 만들므로 **공백을 포함할 수 없다** — 개행을 공백으로 바꿔 실어도 무손실이다.
# 같은 `contra_of`의 `AX`가 이미 이 전송(`split(AX, A, " ")`)을 쓰고 BSD에서 통과한다 — 새 기전을
# 들이는 것이 아니라 **이미 통과하는 전송으로 나머지 둘을 맞추는** 것이다.
NEG_MARKS_SP=$(printf '%s' "$NEG_MARKS" | tr '\n' ' ')
PAST_MARKS_SP=$(printf '%s' "$PAST_MARKS" | tr '\n' ' ')
fi

# POS 집합 = 표에서 **집행 칸이 살아 있는** 축만이다. 전체 `axis:` 토큰을 쓰면 규약이 **의무화한**
# 정직 표기(집행이 없는 축은 부정 상태어로 명시)가 곧 모순으로 잡혀, 그 축의 표 행 자체가 FAIL을
# 만든다(리뷰 실측: 한 축의 집행 칸을 부정 상태어로 바꾸면 그 행이 `axis-state contradiction`으로
# 걸렸다). 규약이 서술한 기전과 러너를 같은 넓이로 맞춘다.
live_axes() { # → 집행 칸이 살아 있는 축 이름(공백 구분)
    # 표 행의 인식 넓이는 ps1 사본과 **같아야 한다**(M42 리뷰 권장 5의 처분). 이 게이트가 없으면
    # 들여쓴 표 행을 sh만 POS로 집어 두 셸이 같은 트리에 다른 판정을 낸다(실측). `^|`는 ps1의
    # `StartsWith('|')`, `NF >= 5`는 `$cols.Count -ge 5`와 같은 의미다(`| a | b | c |` → NF=5).
    awk -F'|' -v NEG="$NEG_MARKS_SP" '
        BEGIN { nn = split(NEG, NG, " ") }
        /^\|/ && NF >= 5 && /axis:[a-z][a-z-]*/ {
            name = ""
            if (match($2, /axis:[a-z][a-z-]*/)) name = substr($2, RSTART + 5, RLENGTH - 5)
            cell = $4; gsub(/[ \t\r]/, "", cell)
            dead = 0
            for (i = 1; i <= nn; i++) if (NG[i] != "" && index(cell, NG[i])) dead = 1
            if (name != "" && cell != "" && !dead) print name
        }' "$CONV" | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ *$//'
}
if part_on I; then
POS_AXES=$(live_axes)
fi

contra_of() { # <file> → "<축>:<줄번호>" (모순 후보, 한 줄에 하나)
    awk -v AX="$POS_AXES" -v NEG="$NEG_MARKS_SP" -v PAST="$PAST_MARKS_SP" '
        BEGIN { na=split(AX, A, " "); nn=split(NEG, NG, " "); np=split(PAST, PS, " ") }
        {
            raw = $0
            line = raw; gsub(/[ \t\r]/, "", line)
            # 창 = 불릿 블록. 제목·표 행도 경계로 친다(축 이름이 블록을 넘어 새지 않게).
            if (raw ~ /^- / || raw ~ /^#/ || raw ~ /^\|/) delete cur
            for (i = 1; i <= na; i++) if (A[i] != "" && index(line, A[i])) cur[A[i]] = 1
            # 표지 선언 줄 자신은 대상이 아니다(선언처가 자기 표지에 걸리면 전건 오탐이 된다).
            if (index(line, "state-neg:") || index(line, "state-past:")) next
            m = ""
            for (i = 1; i <= nn; i++) if (NG[i] != "" && index(line, NG[i])) { m = NG[i]; break }
            if (m == "") next
            if (index(line, "\"" m "\"")) next                       # 인용된 부정어 = 규칙 서술
            for (i = 1; i <= np; i++) if (PS[i] != "" && index(line, PS[i])) next   # 이력 서술
            for (a in cur) print a ":" NR
        }' "$1"
}
contra_count() { # 살아 있는 문서 전체의 후보 수
    n=0
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        c=$(contra_of "$f" | grep -c .)
        n=$((n + c))
    done < "$SBX/living.txt"
    echo "$n"
}

# (I1) 표지를 못 읽으면 아래 전부가 0==0으로 **공허 통과**한다 — 추출 자체를 먼저 문다.
if part_on I; then
chk "I1: state-neg 표지 추출 positive-control(>0)" "$([ "$NMARK" -gt 0 ] && echo ok || echo no)" "ok"
# (I1b) POS 집합도 positive-control이 필요하다 — 표 형식이 바뀌어 집행 칸 추출이 어긋나면 POS가 비고
# I2가 **0==0으로 조용히 통과**한다(H14가 무는 것은 `axis:` 토큰 집합이지 이 파생 집합이 아니다).
NPOS=$(printf '%s\n' "$POS_AXES" | tr ' ' '\n' | grep -c .)
chk "I1b: 집행 칸이 살아 있는 축 추출 positive-control(>0)" "$([ "$NPOS" -gt 0 ] && echo ok || echo no)" "ok"
# (I2) 본 검사 — 살아 있는 문서에 축 상태 모순 0건. 실패하면 **어느 축이 어느 파일 몇 줄에서** 어긋났는지
# 이름을 찍는다(M40의 자기고발 조치와 같은 취지 — 개수만 보면 원인을 찾는 데 다시 사람이 든다).
I2=$(contra_count)
if [ "$I2" != "0" ]; then
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        contra_of "$f" | while IFS= read -r hit; do
            [ -n "$hit" ] && printf '  -> axis-state contradiction: %s (%s)\n' "$hit" "${f##*/}"
        done
    done < "$SBX/living.txt"
fi
chk "I2: 살아 있는 문서의 축 상태 모순 0건" "$I2" "0"

# (I3~I6) 통제 — 주입한 모순은 잡고, 규칙이 일부러 뺀 셋은 잡지 않는다. 픽스처는 샌드박스에 만든다
# (살아 있는 문서를 건드리면 I2가 자기 픽스처를 세게 된다).
ICON="$SBX/contra"
mkdir -p "$ICON"
IAX=$(printf '%s\n' "$POS_AXES" | tr ' ' '\n' | grep -v '^$' | head -1)
INEG=$(printf '%s\n' "$NEG_MARKS" | head -1)
IPAST=$(printf '%s\n' "$PAST_MARKS" | head -1)
printf -- '- **`%s` axis**: %s\n' "$IAX" "$INEG" > "$ICON/inject.md"
printf -- '- **`%s` axis**: "%s"\n' "$IAX" "$INEG" > "$ICON/quoted.md"
printf -- '- **`%s` axis**: %s%s\n' "$IAX" "$INEG" "$IPAST" > "$ICON/past.md"
printf -- '- no axis name here: %s\n' "$INEG" > "$ICON/notarget.md"
chk "I3: 음성 통제 — 주입한 축 상태 모순을 잡는다"  "$(contra_of "$ICON/inject.md" | grep -c .)"   "1"
chk "I4: 통제 — 인용된 부정어(규칙 서술)는 미검출"   "$(contra_of "$ICON/quoted.md" | grep -c .)"   "0"
chk "I5: 통제 — 이력 서술(과거 표지)은 미검출"       "$(contra_of "$ICON/past.md" | grep -c .)"     "0"
chk "I6: 통제 — 대상(축 이름) 없는 부정어는 미검출"  "$(contra_of "$ICON/notarget.md" | grep -c .)" "0"

# (I7~I9) **선언처 유일성** — 규약은 *"아래 두 줄이 표지의 유일한 선언처다"*라고 적지만, 지금까지
# 두 러너 모두 키가 **처음 나오는 줄**을 무조건 선언처로 삼아 그 문장을 기계가 물지 않았다
# (M42 리뷰 사소 8). 0개면 선언이 사라진 것이고(추출이 통째로 빈다), 2개 이상이면 선언처가 갈라져
# **어느 줄이 이기는지가 러너 구현에 달린다** — 둘 다 FAIL이다. 이 검사는 **어느 줄을 읽는지**를
# 물고, 아래 I10~I13이 **그 줄을 어떻게 쪼개는지**를 문다. 둘이 함께 있어야 차단 2(첫 매치 대
# 마지막 매치)와 차단 1(구분자 폭)의 재발이 막힌다 — 앞선 판본은 여기서 *"어느 편집이 시끄럽고
# 어느 편집이 조용한지가 우연에서 벗어난다"*고 적었으나 **거짓이었다**(M42 리뷰 차단 1: 트레일링
# 탭·NBSP는 여전히 조용했다). 지금 성립하는 것만 적는다 — **아래 구분자 집합에 든 문자**가 꼬리에
# 오면 양 셸이 함께 붉어진다. 표지 알파벳 자체(어떤 글자가 표지가 될 수 있는가)는 **묻지 않는다**.
chk "I7: state-neg 선언 줄이 규약에 정확히 1개"  "$(decl_count "$CONV" 'state-neg:')"  "1"
chk "I8: state-past 선언 줄이 규약에 정확히 1개" "$(decl_count "$CONV" 'state-past:')" "1"
# 통제 — 산문 언급은 선언처로 세지 않는다(판별자가 살아 있음의 실증). 픽스처는 **ASCII만** 쓴다:
# `run.ps1` 사본이 글자 그대로 같은 세 줄을 쓰므로 두 셸이 같은 것을 세는지가 바로 드러난다.
{
    printf -- '- `%s` alpha beta\n' 'state-neg:'
    printf -- '- **rule**: the `%s` marker is declared above and only mentioned here\n' 'state-neg:'
    printf -- 'a prose line mentioning `%s` in the middle\n' 'state-neg:'
} > "$ICON/decl.md"
chk "I9: 통제 — 산문 언급은 선언처로 세지 않는다" "$(decl_count "$ICON/decl.md" 'state-neg:')" "1"

# (I10~I13) **선언 줄 꼬리의 구분자는 ASCII 공백 하나뿐이다**(M42 리뷰 차단 1의 처분). 두 러너의
# 쪼개는 폭을 맞추는 것만으로는 부족하다 — 폭 밖 문자(탭·NBSP 등)가 오면 양 셸이 **나란히** 표지를
# 잃고 I2가 다시 0==0으로 조용히 통과하기 때문이다. 그래서 폭을 맞추고(위 `markers_of`) **폭 밖
# 문자를 금지**해 그 부류를 시끄럽게 만든다. I12·I13은 그 금지가 공허하지 않음의 실증이다 —
# 픽스처는 **ASCII 소스**로 바이트를 만들고(`printf` 8진), ps1 사본이 같은 바이트를 쓴다.
chk "I10: state-neg 선언 줄 꼬리에 금지 구분자 0건"  "$(bad_seps "$CONV" 'state-neg:')"  "0"
chk "I11: state-past 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" 'state-past:')" "0"
printf -- '- `%s` alpha\tbeta\n'      'state-neg:' > "$ICON/sep-tab.md"
printf -- '- `%s` alpha\302\240beta\n' 'state-neg:' > "$ICON/sep-nbsp.md"
chk "I12: 통제 — 탭 구분자를 잡는다"   "$(bad_seps "$ICON/sep-tab.md" 'state-neg:')"  "1"
chk "I13: 통제 — NBSP 구분자를 잡는다" "$(bad_seps "$ICON/sep-nbsp.md" 'state-neg:')" "1"
fi

# (I14~I15) **구분자 집합을 규약에서 읽어 자기 구현을 검사한다**(M42 재작업 3). 집합이 세 매체
# (규약의 한글 이름 · 여기 8진 바이트 · ps1의 `\uXXXX`)에 흩어져 문자열 대조로는 닫히지 않았고,
# *"읽어서 확인했다"* 가 **세 라운드 연속 틀렸다**. 그래서 규약의 `sep-cps:` 선언을 **단일 원본**으로
# 두고, 각 코드포인트를 UTF-8로 인코딩해 **자기 픽스처를 만들어** 자기 패턴이 실제로 잡는지 센다.
# 이 검사는 **패턴만 보지 않고 추출 파이프라인 전체를 통과**시킨다 — M42 리뷰 차단 1(CR이 집합에는
# 있는데 `decl_tail`이 먼저 지워 도달 불가)이 바로 그 차이에서 났다.
# 인코딩은 awk 정수 연산 + `printf` 8진으로 한다(POSIX — dash의 `\xHH` 비호환 회피, M37 실측).
utf8_oct() { # <16진 코드포인트> → printf용 8진 이스케이프
    awk -v h="$1" 'BEGIN{
        n = 0; s = toupper(h)
        for (i = 1; i <= length(s); i++) { n = n * 16 + index("0123456789ABCDEF", substr(s, i, 1)) - 1 }
        if (n < 128) printf "\\%03o", n
        else if (n < 2048) printf "\\%03o\\%03o", 192 + int(n / 64), 128 + (n % 64)
        else printf "\\%03o\\%03o\\%03o", 224 + int(n / 4096), 128 + int(n / 64) % 64, 128 + (n % 64)
    }'
}
sep_hits() { # <코드포인트 목록> → 그중 몇 개를 잡는지
    _h=0
    for _cp in $1; do
        printf -- "- \`state-neg:\` alpha$(utf8_oct "$_cp")beta\n" > "$ICON/sep-cp.md"
        _h=$((_h + $(bad_seps "$ICON/sep-cp.md" 'state-neg:')))
    done
    echo "$_h"
}
if part_on I; then
SEP_CPS=$(markers_of 'sep-cps:')
SEP_OK_CPS=$(markers_of 'sep-ok-cps:')
NSEP=$(printf '%s\n' "$SEP_CPS" | grep -c .)
# (I16~I19) **새 선언 키 둘에도 기존 규율을 그대로 건다**(M42 리뷰 차단 1의 처분). I14·I15는 선언을
# **읽어서** 자기 구현을 검사하는데, 그 선언이 **사라지면 집합이 비어 `0 == 0`으로 통과**한다 — 실측:
# `sep-cps:` 줄 하나를 지우면 네 환경이 전부 140/0 초록이었다. 이 레포는 같은 함정을 `I1`·`I1b`·`G6`·
# `F4` 넷에서 이미 막아 왔고, `I7`·`I8`은 다른 두 키에 **선언 줄 유일성**까지 건다. 새 키 둘만 그
# 규율 밖에 있었다 — 집행을 세우는 라운드가 **그 집행을 무는 통제를 빠뜨리는** 이 사이클의 반복
# 형태다. 추출(>0)과 유일성(정확히 1개)을 함께 건다.
NSEPOK=$(printf '%s\n' "$SEP_OK_CPS" | grep -c .)
chk "I16: sep-cps 추출 positive-control(>0)"    "$([ "$NSEP" -gt 0 ] && echo ok || echo no)"    "ok"
chk "I17: sep-ok-cps 추출 positive-control(>0)" "$([ "$NSEPOK" -gt 0 ] && echo ok || echo no)" "ok"
chk "I18: sep-cps 선언 줄이 규약에 정확히 1개"    "$(decl_count "$CONV" 'sep-cps:')"    "1"
chk "I19: sep-ok-cps 선언 줄이 규약에 정확히 1개" "$(decl_count "$CONV" 'sep-ok-cps:')" "1"
chk "I14: 규약이 선언한 구분자를 전부 잡는다"   "$(sep_hits "$SEP_CPS")"    "$NSEP"
chk "I15: 통제 — 허용 문자는 잡지 않는다"       "$(sep_hits "$SEP_OK_CPS")" "0"
fi

# --- Part F (이어서) — 문서 자기서술 정합 · 러너 소스 규율 -------------------
# 여기부터 다시 **F 케이스**다(F1b·F4~F20). 물리적 자리는 Part I 뒤지만 **케이스 표지가 파트**이고,
# 파트 선택 인자가 무는 단위도 그것이다 — 두 사본이 같은 자리에서 같은 표지로 갈린다(M64-T03).
declared_cases() {
    # **첫 매치 고정** — sed의 선행 `.*`는 탐욕이라 한 줄에 `cases:`가 둘이면 **마지막**을 집는데
    # ps1의 `[regex]::Match`는 **첫 번째**를 집는다(M38 리뷰 사소 4의 실측: 같은 입력에 sed 7 ↔
    # .NET 42). `grep -o`는 매치를 파일·줄 순서대로 내므로 `head -1`이 곧 첫 매치다 — 양 셸 동형.
    grep -o 'cases:[^0-9]*[0-9][0-9]*' "$DISC_README" 2>/dev/null | head -1 |
        grep -o '[0-9][0-9]*' | head -1
}

# (F1b) 파트별 내역 합 == 총계 선언 — F1은 **총계**만 본다. 총계를 고치면서 내역
# (`Part A 7 + Part B 14 + ...`)을 안 고치면 같은 줄 안에서 조용히 갈라진다(자기서술 드리프트의
# 한 겹 아래). 내역은 전부 ASCII 골격이라 양 셸이 같은 방식으로 합산한다.
# 합산 범위는 **선언 줄 한 줄**로 좁힌다 — 파일 전체를 훑으면 README 산문이 든 같은 골격 예시까지
# 더해진다(실제로 리뷰 중 그렇게 걸렸다: 83 vs 62). 골격을 산문에 쓰지 말라는 규약과 별개로,
# 가드 자신이 범위를 좁혀 둔다.
part_sum() {
    s=0
    for n in $(grep -F 'cases:' "$DISC_README" 2>/dev/null | head -1 |
               grep -oE 'Part [A-Z] [0-9]+' | sed 's/.* //'); do
        s=$((s + n))
    done
    echo "$s"
}
if part_on F; then
chk "F1b: 파트별 내역 합 == 총계 선언" "$(part_sum)" "$(declared_cases)"
fi

# (F4~F5) **`run.ps1`의 비-ASCII 0줄 규율을 기계가 문다**(M42 재작업 3 — 자체 발의).
# 규약과 이 하니스 README가 *"byte>127=0 규율이 유지된다"*고 적어 왔지만 **어느 케이스도, CI의 어느
# 잡도 그것을 물지 않았다**. 이번 라운드가 그 사실을 실측으로 만났다 — 재작업 중 ps1 주석에 한글이
# 한 줄 섞였는데 **138 케이스가 전부 초록**이었고 사람이 따로 세어서야 드러났다. 규율이 문서에만
# 있으면 그것은 규율이 아니라 희망이다.
# **F4가 positive-control**이다: 발견이 0개면 F5가 `0==0`으로 공허 통과한다.
# 탐색 기준은 **$ROOT**다 — 호출자의 cwd에 기대면 다른 디렉터리에서 부를 때 엉뚱한 트리를 훑고,
# 깨진 사본을 두고도 통과할 수 있다(배선 중 실측: ps1 사본이 cwd 기준이라 깨진 트리에서 초록이었다).
# **발견 명세(두 사본의 단일 기준)**: `<dir>` 아래 **모든 깊이**의 **정규 파일** 중 이름이 `.ps1`로
# 끝나는 것 — ⑴ 확장자 비교는 **대소문자 구분**(`.PS1`은 발견하지 않는다) ⑵ **숨김 항목도 본다**
# ⑶ 디렉터리는 세지 않는다. 이 셋이 갈리면 같은 트리에서 두 셸의 판정이 갈린다(M42 리뷰 차단 1의
# 실측: 비-ASCII가 든 `extra.PS1`에서 sh 145/0 초록 ↔ 양 PowerShell 144/1, 숨김 `hid.ps1`에서
# sh 144/1 ↔ 양 PowerShell 145/0 초록). 규약 `docs/conventions.md`의 "실행 환경 축"이 **경로 API
# 의미론은 축이 아니라 코드 결함**이라고 이미 적어 뒀다 — 두 극이 있는 것이 아니라 한쪽이 틀렸다.
# **sh가 정본이다**: `find`는 셋 다 그대로 하므로 여기서는 `-type f`만 명시하고(디렉터리 제외 — 없으면
# `foo.ps1` 디렉터리가 발견 수에 들어가 F6이 sh에서만 붉어진다), ps1 사본이 `-Force`와 ordinal
# `EndsWith`로 이 명세에 맞춘다. **F7이 그 명세를 픽스처로 문다.**
# 디렉터리를 인자로 받는 것은 F7이 **샌드박스 픽스처**에 같은 함수를 걸기 위해서다 — 검사 대상과
# 다른 코드로 픽스처를 재면 그 픽스처는 아무것도 증명하지 못한다.
ps1_files_in() { find "$1" -type f -name '*.ps1' 2>/dev/null; }
ps1_files() { ps1_files_in "$ROOT/tests"; }
# **단어 분할로 소비하지 않는다** — 앞 판본은 `for _f in $(ps1_files)`였고, 레포 경로에 **공백이 하나만
# 있어도** 목록이 조각나 모든 경로가 열리지 않았다. 그러면 파일마다 `grep -c`가 0을 내 **F5가 절대
# 실패할 수 없게** 된다(M42 리뷰 차단 2의 실측: 공백 든 경로에서 sh 140/0 ↔ ps1 139/1). 목록은 파일로
# 받아 `while IFS= read -r`로 한 줄씩 소비한다(파이프로 받으면 서브셸이라 카운터가 살아 나오지 않는다).
# **무는 넓이는 선언된 규율 그대로 `byte>127`이다.** 앞 판본은 `[^ -~<TAB>]`(인쇄 가능 ASCII와 탭의
# 여집합)이라 **폼피드·수직탭 같은 제어 바이트까지** 물었고, ps1 사본은 `-gt 127`만 보므로 같은 트리에서
# 판정이 갈렸다(M42 리뷰 권장 1의 실측: `.ps1`에 폼피드 한 글자 → sh 144/1 ↔ pwsh 7·PS 5.1 145/0).
# 규약과 이 하니스가 적어 온 규율은 **`byte>127=0`**이므로 **넓은 쪽(sh)을 선언에 맞춰 좁힌다** — 8진
# 이스케이프로 바이트 범위를 만들고 `LC_ALL=C`로 고정해 `SEP_RE`와 같은 idiom을 쓴다(dash의 `printf`가
# `\xHH`를 해석하지 않는다는 M37 실측 때문에 8진이다). CR은 이 범위에 없으므로 앞의 `tr -d '\r'`는
# 줄 수에 영향을 주지 않고, ps1이 바이트 13을 건너뛰는 것과 같은 자리에 남는다.
NONASCII_RE=$(printf '[\200-\377]')
nonascii_scan() { # → "<검사한 파일 수> <비-ASCII 줄 수>"
    _list="$SBX/ps1files.txt"
    ps1_files > "$_list"
    _n=0; _c=0
    while IFS= read -r _f; do
        [ -n "$_f" ] && [ -f "$_f" ] || continue
        _n=$((_n + 1))
        _c=$((_c + $(tr -d '\r' < "$_f" | LC_ALL=C grep -c "$NONASCII_RE" 2>/dev/null)))
    done < "$_list"
    echo "$_n $_c"
}
if part_on F; then
SCAN=$(nonascii_scan)
NPS1_FOUND=$(ps1_files | grep -c .)
NPS1_CHECKED=${SCAN% *}
NPS1_BAD=${SCAN#* }
chk "F4: ps1 러너 발견 positive-control(>0)" "$([ "$NPS1_FOUND" -gt 0 ] && echo ok || echo no)" "ok"
chk "F5: tests/**/*.ps1 비-ASCII 0줄"        "$NPS1_BAD"     "0"
# (F6) **발견과 소비를 대조한다** — F4는 *"발견이 0"* 만 보는데, 실제로 일어난 실패는 *"발견은 다 하고
# 소비에서 전부 흘림"* 이었다. positive-control이 **보지 못한 축**이라 통제를 그 축까지 넓힌다.
# **양 사본이 같은 이유로 붉어질 수 있어야 통제다** — 소비는 **직렬화한 목록을 되읽어** 돌고 이 비교는
# **새 열거**와 맞춘다. 같은 열거를 두 번 해서 서로 비교하면 그것은 통제가 아니라 항등식이라 **어떤
# 입력에서도 붉어지지 않는다**(M42 리뷰 권장 3: ps1 사본이 그 상태였다). 목록 왕복에서 한 줄이라도
# 잃으면 — 인용 없는 단어 분할, 인코딩 손실, 잘린 목록 — 두 수가 갈라진다.
chk "F6: 검사한 파일 수 == 발견한 파일 수"    "$NPS1_CHECKED" "$NPS1_FOUND"
fi
# (F7) **발견 명세를 픽스처로 문다.** 위 세 축(대소문자·숨김·디렉터리)은 `tests/` 실물에는 그런 파일이
# 없어 **실물만 훑어서는 영원히 초록**이다. 샌드박스에 넷을 만들어 `ps1_files_in`을 그대로 걸고 **정렬된
# basename 목록**을 대조한다 — 수가 아니라 **이름**을 보는 이유는, 숨김을 빠뜨리고(-1) 대문자를
# 더하면(+1) 개수가 상쇄돼 초록이 되기 때문이다(실제로 그렇게 갈릴 수 있는 조합이다).
ps1_disc_fixture() { # <dir> 만들고 그 경로를 출력
    _d="$SBX/ps1disc"
    rm -rf "$_d" 2>/dev/null
    mkdir -p "$_d/sub"
    : > "$_d/a.ps1"          # 평범한 것 — 발견된다
    : > "$_d/b.PS1"          # 대문자 확장자 — 발견되지 않는다(ordinal 비교)
    : > "$_d/.hidden.ps1"    # 숨김(POSIX는 점 이름, Windows는 숨김 속성) — 발견된다
    : > "$_d/sub/c.ps1"      # 하위 깊이 — 발견된다
    mkdir -p "$_d/dir.ps1"   # 이름만 .ps1인 디렉터리 — 발견되지 않는다
    echo "$_d"
}
# basename 집합을 한 줄로 접는 자리는 **한 곳뿐**이다 — `F7`(`ps1_files_in`)과 `J6`(`runner_src_files_in`)이
# 같은 접기를 불러 두 번째 선언처를 만들지 않는다. 정렬은 `LC_ALL=C`로 고정한다(ps1 사본은 ordinal).
basename_join() { # (stdin: 경로 목록) → 정렬된 basename을 |로 이어 붙인 한 줄
    sed 's|.*/||' | LC_ALL=C sort |
        awk '{ s = (NR == 1 ? $0 : s "|" $0) } END { print s }'
}
disc_spec() { ps1_files_in "$1" | basename_join; }   # <dir> → 정렬된 basename 한 줄
if part_on F; then
DISC_FIX=$(ps1_disc_fixture)
chk "F7: 발견 명세 — 대소문자 구분·숨김 포함·디렉터리 제외" \
    "$(disc_spec "$DISC_FIX")" ".hidden.ps1|a.ps1|c.ps1"
fi
# (F8) **`F7`의 숨김 축 전제조건을 문다**(M43 — M42 리뷰 반환 권장 1의 처분). `F7`이 "숨김도 본다"를
# 증명하려면 픽스처의 그 파일이 **실제로 숨김이어야** 한다. ps1 사본은 속성 설정을 `try/catch`로
# 감싸는데, 그 단계가 조용히 실패하면 **숨김 축이 통째로 사라지고 러너는 아무 말도 하지 않는다**
# (M42 리뷰 실측: 속성 단계만 무력화하면 `-Force` 결함을 그대로 두고도 양 PowerShell이 146/0 초록).
# 전제조건을 케이스로 승격한다 — **숨김을 포함하지 않는 열거에서 그 파일이 보이지 않아야 한다.**
# 이 판별은 두 플랫폼에서 **각자의 숨김 표기로 성립**한다: POSIX는 점 이름(글로브가 매치하지 않는다),
# Windows는 숨김 속성(`-Force` 없는 열거가 건너뛴다). sh 사본에서 이 케이스가 무는 것은 **점 이름
# 규약**이고(그 셸엔 속성 개념이 없다), ps1 사본에서 무는 것은 **속성 설정의 성공 여부**다 —
# 같은 불변의 양쪽 표현이라 케이스 집합의 동형이 유지된다.
disc_visible_count() { # <dir> → 숨김 미포함·최상위·정규 파일 중 `.ps1`로 끝나는 것의 수
    _n=0
    for _p in "$1"/*.ps1; do
        [ -f "$_p" ] || continue   # `dir.ps1`(디렉터리)을 제외 — ps1의 `-File`과 같은 넓이
        _n=$((_n + 1))
    done
    echo "$_n"
}
if part_on F; then
chk "F8: 숨김 픽스처가 숨김 미포함 열거에서 감춰진다(F7 전제조건)" "$(disc_visible_count "$DISC_FIX")" "1"

# (F9~F12 · M45) **로케일 고정 규율** — F5(비-ASCII 0줄)와 같은 층위다: 문서가 아니라 **러너 소스**의
# 규율을 문다. 네 사이클 연속 같은 부류가 사람 손에 잡혔다 — M41(`Sort-Object`·`StartsWith` 6곳) ·
# M42(세 표면 전수 감사 + `tests/lib/discover.sh`의 누락) · M44 리뷰 이슈 4(`sort -u`의 누락, 구현이
# 놓치고 리뷰가 잡았다). 이 부류는 **두 셸의 의미를 갈라 BSD에서만 터진 전례가 둘**이다.
#   무는 것(명세): ⑴ `.sh` 쪽은 **명령 위치**의 `sort`·`uniq`만 — 줄 선두·파이프·`;`·`&`·`(`·`$(` 뒤에
#         오는 것. 함수 이름 부분 문자열(`toposort`)과 주석은 대상이 아니다(M45-T01 실측: 원시 46줄 →
#         명령 위치 22 사이트). ⑵ `.ps1` 쪽은 **인자 없는 `Sort-Object`** 만 — 키를 지정한
#         `Sort-Object { … }`는 문화권과 무관하고(실측 2건), 광범위 API(`-eq`·`-match`·`IndexOf`)는
#         오탐이 폭발해 대상 밖이다.
#   고정으로 보는 형태: `.sh`는 같은 줄의 `LC_ALL=C`, `.ps1`은 ordinal 전용 헬퍼 경유.
#   예외는 **선언**한다: 같은 줄에 `locale-exempt: <사유>` 주석. 살아 있는 예외는 셋이고 사유가 둘이다 —
#         `version-sort`(`sort -V` 두 곳 · M40이 *"macOS 레그 통과가 BSD 지원의 실측"*이라 유지 결정) ·
#         `diagnostic-only`(진단 출력의 표시 순서라 판정에 쓰이지 않는다 · M41 후속 11이 같은 사실을
#         이미 기록했다).
#   경계(규약이 함께 적는다): 판정은 **줄 단위**라 `LC_ALL=C sort … | uniq`처럼 **파이프 뒤 두 번째
#         명령의 개별 고정**은 묻지 않는다 · 변수 경유 호출·`eval`·다른 로케일 민감 도구(`join`·`comm`)는
#         대상 밖 · `.ps1`의 광범위 비교 API는 위 ⑵의 이유로 대상 밖이다.
LOCALE_EXEMPT_TOK='locale-exempt:'
# **판정은 줄 자체로 한다(M45 재작업 1)** — 첫 판본은 사이트를 `파일:줄번호:본문`으로 이어 붙인 뒤
# 콜론으로 다시 쪼갰고, **경로에 드라이브 콜론이 있는 ps1 사본에서 그 쪼개기가 어긋나** 주석 제외가
# 죽었다(리뷰 차단 1 — 같은 트리에서 bash는 스킵, pwsh는 오탐). 이제 **파일별 스캔 안에서 줄 자체를
# 보고** 판정하고 경로는 보고용으로만 앞에 붙인다 — 콜론 파싱이 사라져 그 부류가 구조적으로 닫힌다.
# **사이트의 종결 문자도 명세다(재작업 1)** — 명령 뒤에 공백·`)`·`;`·`|`·`#`가 오거나 줄이 끝나면
# 사이트다. 첫 판본은 공백·줄끝만 봐서 `$(cat x | sort)`·`| Sort-Object  # 주석` 형태를 **놓쳤다**
# (리뷰 차단 2의 실제 기전 — `Ordinal` 탈출구와 별개의 검출 누락이었다).
# 공백 집합도 양 사본을 **ASCII 공백·탭**으로 고정했다(sh `[[:blank:]]` @ `LC_ALL=C` ↔ ps1 `[ 	]`) —
# `[[:space:]]`와 `\s`는 무는 폭이 달라 그 자체가 두 셸 갈림의 씨앗이다(리뷰 반환 2).
LOCALE_SITE_RE_SH='(^|[|;&(]|\$\()[[:blank:]]*(LC_ALL=C[[:blank:]]+)?(sort|uniq)([[:blank:]);|#]|$)'   # locale-exempt: detector-pattern
LOCALE_SITE_RE_PS1='Sort-Object[[:blank:]]*(\||\)|#|$)'
fi
# **주석 줄 판정은 이 파일에 한 번만 둔다** — Part F(로케일 사이트) · Part J(변수 이름 경계) ·
# Part K(공통 통제 토큰)가 **같은 술어**를 쓴다. 셋이 각자 적으면 그 순간 선언처가 셋이 되고 한 곳만
# 고쳐도 나머지가 조용히 어긋난다(이 저장소가 반복해 데인 자리다).
# **`run.ps1` 사본은 아직 둘이다** — 그쪽 Part F는 자기 인라인 술어(`TrimStart().StartsWith('#')`)를
# 쓰고 Part J·K만 `IsCommentLine`을 쓴다. 폭도 다르다: .NET의 인자 없는 `TrimStart()`는 **모든
# 유니코드 공백**을 벗기고 이쪽과 `IsCommentLine`은 **ASCII 공백·탭뿐**이라, `.sh`에 U+00A0으로
# 시작하는 주석 줄이 있으면 Part F의 두 사본이 갈린다. 오늘 그런 줄은 0건이고 이 갈림은 M48 이전부터
# 있던 것이며, 이 파일이 그것을 고친 것은 아니다(M48 리뷰 라운드 1의 경계 기록).
# 술어: 줄의 첫 비-공백 문자(**ASCII 공백·탭만**)가 `#`이면 주석 줄이다. `LC_ALL=C`를 같은 줄에
# 걸어 `[[:blank:]]`를 space·tab 둘로 고정한다(ps1 사본의 ASCII 공백·탭 클래스와 같은 넓이).
# 줄 단위 술어(`is_comment_line`)와 파일 필터(`noncomment_lines`)는 **같은 `COMMENT_RE`에서 파생**한다 —
# Part K는 하니스 일곱 × 러너 둘을 훑으므로 줄마다 서브프로세스를 띄우는 형태를 쓸 수 없다.
COMMENT_RE='^[[:blank:]]*#'
is_comment_line() { printf '%s\n' "$1" | LC_ALL=C grep -qE "$COMMENT_RE"; }
noncomment_lines() { LC_ALL=C grep -vE "$COMMENT_RE" "$1" 2>/dev/null; }
locale_scan_in() { # <파일> <정규식> [report-only] → 미고정·미선언 줄("파일:줄번호:본문")
    [ -f "$1" ] || return 0
    LC_ALL=C grep -nE "$2" "$1" 2>/dev/null | while IFS= read -r _nl; do
        _lno=${_nl%%:*}
        _body=${_nl#*:}                                   # grep -n 의 첫 콜론까지만 — 경로가 섞이지 않는다
        case "$_body" in *"$LOCALE_EXEMPT_TOK"*) continue ;; esac                              # 예외 선언
        is_comment_line "$_body" && continue                                                    # 주석
        case "$_body" in *'LC_ALL=C '*) continue ;; esac                                        # .sh 의 고정 형태
        printf '%s:%s:%s\n' "$1" "$_lno" "$_body"
    done
}
locale_sites_in() { # <파일> <정규식> → 사이트 수 세기용(필터 없음). **항상 숫자를 낸다** —
    # 빈 문자열을 내면 호출부의 `$((N + $(...)))`가 산술 오류로 죽어 **결과 줄조차 못 낸다**(글롭이
    # 0개 매치하는 경우. M45 리뷰 2회차가 dash·bash에서 실측했다). 설계된 신호는 `F11`의 추출
    # positive-control이므로 러너는 살아서 그 케이스를 붉혀야 한다.
    [ -f "$1" ] || { echo 0; return 0; }
    LC_ALL=C grep -cE "$2" "$1" 2>/dev/null   # grep -c 는 미매치에도 `0`을 찍는다(중복 출력 금지)
}
# **`Ordinal` 탈출구를 없앴다(재작업 1 — 리뷰 차단 2)**: 첫 판본은 같은 줄에 `Ordinal` 문자열이 있으면
# 고정으로 봤는데, 문서는 *"ordinal 전용 헬퍼 경유"*라 적어 **구현이 문서보다 넓었다**(주석의 단어
# 하나로 미고정 정렬이 통과했다 — 실측). 인자 없는 `Sort-Object`에는 **고정 형태가 애초에 없다** —
# 헬퍼로 바꾸면 사이트가 아니게 되고, 남겨야 하면 **선언**한다. 그래서 탈출구는 `.sh`의 `LC_ALL=C` 하나다.
if part_on F; then
LOC_UNFIXED_SH=''; LOC_UNFIXED_PS1=''; NLOCSITE=0; NLOCPS1=0
for f in "$ROOT"/tests/*/run.sh "$ROOT"/tests/lib/*.sh; do
    LOC_UNFIXED_SH="$LOC_UNFIXED_SH$(locale_scan_in "$f" "$LOCALE_SITE_RE_SH")
"
    NLOCSITE=$((NLOCSITE + $(locale_sites_in "$f" "$LOCALE_SITE_RE_SH")))
done
for f in "$ROOT"/tests/*/run.ps1 "$ROOT"/tests/lib/*.ps1; do
    LOC_UNFIXED_PS1="$LOC_UNFIXED_PS1$(locale_scan_in "$f" "$LOCALE_SITE_RE_PS1")
"
    NLOCPS1=$((NLOCPS1 + $(locale_sites_in "$f" "$LOCALE_SITE_RE_PS1")))
done
NLOCUNFIXED=$(printf '%s
%s
' "$LOC_UNFIXED_SH" "$LOC_UNFIXED_PS1" | grep -c .)
[ "$NLOCUNFIXED" = "0" ] || printf '%s
%s
' "$LOC_UNFIXED_SH" "$LOC_UNFIXED_PS1" | grep . | sed 's/^/  -> locale not pinned and not declared: /'
chk "F9: 로케일 미고정·미선언 사이트 0건"          "$NLOCUNFIXED" "0"
chk "F10: sh 쪽 사이트 추출 positive-control(>0)"  "$([ "$NLOCSITE" -gt 0 ] && echo ok || echo no)" "ok"
# 계열별로 나눠 센다(재작업 1) — 합으로 세면 한쪽 추출이 망가져도 다른 계열 수가 남아 초록이었다(R5 실측).
chk "F11: ps1 쪽 사이트 추출 positive-control(>0)" "$([ "$NLOCPS1" -gt 0 ] && echo ok || echo no)" "ok"
# 픽스처 통제 둘 — 살아 있는 미고정이 0건이라 이것이 공허를 막는다. 계열마다 하나씩 둔다(재작업 1:
# 첫 판본은 sh 픽스처만 있어 ps1 검출기의 비공허성에 하니스 안 통제가 없었다).
printf 'x=$(cat a b | sort -u)\n' > "$SBX/locfx.sh"   # locale-exempt: fixture-string (검사가 자기 픽스처 문자열을 문다)
chk "F12: 통제 — 주입한 미고정 sh 사이트를 잡는다" "$(locale_scan_in "$SBX/locfx.sh" "$LOCALE_SITE_RE_SH" | grep -c .)" "1"
printf '$s = @(1,2) | Sort-Object\n' > "$SBX/locfx.ps1"   # locale-exempt: fixture-string
chk "F13: 통제 — 주입한 미고정 ps1 사이트를 잡는다" "$(locale_scan_in "$SBX/locfx.ps1" "$LOCALE_SITE_RE_PS1" | grep -c .)" "1"
# (F17 — M49-T02) 주석 술어의 **폭**을 픽스처로 고정한다. 이 사본은 `COMMENT_RE`(`[[:blank:]]` @
# `LC_ALL=C` = ASCII 공백·탭) 하나뿐이었으나 ps1 사본은 Part F에서 인자 없는 `TrimStart()`를 썼고,
# .NET의 그것은 **모든 유니코드 공백**(U+00A0·U+3000 …)을 벗긴다. 그래서 `.sh` 소스에 U+00A0으로
# 시작하는 주석 줄이 있으면 **두 사본이 갈렸다**(M48 리뷰 이슈 2의 실측 — 그때는 살아 있는 입력이
# 0건이라 어느 케이스도 붉지 않았다). 폭이 좁은 쪽이 옳다 — POSIX 셸에서 `#` 앞에 공백·탭이 아닌
# 바이트가 있으면 그 `#`은 주석 시작이 아니라 단어의 일부다. 픽스처 바이트는 양 사본이 같게 만든다
# (여기는 8진 `\302\240`, ps1 사본은 같은 코드포인트를 UTF-8로 인코딩 — F5의 ASCII-only 규율 때문에
# 그쪽은 리터럴을 쓸 수 없다).
printf '\302\240# x=$(cat a b | sort -u)\n' > "$SBX/locfx_nb.sh"   # locale-exempt: fixture-string
chk "F17: 통제 — 선행 U+00A0 뒤의 #은 주석이 아니다(폭 = ASCII 공백·탭)" "$(locale_scan_in "$SBX/locfx_nb.sh" "$LOCALE_SITE_RE_SH" | grep -c .)" "1"

# (F1) 마지막 케이스 — 자기 README 선언(`cases: N`)과 실제 케이스 수(누계 + 이 케이스) 대조.
# === F14~F16 (M46) — 진입점 문서 줄 수 상한 =============================
# 규약이 `CLAUDE.md`에 줄 수 상한을 적으면서 *"기계가 묻지 않는다"* 고 함께 적고 있었다. M46-T05가
# 닫을 수 있음을 실측했다 — ⑴ 상한 값의 선언처를 규약 한 곳으로 모으고(그 전엔 project-context에도
# 있어 선언 줄 유일성 위반이었다) ⑵ 줄 수 세기를 두 러너 **동형**으로 고정했다.
# **세는 방법이 판정을 가른다**: `wc -l`은 개행 **개수**라 마지막 줄에 개행이 없으면 1 적게 세지만
# `grep -c ""`는 ps1의 `ReadAllLines`와 같은 수를 낸다(실측: 개행 없는 3줄 파일에서 wc=2 · 나머지 둘=3).
# 그래서 상한 판정에는 `grep -c ""`만 쓴다.
ENTRY_DOC="$ROOT/CLAUDE.md"
# 추출 실패 시 **0으로 고정**한다 — 빈 값이면 아래 산술 비교가 sh에서 에러가 되어 ps1(정수 0)과
# 결과가 갈린다. 실측: 선언 줄을 지우면 sh 169/3 · pwsh 170/2로 갈렸고, 0 고정 후 양쪽 170/2다.
ENTRY_CAP=$(LC_ALL=C grep -E '^- \*\*상한\*\*: \*\*[0-9]+줄\*\*' "$CONV" | LC_ALL=C sed -E 's/.*\*\*([0-9]+)줄\*\*.*/\1/' | head -1)
[ -n "$ENTRY_CAP" ] || ENTRY_CAP=0
ENTRY_CAP_DECLS=$(LC_ALL=C grep -cE '^- \*\*상한\*\*: \*\*[0-9]+줄\*\*' "$CONV")
fi
# **판정은 함수 하나에만 있다** — F15(실물)와 F16(픽스처)이 **같은 함수**를 부른다. 재작업 1이 고친
# 자리가 여기다: 첫 판본은 F16이 비교를 인라인으로 재구현해 F15의 판정을 한 번도 호출하지 않았고,
# 그래서 **F15의 판정식을 통째로 무력화해도 양 사본이 172/0 초록**이었다(리뷰 A1 실측 — 동어반복
# 케이스). 이제 판정이 망가지면 픽스처가 `over`를 잃어 F16이 붉어진다.
entry_cap_verdict() { # <파일> <상한> → ok | over(n/cap) | nocap | nofile
    [ -n "$2" ] && [ "$2" -gt 0 ] || { echo nocap; return; }
    [ -f "$1" ] || { echo nofile; return; }
    _n=$(grep -c "" "$1")
    if [ "$_n" -le "$2" ]; then echo ok; else echo "over($_n/$2)"; fi
}
# (F14) 추출 positive-control + 선언 유일성 — 정규식이나 규약 문구가 망가지면 상한이 빈 값이 되어
# 아래 판정이 공허해진다(체크리스트 ⑴⑵ — G8b0·I7~I9와 동형).
if part_on F; then
chk "F14: 상한 선언 추출 positive-control(유일)" "$ENTRY_CAP_DECLS" "1"
# (F15) 실제 판정 — 진입점 문서가 상한 이하인가.
chk "F15: CLAUDE.md 줄 수 <= 규약의 상한" "$(entry_cap_verdict "$ENTRY_DOC" "$ENTRY_CAP")" "ok"
# (F16) 픽스처 통제 — **같은 판정 함수**에 상한 초과 픽스처를 먹여 `over`가 나오는지 본다
# (F12·F13이 `locale_scan_in`을 픽스처에 돌리는 형태와 동형). 이 케이스가 붉으면 판정 자체가 죽은 것이다.
: > "$SBX/entryover.md"
_i=0; while [ "$_i" -le "$ENTRY_CAP" ]; do echo "x" >> "$SBX/entryover.md"; _i=$((_i + 1)); done
case "$(entry_cap_verdict "$SBX/entryover.md" "$ENTRY_CAP")" in
    over*) ENTRY_FIX_R=caught ;;
    *)     ENTRY_FIX_R=missed ;;
esac
chk "F16: 통제 — 판정 함수가 상한 초과 픽스처를 잡는다" "$ENTRY_FIX_R" "caught"
fi

# === F18~F20 (M64-T03) — 파트 선택 인자의 자기 정합 ======================
# 러너가 **자기 인자에 대해 하는 서술**을 집행한다(F1·F1b와 같은 층위 — 그 둘은 케이스 수, 이쪽은
# 파트 표지다). 셋 다 러너가 실제로 쓰는 **같은 함수**를 부른다 — `F16`의 교훈(픽스처 통제는
# 「픽스처가 조건을 만족하는가」가 아니라 「실제 판정이 픽스처를 잡는가」를 물어야 한다)을 따른다.
# 표지 명단을 README 선언 줄에서 뽑는다 — 합산 범위를 **그 한 줄**로 좁히는 것은 `part_sum`과 같다.
part_labels_declared() {
    grep -F 'cases:' "$DISC_README" 2>/dev/null | head -1 |
        grep -oE 'Part [A-Z] [0-9]+' | sed 's/^Part //; s/ .*//' | tr '\n' ' ' | sed 's/ $//'
}
# (F18) 러너의 표지 명단 == README 내역이 여는 파트 — 추출이 0건이면 빈 문자열이 되어 **붉는다**
# (선언을 통째로 지워도 초록이 되는 경로를 닫는다).
if part_on F; then
chk "F18: README 내역의 파트 표지 == 러너의 표지 명단" "$(part_labels_declared)" "$PART_LABELS"
# (F19) 통제 — 없는 표지는 거부된다. `ZZ`는 **한 글자 표지가 될 수 없는** 토큰이라 파트가 늘어도
# 이 통제가 낡지 않는다.
chk "F19: 통제 — 없는 파트 표지는 거부된다" "$(part_known A),$(part_known ZZ)" "yes,no"
# (F20) 부분 실행의 결과 줄 접두가 전수의 접두와 **다르다**. 같으면 부분 총계를 그대로 보고서에
# 옮겨도 사람이 못 알아채므로, 이 다름이 그 경로를 닫는 기계다.
_rp_full=$(result_prefix '')
_rp_part=$(result_prefix ZZ)
if [ -z "$_rp_full" ] || [ -z "$_rp_part" ]; then F20R=empty
else
    case "$_rp_part" in
        "$_rp_full"*) F20R=same ;;
        *)            F20R=distinct ;;
    esac
fi
chk "F20: 부분 결과 줄 접두가 전수 결과 줄 접두와 다르다" "$F20R" "distinct"
fi


# === Part J (M48) — 러너 소스의 변수 이름 경계 ==========================
# `$이름` 바로 뒤에 다중바이트 문자가 오면 **셸 구현마다 이름 경계 판정이 갈린다**. 이 기계의
# bash 5.2·dash는 이름을 거기서 끊지만, macOS가 `sh`로 쓰는 **bash 3.2는 뒤따르는 바이트를 이름에
# 포함**해 `set -u`가 `unbound variable`로 죽인다 — v2.19.1 릴리즈 PR에서 `posix (macos-latest)`
# 하나만 붉었고 **로컬 네 환경도 우분투 CI도 전부 초록**이었다(실측 수치의 단일 출처는
# `docs/reports/debug-2.md`다 — 여기로 옮겨 적지 않는다). 로컬에서 영원히 초록인 부류라 **사람의
# 눈이 아니라 기계가** 물어야 한다. 고치는 형태는 하나다 — 중괄호로 이름 경계를 명시한다.
#
# **무는 대상 집합의 명세(두 사본의 단일 기준)**: `$ROOT/tests`와 `$ROOT/hooks` 아래 **모든 깊이**의
# **정규 파일** 중 이름이 `.sh` 또는 `.ps1`로 끝나는 것 — ⑴ 확장자 비교는 **대소문자 구분**
# (`.SH`·`.PS1`은 발견하지 않는다) ⑵ **숨김 항목도 본다** ⑶ 디렉터리는 세지 않는다. `ps1_files_in`이
# 이미 쓰는 명세와 **같은 형태**이고 확장자만 둘로 넓혔다 — 명세를 새로 만들지 않고
# **같은 명세를 재사용**한다. 다만 `F7`이 물고 있는 것은 `ps1_files_in`이지 **이 파트가 쓰는
# `runner_src_files_in`이 아니다** — 그 틈을 `J6`이 자기 픽스처로 직접 문다(M48 재작업 1).
#
# **판정**: ⑴ 줄의 첫 비-공백 문자(**ASCII 공백·탭만**)가 `#`이면 **주석 줄이라 판정하지 않는다** —
# M48-T01 실측에서 원시 매치 다섯이 **전부** 주석이었고, 그중 하나는 **이 규율 자체를 설명하는 주석**
# 이라 제외가 없으면 규율을 적은 자리가 규율 위반으로 붉어진다. ⑵ 나머지 줄에서 `$` + 이름 첫 글자
# `[A-Za-z_]` + 이름 나머지 `[A-Za-z0-9_]*` 직후에 **byte>127**이 오면 위반이다. ⑶ 중괄호 형태는
# `$` 다음이 `{`라 **구조적으로** 매치되지 않는다 — 이것이 이 판정의 핵심 성질이고 `J5`가 문다.
# CR(byte 13)은 무시한다(`F5`의 `tr -d` 자리·ps1이 바이트 13을 건너뛰는 자리와 같다).
#
# **경계**(규약이 같은 문장으로 적는다): 이 판정은 **정적**이라 변수 경유·`eval`로 조립한 명령은 보지
# 못한다. 주석 줄은 실행되지 않으므로 결함이 아니고 판정에서 제외한다.
#
# **판정은 함수 하나에만 둔다** — 실물(`J3`)과 픽스처 통제(`J4`·`J5`)가 **같은 함수**를 부른다.
# M46의 `F16`이 판정을 인라인으로 재구현해 동어반복이 됐던 자리라 규약이 이 형태를 요구한다.
#
# 바이트 범위는 `NONASCII_RE`(`F5`가 쓰는 8진 이스케이프 클래스)를 **그대로 재사용**한다 — 두 곳에서
# 따로 만들면 그 순간 두 번째 선언처가 생긴다. `LC_ALL=C`를 같은 줄에 걸어 바이트 비교로 고정한다.
runner_src_files_in() { find "$1" -type f \( -name '*.sh' -o -name '*.ps1' \) 2>/dev/null; }
# **스캔 루트의 단일 선언처**는 아래 한 줄이다. `J6`이 무는 것은 `runner_src_files_in`(디렉터리 하나의
# 발견 명세)이라 **어느 루트를 훑는가**는 그 케이스가 보지 못한다 — M48 리뷰 라운드 0이 실측한 구멍이
# 정확히 그 자리였고(루트에서 `hooks`를 빼도 초록), 라운드 1의 `J6`도 그 축은 닫지 못했다. 그래서
# `J1`을 **루트마다** 묻는 형태로 세운다 — 루트를 지우면 자리 수가 줄어 기댓값과 어긋난다.
VARBOUND_ROOTS='tests hooks'
runner_src_files() { for _vbr in $VARBOUND_ROOTS; do runner_src_files_in "$ROOT/$_vbr"; done; }
varbound_root_probe() { # → 루트마다 "ok"/"no"를 `/`로 이어 붙인 한 줄
    _vbo=''
    for _vbr in $VARBOUND_ROOTS; do
        if [ "$(runner_src_files_in "$ROOT/$_vbr" | grep -c .)" -gt 0 ]; then _vbs=ok; else _vbs=no; fi
        _vbo="${_vbo:+$_vbo/}$_vbs"
    done
    printf '%s
' "$_vbo"
}
VARBOUND_RE='\$[A-Za-z_][A-Za-z0-9_]*'"$NONASCII_RE"
varbound_scan_in() { # <파일> → 위반 줄("파일:줄번호:본문"). 주석 줄은 제외한다.
    [ -f "$1" ] || return 0
    tr -d '\r' < "$1" | LC_ALL=C grep -nE "$VARBOUND_RE" 2>/dev/null | while IFS= read -r _nl; do
        _lno=${_nl%%:*}
        _body=${_nl#*:}                                # grep -n 의 첫 콜론까지만 — 경로가 섞이지 않는다
        is_comment_line "$_body" && continue
        printf '%s:%s:%s\n' "$1" "$_lno" "$_body"
    done
}
varbound_probe() { # <파일> → "<원시 매치 줄 수>/<위반 줄 수>" — 주석 제외 **전후**를 함께 낸다
    printf '%s/%s\n' "$(tr -d '\r' < "$1" | LC_ALL=C grep -cE "$VARBOUND_RE" 2>/dev/null)" \
                     "$(varbound_scan_in "$1" | grep -c .)"
}
# **목록은 파일로 직렬화해 되읽는다** — 단어 분할로 소비하면 경로에 공백이 하나만 있어도 목록이 조각나
# 모든 경로가 열리지 않고, 그러면 위반이 있어도 `J3`이 절대 실패할 수 없다(`F6`이 같은 실패를 겪었다).
varbound_scan() { # → "<검사한 파일 수> <위반 줄 수>"
    _list="$SBX/runnersrc.txt"
    runner_src_files > "$_list"
    _n=0; _c=0
    while IFS= read -r _f; do
        [ -n "$_f" ] && [ -f "$_f" ] || continue
        _n=$((_n + 1))
        _c=$((_c + $(varbound_scan_in "$_f" | grep -c .)))
    done < "$_list"
    echo "$_n $_c"
}
if part_on J; then
VBSCAN=$(varbound_scan)
NVBFOUND=$(runner_src_files | grep -c .)
NVBCHECKED=${VBSCAN% *}
NVBBAD=${VBSCAN#* }
# 실패하면 **어느 파일 몇 줄인지 이름을 찍는다**(개수만 보면 원인을 찾는 데 다시 사람이 든다).
if [ "$NVBBAD" != "0" ]; then
    while IFS= read -r _f; do varbound_scan_in "$_f"; done < "$SBX/runnersrc.txt" |
        sed 's|^|  -> variable name boundary, brace it: |'
fi
# (J1) 발견 positive-control — 발견이 0이면 아래가 `0 == 0`으로 공허 통과한다(체크리스트 ⑴).
chk "J1: 러너 소스 발견 positive-control(루트마다 >0)" "$(varbound_root_probe)" "ok/ok"
# (J2) 발견 ↔ 소비 대조 — `J1`이 보지 못하는 축이다(*"발견은 다 하고 소비에서 전부 흘림"*).
# 소비는 **직렬화한 목록을 되읽어** 돌고 이 비교는 **새 열거**와 맞춘다 — 같은 열거를 두 번 해서
# 자기와 비교하면 그것은 통제가 아니라 항등식이라 어떤 입력에서도 붉어지지 않는다(`F6`과 동형).
chk "J2: 스캔한 파일 수 == 발견한 파일 수" "$NVBCHECKED" "$NVBFOUND"
# (J3) 금지형 본 검사 — 살아 있는 위반은 **0건**이다(M48-T01 실측). 그래서 아래 픽스처 둘이 공허를 막는다.
chk "J3: 러너 소스의 변수 이름 경계 위반 0건" "$NVBBAD" "0"
# (J4·J5) 픽스처 통제. **픽스처는 샌드박스에서 8진 이스케이프로 조립한다** — 위반 문자열을 이 소스에
# 리터럴로 쓰면 검사가 **자기 자신을 문다**(M45의 `F12`·`F13`이 정확히 그 자리를 밟았고 그때는
# `locale-exempt:` 선언으로 처분했다. 여기서는 선언 없이 **소스에 그 바이트를 두지 않는 것**으로 닫는다 —
# 아래 리터럴에서 이름 뒤에 오는 것은 백슬래시라 판정식이 매치하지 않는다). 픽스처를 `tests/`·`hooks/`
# 아래에 두면 발견 집합에 섞여 `J3`이 붉어지므로 반드시 샌드박스 안에 둔다.
# 심는 바이트는 U+AC74(UTF-8 `EA B1 B4`)이고 양 사본이 **같은 바이트**를 쓴다.
printf 'echo "x $NANN\352\261\264 y"\n' > "$SBX/varfx1.sh"
chk "J4: 통제 — 심은 경계 위반을 잡는다" "$(varbound_scan_in "$SBX/varfx1.sh" | grep -c .)" "1"
# (J5) 두 축을 한 케이스로 문다 — 기댓값 `1/0`의 앞자리는 **원시 매치**, 뒷자리는 **판정 결과**다.
# ⑴ 중괄호 줄이 구조적으로 매치되지 않으므로 원시 매치는 주석 줄 하나뿐이고(앞자리가 2가 되면
# 중괄호 성질이 깨진 것이다) ⑵ 그 하나가 주석 제외로 사라진다(뒷자리가 1이 되면 주석 제외가 죽은
# 것이다). 뒷자리만 보면 스캔이 통째로 죽어도 `0`이라 초록이므로 **앞자리가 그 공허를 막는다**.
printf 'echo "x ${NANN}\352\261\264 y"\n#  note $NANN\352\261\264 tail\n' > "$SBX/varfx0.sh"
chk "J5: 통제 — 중괄호 형태와 주석 줄은 잡지 않는다" "$(varbound_probe "$SBX/varfx0.sh")" "1/0"
fi
# (J6) **발견 명세를 픽스처로 문다**(M48 재작업 1 — 리뷰 권장 3). `J2`는 발견과 소비를 **같은 함수**로
# 재므로 명세 자체를 무는 것이 하나도 없었다. **이 케이스가 무는 것은 디렉터리 하나의 명세이지
# 「어느 루트를 훑는가」가 아니다** — 라운드 0이 실측한 그 구멍(루트에서 `hooks/`를 빼면 24 → 22 파일로
# 줄 뿐 양 사본 초록)은 이 케이스가 아니라 **`J1`을 루트마다 묻게 바꿔** 닫았다.
# `F7`이 `ps1_files_in`에 하는 것과 **같은 형태**로 `runner_src_files_in`을
# 샌드박스 트리에 걸고 **정렬된 basename**을 대조한다 — 수가 아니라 **이름**을 보는 이유는 숨김을
# 빠뜨리고(-1) 대문자를 더하면(+1) 개수가 상쇄돼 초록이 되기 때문이다.
runner_disc_fixture() { # <dir> 만들고 그 경로를 출력
    _d="$SBX/runnerdisc"
    rm -rf "$_d" 2>/dev/null
    mkdir -p "$_d/sub"
    : > "$_d/a.sh"           # 평범한 것 — 발견된다
    : > "$_d/b.SH"           # 대문자 확장자 — 발견되지 않는다(대소문자 구분)
    : > "$_d/c.PS1"          # 대문자 확장자 — 발견되지 않는다
    : > "$_d/.hidden.ps1"    # 숨김(POSIX는 점 이름, Windows는 숨김 속성) — 발견된다
    : > "$_d/sub/d.ps1"      # 하위 깊이 — 발견된다
    mkdir -p "$_d/dir.ps1" "$_d/dir.sh"   # 이름만 확장자인 디렉터리 — 발견되지 않는다
    echo "$_d"
}
if part_on J; then
chk "J6: 통제 — 발견 명세를 픽스처로 문다(대소문자·숨김·디렉터리)" \
    "$(runner_src_files_in "$(runner_disc_fixture)" | basename_join)" ".hidden.ps1|a.sh|d.ps1"
fi

# === Part K (M48) — 하니스 공통 통제 보유 대조 ==========================
# **기존 하니스가 공통으로 가진 통제를 새 하니스가 빠뜨린다** — M47 사이클의 반환 셋이 전부 이 부류였고
# 그 대조를 지금까지 **사람이 매번** 했다. 단일 원본은 `docs/conventions.md`의 "새 하니스가 갖출 공통 통제 (목록 대조 — 기계가 문다)" 절이며, 이 파트는 그 절의 선언 블록을 **읽기만** 한다.
#
# **선언 추출 명세**: 줄 선두가 `<!-- harness-control: `이고 줄 끝이 ` -->`인 줄. 필드 구분자는
# ` :: `(공백·콜론콜론·공백)이고 순서는 <이름> · <sh 토큰> · <ps1 토큰> · <면제 쉼표목록>이다.
# **토큰은 고정 문자열로 대조한다**(정규식이 아니다 — 값에 `$`·`{`·`'`가 들어 있어 정규식으로 읽으면
# 뜻이 달라진다). `-`는 *그 셸에는 요구하지 않음*, `none`은 *면제 없음*이다. 선언 줄은 **네 필드를 다
# 갖고 어느 필드도 비어 있지 않아야** 한다(`K2`의 뒷자리) — 빈 넷째 필드는 *면제 없음*과
# *적는 것을 잊었다*를 구별하지 못해 규약의 *"빈 칸으로 두지 않는다"* 가 무집행이 된다.
#
# **토큰 대조는 주석 줄이 아닌 줄에서만 한다**(M48 재작업 1 — 리뷰 차단 2). 술어는 Part J와 **같다**
# (`COMMENT_RE`에서 파생한 `noncomment_lines`). 주석까지 세면 `cases:`가 **일곱 하니스 전부의 주석에**
# 있어(하니스마다 복붙된 *"첫 매치 고정 — sed의 선행 `.*`는 탐욕이라…"* 정형 문구) **실제 대조 코드를
# 잃어도 보유로 판정**됐고, 그래서 이 파트가 자기 존재 이유로 든 M47 1회차 반환을 정작 막지 못했다.
# 주석 제외 후에도 면제 집합은 **그대로**고 일곱 하니스가 전부 보유다 — 수치의 단일 출처는
# `docs/reports/M48-impl.md`다.
#
# **하니스 발견 명세**: `$ROOT/tests` **바로 아래(깊이 1)** 디렉터리 중 `run.sh`와 `run.ps1`을 **둘 다**
# 가진 것. 러너가 없는 디렉터리(`tests/lib`)는 하니스가 아니라 제외된다. 이름 비교·정렬은 `LC_ALL=C`로
# 고정한다(ps1 사본은 ordinal 정렬로 같은 순서를 낸다). **하니스가 늘면 대상이 는다** — 목록을
# 하드코딩하지 않는 이유가 그것이다.
#
# **판정 형태를 규약 선언 읽기로 택한 이유**: 하니스끼리 교차 비교하면 **기준 하니스가 낡을 때 같이
# 낡고**, *"일곱 종 전부 빠뜨림"* 과 *"일곱 종 전부 보유"* 를 구별하지 못한다. 규약 선언 읽기는 대신
# **선언 줄 유일성**이 필요하며(`K2`) 그 선례가 `F14`·`I18`·`I19`다.
#
# **자기 참조**: `tests/discover` 자신도 대상 집합에 들어간다 — 네 통제를 전부 보유하므로 역설이 없고
# **자기 제외를 넣지 않는다**. 자기를 빼면 이 검사는 자기 자신에게만 공허해진다.
#
# **경계**(규약이 같은 문장으로 적는다): 이 검사가 무는 것은 **토큰의 존재**이지 그 통제가 **실제로
# 동작하는가**가 아니다. 토큰을 두고 도달하지 못하게 만들면 이 파트는 초록이다 — 그 층은
# `tests/mutation`과 규약이 요구하는 **케이스별 되돌림 실측**(사람)이 덮는다.
if part_on K; then
HC_DECL_RE='^<!-- harness-control: .* -->$'
# (M50) 선언 줄 추출을 **한 번만** 한다 — 이전에는 부르는 자리마다 규약 전체를 다시 훑었고,
# 그 자리 하나가 하니스마다 도는 루프 안에 있어 호출 수가 하니스 수에 비례했다. 값은 같다.
LC_ALL=C grep -E "$HC_DECL_RE" "$CONV" > "$SBX/hclines.txt" 2>/dev/null || :
fi
hc_lines() { cat "$SBX/hclines.txt"; }
hc_field() { # <선언 줄> <필드 번호> → 그 필드
    # (M50) 이전에는 `printf | sed | awk`로 세 프로세스를 썼고, 이 함수가 **하니스 x 선언 줄 x 필드
    # 넷**만큼 불려 Part K 비용의 주력이었다. 구분자가 **고정 문자열**(` :: `)이라 셸 파라미터
    # 확장으로 **프로세스 없이** 같은 값을 낸다. `awk -F' :: '`의 의미를 그대로 유지한다 —
    # 필드 번호가 실제 필드 수보다 크면 **빈 값**이고, 필드 값 안에 구분자가 들어 있으면 그 자리에서
    # 쪼개지는 것도 같다.
    _hf=${1#"<!-- harness-control: "}
    _hf=${_hf%" -->"}
    _hfn=$2
    while [ "$_hfn" -gt 1 ]; do
        case "$_hf" in
            *' :: '*) _hf=${_hf#* :: } ;;
            *) printf '
'; return 0 ;;                       # 필드 수보다 크다 → 빈 값
        esac
        _hfn=$((_hfn - 1))
    done
    case "$_hf" in *' :: '*) _hf=${_hf%% :: *} ;; esac
    # **줄바꿈을 붙인다.** 이전 판본은 `awk print`라 ORS가 따라붙었고, 이 함수를 **파이프로 흘려
    # 보내는 자리**(`NHCNAME`의 필드 1 수집)가 그것에 기대고 있다. 빼면 필드들이 한 줄로 붙어
    # `sort -u`가 1로 세고 `K2`가 조용히 어긋난다 — M50의 판정 지문 대조가 잡은 회귀다.
    printf '%s\n' "$_hf"
}
harness_dirs_in() { # <디렉터리> → run.sh·run.ps1을 둘 다 가진 깊이 1 디렉터리(정렬)
    for _d in "$1"/*; do
        [ -d "$_d" ] || continue
        [ -f "$_d/run.sh" ] && [ -f "$_d/run.ps1" ] || continue
        printf '%s\n' "$_d"
    done | LC_ALL=C sort
}
# **판정 함수는 하니스 목록을 인자로 받는다** — 실물(`K4`)과 픽스처(`K5`)에 **같은 코드**를 걸기
# 위해서다(`F7`의 `ps1_files_in`·`F16`의 `entry_cap_verdict`와 같은 형태). 픽스처를 검사 대상과 다른
# 코드로 재면 그 픽스처는 아무것도 증명하지 못한다.
hc_missing() { # <하니스 목록 파일> → 미보유 조합("하니스:셸:통제")
    # (M50) 이전에는 **선언 줄마다** 주석 제외 사본을 다시 만들어(하니스 x 선언 수 x 셸) 프로세스를
    # 썼다. 사본은 선언과 무관하므로 **하니스마다 한 번**이면 된다. 선언 줄도 파일에서 직접 읽어
    # `hc_lines`를 하니스마다 다시 돌리지 않는다. **판정·출력·면제 규칙은 그대로다.**
    while IFS= read -r _hd; do
        [ -n "$_hd" ] || continue
        _hn=${_hd##*/}
        noncomment_lines "$_hd/run.sh"  > "$SBX/hcnc-sh.txt"
        noncomment_lines "$_hd/run.ps1" > "$SBX/hcnc-ps1.txt"
        while IFS= read -r _l; do
            [ -n "$_l" ] || continue
            _cn=$(hc_field "$_l" 1); _tsh=$(hc_field "$_l" 2)
            _tps=$(hc_field "$_l" 3); _tex=$(hc_field "$_l" 4)
            case ",$_tex," in *",$_hn,"*) continue ;; esac       # 면제로 선언된 하니스는 빠진다
            if [ "$_tsh" != "-" ]; then
                LC_ALL=C grep -qF -e "$_tsh" "$SBX/hcnc-sh.txt" ||
                    printf '%s:sh:%s\n' "$_hn" "$_cn"
            fi
            if [ "$_tps" != "-" ]; then
                LC_ALL=C grep -qF -e "$_tps" "$SBX/hcnc-ps1.txt" ||
                    printf '%s:ps1:%s\n' "$_hn" "$_cn"
            fi
        done < "$SBX/hclines.txt"
    done < "$1"
}
hc_orphan_exempt() { # <하니스 목록 파일> → 실재하지 않는 하니스를 지목한 면제 이름
    while IFS= read -r _hd; do [ -n "$_hd" ] && printf '%s\n' "${_hd##*/}"; done < "$1" > "$SBX/hcnames.txt"
    hc_lines | while IFS= read -r _l; do
        _tex=$(hc_field "$_l" 4)
        [ "$_tex" = "none" ] && continue
        printf '%s\n' "$_tex" | tr ',' '\n' | while IFS= read -r _e; do
            [ -n "$_e" ] || continue
            LC_ALL=C grep -qxF -e "$_e" "$SBX/hcnames.txt" || printf '%s\n' "$_e"
        done
    done
}
hc_wellformed() { # <선언 줄> → 네 필드가 다 있고 어느 것도 비어 있지 않으면 0
    # (M50) 필드 수도 파라미터 확장으로 센다 — `printf | sed | awk` 셋이 0개가 된다.
    _hw=${1#"<!-- harness-control: "}
    _hw=${_hw%" -->"}
    _nf=1
    while :; do
        case "$_hw" in
            *' :: '*) _hw=${_hw#* :: }; _nf=$((_nf + 1)) ;;
            *) break ;;
        esac
    done
    [ "$_nf" = "4" ] || return 1
    for _i in 1 2 3 4; do [ -n "$(hc_field "$1" "$_i")" ] || return 1; done
    return 0
}
if part_on K; then
harness_dirs_in "$ROOT/tests" > "$SBX/harnesses.txt"
NHCDECL=$(hc_lines | grep -c .)
NHCNAME=$(hc_lines | while IFS= read -r _l; do hc_field "$_l" 1; done | LC_ALL=C sort -u | grep -c .)
NHCWELL=$(hc_lines | while IFS= read -r _l; do hc_wellformed "$_l" && echo ok; done | grep -c .)
NHARNESS=$(grep -c . "$SBX/harnesses.txt")
NHCMISS=$(hc_missing "$SBX/harnesses.txt" | grep -c .)
[ "$NHCMISS" = "0" ] || hc_missing "$SBX/harnesses.txt" | sed 's|^|  -> harness control token missing: |'
# (K1) 선언 추출 positive-control — 선언 블록이 사라지면 아래 루프가 통째로 돌지 않아 `0 == 0`이 된다.
chk "K1: harness-control 선언 추출 positive-control(>0)" "$([ "$NHCDECL" -gt 0 ] && echo ok || echo no)" "ok"
# (K2) 선언 **이름 유일성 + 형식 정합**(체크리스트 ⑵). **복합 기댓값**이다 — 앞자리는
# **유일 이름 수**(같은 이름이 둘이면 산문 한 줄이 목록을 통째로 바꾼다), 뒷자리는 **네 필드를 다 갖고
# 어느 필드도 비어 있지 않은 줄 수**다. 뒷자리가 없으면 빈 넷째 필드가 `none`과 **완전히 같게**
# 동작해 규약의 *"빈 칸으로 두지 않는다"* 가 무집행이 된다(M48 리뷰 사소 8).
chk "K2: 통제 이름 유일성 + 선언 줄 형식 정합(네 필드·빈 칸 없음)" "$NHCNAME/$NHCWELL" "$NHCDECL/$NHCDECL"
# (K3) 하니스 발견 positive-control — 발견이 0이면 `K4`가 공허 통과한다.
chk "K3: 하니스 발견 positive-control(>0)" "$([ "$NHARNESS" -gt 0 ] && echo ok || echo no)" "ok"
# (K4) 본 검사 — 면제를 뺀 모든 (하니스 x 셸) 조합이 자기 몫의 토큰을 갖는다.
chk "K4: 면제 제외 하니스x셸 조합의 통제 토큰 미보유 0건" "$NHCMISS" "0"
fi
# (K5) 픽스처 통제 — 살아 있는 미보유가 0건이라 이것이 공허를 막는다. 기댓값 `1/caught`의 앞자리는
# **발견 명세**(러너 하나뿐인 미끼 디렉터리는 하니스가 아니다)를, 뒷자리는 **판정**을 문다.
# 픽스처 하니스는 토큰을 **주석으로만** 갖는다 — 주석 제외를 되돌리면 뒷자리가 `missed`로 바뀌어
# 이 케이스가 붉어진다(차단 2가 닫혔다는 되돌림 증거가 이 자리다).
hc_fixture() { # 토큰을 **주석에만** 가진 하니스 + 러너 하나뿐인 미끼를 만들고 목록 파일 경로를 출력
    _d="$SBX/hcfix"
    rm -rf "$_d" 2>/dev/null
    mkdir -p "$_d/zz-fake" "$_d/zz-decoy"
    # `zz-fake`는 선언된 토큰을 **전부 주석으로만** 갖는다 — 그래서 `K5`는 *"토큰 없음"* 뿐 아니라
    # **"주석에만 있음"** 까지 문다(주석 제외가 죽으면 뒷자리가 `missed`가 된다). 주석 줄은
    # **선언 블록에서 파생**한다 — 토큰을 이 소스에 리터럴로 적으면 그 순간 이 러너 자신이 그 토큰을
    # 코드 줄에 갖게 돼 자기 대조가 헐거워진다(`J4`·`J5`가 바이트를 소스에 두지 않는 것과 같은 규율).
    : > "$_d/zz-fake/run.sh"
    : > "$_d/zz-fake/run.ps1"
    hc_lines | while IFS= read -r _l; do
        _ftsh=$(hc_field "$_l" 2); _ftps=$(hc_field "$_l" 3)
        [ "$_ftsh" = "-" ] || printf '# %s in a comment only\n' "$_ftsh" >> "$_d/zz-fake/run.sh"
        [ "$_ftps" = "-" ] || printf '# %s in a comment only\n' "$_ftps" >> "$_d/zz-fake/run.ps1"
    done
    printf 'echo hello\n'       >> "$_d/zz-fake/run.sh"
    printf 'Write-Host hello\n' >> "$_d/zz-fake/run.ps1"
    printf 'echo hello\n'       >  "$_d/zz-decoy/run.sh"    # run.ps1 없음 → 하니스가 아니다
    harness_dirs_in "$_d" > "$_d/list.txt"
    printf '%s\n' "$_d/list.txt"
}
if part_on K; then
HCFIXLIST=$(hc_fixture)
HCFIXN=$(grep -c . "$HCFIXLIST")
HCFIXR=$([ "$(hc_missing "$HCFIXLIST" | grep -c .)" -gt 0 ] && echo caught || echo missed)
chk "K5: 통제 — 토큰이 주석에만 있는 픽스처 하니스를 같은 함수가 잡는다" "$HCFIXN/$HCFIXR" "1/caught"
# (K6) 면제 실재 — 면제 목록이 지목한 이름이 **실재하는 하니스**여야 한다. 하니스 이름이 바뀌거나
# 사라지면 면제가 고아가 되어 그 통제가 아무도 모르게 헐거워진다(Part H의 면제 실재 검사와 같은 층).
chk "K6: 면제 목록이 지목한 하니스 실재(고아 0)" "$(hc_orphan_exempt "$SBX/harnesses.txt" | grep -c .)" "0"
fi

# === Part L (M49) — 선언한 수 ↔ 열거 항목 수 ==============================
# 문서가 **개수를 선언하고 곧이어 열거**하는 골격에서 둘이 어긋나는 것을 문다. 발단은 M48 라운드 0의
# 차단 1이다 — 그것은 **논리 결함이 아니라 편집 사고**였다(한 줄이 다른 줄을 통째로 덮어써 고지 항목
# 하나가 사라졌는데 서두는 그대로 셋을 선언하고 있었다). 그때 하니스 7종 × 네 실행 환경이 **전부
# 초록**이었고 어떤 가드도 그 자리를 보지 않았다. 단일 원본은
# `docs/conventions.md`의 "선언한 수 ↔ 열거 항목 수" 절.
#   표지는 **규약이 선언**하고 러너는 읽기만 한다(`state-neg:`·`harness-control:`과 같은 기전) —
#   그래야 ps1 사본이 한글 리터럴 없이 **같은 판정**을 쓴다.
#   창은 **동그라미 열거 기호 하나뿐**이다: 뒤따르는 불릿 블록을 창으로 잡으면 전건이 어긋나고
#   `·` 구분 인라인 열거로 잡아도 대부분 어긋난다(`·`가 이 저장소에서 열거 기호가 아니라 범용
#   구분자다). 수치의 단일 출처는 `docs/reports/M49-impl.md`다.
#   경계: 어떤 항목의 **본문**이 아직 등장하지 않은 다음 번호를 언급하면 수가 부풀어 오른다(오탐).
#   오늘 살아 있는 사이트에 그 형태는 0건이고, 규약이 같은 경계를 적는다.
if part_on L; then
CNT_WORDS=$(markers_of 'count-word:')
CNT_COPS=$(markers_of 'count-copula:')
CNT_WORDS_SP=$(printf '%s' "$CNT_WORDS" | tr '\n' ' ')
CNT_COPS_SP=$(printf '%s' "$CNT_COPS" | tr '\n' ' ')
NCW=$(printf '%s\n' "$CNT_WORDS" | grep -c .)
NCC=$(printf '%s\n' "$CNT_COPS" | grep -c .)
# 열거 기호는 G8이 쓰는 **같은 생성기**로 만든다(리터럴을 두지 않는다 — ps1 사본의 ASCII-only 규율과
# 같은 구성). 1~20줄 = U+2460 계열, 21~40줄 = U+2474 계열.
circ_list > "$SBX/lcirc.txt"
ENUM_S1_SP=$(head -20 "$SBX/lcirc.txt" | tr '\n' ' ')
ENUM_S2_SP=$(tail -20 "$SBX/lcirc.txt" | tr '\n' ' ')
NE1=$(printf '%s\n' "$ENUM_S1_SP" | tr ' ' '\n' | grep -c .)
NE2=$(printf '%s\n' "$ENUM_S2_SP" | tr ' ' '\n' | grep -c .)
fi
# `LC_ALL=C`로 고정한다 — `index`·`length`·`substr`가 바이트 의미로 일관되고, 로케일에 따라 문자/
# 바이트가 섞이는 축이 아예 없어진다(ps1 사본은 .NET 문자 의미로 일관되며, 쓰는 연산이 부분 문자열
# 탐색과 그 뒤 자르기뿐이라 두 사본의 답이 같다).
enum_scan_in() { # <파일> → 후보마다 "CAND", 불일치마다 "BAD <파일>:<줄>:<선언>/<실측>"
    [ -f "$1" ] || return 0
    LC_ALL=C awk -v W="$CNT_WORDS_SP" -v C="$CNT_COPS_SP" -v S1="$ENUM_S1_SP" -v S2="$ENUM_S2_SP" -v FN="$1" \
        -v cr="$(printf '\r')" '
    function lead(s,   t) { t = s; sub(/[^ \t].*$/, "", t); return length(t) }
    function islist(s) { return (s ~ /^[ \t]*([-*]|[0-9]+\.)[ \t]/) }
    function isenum(s,   t, k) {
        if (!islist(s)) return 0
        t = s; sub(/^[ \t]*([-*]|[0-9]+\.)[ \t]*/, "", t)
        for (k = 1; k <= n1; k++) if (index(t, E1[k]) == 1) return 1
        for (k = 1; k <= n2; k++) if (index(t, E2[k]) == 1) return 1
        return 0
    }
    # **표지 앞 경계(M49 재작업 1).** 표지를 낱말 경계 없이 찾으면 수사가 **다른 낱말 안에** 들어
    # 있을 때 그것이 선언으로 잡힌다 — `Uni 0xACC4 0xC5F4` 같은 말이 `Uni 0xC5F4`(=10) 표지를 품어
    # 정상 문서가 붉어졌다(M49 리뷰 차단 1의 실측). 규칙은 **표지 바로 앞이 줄머리이거나 ASCII**여야
    # 한다는 것이다. 이 판정이 두 사본에서 같은 답을 내는 근거: 이 사본은 `LC_ALL=C`라 앞 **바이트**를
    # 보고 ps1 사본은 앞 **문자**를 보는데, 비-ASCII 문자는 UTF-8에서 마지막 바이트가 0x80 이상이라
    # **둘의 판정이 항상 일치한다**(ASCII 문자 ⟺ ASCII 바이트).
    function tokpos(s, t,   p, off, pb) {   # 경계를 만족하는 첫 위치. 없으면 0.
        off = 0
        while (1) {
            p = index(substr(s, off + 1), t)
            if (p == 0) return 0
            p = p + off
            if (p == 1) return p
            pb = substr(s, p - 1, 1)
            if (pb == "\t" || pb ~ /^[ -~]$/) return p
            off = p
        }
    }
    function maxrun(w,   a, b) {   # 1부터 이어지는 최대 구간. 두 계열은 따로 세고 큰 쪽을 쓴다.
        a = 0; while (a < n1 && index(w, E1[a + 1]) > 0) a++
        b = 0; while (b < n2 && index(w, E2[b + 1]) > 0) b++
        return (a > b) ? a : b
    }
    BEGIN {
        nw = split(W, WA, " "); nc = split(C, CA, " ")
        n1 = split(S1, E1, " "); n2 = split(S2, E2, " ")
        m = 0
        for (i = 1; i <= nw; i++) {
            p = index(WA[i], "=")
            if (p > 0) { m++; WD[m] = substr(WA[i], 1, p - 1); VL[m] = substr(WA[i], p + 1) + 0 }
        }
        nwv = m
    }
    # **줄 끝 CR을 벗긴다(방어 — 케이스로 못박지 못한다).** `.gitattributes`가 LF로 못박은 것은
    # `*.sh`뿐이라 `.md`는 CRLF로 체크아웃될 수 있고, POSIX awk가 그런 파일을 읽으면 빈 줄이 `\r` 한
    # 글자가 되어 `/^[ \t]*$/`에 걸리지 않는다 — 창이 끊기지 않고 자라 이 사본만 어긋난다.
    # **그런데 이 자리는 네 실행 환경 어디에서도 붉힐 수 없다**: `.md`가 CRLF가 되는 것은 Windows
    # 체크아웃(`core.autocrlf=true`)뿐인데 거기서 이 사본이 쓰는 awk는 Git Bash의 gawk이고, 그것은
    # 파일을 **텍스트 모드로 읽어 CR을 먼저 벗긴다**(M49-T04 실측: `printf 'a\r\n'`에 `length($0)`가
    # 1이다 — bash·dash 둘 다). 그래서 이 줄은 **케이스 없는 방어**로 남긴다 — Part G의 `anchor_set`이
    # 같은 이유로 같은 형태를 두고 있다(그쪽 주석: *"Git Bash grep은 가려 주지만 POSIX grep은 가려
    # 주지 않는다"*). 공허한 케이스를 세우는 대신 **못 무는 것을 적는다.**
    { p = $0; if (length(p) > 0 && substr(p, length(p), 1) == cr) p = substr(p, 1, length(p) - 1); L[NR] = p }
    END {
        for (i = 1; i <= NR; i++) {
            line = L[i]
            # 표지 선언 줄 자신은 대상이 아니다(선언처가 자기 표지에 걸리는 것을 막는다 — Part I와 동형).
            if (index(line, "count-word:") || index(line, "count-copula:")) continue
            base = lead(line)
            for (w = 1; w <= nwv; w++) for (c = 1; c <= nc; c++) {
                tok = WD[w] CA[c]
                pos = tokpos(line, tok)
                if (pos == 0) continue
                win = substr(line, pos + length(tok))
                for (j = i + 1; j <= NR; j++) {
                    nl = L[j]
                    if (nl ~ /^[ \t]*$/) break
                    if (islist(nl) && lead(nl) <= base && !isenum(nl)) break
                    win = win "\n" nl
                }
                k = maxrun(win)
                if (k == 0) continue
                print "CAND"
                if (k != VL[w]) print "BAD " FN ":" i ":" tok ":" VL[w] "/" k
            }
        }
    }' "$1"
}
if part_on L; then
: > "$SBX/lscan.txt"
while IFS= read -r _lf; do
    [ -f "$_lf" ] || continue
    enum_scan_in "$_lf" >> "$SBX/lscan.txt"
done < "$SBX/living.txt"
NLCAND=$(grep -c '^CAND' "$SBX/lscan.txt")
NLBAD=$(grep -c '^BAD ' "$SBX/lscan.txt")
NLIVING=$(grep -c . "$SBX/living.txt")
[ "$NLBAD" = "0" ] || grep '^BAD ' "$SBX/lscan.txt" | sed 's/^BAD /  -> declared count vs enumerated items: /'
chk "L1: count-word 선언 줄 정확히 1개" "$(decl_count "$CONV" 'count-word:')" "1"
chk "L2: count-copula 선언 줄 정확히 1개" "$(decl_count "$CONV" 'count-copula:')" "1"
chk "L3: 표지 추출 positive-control(수사>0 · 조사>0)" \
    "$([ "$NCW" -gt 0 ] && [ "$NCC" -gt 0 ] && echo ok || echo no)" "ok"
chk "L4: 열거 기호 두 계열 각 20자(양 사본이 자기 단언)" "$NE1/$NE2" "20/20"
fi
# (L5) **루트마다 묻는다.** *"발견이 0이면 FAIL"* 만으로는 **루트 하나가 사라지는 것**을 보지 못한다 —
# 나머지 루트의 문서가 남아 수는 여전히 0보다 크고, 훑는 범위만 조용히 줄어든다. M48 리뷰가 정확히
# 이 형태(`J1`)를 반환했으므로 같은 실수를 되풀이하지 않는다. 부류는 **발견 함수가 돌려준 경로에서**
# 분류한다(다시 발견하지 않는다 — 검사 대상과 다른 코드로 재면 아무것도 증명하지 못한다).
living_roots() { # → 살아 있는 문서 목록에 나타난 최상위 루트 부류 수
    awk -v r="$ROOT/" '
        { p = $0; if (index(p, r) == 1) p = substr(p, length(r) + 1) }
        p ~ /^skills\//    { c["skills"] = 1; next }
        p ~ /^site\/docs\// { c["site"] = 1; next }
        p ~ /^docs\//      { c["docs"] = 1; next }
        p ~ /^tests\//     { c["tests"] = 1; next }
        p == "README.md"   { c["readme"] = 1; next }
        END { n = 0; for (k in c) n++; print n }
    ' "$SBX/living.txt"
}
if part_on L; then
chk "L5: 살아 있는 문서 루트 다섯 부류가 전부 나타난다(>0이 아니라 루트마다)" \
    "$(living_roots)/$([ "$NLIVING" -gt 0 ] && echo ok || echo no)" "5/ok"
# (L6) 후보가 0이면 L7이 **0==0으로 조용히 통과**한다 — 추출 자체를 먼저 문다.
chk "L6: 선언+열거 후보 추출 positive-control(>0)" "$([ "$NLCAND" -gt 0 ] && echo ok || echo no)" "ok"
chk "L7: 살아 있는 문서의 선언 수 ↔ 열거 항목 수 불일치 0건" "$NLBAD" "0"
fi
# 픽스처 통제 둘 — **실제 판정을 픽스처에 건다**(픽스처가 조건을 만족하는가가 아니라 판정이 잡는가를
# 묻는 형태. M46 리뷰 차단 #1의 판례). 픽스처 문자열은 **표지에서 파생**시킨다 — 러너 소스에 수사·
# 조사를 리터럴로 적으면 ps1 사본이 ASCII-only 규율을 어기고, 이 사본도 자기 표지를 갖게 된다.
enum_word_for() { printf '%s\n' "$CNT_WORDS" | awk -F= -v v="$1" '$2 + 0 == v { print $1; exit }'; }
if part_on L; then
LW3=$(enum_word_for 3)
LCOP=$(printf '%s\n' "$CNT_COPS" | head -1)
LE1=$(sed -n '21p' "$SBX/lcirc.txt"); LE2=$(sed -n '22p' "$SBX/lcirc.txt")
LE3=$(sed -n '23p' "$SBX/lcirc.txt"); LE4=$(sed -n '24p' "$SBX/lcirc.txt")
printf '%s%s: %s a %s b\n' "$LW3" "$LCOP" "$LE1" "$LE2" > "$SBX/lfa.md"
printf '%s%s: %s a %s b %s c %s d\n' "$LW3" "$LCOP" "$LE1" "$LE2" "$LE3" "$LE4" > "$SBX/lfb.md"
printf '%s%s: a b c\n' "$LW3" "$LCOP" > "$SBX/lfc.md"
printf '%s %s: %s a %s b %s c\n' "$LW3" "$LCOP" "$LE1" "$LE2" "$LE3" > "$SBX/lfd.md"
chk "L8: 픽스처 통제 — 항목 하나가 사라진 선언을 판정이 잡는다" "$(enum_scan_in "$SBX/lfa.md" | grep -c '^BAD ')" "1"
chk "L9: 픽스처 통제 — 항목 하나가 늘어난 선언을 판정이 잡는다" "$(enum_scan_in "$SBX/lfb.md" | grep -c '^BAD ')" "1"
# (L10) 음성 통제 둘 — 동그라미 열거가 없으면 후보가 아니고(창이 이것 하나뿐이라는 명세의 실증),
# 수사와 조사가 **붙어 있지 않으면** 선언이 아니다(이력 서술 *"넷에서 셋으로 줄였다"* 가 후보에서
# 빠지는 것이 이 인접 조건이다 — 그쪽 조사는 `count-copula:`에 없다).
chk "L10: 음성 통제 — 열거 없음 · 수사와 조사가 떨어진 형태는 후보가 아니다" \
    "$(enum_scan_in "$SBX/lfc.md" | grep -c '^CAND')/$(enum_scan_in "$SBX/lfd.md" | grep -c '^CAND')" "0/0"
# (L11) **빈 줄 판정의 폭.** 창은 빈 줄에서 끊기므로 *"무엇이 빈 줄인가"* 가 곧 창의 경계이고, 그
# 폭이 두 사본에서 갈리면 같은 트리에 다른 수가 나온다. 폭은 **ASCII 공백·탭**뿐이다 — U+00A0만 있는
# 줄은 **빈 줄이 아니다.** 픽스처는 선언 뒤에 항목 둘을 두고 **U+00A0 줄 뒤에 셋째**를 둔다: 폭이
# 맞으면 창이 끊기지 않아 셋을 세고 불일치가 **0건**이며, 폭을 유니코드 공백까지 넓히면(ps1의 `\s`가
# 그 폭이다) 창이 거기서 끊겨 둘을 세고 **불일치 1건**이 된다. 기댓값을 `<후보>/<불일치>` 복합으로
# 두는 것은 스캔이 통째로 죽어도 `0/0`이 아니라 **붉게** 만들기 위해서다. F17과 같은 층이다.
printf '%s%s: %s a %s b\n\302\240\n%s c\n' "$LW3" "$LCOP" "$LE1" "$LE2" "$LE3" > "$SBX/lfe.md"
chk "L11: 통제 — U+00A0만 있는 줄은 빈 줄이 아니다(창 경계의 폭)" \
    "$(enum_scan_in "$SBX/lfe.md" | grep -c '^CAND')/$(enum_scan_in "$SBX/lfe.md" | grep -c '^BAD ')" "1/0"

# (L12) **오탐 방향 음성 통제(M49 재작업 1).** 여기까지의 케이스는 전부 *"검사가 죽는가"* 를 묻고
# *"검사가 과하게 무는가"* 를 묻는 것이 하나도 없었다 — 그 빈자리에서 리뷰 차단 1이 나왔다. 이 케이스는
# **양방향**이다: 앞자리는 수사가 **낱말 안에** 있을 때 후보가 아님을(경계를 지우면 1이 되어 붉는다),
# 뒷자리는 **ASCII 공백 뒤**면 여전히 후보임을(경계를 지나치게 좁히면 0이 되어 붉는다) 문다.
# 픽스처의 앞 낱말도 **표지에서 파생**시킨다 — 러너 소스에 한글 리터럴을 두지 않는 규율 그대로다.
LW4=$(enum_word_for 4)
printf '%s%s%s: %s a %s b\n' "$LW4" "$LW3" "$LCOP" "$LE1" "$LE2" > "$SBX/lff.md"
printf ' %s%s: %s a %s b %s c\n' "$LW3" "$LCOP" "$LE1" "$LE2" "$LE3" > "$SBX/lfg.md"
chk "L12: 음성 통제 — 수사가 낱말 안이면 표지가 아니다 / 공백 뒤면 표지다" \
    "$(enum_scan_in "$SBX/lff.md" | grep -c '^CAND')/$(enum_scan_in "$SBX/lfg.md" | grep -c '^CAND')" "0/1"
# (L13) 불일치 진단은 **걸린 표지를 함께 말한다**. 수를 세는 단언은 붉어져도 원인을 말해 주지 않아
# M40에서 기전을 재현하지 못했고(그래서 `G2`가 중복 앵커 이름을 찍는다), M49 리뷰 차단 1의 재현에서도
# `10/2`만으로는 원인이 보이지 않았다. 같은 일을 세 번째로 반복하지 않는다.
chk "L13: 불일치 진단이 걸린 표지를 담는다"     "$(enum_scan_in "$SBX/lfa.md" | grep -c "^BAD .*:${LW3}${LCOP}:")" "1"
fi

# === Part M (M51) — 에픽(방향) 참조 정합 =================================
# 사이클의 방향이 **직전 사이클의 후속 메모**가 아니라 **선언된 줄기**에서 오게 하는 장치다.
# 마일스톤이 `epic:` 한 줄로 자기가 속한 줄기를 밝히고, 이 파트가 **참조의 존재·실재·양방향
# 일치**를 문다. 단일 원본은 `docs/conventions.md`의 "에픽 (방향) 층" 절.
#   값은 **규약이 선언하고 러너는 읽기만 한다**(`state-neg:`·`count-word:`와 같은 기전) —
#   `epic-status:`(열림/닫힘 값 집합) · `epic-since:`(집행이 시작되는 마일스톤 번호).
#   역방향은 에픽의 **줄머리 `- M{N}`** 으로 잡는다 — 절 제목을 매칭하지 않아 러너 소스가 한글
#   바이트에 기대지 않고 ps1 사본과 같은 술어를 쓴다.
#   **묻지 않는 것**: 「이 마일스톤이 그 줄기에 정말 속하는가」는 의미 판정이라 정적으로 물을 수
#   없다(M49의 「머리 위치」·M50의 「while-read 루프」와 같은 부류). 거짓 참조는 문서에 남는 눈에
#   보이는 진술이라 리뷰의 영역이다.
if part_on M; then
EPIC_STATUSES=$(markers_of 'epic-status:')
EPIC_MEMBER_MARK=$(markers_of 'epic-members:' | head -1)
EPIC_SINCE=$(markers_of 'epic-since:' | head -1)
NEPICSTAT=$(printf '%s\n' "$EPIC_STATUSES" | grep -c .)
fi
epic_list_into() { # <에픽목록 경로> <마일스톤목록 경로> <트리 루트>
    : > "$1"
    [ -d "$3/docs/epics" ] && ls "$3"/docs/epics/E*.md 2>/dev/null > "$1"
    : > "$2"
    ls "$3"/docs/milestones/M*.md 2>/dev/null > "$2"
    return 0
}
# 한 번 도는 awk가 **양쪽을 함께** 읽어 판정한다(줄마다 프로세스를 띄우지 않는다 — M50 비용 규율).
#   출력: `OPEN <n>` 열린 에픽 수 · `MREF <M> <E>` 마일스톤의 참조 · `EREF <E> <M>` 에픽의 역방향
#         `BAD <사유> <대상>` 불일치
epic_scan() { # <에픽목록> <마일스톤목록>
    LC_ALL=C awk -v EL="$1" -v ML="$2" -v SINCE="$EPIC_SINCE" -v MARK="$EPIC_MEMBER_MARK" '
    function base(t,   i) { while ((i = index(t, "/")) > 0) t = substr(t, i + 1); return t }
    function num(t,   d) { d = t; gsub(/[^0-9]/, "", d); return d + 0 }
    BEGIN {
        since = num(SINCE)
        nopen = 0
        while ((getline ef < EL) > 0) {
            if (ef == "") continue
            eid = base(ef); sub(/\.md$/, "", eid)
            EPIC[eid] = 1
            inblk = 0
            while ((getline l < ef) > 0) {
                if (l ~ /^- status:/) {
                    st = l; sub(/^- status:[ \t]*/, "", st); gsub(/[ \t\r]/, "", st)
                    if (st == "open") { nopen++; }
                }
                # **마커 블록 안만 등재로 본다.** 줄머리 `- M{N}`만으로 잡으면 에픽 본문의
                # 평범한 산문 목록 항목이 등재로 세어진다(공백으로 끊기는 형태는 토큰이 정확히
                # `M{N}`이 되어 실재 마일스톤과 일치한다 — M51 리뷰 권장 2의 실측). 마커는
                # **ASCII**라 ps1 사본의 byte>127=0 규율을 지키면서 창을 정확히 자른다.
                if (index(l, "<!-- " MARK ":start -->") > 0) { inblk = 1; continue }
                if (index(l, "<!-- " MARK ":end -->") > 0) { inblk = 0; continue }
                if (inblk && l ~ /^- M[0-9]/) {
                    m = l; sub(/^- /, "", m); sub(/[ \t].*$/, "", m); gsub(/\r/, "", m)
                    nback++; BE[nback] = eid; BM[nback] = m
                    BACK[eid SUBSEP m] = 1
                    print "EREF " eid " " m
                }
            }
            close(ef)
        }
        close(EL)
        print "OPEN " nopen
        while ((getline mf < ML) > 0) {
            if (mf == "") continue
            mid = base(mf); sub(/\.md$/, "", mid)
            ref = ""
            while ((getline l < mf) > 0) {
                if (l ~ /^- epic:/) { ref = l; sub(/^- epic:[ \t]*/, "", ref); gsub(/[ \t\r]/, "", ref); break }
            }
            close(mf)
            MSEEN[mid] = 1                                       # 실재 기록(에픽 기준 순회가 쓴다)
            MREF[mid] = ref
            if (num(mid) < since) continue                       # 집행 시작 이전은 대상이 아니다
            if (ref == "") {
                if (nopen > 0) print "BAD noref " mid            # 규칙 1
                continue
            }
            print "MREF " mid " " ref
            if (!(ref in EPIC)) { print "BAD dangling " mid ">" ref; continue }    # 규칙 2
            if (!((ref SUBSEP mid) in BACK)) print "BAD oneway " mid ">" ref       # 규칙 3
        }
        close(ML)
        # **에픽 기준 순회(규칙 3의 「그 반대」).** 마일스톤 기준 순회만으로는 **에픽이 어떤 마일스톤을
        # 자기 줄기라고 주장하는데 그 마일스톤이 부인하는 자리**를 보지 못한다(M51 리뷰 차단 1).
        #   ⑴ 등재된 마일스톤이 **실재하지 않으면** FAIL(고아)
        #   ⑵ 실재하되 **다른 에픽을 가리키면** FAIL
        #   ⑶ `epic-since:` **미만**이면 **정상** — 그 마일스톤은 에픽 층이 없던 시절의 산출물이라
        #      참조를 갖지 않는 것이 옳다. 이것을 FAIL로 만들면 과거를 소급하는 셈이 된다.
        for (i = 1; i <= nback; i++) {
            e = BE[i]; m = BM[i]
            if (!(m in MSEEN)) { print "BAD ghost " e ">" m; continue }
            if (num(m) < since) continue
            if (MREF[m] != e) print "BAD claim " e ">" m
        }
    }' < /dev/null
}
if part_on M; then
epic_list_into "$SBX/epics.txt" "$SBX/msdocs.txt" "$ROOT"
NMSDOC=$(grep -c . "$SBX/msdocs.txt")
epic_scan "$SBX/epics.txt" "$SBX/msdocs.txt" > "$SBX/epicscan.txt"
NEPICOPEN=$(grep -c '^OPEN [1-9]' "$SBX/epicscan.txt")
NEPICREF=$(grep -c '^MREF ' "$SBX/epicscan.txt")
NEPICBAD=$(grep -c '^BAD ' "$SBX/epicscan.txt")
[ "$NEPICBAD" = "0" ] || grep '^BAD ' "$SBX/epicscan.txt" | sed 's/^BAD /  -> epic reference: /'
chk "M1: epic-status 선언 줄 정확히 1개" "$(decl_count "$CONV" 'epic-status:')" "1"
chk "M2: epic-since 선언 줄 정확히 1개" "$(decl_count "$CONV" 'epic-since:')" "1"
# (M3) 표지가 비면 아래 판정이 통째로 공허해진다 — 추출 자체를 먼저 문다.
# (M3) **복합 기댓값**이다. 앞자리는 추출 positive-control(살아 있는 표지가 뽑혀야 한다), 뒷자리는
# **없는 키로 같은 추출 경로를 한 번 더 태워** 그것이 **비었다고 판정되는지**를 묻는다 — 두 사본이
# 갈렸던 자리가 정확히 거기다(ps1의 `[string](@() | Select-Object -First 1)`이 `''`가 아니라 `$null`
# 이고 `$null -ne ''`가 참이라 없는 선언을 있는 것으로 읽었다. M51 되돌림의 `m2-key`·`m3-empty`가
# 잡았다). 뒷자리를 두면 그 갈림이 되돌림 표가 아니라 **상시 케이스**로 고정된다.
EPIC_SINCE_ABSENT=$(markers_of 'epic-since-absent:' | head -1)
chk "M3: 표지 추출 positive-control / 없는 키는 비었다고 판정" \
    "$([ "$NEPICSTAT" -gt 0 ] && [ -n "$EPIC_SINCE" ] && echo ok || echo no)/$([ -n "$EPIC_SINCE_ABSENT" ] && echo ok || echo no)" "ok/no"
# (M4) 두 발견 목록을 **각각** 묻는다 — 합으로 세면 한쪽이 사라져도 다른 쪽 수가 남아 초록이다
# (M48 리뷰가 `J1`에서 반환한 부류와 같은 방향).
chk "M4: 마일스톤 문서 발견 positive-control(>0)" "$([ "$NMSDOC" -gt 0 ] && echo ok || echo no)" "ok"
chk "M5: 본 검사 — 에픽 참조 불일치 0건" "$NEPICBAD" "0"
# 픽스처 통제 셋 — **실제 판정을 픽스처에 건다**(픽스처가 조건을 만족하는가가 아니라 판정이
# 잡는가를 묻는 형태. M46 리뷰 차단 #1의 판례). 목록을 인자로 넘기므로 **살아 있는 목록을
# 덮어쓰지 않는다.**
EPIC_SN=${EPIC_SINCE#M}
fi
epic_fixture() { # <모드> → 사본 트리 경로. 모드: dangling | oneway | noref | clean | noepic
    _d="$SBX/epicfix-$1"
    rm -rf "$_d" 2>/dev/null
    mkdir -p "$_d/docs/milestones"
    [ "$1" = "noepic" ] || mkdir -p "$_d/docs/epics"
    _bs="<!-- $EPIC_MEMBER_MARK:start -->"
    _be="<!-- $EPIC_MEMBER_MARK:end -->"
    case "$1" in
        # `oneway`·`dangling`·`noref`는 **블록을 비운다** — 그래야 마일스톤 쪽 위반 하나만 남는다.
        # 블록이 `M{since}`를 등재한 채로 두면 에픽 기준 순회가 `claim`을 하나 더 내 통제가 둘을 센다.
        oneway|dangling|noref)
                 printf -- '- status: open\n%s\n%s\n' "$_bs" "$_be" > "$_d/docs/epics/E1.md" ;;
        noepic)  : ;;
        # `ghost`는 반대다 — **정방향은 성립시켜 두고**(블록에 `M{since}`도 넣는다) 없는 마일스톤
        # 하나만 더해 에픽 기준 위반 하나만 남긴다.
        ghost)   printf -- '- status: open\n%s\n- M%s x\n- M999 x\n%s\n' \
                     "$_bs" "$EPIC_SN" "$_be" > "$_d/docs/epics/E1.md" ;;
        # E1은 정상으로 등재하고(정방향 통과) **E2가 같은 마일스톤을 자기 것이라 주장**한다.
        # 그 마일스톤은 `epic: E1`을 적으므로 E2의 주장만 어긋난다.
        claim)   printf -- '- status: open\n%s\n- M%s x\n%s\n' "$_bs" "$EPIC_SN" "$_be" > "$_d/docs/epics/E1.md"
                 printf -- '- status: open\n%s\n- M%s x\n%s\n' "$_bs" "$EPIC_SN" "$_be" > "$_d/docs/epics/E2.md" ;;
        # `prose`는 `claim`과 **줄의 위치만 다른 한 쌍**이다 — E2가 같은 마일스톤을 언급하되
        # **블록 밖**에서 한다. 창이 살아 있으면 세지 않아 0이고, 창을 지우면 E2의 주장이 되어
        # `claim`이 난다. 언급 대상이 **`epic-since:` 이상**이어야 한다 — 미만을 쓰면 창을 지워도
        # **과거 예외가 삼켜** 통제가 창이 아니라 그 예외를 무는 자리가 된다(라운드 1 실측:
        # 대상이 M9이던 판에서 `m-block-off`가 초록으로 돌아왔다).
        prose)   printf -- '- status: open\n%s\n- M%s x\n%s\n' "$_bs" "$EPIC_SN" "$_be" > "$_d/docs/epics/E1.md"
                 printf -- '- status: open\n- M%s x\n%s\n%s\n' "$EPIC_SN" "$_bs" "$_be" > "$_d/docs/epics/E2.md" ;;
        past)    printf -- '- status: open\n%s\n- M9 x\n- M%s x\n%s\n' "$_bs" "$EPIC_SN" "$_be" \
                     > "$_d/docs/epics/E1.md" ;;
        *)       printf -- '- status: open\n%s\n- M%s x\n%s\n' "$_bs" "$EPIC_SN" "$_be" > "$_d/docs/epics/E1.md" ;;
    esac
    case "$1" in
        # `claim`·`prose` 둘 다 E2가 M{since}를 자기 것이라 하는데 그 마일스톤은 E1을 가리킨다.
        claim|prose) printf -- '- epic: E1\n' > "$_d/docs/milestones/M$EPIC_SN.md" ;;
        # `past`는 과거 마일스톤(M9)이 실재해야 판정이 성립한다(`prose`는 라운드 1에서
        # 언급 대상을 M{since}로 옮겨 M9 의존이 없어졌다).
        past)     printf -- '- epic: E1\n' > "$_d/docs/milestones/M$EPIC_SN.md"
                  printf -- '- x\n' > "$_d/docs/milestones/M9.md" ;;
        dangling) printf -- '- epic: E9\n' > "$_d/docs/milestones/M$EPIC_SN.md" ;;
        # `noref`는 **열린 에픽이 있는데** 참조가 없는 자리고, `noepic`은 **에픽 자체가 없는**
        # 저장소다 — 후자의 마일스톤도 참조를 갖지 않아야 그 저장소의 현실이 된다(하위 호환).
        noref|noepic) printf -- '- x\n'    > "$_d/docs/milestones/M$EPIC_SN.md" ;;
        *)        printf -- '- epic: E1\n' > "$_d/docs/milestones/M$EPIC_SN.md" ;;
    esac
    printf '%s' "$_d"
}
epic_bad_in() { # <사본 트리> → 그 트리에서 **실제 판정**이 낸 BAD 수
    epic_list_into "$SBX/fx-epics.txt" "$SBX/fx-ms.txt" "$1"
    epic_scan "$SBX/fx-epics.txt" "$SBX/fx-ms.txt" | grep -c '^BAD '
}
if part_on M; then
chk "M6: 픽스처 통제 — 실재하지 않는 에픽을 가리키면 판정이 잡는다" \
    "$(epic_bad_in "$(epic_fixture dangling)")" "1"
chk "M7: 픽스처 통제 — 역방향이 끊기면 판정이 잡는다" \
    "$(epic_bad_in "$(epic_fixture oneway)")" "1"
chk "M8: 픽스처 통제 — 열린 에픽이 있는데 참조가 없으면 판정이 잡는다" \
    "$(epic_bad_in "$(epic_fixture noref)")" "1"
# (M9) **오탐 방향 음성 통제 — 양방향 기댓값.** 앞자리는 정상 참조가 붉지 않음을, 뒷자리는
# **에픽이 하나도 없는 트리**가 붉지 않음을 묻는다(하위 호환 — tide는 남의 저장소에 얹는 물건이라
# 이것이 계약이다). 경계를 지우면 앞자리가, 지나치게 좁히면 뒷자리가 어긋난다.
chk "M9: 음성 통제 — 정상 참조 / 에픽 없는 트리는 붉지 않는다" \
    "$(epic_bad_in "$(epic_fixture clean)")/$(epic_bad_in "$(epic_fixture noepic)")" "0/0"
# (M10) 이 저장소에서 장치가 **실제로 서 있는지** — 열린 에픽과 마일스톤 참조가 각각 실재한다.
# 에픽을 쓰지 않는 저장소에서는 둘 다 0이고 그때 M5는 발동하지 않는다(위 M9 뒷자리가 그 경로다).
chk "M10: 이 저장소에 열린 에픽과 마일스톤 참조가 실재" \
    "$NEPICOPEN/$([ "$NEPICREF" -gt 0 ] && echo ok || echo no)" "1/ok"
chk "M11: epic-members 선언 줄 정확히 1개" "$(decl_count "$CONV" 'epic-members:')" "1"
# 픽스처 통제 둘 — **에픽 기준 순회**(규칙 3의 「그 반대」)를 실제 판정으로 건다. M51 리뷰 차단 1이
# 정확히 이 축의 부재였고, **되돌림은 구현되지 않은 축을 볼 수 없어** 그때 잡지 못했다.
chk "M12: 픽스처 통제 — 에픽이 실재하지 않는 마일스톤을 등재하면 잡는다" \
    "$(epic_bad_in "$(epic_fixture ghost)")" "1"
chk "M13: 픽스처 통제 — 에픽이 남의 마일스톤을 등재하면 잡는다" \
    "$(epic_bad_in "$(epic_fixture claim)")" "1"
# (M14) **오탐 방향 음성 통제 — 양방향.** 앞자리는 **블록 밖 산문 목록 항목**(E2가 남의 마일스톤을
# 블록 밖에서 언급한다 — 창이 없으면 `claim`이 난다)이 등재로 세어지지 않음을,
# 뒷자리는 **`epic-since:` 미만 마일스톤 등재**가 붉지 않음을 묻는다(과거는 소급 대상이 아니다).
# 창을 지우면 앞자리가, 과거 예외를 지우면 뒷자리가 어긋난다.
chk "M14: 음성 통제 — 블록 밖 산문 / 과거 마일스톤 등재는 붉지 않는다" \
    "$(epic_bad_in "$(epic_fixture prose)")/$(epic_bad_in "$(epic_fixture past)")" "0/0"
fi

# === Part N (M52) — 상태 확인 항목 선언 정합 =============================
# 확인 항목 목록의 선언처를 규약 한 곳으로 만들고 `/tide:status`·`/tide:fleet`이 **읽기만** 하게 한
# 것을 문다. 결함의 형태는 **선언과 사본이 갈리는 것**이었다 — fleet이 여섯을 박아 둔 채 status가
# 여덟로 늘어 fleet의 판단 규칙이 **데이터 없이 조용히 발화하지 못했다**(M52-T01 실측).
#   단일 원본은 `docs/conventions.md`의 "상태 확인 항목과 시작점 판단 (선언)" 절.
#   **소비자 대조에 ASCII 토큰만 쓴다**(`status-items:`·`M{N}-impl.md`) — ps1 사본이 한글 리터럴을
#   가질 수 없으므로 두 사본이 **문자 그대로 같은 술어**를 쓰게 하는 자리다.
if part_on N; then
NSIABSENT=$(markers_of 'status-items-absent:' | grep -c .)
NSI=$(markers_of 'status-items:' | grep -c .)
fi
si_rows_in() { # <규약 경로> → 「무엇을 읽는가」 표의 행 수(선언 줄 이후·다음 제목 전까지)
    LC_ALL=C awk '
        index($0, "status-items:") > 0 { win = 1; next }
        win && substr($0, 1, 1) == "#" { win = 0 }
        win && index($0, "  | `") == 1 { n++ }
        END { print n + 0 }
    ' "$1"
}
si_mismatch() { # <규약 경로> → 선언 토큰 수 != 표 행 수면 1
    _sd=$(decl_tail "$1" 'status-items:' | tr -d '`*' | tr ' ' '\n' | grep -c .)
    _sr=$(si_rows_in "$1")
    [ "$_sd" = "$_sr" ] && echo 0 || echo 1
}
si_fixture() { # <모드> → 사본 규약 경로 (clean | norow | notoken)
    _sf="$SBX/si-$1.md"
    case "$1" in
        norow)   LC_ALL=C awk 'BEGIN { d = 0 }
                     d == 0 && index($0, "  | `open-epic`") == 1 { d = 1; next }
                     { print }' "$CONV" > "$_sf" ;;
        notoken) LC_ALL=C awk '{ if (index($0, "`status-items:`") > 0) sub(/ open-epic/, ""); print }' \
                     "$CONV" > "$_sf" ;;
        *)       cat "$CONV" > "$_sf" ;;
    esac
    printf '%s' "$_sf"
}
if part_on N; then
chk "N1: status-items 선언 줄 정확히 1개" "$(decl_count "$CONV" 'status-items:')" "1"
chk "N2: autonomy-level 선언 줄 정확히 1개" "$(decl_count "$CONV" 'autonomy-level:')" "1"
# (N3) **복합 기댓값**. 앞자리는 추출 positive-control, 뒷자리는 **없는 키로 같은 추출 경로를 한 번
# 더 태워** 그것이 비었다고 판정되는지를 묻는다. 부재 판정을 **문자열이 아니라 개수**로 하는 것이
# M51의 교훈이다 — PowerShell의 null 통과 캐스트에서 `-ne ''`가 참이 되어 두 사본이 갈렸다.
chk "N3: 표지 추출 positive-control / 없는 키는 비었다고 판정" \
    "$([ "$NSI" -gt 0 ] && echo ok || echo no)/$([ "$NSIABSENT" -gt 0 ] && echo ok || echo no)" "ok/no"
# (N4) **본 검사.** 선언 토큰 수와 표 행 수가 어긋나면 붉는다 — 목록이 늘 때 표가 따라오지 않는
# (또는 그 반대의) 드리프트를 잡는 자리다.
chk "N4: 본 검사 — 선언 토큰 수 == 표 행 수" "$(si_mismatch "$CONV")" "0"
# 픽스처 통제 둘 — **실제 판정을 픽스처에 건다**(M46 판례). **양쪽 방향을 각각 깨서** 건다.
chk "N5: 픽스처 통제 — 표에서 행이 사라지면 잡는다" "$(si_mismatch "$(si_fixture norow)")" "1"
chk "N6: 픽스처 통제 — 선언에서 토큰이 사라지면 잡는다" "$(si_mismatch "$(si_fixture notoken)")" "1"
chk "N7: 음성 통제 — 손대지 않은 사본은 붉지 않는다" "$(si_mismatch "$(si_fixture clean)")" "0"
# (N8)(N9) **소비자 대조 — 사본 0 · 참조 2.** 둘 중 하나만 성립하면 «아무것도 가리키지 않는 상태»나
# «복제가 남은 상태»가 되므로 **양쪽을 다 묻는다.**
chk "N8: 소비자 둘이 선언을 가리킨다 (status/fleet)" \
    "$([ "$(grep -cF 'status-items:' "$ROOT/skills/status/SKILL.md")" -gt 0 ] && echo ok || echo no)/$([ "$(grep -cF 'status-items:' "$ROOT/skills/fleet/SKILL.md")" -gt 0 ] && echo ok || echo no)" \
    "ok/ok"
chk "N9: 소비자에 옛 열거의 흔적이 없다 (status/fleet)" \
    "$(grep -cF 'M{N}-impl.md' "$ROOT/skills/status/SKILL.md")/$(grep -cF 'M{N}-impl.md' "$ROOT/skills/fleet/SKILL.md")" \
    "0/0"

# --- 자율 배선 선언 정합 (M52 리뷰 차단 1) ---------------------------------
# 안전 바닥의 **열거 자체**는 Part L이 물지만, **스킬 쪽에서 바닥 게이트에 자율 조건을 다는 편집**은
# 그 열거를 건드리지 않아 통과했다 — M52 리뷰가 사본 트리에서 실측했다(PR CI 확인 게이트에 한 문장을
# 더하고 목록은 그대로 두니 221/0 초록). 그래서 **자율이 어디에 걸리는가**를 규약이
# `autonomy-lines:`로 선언하고 실측과 대조한다. 적용 범위를 바꾸려면 선언을 함께 고쳐야 하고,
# 그 편집이 리뷰의 눈에 걸리는 것이 이 자리의 방어다(규약이 그 한계를 함께 적는다).
AUTLINES=$(markers_of 'autonomy-lines:' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ *$//')
AUTDEF=$(markers_of 'autonomy-default:' | head -1)
fi
auton_scan() { # <skills 루트> -> "이름=줄수" 를 ordinal 정렬해 한 줄로
    for _ad in "$1"/*/; do
        [ -f "$_ad/SKILL.md" ] || continue
        _ac=$(grep -c 'autonomy' "$_ad/SKILL.md")
        [ "$_ac" -gt 0 ] && printf '%s=%s\n' "$(basename "$_ad")" "$_ac"
    done | LC_ALL=C sort | tr '\n' ' ' | sed 's/ *$//'
}
auton_mismatch() { # <skills 루트> <선언 문자열> -> 다르면 1
    [ "$(auton_scan "$1")" = "$2" ] && echo 0 || echo 1
}
auton_fixture() { # <모드> -> 사본 skills 루트 (clean | extra | more)
    _af="$SBX/auton-$1"
    rm -rf "$_af"; mkdir -p "$_af"
    _adone=0
    for _at in $AUTLINES; do
        _an=${_at%%=*}; _ak=${_at##*=}
        if [ "$1" = "more" ] && [ "$_adone" = 0 ]; then _ak=$((_ak + 1)); _adone=1; fi
        mkdir -p "$_af/$_an"
        : > "$_af/$_an/SKILL.md"
        _ai=0
        while [ "$_ai" -lt "$_ak" ]; do
            echo 'autonomy' >> "$_af/$_an/SKILL.md"
            _ai=$((_ai + 1))
        done
    done
    if [ "$1" = "extra" ]; then
        mkdir -p "$_af/zzz-outside"
        echo 'autonomy' > "$_af/zzz-outside/SKILL.md"
    fi
    printf '%s' "$_af"
}
auton_default_ok() { # -> ok|no : 선언된 사이트 전부가 기본값 토큰을 문면에 갖는가
    # **빈 기본값은 no로 고정한다** — 빈 패턴은 `grep -F`에서 «항상 일치»라 표지가 사라지면 이 검사가
    # 조용히 통과하고, ps1의 `Contains($null)`은 반대로 0을 내 **두 사본이 갈린다**. 되돌림 `n10-key`가
    # 그 갈림을 실측했다(sh 228/1 · ps1 227/2). 판정을 여기서 같게 못박는다.
    [ -n "$AUTDEF" ] || { printf 'no'; return; }
    _ar=ok
    for _at in $AUTLINES; do
        _an=${_at%%=*}
        grep -qF "$AUTDEF" "$ROOT/skills/$_an/SKILL.md" || _ar=no
    done
    printf '%s' "$_ar"
}
# (N10) 부재의 의미를 선언 하나가 정하고, 그 값이 값 집합의 원소인지까지 **복합**으로 묻는다 —
# 집합 밖의 기본값은 "파일이 없으면 무슨 뜻인가"를 미정으로 만든다.
if part_on N; then
chk "N10: autonomy-default 선언 1개 / 값이 값 집합의 원소" \
    "$(decl_count "$CONV" 'autonomy-default:')/$(markers_of 'autonomy-level:' | grep -cx "$AUTDEF")" "1/1"
chk "N11: autonomy-lines 선언 줄 정확히 1개" "$(decl_count "$CONV" 'autonomy-lines:')" "1"
# (N12) **본 검사.** 자율 토큰을 가진 스킬과 그 줄 수가 선언과 어긋나면 붉는다.
chk "N12: 본 검사 - 자율 배선 실측 == autonomy-lines 선언" "$(auton_mismatch "$ROOT/skills" "$AUTLINES")" "0"
# 픽스처 통제 둘 — **실제 판정을 픽스처에 건다**(M46 판례). **양쪽 방향을 각각 깬다.**
chk "N13: 픽스처 통제 - 선언 밖 스킬이 자율 토큰을 가지면 잡는다" \
    "$(auton_mismatch "$(auton_fixture extra)" "$AUTLINES")" "1"
chk "N14: 픽스처 통제 - 선언된 스킬의 자율 줄이 늘면 잡는다" \
    "$(auton_mismatch "$(auton_fixture more)" "$AUTLINES")" "1"
chk "N15: 음성 통제 - 선언대로인 사본은 붉지 않는다" \
    "$(auton_mismatch "$(auton_fixture clean)" "$AUTLINES")" "0"
# (N16) 하위 호환의 계약 — **선언이 없는 저장소의 동작이 현행**임을 두 사이트가 문면에 갖는가.
chk "N16: 기본값 계약 - 선언된 스킬 전부가 기본값 토큰을 갖는다" "$(auton_default_ok)" "ok"
# (N17) fleet-cycle의 시작점 사본 — 참조 1 · 그 문단에 열거 0. **묻는 창은 그 문단 전체**다.
# 첫 판본은 창을 *"표지 줄부터 빈 줄까지"* 로 열었고, 되돌림 `n17-copy`가 **표지 줄 위에** 열거를
# 되살려 **229/0 초록으로 통과**시켰다 — 창이 한쪽으로만 열려 있으면 사본은 반대쪽에 산다.
# 이제 빈 줄로 끊은 **문단을 통째로** 모아 그 안에 표지가 있으면 열거를 센다(양방향).
chk "N17: fleet-cycle 시작점 - 참조 1 / 그 문단의 열거 0" \
    "$([ "$(grep -cF 'status-items:' "$ROOT/skills/fleet-cycle/SKILL.md")" -gt 0 ] && echo ok || echo no)/$(LC_ALL=C awk '
        function flush(   i) {
            if (has) {
                for (i = 1; i <= m; i++)
                    if (substr(buf[i], 1, 2) == "- " || substr(buf[i], 1, 3) == "  -") n++
            }
            has = 0; m = 0
        }
        $0 == "" { flush(); next }
        { buf[++m] = $0; if (index($0, "status-items:") > 0) has = 1 }
        END { flush(); print n + 0 }' "$ROOT/skills/fleet-cycle/SKILL.md")" "ok/0"
fi

# --- 바닥 표지 공존 금지 (M52 리뷰 라운드 1 차단 1) -------------------------
# `autonomy-lines:`가 세는 것은 **조건이 아니라 언급**이라, 조건을 한 게이트에서 다른 게이트로
# **옮기면 수가 보존돼 초록**이었다(리뷰 실측: 프리플라이트 3의 조건을 PR CI 게이트로 옮기고 229/0).
# 그래서 «자율이 **바닥 게이트에 붙었는가**»를 직접 묻는다 — 규약이 선언한 `floor-marks:`가 자율
# 토큰과 **같은 항목 창**에 있으면 붉는다. 창은 목록 항목(또는 빈 줄)에서 끊는다.
floor_marks() { # 선언 줄의 백틱 구획 토큰(공백을 포함할 수 있어 공백 분해를 쓰지 않는다)
    decl_tail "$CONV" 'floor-marks:' | LC_ALL=C awk -v q="\`" '{
        n = split($0, a, q)
        for (i = 2; i <= n; i += 2) if (a[i] != "") print a[i]
    }'
}
if part_on N; then
FLOORTAB=$(floor_marks | tr '\n' '\t')
NFLOOR=$(floor_marks | grep -c .)
fi
floor_hits_in() { # <SKILL.md 경로> → 자율 토큰과 바닥 표지가 같은 항목 창에 있는 창 수
    # **창은 들여쓰기를 안다**(재작업 3). 첫 판본은 «항목 줄이면 무조건 새 창»이라 **하위 불릿이 부모의
    # 창에서 빠져나갔고**, 바닥 게이트 항목 바로 아래에 하위 불릿으로 조건을 달면 표지와 다른 창이 되어
    # 초록이었다(리뷰 라운드 2 실측: 234/0). 이제 **더 깊은 들여쓰기의 항목은 부모 창에 남는다** —
    # 닫는 것이 «편집의 모양»이 아니라 «항목의 부분 트리»라 그 계열 전체가 함께 닫힌다.
    # 창은 ⑴ 같거나 얕은 들여쓰기의 항목 ⑵ 빈 줄 뒤에 오는 들여쓰기 0의 비-항목 줄에서 끊는다.
    # 들여쓰기는 **공백만** 센다(이 저장소의 마크다운에 탭이 없다 — 있으면 그 줄은 깊이 0으로 보인다).
    LC_ALL=C awk -v marks="$FLOORTAB" '
        function ind(s,   n) { n = 0; while (substr(s, n + 1, 1) == " ") n++; return n }
        function isitem(s,   t) {
            t = substr(s, ind(s) + 1)
            return (substr(t, 1, 2) == "- " || t ~ /^[0-9]+\. /)
        }
        function flush(   j) {
            if (auto) {
                for (j = 1; j <= nm; j++) if (MK[j] != "" && index(win, MK[j]) > 0) { hits++; break }
            }
            win = ""; auto = 0
        }
        BEGIN { nm = split(marks, MK, "\t"); cur = -1; pb = 1 }
        {
            if ($0 == "") { pb = 1; win = win "\n" $0; next }
            if (isitem($0)) {
                i = ind($0)
                if (cur < 0 || i <= cur) { flush(); cur = i }
            } else if (ind($0) == 0 && pb) {
                flush(); cur = -1
            }
            pb = 0
            win = win "\n" $0
            if (index($0, "autonomy") > 0) auto = 1
        }
        END { flush(); print hits + 0 }
    ' "$1"
}
floor_hits() { # <skills 루트> → 합계
    _fh=0
    for _fd in "$1"/*/; do
        [ -f "$_fd/SKILL.md" ] || continue
        _fh=$((_fh + $(floor_hits_in "$_fd/SKILL.md")))
    done
    echo "$_fh"
}
floor_fixture() { # <모드> → 사본 skills 루트 (clean | attach | nest)
    # `attach`는 **같은 항목 안**에 다는 모양, `nest`는 **하위 불릿**으로 다는 모양이다 — 리뷰 두
    # 라운드가 각각 실측한 두 형태를 픽스처가 둘 다 재현한다. 마지막 줄(프리플라이트 3)은 **표지가 없는
    # 정당한 자율 자리**라 어느 모드에서도 붉지 않아야 한다(음성 통제의 대상이 여기다).
    _ff="$SBX/floor-$1"
    rm -rf "$_ff"; mkdir -p "$_ff/rel"
    {
        printf -- '- 게시 분기 — 머지된 PR을 마무리한다.\n'
        printf -- '  PR CI 확인(`gh pr checks`)에서 실패가 있으면 사용자 확인을 받은 뒤 진행한다.\n'
        [ "$1" = "attach" ] && printf -- '  단 `.tide/autonomy`가 `continuous`면 확인 없이 진행한다.\n'
        [ "$1" = "nest" ] && printf -- '  - `.tide/autonomy`가 `continuous`면 위 확인 없이 진행한다.\n'
        printf -- '\n'
        printf -- '- 프리플라이트 3 — 무관 변경 확인. `.tide/autonomy`가 `continuous`면 확인 없이 진행한다.\n'
    } > "$_ff/rel/SKILL.md"
    printf '%s' "$_ff"
}
# (N18)(N19) 선언 줄 유일성과 **추출 positive-control** — 표지 추출이 비면 아래 본 검사가 «항상 0»으로
# 공허해진다. 백틱 구획 파싱이 망가지는 것이 그 경로라 수를 직접 단언한다.
if part_on N; then
chk "N18: floor-marks 선언 줄 정확히 1개" "$(decl_count "$CONV" 'floor-marks:')" "1"
chk "N19: 바닥 표지 추출 positive-control(>0)" "$([ "$NFLOOR" -gt 0 ] && echo ok || echo no)" "ok"
# (N20) **본 검사.** 자율 토큰이 바닥 표지와 같은 항목 창에 있으면 붉는다.
chk "N20: 본 검사 - 자율 토큰이 바닥 표지와 같은 창에 0건" "$(floor_hits "$ROOT/skills")" "0"
# 픽스처 통제 — **실제 판정을 픽스처에 건다**(M46 판례). `attach`가 리뷰가 실측한 「옮기는」 편집의 형태다.
chk "N21: 픽스처 통제 - 바닥 게이트에 자율 조건이 붙으면 잡는다" "$(floor_hits "$(floor_fixture attach)")" "1"
chk "N22: 음성 통제 - 붙지 않은 사본은 붉지 않는다" "$(floor_hits "$(floor_fixture clean)")" "0"
# (N23) **하위 불릿 형태** — 리뷰 라운드 2가 실측한 모양이다. 창이 들여쓰기를 모르면 이 사본이 초록이 된다.
chk "N23: 픽스처 통제 - 하위 불릿으로 달아도 잡는다" "$(floor_hits "$(floor_fixture nest)")" "1"

# --- 되돌림 축 선언 정합 (M53-T02) ------------------------------------------
# 되돌림의 방향이 둘(`broken`·`adversarial`)이라는 것을 규약이 선언하고, **각 축이 그 절 안에서 실제로
# 서술되는지**를 문다. 선언만 있고 서술이 없으면 «축이 있다»는 말만 남고 무엇을 하라는 것인지가
# 사라진다 — M53-T01 실측: 재작업 17라운드가 낳은 차단 25건 중 `adversarial` 방향이 연 것이 15건이고
# `broken` 방향이 연 것은 0건이었다. **묻는 방향이 한쪽이면 나머지는 통째로 뒤 단계로 미뤄진다.**
MAXES=$(decl_tail "$CONV" 'mutation-axes:' | LC_ALL=C awk -v q="\`" '{
    n = split($0, a, q)
    for (i = 2; i <= n; i += 2) if (a[i] != "") print a[i]
}')
NMAX=$(printf '%s\n' "$MAXES" | grep -c .)
fi
axis_desc_in() { # <규약 경로> <축 토큰> → **그 절 안에서** 그 축을 서술하는 줄 수
    # **창은 선언 줄부터 다음 최상위 체크리스트 항목 전까지다.** 파일 전역을 훑으면 서술을 **지우지
    # 않고 다른 절로 옮기는** 편집이 초록으로 지나간다 — 같은 피해에 이르는 다른 모양이고,
    # M53-T03의 **적대 변이 `adv-move`가 실측으로 그것을 보였다**(양 사본 240/0 초록). 이 저장소가
    # 창 경계에서 세 번 데인 자리라(M52 리뷰 라운드 1·2·3) 이번엔 impl 안에서 닫는다.
    LC_ALL=C awk -v ax="$2" '
        index($0, "mutation-axes:") > 0 { win = 1; next }
        win && $0 ~ /^[0-9]+\. / { win = 0 }
        win && substr($0, 1, 1) == "#" { win = 0 }
        win && index($0, "- **`" ax "`") > 0 { n++ }
        END { print n + 0 }
    ' "$1"
}
axis_missing() { # <규약 경로> → 서술이 없는 축의 수
    _am=0
    for _ax in $MAXES; do
        [ "$(axis_desc_in "$1" "$_ax")" -gt 0 ] || _am=$((_am + 1))
    done
    echo "$_am"
}
axis_fixture() { # <모드> → 사본 규약 경로 (clean | nodesc | moved)
    _axf="$SBX/axis-$1.md"
    case "$1" in
        nodesc) LC_ALL=C awk '{ if (index($0, "- **`adversarial`") > 0) sub(/adversarial/, "zzz-gone"); print }' \
                    "$CONV" > "$_axf" ;;
        moved)  LC_ALL=C awk '
                    index($0, "- **`adversarial`") > 0 && index($0, "mutation-axes:") == 0 { held = $0; next }
                    { print }
                    END { if (held != "") { print ""; print "## zzz-appendix"; print ""; print held } }
                ' "$CONV" > "$_axf" ;;
        *)      cat "$CONV" > "$_axf" ;;
    esac
    printf '%s' "$_axf"
}
if part_on N; then
chk "N24: mutation-axes 선언 줄 정확히 1개" "$(decl_count "$CONV" 'mutation-axes:')" "1"
# (N25) 추출 positive-control — 백틱 구획 파싱이 망가지면 아래 본 검사가 «축 0개»로 공허 통과한다.
chk "N25: 되돌림 축 추출 positive-control(>0)" "$([ "$NMAX" -gt 0 ] && echo ok || echo no)" "ok"
# (N26) **본 검사.** 선언된 축마다 그 축을 서술하는 줄이 있어야 한다.
chk "N26: 본 검사 - 서술이 없는 되돌림 축 0개" "$(axis_missing "$CONV")" "0"
# 픽스처 통제 — **실제 판정을 픽스처에 건다**(M46 판례).
chk "N27: 픽스처 통제 - 축의 서술이 사라지면 잡는다" "$(axis_missing "$(axis_fixture nodesc)")" "1"
chk "N28: 음성 통제 - 손대지 않은 사본은 붉지 않는다" "$(axis_missing "$(axis_fixture clean)")" "0"
# (N29) **적대 변이의 승격**(M53). 서술을 **지우지 않고 다른 절로 옮기는** 편집 — 적대 변이가 초록으로
# 열었던 자리이고, 창을 절로 좁혀 닫았다. 이 케이스가 없으면 **창을 되돌려도 아무것도 붉지 않는다**
# (실측: 창 좁히기를 되돌린 변이가 240/0 초록이었다). 규약의 「성립한 적대 변이는 픽스처로 승격한다」가
# 이 자리를 가리킨다.
chk "N29: 적대 통제 - 서술을 절 밖으로 옮기면 잡는다" "$(axis_missing "$(axis_fixture moved)")" "1"
fi

# `scope_tok`은 Part O(M69)와 Part W(M66~M68) **둘이 부른다** — 정의를 앞으로 올려 판정을 사본당
# 하나로 둔다(두 벌로 두면 한쪽만 고쳐 두 파트가 다른 답을 낼 수 있다).
scope_tok() { # <파일> <병기어> → 그 파일이 병기어를 **백틱 토큰**으로 가지면 yes
    has_token "$1" "$(printf '`%s`' "$2")"
}

# --- Part O: 회고 후속 항목의 소비 (M54) -------------------------------------
# 회고가 적은 후속 항목이 다음 사이클에 닿는지를 문다. 무는 것은 **선언의 유일성 · 상태 값의 집합
# 소속 · 소비자의 배선**까지이고, 처분이 타당한가는 리뷰의 영역이다(규약이 같은 경계를 적는다).
# (O15~O59 · M69·M70) **회고의 갱신 주기와 「집었다」 선언** — 위 O1~O14가 표의 **상태 값 집합**과 **창의
# 유일성**을 문다면, 아래는 그 창이 **낡았는지**와 마일스톤의 **선언이 추적되는지**를 묻는다.
# 백스톱은 `CHANGELOG.md`의 최상단 릴리즈 노트 버전이다 — 버전 파일은 프로젝트마다 달라 경로를 박을 수
# 없고(`bk-version-file`이 추상 토큰인 사유), CHANGELOG는 `bk-changelog`로 선언돼 있다.
nth_ver() { # <파일> <줄 접두> <n> → 그 접두로 시작하는 **n번째 줄**의 `(v` 또는 `[v` 뒤 숫자·점 토큰
    # 한글 낱말(「시점」 등)을 매칭하지 않는다 — `.ps1` 사본이 같은 판정을 쓸 수 없기 때문이다.
    [ -f "$1" ] || return 0
    LC_ALL=C awk -v pfx="$2" -v n="$3" '
        substr($0, 1, length(pfx)) == pfx && ++c == n {
            i = index($0, "(v"); if (i == 0) i = index($0, "[v")
            if (i == 0) exit
            t = substr($0, i + 2); v = ""
            for (k = 1; k <= length(t); k++) { c = substr(t, k, 1); if (c ~ /[0-9.]/) v = v c; else break }
            print v; exit
        }' "$1"
}
first_ver() { nth_ver "$1" "$2" 1; }
backstop_verdict() { # <회고 버전> <CHANGELOG 첫 버전> <CHANGELOG 둘째 버전> <최대 번호 마일스톤의 기반 버전> → ok|no
    # **릴리즈 커밋을 정상으로 받는다(M69 리뷰 라운드 1 차단 1 · 라운드 2 차단 1)** — release는 CHANGELOG를
    # 올려 커밋하고 자동 회고는 태그 **뒤**에 돌므로, 릴리즈 커밋의 트리는 언제나 「회고 = CHANGELOG 둘째」다.
    # 둘째와의 같음은 **최대 번호 마일스톤이 CHANGELOG 첫째 위에 서지 않았을 때만** 받는다 — 첫째 위에 섰다면
    # 그 릴리즈 뒤 새 마일스톤이 세워졌는데 회고는 그 릴리즈를 모르는 것, 곧 **회고를 건너뛴 것**이다.
    # 라운드 2는 이 자리를 「최대 번호의 review 보고서 존재」로 물었고, 리뷰 없이 생기는 릴리즈 커밋(마일스톤
    # 초안 뒤 debug 릴리즈 · 강행)에서 붉었다. 기반 버전은 리뷰 유무와 무관하다. 기반 버전이 비면 막지 않는다.
    if [ -n "$1" ] && [ "$1" = "$2" ]; then echo ok; return; fi
    if [ -n "$1" ] && [ "$1" = "$3" ] && [ "$4" != "$2" ]; then echo ok; return; fi
    echo no
}
BASE_KEY='- 기반 버전:'
doc_base() { # <마일스톤 문서> → 그 문서의 `- 기반 버전:` 값에서 `v` 뒤 숫자·점 토큰(없으면 빈 출력)
    # 키는 `skills/milestone/template.md` 메타데이터의 그 줄이다. ps1 사본은 같은 키를 코드포인트로 만든다.
    [ -f "$1" ] || return 0
    LC_ALL=C awk -v pfx="$BASE_KEY" '
        substr($0, 1, length(pfx)) == pfx {
            t = substr($0, length(pfx) + 1); sub(/^[ \t]+/, "", t)
            if (substr(t, 1, 1) != "v") exit
            t = substr(t, 2); v = ""
            for (k = 1; k <= length(t); k++) { c = substr(t, k, 1); if (c ~ /[0-9.]/) v = v c; else break }
            print v; exit
        }' "$1"
}
base_ver() { # [마일스톤 디렉터리] → 최대 번호 마일스톤 문서의 기반 버전
    _bd=${1:-$MDIR}
    _bm=$(mst_max "$_bd")
    [ -n "$_bm" ] || return 0
    doc_base "$_bd/M$_bm.md"
}
ver_rank() { # <CHANGELOG> <버전> → 그 버전을 가진 `### [` 머리의 자리(1이 최신 · 없으면 빈 출력)
    # **자리로 비교한다** — 버전 수의 대소를 재지 않는다(백스톱과 같은 사유 · 규약 "회고 후속 항목의 소비" 절).
    [ -f "$1" ] && [ -n "$2" ] || return 0
    LC_ALL=C awk -v want="$2" '
        substr($0, 1, 5) == "### [" {
            n++
            i = index($0, "[v"); if (i == 0) next
            t = substr($0, i + 2); v = ""
            for (k = 1; k <= length(t); k++) { c = substr(t, k, 1); if (c ~ /[0-9.]/) v = v c; else break }
            if (v == want) { print n; exit }
        }' "$1"
}
doc_claims() { # <마일스톤 문서> → 그 문서의 첫 `- retro-rows:` 줄의 키 한 줄씩
    LC_ALL=C awk '/^- retro-rows:/ { sub(/^- retro-rows:[ \t]*/, ""); sub(/\r$/, ""); print; exit }' "$1" |
        LC_ALL=C tr ' \t' '\n\n' | grep .
}
doc_released() { # <마일스톤 문서> → 첫 `- released:` 줄(릴리즈 표지)의 `v` 뒤 숫자·점 토큰(없으면 빈 출력)
    [ -f "$1" ] || return 0
    LC_ALL=C awk '
        substr($0, 1, 11) == "- released:" {
            t = substr($0, 12); sub(/^[ \t]+/, "", t)
            if (substr(t, 1, 1) != "v") exit
            t = substr(t, 2); v = ""
            for (k = 1; k <= length(t); k++) { c = substr(t, k, 1); if (c ~ /[0-9.]/) v = v c; else break }
            print v; exit
        }' "$1"
}
mst_num() { # <마일스톤 문서> → `M{숫자}.md`면 그 숫자, 아니면 빈 출력(대소문자 구분 — ps1 사본은 `-cmatch`)
    _nn=$(basename "$1" .md)
    case "$_nn" in M*) ;; *) return 0 ;; esac
    _nn=${_nn#M}
    case "$_nn" in ''|*[!0-9]*) return 0 ;; esac
    echo "$_nn"
}
target_claims() { # <마일스톤 디렉터리> <회고 버전> <CHANGELOG> <표지 도입 번호> → stale 대상의 선언 키(정렬)
    # **번호가 도입 번호 이상이면 릴리즈 표지로 가린다** — 표지 머리가 회고 머리와 같거나 아래(자리 수가 크거나
    # 같음)면 대상이다. 표지가 없으면 대상이 아니다(진행 중 · debug만 나간 사이클 — M70 리뷰 라운드 0 차단).
    # **그 미만은 기반 버전으로 가린다** — 기반 머리가 회고 머리보다 아래면 대상이다(표지가 없던 시절의 릴리즈된
    # 마일스톤). 최대 번호는 신호가 아니다. 두 자리 중 하나라도 비면 대상이 아니다(`O41`이 따로 문다).
    _tr=$(ver_rank "$3" "$2")
    [ -n "$_tr" ] || return 0
    for _tf in "$1"/M*.md; do
        [ -f "$_tf" ] || continue
        _tn=$(mst_num "$_tf")
        [ -n "$_tn" ] || continue
        if [ "$_tn" -ge "$4" ]; then
            _tb=$(ver_rank "$3" "$(doc_released "$_tf")")
            [ -n "$_tb" ] || continue
            [ "$_tr" -le "$_tb" ] && doc_claims "$_tf"
        else
            _tb=$(ver_rank "$3" "$(doc_base "$_tf")")
            [ -n "$_tb" ] || continue
            [ "$_tr" -lt "$_tb" ] && doc_claims "$_tf"
        fi
    done | LC_ALL=C sort
}
claim_base_missing() { # <마일스톤 디렉터리> <CHANGELOG> <표지 도입 번호> → 선언 문서 중 판정 값이 머리에 없는 수
    # 판정 값 = 도입 번호 이상이면 **표지가 있을 때** 표지, 그 미만이면 기반 버전. 파일 이름 거름은 `target_claims`와
    # 같다(M70 리뷰 라운드 0 사소 2).
    _cb=0
    for _cf in "$1"/M*.md; do
        [ -f "$_cf" ] || continue
        _cn=$(mst_num "$_cf")
        [ -n "$_cn" ] || continue
        LC_ALL=C grep -q '^- retro-rows:' "$_cf" 2>/dev/null || continue
        if [ "$_cn" -ge "$3" ]; then
            _cv=$(doc_released "$_cf")
            LC_ALL=C grep -q '^- released:' "$_cf" 2>/dev/null || continue
        else
            _cv=$(doc_base "$_cf")
        fi
        [ -n "$(ver_rank "$2" "$_cv")" ] || _cb=$((_cb + 1))
    done
    echo "$_cb"
}
mark_dup() { # <마일스톤 디렉터리> → `- released:` 줄이 둘 이상인 문서 수
    _kd=0
    for _kf in "$1"/M*.md; do
        [ -f "$_kf" ] || continue
        [ -n "$(mst_num "$_kf")" ] || continue
        _kc=$(LC_ALL=C grep -c '^- released:' "$_kf" 2>/dev/null)
        [ "${_kc:-0}" -gt 1 ] && _kd=$((_kd + 1))
    done
    echo "$_kd"
}
target_fixture() { # → 합성 마일스톤 일곱(표지 도입 번호 5로 읽는다)
    # M1~M4 기반 버전 규칙: M1 v1.0.0 k1 · M2 v2.0.0 k2 · M3 v3.0.0 k3 · M4 v9.9.9 k4(머리 없음).
    # M5~M7 표지 규칙(기반은 전부 v2.0.0): M5 표지 없음 k5(진행 중 · debug만 나감) · M6 표지 v3.0.0 k6 ·
    # M7 표지 v8.8.8 k7(머리 없음). **도입 번호 자리(M5)에 표지 없는 문서**를 두어 `>=`와 `>`를 가른다 — `>`면 M5가
    # 기반 규칙으로 떨어져 회고 v3.0.0에서 대상이 된다(M70 리뷰 라운드 3 권장 3).
    _gf="$SBX/target-milestones"
    mkdir -p "$_gf"
    for _gi in 1:1.0.0 2:2.0.0 3:3.0.0 4:9.9.9 5:2.0.0 6:2.0.0 7:2.0.0; do
        _gn=${_gi%%:*}; _gv=${_gi#*:}
        printf '%s\n' "# M$_gn" "$BASE_KEY v$_gv" "- retro-rows: k$_gn" > "$_gf/M$_gn.md"
    done
    printf '%s\n' '- released: v3.0.0' >> "$_gf/M6.md"
    printf '%s\n' '- released: v8.8.8' >> "$_gf/M7.md"
    printf '%s' "$_gf"
}
markdup_fixture() { # → 표지 줄이 둘인 문서 하나를 가진 디렉터리
    _mf2="$SBX/markdup-milestones"
    mkdir -p "$_mf2"
    printf '%s\n' '# M1' '- released: v1.0.0' '- released: v2.0.0' > "$_mf2/M1.md"
    printf '%s' "$_mf2"
}
mark_gap() { # <마일스톤 디렉터리> <보고서 디렉터리> <표지 도입 번호> → 표지 누락 수
    # **표지가 있는 마일스톤 아래의 누락**(M70 리뷰 라운드 1 차단 갈래 ⓐ) — 표지 대상은 「이번 태그에 실리는
    # 마일스톤 전부」(번호 >= 도입 번호 · impl 보고서 있음 · 표지 없음)라, 표지가 선 마일스톤보다 번호가 작은데
    # 그 조건을 갖춘 문서는 그 릴리즈가 함께 표지했어야 한다 — **한 릴리즈가 일부만 표지하고 아래를 건너뛴** 경우다.
    # 가장 큰 표지 번호 **위**는 묻지 않는다. 릴리즈가 표지를 **통째로** 빠뜨리면 다음 표지 릴리즈가 자기 버전으로
    # 메워 여기 닿지 않는다(규약의 경계 — M70 리뷰 라운드 2 차단). 표지 유무는 `mark_dup`과 같은 줄 접두로 본다.
    _gt=0
    for _gf in "$1"/M*.md; do
        [ -f "$_gf" ] || continue
        _gn=$(mst_num "$_gf")
        [ -n "$_gn" ] || continue
        LC_ALL=C grep -q '^- released:' "$_gf" 2>/dev/null || continue
        [ "$_gn" -gt "$_gt" ] && _gt=$_gn
    done
    _gc=0
    for _gf in "$1"/M*.md; do
        [ -f "$_gf" ] || continue
        _gn=$(mst_num "$_gf")
        [ -n "$_gn" ] || continue
        [ "$_gn" -ge "$3" ] || continue
        [ "$_gn" -lt "$_gt" ] || continue
        [ -f "$2/M$_gn-impl.md" ] || continue
        LC_ALL=C grep -q '^- released:' "$_gf" 2>/dev/null && continue
        _gc=$((_gc + 1))
    done
    echo "$_gc"
}
gap_fixture() { # <gap|clean> → 마일스톤 일곱과 impl 보고서를 가진 디렉터리(표지 도입 번호 5로 읽는다)
    # M4 impl · 표지 없음(도입 번호 미만) · M5 impl · 표지 없음(gap)/v1.0.0(clean) · M6 impl · 표지 v1.0.0 ·
    # M7 impl · 표지 없음(gap)/v2.0.0(clean) · M8 초안(impl 없음 · 표지 없음) · M9 impl · 표지 v2.0.0 ·
    # M10 impl · 표지 없음(가장 큰 표지 위 — 진행 중). gap이면 누락은 M5 · M7 둘이다.
    # - 표지를 둘 이상(M6 · M9) 두어 「가장 큰 표지」와 「가장 작은 표지」를 가른다(M70 리뷰 라운드 2 권장 3 — 가장 작은
    #   표지 M6을 쓰면 M7이 그 위라 1이 나온다).
    # - **도입 번호 자리(M5)에 impl 있는 무표지**를 두어 `>=`와 `>`를 가른다(M70 리뷰 라운드 3 권장 3 — `>`면 M5가 빠져 1).
    _pf="$SBX/gap-$1"
    mkdir -p "$_pf/m" "$_pf/r"
    for _pn in 4 5 6 7 8 9 10; do
        printf '%s\n' "# M$_pn" > "$_pf/m/M$_pn.md"
        [ "$_pn" = 8 ] || printf '%s\n' "# M$_pn impl" > "$_pf/r/M$_pn-impl.md"
    done
    printf '%s\n' '- released: v1.0.0' >> "$_pf/m/M6.md"
    printf '%s\n' '- released: v2.0.0' >> "$_pf/m/M9.md"
    if [ "$1" = clean ]; then
        printf '%s\n' '- released: v1.0.0' >> "$_pf/m/M5.md"
        printf '%s\n' '- released: v2.0.0' >> "$_pf/m/M7.md"
    fi
    printf '%s' "$_pf"
}
mark_since() { # <마일스톤 디렉터리> → 표지가 있는 마일스톤 중 가장 작은 번호(없으면 빈 출력)
    # **대상 레포의 도입 번호 파생**(`mark-since-derived` · M70 리뷰 라운드 3 차단) — 선언이 없는 레포는 이 값을 쓴다.
    # 이 저장소에서는 선언과 같아야 한다(도입 번호 미만의 소급 표지가 여기서 붉다). 표지 유무는 `mark_dup`과 같은 줄 접두다.
    _sm=""
    for _sf in "$1"/M*.md; do
        [ -f "$_sf" ] || continue
        _sn=$(mst_num "$_sf")
        [ -n "$_sn" ] || continue
        LC_ALL=C grep -q '^- released:' "$_sf" 2>/dev/null || continue
        if [ -z "$_sm" ] || [ "$_sn" -lt "$_sm" ]; then _sm=$_sn; fi
    done
    printf '%s' "$_sm"
}
chlog_fixture() { # → 릴리즈 노트 머리 셋(v3.0.0 · v2.0.0 · v1.0.0)을 가진 **합성** CHANGELOG
    # 실제 CHANGELOG 값에 기대지 않는다 — 릴리즈 커밋 트리에서도 통제가 같은 답을 내야 한다.
    _cf="$SBX/chlog-fixture.md"
    printf '%s\n' '# Changelog' '<!-- [start:notes] ### [v9.9.9] distractor -->' '' \
        '### [v3.0.0]' '' '- c' '' '### [v2.0.0]' '' '- b' '' '### [v1.0.0]' '' '- a' > "$_cf"
    printf '%s' "$_cf"
}
base_fixture() { # → 마일스톤 두 개(M9 기반 v1.0.0 · M10 기반 v2.0.0)를 가진 디렉터리
    # 번호를 9·10으로 두는 이유: 문자열 정렬이면 M9가 최대로 뽑혀 v1.0.0이 나온다(수 정렬 회귀를 문다).
    _bf="$SBX/base-milestones"
    mkdir -p "$_bf"
    printf '%s\n' '# M9' "$BASE_KEY v1.0.0" > "$_bf/M9.md"
    printf '%s\n' '# M10' "$BASE_KEY v2.0.0 (note)" > "$_bf/M10.md"
    printf '%s' "$_bf"
}
retro_pairs() { # <retro 경로> → 마커 창 안 데이터 행의 "<행 키> <상태 값>" 한 줄씩
    # 행 키는 `항목` 셀 머리의 **첫 백틱 구획**이다(`absent-job-anchor:` 추출과 같은 형태) — 제목
    # 텍스트를 키로 쓰지 않는 사유는 규약이 적는다(회고가 제목을 다듬는다).
    [ -f "$1" ] || return 0
    LC_ALL=C awk -v mk="$RBLK" -v q='`' '
        mk == "" { exit }
        index($0, "<!-- " mk ":start -->") > 0 { inb = 1; sep = 0; next }
        index($0, "<!-- " mk ":end -->") > 0 { inb = 0; next }
        inb && sep == 0 { if (index($0, "---") > 0) sep = 1; next }
        inb && substr($0, 1, 1) == "|" {
            n = split($0, f, "|")
            if (n < 5) next
            m = split(f[2], a, q)
            if (m < 3 || a[2] == "") next
            v = f[4]
            gsub(/\r/, "", v); gsub(/\*/, "", v); gsub(/ /, "", v)
            pp = index(v, "(")
            if (pp > 0) v = substr(v, 1, pp - 1)
            print a[2] " " v
        }
    ' "$1"
}
retro_keys() { retro_pairs "$1" | LC_ALL=C awk '{ print $1 }'; }
MDIR="$ROOT/docs/milestones"
mst_max() { # [마일스톤 디렉터리] → 마일스톤 문서의 최대 번호(없으면 빈 출력)
    # 번호는 **문자열 그대로** 낸다(`base_ver`가 그 문자열로 문서 경로를 만든다 — ps1 사본과 같은 형태).
    LC_ALL=C ls "${1:-$MDIR}" 2>/dev/null |
        LC_ALL=C sed -n 's/^M\([0-9][0-9]*\)\.md$/\1/p' | LC_ALL=C sort -n | tail -1
}
mst_claims() { # [마일스톤 디렉터리] → 선언된 행 키 한 줄씩(전 문서)
    # 파일 이름은 `M{숫자}.md`만 받는다 — ps1 사본의 거름과 같은 형태다(M69 리뷰 라운드 1 사소 6).
    # stale 대상 선택은 여기서 하지 않는다 — `target_claims`가 기반 버전 자리로 가린다(M70).
    _md=${1:-$MDIR}
    for _mf in "$_md"/M*.md; do
        [ -f "$_mf" ] || continue
        _mn=$(basename "$_mf" .md); _mn=${_mn#M}
        case "$_mn" in ''|*[!0-9]*) continue ;; esac
        doc_claims "$_mf"
    done
}
mst_claim_docs() { # [마일스톤 디렉터리] → `- retro-rows:` 선언 줄을 **가진** 마일스톤 문서의 수
    # `mst_claims` 추출의 positive-control용이다. 무조건 「추출 > 0」을 요구하면 **소음 0 계약과 충돌**한다
    # (선언을 쓰지 않는 저장소의 정상 트리가 붉는다) — 그래서 **조건부**로 묻는다: 선언 줄을 가진 문서가
    # 하나라도 있으면 추출이 0이어서는 안 된다(M69 리뷰 권장 6).
    LC_ALL=C grep -l '^- retro-rows:' "${1:-$MDIR}"/M*.md 2>/dev/null | grep -c .
}
claim_extract_ok() { # <마일스톤 디렉터리> → ok|no (`O31`의 판정 — `O35`가 선언 없는 사본에 **같은 함수**를 먹인다)
    if [ "$(mst_claim_docs "$1")" -eq 0 ] || [ "$(mst_claims "$1" | grep -c .)" -gt 0 ]; then echo ok; else echo no; fi
}
silence_fixture() { # → 실제 마일스톤 문서 둘(M1 · 최대 번호)에서 `- retro-rows:` 줄을 지운 사본 디렉터리
    _sf="$SBX/silence-milestones"
    mkdir -p "$_sf"
    for _sn in 1 "$(mst_max)"; do
        [ -f "$MDIR/M$_sn.md" ] || continue
        LC_ALL=C grep -v '^- retro-rows:' "$MDIR/M$_sn.md" > "$_sf/M$_sn.md"
    done
    printf '%s' "$_sf"
}
mst_claim_lines() { # <마일스톤 문서> → 그 문서의 `- retro-rows:` 줄 수 (선언 유일성용)
    # `grep -c`는 매치가 0이어도 `0`을 **출력하고** exit 1이다 — `|| echo 0`을 붙이면 `0`이 두 줄이 되어
    # 호출부의 `-gt`가 오류로 거짓이 된다(M69 리뷰 라운드 1 권장 2의 실측: stderr 68쌍).
    _cl=$(LC_ALL=C grep -c '^- retro-rows:' "$1" 2>/dev/null)
    echo "${_cl:-0}"
}
mst_claim_dup() { # → `- retro-rows:` 줄이 **둘 이상**인 마일스톤 문서의 수
    _md=0
    for _mf in "$ROOT"/docs/milestones/M*.md; do
        [ -f "$_mf" ] || continue
        [ "$(mst_claim_lines "$_mf")" -gt 1 ] && _md=$((_md + 1))
    done
    echo "$_md"
}
mst_claim_empty() { # → `- retro-rows:` 줄이 있는데 **값이 빈** 문서의 수(규약이 빈 값을 금지한다)
    _me=0
    for _mf in "$ROOT"/docs/milestones/M*.md; do
        [ -f "$_mf" ] || continue
        # 공백·탭·CR을 양끝에서 벗긴다 — ps1 사본의 `Trim(' ', TAB, CR)`과 같은 집합이다(라운드 1 사소 5).
        _mv=$(LC_ALL=C awk '/^- retro-rows:/ { sub(/^- retro-rows:/, ""); gsub(/^[ \t\r]+|[ \t\r]+$/, ""); print; exit }' "$_mf")
        LC_ALL=C grep -q '^- retro-rows:' "$_mf" 2>/dev/null || continue
        [ -z "$_mv" ] && _me=$((_me + 1))
    done
    echo "$_me"
}
retro_key_dup() { # <retro 경로> → 같은 행 키가 두 번 이상 나오는 키의 수
    retro_keys "$1" | LC_ALL=C sort | LC_ALL=C uniq -d | grep -c .
}
claim_missing() { # <retro 경로> <행 키 목록> → 그 표에 **없는** 키의 수
    # 키 목록을 인자로 받는 이유는 **통제 때문**이다 — 선언한 마일스톤이 최대 번호 하나뿐이면 대상이
    # 비어 판정이 늘 0이 되고 통제가 아무것도 묻지 못한다. 픽스처는 **같은 함수**에 키를 먹인다.
    # **고정 문자열로 비교한다** — `grep -qx`만 쓰면 BRE라 `rf.02`의 `.`이 임의 문자가 되어
    # `rf-02`에 매치되고, ps1 사본은 ordinal이라 붉는다(M69 리뷰 차단 2의 실측). `-F`가 그 갈림을 닫는다.
    # 루프의 `$2`는 **인용한다** — 인용하지 않으면 키가 경로 확장까지 받는다.
    _cm=0
    _ck=$(retro_keys "$1")
    set -f
    for _c in $2; do
        printf '%s\n' "$_ck" | LC_ALL=C grep -qxF -- "$_c" || _cm=$((_cm + 1))
    done
    set +f
    echo "$_cm"
}
claim_stale() { # <retro 경로> <행 키 목록> → 그 표에서 상태가 「아직 아무도 집지 않은 것」인 키의 수
    # 비교는 `awk`의 `==`라 바이트 일치다(ps1 사본은 `StringComparison::Ordinal`로 맞췄다).
    # `set -f`는 키가 글로브 문자를 담아도 경로 확장을 받지 않게 한다(위 `claim_missing`과 같은 사유).
    _cs=0
    _cp=$(retro_pairs "$1")
    set -f
    for _c in $2; do
        _st=$(printf '%s\n' "$_cp" | LC_ALL=C awk -v k="$_c" '$1 == k { print $2; exit }')
        [ "$_st" = "$RUNDONE" ] && _cs=$((_cs + 1))
    done
    set +f
    echo "$_cs"
}
key_with_stat() { # <retro 경로> <상태 값> → 그 상태인 **첫 행의 키**(없으면 빈 출력)
    retro_pairs "$1" | LC_ALL=C awk -v s="$2" '$2 == s { print $1; exit }'
}
retro_out_fixture() { # 마커 창 **밖**에 행 키를 가진 행을 하나 덧붙인 사본
    # 창을 최상단 섹션 밖으로 넓히는 회귀를 무는 자리다. 과거 섹션 표에는 행 키가 없어 창을 넓혀도
    # 키 집합이 변하지 않으므로(구현 중 실측: 넓힌 변이가 초록이었다) **키 있는 행을 밖에 둬야** 갈린다.
    _ro="$SBX/retro-outside.md"
    cat "$RETRO" > "$_ro"
    printf '| `%s` **zzz** | zzz | **%s** | zzz |\n' zzz-outside "$RUNDONE" >> "$_ro"
    printf '%s' "$_ro"
}
retro_ver_fixture() { # <모드> → 사본 경로 (badver: **최상단 섹션의 기준 버전만** 바꾼다)
    _rv="$SBX/retro-$1.md"
    LC_ALL=C awk -v mode="$1" '
        done == 0 && substr($0, 1, 3) == "## " {
            done = 1
            if (mode == "badver") { sub(/\(v[0-9.]*/, "(v0.0.0") }
        }
        { print }
    ' "$RETRO" > "$_rv"
    printf '%s' "$_rv"
}
if part_on O; then
RETRO="$ROOT/docs/reports/retro.md"
# **꼬리를 정규화한다** — 앞뒤·중복 공백을 남기면 빈 값 검사에서 ` ` + `` + ` ` 가 선언 줄의
# 선행 공백과 맞아떨어져 **빈 상태 칸이 조용히 통과한다**(실측: O6이 got 0/want 1로 붉었다).
RSTAT=$(decl_tail "$CONV" 'retro-status:' | LC_ALL=C awk '{ $1 = $1; print }')
RBLK=$(decl_tail "$CONV" 'retro-block:' | LC_ALL=C awk '{ print $1 }')
RFIRST=$(printf '%s' "$RSTAT" | LC_ALL=C awk '{ print $1 }')
RCAD=$(decl_tail "$CONV" 'retro-cadence:' | LC_ALL=C awk '{ print $1 }')
[ -n "$RCAD" ] || RCAD=zzz-retro-cadence-unset
RPICK=$(decl_tail "$CONV" 'retro-pick:' | LC_ALL=C awk '{ print $1 }')
[ -n "$RPICK" ] || RPICK=zzz-retro-pick-unset
CHLOG="$ROOT/CHANGELOG.md"
# **상태 값은 선언에서 자리로 집는다** — `.ps1` 사본이 비-ASCII를 담을 수 없어 값을 글자로 쓸 수 없다.
# 두 번째 토큰이 「아직 아무도 집지 않은 것」이며, 선언 순서의 단일 원본은 규약의 `retro-status:` 줄이다
# (`RFIRST`가 첫 토큰을 같은 방식으로 집는 것과 같은 형태).
RUNDONE=$(printf '%s' "$RSTAT" | LC_ALL=C awk '{ print $2 }')
fi
retro_vals() { # <retro 경로> → 마커 창 안 데이터 행의 상태 값(정규화)을 `[값]`으로 한 줄씩
    # **창은 ASCII 마커 블록이다** — 절 제목(한글)을 매칭하면 제목이 바뀔 때 조용히 창을 잃고
    # `run.ps1` 사본이 byte>127=0 규율 아래 같은 판정을 쓸 수 없다(에픽 블록과 같은 근거).
    # 머리글 건너뛰기도 구조로 한다 — 창 안에서 구분선(`---`)을 본 **뒤의** 행만 데이터다.
    # 값을 `[ ]`로 감싸 내보내는 것은 **빈 값이 단어 분리에서 사라지지 않게** 하기 위함이다.
    [ -f "$1" ] || return 0
    LC_ALL=C awk -v mk="$RBLK" '
        mk == "" { exit }
        index($0, "<!-- " mk ":start -->") > 0 { inb = 1; sep = 0; next }
        index($0, "<!-- " mk ":end -->") > 0 { inb = 0; next }
        inb && sep == 0 { if (index($0, "---") > 0) sep = 1; next }
        inb && substr($0, 1, 1) == "|" {
            n = split($0, f, "|")
            if (n < 5) next
            v = f[4]
            gsub(/\r/, "", v); gsub(/\*/, "", v); gsub(/ /, "", v)
            pp = index(v, "(")
            if (pp > 0) v = substr(v, 1, pp - 1)
            print "[" v "]"
        }
    ' "$1"
}
retro_rows() { retro_vals "$1" | grep -c .; }
retro_bad() { # <retro 경로> → 선언 집합 밖인 행의 수 (**빈 값도 밖으로 센다**)
    # 비우는 것이 지우는 것보다 조용한 경로다 — 빈 값을 통과시키면 이 검사가 그 자리에서 공허해진다.
    _rb=0
    for _rv in $(retro_vals "$1"); do
        _rt=${_rv#[}; _rt=${_rt%]}
        case " $RSTAT " in
            *" $_rt "*) ;;
            *) _rb=$((_rb + 1)) ;;
        esac
    done
    echo "$_rb"
}
retro_fixture() { # <모드> → 사본 경로 (clean | outset | blank | paren | dup)
    # **첫 데이터 행 하나만** 건드린다 — 판정이 그 한 행에서 갈리는지 보려는 것이다.
    _rf="$SBX/retro-$1.md"
    LC_ALL=C awk -v mk="$RBLK" -v mode="$1" -v ok1="$RFIRST" '
        index($0, "<!-- " mk ":start -->") > 0 { inb = 1; sep = 0; print; next }
        index($0, "<!-- " mk ":end -->") > 0 { inb = 0; print; next }
        inb && sep == 0 { if (index($0, "---") > 0) sep = 1; print; next }
        inb && done == 0 && substr($0, 1, 1) == "|" {
            n = split($0, f, "|")
            if (n >= 5 && mode != "clean") {
                done = 1
                if (mode == "outset") f[4] = " zzz-gone "
                else if (mode == "blank") f[4] = "  "
                else if (mode == "paren") f[4] = " **" ok1 "(zzz-note)** "
                line = f[1]
                for (i = 2; i <= n; i++) line = line "|" f[i]
                print line; next
            }
        }
        { print }
        END {
            if (mode == "dup") {
                print ""
                print "<!-- " mk ":start -->"
                print ""
                print "| item | source | status | where |"
                print "|---|---|---|---|"
                print "| zzz-dup | zzz | " ok1 " | zzz |"
                print "<!-- " mk ":end -->"
            }
        }
    ' "$RETRO" > "$_rf"
    printf '%s' "$_rf"
}
mst_hits() { # 선언된 상태 값 중 milestone 스킬에 등장하는 **서로 다른** 값의 수
    _mh=0
    for _mv in $RSTAT; do
        grep -qF -- "$_mv" "$ROOT/skills/milestone/SKILL.md" && _mh=$((_mh + 1))
    done
    echo "$_mh"
}
if part_on O; then
chk "O1: retro-status 선언 줄 정확히 1개" "$(decl_count "$CONV" 'retro-status:')" "1"
chk "O2: retro-block 선언 줄 정확히 1개" "$(decl_count "$CONV" 'retro-block:')" "1"
# (O3) 추출 positive-control — 마커·표 파싱이 망가지면 아래 본 검사가 «행 0개»로 공허 통과한다.
chk "O3: 후속 항목 행 추출 positive-control(>0)" "$([ "$(retro_rows "$RETRO")" -gt 0 ] && echo ok || echo no)" "ok"
# (O4) **본 검사.** 표의 상태 값이 전부 선언 집합 안이어야 한다.
chk "O4: 본 검사 - 선언 집합 밖 상태 값 0개" "$(retro_bad "$RETRO")" "0"
# 픽스처 통제 — **실제 판정을 픽스처에 건다**(M46 판례). 두 방향을 각각 깬다.
chk "O5: 픽스처 통제 - 집합 밖 값을 잡는다" "$(retro_bad "$(retro_fixture outset)")" "1"
chk "O6: 픽스처 통제 - 상태 칸을 비워도 잡는다" "$(retro_bad "$(retro_fixture blank)")" "1"
chk "O7: 음성 통제 - 손대지 않은 사본은 붉지 않는다" "$(retro_bad "$(retro_fixture clean)")" "0"
# (O8) 부재 통제 — 회고 문서가 없는 저장소에서 이 파트는 **침묵**한다(소음 0 계약의 기계 확인).
chk "O8: 부재 통제 - 회고 문서가 없으면 행 0개" "$(retro_rows "$SBX/zzz-no-retro.md")" "0"
# (O9) **오탐 방향.** 정상 문서를 붉히지 않는가 — 집합 안 값에 괄호 주석이 붙은 형태는 정상이다.
# 정규화가 깨지면 여기서 붉는다(M49의 차단이 이 방향의 빈자리에서 나왔다).
chk "O9: 오탐 방향 - 괄호 주석이 붙은 집합 안 값은 통과" "$(retro_bad "$(retro_fixture paren)")" "0"
# (O10·O11) 소비자의 배선. 읽는다는 사실은 있어야 하고, **규칙을 다시 열거하면 안 된다**.
chk "O10: milestone 스킬이 회고 문서를 가리킨다" "$([ "$(grep -cF -- 'docs/reports/retro.md' "$ROOT/skills/milestone/SKILL.md")" -ge 1 ] && echo ok || echo no)" "ok"
fi
retro_blocks() { # <retro 경로> → 마커 시작 표지의 수 (창이 몇 개인가)
    # **창은 문서 전체에서 하나여야 한다.** 규약이 *"읽는 범위는 최상단 회고 섹션의 그 표뿐"*
    # 이라 못박는데 위 `retro_vals`의 파서는 **파일 안 마커 블록을 전부** 읽는다 — 새 섹션에
    # 마커를 달면서 직전 섹션 마커를 두면 **이미 처분된 것이 되살아나고 그래도 `O4`는 초록**이다
    # (값이 전부 선언 집합 안이므로). 2026-08-31 회고 실행이 그 자리를 실측으로 열었다.
    [ -f "$1" ] || { echo 0; return; }
    LC_ALL=C awk -v mk="$RBLK" '
        mk == "" { exit }
        index($0, "<!-- " mk ":start -->") > 0 { n++ }
        END { print n + 0 }
    ' "$1"
}
if part_on O; then
chk "O11: 복제 금지 - 스킬이 상태 값 집합을 열거하지 않는다" "$([ "$(mst_hits)" -le 1 ] && echo ok || echo no)" "ok"
# (O12~O14 · M58) **소비 창의 유일성.** 위 파서가 전부 읽으므로 창이 둘이 되면 규약이 금지한
# *"이력을 가로질러 세기"* 가 그대로 성립한다. 그 상태를 여기서 붉힌다.
chk "O12: 본 검사 - 마커 창이 정확히 1개" "$(retro_blocks "$RETRO")" "1"
# 픽스처 통제 — **실제 판정을 사본에 건다**(M46 판례). 창을 하나 더 붙이면 잡아야 한다.
chk "O13: 픽스처 통제 - 창이 둘이면 잡는다" "$(retro_blocks "$(retro_fixture dup)")" "2"
# 오탐 방향 — 손대지 않은 사본은 그대로 1이다. 여기서 갈리면 픽스처 생성이 창을 건드린 것이다.
chk "O14: 오탐 방향 - 손대지 않은 사본은 창이 1개" "$(retro_blocks "$(retro_fixture clean)")" "1"
# (O15~O59 · M69·M70) 케이스. 본 검사 셋은 ⑴ 회고가 릴리즈 뒤에 돌았는가(백스톱) ⑵ 선언된 행 키가
# 추적되는가 ⑶ 릴리즈된 마일스톤이 집었다는 행이 아직 미반영인가다. 통제는 **같은 함수**에 키·사본을
# 먹여 판정의 반응을 묻는다(M46·M47 판례).
chk "O15: retro-cadence 선언 줄 정확히 1개" "$(decl_count "$CONV" 'retro-cadence:')" "1"
chk "O16: retro-pick 선언 줄 정확히 1개" "$(decl_count "$CONV" 'retro-pick:')" "1"
chk "O17: 회고 기준 버전 추출 positive-control" "$([ -n "$(first_ver "$RETRO" '## ')" ] && echo ok || echo no)" "ok"
RBASE=$(base_ver "$MDIR")
RVER=$(first_ver "$RETRO" '## ')
RMARK=$(decl_tail "$CONV" 'retro-release-mark:' | LC_ALL=C awk '{ print $1 }')
[ -n "$RMARK" ] || RMARK=zzz-retro-release-mark-unset
RDERIVE=$(decl_tail "$CONV" 'retro-mark-derive:' | LC_ALL=C awk '{ print $1 }')
[ -n "$RDERIVE" ] || RDERIVE=zzz-retro-mark-derive-unset
RSINCE=$(decl_tail "$CONV" 'retro-mark-since:' | LC_ALL=C awk '{ print $1 }' | LC_ALL=C sed -n 's/^M\([0-9][0-9]*\)$/\1/p')
chk "O18: 본 검사 - 최상단 회고 기준 버전이 CHANGELOG와 맞는다(릴리즈 커밋이면 둘째 머리도 받는다)" "$(backstop_verdict "$(first_ver "$RETRO" '## ')" "$(nth_ver "$CHLOG" '### [' 1)" "$(nth_ver "$CHLOG" '### [' 2)" "$RBASE")" "ok"
chk "O19: 픽스처 통제 - 기준 버전이 뒤처진 사본을 잡는다" "$(backstop_verdict "$(first_ver "$(retro_ver_fixture badver)" '## ')" "$(nth_ver "$CHLOG" '### [' 1)" "$(nth_ver "$CHLOG" '### [' 2)" "$RBASE")" "no"
chk "O20: 행 키 추출 positive-control(>0)" "$([ "$(retro_keys "$RETRO" | grep -c .)" -gt 0 ] && echo ok || echo no)" "ok"
chk "O21: 본 검사 - 선언된 행 키가 전부 최상단 표에 실재한다" "$(claim_missing "$RETRO" "$(mst_claims)")" "0"
chk "O22: 픽스처 통제 - 표에 없는 키를 주면 잡는다" "$(claim_missing "$RETRO" zzz-key-gone)" "1"
chk "O23: 본 검사 - 회고가 본 릴리즈 위에 선 마일스톤의 선언 중 미반영 0개" "$(claim_stale "$RETRO" "$(target_claims "$MDIR" "$RVER" "$CHLOG" "${RSINCE:-0}")")" "0"
chk "O24: 픽스처 통제 - 미반영 행의 키를 주면 잡는다" "$(claim_stale "$RETRO" "$(key_with_stat "$RETRO" "$RUNDONE")")" "1"
chk "O25: 음성 통제 - 반영된 행의 키는 세지 않는다" "$(claim_stale "$RETRO" "$(key_with_stat "$RETRO" "$RFIRST")")" "0"
chk "O26: retro-cadence 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" 'retro-cadence:')" "0"
chk "O27: retro-pick 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" 'retro-pick:')" "0"
chk "O28: 갱신 주기 병기어가 재서술처 둘에 공존" "$(scope_tok "$ROOT/skills/release/SKILL.md" "$RCAD")$(scope_tok "$ROOT/docs/commands.md" "$RCAD")" "yesyes"
chk "O29: 집은 행 병기어가 재서술처 둘에 공존" "$(scope_tok "$ROOT/skills/milestone/SKILL.md" "$RPICK")$(scope_tok "$ROOT/skills/milestone/template.md" "$RPICK")" "yesyes"
chk "O30: 창 통제 - 마커 창 밖의 키 있는 행은 보지 않는다" "$(claim_stale "$(retro_out_fixture)" zzz-outside)" "0"
# (O31~O35 · M69 리뷰 라운드 1) 리뷰가 연 빈자리 넷을 닫는다 — ⑴ 선언 쪽 추출의 조건부
# positive-control(`O31`) ⑵ 선언 형태 규율 셋(`O32`~`O34`) ⑶ 소음 0 음성 통제(`O35`).
chk "O31: 선언 추출 조건부 positive-control" "$(claim_extract_ok "$MDIR")" "ok"
chk "O32: retro-rows 선언 줄이 둘 이상인 문서 0개" "$(mst_claim_dup)" "0"
chk "O33: retro-rows 값이 빈 문서 0개" "$(mst_claim_empty)" "0"
chk "O34: 회고 표의 행 키 중복 0개" "$(retro_key_dup "$RETRO")" "0"
# (O35) **소음 0 음성 통제** — 선언 줄이 **없는** 마일스톤 문서만으로도 판정이 붉지 않아야 한다.
# 선언을 쓰지 않는 저장소가 곧 이 상태이고, 그 저장소의 정상 트리가 붉으면 소음 0 계약이 깨진다.
# **빈 키 목록을 리터럴로 먹이지 않는다** — 그러면 루프가 0회라 구성상 0이다(라운드 1 권장 3). 선언을 지운
# 사본 디렉터리를 추출·조건부 통제·본 검사 **같은 함수**에 먹인다.
SILM=$(silence_fixture)
chk "O35: 음성 통제 - 선언 없는 문서 집합에서 추출 통제·판정이 붉지 않는다" "$(claim_extract_ok "$SILM")$(claim_missing "$RETRO" "$(mst_claims "$SILM")")$(claim_stale "$RETRO" "$(target_claims "$SILM" "$RVER" "$CHLOG" "${RSINCE:-0}")")" "ok00"
# (O36~O40 · M69 리뷰 라운드 2·3) **백스톱의 릴리즈 커밋 갈래** — `O18`이 릴리즈 커밋에서 붉던 차단을 닫으며
# 판정의 방향마다 통제를 둔다. 판정 값은 **합성 픽스처**에서 온다(실제 CHANGELOG가 릴리즈 커밋 상태여도 같은 답).
CHFX=$(chlog_fixture)
chk "O36: 통제 - 기반 버전이 첫째 머리보다 앞서면 둘째 머리를 받는다(릴리즈 커밋)" "$(backstop_verdict 2.0.0 "$(nth_ver "$CHFX" '### [' 1)" "$(nth_ver "$CHFX" '### [' 2)" 2.0.0)" "ok"
chk "O37: 통제 - 기반 버전이 첫째 머리와 같으면 둘째 머리를 받지 않는다(회고 건너뜀)" "$(backstop_verdict 2.0.0 "$(nth_ver "$CHFX" '### [' 1)" "$(nth_ver "$CHFX" '### [' 2)" 3.0.0)" "no"
chk "O38: 통제 - 두 릴리즈 뒤처지면 잡는다" "$(backstop_verdict 1.0.0 "$(nth_ver "$CHFX" '### [' 1)" "$(nth_ver "$CHFX" '### [' 2)" 1.0.0)" "no"
chk "O39: 기반 버전 추출 positive-control(실제 최대 번호 문서)" "$([ -n "$RBASE" ] && echo ok || echo no)" "ok"
chk "O40: 기반 버전 추출 통제 - 수로 최대인 문서를 읽고 꼬리 메모를 떼어 낸다" "$(base_ver "$(base_fixture)")" "2.0.0"
# (O41~O45 · M70) **stale 대상을 기반 버전 자리로 가린다** — 「최대 번호만 뺀다」를 대체한다. 통제는 합성
# 마일스톤 넷과 합성 CHANGELOG에 **같은 함수**를 먹여 방향마다 묻는다(전부 포함 · 전부 제외 · 옛 최대 번호 ·
# 경계의 같음/아래 · 자리 없는 기반 버전).
chk "O41: 선언한 마일스톤의 기반 버전이 전부 CHANGELOG 머리에 있다" "$(claim_base_missing "$MDIR" "$CHLOG" "${RSINCE:-0}")" "0"
TGFX=$(target_fixture)
chk "O42: 대상 통제 - 회고 v2.0.0이면 기반 규칙의 M1만 대상이다(표지 v3.0.0은 아직 회고 위)" "$(target_claims "$TGFX" 2.0.0 "$CHFX" 5 | tr '\n' ' ' | sed 's/ $//')" "k1"
chk "O43: 대상 통제 - 회고 v3.0.0이면 M1·M2와 표지가 같은 M6이 대상이다(도입 번호 자리의 무표지 M5는 아니다)" "$(target_claims "$TGFX" 3.0.0 "$CHFX" 5 | tr '\n' ' ' | sed 's/ $//')" "k1 k2 k6"
chk "O44: 통제 - 머리에 없는 판정 값(기반 M4 · 표지 M7)의 선언을 따로 센다" "$(claim_base_missing "$TGFX" "$CHFX" 5)" "2"
chk "O45: 순서 규칙 병기어가 milestone 스킬에 있다" "$(scope_tok "$ROOT/skills/milestone/SKILL.md" "$RCAD")" "yes"
# (O46~O52 · M70 리뷰 라운드 0 차단) **릴리즈 표지** — debug 릴리즈가 기반 버전 규칙을 거짓으로 만들어, 도입 번호
# 이상의 마일스톤은 릴리즈가 남긴 `- released:` 표지로 가린다. 릴리즈가 표지를 **통째로** 빠뜨렸는가는 묻지 않는다
# (규약의 경계 — 다음 표지 릴리즈가 늦은 버전으로 메운다). 한 릴리즈가 일부만 표지하고 건너뛴 것은 아래 `O53`이 문다.
chk "O46: retro-release-mark 선언 줄 정확히 1개" "$(decl_count "$CONV" 'retro-release-mark:')" "1"
chk "O47: retro-mark-since 선언 줄 정확히 1개" "$(decl_count "$CONV" 'retro-mark-since:')" "1"
chk "O48: 표지 도입 번호 추출 positive-control(M{숫자})" "$([ -n "$RSINCE" ] && echo ok || echo no)" "ok"
chk "O49: 릴리즈 표지 병기어가 재서술처 둘에 공존" "$(scope_tok "$ROOT/skills/release/SKILL.md" "$RMARK")$(scope_tok "$ROOT/docs/commands.md" "$RMARK")" "yesyes"
chk "O50: 본 검사 - 표지 줄이 둘 이상인 마일스톤 문서 0개" "$(mark_dup "$MDIR")" "0"
chk "O51: 통제 - 표지 줄이 둘인 문서를 센다" "$(mark_dup "$(markdup_fixture)")" "1"
chk "O52: 세 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" 'retro-release-mark:')$(bad_seps "$CONV" 'retro-mark-since:')$(bad_seps "$CONV" 'retro-mark-derive:')" "000"
# (O53~O55 · M70 리뷰 라운드 1 차단) **표지 누락** — 표지 대상이 「이번 태그에 실리는 마일스톤 전부」라, 표지가 선
# 마일스톤 아래에서 impl 보고서가 있는데 표지가 없는 문서는 누락이다(갈래 ⓐ의 공허 통과를 붉힌다). 통제는 합성
# 픽스처 두 벌(누락 있음 · 없음)에 **같은 함수**를 먹인다 — 도입 번호 미만 · 초안 · 가장 큰 표지 위와 표지 둘을
# 함께 둔다. 붉히는 것은 한 릴리즈의 **부분** 누락이고, 통째 누락은 다음 릴리즈가 늦은 버전으로 메워 닿지 않는다.
chk "O53: 본 검사 - 표지가 있는 마일스톤 아래의 표지 누락 0개" "$(mark_gap "$MDIR" "$ROOT/docs/reports" "${RSINCE:-0}")" "0"
GPFX=$(gap_fixture gap)
chk "O54: 통제 - 가장 큰 표지 M9 아래의 impl 있는 무표지 M5(도입 번호 자리)·M7을 센다(M4 도입 전 · M8 초안 · M10 가장 큰 표지 위는 아니다)" "$(mark_gap "$GPFX/m" "$GPFX/r" 5)" "2"
GPCL=$(gap_fixture clean)
chk "O55: 음성 통제 - M5·M7에도 표지가 있으면 0이다" "$(mark_gap "$GPCL/m" "$GPCL/r" 5)" "0"
# (O56~O59 · M70 리뷰 라운드 3 차단) **도입 번호는 대상 레포로 폴백하지 않는다**(`mark-since-derived`) — 선언이 없는 레포는
# 가장 작은 표지 번호를 도입 번호로 쓴다. 이 저장소에서는 그 파생 값이 선언과 같아야 한다(표지가 없으면 선언 그대로).
# 통제는 clean(표지 M5·M6·M7·M9) · gap(표지 M6·M9) · 표지 없는 디렉터리에 **같은 함수**를 먹인다 — 가장 큰 표지를
# 쓰면 9·9, 추출을 죽이면 빈 값이 나온다. 대상 레포에서 파생이 실제로 도는가는 묻지 않는다(하니스가 거기서 돌지 않는다).
RSMIN=$(mark_since "$MDIR")
chk "O56: 본 검사 - 표지가 있으면 가장 작은 표지 번호가 선언된 도입 번호와 같다" "$([ -n "$RSINCE" ] && [ "${RSMIN:-$RSINCE}" = "$RSINCE" ] && echo ok || echo no)" "ok"
mkdir -p "$SBX/nomark-milestones"
printf '%s\n' '# M1' > "$SBX/nomark-milestones/M1.md"
chk "O57: 통제 - 가장 작은 표지 번호(clean 5 · gap 6 · 표지 없음 빈 값)" "$(mark_since "$GPCL/m")|$(mark_since "$GPFX/m")|$(mark_since "$SBX/nomark-milestones")" "5|6|"
chk "O58: retro-mark-derive 선언 줄 정확히 1개" "$(decl_count "$CONV" 'retro-mark-derive:')" "1"
chk "O59: 도입 번호 파생 병기어가 재서술처 셋에 공존" "$(scope_tok "$ROOT/skills/release/SKILL.md" "$RDERIVE")$(scope_tok "$ROOT/skills/retro/SKILL.md" "$RDERIVE")$(scope_tok "$ROOT/docs/commands.md" "$RDERIVE")" "yesyesyes"
fi

# --- Part P: 완료 기준 대조 (M55) --------------------------------------------
# 마일스톤이 요구한 것을 impl이 번호로 대조했는가. 무는 것은 **빠짐과 유령**까지이고
# *"충족이 사실인가"* 는 리뷰의 영역이다(규약이 같은 경계를 적는다).
if part_on P; then
CRITV=$(decl_tail "$CONV" 'criteria-verdict:' | LC_ALL=C awk '{ $1 = $1; print }')
fi
# **선언을 잃었을 때의 기본값을 두 사본에 못박는다.** 그러지 않으면 `sh`는 `[ n -ge "" ]`가 죽어
# 대상이 비고, `ps1`은 `[int]''`가 **0**이라 **모든 마일스톤**을 대상으로 삼는다 — 같은 트리에서
# 다른 판정이 된다(되돌림 `p2-key` 실측: sh 263/6 vs ps1 262/7). 형식이 어긋나면 **어느 마일스톤도
# 대상이 되지 않게** 해 추출 positive-control이 양쪽에서 붉게 한다 — fail-loud이고 동치다.
CRITS=$(decl_tail "$CONV" 'criteria-since:' | LC_ALL=C awk '{ print $1 }')
CRITN=999999
case "$CRITS" in
    M*) _cs0=${CRITS#M}
        case "$_cs0" in
            "" | *[!0-9]*) ;;
            *) CRITN=$_cs0 ;;
        esac ;;
esac
# 선언이 **비었을 때의 기본값도 양 사본에 못박는다**. 그냥 두면 `grep -cF -- ""`가 **모든 줄**에
# 맞아 sh는 P15를 91로 세고, ps1은 `IndexOf('')`가 끝을 넘어가 **결과 줄에 닿기 전에 죽는다** —
# 같은 트리에서 한쪽은 세고 한쪽은 중단한다(완료 기준 6-(1) 교란의 실측: sh 263/6 · ps1 중단).
# 빈 선언은 이제 **어느 사본에서도 나타나지 않는 토큰**이 되고, 그 사실은 `P1`이 양쪽에서 붉혀
# 드러낸다. `criteria-since:`의 기본값을 못박은 것과 같은 기전이다(관측 (b)).
# **못은 선언 원문에 박는다**(M56 — M55 리뷰 반환 ②). 파생 토큰에만 박으면 **집합 소속을 판정하는
# 자리**가 여전히 선언 원문을 읽어, 빈 판정 값을 sh는 **집합 안**(`case "  " in *"  "*`이 맞는다)으로
# ps1은 **집합 밖**(`@() -notcontains ''`)으로 센다 — 같은 트리에서 다른 수다(실측: 선언을 지우고
# 판정 칸 하나를 비우면 `P9`가 sh 10 · ps1 11). 원문에 박으면 파생 토큰이 **거기서 나오므로** 한
# 자리로 끝난다 — 아래 두 대입에 따로 폴백을 두지 않는 이유이고, 두면 그것이 두 번째 선언처다.
if part_on P; then
CRITUNSET=zzz-criteria-verdict-unset
[ -n "$CRITV" ] || CRITV=$CRITUNSET
CRITOK=$(printf '%s' "$CRITV" | LC_ALL=C awk '{ print $1 }')
CRITALT=$(printf '%s' "$CRITV" | LC_ALL=C awk '{ print $NF }')
fi
crit_nums() { # <마일스톤 경로> → 완료 기준의 **최상위** 번호
    # 창은 그 절 하나다 — 파일 전역을 훑으면 다른 절의 번호 목록이 섞인다.
    # 창 열기는 **줄 끝 CR만 벗기고 여전히 정확히 비교**한다(`decl_lines`와 **같은 형태** — M56).
    # `index()`로 넓히면 안 된다: `## 완료 기준 대조`가 `## 완료 기준`을 **부분 문자열로 포함**해
    # 창이 잘못 열린다. 줄 전체 일치만 두면 CR을 레코드에 남기는 awk에서 창이 **아예 안 열린다**.
    LC_ALL=C awk -v cr="$(printf '\r')" '
        { s = $0; if (length(s) > 0 && substr(s, length(s), 1) == cr) s = substr(s, 1, length(s) - 1) }
        s == "## 완료 기준" { w = 1; next }
        w && substr(s, 1, 3) == "## " { w = 0 }
        w && s ~ /^[0-9]+\. / { n = $1; sub(/\./, "", n); print n }
    ' "$1"
}
crit_head_lines() { # <파일> → 절 제목과 **줄 전체가 같은** 줄 수
    # **가드가 지키는 대상과 같은 형태로 본다**(M56 — `p14-template` 실측이 연 자리). 앞선 판본은
    # `grep -cF`라 **부분 문자열**이었고, 제목을 `## 완료 기준 대조표`로 늘리면 **여전히 맞아 초록**
    # 이었다(실측 273/0). 그런데 창을 여는 `crit_rows`는 **줄 전체 일치**라 그 템플릿에서 나온 보고서는
    # 창이 열리지 않는다 — **가드는 초록인데 지켜야 할 것이 깨진다.** 창과 같은 형태로 맞춘다.
    LC_ALL=C awk -v cr="$(printf '\r')" '
        { s = $0; if (length(s) > 0 && substr(s, length(s), 1) == cr) s = substr(s, 1, length(s) - 1) }
        s == "## 완료 기준 대조" { n++ }
        END { print n + 0 }
    ' "$1"
}
crit_rows() { # <impl 보고서 경로> → 대조표의 `번호|판정`(정규화) 한 줄씩
    # 머리글 건너뛰기는 구조로 한다 — 창 안에서 구분선(`---`)을 본 **뒤의** 행만 데이터다.
    [ -f "$1" ] || return 0
    LC_ALL=C awk -v cr="$(printf '\r')" '
        { s = $0; if (length(s) > 0 && substr(s, length(s), 1) == cr) s = substr(s, 1, length(s) - 1) }
        s == "## 완료 기준 대조" { w = 1; sep = 0; next }
        w && substr(s, 1, 3) == "## " { w = 0 }
        w && sep == 0 { if (index(s, "---") > 0) sep = 1; next }
        w && substr(s, 1, 1) == "|" {
            n = split(s, f, "|")
            if (n < 5) next
            a = f[2]; b = f[3]
            gsub(/[ \r*]/, "", a); gsub(/[ \r*]/, "", b)
            print a "|" b
        }
    ' "$1"
}
crit_targets() { # <시작 번호> → 대상 마일스톤 번호(그 번호 이상 + impl 보고서 실재)
    for _cm0 in "$ROOT"/docs/milestones/M*.md; do
        _cn=$(basename "$_cm0" .md | sed 's/^M//')
        [ "$_cn" -ge "$1" ] || continue
        [ -f "$ROOT/docs/reports/M$_cn-impl.md" ] || continue
        echo "$_cn"
    done
}
crit_rep() { # <번호> [사본 경로] → 그 번호가 대상 사본이면 사본을, 아니면 실물을
    # `set -u` 아래에서는 **미설정 위치 인자를 그냥 참조하면 죽는다** — 옵션 인자는 `${2-}`로 받는다.
    if [ -n "${2-}" ] && [ "$1" = "$CRITN" ]; then printf '%s' "$2"
    else printf '%s' "$ROOT/docs/reports/M$1-impl.md"; fi
}
crit_mismatch() { # <시작 번호> [사본 경로] → 번호 집합이 어긋난 마일스톤 수
    _cmm=0
    for _cn in $(crit_targets "$1"); do
        _crep=$(crit_rep "$_cn" "${2-}")
        _cwant=$(crit_nums "$ROOT/docs/milestones/M$_cn.md" | LC_ALL=C sort -n | tr '\n' ' ')
        _chave=$(crit_rows "$_crep" | cut -d'|' -f1 | LC_ALL=C sort -n | tr '\n' ' ')
        [ "$_cwant" = "$_chave" ] || _cmm=$((_cmm + 1))
    done
    echo "$_cmm"
}
crit_bad() { # [사본 경로] → 선언 집합 밖 판정 값의 수 (**빈 값도 밖으로 센다**)
    _cbv=0
    for _cn in $(crit_targets "$CRITN"); do
        _crep=$(crit_rep "$_cn" "${1-}")
        for _cv in $(crit_rows "$_crep" | LC_ALL=C awk -F'|' '{ print "[" $2 "]" }'); do
            _ct=${_cv#[}; _ct=${_ct%]}
            case " $CRITV " in
                *" $_ct "*) ;;
                *) _cbv=$((_cbv + 1)) ;;
            esac
        done
    done
    echo "$_cbv"
}
crit_seen() { # <시작 번호> → 대상 마일스톤의 기준 번호 총수 (추출 positive-control용)
    _cs=0
    for _cn in $(crit_targets "$1"); do
        _cs=$((_cs + $(crit_nums "$ROOT/docs/milestones/M$_cn.md" | grep -c .)))
    done
    echo "$_cs"
}
crit_fixture() { # <모드> → 사본 경로 (clean|drop|ghost|outset|blank|swap)
    # **첫 데이터 행 하나만** 건드린다 — 판정이 그 한 행에서 갈리는지 보려는 것이다.
    _cf="$SBX/crit-$1.md"
    LC_ALL=C awk -v mode="$1" -v ok1="$CRITOK" -v alt="$CRITALT" -v cr="$(printf '\r')" '
        { s = $0; if (length(s) > 0 && substr(s, length(s), 1) == cr) s = substr(s, 1, length(s) - 1) }
        s == "## 완료 기준 대조" { w = 1; sep = 0; print; next }
        w && substr(s, 1, 3) == "## " { w = 0 }
        w && sep == 0 { if (index(s, "---") > 0) sep = 1; print; next }
        w && done == 0 && substr(s, 1, 1) == "|" {
            n = split($0, f, "|")
            if (n >= 5 && mode != "clean") {
                done = 1
                if (mode == "drop") next
                if (mode == "ghost") { print; print "| 999 | " ok1 " | zzz |"; next }
                if (mode == "outset") f[3] = " zzz-gone "
                else if (mode == "blank") f[3] = "  "
                else if (mode == "swap") f[3] = " " alt " "
                line = f[1]
                for (i = 2; i <= n; i++) line = line "|" f[i]
                print line; next
            }
        }
        { print }
    ' "$ROOT/docs/reports/M$CRITN-impl.md" > "$_cf"
    printf '%s' "$_cf"
}
crit_eol() { # <줄끝> → 대상 마일스톤 문서를 그 줄끝으로 다시 쓴 픽스처 경로 (lf|crlf)
    # **CR 내성 통제의 픽스처**(M56 — M55 리뷰 반환 ③). 원본의 줄끝이 무엇이든 같은 본문을 두 줄끝으로
    # 각각 만든다. 판정은 여기서 하지 않는다 — 아래 `crit_eol_same`이 **실제 판정 함수**(`crit_nums`)를
    # 둘 다에 걸어 대조하므로, «픽스처가 조건을 만족하는가»가 아니라 «판정이 픽스처를 잡는가»를 묻는다.
    _cef="$SBX/crit-eol-$1.md"
    if [ "$1" = crlf ]; then _cee=$(printf '\r'); else _cee=''; fi
    LC_ALL=C awk -v cr="$(printf '\r')" -v eol="$_cee" '{
        s = $0
        if (length(s) > 0 && substr(s, length(s), 1) == cr) s = substr(s, 1, length(s) - 1)
        print s eol
    }' "$ROOT/docs/milestones/M$CRITN.md" > "$_cef"
    printf '%s' "$_cef"
}
crit_eol_same() { # → LF·CRLF 픽스처에서 **같은 번호**가 나오면 ok (추출이 비면 no — 공허 통과 차단)
    _celff=$(crit_eol lf); _cecrf=$(crit_eol crlf)
    # **픽스처 positive-control** — CRLF 사본에 CR이 실제로 있고 LF 사본에는 **없어야** 한다.
    # 없으면 두 사본이 같아져 «같은 번호»가 **공허하게** 성립한다: 픽스처 생성기를 깨서 양쪽을 LF로
    # 만들어도 초록이 나온다(M46 판례의 동어반복 그 자체). `awk`로 세지 않는 이유는 윈도우 gawk가
    # 텍스트 모드로 **CR을 먼저 벗겨** 그 자리에서 볼 수 없기 때문이다 — 바이트로 센다.
    _cecn=$(LC_ALL=C tr -dc '\r' < "$_cecrf" | wc -c | tr -d ' ')
    _celn=$(LC_ALL=C tr -dc '\r' < "$_celff" | wc -c | tr -d ' ')
    if [ "$_cecn" -le 0 ] || [ "$_celn" -ne 0 ]; then echo no; return; fi
    _celf=$(crit_nums "$_celff" | tr '\n' ' ')
    _cecr=$(crit_nums "$_cecrf" | tr '\n' ' ')
    [ -n "$_celf" ] && [ "$_celf" = "$_cecr" ] && echo ok || echo no
}
# (M56 — M55 리뷰 반환 ① + 적대 축 `adv-enum-split`) **재열거의 창은 파일이다.**
# 앞선 판본은 선언 집합의 **첫 값 하나**를 grep했다. 그 값이 둘째 값의 **부분 문자열**이라
# 스킬이 산문에서 둘째 값을 **한 번만 써도 붉었다** — 그런 문장은 마일스톤이 **템플릿에 두라고
# 요구한 안내문과 같은 문장**이고, 그것을 스킬로 옮기는 것은 평범한 편집이다(과하게 무는 방향).
# 그다음 판본은 **줄 단위로** 서로 다른 값의 수를 셌고, 적대 축이 그 창을 뚫었다 — 값을 **두 줄에
# 나눠** 적으면 어느 줄도 둘을 담지 않아 **초록으로 통과**했다(`adv-enum-split` 실측).
# 그래서 창을 **파일 단위**로 연다. 다만 그대로 넓히면 셋째 값이 **한국어 산문의 흔한 낱말**이라
# 같은 스킬에 이미 다른 뜻으로 여러 번 있고, 파일 어디엔가 다른 값이 하나만 있어도 붉는다.
# 세는 대상을 **포함 관계에 있는 쌍**으로 한정하는 이유다 — 그 쌍은 **선언 집합에서 도출한다**
# (어떤 값이 다른 값 안에 들어 있는 그 둘). 러너는 값의 위치도 낱말도 알지 않는다.
# 쌍이 도출되지 않으면(선언에 포함 관계가 없거나 선언을 잃었을 때) 판정은 **항상 `no`**가 되고
# `P17`이 **붉어 그 사실을 드러낸다** — 조용히 공허해지지 않는다.
if part_on P; then
CRITPAIR=$(printf '%s' "$CRITV" | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) for (j = 1; j <= NF; j++) if (i != j && index($i, $j) > 0) { print $i, $j; exit } }')
CRITSUP=$(printf '%s' "$CRITPAIR" | LC_ALL=C awk '{ print $1 }')
[ -n "$CRITSUP" ] || CRITSUP=$CRITOK
CRITSUB=$(printf '%s' "$CRITPAIR" | LC_ALL=C awk '{ print $NF }')
[ -n "$CRITSUB" ] || CRITSUB=$CRITOK
fi
crit_reenum() { # <파일> → 포함 쌍의 **두 값이 모두** 파일에 나타나면 yes, 아니면 no
    [ -f "$1" ] || { echo no; return; }
    LC_ALL=C awk -v vals="$CRITPAIR" '
        function cnt(s, t,   n, p) {
            if (t == "") return 0
            n = 0; p = index(s, t)
            while (p > 0) { n++; s = substr(s, p + length(t)); p = index(s, t) }
            return n
        }
        BEGIN { nv = split(vals, v, " ") }
        {
            for (i = 1; i <= nv; i++) {
                c = cnt($0, v[i])
                for (j = 1; j <= nv; j++) if (i != j && index(v[j], v[i]) > 0) c -= cnt($0, v[j])
                if (c > 0) seen[i] = 1
            }
        }
        END { d = 0; for (i = 1; i <= nv; i++) if (seen[i]) d++; print (d >= 2) ? "yes" : "no" }
    ' "$1"
}
crit_skill_base() { # → 쌍의 값이 **한 자리도 없는** 스킬 사본 (픽스처의 바닥)
    # **픽스처를 살아 있는 파일 위에 쌓지 않는다**(M56 — 적대 축 `adv-enum-third`가 연 자리).
    # 바닥을 `skills/impl/SKILL.md` 그대로 두면 그 파일이 쌍의 값 **하나만 갖게 되는 순간**
    # `one` 픽스처가 나머지 하나를 얹어 **둘**이 되어 `P18`이 붉는다 — 값 하나를 산문에서 쓰는 것은
    # 통과해야 한다는 이 계열의 계약과 **정면으로 어긋나는 오탐**이다. 바닥에서 쌍의 값을 지워
    # `P17`·`P18`·`P19`가 **판정 함수만** 재게 한다. 살아 있는 파일을 재는 것은 `P15`의 몫이다.
    _csb="$SBX/crit-skill-base.md"
    LC_ALL=C awk -v vals="$CRITPAIR" '
        BEGIN { nv = split(vals, v, " ") }
        {
            for (i = 1; i <= nv; i++) if (index($0, v[i]) > 0) next
            print
        }
    ' "$ROOT/skills/impl/SKILL.md" > "$_csb"
    printf '%s' "$_csb"
}
crit_skill_fixture() { # <모드> → 스킬 사본 경로
    # enum: 값을 **한 줄에** 열거 · one: 값 **하나**만 · split: 쌍을 **두 줄에 나눠** 적는다.
    # `split`은 적대 변이가 성립한 형태를 **픽스처로 승격**한 것이다(규약의 되돌림 절).
    _csf="$SBX/crit-skill-$1.md"
    cp "$(crit_skill_base)" "$_csf"
    case "$1" in
        enum)  printf '%s\n' "$CRITV" >> "$_csf" ;;
        split) printf '%s\n' "$CRITSUP" >> "$_csf"; printf '%s\n' "$CRITSUB" >> "$_csf" ;;
        *)     printf '%s\n' "$CRITSUP" >> "$_csf" ;;
    esac
    printf '%s' "$_csf"
}
if part_on P; then
chk "P1: criteria-verdict 선언 줄 정확히 1개" "$(decl_count "$CONV" 'criteria-verdict:')" "1"
chk "P2: criteria-since 선언 줄 정확히 1개" "$(decl_count "$CONV" 'criteria-since:')" "1"
# (P3) 추출 positive-control — 기준 파싱이 망가지면 «집합이 같다»가 «0 == 0»으로 공허 통과한다.
chk "P3: 완료 기준 번호 추출 positive-control(>0)" "$([ "$(crit_seen "$CRITN")" -gt 0 ] && echo ok || echo no)" "ok"
# (P4·P5) **본 검사 둘.** 번호 집합 일치(빠짐 0·유령 0)와 판정 값의 집합 소속.
chk "P4: 본 검사 - 번호 집합이 어긋난 마일스톤 0개" "$(crit_mismatch "$CRITN")" "0"
chk "P5: 본 검사 - 선언 집합 밖 판정 값 0개" "$(crit_bad)" "0"
# 픽스처 통제 — **실제 판정을 픽스처에 건다**(M46 판례). 네 방향을 각각 깬다.
# **차이로 묻는다**(M61 — 규약의 `control-reads-delta:`). 앞선 판본은 절대값(`1`·`0`)을 물어
# **기준선이 0이라고 가정**했다. 기준선은 0이 아닐 수 있고(대조 대상 보고서가 실제로 어긋난 동안이
# 그 상태다) 그때 통제는 **자기가 무는 반응이 아니라 기준선을 재게 된다** — 실측으로 `P6`·`P7`이
# `got 2, want 1`, `P10`이 `got 1, want 0`으로 붉었다(M60 반증 ⑴ · 이 사이클이 재현). `P8`·`P9`·
# `P12`도 같은 부류임을 실측으로 확인했다(판정 칸 하나를 집합 밖 값으로 두면 `got 2, want 1` ·
# `got 1, want 0`). **판정 함수를 무력화하면 차이가 0이 되어 여전히 붉는다** — 무는 힘은 그대로다.
chk "P6: 픽스처 통제 - 행이 빠지면 잡는다" "$(( $(crit_mismatch "$CRITN" "$(crit_fixture drop)") - $(crit_mismatch "$CRITN") ))" "1"
chk "P7: 픽스처 통제 - 없는 번호를 적으면 잡는다" "$(( $(crit_mismatch "$CRITN" "$(crit_fixture ghost)") - $(crit_mismatch "$CRITN") ))" "1"
chk "P8: 픽스처 통제 - 집합 밖 판정 값을 잡는다" "$(( $(crit_bad "$(crit_fixture outset)") - $(crit_bad) ))" "1"
chk "P9: 픽스처 통제 - 판정 칸을 비워도 잡는다" "$(( $(crit_bad "$(crit_fixture blank)") - $(crit_bad) ))" "1"
chk "P10: 음성 통제 - 손대지 않은 사본은 붉지 않는다" "$(( $(crit_mismatch "$CRITN" "$(crit_fixture clean)") - $(crit_mismatch "$CRITN") ))" "0"
# (P11) **소급 경계가 실제로 거르는가.** 시작 번호를 1로 낮추면 이 절이 없던 시절의 보고서가
# 대상에 들어와 어긋난다 — 경계가 장식이 아니라는 것을 이 케이스가 확인한다.
chk "P11: 경계 통제 - 시작 번호를 1로 낮추면 어긋난다(>0)" "$([ "$(crit_mismatch 1)" -gt 0 ] && echo ok || echo no)" "ok"
# (P12) **오탐 방향.** 집합 안 다른 값으로 바꾸는 것은 정상이다 — 여기서 붉으면 과하게 무는 것이다.
# 여기도 차이다 — 기준선이 0이 아니면 절대값은 오탐 방향을 판정하지 못한다.
chk "P12: 오탐 방향 - 집합 안 다른 값은 통과" "$(( $(crit_bad "$(crit_fixture swap)") - $(crit_bad) ))" "0"
# (P13~P15) 소비자의 배선. 스킬·템플릿이 가리키되 **규칙을 다시 열거하지 않는다**.
chk "P13: impl 스킬이 규약 절을 가리킨다" "$([ "$(grep -cF -- '완료 기준 대조 (impl)' "$ROOT/skills/impl/SKILL.md")" -ge 1 ] && echo ok || echo no)" "ok"
chk "P14: impl 템플릿이 그 절을 갖는다(줄 전체 일치, 정확히 1)" "$(crit_head_lines "$ROOT/skills/impl/template.md")" "1"
chk "P15: 복제 금지 - 스킬이 포함 쌍을 다시 열거하지 않는다" "$(crit_reenum "$ROOT/skills/impl/SKILL.md")" "no"
# (P16) **CR 내성 통제**(M56 — M55 리뷰 반환 ③). 창 열기가 **줄 전체 일치**뿐이면 CR을 레코드에
# 남기는 awk(mawk 등)에서 창이 열리지 않는다 — 선언된 네 환경에서는 윈도우 gawk가 CR을 선벗기고
# 우분투는 LF 체크아웃이라 발화하지 않았고, 그래서 **CRLF 픽스처를 명시로 세워** 그 자리를 문다.
# `run.ps1` 사본은 `ReadAllLines`가 CRLF를 이미 벗기므로 **고칠 것이 없고 케이스만 동형**이다.
chk "P16: CR 내성 - CRLF 픽스처에서도 창이 열리고 번호가 같다" "$(crit_eol_same)" "ok"
# (P17) 픽스처 통제 — **실제 판정을 픽스처에 건다**. 값을 한 줄에 열거하면 잡아야 한다.
# 쌍이 도출되지 않으면 이 자리가 붉는다 — **공허 통과를 막는 자리**이기도 하다.
chk "P17: 픽스처 통제 - 값을 한 줄에 열거하면 잡는다" "$(crit_reenum "$(crit_skill_fixture enum)")" "yes"
# (P18) **오탐 방향**(M55 리뷰 반환 ①). 값 **하나**를 산문에서 쓰는 것은 열거가 아니다 —
# 여기서 붉으면 과하게 무는 것이고, 그 문장은 템플릿에 실재한다.
chk "P18: 오탐 방향 - 값 하나만 쓰는 줄은 통과" "$(crit_reenum "$(crit_skill_fixture one)")" "no"
# (P19) 픽스처 통제 — **적대 변이의 승격**(M56). 값을 **두 줄에 나눠** 적는 것도 재열거다.
# 줄 단위 창이던 시절 이 형태가 초록으로 통과했다(`adv-enum-split`). 창이 줄로 되돌아가면
# 여기서 붉는다 — 되돌림이 아니라 **상시로** 무는 자리다.
chk "P19: 픽스처 통제 - 두 줄에 나눠 적은 열거도 잡는다" "$(crit_reenum "$(crit_skill_fixture split)")" "yes"
fi

# --- Part Q: 판정 비교의 Ordinal 고정 (M57) -----------------------------------
# M42-T03이 *"이 파일의 모든 단언이 여기를 지난다"* 며 판정 비교를 Ordinal로 못박았다. 그 처방이
# **일곱 러너 중 다섯에만** 적용돼 있었고 `tests/mutation`은 `-eq`로 남아 있었다 — 그리고
# **아무것도 붉지 않았다.** 「분담해서 집행한다」가 「일부에서만 돈다」를 가린 자리이고, 이 사이클이
# 무는 부류 그 자체다. 이제 기계가 문다.
#
# **무는 것은 판정 자리의 비교 형태다** — `$script:pass++`가 있는 줄과 그 **직전 두 줄** 안에
# Ordinal 비교가 있거나 `verdict-exempt: <사유>` 선언이 있어야 한다. 창을 세 줄로 잡는 이유는
# 판정이 `if (…) { $script:pass++ }` 두 줄 형태와 한 줄 형태 **둘 다**로 쓰이기 때문이다.
# **면제는 침묵이 아니라 선언이다** — `locale-exempt:`와 같은 기전이고 규약이 사유를 선언한다.
VERDICT_MARK='$script:pass++'
VERDICT_ORD='StringComparison]::Ordinal'
VERDICT_EXEMPT='verdict-exempt:'
vq_scan() { # <파일> → 그 파일에서 **미고정·미선언**인 판정 자리 수
    [ -f "$1" ] || { echo 0; return; }
    LC_ALL=C awk -v mark="$VERDICT_MARK" -v ord="$VERDICT_ORD" -v ex="$VERDICT_EXEMPT" '
        { l[NR] = $0 }
        # 주석 줄은 판정 자리가 아니다 — 토큰을 **말하는** 줄과 **쓰는** 줄을 가른다
        # (이 파트의 설명 주석이 자기 자신에게 잡힌 실측이 이 한 줄을 낳았다).
        { t = $0; sub(/^[ 	]+/, "", t); if (substr(t, 1, 1) == "#") next }
        index($0, mark) > 0 {
            ok = 0
            for (i = NR - 2; i <= NR; i++)
                if (i >= 1 && (index(l[i], ord) > 0 || index(l[i], ex) > 0)) ok = 1
            if (!ok) n++
        }
        END { print n + 0 }
    ' "$1"
}
vq_sites() { # → 전 러너의 판정 자리 총수 (추출 positive-control — 0이면 검사가 공허하다)
    _vqs=0
    for _vf in "$ROOT"/tests/*/run.ps1; do
        _vqs=$((_vqs + $(LC_ALL=C grep -vE '^[[:space:]]*#' "$_vf" | LC_ALL=C grep -cF -- "$VERDICT_MARK")))
    done
    echo "$_vqs"
}
vq_total() { # → 전 러너의 미고정·미선언 자리 총수
    _vqt=0
    for _vf in "$ROOT"/tests/*/run.ps1; do
        _vqt=$((_vqt + $(vq_scan "$_vf")))
    done
    echo "$_vqt"
}
vq_fixture() { # <모드> → 사본 경로
    # unpin: Ordinal 토큰을 지운다 · nodecl: 면제 선언을 지운다 · redecl: unpin 자리에 면제를 선언한다
    _vqf="$SBX/vq-$1.ps1"
    case "$1" in
        nodecl) _vqsrc="$ROOT/tests/multi-repo/run.ps1" ;;
        *)      _vqsrc="$ROOT/tests/mutation/run.ps1" ;;
    esac
    LC_ALL=C awk -v mode="$1" -v mark="$VERDICT_MARK" -v ord="$VERDICT_ORD" -v ex="$VERDICT_EXEMPT" '
        {
            s = $0
            if (mode != "nodecl" && index(s, ord) > 0) {
                p = index(s, ord); s = substr(s, 1, p - 1) "zzz-unpinned" substr(s, p + length(ord))
                if (mode == "redecl") s = s "   # " ex " zzz-fixture"
            }
            if (mode == "nodecl") { p = index(s, ex); if (p > 0) s = substr(s, 1, p - 1) }
            print s
        }
    ' "$_vqsrc" > "$_vqf"
    printf '%s' "$_vqf"
}
if part_on Q; then
chk "Q1: 판정 자리 추출 positive-control(>0)" "$([ "$(vq_sites)" -gt 0 ] && echo ok || echo no)" "ok"
chk "Q2: 본 검사 - 미고정·미선언 판정 자리 0건" "$(vq_total)" "0"
# 픽스처 통제 — **실제 판정을 사본에 건다**(M46 판례). 두 방향을 각각 깬다.
chk "Q3: 픽스처 통제 - Ordinal을 잃으면 잡는다" "$(vq_scan "$(vq_fixture unpin)")" "1"
chk "Q4: 픽스처 통제 - 면제 선언을 잃으면 잡는다" "$(vq_scan "$(vq_fixture nodecl)")" "1"
# 오탐 방향 — **선언한 자리는 통과한다**. 여기서 붉으면 면제 경로가 죽은 것이고, 그러면 규약이
# 「선언하면 된다」고 적는 것이 거짓이 된다.
chk "Q5: 오탐 방향 - 미고정이어도 선언하면 통과" "$(vq_scan "$(vq_fixture redecl)")" "0"
fi

# --- Part R: 릴리즈 커버리지 bookkeeping 선언 정합 (M58) ---------------------
# 커버리지 체크가 대상에서 빼는 집합이 **규약과 릴리즈 스킬 두 곳**에 적혀 있었고 기계가 둘을
# 묶지 않았다 — 한쪽만 고치면 조용히 갈라지는 부류이고, 이 저장소가 커맨드 수·상태 값 집합·
# phase 명단에서 이미 닫은 형태다. 단일 선언처는 규약의 `coverage-bookkeeping:` 한 줄이고
# 소비자는 **가리키기만** 한다. 토큰을 추상 이름(`bk-…`)으로 둔 이유는 버전 파일이 프로젝트마다
# 다르고, 경로를 토큰으로 쓰면 소비자가 다른 뜻으로 그 경로를 말하기만 해도 복제로 오인되기
# 때문이다(규약이 같은 사유를 적는다).
BK_KEY='coverage-bookkeeping:'
bk_tokens() { decl_tail "$CONV" "$BK_KEY"; }
bk_dup_in() { # <파일> → 그 파일에 등장하는 **서로 다른** bk 토큰 수
    _bkn=0
    for _bkt in $(bk_tokens); do
        [ "$(has_token "$1" "$_bkt")" = yes ] && _bkn=$((_bkn + 1))
    done
    echo "$_bkn"
}
bk_fixture() { # → 릴리즈 스킬 사본에 토큰 하나를 심은 것 (실제 판정을 사본에 건다)
    _bkf="$SBX/rel-bk.md"
    { cat "$REL_SKILL"; printf 'zzz %s zzz\n' "$(bk_tokens | LC_ALL=C awk '{ print $1; exit }')"; } > "$_bkf"
    printf '%s' "$_bkf"
}
if part_on R; then
chk "R1: coverage-bookkeeping 선언 줄 정확히 1개" "$(decl_count "$CONV" "$BK_KEY")" "1"
# (R2) 추출 positive-control — 토큰이 0개면 아래 본 검사가 «복제 0»으로 공허하게 통과한다.
chk "R2: 토큰 추출 positive-control(>0)" "$([ "$(bk_tokens | LC_ALL=C awk '{ print NF }')" -gt 0 ] && echo ok || echo no)" "ok"
# (R3) **본 검사.** 소비자가 목록을 다시 열거하면 그 자리가 두 번째 선언처가 된다.
chk "R3: 본 검사 - release 스킬이 목록을 다시 열거하지 않는다" "$(bk_dup_in "$REL_SKILL")" "0"
# 픽스처 통제 — **실제 판정을 사본에 건다**(M46 판례). 토큰이 새면 잡아야 한다.
chk "R4: 픽스처 통제 - 토큰이 새면 잡는다" "$(bk_dup_in "$(bk_fixture)")" "1"
# (R5) 배선 — 열거하지 않는 것만으로는 부족하다. **목록을 통째로 지워도** R3은 0이라 초록이므로,
# 소비자가 선언 이름을 **가리키는지**를 함께 문다(그러지 않으면 이 검사가 공허해진다).
chk "R5: 배선 - release 스킬이 선언 이름을 가리킨다" "$(has_token "$REL_SKILL" "$BK_KEY")" "yes"
fi

# --- Part S: 게시 가용성 축 · 게시 불가 종료 선언 정합 (M59) ------------------
# release 절차가 「닿는 원격이 있다」를 전제해 원격 불가 환경에서 정상 결과가 실패로 보고되던
# 자리를 M59가 닫았다. 세운 것은 축 둘의 **이름**이고(`push-availability`가 게시 축과 분리된
# push 축, `unpublished-release`가 그 축이 불통과일 때의 성공 종료), 이름은 스킬·카탈로그에
# **재서술**되므로 선언처가 갈리면 조용히 낡는다 — Part E·R이 이미 닫은 형태다. 선언은 규약
# 조각 한 곳이고 소비자는 **가리키기만** 한다.
PA_KEY='push-availability:'
TS_KEY='terminal-state:'
CMD_CANON="$ROOT/docs/commands.md"
ts_token() { decl_tail "$CONV_REL" "$TS_KEY" | LC_ALL=C awk '{ print $1; exit }'; }
pa_token() { decl_tail "$CONV_REL" "$PA_KEY" | LC_ALL=C awk '{ print $1; exit }'; }
ts_fixture() { # → 종료 상태 토큰을 **지운** 릴리즈 스킬 사본(실제 판정을 사본에 건다)
    _tsf="$SBX/rel-ts.md"
    _tst=$(ts_token)
    # 토큰이 비면 `sed s///`가 모든 줄을 건드려 통제가 뜻을 잃는다 — 그때는 원본을 그대로 둬
    # S7이 붉게 두고(공허한 초록 금지), 원인은 S3의 추출 통제가 지목한다.
    if [ -n "$_tst" ]; then
        LC_ALL=C sed "s/$_tst/zzz/g" "$REL_SKILL" > "$_tsf"
    else
        cat "$REL_SKILL" > "$_tsf"
    fi
    printf '%s' "$_tsf"
}
if part_on S; then
chk "S1: push-availability 선언 줄 정확히 1개" "$(decl_count "$CONV_REL" "$PA_KEY")" "1"
chk "S2: terminal-state 선언 줄 정확히 1개" "$(decl_count "$CONV_REL" "$TS_KEY")" "1"
# (S3) 추출 positive-control — 꼬리가 비면 아래 본 검사가 빈 토큰을 찾아 **공허하게** 갈린다.
chk "S3: 두 선언 꼬리 추출 positive-control"     "$([ -n "$(pa_token)" ] && [ -n "$(ts_token)" ] && echo ok || echo no)" "ok"
# (S4·S5) **본 검사** — 종료 상태 이름이 소비자 둘에 실제로 가 있는가. 규약에서 값을 바꾸면
# 여기가 붉어 재서술처가 함께 고쳐진다.
chk "S4: 본 검사 - release 스킬이 종료 상태 이름을 갖는다" "$(has_token "$REL_SKILL" "$(ts_token)")" "yes"
chk "S5: 본 검사 - 커맨드 카탈로그가 종료 상태 이름을 갖는다" "$(has_token "$CMD_CANON" "$(ts_token)")" "yes"
fi
# (S6) 배선 — 종료 상태만 물으면 **축 이름**이 사라져도 초록이다(축이 종료 상태의 트리거다).
# 무는 것은 선언 **키**가 아니라 그 키가 이름 붙인 **병기어**다(키의 꼬리 콜론을 벗긴 것) —
# 소비자에 재서술되는 것이 병기어이기 때문이다(규약의 ASCII 병기어 규율).
pa_name() { printf '%s' "${PA_KEY%:}"; }
if part_on S; then
chk "S6: 배선 - release 스킬이 push 축 이름을 갖는다" "$(has_token "$REL_SKILL" "$(pa_name)")" "yes"
# (S7) 픽스처 통제 — **실제 판정을 사본에 건다**(M46 판례). 이름이 빠지면 S4가 잡아야 한다.
chk "S7: 픽스처 통제 - 이름이 빠지면 잡는다" "$(has_token "$(ts_fixture)" "$(ts_token)")" "no"
fi

# --- Part T: 러너 소스 개행 계약 (M59 리뷰 차단 1 → M60) --------------------
# `.gitattributes`가 `*.sh`를 `eol=lf`로 못박고 사유까지 적어 두었는데 확인하는 기계가 0개였다.
# M59에서 `run.sh`가 CRLF가 되자 **dash만** 즉사하고 bash·양 PowerShell은 초록이었다 — 「양 사본
# 동일」도 「네 환경 동수」도 이 형태를 덮지 못한다. 패턴의 선언처는 `.gitattributes` 한 곳이고
# 러너는 읽기만 한다(규약의 `source-eol:` 선언이 그 자리를 가리킨다).
EOL_KEY='source-eol:'
GITATTR="$ROOT/.gitattributes"
eol_globs() { # [경로] → `.gitattributes`에서 eol=lf를 건 패턴 토큰(줄당 첫 낱말) 한 줄씩
    # 경로를 인자로 받는 이유는 `T7`이 **다른 파일을 먹여** 추출이 상수가 아니라 파일을 읽는지
    # 확인하기 때문이다 — 그러지 않으면 「하드코딩하지 않았다」가 주장으로만 남는다.
    _ega="${1:-$GITATTR}"
    [ -f "$_ega" ] || return 0
    LC_ALL=C awk '
        { s = $0; sub(/\r$/, "", s) }
        s ~ /^[[:space:]]*#/ { next }
        s ~ /eol=lf/ { n = split(s, f, /[ 	]+/); for (i = 1; i <= n; i++) if (f[i] != "") { print f[i]; break } }
    ' "$_ega"
}
eol_ga_fixture() { # → 다른 패턴을 담은 `.gitattributes` 사본
    _egf="$SBX/gitattr-probe"
    printf '# probe
*.zzz text eol=lf
' > "$_egf"
    printf '%s' "$_egf"
}
eol_files() { # → 그 패턴에 걸리는 추적 파일 경로 한 줄씩 (중복 제거)
    for _eg in $(eol_globs); do
        git -C "$ROOT" ls-files "$_eg" 2>/dev/null
    done | LC_ALL=C sort -u
}
crlf_in() { # <file> -> yes when the file carries any CR byte
    # **awk must not be used here.** Measured (M60): Git Bash's gawk reads files in TEXT mode and
    # strips the trailing CR before the record is seen, so `index($0, cr)` returns 0 for a real
    # CRLF file -- the check would be VACUOUS on exactly the shell pair this repo runs. `tr` and
    # `cmp` are byte-oriented in both shells (verified: dash and bash agree), so the judgment is
    # "does stripping CR change the bytes". A CRLF checker that cannot see CRLF is its own first
    # failure, so the detection method is measured, not assumed.
    [ -f "$1" ] || { echo no; return; }
    _cn="$SBX/crlf-probe.$$"
    LC_ALL=C tr -d '\r' < "$1" > "$_cn"
    if cmp -s "$1" "$_cn"; then rm -f "$_cn"; echo no
    else rm -f "$_cn"; echo yes; fi
}
eol_bad() { # [extra file] -> number of target files that carry CRLF
    _eb=0
    for _ef in $(eol_files); do
        [ "$(crlf_in "$ROOT/$_ef")" = yes ] && _eb=$((_eb + 1))
    done
    if [ -n "${1-}" ]; then
        [ "$(crlf_in "$1")" = yes ] && _eb=$((_eb + 1))
    fi
    echo "$_eb"
}
eol_fixture() { # <lf|crlf> -> sandbox copy (the REAL verdict runs on the copy)
    _efx="$SBX/eol-$1.sh"
    if [ "$1" = crlf ]; then
        printf 'a%sb%s' "$(printf '\r')" "$(printf '\r')" > "$_efx"
    else
        printf 'a
b
' > "$_efx"
    fi
    printf '%s' "$_efx"
}
if part_on T; then
chk "T1: source-eol 선언 줄 정확히 1개" "$(decl_count "$CONV" "$EOL_KEY")" "1"
# (T2) 추출 positive-control — 패턴이 0개면 아래 「검출 0」이 공허하다.
chk "T2: eol=lf 패턴 추출 positive-control(>0)" "$([ "$(eol_globs | grep -c .)" -gt 0 ] && echo ok || echo no)" "ok"
# (T3) 대상 positive-control — 패턴은 있는데 걸리는 추적 파일이 0개여도 같은 공허가 된다.
chk "T3: 대상 추적 파일 positive-control(>0)" "$([ "$(eol_files | grep -c .)" -gt 0 ] && echo ok || echo no)" "ok"
# (T4) **본 검사.** 선언된 계약을 실제 트리가 지키는가.
chk "T4: 본 검사 - CRLF를 가진 대상 파일 0개" "$(eol_bad)" "0"
# (T5) 픽스처 통제 — **실제 판정 함수**를 사본에 건다(M46 판례).
chk "T5: 픽스처 통제 - CRLF 사본을 잡는다" "$(crlf_in "$(eol_fixture crlf)")" "yes"
# (T6) 음성 통제 — LF만 있는 사본은 붉지 않는다(오탐 방향).
chk "T6: 음성 통제 - LF 사본은 통과" "$(crlf_in "$(eol_fixture lf)")" "no"
# (T7) 배선 — **패턴이 상수가 아니라 파일에서 온다**는 것을 픽스처로 문다. 반증(M60 리뷰)이 이
# 자리를 열었다: 앞선 판본은 `has_token "$GITATTR" 'eol=lf'`라 **주석 처리된 선언에도 초록**이었고
# T2보다 약해 **독립으로 붉을 수 없었다** — 검사가 아니라 주장이었다.
chk "T7: 배선 - 다른 .gitattributes를 주면 추출이 그것을 따른다" "$(eol_globs "$(eol_ga_fixture)")" "*.zzz"
fi

# --- Part U: 측정 시점 규율 + 대조의 조용한 제외 노출 (M60) ------------------
# 하니스는 impl 보고서를 **입력으로 읽는데**(Part P), `crit_targets`가 보고서 없는 마일스톤을
# 조용히 건너뛴다. 그래서 보고서 이전에 잰 값은 「그 사이클을 아예 보지 않은 초록」이었고,
# M59가 정확히 그 순서로 돌아 차단 둘이 리뷰까지 살아남았다. **필터는 유지한다** — 없애면 impl
# 작업 중 늘 붉어 하니스가 진행 신호로 못 쓰인다. 고치는 것은 **침묵**이다.
MO_KEY='measure-order:'
IMPL_SKILL="$ROOT/skills/impl/SKILL.md"
IMPL_TPL="$ROOT/skills/impl/template.md"
mo_name() { decl_tail "$CONV" "$MO_KEY" | LC_ALL=C awk '{ print $1; exit }'; }
# `criteria-since` 이상인데 impl 보고서가 없어 대조에서 빠진 마일스톤 번호(한 줄씩).
skipped_ms() { # [추가 마일스톤 번호] → 제외된 번호
    for _sm0 in "$ROOT"/docs/milestones/M*.md; do
        _sn=$(basename "$_sm0" .md | sed 's/^M//')
        [ "$_sn" -ge "$CRITN" ] || continue
        [ -f "$ROOT/docs/reports/M$_sn-impl.md" ] || echo "$_sn"
    done
    [ -n "${1-}" ] && echo "$1"
    return 0
}
skipped_n() { skipped_ms "${1-}" | grep -c .; }
if part_on U; then
chk "U1: measure-order 선언 줄 정확히 1개" "$(decl_count "$CONV" "$MO_KEY")" "1"
# (U2) 추출 positive-control — 꼬리가 비면 아래 결합이 빈 토큰으로 공허하게 성립한다.
chk "U2: 병기어 추출 positive-control" "$([ -n "$(mo_name)" ] && echo ok || echo no)" "ok"
# (U3~U5) **본 검사** — 규율이 재서술되는 세 자리에 병기어가 실제로 가 있는가.
chk "U3: 본 검사 - impl 스킬이 병기어를 갖는다" "$(has_token "$IMPL_SKILL" "$(mo_name)")" "yes"
chk "U4: 본 검사 - impl 템플릿이 병기어를 갖는다" "$(has_token "$IMPL_TPL" "$(mo_name)")" "yes"
chk "U5: 본 검사 - release 스킬이 병기어를 갖는다" "$(has_token "$REL_SKILL" "$(mo_name)")" "yes"
# (U6) **조용한 제외 노출.** 대조에서 빠진 마일스톤이 있으면 그 수가 여기 드러난다 — 보고서 이전에
# 잰 측정은 이 값이 0이 아니고, 그것이 「그 사이클을 보지 않았다」의 기계적 신호다.
chk "U6: 대조에서 제외된 마일스톤 0개" "$(skipped_n)" "0"
# (U7) 픽스처 통제 — 노출이 공허하지 않다. **차이로 묻는다**: 기준선이 0이 아닐 수 있고(작업 중
# 사이클이 정확히 그 상태다) 절대값으로 물으면 그때 통제가 기준선을 재게 된다.
chk "U7: 픽스처 통제 - 제외가 하나 늘면 수도 하나 는다" "$(( $(skipped_n 9999) - $(skipped_n) ))" "1"
fi


# --- Part V: 되돌림 표를 기계가 읽는다 (M61) ---------------------------------
# 체크리스트의 **되돌림 실측**은 *"각 케이스를 개별로 되돌려 그 케이스가 붉어지는 것을 확인한다"* 를
# 요구하는데, **그것이 지켜졌는지를 아무도 묻지 않았다.** M60의 `T7`이 실례다 — 문서에는 배선을
# 검사한다고 적혀 있었으나 구현은 토큰 존재만 보아 `T2`보다 엄격히 약했고, 되돌림 여덟 행에서
# **단독으로 붉은 적이 없었다**(항상 `T2`·`T3`과 함께만). **표를 읽을 수 있었다면 기계가 지목했을
# 것이다.** 그 표를 **선언 형식**으로 만들고 여기서 읽는다. 형식의 단일 원본은 규약이다.
if part_on V; then
RVB_KEY='reversal-block:'
RVC_KEY='reversal-columns:'
RVS_KEY='reversal-sep:'
RVN_KEY='reversal-since:'
RVA_KEY='mutation-axes:'
# **선언을 잃었을 때의 기본값을 두 사본에 못박는다**(`criteria-since:`와 같은 기전). 그냥 두면 빈
# 마커가 **모든 줄**에 맞아 창이 통째로 열리고, 빈 구분자는 쪼개기를 무한 루프로 만든다 — 같은
# 트리에서 두 사본이 다른 값을 낸다. 나타나지 않는 토큰으로 두면 **행이 0이 되어 `V6`이 붉는다.**
# **양 사본이 같은 형태로 폴백해야 한다**(M61 리뷰 권장 2): ps1 사본이 `null`에서 죽으면 그 트리는
# sh에서 「케이스를 이름으로 지목」인데 ps1에서 「완주 못 함」이 된다 — 같은 트리, 다른 형태다.
RVBLK=$(decl_tail "$CONV" "$RVB_KEY" | LC_ALL=C awk '{ print $1 }')
[ -n "$RVBLK" ] || RVBLK=zzz-reversal-block-unset
RVSEP=$(decl_tail "$CONV" "$RVS_KEY" | LC_ALL=C awk '{ print $1 }')
[ -n "$RVSEP" ] || RVSEP=zzz-reversal-sep-unset
RVCOL=$(decl_tail "$CONV" "$RVC_KEY" | LC_ALL=C awk '{ $1 = $1; print }')
# 축 값 집합은 `mutation-axes:` 선언에서 온다 — 러너는 축의 **이름을 알지 않는다**. 선언에서
# 백틱을 걷어낸 것이 곧 집합이고, 비면 아래 축 판정이 **모든 칸을 집합 밖으로 세어 붉는다**.
RVAX=$(decl_tail "$CONV" "$RVA_KEY" | LC_ALL=C tr -d '`' | LC_ALL=C awk '{ $1 = $1; print }')
RVN=999999
_rvs0=$(decl_tail "$CONV" "$RVN_KEY" | LC_ALL=C awk '{ print $1 }')
case "$_rvs0" in
    M*) _rvs1=${_rvs0#M}
        case "$_rvs1" in
            "" | *[!0-9]*) ;;
            *) RVN=$_rvs1 ;;
        esac ;;
esac
fi
rv_col() { # <토큰> → 선언된 열 순서에서 그 열의 1-기반 위치 (없으면 0)
    printf '%s\n' "$RVCOL" | LC_ALL=C awk -v t="$1" '{ for (i = 1; i <= NF; i++) if ($i == t) { print i; exit } ; print 0; exit }'
}
rv_targets() { # <시작 번호> → 대상 마일스톤 번호 (그 번호 이상 + impl 보고서 실재)
    for _rm0 in "$ROOT"/docs/milestones/M*.md; do
        _rn0=$(basename "$_rm0" .md | sed 's/^M//')
        [ "$_rn0" -ge "$1" ] || continue
        [ -f "$ROOT/docs/reports/M$_rn0-impl.md" ] || continue
        echo "$_rn0"
    done
}
rv_rep() { # <번호> [사본] → 그 번호가 대상 사본이면 사본을, 아니면 실물을
    if [ -n "${2-}" ] && [ "$1" = "$RVN" ]; then printf '%s' "$2"
    else printf '%s' "$ROOT/docs/reports/M$1-impl.md"; fi
}
rv_colcells() { # <보고서> <열 토큰> [마커 이름] → 마커 구획 표에서 그 열의 칸(정규화) 한 줄씩
    # 머리글 건너뛰기는 구조로 한다 — 창 안에서 구분선(`---`)을 본 **뒤의** 행만 데이터다.
    # **창은 줄 전체 일치로 연다 — 언급은 마커가 아니다**(M61 impl 실측이 연 자리). `index()`로
    # 넓히면 **보고서 산문이 마커 이름을 말하는 순간 창이 거기서 열려** 엉뚱한 표(완료 기준 대조)를
    # 되돌림 행으로 읽는다. 실제로 이 사이클의 보고서가 근거 칸에서 마커를 인용해 그 상태가 됐고,
    # 그때 `V6`이 **초록인 채** `V8`만 붉었다 — 즉 추출 positive-control이 **공허**했다. 같은 판례가
    # `tests/site-includes`에도 있다(`--8<-- ` 접두가 있어야 진짜 섹션 마커다).
    # **열은 이름으로 고르고 위치는 선언에서 온다** — 그래야 머리글을 한국어로 쓰면서 러너가 한글
    # 리터럴을 갖지 않는다.
    [ -f "$1" ] || return 0
    _rvm=${3-}
    [ -n "$_rvm" ] || _rvm=$RVBLK
    LC_ALL=C awk -v cr="$(printf '\r')" -v s="<!-- $_rvm:start -->" -v e="<!-- $_rvm:end -->" -v ci="$(rv_col "$2")" '
        { t = $0; if (length(t) > 0 && substr(t, length(t), 1) == cr) t = substr(t, 1, length(t) - 1) }
        w != 1 && t == s { w = 1; sep = 0; next }
        w == 1 && t == e { w = 0; next }
        w == 1 && substr(t, 1, 1) == "|" {
            if (sep == 0) { if (index(t, "---") > 0) sep = 1; next }
            n = split(t, f, "|")
            if (ci < 1 || n < ci + 2) next
            a = f[ci + 1]
            gsub(/[ \r*]/, "", a)
            if (a == "") next
            print a
        }
    ' "$1"
}
rv_rows() { # <보고서> [마커 이름] → `reddened` 칸(정규화) 한 줄씩
    rv_colcells "$1" reddened "${2-}"
}
rv_main() { # <보고서> [마커 이름] → 블록 안 선언 줄이 든 「본 검사」 케이스 이름 한 줄씩
    [ -f "$1" ] || return 0
    _rvm1=${2-}
    [ -n "$_rvm1" ] || _rvm1=$RVBLK
    LC_ALL=C awk -v cr="$(printf '\r')" -v s="<!-- $_rvm1:start -->" -v e="<!-- $_rvm1:end -->" -v k="<!-- $_rvm1-main:" '
        { t = $0; if (length(t) > 0 && substr(t, length(t), 1) == cr) t = substr(t, 1, length(t) - 1) }
        w != 1 && t == s { w = 1; next }
        w == 1 && t == e { w = 0; next }
        w == 1 {
            p = index(t, k)
            if (p == 0) next
            r = substr(t, p + length(k))
            q = index(r, "-->")
            if (q > 0) r = substr(r, 1, q - 1)
            n = split(r, f, " ")
            for (i = 1; i <= n; i++) if (f[i] != "") print f[i]
            exit
        }
    ' "$1"
}
rv_solo() { # <칸 목록> <케이스 이름> → 그 케이스 **하나뿐인** 칸이 있으면 yes
    # 구분자로 쪼개 **필드가 하나이고 그것이 그 케이스**인 칸을 찾는다. 여럿을 붉힌 행은 여기서
    # 세지 않는다 — 그것이 `T7`이 여덟 행 내내 있던 자리이고, 이 절이 무는 것 자체다.
    printf '%s\n' "$1" | LC_ALL=C awk -v sep="$RVSEP" -v c="$2" '
        found == 0 {
            n = 0; hit = 0; s = $0
            while (1) {
                p = index(s, sep)
                if (p == 0) { u = s } else { u = substr(s, 1, p - 1) }
                if (u != "") { n++; if (u == c) hit = 1 }
                if (p == 0) break
                s = substr(s, p + length(sep))
            }
            if (n == 1 && hit == 1) found = 1
        }
        END { print (found == 1) ? "yes" : "no" }
    '
}
rv_lonely() { # [사본] [마커 이름] → 단독 행이 없는 「본 검사」 케이스 수
    _rvl=0
    for _rn1 in $(rv_targets "$RVN"); do
        _rrep=$(rv_rep "$_rn1" "${1-}")
        _rmain=$(rv_main "$_rrep" "${2-}")
        [ -n "$_rmain" ] || continue
        _rrows=$(rv_rows "$_rrep" "${2-}")
        for _rc in $_rmain; do
            [ "$(rv_solo "$_rrows" "$_rc")" = yes ] || _rvl=$((_rvl + 1))
        done
    done
    echo "$_rvl"
}
rv_rows_n() { # [사본] [마커 이름] → 대상 전체의 되돌림 행 수
    _rvr=0
    for _rn2 in $(rv_targets "$RVN"); do
        _rvr=$((_rvr + $(rv_rows "$(rv_rep "$_rn2" "${1-}")" "${2-}" | grep -c .)))
    done
    echo "$_rvr"
}
rv_main_n() { # → 대상 전체의 선언된 「본 검사」 케이스 수
    for _rn3 in $(rv_targets "$RVN"); do rv_main "$ROOT/docs/reports/M$_rn3-impl.md"; done | grep -c .
}
rv_unread() { # <보고서> → 단독 판정이 **읽을 수 없는** 보고서면 1 (행이 0이거나 목록이 비었다)
    # **세는 침묵과 건너뛰는 침묵을 같은 집합으로 둔다**(M61 리뷰 라운드 1의 차단). 앞선 판본은
    # `rv_lonely`가 **`-main` 줄이 빈 것**을 건너뛰면서 여기서는 **행이 0인 것**만 셌다 — 두 집합이
    # 어긋나 「표는 있고 `-main` 줄만 없는 보고서」가 **차집합에 그대로 남았다.** 조건을 합친다.
    [ "$(rv_rows "$1" | grep -c .)" -gt 0 ] || { echo 1; return; }
    [ -n "$(rv_main "$1")" ] || { echo 1; return; }
    echo 0
}
rv_noblock() { # <시작 번호> [추가 보고서 경로] → 단독 판정이 읽지 못하는 보고서 수
    # `rv_lonely`가 그런 보고서를 **건너뛰므로**(그래야 작업 중 사이클이 늘 붉지 않는다) 그 침묵을
    # 여기서 센다 — `criteria-since:` 쪽의 `U6`와 **같은 형태**다.
    _rvb=0
    for _rn4 in $(rv_targets "$1"); do
        _rvb=$((_rvb + $(rv_unread "$ROOT/docs/reports/M$_rn4-impl.md")))
    done
    if [ -n "${2-}" ]; then
        _rvb=$((_rvb + $(rv_unread "$2")))
    fi
    echo "$_rvb"
}
rv_mainbad() { # <보고서> [마커 이름] → 목록 선언이 **규정된 한 줄의 형태**가 아니면 1
    # **부정 검사를 더하지 않고 한 줄의 형태를 통째로 단언한다**(M61 리뷰 라운드 4의 차단). 이 자리는
    # 다섯 라운드에 걸쳐 **같은 줄의 변종**으로 다섯 번 열렸다 — ⑴ 블록 부재 ⑵ 두 침묵의 차집합
    # ⑶ 줄 복제 ⑷ 줄 접기 ⑸ **닫는 태그 뒤에 남은 이름**. 매번 처방이 **금지 조건을 하나 더하는**
    # 형태였고 그래서 다음 변종이 남았다. 마지막 변종의 실측이 그것을 못박는다: 마지막 이름을
    # `-->` **뒤로** 옮기면 그 줄은 「닫힌 선언」이라 종전 판정이 통과하는데, `rv_main`은 `-->`에서
    # 끊으므로 그 이름은 **단독 행 판정의 대상에서 사라지고 `V8`이 거짓 초록**이 됐다(345/0 전 축 초록).
    # **형태를 통째로 물으면 넷이 한 판정에 걸리고, 형태를 벗어나는 다음 변종도 그 순간 걸린다.**
    #
    # **규정**(규약이 단일 원본): 창 안에 목록 줄은 **정확히 하나**이고, 그 줄은 앞뒤 공백을 뺀
    # 나머지가 **키로 시작해 `-->`로 끝나며** 그 사이는 **ASCII 영숫자·하이픈 이름을 공백으로 가른
    # 목록**뿐이다(빈 목록도 형태로는 유효하다 — 비어 있다는 사실은 `rv_unread`가 따로 센다).
    # **이름 규칙을 상수 정규식으로 둔다** — 마커 이름은 고정 문자열 비교로만 쓰므로 두 사본이
    # 정규식 방언(POSIX ERE ↔ .NET)으로 갈릴 자리가 없다.
    # **0줄은 `rv_unread`가 이미 세므로** 여기서는 세지 않는다(두 판정이 같은 상태를 두 번 세지 않는다).
    # 이 판정이 곧 **`nosolo` 픽스처가 기대는 전제의 집행**이다 — 그 픽스처는 `-main` 줄에 `-->`가
    # 같은 줄에 있을 때만 동작하고, 없으면 **무동작이 되어 통제가 붉는데 깨진 것은 통제의 대상이
    # 아니다**(M61 리뷰 라운드 3의 권장 3). 전제를 규약이 선언하고 여기서 문다.
    [ -f "$1" ] || { echo 0; return; }
    _rvml=${2-}
    [ -n "$_rvml" ] || _rvml=$RVBLK
    LC_ALL=C awk -v cr="$(printf '\r')" -v s="<!-- $_rvml:start -->" -v e="<!-- $_rvml:end -->" -v k="<!-- $_rvml-main:" '
        { t = $0; if (length(t) > 0 && substr(t, length(t), 1) == cr) t = substr(t, 1, length(t) - 1) }
        w != 1 && t == s { w = 1; next }
        w == 1 && t == e { w = 0; next }
        w == 1 {
            p = index(t, k)
            if (p == 0) next
            n++
            u = t
            gsub(/^[ \t]+/, "", u); gsub(/[ \t]+$/, "", u)
            if (substr(u, 1, length(k)) != k) { bad++; next }
            if (length(u) < length(k) + 3 || substr(u, length(u) - 2) != "-->") { bad++; next }
            mid = substr(u, length(k) + 1, length(u) - length(k) - 3)
            if (mid !~ /^([ \t]+[A-Za-z0-9-]+)*[ \t]*$/) bad++
        }
        END { print (n >= 2 || bad > 0) ? 1 : 0 }
    ' "$1"
}
rv_mainbadn() { # <시작 번호> [추가 보고서] → 목록 선언의 형태가 깨진 대상 보고서 수
    _rvmm=0
    for _rn7 in $(rv_targets "$1"); do
        _rvmm=$((_rvmm + $(rv_mainbad "$ROOT/docs/reports/M$_rn7-impl.md")))
    done
    if [ -n "${2-}" ]; then
        _rvmm=$((_rvmm + $(rv_mainbad "$2")))
    fi
    echo "$_rvmm"
}
rv_axisbad() { # [사본] → 축 칸이 **선언 집합 밖**이거나 **비어 있는** 수
    # 축을 열로 두고 값 집합을 `mutation-axes:`에서 읽는다. 열만 만들고 값을 안 재면 그것이
    # **죽은 선언**이고, 이 사이클이 `reversal-sep:`에서 정확히 그 지적을 받았다(M61 리뷰 권장 5).
    _rab=0
    for _rn5 in $(rv_targets "$RVN"); do
        _rrep2=$(rv_rep "$_rn5" "${1-}")
        _nrow=$(rv_colcells "$_rrep2" row | grep -c .)
        _nax=0
        for _rv in $(rv_colcells "$_rrep2" axis); do
            _nax=$((_nax + 1))
            case " $RVAX " in
                *" $_rv "*) ;;
                *) _rab=$((_rab + 1)) ;;
            esac
        done
        _rab=$((_rab + _nrow - _nax))
    done
    echo "$_rab"
}
rv_cellbad() { # [사본] [구분자] → 붉은 케이스 칸의 **빈 이름·중복 이름** 수
    # **구분자 선언을 실제로 쓰는 자리**다(M61 리뷰 권장 5). 단독 판정만으로는 구분자가 무엇이든
    # 결과가 같아 선언이 **죽어 있었다** — 여기서는 다른 구분자를 주면 `A<sep>A`를 **못 쪼개** 중복을
    # 놓치므로 `V23`이 그 배선을 확인한다.
    _rcb=0
    _rsep=${2-}
    [ -n "$_rsep" ] || _rsep=$RVSEP
    for _rn6 in $(rv_targets "$RVN"); do
        _rrep3=$(rv_rep "$_rn6" "${1-}")
        _rcb=$((_rcb + $(rv_colcells "$_rrep3" reddened | LC_ALL=C awk -v sep="$_rsep" '
            {
                split("", seen); bad = 0; s = $0; hassep = (index(s, sep) > 0)
                while (1) {
                    p = index(s, sep)
                    if (p == 0) { u = s } else { u = substr(s, 1, p - 1) }
                    if (u == "") { if (hassep) bad++ }
                    else { if (u in seen) bad++; seen[u] = 1 }
                    if (p == 0) break
                    s = substr(s, p + length(sep))
                }
                t += bad
            }
            END { print t + 0 }
        ')))
    done
    echo "$_rcb"
}
rv_tpl_markers() { # → impl 템플릿이 마커 쌍과 **창 안의 규정된 목록 줄**을 가지면 ok
    # **`-main` 줄도 센다**(M61 리뷰 라운드 1) — 마커 쌍만 세면 템플릿이 그 줄을 잃어도 초록이고,
    # 그러면 다음 보고서가 목록을 갖지 못한 채 나온다(위 `rv_unread`가 무는 상태로 직행한다).
    # **세는 자리를 창 안으로 좁히고 형태까지 묻는다**(M61 리뷰 라운드 4의 기록 — impl 후속 7·9가
    # 같은 함수의 같은 사각이었다). 종전에는 ⑴ 그 줄이 **블록 밖으로 나가도** 초록이었고 ⑵ **접혀
    # 있어도** 초록이었다 — 실물 보고서 쪽은 창 안만 읽고 형태를 무는데 **템플릿만 헐거워서**,
    # 다음 사이클이 그 형태를 그대로 복사해 나오고 나서야 `V25`가 잡았다(한 겹 늦다).
    # 형태 판정은 `rv_mainbad`를 그대로 쓴다 — 술어가 둘로 갈리면 그 자체가 다음 변종의 자리다.
    _rvt="$ROOT/skills/impl/template.md"
    [ -f "$_rvt" ] || { echo no; return; }
    [ "$(rv_mainbad "$_rvt")" = 0 ] || { echo no; return; }
    LC_ALL=C awk -v cr="$(printf '\r')" -v s="<!-- $RVBLK:start -->" -v e="<!-- $RVBLK:end -->" -v k="<!-- $RVBLK-main:" '
        { t = $0; if (length(t) > 0 && substr(t, length(t), 1) == cr) t = substr(t, 1, length(t) - 1) }
        t == s { a++ }
        t == e { b++ }
        w != 1 && t == s { w = 1; next }
        w == 1 && t == e { w = 0; next }
        w == 1 && index(t, k) > 0 { c++ }
        END { print (a == 1 && b == 1 && c == 1) ? "ok" : "no" }
    ' "$_rvt"
}
rv_fixture() { # <모드> → 대상 보고서 사본 (clean|nosolo|nomarker|nomain|dupmain|foldmain|aftermain|mention|dupname|badaxis)
    # **원본이 없으면 빈 사본을 낸다**(M61 리뷰 라운드 1의 권장 2). `reversal-since:` 선언을 잃으면
    # 시작 번호가 폴백 값이 되고 그 값이 **경로로 역참조**되는데, ps1 사본은 그때 파일을 열다
    # **중단**했고 sh 사본은 완주했다 — 같은 트리에서 두 사본이 **다른 형태**로 실패했다.
    # 부재를 양쪽이 같은 방식으로 흡수하고, 대상이 0이 되는 사실은 `V6`·`V7`이 붉혀 드러낸다.
    _rvf="$SBX/rev-$1.md"
    _rvsrc="$ROOT/docs/reports/M$RVN-impl.md"
    if [ ! -f "$_rvsrc" ]; then : > "$_rvf"; printf '%s' "$_rvf"; return; fi
    LC_ALL=C awk -v mode="$1" -v cr="$(printf '\r')" -v s="<!-- $RVBLK:start -->" -v e="<!-- $RVBLK:end -->" -v k="<!-- $RVBLK-main:" -v sep="$RVSEP" -v ci="$(rv_col reddened)" -v ai="$(rv_col axis)" '
        { t = $0; if (length(t) > 0 && substr(t, length(t), 1) == cr) t = substr(t, 1, length(t) - 1) }
        mode == "nomarker" && (t == s || t == e) { next }
        # 산문이 마커를 **언급**하는 줄을 표 앞에 심는다 — 창이 부분 문자열로 열리면 여기서 열려
        # 아래 다른 표가 되돌림 행으로 읽힌다. 줄 전체 일치면 아무 일도 일어나지 않는다.
        mode == "mention" && done1 == 0 && substr(t, 1, 3) == "## " { done1 = 1; print "zzz-mention " s " in prose"; print t; next }
        mode == "nomain" && index(t, k) > 0 { next }
        # 목록 줄을 **하나 더** 만든다 — 사람 눈에는 선언한 것으로 보이는데 판정은 첫 줄에서 끝난다.
        mode == "dupmain" && index(t, k) > 0 { print t; print t; next }
        # 목록 줄을 **두 줄로 접는다** — 첫 줄에 키가 있고 `-->`가 **없다**. 키가 든 줄의 수는
        # 그대로 **1**이라 「줄 수」로 묻던 판정은 이 상태를 보지 못했다(라운드 3의 차단).
        mode == "foldmain" && index(t, k) > 0 {
            p = index(t, "-->")
            if (p > 1) { print substr(t, 1, p - 1); print "  zzz-folded -->"; next }
        }
        # 마지막 이름을 **닫는 태그 뒤로** 옮긴다 — 그 줄은 여전히 「닫힌 선언」이라 **닫힘만 묻던
        # 판정은 통과**했고, 그 사이 그 이름은 `rv_main`의 시야에서 사라졌다(라운드 4의 차단).
        mode == "aftermain" && index(t, k) > 0 {
            p = index(t, "-->")
            if (p > 1) { print substr(t, 1, p - 1) "--> zzz-after"; next }
        }
        mode == "nosolo" && index(t, k) > 0 {
            p = index(t, "-->")
            if (p > 1) { print substr(t, 1, p - 1) " zzz-nosolo -->"; next }
        }
        t == s { w = 1; sep0 = 0; print; next }
        w == 1 && t == e { w = 0; print; next }
        # **첫 데이터 행 하나만** 건드린다 — 판정이 그 한 행에서 갈리는지 보려는 것이다.
        w == 1 && done2 == 0 && substr(t, 1, 1) == "|" && (mode == "dupname" || mode == "badaxis") {
            if (sep0 == 0) { if (index(t, "---") > 0) sep0 = 1; print; next }
            n = split(t, f, "|")
            if (n >= 5) {
                done2 = 1
                if (mode == "dupname" && ci >= 1 && n >= ci + 2) f[ci + 1] = f[ci + 1] sep f[ci + 1]
                if (mode == "badaxis" && ai >= 1 && n >= ai + 2) f[ai + 1] = " zzz-not-an-axis "
                line = f[1]
                for (i = 2; i <= n; i++) line = line "|" f[i]
                print line; next
            }
        }
        w == 1 && sep0 == 0 && substr(t, 1, 1) == "|" { if (index(t, "---") > 0) sep0 = 1; print; next }
        { print t }
    ' "$_rvsrc" > "$_rvf"
    printf '%s' "$_rvf"
}
CF_KEY='control-form:'
SITE_README="$ROOT/tests/site-includes/README.md"
cf_name() { decl_tail "$CONV" "$CF_KEY" | LC_ALL=C awk '{ print $1; exit }'; }
cf_defn() { # <병기어> → 규약에서 그 병기어를 **정의하는 줄**의 수
    # **선언 값이 판정을 바꾸는 형태로 쓰인다**(M61 리뷰 라운드 3의 권장 2). 앞선 판본은 *"그
    # 문자열이 README 어딘가에 있는가"* 만 물어, 값을 `control-reads-delta` → `control`로 **줄여도**
    # `positive-control`에 **부분 일치**해 전 축이 초록이었다 — `reversal-sep:`가 `V21`~`V23`에서
    # 파싱을 실제로 바꾸는 것과 동형이 아니었다. 그래서 대조를 **백틱 토큰**으로 좁히고, 값을 **키로
    # 삼아 규약의 정의 줄을 찾는다**: 값이 달라지면 정의 줄이 없어 붉는다.
    grep -cF "$(printf '**`%s`**' "$1")" "$CONV" 2>/dev/null | LC_ALL=C awk 'NR == 1 { print $1 + 0 }'
}
cf_restated() { # <병기어> → 그 병기어를 **백틱 토큰**으로 가진 재서술처의 수
    # 재서술처는 **둘**이다(이 하니스 README + `tests/site-includes` README). 앞선 판본이 하나만
    # 묶어, 다른 쪽에서 사라져도 아무것도 붉지 않았다(M61 리뷰의 미검증 잔여 리스크 2).
    # `measure-order:`의 `U3`~`U5`가 재서술처 셋을 전부 묶은 것과 같은 형태로 맞춘다.
    _cft=$(printf '`%s`' "$1")
    _cfn=0
    for _cff in "$DISC_README" "$SITE_README"; do
        [ "$(has_token "$_cff" "$_cft")" = yes ] && _cfn=$((_cfn + 1))
    done
    echo "$_cfn"
}
if part_on V; then
chk "V1: control-form 선언 줄 정확히 1개" "$(decl_count "$CONV" "$CF_KEY")" "1"
chk "V2: reversal-block 선언 줄 정확히 1개" "$(decl_count "$CONV" "$RVB_KEY")" "1"
chk "V3: reversal-columns 선언 줄 정확히 1개" "$(decl_count "$CONV" "$RVC_KEY")" "1"
chk "V4: reversal-sep 선언 줄 정확히 1개" "$(decl_count "$CONV" "$RVS_KEY")" "1"
chk "V5: reversal-since 선언 줄 정확히 1개" "$(decl_count "$CONV" "$RVN_KEY")" "1"
# (V6·V7) 추출 positive-control 둘 — 어느 하나가 비면 아래 본 검사가 **0 == 0**으로 공허 통과한다.
chk "V6: 되돌림 행 추출 positive-control(>0)" "$([ "$(rv_rows_n)" -gt 0 ] && echo ok || echo no)" "ok"
chk "V7: 본 검사 목록 추출 positive-control(>0)" "$([ "$(rv_main_n)" -gt 0 ] && echo ok || echo no)" "ok"
# (V8) **본 검사.** 단독으로 붉는 행을 갖지 않는 「본 검사」 케이스가 있으면 그 수가 여기 드러난다.
chk "V8: 본 검사 - 단독 행이 없는 본 검사 케이스 0개" "$(rv_lonely)" "0"
# (V9) 픽스처 통제 — 노출이 공허하지 않다. **차이로 묻는다**(규약 `control-form:`).
chk "V9: 픽스처 통제 - 단독 행 없는 케이스를 심으면 하나 는다" "$(( $(rv_lonely "$(rv_fixture nosolo)") - $(rv_lonely) ))" "1"
# (V10) 픽스처 통제 — 마커를 지운 사본에서 창이 열리지 않는다. **사본 하나만 읽으므로 기준선이
# 구조로 상수 0이다**(대상이 늘어도 이 사본에는 마커가 없다) — 규약 `control-form:`이 요구하는
# 「왜 상수인가」의 같은 줄 서술이 이것이다.
chk "V10: 픽스처 통제 - 마커를 지우면 그 사본의 행이 0이 된다" "$(rv_rows "$(rv_fixture nomarker)" | grep -c .)" "0"
# (V11) 음성 통제 — 손대지 않은 사본은 기준선과 같다.
chk "V11: 음성 통제 - 손대지 않은 사본은 기준선과 같다" "$(( $(rv_lonely "$(rv_fixture clean)") - $(rv_lonely) ))" "0"
# (V12) 배선 — 마커 이름이 **규약에서 온다**. 러너에 박혀 있으면 다른 이름을 줘도 창이 열려 초록이다.
# **다른 이름의 마커는 어느 보고서에도 없으므로 기준선이 구조로 상수 0이다**(같은 줄 서술).
chk "V12: 배선 - 다른 마커 이름을 주면 창이 열리지 않는다" "$(rv_rows_n "" zzz-other-marker)" "0"
# (V13) 소비자의 배선 — impl 템플릿이 마커 쌍을 갖는다. 없으면 다음 보고서가 형식을 잃는다.
chk "V13: impl 템플릿이 마커 쌍과 목록 줄을 갖는다" "$(rv_tpl_markers)" "ok"
# (V14) **소급 경계가 실제로 거르는가.** 시작 번호를 1로 낮추면 이 형식이 없던 시절의 보고서가
# 대상에 들어와 블록 없는 보고서가 생긴다 — 경계가 장식이 아니라는 것을 이 케이스가 확인한다.
chk "V14: 경계 통제 - 시작 번호를 1로 낮추면 블록 없는 보고서가 생긴다(>0)" "$([ "$(rv_noblock 1)" -gt 0 ] && echo ok || echo no)" "ok"
# (V15) **오탐 방향** — 산문이 마커를 **언급**해도 창은 열리지 않는다(창은 줄 전체 일치다). 이 자리가
# 열려 있던 동안 `V6`이 초록인 채 `V8`만 붉었다(이 사이클의 impl 실측). 여기서 붉으면 창이 다시
# 부분 문자열로 넓어진 것이다.
chk "V15: 오탐 방향 - 산문의 마커 언급은 창을 열지 않는다" "$(( $(rv_rows_n "$(rv_fixture mention)") - $(rv_rows_n) ))" "0"
# (V16) **본 검사 — 조용한 제외 노출.** `rv_lonely`가 **행이 없거나 목록이 빈** 보고서를 건너뛰므로
# 센다. 이 케이스가 없으면 **다음 사이클이 되돌림 절을 통째로 빠뜨려도 기계가 아무 말도 안 한다**
# (M61 리뷰 차단 1의 실측: 그 상태에서 `V1`~`V15` 열다섯이 전부 초록이었다).
chk "V16: 본 검사 - 단독 판정이 읽지 못하는 대상 보고서 0개" "$(rv_noblock "$RVN")" "0"
# (V17·V18·V24) 픽스처·음성 통제 — 노출이 공허하지 않다. **차이로 묻는다**(규약 `control-form:`).
# 두 픽스처가 **두 침묵을 각각** 만든다: 마커를 지우면 행이 0이고, `-main` 줄만 지우면 목록이 빈다.
chk "V17: 픽스처 통제 - 마커 없는 보고서를 더하면 하나 는다" "$(( $(rv_noblock "$RVN" "$(rv_fixture nomarker)") - $(rv_noblock "$RVN") ))" "1"
chk "V24: 픽스처 통제 - 목록 줄만 없는 보고서를 더해도 하나 는다" "$(( $(rv_noblock "$RVN" "$(rv_fixture nomain)") - $(rv_noblock "$RVN") ))" "1"
chk "V18: 음성 통제 - 손대지 않은 사본을 더해도 늘지 않는다" "$(( $(rv_noblock "$RVN" "$(rv_fixture clean)") - $(rv_noblock "$RVN") ))" "0"
# (V25) **본 검사 — 목록 선언의 범위.** `rv_main`이 첫 매치에서 끝나고 `-->`가 없으면 **그 줄에 있는
# 이름만** 반환하므로, 복제된 둘째 줄도 **접힌 뒷줄**도 판정 대상에서 통째로 빠진다. 라운드 3은 그
# 중 **복제**만 물었고, 정작 반환이 트리거로 적은 **줄 접기**가 그대로 남아 `V8`이 거짓 초록이 됐다
# (M61 리뷰 라운드 3의 차단). **닫힘을 물어 두 상태를 한 판정에 건다.**
chk "V25: 본 검사 - 목록 선언이 규정된 한 줄의 형태가 아닌 대상 보고서 0개" "$(rv_mainbadn "$RVN")" "0"
# (V26·V30·V33·V27) 픽스처·음성 통제 — 노출이 공허하지 않다. **차이로 묻는다**(규약 `control-form:`).
# 픽스처 **셋**이 세 상태를 각각 만든다: 줄을 복제하는 쪽 · 한 줄을 **두 줄로 접는** 쪽 · 이름을
# **닫는 태그 뒤로** 미는 쪽. 셋 다 사람 눈에는 선언한 것으로 보이고, 셋 다 **한 판정**에 걸린다.
chk "V26: 픽스처 통제 - 목록 줄을 하나 더 만든 보고서를 더하면 하나 는다" "$(( $(rv_mainbadn "$RVN" "$(rv_fixture dupmain)") - $(rv_mainbadn "$RVN") ))" "1"
chk "V30: 픽스처 통제 - 목록 줄을 두 줄로 접은 보고서를 더해도 하나 는다" "$(( $(rv_mainbadn "$RVN" "$(rv_fixture foldmain)") - $(rv_mainbadn "$RVN") ))" "1"
chk "V33: 픽스처 통제 - 이름을 닫는 태그 뒤로 민 보고서를 더해도 하나 는다" "$(( $(rv_mainbadn "$RVN" "$(rv_fixture aftermain)") - $(rv_mainbadn "$RVN") ))" "1"
chk "V27: 음성 통제 - 손대지 않은 사본을 더해도 늘지 않는다" "$(( $(rv_mainbadn "$RVN" "$(rv_fixture clean)") - $(rv_mainbadn "$RVN") ))" "0"
# (V19) **본 검사 — 축 값의 집합 소속.** 되돌림의 방향은 둘(`mutation-axes:`)이고 표가 행마다 그것을
# 적는다. 열만 만들고 값을 안 재면 **죽은 선언**이 된다 — 빈 칸도 집합 밖으로 센다.
chk "V19: 본 검사 - 선언 집합 밖이거나 빈 축 값 0개" "$(rv_axisbad)" "0"
# (V20) 픽스처 통제 — 차이로 묻는다.
chk "V20: 픽스처 통제 - 집합 밖 축 값을 심으면 하나 는다" "$(( $(rv_axisbad "$(rv_fixture badaxis)") - $(rv_axisbad) ))" "1"
# (V21) **본 검사 — 붉은 케이스 칸의 형식 무결성.** 빈 이름(`A;;B`·`A;`)과 중복 이름(`A;A`)은 표를
# 읽을 수 없게 만든다. 단독 판정과 **독립**이다 — 여러 이름이 든 칸이 망가져도 단독 행은 멀쩡하다.
chk "V21: 본 검사 - 붉은 케이스 칸의 빈 이름·중복 0개" "$(rv_cellbad)" "0"
# (V22) 픽스처 통제 — 차이로 묻는다.
chk "V22: 픽스처 통제 - 중복 이름을 심으면 하나 는다" "$(( $(rv_cellbad "$(rv_fixture dupname)") - $(rv_cellbad) ))" "1"
# (V23) **배선 — 구분자가 규약에서 온다.** 다른 구분자를 주면 그 픽스처를 **못 쪼개** 중복을 놓친다.
# 이 케이스가 없는 동안 `reversal-sep:`는 값을 바꿔도 전 축이 초록인 **죽은 선언**이었다(M61 리뷰
# 권장 5). **픽스처 하나만 읽으므로 기준선이 구조로 상수 0이다**(같은 줄 서술).
chk "V23: 배선 - 다른 구분자를 주면 그 픽스처를 못 잡는다" "$(rv_cellbad "$(rv_fixture dupname)" zzz-other-sep)" "0"
# (V28·V29) **`control-form:`의 값이 판정에 쓰인다.** `V1`은 선언 **줄 수**만 세어, 값을 아무거나
# 바꿔도 전 축이 초록이었다 — 같은 사이클이 `reversal-sep:`에 대해 *"선언은 판정에 실제로 쓰여야
# 한다"* 를 규약에 적고도 다섯째 키에서 같은 결함을 반복했다(M61 리뷰 라운드 2의 권장 2).
# 형태는 `measure-order:`의 `U2`~`U5`와 같다 — 꼬리에서 병기어를 뽑고 **재서술처가 그것을 갖는지**를 묻는다.
# **다만 부분 문자열로는 부족하다**(M61 리뷰 라운드 3의 권장 2) — 값을 `control`로 **줄여도**
# `positive-control`에 걸려 전 축이 초록이었다. 대조를 **백틱 토큰**으로 좁히고, 값을 **키로 삼아
# 규약의 정의 줄**(`V31`)까지 묻는다. 그래야 값이 달라질 때 판정이 실제로 달라진다.
chk "V28: control-form 병기어 추출 positive-control" "$([ -n "$(cf_name)" ] && echo ok || echo no)" "ok"
chk "V29: 본 검사 - 재서술처 둘이 그 병기어를 백틱 토큰으로 갖는다" "$(cf_restated "$(cf_name)")" "2"
chk "V31: 본 검사 - 규약이 그 병기어의 정의 줄을 정확히 하나 갖는다" "$(cf_defn "$(cf_name)")" "1"
# (V32) **배선** — 재서술처 판정이 **주어진 병기어**를 실제로 쓴다. **인자로 준 토큰 하나만 읽고 그
# 토큰은 어느 파일에도 없으므로 기준선이 구조로 상수 0이다**(규약 `control-form:`이 요구하는 같은
# 줄 서술). 이 케이스가 없으면 `cf_restated`가 인자를 무시해도 `V29`가 초록이다.
chk "V32: 배선 - 다른 병기어를 주면 재서술처가 0이다" "$(cf_restated zzz-other-form)" "0"
fi

# --- Part W: 검사 범위 선언 (M62) --------------------------------------------
# 「X를 검사했다」의 **범위를 검사자가 정하고 아무도 보지 않는** 자리다. 외부 저장소의 첫 전면
# 사이클에서 이 부류가 **축을 바꿔 가며 네 번 재발**했고(검색 패턴 → 대상 파일 집합 → 대조 항목 →
# 검색 루트) 넷째는 **이미 릴리즈에 실린 뒤** 발견됐다. 규약이 그 자리에 병기어 하나를 세웠으므로
# 이 파트가 **선언 정합**으로 결합한다 — 병기어가 없으면 Part E의 `E8`·`E9`와 같은 이유로
# 재서술처가 낡아도 초록이다. 단일 원본은 `docs/conventions.md`의 "검사 범위 선언" 절.
#   무는 것은 **선언의 유일성 · 병기어의 세 자리 공존 · 경계 표지의 실재**까지다. 「선언한 범위가
#   실제로 돌린 검색과 같은가」는 정적으로 판정되지 않으며 규약이 그 경계를 같은 절에 적는다.
if part_on W; then
SCOPE_KEY='scope-decl:'
SCOPE_LIM_KEY='scope-limits:'
# 병기어는 **선언에서 온다**(러너에 박으면 값을 바꿔도 초록이다 — `control-form:`의 `V28`~`V32`와
# 같은 형태). 선언을 잃었을 때의 폴백을 **두 사본에 같은 형태로 못박는다**: 빈 값을 그대로 쓰면
# 백틱 토큰이 `` `` `` 두 글자가 되어 아무 파일에나 걸리고, 그러면 선언을 지운 트리가 초록이 된다.
SCOPE_ALIAS=$(decl_tail "$CONV" "$SCOPE_KEY" | LC_ALL=C awk '{ print $1 }')
[ -n "$SCOPE_ALIAS" ] || SCOPE_ALIAS=zzz-scope-decl-unset
SCOPE_MARKS=$(markers_of "$SCOPE_LIM_KEY")
NSCM=$(printf '%s\n' "$SCOPE_MARKS" | grep -c .)
fi
scope_all() { # <병기어> → 규약·review 스킬·review 템플릿·impl 템플릿 **넷** 전부에 있으면 yes
    # **M63에서 넷이 됐다** — M62 리뷰가 *"impl 템플릿과 리뷰 스킬에는 넣고 리뷰 템플릿만 비었는데
    # 사유가 없다"* 를 지적했고, 그 자리를 채우면 재서술처가 하나 는다. 결합을 함께 넓히지 않으면
    # 규약이 「재서술처 셋」이라 적는 동안 기계는 **둘만** 보게 되어, 이 절이 존재하는 이유
    # (*"병기어가 없으면 재서술처가 낡아도 초록"*)가 그 자리에서 그대로 무너진다.
    for _sa4 in "$CONV" "$REV_SKILL" "$REV_TPL" "$IMPL_TPL"; do
        [ "$(has_token "$_sa4" "$1")" = yes ] || { echo no; return; }
    done
    echo yes
}
scope_defn() { # <병기어> → 규약에서 그 병기어를 **정의하는 줄**의 수(`V31`과 같은 형태)
    grep -cF "$(printf '**`%s`**' "$1")" "$CONV" 2>/dev/null | LC_ALL=C awk 'NR == 1 { print $1 + 0 }'
}
marks_used_in() { # <파일> <선언 키> <표지들> → 그 **선언 줄이 속한 절 안**에서 실제로 쓰인 표지의 수
    # 표지만 선언하고 경계 문장을 지우면 선언이 **죽은 채** 남는다 — `mutation-axes:`가 열만 만들고
    # 값을 안 재던 자리와 같은 부류다. 선언 줄 자신은 세지 않는다(Part I·L과 같은 제외).
    #
    # **창은 「파일 전체」가 아니라 「선언 줄이 속한 절」이다**(M62 리뷰 라운드 0 차단 1의 처분).
    # 전역으로 세면 **다른 절이 같은 표지를 인용하는 것만으로** 정작 그 절의 경계 문장을 지워도
    # 초록이 된다 — 실측된 자리다.
    #
    # **창을 여는 것은 「선언 줄」이지 「키의 첫 언급」이 아니다**(라운드 1 차단 1의 처분). 앵커를
    # 첫 백틱 언급으로 잡으면 **앞선 절이 키를 인용하기만 해도** 창이 그리로 옮겨가고, 그 절이
    # 표지를 담고 있으면 진짜 절의 경계 문장을 **전부 지워도 초록**이다(실측: 인용을 두 줄로 나눠
    # 적은 트리에서 `W9`가 3으로 통과했다). 그래서 앵커 술어를 `decl_lines`와 **같은 것**으로
    # 맞춘다 — 들여쓰기 + `-` + 공백 + 백틱 키. 두 술어가 갈린 것이 그 공허의 원인이었다.
    # 절 = 선언 줄이 속한 헤딩의 **다음 줄부터** 다음 헤딩 직전까지이며(헤딩 줄 자신은 창 밖이다 —
    # 제목에 든 표지는 경계 문장이 아니다), 헤딩은 층위를 가리지 않는다(`#`로 시작하는 줄).
    #
    # **세는 것은 「토큰의 출현」이 아니라 「경계 문장으로 쓰였는가」다**(라운드 2 차단 1의 처분).
    # 창을 두 번 좁히고도 판정의 술어가 토큰 출현이면 **같은 절 안에 표지를 나열한 한 줄**이 대신
    # 세어져 경계 문장을 전부 지워도 초록이다(실측: 나열 한 줄만 남긴 트리가 기준선과 같았다).
    # 그래서 줄을 둘로 거른다 — ⑴ **나열 줄**(선언된 표지를 **전부** 담은 줄. 선언 줄 자신과 그
    # 복제가 이 형태다. 표지가 하나뿐이면 이 거름을 끈다 — 그때는 모든 사용 줄이 「전부」가 된다)
    # ⑵ 표지가 **굵은 코드 스팬**(`**` + 백틱 표지 + `**`)으로 쓰인 줄만 센다. 규약이 경계 문장을
    # 그 형태로 적기 때문이며(`scope_defn`이 병기어 정의 줄에 같은 형태를 요구한다) 나열은 그 형태를
    # 쓰지 않는다. **남는 구멍은 정직하게 적는다** — 굵게 적은 나열 줄을 **둘로 쪼개** 각 줄이
    # 표지를 전부 담지 않게 하면 여전히 지나간다. 그 잔여는 README Part W 절의 고지가 받는다.
    _mf="$1"; _mk="$2"
    [ -f "$_mf" ] || { echo 0; return; }
    LC_ALL=C awk -v k="\`$_mk\`" -v cr="$(printf '\r')" '
        function is_decl(s,   i, n) {
            if (length(s) > 0 && substr(s, length(s), 1) == cr) s = substr(s, 1, length(s) - 1)
            i = 1
            while (i <= length(s) && (substr(s, i, 1) == " " || substr(s, i, 1) == "\t")) i++
            if (substr(s, i, 1) != "-") return 0
            i++
            n = 0
            while (i <= length(s) && (substr(s, i, 1) == " " || substr(s, i, 1) == "\t")) { i++; n++ }
            if (n < 1) return 0
            return (substr(s, i, length(k)) == k)
        }
        /^#/ { if (found) exit; n = 0; delete buf; next }
        { buf[++n] = $0; if (is_decl($0)) found = 1 }
        END { if (found) for (i = 1; i <= n; i++) print buf[i] }
    ' "$_mf" > "$SBX/marksection.txt"
    _mn=0
    # 표지 목록은 공백으로 갈린 토큰이라 분리를 위해 인용하지 않는다 — 대신 **글롭을 끈다**.
    # 끄지 않으면 표지에 `*`·`?`가 들어갔을 때 경로 확장이 일어나 ps1 사본(배열)과 답이 갈린다.
    set -f
    _mtot=0
    for _mm in $3; do _mtot=$((_mtot + 1)); done
    : > "$SBX/marksbound.txt"
    while IFS= read -r _ml; do
        case "$_ml" in *"$_mk"*) continue ;; esac
        if [ "$_mtot" -gt 1 ]; then
            _mall=1
            for _m2 in $3; do
                case "$_ml" in *"$_m2"*) ;; *) _mall=0; break ;; esac
            done
            [ "$_mall" -eq 1 ] && continue
        fi
        printf '%s\n' "$_ml" >> "$SBX/marksbound.txt"
    done < "$SBX/marksection.txt"
    for _mm in $3; do
        _mc=$(grep -F "$(printf '**`%s`**' "$_mm")" "$SBX/marksbound.txt" 2>/dev/null | grep -c .)
        [ "$_mc" -gt 0 ] && _mn=$((_mn + 1))
    done
    set +f
    echo "$_mn"
}
# 픽스처 — 표지 하나는 선언과 **같은 절**에, 다른 하나는 **다른 절**에 둔다. 절 창이 살아 있으면 1,
# 창이 파일 전역으로 되돌아가면 2가 되어 아래 `W22`가 붉는다(판정을 망가뜨렸을 때 붉는 통제다).
if part_on W; then
MK_FIX="$SBX/marks-crosssection.md"
{
    printf '## Sec A\n'
    printf -- '- `zzz-mk:` `zzz-m1` `zzz-m2`\n'
    printf 'uses **`zzz-m1`** in its own section\n'
    printf '## Sec B\n'
    printf 'uses **`zzz-m2`** in a different section\n'
} > "$MK_FIX"
# 픽스처 둘째 — **앞선 절이 키를 산문으로 인용**하고 표지 둘을 함께 담는다. 선언 줄(불릿)은 그 뒤
# 절에 있고 그 절은 표지 하나만 쓴다. 앵커가 `decl_lines`와 같은 술어면 답은 1이고, 앵커가 「키의
# 첫 언급」으로 되돌아가면 창이 앞 절로 옮겨가 2가 된다 — `W23`이 그 회귀를 문다.
MK_FIX2="$SBX/marks-citeahead.md"
{
    printf '## Sec A\n'
    printf 'the `zzz-mk:` list is cited here in prose\n'
    printf 'and it names **`zzz-m1`** and **`zzz-m2`** on this line\n'
    printf '## Sec B\n'
    printf -- '- `zzz-mk:` `zzz-m1` `zzz-m2`\n'
    printf 'uses **`zzz-m1`** in the declaration section\n'
} > "$MK_FIX2"
# 픽스처 셋째 — 선언과 **같은 절**에 **맨 백틱으로 적힌 줄**이 있고 경계 문장은 다른 표지에만 있다.
# **그 줄은 표지를 하나만 담는다** — 전부 담으면 앞의 나열 줄 거름에 먼저 걸려 굵기 요구가 판정을
# 가르지 못하고, 그러면 이 픽스처는 굵기 요구를 지워도 답이 변하지 않는 **죽은 통제**가 된다
# (M62 리뷰 라운드 3의 실측: 앞 판본이 그 상태였고 굵기 요구를 지운 트리가 양 축 전건 초록이었다).
# 판정이 「굵은 코드 스팬으로 쓰였는가」면 답은 1이고, 「토큰이 있는가」로 되돌아가면 2가 된다 —
# `W24`가 그 회귀를 문다(라운드 2 차단 1의 실물이 이 형태였다).
MK_FIX3="$SBX/marks-plainlist.md"
{
    printf '## Sec A\n'
    printf -- '- `zzz-mk:` `zzz-m1` `zzz-m2`\n'
    printf 'the markers are `zzz-m2` in a plain list\n'
    printf 'uses **`zzz-m1`** as a boundary sentence\n'
} > "$MK_FIX3"
# 픽스처 넷째 — 같은 절의 나열 줄이 **굵게** 적혔고 선언된 표지를 **전부** 담는다. 나열 줄 거름이
# 살아 있으면 답은 1이고, 거름이 빠지면 2가 된다 — `W25`가 그 회귀를 문다.
MK_FIX4="$SBX/marks-boldlist.md"
{
    printf '## Sec A\n'
    printf -- '- `zzz-mk:` `zzz-m1` `zzz-m2`\n'
    printf 'the markers are **`zzz-m1`** and **`zzz-m2`** on one line\n'
    printf 'uses **`zzz-m1`** as a boundary sentence\n'
} > "$MK_FIX4"
chk "W1: scope-decl 선언 줄 정확히 1개" "$(decl_count "$CONV" "$SCOPE_KEY")" "1"
# (W2) 추출 positive-control — 병기어를 못 뽑으면 아래 결합이 **폴백 토큰**으로 돌아 전부 붉는데,
# 그 원인이 「어디서 지워졌는가」인지 「선언이 없는가」인지 여기서 갈린다.
chk "W2: 병기어 추출 positive-control" "$([ "$SCOPE_ALIAS" != zzz-scope-decl-unset ] && echo ok || echo no)" "ok"
# (W3) **본 검사** — 병기어가 규약·review 스킬·impl 템플릿 셋 전부에 있다(E2·E5와 같은 3곳 결합).
chk "W3: 검사 범위 병기어($SCOPE_ALIAS) 네 파일 전부에 등장" "$(scope_all "$SCOPE_ALIAS")" "yes"
# (W4~W6) **셋을 각각 따로도 문다** — 결합만 두면 하나가 죽어도 「어느 자리인가」가 가려진다
# (Part E가 `E10`·`E11`에서 3파일 결합과 자리별 단언을 함께 두는 형태). 규약 쪽은 **정의 줄**을,
# 재서술처 둘은 **백틱 토큰**을 문다 — 재서술이 병기어를 산문에 흘려 적는 것과 구별한다.
chk "W4: 규약이 그 병기어의 정의 줄을 정확히 하나 갖는다" "$(scope_defn "$SCOPE_ALIAS")" "1"
chk "W5: review SKILL이 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$REV_SKILL" "$SCOPE_ALIAS")" "yes"
chk "W6: impl 템플릿이 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$IMPL_TPL" "$SCOPE_ALIAS")" "yes"
# (W30) **자리별 단언 — 셋째 재서술처**(M63). 결합(`W3`)만 넓히면 **어느 자리가 죽었는지**가 가려진다
# (`W4`~`W6`이 앞 셋에 대해 같은 판단을 적는 것과 같은 형태다).
chk "W30: review 템플릿이 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$REV_TPL" "$SCOPE_ALIAS")" "yes"
chk "W7: scope-limits 선언 줄 정확히 1개" "$(decl_count "$CONV" "$SCOPE_LIM_KEY")" "1"
# (W8) 표지 추출 positive-control — 0이면 아래 `W9`가 **0 == 0**으로 공허 통과한다.
chk "W8: 경계 표지 추출 positive-control(>0)" "$([ "$NSCM" -gt 0 ] && echo ok || echo no)" "ok"
# (W9) **본 검사** — 선언한 경계 표지가 전부 규약 본문에서 **실제로 쓰인다**(경계 문장이 살아 있다).
chk "W9: 경계 표지 전부가 선언 절 안에서 쓰인다" "$(marks_used_in "$CONV" "$SCOPE_LIM_KEY" "$SCOPE_MARKS")" "$NSCM"
# (W22) **픽스처 통제** — 판정이 절 창을 실제로 쓰는가. 표지 둘 중 하나만 선언과 같은 절에 있으므로
# 절 창이면 1, 파일 전역으로 되돌아가면 2다. **판정을 망가뜨렸을 때 붉어지지 않으면 통제가 아니다.**
# **기준선이 상수인 이유**: 읽는 대상이 이 파트가 방금 쓴 **픽스처 한 파일뿐**이라 산출물이 늘거나
# 줄어도 값이 움직이지 않는다(규약 `control-form:`의 절대값 예외 — `W12`·`W18`과 같은 사유).
chk "W22: 픽스처 통제 - 다른 절의 표지 사용은 세지 않는다" "$(marks_used_in "$MK_FIX" zzz-mk: "zzz-m1 zzz-m2")" "1"
# (W23) **적대 통제** — 창의 앵커가 「선언 줄」인가 「키의 첫 언급」인가. 앞선 절이 키를 **산문으로**
# 인용하고 표지 둘을 담으므로, 앵커가 첫 언급이면 2이고 선언 줄이면 1이다. 라운드 1의 공허가 정확히
# 이 자리였다 — 경계 문장을 다 지워도 앞 절의 인용이 대신 세어져 초록이었다.
# **기준선이 상수인 이유**는 `W22`와 같다(픽스처 한 파일만 읽는다).
chk "W23: 적대 통제 - 앞선 절의 키 인용은 창을 옮기지 않는다" "$(marks_used_in "$MK_FIX2" zzz-mk: "zzz-m1 zzz-m2")" "1"
# (W24) **적대 통제** — 판정의 술어가 「토큰 출현」인가 「경계 문장으로 쓰였는가」인가. 같은 절에 표지
# 둘을 **맨 백틱으로 나열한 줄**이 있고 굵은 사용은 하나뿐이므로, 술어가 출현이면 2이고 굵은 사용이면
# 1이다. 라운드 2의 공허가 정확히 이 자리였다.
# **기준선이 상수인 이유**는 `W22`와 같다(픽스처 한 파일만 읽는다).
chk "W24: 적대 통제 - 같은 절의 맨 나열 줄은 세지 않는다" "$(marks_used_in "$MK_FIX3" zzz-mk: "zzz-m1 zzz-m2")" "1"
# (W25) **적대 통제** — 나열 줄이 **굵게** 적히고 표지를 **전부** 담아도 세지 않는가. 나열 줄 거름이
# 빠지면 2다. `W24`가 「굵기」 축을, `W25`가 「전부 담은 줄」 축을 각각 문다.
# **기준선이 상수인 이유**는 `W22`와 같다(픽스처 한 파일만 읽는다).
chk "W25: 적대 통제 - 표지를 전부 담은 굵은 나열 줄은 세지 않는다" "$(marks_used_in "$MK_FIX4" zzz-mk: "zzz-m1 zzz-m2")" "1"
# 음성 통제 — 가짜 병기어는 규약에 없어야 한다(Part E의 `-bogus` 통제와 동형, 구별력 입증).
chk "W: 통제 — conventions에 가짜 범위 병기어 없음" "$(has_token "$CONV" "${SCOPE_ALIAS}-bogus")" "no"
# 교차 통제 — 범위 선언은 리뷰·impl 보고서의 자산이라 milestone 템플릿에 없어야 한다(Part D·E와 동형).
chk "W: 통제 — milestone 템플릿에 범위 병기어 없음" "$(has_token "$MS_TPL" "$SCOPE_ALIAS")" "no"
# (W12) **배선** — 결합 판정이 **인자로 준 병기어**를 실제로 쓴다. 이 케이스가 없으면 `scope_all`이
# 인자를 무시해도 `W3`가 초록이다(`V32`와 같은 형태 — 읽는 것은 인자로 준 그 토큰 하나이고 어느
# 파일에도 없으므로 기준선이 **구조로 상수**다).
chk "W12: 배선 - 다른 병기어를 주면 결합이 성립하지 않는다" "$(scope_all zzz-other-scope)" "no"
# (W13~W18 · M62-T03) 측정이 **캐시·스킵으로 위조되는** 자리. Part U가 무는 것은 **순서**이고, 순서를
# 지켜도 빌드 시스템이 태스크를 UP-TO-DATE로 건너뛰면 명령을 돌린 것만 참이고 값은 **옛 트리의 것**이다
# (외부 실측 2회 — Gradle `test`가 3개월 전 XML을 「마지막 측정」으로 만들었다). 규약이 그 자리에
# 병기어를 하나 더 세웠으므로 위와 같은 형태로 결합한다. 층위는 **2곳**이다(규약 = 정의, impl 스킬 =
# 절차) — 보고서 템플릿에 슬롯을 두면 복제 선언을 늘린다(`E6`·`E9`가 같은 판단을 적는다).
MC_KEY='measure-cache:'
MC_ALIAS=$(decl_tail "$CONV" "$MC_KEY" | LC_ALL=C awk '{ print $1 }')
[ -n "$MC_ALIAS" ] || MC_ALIAS=zzz-measure-cache-unset
chk "W13: measure-cache 선언 줄 정확히 1개" "$(decl_count "$CONV" "$MC_KEY")" "1"
# (W14) 추출 positive-control — `W2`와 같은 사유(폴백으로 돌면 원인이 가려진다).
chk "W14: 캐시 병기어 추출 positive-control" "$([ "$MC_ALIAS" != zzz-measure-cache-unset ] && echo ok || echo no)" "ok"
# (W15~W17) **본 검사** — 병기어가 규약과 impl 스킬 둘 다에 있고(`in_both`), 규약 쪽은 **정의 줄**을,
# 스킬 쪽은 **백틱 토큰**을 따로 문다(`W4`~`W6`과 같은 층위 분담).
chk "W15: 캐시 병기어($MC_ALIAS) 규약↔impl SKILL 정합" "$(in_both "$MC_ALIAS" "$CONV" "$IMPL_SKILL")" "yes"
chk "W16: 규약이 캐시 병기어의 정의 줄을 정확히 하나 갖는다" "$(scope_defn "$MC_ALIAS")" "1"
chk "W17: impl SKILL이 캐시 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$IMPL_SKILL" "$MC_ALIAS")" "yes"
# 음성 통제 · 교차 통제 — 위 두 통제와 동형(구별력 입증 · 자산 경계).
chk "W: 통제 — conventions에 가짜 캐시 병기어 없음" "$(has_token "$CONV" "${MC_ALIAS}-bogus")" "no"
chk "W: 통제 — milestone 템플릿에 캐시 병기어 없음" "$(has_token "$MS_TPL" "$MC_ALIAS")" "no"
# (W18) **배선** — `W12`와 같은 형태(인자로 준 토큰 하나만 읽고 그 토큰은 어느 파일에도 없다).
chk "W18: 배선 - 다른 캐시 병기어를 주면 결합이 성립하지 않는다" "$(in_both zzz-other-cache "$CONV" "$IMPL_SKILL")" "no"
# (W19~W21 · M62-T04) `fleet-verify`의 **pass가 덮는 범위**를 산출물이 적는가. 외부 실측에서 훅의
# 스모크 스텝 자리가 **빈 채 pass**가 났고 그 pass가 「통합이 검증됐다」로 읽혔다. 규약이 표지 셋을
# 선언하므로 `W7`~`W9`와 **같은 기전**으로 문다(표지의 선언처는 규약, 러너는 읽기만 — 한글 리터럴 0).
# 스킬 문면의 산문 판정은 하지 않는다 — 그 층은 리뷰의 자리다.
VS_KEY='verify-scope:'
VS_MARKS=$(markers_of "$VS_KEY")
NVSM=$(printf '%s\n' "$VS_MARKS" | grep -c .)
chk "W19: verify-scope 선언 줄 정확히 1개" "$(decl_count "$CONV" "$VS_KEY")" "1"
# (W20) 추출 positive-control — 0이면 아래 `W21`이 **0 == 0**으로 공허 통과한다(`W8`과 같은 사유).
chk "W20: 검증 범위 표지 추출 positive-control(>0)" "$([ "$NVSM" -gt 0 ] && echo ok || echo no)" "ok"
# (W21) **본 검사** — 선언한 표지가 전부 규약 본문에서 **실제로 쓰인다**(정의 문장이 살아 있다).
chk "W21: 검증 범위 표지 전부가 선언 절 안에서 쓰인다" "$(marks_used_in "$CONV" "$VS_KEY" "$VS_MARKS")" "$NVSM"
# (W26~W27) **꼬리의 구분자**를 이 파트가 세운 병기어 키 둘에도 못박는다(M42 리뷰 차단 1의 처방을
# Part W가 물려받는 자리 — `I10`~`I13`과 **같은 헬퍼**를 부른다). 두 사본의 꼬리 분리 폭이 다르면
# 보이지 않는 한 글자(NBSP·탭)에 **한쪽만 붉어 총계가 갈린다** — 실측된 자리다. 금지 자체를 여기
# 두면 그 갈림이 **양 축에서 함께** 붉는다. 통제(`I12`·`I13`)가 이미 이 금지의 비공허를 실증하므로
# 여기서 픽스처를 다시 만들지 않는다.
chk "W26: scope-decl 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$SCOPE_KEY")" "0"
# (W49~W57 · M65) **구조적 불가 주장의 근거** — `scope-decl:`의 반대 방향 병기어다. 층·재서술처·기전이
# 위 `W1`~`W6`·`W12`·`W26`과 같아 **같은 헬퍼**(`scope_all`·`scope_defn`·`scope_tok`·`bad_seps`)를 부른다.
# 공유의 근거는 **규약이 두 병기어에 적은 재서술처 목록이 같다**는 사실이다 — 한쪽만 늘면 공유가
# 틀리므로, 그때는 헬퍼를 가르고 같은 편집에서 이 주석과 규약 문장을 함께 고친다.
# 폴백은 `W2`와 같은 형태로 못박는다(빈 값이면 백틱 토큰이 두 글자가 되어 아무 파일에나 걸린다).
INF_KEY='infeasible-decl:'
INF_ALIAS=$(decl_tail "$CONV" "$INF_KEY" | LC_ALL=C awk '{ print $1 }')
[ -n "$INF_ALIAS" ] || INF_ALIAS=zzz-infeasible-decl-unset
chk "W49: infeasible-decl 선언 줄 정확히 1개" "$(decl_count "$CONV" "$INF_KEY")" "1"
chk "W50: 불가 주장 병기어 추출 positive-control" "$([ "$INF_ALIAS" != zzz-infeasible-decl-unset ] && echo ok || echo no)" "ok"
# (W51) **본 검사** — 규약 + 재서술처 셋, 네 파일 결합(`W3`과 같은 헬퍼).
chk "W51: 불가 주장 병기어($INF_ALIAS) 네 파일 전부에 등장" "$(scope_all "$INF_ALIAS")" "yes"
# (W52~W55) **자리별로도 문다** — 결합만 두면 어느 자리가 죽었는지 가려진다(`W4`~`W6`·`W30`과 같은 판단).
chk "W52: 규약이 불가 주장 병기어의 정의 줄을 정확히 하나 갖는다" "$(scope_defn "$INF_ALIAS")" "1"
chk "W53: review SKILL이 불가 주장 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$REV_SKILL" "$INF_ALIAS")" "yes"
chk "W54: impl 템플릿이 불가 주장 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$IMPL_TPL" "$INF_ALIAS")" "yes"
chk "W55: review 템플릿이 불가 주장 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$REV_TPL" "$INF_ALIAS")" "yes"
# (W56) **배선** — `W12`와 같은 형태(인자로 준 토큰 하나만 읽고 그 토큰은 어느 파일에도 없어 기준선이
# **구조로 상수**다).
chk "W56: 배선 - 다른 불가 주장 병기어를 주면 결합이 성립하지 않는다" "$(scope_all zzz-other-infeasible)" "no"
# (W57) 꼬리 구분자 — `W26`과 같은 헬퍼·같은 사유(두 사본의 분리 폭이 갈리는 자리를 양 축에서 함께 붉힌다).
chk "W57: infeasible-decl 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$INF_KEY")" "0"
# (W58~W66 · M66) **다른 절차에 기대는 주장의 분기** — `scope-decl:`·`infeasible-decl:`과 같은 층의 셋째
# 병기어이고 재서술처도 같은 셋이라 **같은 헬퍼**를 부른다(공유의 근거와 깨지는 조건은 `W49` 주석과 같다).
# 발화(어떤 문장이 기대는 주장인가)는 여기서 묻지 않는다 — 규약이 그 판정을 리뷰의 목록 대조에 둔다.
LEAN_KEY='lean-decl:'
LEAN_ALIAS=$(decl_tail "$CONV" "$LEAN_KEY" | LC_ALL=C awk '{ print $1 }')
[ -n "$LEAN_ALIAS" ] || LEAN_ALIAS=zzz-lean-decl-unset
chk "W58: lean-decl 선언 줄 정확히 1개" "$(decl_count "$CONV" "$LEAN_KEY")" "1"
chk "W59: 기대는 분기 병기어 추출 positive-control" "$([ "$LEAN_ALIAS" != zzz-lean-decl-unset ] && echo ok || echo no)" "ok"
# (W60) **본 검사** — 규약 + 재서술처 셋, 네 파일 결합(`W3`·`W51`과 같은 헬퍼).
chk "W60: 기대는 분기 병기어($LEAN_ALIAS) 네 파일 전부에 등장" "$(scope_all "$LEAN_ALIAS")" "yes"
# (W61~W64) **자리별로도 문다**(`W52`~`W55`와 같은 판단).
chk "W61: 규약이 기대는 분기 병기어의 정의 줄을 정확히 하나 갖는다" "$(scope_defn "$LEAN_ALIAS")" "1"
chk "W62: review SKILL이 기대는 분기 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$REV_SKILL" "$LEAN_ALIAS")" "yes"
chk "W63: impl 템플릿이 기대는 분기 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$IMPL_TPL" "$LEAN_ALIAS")" "yes"
chk "W64: review 템플릿이 기대는 분기 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$REV_TPL" "$LEAN_ALIAS")" "yes"
# (W65) **배선** — `W12`·`W56`과 같은 형태(인자로 준 토큰 하나만 읽고 그 토큰은 어느 파일에도 없어 기준선이
# **구조로 상수**다).
chk "W65: 배선 - 다른 기대는 분기 병기어를 주면 결합이 성립하지 않는다" "$(scope_all zzz-other-lean)" "no"
chk "W66: lean-decl 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$LEAN_KEY")" "0"
# (W67~W72 · M66) **스캔 양성 통제** — 규약 "릴리즈 빌드 출력 검증" 절의 병기어와 재서술처 하나
# (`skills/release/SKILL.md`). 재서술처가 하나라 결합이 자리별 단언과 겹치므로 결합 케이스를 두지 않고
# 규약 정의 줄(`W69`)과 재서술처 백틱 토큰(`W70`)만 문다. 여기서 release 스킬의 토큰은 **파일 전역**으로 찾고,
# 단계 앵커와 같은 항목 창에 있는지는 아래 `W81`·`W82`(M68)가 따로 문다.
SCAN_KEY='scan-control:'
SCAN_ALIAS=$(decl_tail "$CONV" "$SCAN_KEY" | LC_ALL=C awk '{ print $1 }')
[ -n "$SCAN_ALIAS" ] || SCAN_ALIAS=zzz-scan-control-unset
chk "W67: scan-control 선언 줄 정확히 1개" "$(decl_count "$CONV" "$SCAN_KEY")" "1"
chk "W68: 스캔 양성 통제 병기어 추출 positive-control" "$([ "$SCAN_ALIAS" != zzz-scan-control-unset ] && echo ok || echo no)" "ok"
chk "W69: 규약이 스캔 양성 통제 병기어의 정의 줄을 정확히 하나 갖는다" "$(scope_defn "$SCAN_ALIAS")" "1"
chk "W70: release SKILL이 스캔 양성 통제 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$REL_SKILL" "$SCAN_ALIAS")" "yes"
# (W71) **배선** — 인자로 준 토큰(어느 파일에도 없음)을 주면 `no`다. 이 케이스가 없으면 `scope_tok`이 인자를
# 무시해도 `W70`이 초록이다(기준선이 구조로 상수 — `W12`와 같은 형태).
chk "W71: 배선 - 다른 스캔 양성 통제 병기어는 release SKILL에 없다" "$(scope_tok "$REL_SKILL" zzz-other-scan)" "no"
chk "W72: scan-control 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$SCAN_KEY")" "0"
# (W73~W78 · M67) **판정 없는 부재 잡** — 규약 측정 배당 블록의 병기어(`absent-job:`)와 재서술처 하나
# (`skills/release/SKILL.md`의 `pr` 모드 마무리). `W67`~`W72`와 같은 층·같은 형태다. 재서술처가 하나라 결합이
# 자리별 단언과 겹치므로 결합 케이스를 두지 않고 정의 줄(`W75`)과 재서술처 백틱 토큰(`W76`)만 문다.
# 여기서 release 스킬의 토큰은 **파일 전역**으로 찾고, 단계 앵커와 같은 항목 창에 있는지는 아래 `W87`·`W88`(M68)이
# 따로 문다.
# 마무리에서 그 갈래를 **실제로 밟았는가**는 절차라 묻지 않는다.
ABSENT_KEY='absent-job:'
ABSENT_ALIAS=$(decl_tail "$CONV" "$ABSENT_KEY" | LC_ALL=C awk '{ print $1 }')
[ -n "$ABSENT_ALIAS" ] || ABSENT_ALIAS=zzz-absent-job-unset
chk "W73: absent-job 선언 줄 정확히 1개" "$(decl_count "$CONV" "$ABSENT_KEY")" "1"
chk "W74: 부재 잡 병기어 추출 positive-control" "$([ "$ABSENT_ALIAS" != zzz-absent-job-unset ] && echo ok || echo no)" "ok"
chk "W75: 규약이 부재 잡 병기어의 정의 줄을 정확히 하나 갖는다" "$(scope_defn "$ABSENT_ALIAS")" "1"
chk "W76: release SKILL이 부재 잡 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$REL_SKILL" "$ABSENT_ALIAS")" "yes"
# (W77) **배선** — 인자로 준 토큰(어느 파일에도 없음)을 주면 `no`다. 이 케이스가 없으면 `scope_tok`이 인자를
# 무시해도 `W76`이 초록이다(기준선이 구조로 상수 — `W71`과 같은 형태).
chk "W77: 배선 - 다른 부재 잡 병기어는 release SKILL에 없다" "$(scope_tok "$REL_SKILL" zzz-other-absent)" "no"
chk "W78: absent-job 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$ABSENT_KEY")" "0"
# (W79~W90 · M68) **단계 창** — 위 두 병기어의 토큰은 파일 전역이 아니라 자기 단계를 가리키는 **앵커와 같은 항목
# 창**에 있어야 한다. 창은 토큰이 든 **가장 안쪽 목록 항목의 부분 트리**다(항목 줄부터 들여쓰기가 더 깊은 줄이
# 이어지는 데까지 · 빈 줄은 끊지 않는다). Part N의 `floor_hits_in` 창(최상위 항목의 부분 트리)과 **함수를 공유하지
# 않는다** — 그 정의로는 「게시 분기」 항목 전체가 한 창이라 `open → 대기`로 옮긴 토큰이 초록이다(M68-T01 실측).
# `W70`·`W76`(파일 전역 공존)은 지우지 않는다 — 창 판정이 망가져도 토큰 **삭제**는 여전히 붉어야 한다.
# 앵커 값은 공백을 품을 수 있어 선언 줄의 **첫 백틱 구획**을 읽는다(`floor_marks`와 같은 형태).
anchor_of() { # <선언 키> → 선언 줄 꼬리의 첫 백틱 구획(없으면 빈 출력)
    decl_tail "$CONV" "$1" | LC_ALL=C awk -v q="\`" '{ n = split($0, a, q); if (n >= 3 && a[2] != "") print a[2] }' | head -1
}
item_win_probe() { # <파일> <병기어> <앵커> → "<창 안 앵커 yes|no> <파일의 앵커 줄 수> <창 안 앵커 줄 수>"
    # 토큰의 **첫 등장 줄**에서 위로 올라가며, 그 줄까지의 비어 있지 않은 줄이 모두 자기보다 깊은 **가장 가까운
    # 항목 줄**을 창의 머리로 삼는다. 창의 끝은 그 머리보다 얕거나 같은 들여쓰기의 비어 있지 않은 줄 직전이다.
    # 들여쓰기는 **공백만** 세고 줄 끝 CR은 먼저 벗긴다(ps1 사본의 `ReadAllLines`와 같은 줄을 보게 한다).
    LC_ALL=C awk -v tok="\`$2\`" -v anc="$3" '
        function ind(s,   n) { n = 0; while (substr(s, n + 1, 1) == " ") n++; return n }
        function isitem(s,   t) { t = substr(s, ind(s) + 1); return (substr(t, 1, 2) == "- " || t ~ /^[0-9]+\. /) }
        { sub(/\r$/, ""); L[NR] = $0 }
        END {
            tl = 0
            for (i = 1; i <= NR; i++) if (index(L[i], tok) > 0) { tl = i; break }
            ws = 0; we = 0
            if (tl > 0) {
                for (k = tl; k >= 1; k--) {
                    if (L[k] == "" || !isitem(L[k])) continue
                    d = ind(L[k]); ok = 1
                    for (j = k + 1; j <= tl; j++) if (L[j] != "" && ind(L[j]) <= d) { ok = 0; break }
                    if (ok) {
                        ws = k; we = k
                        for (j = k + 1; j <= NR; j++) { if (L[j] == "") continue; if (ind(L[j]) <= d) break; we = j }
                        break
                    }
                }
            }
            na = 0; nin = 0
            for (i = 1; i <= NR; i++) if (index(L[i], anc) > 0) { na++; if (ws > 0 && i >= ws && i <= we) nin++ }
            printf "%s %d %d\n", (nin > 0 ? "yes" : "no"), na, nin
        }' "$1"
}
win_unique() { # <probe 출력> → 앵커가 파일에 있고 전부 창 안이면 ok
    printf '%s\n' "$1" | LC_ALL=C awk '{ print (($2 + 0) > 0 && ($2 + 0) == ($3 + 0)) ? "ok" : "no" }'
}
SCAN_ANCHOR=$(anchor_of 'scan-control-anchor:')
[ -n "$SCAN_ANCHOR" ] || SCAN_ANCHOR=zzz-scan-anchor-unset
ABSENT_ANCHOR=$(anchor_of 'absent-job-anchor:')
[ -n "$ABSENT_ANCHOR" ] || ABSENT_ANCHOR=zzz-absent-anchor-unset
SCAN_WIN=$(item_win_probe "$REL_SKILL" "$SCAN_ALIAS" "$SCAN_ANCHOR")
ABSENT_WIN=$(item_win_probe "$REL_SKILL" "$ABSENT_ALIAS" "$ABSENT_ANCHOR")
# (W83·W89) **픽스처 통제** — 앵커를 토큰 항목의 **위(부모 항목 줄)와 아래(다음 형제 항목)** 양쪽에 둔 픽스처를
# **같은 헬퍼**에 먹인다. 창이 정확히 토큰 항목 하나일 때만 `no`이므로, 헬퍼가 ⑴ 창을 끊지 않고 파일 전체를 한
# 창으로 보거나 ⑵ 창을 **최상위 항목**의 부분 트리로 넓히거나(= Part N 정의로의 회귀) ⑶ 창의 **끝 경계**를 잃으면
# 셋 다 `yes`로 붉는다(판정의 반응을 묻는 통제). 셋 다 M68 리뷰가 앞 판본의 픽스처를 초록으로 빠져나가는 것을
# 실측해 넓힌 자리다. **아직 통제 밖** — 창 머리를 고르는 깊이 가드(토큰을 담지 않는 항목을 건너뛰는 `ok` 루프)는
# 어느 픽스처도 밟지 않는다(제거해도 전수 초록을 M68 리뷰가 실측했다). 새 픽스처가 필요해 다음 사이클로 넘겼다.
printf '1. step %s\n   - a `%s`\n   - b %s\n' "$SCAN_ANCHOR" "$SCAN_ALIAS" "$SCAN_ANCHOR" > "$SBX/winfx_scan.md"
printf '1. step %s\n   - a `%s`\n   - b %s\n' "$ABSENT_ANCHOR" "$ABSENT_ALIAS" "$ABSENT_ANCHOR" > "$SBX/winfx_absent.md"
chk "W79: scan-control-anchor 선언 줄 정확히 1개" "$(decl_count "$CONV" 'scan-control-anchor:')" "1"
chk "W80: 스캔 단계 앵커 추출 positive-control" "$([ "$SCAN_ANCHOR" != zzz-scan-anchor-unset ] && echo ok || echo no)" "ok"
chk "W81: 스캔 양성 통제 토큰이 앵커와 같은 항목 창에 있다" "${SCAN_WIN%% *}" "yes"
chk "W82: 스캔 단계 앵커가 파일에서 그 창 안에만 있다" "$(win_unique "$SCAN_WIN")" "ok"
chk "W83: 통제 - 앵커 밖 항목 창의 스캔 토큰을 잡는다" "$(item_win_probe "$SBX/winfx_scan.md" "$SCAN_ALIAS" "$SCAN_ANCHOR" | LC_ALL=C awk '{ print $1 }')" "no"
chk "W84: scan-control-anchor 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" 'scan-control-anchor:')" "0"
chk "W85: absent-job-anchor 선언 줄 정확히 1개" "$(decl_count "$CONV" 'absent-job-anchor:')" "1"
chk "W86: 부재 잡 단계 앵커 추출 positive-control" "$([ "$ABSENT_ANCHOR" != zzz-absent-anchor-unset ] && echo ok || echo no)" "ok"
chk "W87: 부재 잡 토큰이 앵커와 같은 항목 창에 있다" "${ABSENT_WIN%% *}" "yes"
chk "W88: 부재 잡 단계 앵커가 파일에서 그 창 안에만 있다" "$(win_unique "$ABSENT_WIN")" "ok"
chk "W89: 통제 - 앵커 밖 항목 창의 부재 잡 토큰을 잡는다" "$(item_win_probe "$SBX/winfx_absent.md" "$ABSENT_ALIAS" "$ABSENT_ANCHOR" | LC_ALL=C awk '{ print $1 }')" "no"
chk "W90: absent-job-anchor 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" 'absent-job-anchor:')" "0"
# (W91~W98 · M70) **새 판정의 생명주기 상태표** — 규약 "새 판정의 생명주기 상태표" 소절의 병기어와 재서술처
# 둘(impl SKILL · impl 템플릿). `lean-decl:`(W58~W66)과 같은 형태이되 재서술처 집합이 달라 세 파일 결합을
# `in_all_three`로 묻는다. 표가 상태 목록을 빠짐없이 덮는가·실측이 정말 돌았는가는 묻지 않는다(규약이 리뷰의 층에 둔다).
LIFE_KEY='lifecycle-decl:'
LIFE_ALIAS=$(decl_tail "$CONV" "$LIFE_KEY" | LC_ALL=C awk '{ print $1 }')
[ -n "$LIFE_ALIAS" ] || LIFE_ALIAS=zzz-lifecycle-decl-unset
chk "W91: lifecycle-decl 선언 줄 정확히 1개" "$(decl_count "$CONV" "$LIFE_KEY")" "1"
chk "W92: 생명주기 병기어 추출 positive-control" "$([ "$LIFE_ALIAS" != zzz-lifecycle-decl-unset ] && echo ok || echo no)" "ok"
chk "W93: 생명주기 병기어($LIFE_ALIAS) 세 파일 전부에 등장" "$(in_all_three "$LIFE_ALIAS" "$CONV" "$IMPL_SKILL" "$IMPL_TPL")" "yes"
chk "W94: 규약이 생명주기 병기어의 정의 줄을 정확히 하나 갖는다" "$(scope_defn "$LIFE_ALIAS")" "1"
chk "W95: impl SKILL이 생명주기 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$IMPL_SKILL" "$LIFE_ALIAS")" "yes"
chk "W96: impl 템플릿이 생명주기 병기어를 백틱 토큰으로 갖는다" "$(scope_tok "$IMPL_TPL" "$LIFE_ALIAS")" "yes"
# (W97) **배선** — `W65`와 같은 형태(인자로 준 토큰은 어느 파일에도 없어 기준선이 구조로 상수다).
chk "W97: 배선 - 다른 생명주기 병기어를 주면 결합이 성립하지 않는다" "$(in_all_three zzz-other-lifecycle "$CONV" "$IMPL_SKILL" "$IMPL_TPL")" "no"
chk "W98: lifecycle-decl 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$LIFE_KEY")" "0"
# (W99~W110 · M71) **전이 표** — 같은 소절이 상태 목록을 손으로 늘리는 열거 대신 **스킬 흐름의 전이**에서 끌어내게 했다.
# 전이마다 선언 줄 하나(`tr-…:`)가 있고 꼬리의 첫 백틱 구획이 출처 파일, 둘째가 그 파일 안의 앵커다. 상태 목록은 ASCII
# 마커 블록 안에서 전이를 인용한다. 무는 것은 넷 — 전이 선언의 유일성 · 앵커가 출처 파일에서 정확히 한 줄 · 덮음(모든 전이가 인용된다) · 고아
# 인용(표에 없는 전이) — 이다. **묻지 않는 것**: 전이 표가 스킬의 분기를 빠짐없이 덮는가 · 앵커가 분기 문장 안에 있는가 · 판정별 격자(조합을
# 밟았는가) · impl 보고서의 표가 목록과 격자를 덮는가. 규약이 넷 다 리뷰의 층에 둔다.
# 헬퍼는 규약 파일과 루트를 인자로 받는다 — 아래 픽스처 통제가 **같은 헬퍼**를 먹여 판정의 반응을 묻기 위해서다.
LTR_KEY='lifecycle-transitions:'
ltr_ids() { # <규약 파일> → 선언된 전이 식별자(한 줄에 하나)
    decl_tail "$1" "$LTR_KEY" | tr -d '`*' | tr ' ' '\n' | grep -v '^$'
}
ltr_seg() { # <규약 파일> <전이> <n> → 그 전이 선언 줄 꼬리의 n번째 백틱 구획(없으면 빈 출력)
    decl_tail "$1" "$2:" | LC_ALL=C awk -v q="\`" -v n="$3" '{ k = split($0, a, q); if (k >= 2 * n + 1 && a[2 * n] != "") print a[2 * n] }' | head -1
}
ltr_dup() { # <규약 파일> → 선언 줄이 정확히 하나가 아닌 전이의 수
    _ln=0
    for _lt in $(ltr_ids "$1"); do [ "$(decl_count "$1" "$_lt:")" = 1 ] || _ln=$((_ln + 1)); done
    echo "$_ln"
}
ltr_anchor_missing() { # <규약 파일> <루트> → 선언 줄이 있는 전이 중 출처 파일에서 앵커가 정확히 한 줄이 아닌 것의 수
    # 선언 줄이 없는 전이는 세지 않는다 — 그 결함은 `ltr_dup`가 따로 문다(한 결함이 두 케이스를 함께 붉히지 않게).
    # **「있다」가 아니라 「정확히 한 줄」이다**(M71 리뷰 라운드 0 차단 1) — 있기만 보면 여러 줄에 나오는 앵커는 그 분기를
    # 지워도 다른 자리의 같은 토큰으로 초록이었다(`pr` 생성 분기를 지워도 「운영 주의」의 `gh pr create`가 남았다).
    _ln=0
    for _lt in $(ltr_ids "$1"); do
        [ "$(decl_count "$1" "$_lt:")" -ge 1 ] || continue
        _lp=$(ltr_seg "$1" "$_lt" 1); _la=$(ltr_seg "$1" "$_lt" 2)
        if [ -z "$_lp" ] || [ -z "$_la" ] || [ ! -f "$2/$_lp" ] || [ "$(LC_ALL=C grep -cF -- "$_la" "$2/$_lp")" != 1 ]; then _ln=$((_ln + 1)); fi
    done
    echo "$_ln"
}
ltr_cited() { # <규약 파일> → 상태 블록 안의 전이 인용(중복 제거, 한 줄에 하나)
    # 인용은 `tr-`로 시작하는 [a-z0-9-] 연속이다 — ps1 사본은 같은 문자 집합의 정규식 매치로 같은 토큰을 얻는다.
    LC_ALL=C awk '/<!-- lifecycle-states:start -->/ { on = 1; next } /<!-- lifecycle-states:end -->/ { on = 0 } on' "$1" |
        LC_ALL=C tr -c 'a-z0-9-' '\n' | LC_ALL=C grep '^tr-' | LC_ALL=C sort -u
}
ltr_uncovered() { # <규약 파일> → 선언된 전이 중 상태 블록이 인용하지 않은 것의 수
    _lc=" $(ltr_cited "$1" | tr '\n' ' ')"
    _ln=0
    for _lt in $(ltr_ids "$1"); do case "$_lc" in *" $_lt "*) ;; *) _ln=$((_ln + 1)) ;; esac; done
    echo "$_ln"
}
ltr_orphans() { # <규약 파일> → 상태 블록이 인용했으나 선언되지 않은 전이의 수
    _ld=" $(ltr_ids "$1" | tr '\n' ' ')"
    _ln=0
    for _lt in $(ltr_cited "$1"); do case "$_ld" in *" $_lt "*) ;; *) _ln=$((_ln + 1)) ;; esac; done
    echo "$_ln"
}
NLTR=$(ltr_ids "$CONV" | grep -c .)
NLCI=$(ltr_cited "$CONV" | grep -c .)
LTR_MARKS="$(LC_ALL=C grep -cF '<!-- lifecycle-states:start -->' "$CONV") $(LC_ALL=C grep -cF '<!-- lifecycle-states:end -->' "$CONV")"
# (W108~W110) **픽스처 통제** — 전이 셋(`tr-fa` · `tr-fb` · `tr-fc`)을 선언하고, 출처 파일에는 `tr-fa`의 앵커를 한 줄 ·
# `tr-fc`의 앵커를 **두 줄** 두고 `tr-fb`의 앵커는 두지 않는다. 상태 블록은 `tr-fa` · `tr-fc`와 표에 없는 `tr-fzz`를 인용한다.
# 앵커는 2(없음 하나 · 두 줄 하나), 덮음 · 고아는 1이어야 한다 — 판정을 「무조건 0」으로 바꾸거나, 앵커 판정을 「있다」로
# 되돌리거나(1이 된다), 인용을 **전이 표 자신**에서 읽게 바꾸면(자기 대조 — 늘 덮인다) 여기서 붉다. 읽는 대상이 픽스처뿐이라
# 기준선이 구조로 상수다.
mkdir -p "$SBX/ltrfx"
printf '  - `lifecycle-transitions:` tr-fa tr-fb tr-fc\n  - `tr-fa:` `sk.md` `anc-a`\n  - `tr-fb:` `sk.md` `anc-b`\n  - `tr-fc:` `sk.md` `anc-c`\n<!-- lifecycle-states:start -->\n  - s1 `tr-fa` `tr-fc` `tr-fzz`\n<!-- lifecycle-states:end -->\n' > "$SBX/ltrfx/conv.md"
printf 'anc-a\nanc-c one\nanc-c two\n' > "$SBX/ltrfx/sk.md"
chk "W99: lifecycle-transitions 선언 줄 정확히 1개" "$(decl_count "$CONV" "$LTR_KEY")" "1"
chk "W100: 전이 추출 positive-control(>0)" "$([ "$NLTR" -gt 0 ] && echo ok || echo no)" "ok"
chk "W101: lifecycle-transitions 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$LTR_KEY")" "0"
chk "W102: 선언 줄이 정확히 하나가 아닌 전이 0개" "$(ltr_dup "$CONV")" "0"
chk "W103: 출처 파일에서 앵커가 정확히 한 줄이 아닌 전이 0개" "$(ltr_anchor_missing "$CONV" "$ROOT")" "0"
chk "W104: 상태 블록 마커가 각각 정확히 하나" "$LTR_MARKS" "1 1"
chk "W105: 전이 인용 추출 positive-control(>0)" "$([ "$NLCI" -gt 0 ] && echo ok || echo no)" "ok"
chk "W106: 상태 목록이 인용하지 않은 전이 0개" "$(ltr_uncovered "$CONV")" "0"
chk "W107: 상태 목록이 인용한 표 밖의 전이 0개" "$(ltr_orphans "$CONV")" "0"
chk "W108: 통제 - 픽스처에서 앵커가 없거나 두 줄인 전이를 센다" "$(ltr_anchor_missing "$SBX/ltrfx/conv.md" "$SBX/ltrfx")" "2"
chk "W109: 통제 - 픽스처에서 인용되지 않은 전이를 센다" "$(ltr_uncovered "$SBX/ltrfx/conv.md")" "1"
chk "W110: 통제 - 픽스처에서 표 밖의 인용을 센다" "$(ltr_orphans "$SBX/ltrfx/conv.md")" "1"
chk "W27: measure-cache 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$MC_KEY")" "0"
# (W28~W29) **표지 키 둘**에는 같은 금지를 다른 사유로 건다 — `markers_of`의 분리 폭은 두 사본 모두
# ASCII 공백 하나로 못박혀 있어 금지 문자가 축을 **가르지 않는다**. 대신 **표지 둘을 한 토큰으로
# 붙여** 선언된 수를 줄이고, `W9`·`W21`은 **줄어든 수와 자기를 비교**해 통과한다. positive-control
# (`W8`·`W20`)은 수가 여전히 0보다 커서 초록이다. **보이지 않는 한 글자가 경계 표지를 은퇴시킬 수
# 없어야 한다.**
chk "W28: scope-limits 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$SCOPE_LIM_KEY")" "0"
chk "W29: verify-scope 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$VS_KEY")" "0"
fi

# (W31~W41 · M64-T04) **측정 배당** — 규약이 `sh` 축 판정의 책임처와 보고서 값의 출처를 가르는 선언
# 줄 둘을 세웠고(`measure-axis:` · `measure-axis-job:`), 재서술처 셋(impl 스킬 · impl 템플릿 · release
# 스킬)은 그 값을 **가리키기만** 한다. 무는 것은 규약이 같은 자리에 적은 셋 — 선언의 존재 · 값의 집합
# 소속 · 지목한 잡의 실재 — 까지다. *"이번 CI 실행이 이 트리를 봤는가"* 는 Part U의 「순서 그 자체」와
# 같은 이유로 정적으로 판정되지 않는다. `measure-cache:`(`W13`~`W18`)와 **같은 층**이라 새 파트를
# 만들지 않았다 — 파트를 가르는 기준은 무는 층이다.
#
# 결합은 **양방향**이다. 한 방향만 두면 반쪽이다 — 선언된 값이 재서술처에서 사라지는 것은 `W36`이,
# 재서술처가 **선언에 없는 값**을 말하는 것은 `W37`이 문다. 앞의 것만 있으면 선언에서 값을 하나 지워도
# 재서술처가 옛 값을 계속 말하는 채 초록이다(Part H가 `axis:` 표기를 양방향으로 대조하는 것과 같은 판단).
axis_sites_have() { # <값> → 재서술처 셋 전부가 그 값을 **백틱 토큰**으로 가지면 yes
    for _axs in "$IMPL_SKILL" "$IMPL_TPL" "$REL_SKILL"; do
        [ "$(scope_tok "$_axs" "$1")" = yes ] || { echo no; return; }
    done
    echo yes
}
axis_site_tokens() { # → 재서술처 셋이 백틱으로 적은 배당 값 토큰(한 줄에 하나, 중복 포함)
    for _axs in "$IMPL_SKILL" "$IMPL_TPL" "$REL_SKILL"; do
        grep -o '`axis-[a-z0-9-]*`' "$_axs" 2>/dev/null
    done | tr -d '`'
}
axis_site_miss() { # → 선언된 값 중 재서술처 셋이 **함께** 갖지 않는 값의 수
    _axm=0
    for _axv in $MA_VALS; do
        [ "$(axis_sites_have "$_axv")" = yes ] || _axm=$((_axm + 1))
    done
    echo "$_axm"
}
# (W42~W43 · M64 재작업 1) **적용 범위의 집행** — 축의 이름은 참조 구현 저장소의 사정이라 사용자 스킬
# (재서술처 셋)은 병기어만 가리키고 축 이름을 적지 않는다(M64 리뷰 차단 2). 무는 형태는 「백틱 이름 +
# 공백 0개 이상 + 축」이다(붙여 쓴 형태도 같은 피해에 이른다 — M64 재작업 1 리뷰). **백틱 없는 「이름 + 축」은 묻지 않는다** — release 스킬의 게시 가용성 축 서술이 백틱
# 없는 영문 이름으로 축을 부르는 정당한 사용이라, 그 형태까지 금지하면 그 줄들이 붉는다(경계 — README에
# 실측과 함께 적는다). 「축」은 바이트로 적는다(`LC_ALL=C` 바이트 매칭 — ps1은 코드포인트 U+CD95).
AXIS_NAME_RE=$(printf '`[A-Za-z][A-Za-z0-9._-]*` *\354\266\225')
axis_name_hits() { # <파일> → 「백틱 이름 + 공백 0개 이상 + 축」 형태가 든 줄 수
    [ -f "$1" ] || { echo 0; return; }
    LC_ALL=C grep -cE "$AXIS_NAME_RE" "$1" 2>/dev/null
}
axis_name_sites() { # → 재서술처 셋의 그 줄 수 합
    _axn=0
    for _axs in "$IMPL_SKILL" "$IMPL_TPL" "$REL_SKILL"; do
        _axn=$((_axn + $(axis_name_hits "$_axs")))
    done
    echo "$_axn"
}
# (W44~W48 · M64 재작업 2) **이름의 직접 금지** — `W42`는 「백틱 이름 + 축」 형태만 봐서, 참조 구현
# 문서의 문장을 그대로 옮긴 「로컬 값은 `pwsh`(과 5.1)」·「CI `posix` 잡」 같은 줄이 지나갔다(M64 재작업 1
# 리뷰 차단 2). 규약이 참조 구현의 축 이름을 선언하고(`measure-axis-names:`) 러너는 그 이름과 지목한
# 잡 이름을 **백틱 토큰으로** 스킬 셋에서 센다. 오늘 `skills/`에 그런 토큰이 0이라 기준선이 0이다.
# **백틱 없는 이름은 묻지 않는다** — `sh`·`bash` 같은 이름은 맨 낱말·명령 조각으로 흔히 나와 맨 낱말
# 금지는 오탐이 된다(경계 — README에 적는다).
axis_name_token_hits() { # <파일> → 선언된 축·잡 이름이 백틱 토큰으로 든 줄 수(이름마다 센 합)
    [ -f "$1" ] || { echo 0; return; }
    _ant=0
    for _anv in $MN_VALS $MJ_JOB; do
        _ant=$((_ant + $(grep -cF "\`$_anv\`" "$1" 2>/dev/null)))
    done
    echo "$_ant"
}
axis_name_token_sites() { # → 재서술처 셋의 그 줄 수 합
    _ans=0
    for _axs in "$IMPL_SKILL" "$IMPL_TPL" "$REL_SKILL"; do
        _ans=$((_ans + $(axis_name_token_hits "$_axs")))
    done
    echo "$_ans"
}
axis_site_orphan() { # → 재서술처가 적은 배당 값 토큰 중 선언에 없는 것의 수
    _axm=0
    for _axt in $(axis_site_tokens); do
        case " $MA_VALS " in *" $_axt "*) : ;; *) _axm=$((_axm + 1)) ;; esac
    done
    echo "$_axm"
}
if part_on W; then
MA_KEY='measure-axis:'
MJ_KEY='measure-axis-job:'
# 값은 **공백·탭으로 가르고 이름 형태의 토큰만** 취한다(ps1은 `-split '[ \t]+'` — `W13`과 같은 폭).
# 꼬리 끝의 탭 한 글자가 토큰에 붙어 결합 판정까지 함께 붉히면 `W40`·`W41`이 단독 행을 가질 수 없다.
MA_VALS=$(decl_tail "$CONV" "$MA_KEY" | tr ' \011' '\n\n' | grep -E '^[a-z][a-z0-9-]*$' | tr '\n' ' ' | sed 's/ *$//')
NMAV=$(printf '%s\n' "$MA_VALS" | tr ' ' '\n' | grep -c .)
MJ_JOB=$(decl_tail "$CONV" "$MJ_KEY" | tr ' \011' '\n\n' | grep -E '^[a-z][a-z0-9-]*$' | head -1)
NAXT=$(axis_site_tokens | grep -c .)
MA_WF="$ROOT/.github/workflows/tests.yml"
chk "W31: measure-axis 선언 줄 정확히 1개" "$(decl_count "$CONV" "$MA_KEY")" "1"
chk "W32: measure-axis-job 선언 줄 정확히 1개" "$(decl_count "$CONV" "$MJ_KEY")" "1"
# (W33~W35) 추출 positive-control 셋 — 각각 0이면 아래 본 검사가 **0 == 0**으로 공허 통과한다.
# `W35`는 재서술처 쪽 추출이다: 토큰 형태(`axis-` 접두)가 바뀌어 아무것도 긁히지 않으면 `W37`이 공허다.
chk "W33: 배당 축 값 추출 positive-control(>0)" "$([ "$NMAV" -gt 0 ] && echo ok || echo no)" "ok"
chk "W34: 배당 잡 추출 positive-control" "$([ -n "$MJ_JOB" ] && echo ok || echo no)" "ok"
chk "W35: 재서술처의 배당 토큰 추출 positive-control(>0)" "$([ "$NAXT" -gt 0 ] && echo ok || echo no)" "ok"
# (W36~W38) **본 검사**.
chk "W36: 선언된 배당 값마다 재서술처 셋이 백틱 토큰으로 갖는다" "$(axis_site_miss)" "0"
chk "W37: 재서술처가 선언에 없는 배당 값을 말하지 않는다" "$(axis_site_orphan)" "0"
# (W38) 지목한 잡의 실재 — 잡 이름 집합은 Part H와 **같은 함수**(`ci_job_names`)로 발견한다. 지목한
# 잡이 워크플로에 없으면 배당은 **아무 데도 가리키지 않는 선언**이 된다.
chk "W38: 배당이 지목한 CI 잡이 워크플로에 실재" "$(has_job "$(ci_job_names "$MA_WF")" "$MJ_JOB")" "yes"
# (W39) **배선** — `W18`과 같은 형태(인자로 준 토큰 하나만 읽고 그 토큰은 어느 파일에도 없어 기준선이
# **구조로 상수**다). 이 케이스가 없으면 `axis_sites_have`가 인자를 무시해도 `W36`이 초록이다.
chk "W39: 배선 - 선언에 없는 값을 주면 재서술처 결합이 성립하지 않는다" "$(axis_sites_have zzz-other-axis)" "no"
# (W40~W41) 꼬리 구분자 — `W26`~`W29`와 같은 헬퍼·같은 사유.
chk "W40: measure-axis 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$MA_KEY")" "0"
chk "W41: measure-axis-job 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$MJ_KEY")" "0"
# (W42) **본 검사** — 재서술처 셋이 축 이름을 백틱으로 적지 않는다(적용 범위).
chk "W42: 재서술처 셋이 축 이름을 백틱으로 적지 않는다" "$(axis_name_sites)" "0"
# (W43) **통제** — 같은 판정 함수가 픽스처 한 줄을 잡는다. 픽스처를 건 값과 걸지 않은 값의 **차이**를
# 묻는다(`control-reads-delta`) — 기준선이 0이 아닐 때도 이 통제는 자기가 무는 반응만 잰다.
AXN_FIX="$SBX/axis-name-fixture.md"
# 픽스처는 **두 줄**이다 — 공백 하나 형태와 붙여 쓴 형태. 붙여 쓴 형태가 없으면 정규식의 「공백 0개
# 이상」을 공백 하나로 되돌려도 이 통제가 초록이다(M64 재작업 1 리뷰 사소 7).
{ cat "$IMPL_TPL" 2>/dev/null; echo; echo '| 로컬 `pwsh` 축 |'; echo '| 로컬 `pwsh`축 |'; } > "$AXN_FIX"
chk "W43: 통제 — 판정 함수가 백틱 축 이름 픽스처를 잡는다" "$(( $(axis_name_hits "$AXN_FIX") - $(axis_name_hits "$IMPL_TPL") ))" "2"
MN_KEY='measure-axis-names:'
MN_VALS=$(decl_tail "$CONV" "$MN_KEY" | tr ' \011' '\n\n' | LC_ALL=C grep -E '^[a-z][a-z0-9-]*$' | tr '\n' ' ' | sed 's/ *$//')
NMNV=$(printf '%s\n' "$MN_VALS" | tr ' ' '\n' | grep -c .)
chk "W44: measure-axis-names 선언 줄 정확히 1개" "$(decl_count "$CONV" "$MN_KEY")" "1"
# (W45) 추출 positive-control — 0이면 `W46`이 잡 이름 하나만 세는 반쪽 검사가 된다.
chk "W45: 참조 구현 축 이름 추출 positive-control(>0)" "$([ "$NMNV" -gt 0 ] && echo ok || echo no)" "ok"
# (W46) **본 검사**.
chk "W46: 재서술처 셋에 참조 구현의 축·잡 이름이 백틱 토큰으로 없다" "$(axis_name_token_sites)" "0"
# (W47) **통제** — 실물과, 선언된 첫 축 이름 · 지목한 잡 이름의 백틱 토큰 **두 줄**을 붙인 픽스처의
# **차이**를 묻는다. 두 줄인 이유는 `W46`의 두 절반(축 이름 · 잡 이름)을 각각 통제하기 위해서다 — 한 줄이던
# 동안 세는 루프에서 잡 이름을 빼도 초록이었다(M64 재작업 2 리뷰 사소 4).
AXT_FIX="$SBX/axis-token-fixture.md"
AXT_FIRST=$(printf '%s\n' $MN_VALS | head -1)
{ cat "$IMPL_TPL" 2>/dev/null; echo; printf '| 로컬 `%s` |\n' "$AXT_FIRST"; printf '| CI `%s` |\n' "$MJ_JOB"; } > "$AXT_FIX"
chk "W47: 통제 — 판정 함수가 선언된 이름의 백틱 토큰 픽스처를 잡는다" "$(( $(axis_name_token_hits "$AXT_FIX") - $(axis_name_token_hits "$IMPL_TPL") ))" "2"
chk "W48: measure-axis-names 선언 줄 꼬리에 금지 구분자 0건" "$(bad_seps "$CONV" "$MN_KEY")" "0"
fi

# **`F1`은 전수 실행에서만 돈다**(M64-T03) — 부분 실행에서 이 대조가 돌면 구조상 언제나 붉어
# 통제가 공허해진다. 부분 실행의 결과 줄은 아래에서 **다른 접두**로 나가므로 그 총계를 케이스 수
# 선언과 견줄 수 있다는 오해도 함께 닫힌다.
if part_full; then
chk "F1: README cases 선언 == 실제 케이스 수" "$(declared_cases)" "$((pass + fail + 1))"
fi

echo
if part_full; then
    echo "$RESULT_FULL_PREFIX PASS=$pass FAIL=$fail (실제 커맨드 스킬 N=$N)"
else
    echo "$(result_prefix "$PART_SEL") PASS=$pass FAIL=$fail"
fi
[ "$fail" -eq 0 ] || exit 1
part_full || exit 0
echo "# discover 감지 임계값(≥2→hint·<2→none·단일 레포→none·숨김 미카운트) + 단일 원본 동결(B1 카운트 정합·B2 사이트 셸·B3 카탈로그 완전성, 캐노니컬=docs/commands.md, 실제 ${N}종) + 선언 정합(C1 상태값 네 값×세 파일·부재 통제·C2 기준선×세 템플릿·C3 phase 명단 기록·비기록 두 목록의 규약↔발행 페이지 집합 일치·유일 열거처·서로소·음성 통제·D 브랜치 협업 안전 커버리지(커밋 diff·미커밋 범위 두 토큰 — 규약↔스킬↔캐노니컬 카탈로그)·번호경고 규약↔스킬 정합·PR CI 확인 규약조각↔스킬 정합·E 리뷰 검증 규율 반증 시도·판정 계측·재작업 라운드 규약↔스킬↔템플릿 정합 + 계측 줄 골격 형식 정합 + 재검증 선언 + 교차·음성 통제 · F 문서 자기서술 정합 = 역할 앵커 추출·캐노니컬 행 실재·소비자 전파 + 케이스 수 자기 정합 · G 상호참조 무결성 = 인용 추출·앵커 실재 대조 + 추출 0건·이름 유일성·줄바꿈 인용 통제 + 규약 집합 밖 대상 인용의 파일별 앵커 대조(골격 조사 요구·주입 통제 — 대상 파일 부재는 경계 밖) · I 축 상태 주장 정합 = 표가 집행된다고 적은 축을 산문이 반대로 적는 자리(표지는 규약이 단일 선언처, 창=불릿 블록, 인용·이력 서술·무대상 세 통제 — 축 이름이 아닌 대상의 모순과 반대 방향은 경계 밖) · H 실행 환경 축 선언 정합 = 축 이름 추출·규약 표 행 실재·집합 일치·표의 job: 토큰이 가리킨 잡의 워크플로 실재와 선언 축 행 소속(고아 0)·커버리지(실재 잡의 등재 또는 면제 선언)·면제 선언의 실재·무토큰 축 통제·axis: 표기 양방향 정합·데이터 행 수 대조·음성 통제 — 잡을 지목하지 않는 집행 칸과 잡을 지목한 칸의 나머지 서술은 사람의 리뷰 영역이라 여기서 묻지 않음) 확인됨 (참조 구현 기준)"

# --- 뮤테이션 선언 (M47) — `tests/mutation`이 읽는다 -------------------------
# 형식: `# mutates: <파일> :: <토큰> :: <케이스 라벨 안정 접두> :: <caught|missed>`
# 토큰은 **필드 구분자 ` :: `와 앞뒤 공백만** 금지한다(M63 — 앞 판본은 영숫자·하이픈만 허용해
# **판정 코드의 리터럴을 적을 수 없었고**, 그것이 죽은 통제를 아무도 못 잡던 이유였다). 라벨은
# 보간(`$`) 앞까지의 안정 접두이며 이 사본 안에서 유일하다. ps1 사본은 자기 언어의 라벨로 같은
# 선언을 둔다.
#   **`# mutates:`(고정 대체)로 무력화되려면 리터럴의 「짝」이 이 파일 밖에 있어야 한다**(M63 실측)
#   — 치환은 파일 전역이라 비교의 **양변이 같은 파일 안**에 있으면 둘 다 함께 바뀌어 동작이 그대로다.
#   아래 셋째 선언이 무는 굵은 코드 스팬은 짝이 규약·픽스처에 있어 죽는다.
#   **`# mutates-to:`에는 그 제약이 없다**(M63 리뷰) — 대체값을 선언이 정하므로 **비대칭 치환**이
#   되고, 자기 변수끼리 비교하는 자리(나열 줄 거름 등)도 **선언할 수 있다**. M63은 비용을 사유로
#   선언을 미뤘고, **M65가 아래 다섯째 선언으로 실제로 선언했다**(M64가 그 `sh` 축 판정을 CI에 넘긴 뒤). 경계의 단일 원본은 `tests/mutation/README.md`다.
# mutates: docs/conventions.md :: declared-change-set :: D7: conventions :: caught
# mutates: docs/conventions.md :: mutation-negative-control-sentinel :: D7: conventions :: missed
# mutates-to: tests/discover/run.sh :: printf '**`%s`**' "$_mm" :: printf '`%s`' "$_mm" :: W24: 적대 통제 :: caught
# mutates-to: tests/discover/run.sh :: '`axis-[a-z0-9-]*`' :: '`zzz-[a-z0-9-]*`' :: W35: 재서술처의 배당 토큰 추출 :: caught
# mutates-to: tests/discover/run.sh :: [ "$_mall" -eq 1 ] && continue :: [ "$_mall" -eq 9 ] && continue :: W25: 적대 통제 - 표지를 전부 :: caught
