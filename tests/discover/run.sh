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
# 사용: sh tests/discover/run.sh   (성공 시 exit 0, 하나라도 실패 시 exit 1)

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

# --- Part A 시나리오 ---
chk "A: 자식 tide 레포 2개 → hint N=2"            "$(detect_hint "$P2")" "hint N=2"
chk "A: 자식 tide 레포 1개 → none"                "$(detect_hint "$P1")" "none"
chk "A: 자식 tide 레포 0개 → none"                "$(detect_hint "$P0")" "none"
chk "A: 단일 레포 루트(자식 src 등 비-tide) → none" "$(detect_hint "$SR")" "none"
chk "A: 자식 2개 + 숨김 tide 자식 → hint N=2(숨김 미카운트)" "$(detect_hint "$PH")" "hint N=2"
chk "A: 숨김 자식(.hidden-svc) 미발견"             "$(discover "$PH" | grep -c hidden)" "0"
chk "A: 발견 = svc-a,svc-b (숨김 제외)"            "$(discover "$PH" | tr '\n' ',')" "svc-a,svc-b,"

# === Part B — 단일 원본 동결: 카탈로그 단일 원본 + 드리프트 가드 ==========
# (M22) 커맨드 카탈로그를 docs/commands.md 단일 원본으로 끌어오고, 사이트는 스니펫 셸이다.
# 가드는 (B1) 카운트 선언 정합, (B2) 사이트 카탈로그 페이지가 셸(재복제 아님),
# (B3) 카탈로그 완전성(각 커맨드 이름 등장)을 검증한다 — M20 리뷰 #6 회귀 고정의 확장.

