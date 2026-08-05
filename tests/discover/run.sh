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
    grep -F -- "phase" "$1" | grep -F -- "milestone" | grep -F -- "impl"       | grep -F -- "review" | grep -F -- "release" | grep -F -- "debug"       | grep -F -- "cycle" | head -1
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

# 교차 통제 — 각 메커니즘은 반대 스킬에 없어야 한다(토큰 구별력: 커버리지=release, 경고=milestone).
chk "D: 통제 — milestone SKILL 에 커버리지 토큰 없음" "$(has_token "$MS_SKILL" "$COV_TOK")" "no"
chk "D: 통제 — milestone SKILL 에 미커밋 범위 토큰 없음" "$(has_token "$MS_SKILL" "$UNCOMMITTED_TOK")" "no"
chk "D: 통제 — release SKILL 에 번호경고 토큰 없음"   "$(has_token "$REL_SKILL" "$WARN_TOK")" "no"
chk "D: 통제 — milestone SKILL 에 PR CI 토큰 없음"   "$(has_token "$MS_SKILL" "$PRCI_TOK")" "no"

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

# 음성 통제 — 가짜 판례 토큰은 규약에 없어야 한다(E의 `refutation-bogus` 통제와 동형, 구별력 입증).
chk "E: 통제 — conventions에 가짜 판례 토큰 없음" "$(has_token "$CONV" "${VACUOUS_TOK}-bogus")" "no"

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

# (F1) 마지막 케이스 — 자기 README 선언(`cases: N`)과 실제 케이스 수(누계 + 이 케이스) 대조.
chk "F1: README cases 선언 == 실제 케이스 수" "$(declared_cases)" "$((pass + fail + 1))"

echo
echo "# 결과: PASS=$pass FAIL=$fail (실제 커맨드 스킬 N=$N)"
[ "$fail" -eq 0 ] || exit 1
echo "# discover 감지 임계값(≥2→hint·<2→none·단일 레포→none·숨김 미카운트) + 단일 원본 동결(B1 카운트 정합·B2 사이트 셸·B3 카탈로그 완전성, 캐노니컬=docs/commands.md, 실제 ${N}종) + 선언 정합(C1 상태값 네 값×세 파일·부재 통제·C2 기준선×세 템플릿·C3 phase 명단 기록·비기록 두 목록의 규약↔발행 페이지 집합 일치·유일 열거처·서로소·음성 통제·D 브랜치 협업 안전 커버리지(커밋 diff·미커밋 범위 두 토큰 — 규약↔스킬↔캐노니컬 카탈로그)·번호경고 규약↔스킬 정합·PR CI 확인 규약조각↔스킬 정합·E 리뷰 검증 규율 반증 시도·판정 계측·재작업 라운드 규약↔스킬↔템플릿 정합 + 계측 줄 골격 형식 정합 + 재검증 선언 + 교차·음성 통제 · F 문서 자기서술 정합 = 역할 앵커 추출·캐노니컬 행 실재·소비자 전파 + 케이스 수 자기 정합 · G 상호참조 무결성 = 인용 추출·앵커 실재 대조 + 추출 0건·이름 유일성·줄바꿈 인용 통제 · H 실행 환경 축 선언 정합 = 축 이름 추출·규약 표 행 실재·집합 일치·표의 job: 토큰이 가리킨 잡의 워크플로 실재와 선언 축 행 소속(고아 0)·커버리지(실재 잡의 등재 또는 면제 선언)·면제 선언의 실재·무토큰 축 통제·axis: 표기 양방향 정합·데이터 행 수 대조·음성 통제 — 잡을 지목하지 않는 집행 칸과 잡을 지목한 칸의 나머지 서술은 사람의 리뷰 영역이라 여기서 묻지 않음) 확인됨 (참조 구현 기준)"
