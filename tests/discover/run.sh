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
# (M38-T04) 의미는 **"점으로 시작하는 디렉터리는 커맨드 스킬이 아니다"** 이고, 이 글롭이 그 의미를
# 공짜로 만족한다(POSIX 글롭은 선행 점 성분을 매치하지 않는다). ps1의 `Get-ChildItem -Directory`는
# 점 디렉터리를 **포함**하므로 그쪽에 같은 의미의 점 필터를 명시했다 — 없던 동안 `skills/.spare/SKILL.md`
# 하나로 sh 85/0 exit 0 vs ps1 79/6 exit 1로 갈렸다(같은 러너의 Part G는 점 필터를 갖고 있어
# **한 러너 안에서 파트끼리 규율이 달랐다**). 범위 표의 Part B 가지가 이 의미의 선언처다.
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

chk "C4: 규약 stable 명단 이름 11개"   "$(stable_count "$CONV")"   "11"
chk "C4: README stable 명단 이름 11개" "$(stable_count "$README")" "11"
chk "C4: 두 stable 명단 집합 일치" "$(sets_equal "$(stable_set "$CONV")" "$(stable_set "$README")")" "yes"
chk "C4: stable 열거 파일은 규약·README 둘뿐" "$(stable_files)" "README.md docs/conventions.md"
chk "C4: stable 명단 통제 — 규약에 phantom-stable 없음"   "$(stable_has "$CONV" phantom-stable)"   "no"
chk "C4: stable 명단 통제 — README에 phantom-stable 없음" "$(stable_has "$README" phantom-stable)" "no"

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

citation_lines > "$SBX/citelines.txt"
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
cite_records > "$SBX/cites.txt"

NANCHOR=$(grep -c . "$SBX/anchors.txt")
NCITE=$(grep -c . "$SBX/cites.txt")

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
selfref_scan "$SBX/living.txt" "$SBX/selfrefs.txt" "$SBX/selfmiss.txt"
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
SELF_MISS=$(cat "$SBX/selfmiss.txt")
NSELF=$(grep -c . "$SBX/selfrefs.txt")
selfref_has() { grep -qxF -- "$1" "$SBX/selfrefs.txt" </dev/null && echo yes || echo no; }

chk "G4: 자기참조가 전부 자기 파일 앵커를 가리킴"   "$SELF_MISS" "0"
chk "G4: 자기참조 추출 positive-control(>0)"        "$([ "$NSELF" -gt 0 ] && echo ok || echo no)" "ok"
chk "G4: 통제 — 가짜 이름(bogus-section) 자기참조 부재" "$(selfref_has 'bogus-section')" "no"
# (M54) 픽스처 통제 — **같은 스캔**을 자기 파일에 없는 앵커를 가리키는 사본에 건다. 위 `G1`과 같은
# 사유이고 같은 반환에서 왔다(M50 리뷰 권장 1 · 부인 기록 있음 · 세 사이클 이월).
chk "G4: 픽스처 통제 — 미해소 자기참조를 실제로 잡는다" "$(selfref_fixture)" "1"

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
CONV_AXES=$(env_axes "$CONV")
READ_AXES=$(env_axes "$DISC_README")
NAXES=$(printf '%s\n' "$CONV_AXES" | tr ' ' '\n' | grep -c .)

# (H14~H16 · M40) 축 이름의 **해소 가능한 표기** `axis:<이름>`. 표기 이전에는 검사가 전부 `env-axes:`
# 선언을 기점으로 돌아서, **선언에 없는 표 행**은 무엇을 적든 아무 검사도 걸리지 않았다(M38 실측:
# 미선언 `ghost-axis` 행이 실재 잡을 지목해도 초록). 이제 표 쪽에서도 축을 셀 수 있으므로 **양방향**
# 대조가 선다 — 선언에 있는데 표기가 없어도, 표기가 있는데 선언에 없어도 FAIL이다.
# `job:`과 같은 형태라 추출기도 같은 모양이다(표 행에서 토큰만 긁는다).
table_axis_tokens() { # <file> → 정렬·중복제거된 표 행의 `axis:<이름>` (접두사 제거)
    grep -E '^\|' "$1" 2>/dev/null | grep -o 'axis:[a-z][a-z-]*' | sed 's/^axis://' |
        LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ *$//'
}
CONV_AXIS_TOKENS=$(table_axis_tokens "$CONV")
NAXIS_TOK=$(printf '%s\n' "$CONV_AXIS_TOKENS" | tr ' ' '\n' | grep -c .)

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
NAXIS_ROWS=$(axis_table_data_rows "$CONV" | grep -c .)
NAXIS_ROW_TOK=$(axis_table_data_rows "$CONV" | grep -c 'axis:[a-z]')

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
WF="$ROOT/.github/workflows/tests.yml"
AXIS_ROWS="$SBX/axisrows.txt"
grep -E '^\|' "$CONV" 2>/dev/null > "$AXIS_ROWS"

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
AXIS_JOBS=$(env_axis_jobs "$CONV")
CI_JOBS=$(ci_job_names "$WF")
EXEMPT_JOBS=$(env_exempt_jobs "$CONV")
NAXJOBS=$(printf '%s\n' "$AXIS_JOBS" | tr ' ' '\n' | grep -c .)

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