# 실제 커맨드 스킬 개수 = skills/*/SKILL.md 파일 수.
N=$(ls "$ROOT"/skills/*/SKILL.md 2>/dev/null | grep -c .)
chk "B: 실제 커맨드 스킬 개수 측정(>0)" "$([ "$N" -gt 0 ] && echo ok || echo no)" "ok"

README="$ROOT/README.md"
CONV="$ROOT/docs/conventions.md"
CANON_CMD="$ROOT/docs/commands.md"        # 새 캐노니컬 커맨드 카탈로그(단일 원본)
SITE_CMD="$ROOT/site/docs/commands.md"    # 사이트 셸(스니펫 인클루드)
SITE_GS="$ROOT/site/docs/getting-started.md"
ORCH="$ROOT/docs/orchestration.md"       # 사이트 본문으로 인클루드되는 오케스트레이션 안내(카운트 선언 보유)

# (B1) 카운트 선언 정합 — "N종"(예: 11종) 선언 파일이 실제 스킬 수와 일치(불일치면 FAIL).
#      site/docs/commands.md는 이제 셸이라 카운트 비보유 → 캐노니컬 docs/commands.md로 대체.
declared_has_count() { # <file> <N> → yes|no
    [ -f "$1" ] && grep -qF "${2}종" "$1" && echo yes || echo no
}
chk "B1: docs/commands.md 가 ${N}종 선언(캐노니컬)"     "$(declared_has_count "$CANON_CMD" "$N")" "yes"
chk "B1: README.md 가 ${N}종 선언"                     "$(declared_has_count "$README" "$N")" "yes"
chk "B1: docs/conventions.md 가 ${N}종 선언"           "$(declared_has_count "$CONV" "$N")" "yes"
chk "B1: site/docs/getting-started.md 가 ${N}종 선언"  "$(declared_has_count "$SITE_GS" "$N")" "yes"
chk "B1: docs/orchestration.md 가 ${N}종 선언"          "$(declared_has_count "$ORCH" "$N")" "yes"

# (B2) 사이트 카탈로그 페이지가 스니펫 셸인지 — 인클루드 보유 AND 카운트·카탈로그 표 미재선언.
#      재수기화(카탈로그 복귀) 시 FAIL → 단일 원본화를 강제한다.
is_snippet_shell() { # <file> <N> → yes|no
    [ -f "$1" ] || { echo no; return; }
    grep -qF '8<-- "docs/commands.md:body"' "$1" || { echo no; return; }   # 스니펫 인클루드 보유
    grep -qF "${2}종" "$1" && { echo no; return; }                          # 카운트 재선언 = 셸 아님
    grep -qF '|---|---|---|---|' "$1" && { echo no; return; }               # 카탈로그 표 재선언 = 셸 아님
    echo yes
}
chk "B2: site/docs/commands.md 는 스니펫 셸(재복제 아님)" "$(is_snippet_shell "$SITE_CMD" "$N")" "yes"

# (B3) 카탈로그 완전성 — 각 커맨드 이름이 캐노니컬 카탈로그에 /tide:<name> 으로 등장.
#      개수만 맞고 이름이 빠지거나 바뀐 표류(개수 가드가 못 잡던 것)를 적발한다.
#      이름 뒤 경계(영문·하이픈 아님)를 요구해 prefix 오탐을 막는다 — /tide:fleet 이
#      /tide:fleet-cycle 에 substring으로 걸려 거짓 통과하지 않도록(fleet ≠ fleet-cycle).
has_command() { # <file> <name> → yes|no
    [ -f "$1" ] && grep -qE "/tide:$2([^a-z-]|$)" "$1" && echo yes || echo no
}
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

# === Part D — 브랜치 간 협업 안전(M31) 선언 정합 =========================
# (M31) Part B/C와 동형 — 규약(conventions 단일 원본)과 그것을 배선하는 스킬이 같은 메커니즘을
# 선언하는지 결합한다. 두 검사(릴리즈 커버리지 체크·마일스톤 번호 사전경고)는 프롬프트 규율이라
# 런타임 발화는 하니스로 집행 못 하지만, **규약↔스킬 선언 정합**은 결정적으로 고정할 수 있다.
# ASCII 메커니즘 토큰(git 읽기 명령)으로 집행해 ps1의 ASCII-only 원본 규율과도 정합한다.
# (D1) 릴리즈 커버리지 체크: `git diff --name-only`가 conventions와 release SKILL 둘 다에 등장,
# (D2) 마일스톤 번호 사전경고: `git log --all`이 conventions와 milestone SKILL 둘 다에 등장.
# 단일 원본은 conventions "릴리즈 커버리지 체크" 절 + "마일스톤 문서"의 번호 사전경고 항목.

REL_SKILL="$ROOT/skills/release/SKILL.md"
MS_SKILL="$ROOT/skills/milestone/SKILL.md"
COV_TOK='git diff --name-only'
WARN_TOK='git log --all'

# (D1) 커버리지 체크 메커니즘이 규약과 스킬 둘 다에 선언(한 곳만 있으면 갈라짐 → FAIL).
chk "D1: conventions 가 커버리지 체크($COV_TOK) 선언" "$(has_token "$CONV" "$COV_TOK")" "yes"
chk "D1: release SKILL 이 커버리지 체크 배선"          "$(has_token "$REL_SKILL" "$COV_TOK")" "yes"

# (D2) 번호 사전경고 메커니즘이 규약과 스킬 둘 다에 선언.
chk "D2: conventions 가 번호 사전경고($WARN_TOK) 선언" "$(has_token "$CONV" "$WARN_TOK")" "yes"
chk "D2: milestone SKILL 이 번호 사전경고 배선"        "$(has_token "$MS_SKILL" "$WARN_TOK")" "yes"

# 교차 통제 — 각 메커니즘은 반대 스킬에 없어야 한다(토큰 구별력: 커버리지=release, 경고=milestone).
chk "D: 통제 — milestone SKILL 에 커버리지 토큰 없음" "$(has_token "$MS_SKILL" "$COV_TOK")" "no"
chk "D: 통제 — release SKILL 에 번호경고 토큰 없음"   "$(has_token "$REL_SKILL" "$WARN_TOK")" "no"

# 음성 통제 — 존재하지 않는 가짜 메커니즘 토큰은 규약에 없어야 한다(가드 구별력 입증, B1의 N+1종 부재와 동형).
chk "D: 통제 — conventions에 가짜 토큰 없음" "$(has_token "$CONV" "git diff --bogus-only")" "no"

# === Part E — 리뷰 검증 규율(M32) 선언 정합 ==============================
# (M32) Part C/D와 동형 — 규약(conventions 단일 원본)과 그것을 배선하는 스킬·템플릿이 같은
# 메커니즘을 선언하는지 결합한다. 반증 시도가 런타임에 실제로 디스패치되는지는 프롬프트 규율이라
# 하니스로 집행할 수 없지만, **규약↔스킬↔템플릿 선언 정합**은 결정적으로 고정할 수 있다
# (Part C·D와 같은 분담). 토큰은 전부 ASCII 병기어(conventions "리뷰 검증 규율" 절의 ASCII 병기
# 결정)라 ps1 사본이 코드포인트 조립 없이 같은 토큰을 앵커한다.
# (E1) 반증 시도: `refutation`이 conventions·review SKILL 둘 다에 등장,
# (E2) 판정 계측: `in-review`가 conventions·review SKILL·review 템플릿 세 곳 모두에 등장,
# (E3) 재작업 라운드: `rework`가 conventions·review 템플릿·impl 템플릿 세 곳 모두에 등장.
# 단일 원본은 conventions "리뷰 검증 규율" 절.

REV_SKILL="$ROOT/skills/review/SKILL.md"
REV_TPL="$ROOT/skills/review/template.md"
REFUT_TOK='refutation'
MEAS_TOK='in-review'
REWORK_TOK='rework'
REVERIFY_TOK='re-verify'

in_both() { # <token> <f1> <f2> → yes|no
    for f in "$2" "$3"; do
        [ "$(has_token "$f" "$1")" = yes ] || { echo no; return; }
    done
    echo yes
}

# (E1) 반증 시도 메커니즘이 규약과 review 스킬 둘 다에 선언(한 곳만 있으면 갈라짐 → FAIL).
chk "E1: 반증 시도($REFUT_TOK) 규약↔review SKILL 정합"  "$(in_both "$REFUT_TOK" "$CONV" "$REV_SKILL")" "yes"

# (E2) 판정 계측 토큰이 규약·스킬·템플릿 세 곳 전부에 선언(계측 줄은 템플릿에도 자리가 있어야 한다).
chk "E2: 판정 계측($MEAS_TOK) 세 파일 전부에 등장"      "$(in_all_three "$MEAS_TOK" "$CONV" "$REV_SKILL" "$REV_TPL")" "yes"

# (E3) 재작업 라운드는 review 계측 줄과 impl 개요가 같은 값을 적으므로 세 곳 선언이 결합 조건이다.
chk "E3: 재작업 라운드($REWORK_TOK) 세 파일 전부에 등장" "$(in_all_three "$REWORK_TOK" "$CONV" "$REV_TPL" "$IMPL_TPL")" "yes"

# (E4) 계측 줄 **형식** 정합 — 토큰이 파일 어딘가에 있기만 해선 부족하다. 실제로 M32 구현 중 세 파일이
# `재작업 라운드 {n}` / `재작업 라운드(rework) {n}` 두 이형으로 갈렸고(E1~E3는 전부 통과했다), 사람이
# 손으로 잡았다. 고정 형식의 **ASCII 골격**(`in-review` … `(rework)`가 같은 한 줄)을 결합해 그 이형을
# 잡는다 — 한글 본문을 앵커하지 않으므로 ps1의 ASCII-only 원본 규율도 유지된다.
same_line() { # <file> <tokA> <tokB> → yes|no  (두 토큰이 같은 한 줄에 있으면 yes)
    [ -f "$1" ] && grep -F "$2" "$1" 2>/dev/null | grep -qF "$3" && echo yes || echo no
}
for pair in "conventions:$CONV" "review SKILL:$REV_SKILL" "review 템플릿:$REV_TPL"; do
    chk "E4: 계측 줄 골격(${MEAS_TOK}…(${REWORK_TOK})) ${pair%%:*}" \
        "$(same_line "${pair#*:}" "$MEAS_TOK" "($REWORK_TOK)")" "yes"
done

# (E5) 재검증 규약 선언 정합 — `in-review`만으로는 이 규약을 앵커할 수 없다. 그 토큰은 계측 줄에도
# 있어(이중 용도) **재검증 절을 통째로 지워도 E2가 통과**한다(M32 리뷰의 반증 패스가 복사본에서 실증).
# 그래서 재검증 전용 ASCII 병기어 `re-verify`를 세 파일에 결합한다.
chk "E5: 재검증($REVERIFY_TOK) 세 파일 전부에 등장" "$(in_all_three "$REVERIFY_TOK" "$CONV" "$REV_SKILL" "$REV_TPL")" "yes"

# 교차 통제 — 반증 시도는 review 자산이라 impl 템플릿에 없어야 한다(토큰 구별력, Part D 교차 통제와 동형).
chk "E: 통제 — impl 템플릿에 반증 토큰 없음" "$(has_token "$IMPL_TPL" "$REFUT_TOK")" "no"

# 교차 통제 — 계측 줄은 review 자산이라 impl 템플릿엔 골격이 없어야 한다(개요엔 rework 값만 적는다).
chk "E: 통제 — impl 템플릿에 계측 줄 골격 없음" "$(same_line "$IMPL_TPL" "$MEAS_TOK" "($REWORK_TOK)")" "no"

# 음성 통제 — 존재하지 않는 가짜 토큰은 규약에 없어야 한다(B1의 N+1종 부재·Part D 가짜 토큰과 동형).
chk "E: 통제 — conventions에 가짜 반증 토큰 없음" "$(has_token "$CONV" "${REFUT_TOK}-bogus")" "no"

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

# 인용 후보 줄 — 집합의 **어느 파일명이든** 든 줄. 스니펫 인클루드 지시어 줄(`8<--`)은 제외한다.
citation_lines() {
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        grep -F -f "$SBX/convbases.txt" "$f" 2>/dev/null | grep -v '8<--'
    done < "$SBX/living.txt"
}

# 인용의 파일 귀속 — 그 줄에 등장한 규약 파일명들의 인덱스(쉼표 결합). 없으면 빈 문자열.
line_owners() { # <line> → "1" | "1,2" | ""
    o=""; i=0
    while IFS= read -r b; do
        i=$((i + 1))
        case "$1" in *"$b"*) o="$o,$i" ;; esac
    done < "$SBX/convbases.txt"
    printf '%s' "${o#,}"
}

citation_lines > "$SBX/citelines.txt"
# 인용 = 후보 줄의 따옴표 구획. 골격 자리표({} 포함)와 빈 구획은 인용이 아니다(빈 줄로 떨어진다).
# 레코드 형식은 `<인덱스 목록> <인용>` — 인용은 공백 제거 후라 공백을 담지 않는다.
cite_records() {
    while IFS= read -r line; do
        o=$(line_owners "$line")
        [ -n "$o" ] || continue
        printf '%s\n' "$line" | grep -o '"[^"]*"' |
            sed 's/^"//; s/"$//' | grep -v '[{}]' | tr -d ' \r' |
            while IFS= read -r span; do
                [ -n "$span" ] || continue
                printf '%s %s\n' "$o" "$span"
            done
    done < "$SBX/citelines.txt"
}
cite_records > "$SBX/cites.txt"

NANCHOR=$(grep -c . "$SBX/anchors.txt")
NCITE=$(grep -c . "$SBX/cites.txt")

# `--`와 `</dev/null`이 둘 다 필요하다: 인용 이름이 `-`로 시작하면 grep이 그것을 **옵션**으로 읽고,
# 그러면 패턴 인자가 없어 파일명을 패턴으로 삼아 **stdin을 읽는다** — 그 stdin이 이 루프의 입력이라
# 나머지 인용이 통째로 소비돼 미검사로 남는다(실측: miss가 0으로 나오며 가드가 조용히 죽는다).
# 귀속된 파일이 둘이면 **어느 집합에든 있으면** 통과다(안전 측).
cite_miss() {
    n=0
    while IFS= read -r rec; do
        o=${rec%% *}; c=${rec#* }
        [ -n "$c" ] || continue
        ok=no; rest=$o
        while [ -n "$rest" ]; do
            i=${rest%%,*}
            case "$rest" in *,*) rest=${rest#*,} ;; *) rest="" ;; esac
            grep -qxF -- "$c" "$SBX/anchors.$i.txt" </dev/null && ok=yes
        done
        [ "$ok" = yes ] || n=$((n + 1))
    done < "$SBX/cites.txt"
    echo "$n"
}
# 가짜 이름·유일성 통제는 **집합 전체**(합친 anchors.txt)를 본다.
has_anchor_name() { grep -qxF -- "$1" "$SBX/anchors.txt" </dev/null && echo yes || echo no; }
odd_quote_lines() { awk '{ n = gsub(/"/, "&"); if (n % 2 == 1) c++ } END { print c + 0 }' "$SBX/citelines.txt"; }

chk "G1: 살아 있는 인용이 전부 실재 앵커를 가리킴" "$(cite_miss)" "0"
chk "G2: 인용 추출 positive-control(>0)"          "$([ "$NCITE" -gt 0 ] && echo ok || echo no)" "ok"
chk "G2: 앵커 추출 positive-control(>0)"          "$([ "$NANCHOR" -gt 0 ] && echo ok || echo no)" "ok"
chk "G2: 통제 — 가짜 앵커 이름(bogus-section) 부재" "$(has_anchor_name 'bogus-section')" "no"
chk "G2: 앵커 이름 유일성(정규화 후 중복 0)"       "$(sort "$SBX/anchors.txt" | uniq -d | grep -c .)" "0"
chk "G3: 인용 줄 따옴표 종결(줄바꿈 인용 0)"       "$(odd_quote_lines)" "0"

declared_cases() {
    sed -n 's/.*cases:[^0-9]*\([0-9][0-9]*\).*/\1/p' "$DISC_README" 2>/dev/null | head -1
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
chk "F1b: 파트별 내역 합 == 총계 선언" "$(part_sum)" "$(declared_cases)"

# (F1) 마지막 케이스 — 자기 README 선언(`cases: N`)과 실제 케이스 수(누계 + 이 케이스) 대조.
chk "F1: README cases 선언 == 실제 케이스 수" "$(declared_cases)" "$((pass + fail + 1))"

echo
echo "# 결과: PASS=$pass FAIL=$fail (실제 커맨드 스킬 N=$N)"
[ "$fail" -eq 0 ] || exit 1
echo "# discover 감지 임계값(≥2→hint·<2→none·단일 레포→none·숨김 미카운트) + 단일 원본 동결(B1 카운트 정합·B2 사이트 셸·B3 카탈로그 완전성, 캐노니컬=docs/commands.md, 실제 ${N}종) + 선언 정합(C1 상태값 네 값×세 파일·부재 통제·C2 기준선×세 템플릿·D 브랜치 협업 안전 커버리지·번호경고 규약↔스킬 정합·E 리뷰 검증 규율 반증 시도·판정 계측·재작업 라운드 규약↔스킬↔템플릿 정합 + 계측 줄 골격 형식 정합 + 재검증 선언 + 교차·음성 통제 · F 문서 자기서술 정합 = 역할 앵커 추출·캐노니컬 행 실재·소비자 전파 + 케이스 수 자기 정합 · G 상호참조 무결성 = 인용 추출·앵커 실재 대조 + 추출 0건·이름 유일성·줄바꿈 인용 통제) 확인됨 (참조 구현 기준)"