chk "H1: 축 이름 추출 positive-control(>0)"        "$([ "$NAXES" -gt 0 ] && echo ok || echo no)" "ok"
chk "H2: 선언된 축마다 규약 표 행 실재"            "$(axis_row_miss)" "0"
chk "H3: 축 이름 집합 일치(규약 ↔ discover README)" "$([ -n "$CONV_AXES" ] && [ "$CONV_AXES" = "$READ_AXES" ] && echo yes || echo no)" "yes"
chk "H4: 통제 — 가짜 축 이름(bogus-axis) 규약 부재" "$(has_axis "$CONV_AXES" bogus-axis)" "no"
chk "H5: 통제 — 가짜 축 이름(bogus-axis) README 부재" "$(has_axis "$READ_AXES" bogus-axis)" "no"
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

# (G5~G7 · M42) 규약 문서 집합 **밖**을 가리키는 인용. G1의 대조 집합은 `docs/conventions*.md`의 앵커
# 뿐이라 `skills/*/SKILL.md`·`docs/*.md`를 가리킨 인용은 **어느 가드도 보지 않았다** — 네 사이클 미반영
# (M35-impl 후속3)이고, M41이 그 실례를 하나 찾았다(`skills/impl/SKILL.md`의 절 이름이 인용과 어긋남).
# 일반화의 근거: 인용 골격이 **파일명을 명시**하므로 대조는 **그 파일 자신의 앵커**로 하면 되고, 이름
# **유일성은 규약 집합에만** 유지한다(살아 있는 문서 전체로 넓히면 무관한 문서 간 이름 충돌이 터진다).
# 골격은 G4와 같은 표지(`"…" 절`)를 쓴다 — 표지가 없으면 후보가 평범한 인용부호 산문으로 폭발한다.
# 대상 파일이 레포에 **없으면 대조하지 않는다**(경로 자체가 틀린 경우는 이 파트의 경계 밖 — 규약 고지).
SKEL_UI=$(printf '\354\235\230')        # U+C758 — 인용 골격의 조사(`…`의 "…" 절). ps1은 Uni(0xC758)
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
TAB=$(printf '\t')
extdoc_misses() { # <레코드 파일> → 미해소 인용(사람이 읽을 형태)
    while IFS="$TAB" read -r p a; do
        [ -n "$a" ] || continue
        [ -f "$ROOT/$p" ] || continue
        anchor_set "$ROOT/$p" > "$SBX/extanchors.txt"
        grep -qxF -- "$a" "$SBX/extanchors.txt" </dev/null || printf '%s -> %s\n' "$p" "$a"
    done < "$1"
}
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
circ_list > "$SBX/circ.txt"
NCIRC=$(grep -c . "$SBX/circ.txt")
CIRCBYTES=$(LC_ALL=C wc -c < "$SBX/circ.txt" | tr -d ' ')

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
POS_AXES=$(live_axes)

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
chk "F1b: 파트별 내역 합 == 총계 선언" "$(part_sum)" "$(declared_cases)"

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
DISC_FIX=$(ps1_disc_fixture)
chk "F7: 발견 명세 — 대소문자 구분·숨김 포함·디렉터리 제외" \
    "$(disc_spec "$DISC_FIX")" ".hidden.ps1|a.ps1|c.ps1"
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
chk "J6: 통제 — 발견 명세를 픽스처로 문다(대소문자·숨김·디렉터리)" \
    "$(runner_src_files_in "$(runner_disc_fixture)" | basename_join)" ".hidden.ps1|a.sh|d.ps1"

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
HC_DECL_RE='^<!-- harness-control: .* -->$'
# (M50) 선언 줄 추출을 **한 번만** 한다 — 이전에는 부르는 자리마다 규약 전체를 다시 훑었고,
# 그 자리 하나가 하니스마다 도는 루프 안에 있어 호출 수가 하니스 수에 비례했다. 값은 같다.
LC_ALL=C grep -E "$HC_DECL_RE" "$CONV" > "$SBX/hclines.txt" 2>/dev/null || :
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
HCFIXLIST=$(hc_fixture)
HCFIXN=$(grep -c . "$HCFIXLIST")
HCFIXR=$([ "$(hc_missing "$HCFIXLIST" | grep -c .)" -gt 0 ] && echo caught || echo missed)
chk "K5: 통제 — 토큰이 주석에만 있는 픽스처 하니스를 같은 함수가 잡는다" "$HCFIXN/$HCFIXR" "1/caught"
# (K6) 면제 실재 — 면제 목록이 지목한 이름이 **실재하는 하니스**여야 한다. 하니스 이름이 바뀌거나
# 사라지면 면제가 고아가 되어 그 통제가 아무도 모르게 헐거워진다(Part H의 면제 실재 검사와 같은 층).
chk "K6: 면제 목록이 지목한 하니스 실재(고아 0)" "$(hc_orphan_exempt "$SBX/harnesses.txt" | grep -c .)" "0"

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
chk "L5: 살아 있는 문서 루트 다섯 부류가 전부 나타난다(>0이 아니라 루트마다)" \
    "$(living_roots)/$([ "$NLIVING" -gt 0 ] && echo ok || echo no)" "5/ok"
# (L6) 후보가 0이면 L7이 **0==0으로 조용히 통과**한다 — 추출 자체를 먼저 문다.
chk "L6: 선언+열거 후보 추출 positive-control(>0)" "$([ "$NLCAND" -gt 0 ] && echo ok || echo no)" "ok"
chk "L7: 살아 있는 문서의 선언 수 ↔ 열거 항목 수 불일치 0건" "$NLBAD" "0"
# 픽스처 통제 둘 — **실제 판정을 픽스처에 건다**(픽스처가 조건을 만족하는가가 아니라 판정이 잡는가를
# 묻는 형태. M46 리뷰 차단 #1의 판례). 픽스처 문자열은 **표지에서 파생**시킨다 — 러너 소스에 수사·
# 조사를 리터럴로 적으면 ps1 사본이 ASCII-only 규율을 어기고, 이 사본도 자기 표지를 갖게 된다.
enum_word_for() { printf '%s\n' "$CNT_WORDS" | awk -F= -v v="$1" '$2 + 0 == v { print $1; exit }'; }
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
EPIC_STATUSES=$(markers_of 'epic-status:')
EPIC_MEMBER_MARK=$(markers_of 'epic-members:' | head -1)
EPIC_SINCE=$(markers_of 'epic-since:' | head -1)
NEPICSTAT=$(printf '%s\n' "$EPIC_STATUSES" | grep -c .)
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

# === Part N (M52) — 상태 확인 항목 선언 정합 =============================
# 확인 항목 목록의 선언처를 규약 한 곳으로 만들고 `/tide:status`·`/tide:fleet`이 **읽기만** 하게 한
# 것을 문다. 결함의 형태는 **선언과 사본이 갈리는 것**이었다 — fleet이 여섯을 박아 둔 채 status가
# 여덟로 늘어 fleet의 판단 규칙이 **데이터 없이 조용히 발화하지 못했다**(M52-T01 실측).
#   단일 원본은 `docs/conventions.md`의 "상태 확인 항목과 시작점 판단 (선언)" 절.
#   **소비자 대조에 ASCII 토큰만 쓴다**(`status-items:`·`M{N}-impl.md`) — ps1 사본이 한글 리터럴을
#   가질 수 없으므로 두 사본이 **문자 그대로 같은 술어**를 쓰게 하는 자리다.
NSIABSENT=$(markers_of 'status-items-absent:' | grep -c .)
NSI=$(markers_of 'status-items:' | grep -c .)
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
FLOORTAB=$(floor_marks | tr '\n' '\t')
NFLOOR=$(floor_marks | grep -c .)
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

# --- Part O: 회고 후속 항목의 소비 (M54) -------------------------------------
# 회고가 적은 후속 항목이 다음 사이클에 닿는지를 문다. 무는 것은 **선언의 유일성 · 상태 값의 집합
# 소속 · 소비자의 배선**까지이고, 처분이 타당한가는 리뷰의 영역이다(규약이 같은 경계를 적는다).
RETRO="$ROOT/docs/reports/retro.md"
# **꼬리를 정규화한다** — 앞뒤·중복 공백을 남기면 빈 값 검사에서 ` ` + `` + ` ` 가 선언 줄의
# 선행 공백과 맞아떨어져 **빈 상태 칸이 조용히 통과한다**(실측: O6이 got 0/want 1로 붉었다).
RSTAT=$(decl_tail "$CONV" 'retro-status:' | LC_ALL=C awk '{ $1 = $1; print }')
RBLK=$(decl_tail "$CONV" 'retro-block:' | LC_ALL=C awk '{ print $1 }')
RFIRST=$(printf '%s' "$RSTAT" | LC_ALL=C awk '{ print $1 }')
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
retro_fixture() { # <모드> → 사본 경로 (clean | outset | blank | paren)
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
chk "O11: 복제 금지 - 스킬이 상태 값 집합을 열거하지 않는다" "$([ "$(mst_hits)" -le 1 ] && echo ok || echo no)" "ok"

# --- Part P: 완료 기준 대조 (M55) --------------------------------------------
# 마일스톤이 요구한 것을 impl이 번호로 대조했는가. 무는 것은 **빠짐과 유령**까지이고
# *"충족이 사실인가"* 는 리뷰의 영역이다(규약이 같은 경계를 적는다).
CRITV=$(decl_tail "$CONV" 'criteria-verdict:' | LC_ALL=C awk '{ $1 = $1; print }')
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
CRITUNSET=zzz-criteria-verdict-unset
[ -n "$CRITV" ] || CRITV=$CRITUNSET
CRITOK=$(printf '%s' "$CRITV" | LC_ALL=C awk '{ print $1 }')
CRITALT=$(printf '%s' "$CRITV" | LC_ALL=C awk '{ print $NF }')
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
CRITPAIR=$(printf '%s' "$CRITV" | LC_ALL=C awk '{ for (i = 1; i <= NF; i++) for (j = 1; j <= NF; j++) if (i != j && index($i, $j) > 0) { print $i, $j; exit } }')
CRITSUP=$(printf '%s' "$CRITPAIR" | LC_ALL=C awk '{ print $1 }')
[ -n "$CRITSUP" ] || CRITSUP=$CRITOK
CRITSUB=$(printf '%s' "$CRITPAIR" | LC_ALL=C awk '{ print $NF }')
[ -n "$CRITSUB" ] || CRITSUB=$CRITOK
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
chk "P1: criteria-verdict 선언 줄 정확히 1개" "$(decl_count "$CONV" 'criteria-verdict:')" "1"
chk "P2: criteria-since 선언 줄 정확히 1개" "$(decl_count "$CONV" 'criteria-since:')" "1"
# (P3) 추출 positive-control — 기준 파싱이 망가지면 «집합이 같다»가 «0 == 0»으로 공허 통과한다.
chk "P3: 완료 기준 번호 추출 positive-control(>0)" "$([ "$(crit_seen "$CRITN")" -gt 0 ] && echo ok || echo no)" "ok"
# (P4·P5) **본 검사 둘.** 번호 집합 일치(빠짐 0·유령 0)와 판정 값의 집합 소속.
chk "P4: 본 검사 - 번호 집합이 어긋난 마일스톤 0개" "$(crit_mismatch "$CRITN")" "0"
chk "P5: 본 검사 - 선언 집합 밖 판정 값 0개" "$(crit_bad)" "0"
# 픽스처 통제 — **실제 판정을 픽스처에 건다**(M46 판례). 네 방향을 각각 깬다.
chk "P6: 픽스처 통제 - 행이 빠지면 잡는다" "$(crit_mismatch "$CRITN" "$(crit_fixture drop)")" "1"
chk "P7: 픽스처 통제 - 없는 번호를 적으면 잡는다" "$(crit_mismatch "$CRITN" "$(crit_fixture ghost)")" "1"
chk "P8: 픽스처 통제 - 집합 밖 판정 값을 잡는다" "$(crit_bad "$(crit_fixture outset)")" "1"
chk "P9: 픽스처 통제 - 판정 칸을 비워도 잡는다" "$(crit_bad "$(crit_fixture blank)")" "1"
chk "P10: 음성 통제 - 손대지 않은 사본은 붉지 않는다" "$(crit_mismatch "$CRITN" "$(crit_fixture clean)")" "0"
# (P11) **소급 경계가 실제로 거르는가.** 시작 번호를 1로 낮추면 이 절이 없던 시절의 보고서가
# 대상에 들어와 어긋난다 — 경계가 장식이 아니라는 것을 이 케이스가 확인한다.
chk "P11: 경계 통제 - 시작 번호를 1로 낮추면 어긋난다(>0)" "$([ "$(crit_mismatch 1)" -gt 0 ] && echo ok || echo no)" "ok"
# (P12) **오탐 방향.** 집합 안 다른 값으로 바꾸는 것은 정상이다 — 여기서 붉으면 과하게 무는 것이다.
chk "P12: 오탐 방향 - 집합 안 다른 값은 통과" "$(crit_bad "$(crit_fixture swap)")" "0"
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

chk "F1: README cases 선언 == 실제 케이스 수" "$(declared_cases)" "$((pass + fail + 1))"

echo
echo "# 결과: PASS=$pass FAIL=$fail (실제 커맨드 스킬 N=$N)"
[ "$fail" -eq 0 ] || exit 1
echo "# discover 감지 임계값(≥2→hint·<2→none·단일 레포→none·숨김 미카운트) + 단일 원본 동결(B1 카운트 정합·B2 사이트 셸·B3 카탈로그 완전성, 캐노니컬=docs/commands.md, 실제 ${N}종) + 선언 정합(C1 상태값 네 값×세 파일·부재 통제·C2 기준선×세 템플릿·C3 phase 명단 기록·비기록 두 목록의 규약↔발행 페이지 집합 일치·유일 열거처·서로소·음성 통제·D 브랜치 협업 안전 커버리지(커밋 diff·미커밋 범위 두 토큰 — 규약↔스킬↔캐노니컬 카탈로그)·번호경고 규약↔스킬 정합·PR CI 확인 규약조각↔스킬 정합·E 리뷰 검증 규율 반증 시도·판정 계측·재작업 라운드 규약↔스킬↔템플릿 정합 + 계측 줄 골격 형식 정합 + 재검증 선언 + 교차·음성 통제 · F 문서 자기서술 정합 = 역할 앵커 추출·캐노니컬 행 실재·소비자 전파 + 케이스 수 자기 정합 · G 상호참조 무결성 = 인용 추출·앵커 실재 대조 + 추출 0건·이름 유일성·줄바꿈 인용 통제 + 규약 집합 밖 대상 인용의 파일별 앵커 대조(골격 조사 요구·주입 통제 — 대상 파일 부재는 경계 밖) · I 축 상태 주장 정합 = 표가 집행된다고 적은 축을 산문이 반대로 적는 자리(표지는 규약이 단일 선언처, 창=불릿 블록, 인용·이력 서술·무대상 세 통제 — 축 이름이 아닌 대상의 모순과 반대 방향은 경계 밖) · H 실행 환경 축 선언 정합 = 축 이름 추출·규약 표 행 실재·집합 일치·표의 job: 토큰이 가리킨 잡의 워크플로 실재와 선언 축 행 소속(고아 0)·커버리지(실재 잡의 등재 또는 면제 선언)·면제 선언의 실재·무토큰 축 통제·axis: 표기 양방향 정합·데이터 행 수 대조·음성 통제 — 잡을 지목하지 않는 집행 칸과 잡을 지목한 칸의 나머지 서술은 사람의 리뷰 영역이라 여기서 묻지 않음) 확인됨 (참조 구현 기준)"

# --- 뮤테이션 선언 (M47) — `tests/mutation`이 읽는다 -------------------------
# 형식: `# mutates: <파일> :: <토큰> :: <케이스 라벨 안정 접두> :: <caught|missed>`
# 토큰은 **영숫자·하이픈만** 쓴다(치환 구분자 충돌 방지). 라벨은 보간(`$`) 앞까지의 안정 접두이며
# 이 사본의 라벨 161개 안에서 유일하다(M47-T01 실측). ps1 사본은 자기 언어의 라벨로 같은 선언을 둔다.
# mutates: docs/conventions.md :: declared-change-set :: D7: conventions :: caught
# mutates: docs/conventions.md :: mutation-negative-control-sentinel :: D7: conventions :: missed
