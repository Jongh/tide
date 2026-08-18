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
selfref_of() { # <file> → 그 파일의 자기참조 구획(공백·CR 제거, 한 줄에 하나)
    awk -v J="$SELFREF_JEOL" -v BASES="$SBX/convbases.txt" '
        BEGIN { while ((getline b < BASES) > 0) if (b != "") BASE[++NB] = b }
        function hasbase(s,   i) { for (i = 1; i <= NB; i++) if (index(s, BASE[i])) return 1; return 0 }
        {
            cur = $0
            skip = 0
            if (cur ~ /`[A-Za-z0-9_.\/-]+\.(md|sh|ps1|json|yml)`/) skip = 1
            else if (hasbase(cur)) skip = 1
            else if (hasbase(prev)) skip = 1
            if (!skip) {
                line = cur
                pat = "\"[^\"]*\"[ \t]*" J
                while (match(line, pat)) {
                    m = substr(line, RSTART, RLENGTH)
                    rest = substr(m, 2)
                    q = index(rest, "\"")
                    if (q > 1) print substr(rest, 1, q - 1)
                    line = substr(line, RSTART + RLENGTH)
                }
            }
            prev = cur
        }' "$1" | grep -v '[{}]' | tr -d ' \r' | grep -v '^$'
}
# `--`와 `</dev/null`은 G1과 같은 이유로 둘 다 필요하다(이름이 `-`로 시작하면 grep이 옵션으로 읽고
# stdin을 삼켜 나머지가 통째로 미검사로 남는다).
# 실패하면 **어느 파일의 무엇이 안 풀렸는지 이름을 출력한다**(M40의 자기고발 조치와 같은 취지).
# 진단 문구가 **두 가지를 함께 말한다** — 해소되지 않는 자기참조이거나, 파일명이 두 줄 이상 앞에
# 있는 끊긴 인용이다(위 ⑷ 참조). 어느 쪽인지는 사람이 그 줄과 앞 줄들을 보고 가르며, 어느 쪽이든
# 고칠 것이 있다. 한쪽 이름만 찍으면 원인을 잘못 지목하게 된다.
: > "$SBX/selfrefs.txt"
SELF_MISS=0
while IFS= read -r lf; do
    [ -f "$lf" ] || continue
    anchor_set "$lf" > "$SBX/ownanchors.txt"
    selfref_of "$lf" > "$SBX/ownrefs.txt"
    cat "$SBX/ownrefs.txt" >> "$SBX/selfrefs.txt"
    while IFS= read -r s; do
        [ -n "$s" ] || continue
        grep -qxF -- "$s" "$SBX/ownanchors.txt" </dev/null || {
            SELF_MISS=$((SELF_MISS + 1))
            printf '  ↳ 미해소 자기참조 또는 끊긴 인용: %s → %s\n' "${lf#"$ROOT"/}" "$s"
        }
    done < "$SBX/ownrefs.txt"
done < "$SBX/living.txt"
NSELF=$(grep -c . "$SBX/selfrefs.txt")
selfref_has() { grep -qxF -- "$1" "$SBX/selfrefs.txt" </dev/null && echo yes || echo no; }

chk "G4: 자기참조가 전부 자기 파일 앵커를 가리킴"   "$SELF_MISS" "0"
chk "G4: 자기참조 추출 positive-control(>0)"        "$([ "$NSELF" -gt 0 ] && echo ok || echo no)" "ok"
chk "G4: 통제 — 가짜 이름(bogus-section) 자기참조 부재" "$(selfref_has 'bogus-section')" "no"

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
disc_spec() { # <dir> → 정렬된 basename을 |로 이어 붙인 한 줄
    ps1_files_in "$1" | sed 's|.*/||' | LC_ALL=C sort |
        awk '{ s = (NR == 1 ? $0 : s "|" $0) } END { print s }'
}
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

# (F1) 마지막 케이스 — 자기 README 선언(`cases: N`)과 실제 케이스 수(누계 + 이 케이스) 대조.
chk "F1: README cases 선언 == 실제 케이스 수" "$(declared_cases)" "$((pass + fail + 1))"

echo
echo "# 결과: PASS=$pass FAIL=$fail (실제 커맨드 스킬 N=$N)"
[ "$fail" -eq 0 ] || exit 1
echo "# discover 감지 임계값(≥2→hint·<2→none·단일 레포→none·숨김 미카운트) + 단일 원본 동결(B1 카운트 정합·B2 사이트 셸·B3 카탈로그 완전성, 캐노니컬=docs/commands.md, 실제 ${N}종) + 선언 정합(C1 상태값 네 값×세 파일·부재 통제·C2 기준선×세 템플릿·C3 phase 명단 기록·비기록 두 목록의 규약↔발행 페이지 집합 일치·유일 열거처·서로소·음성 통제·D 브랜치 협업 안전 커버리지(커밋 diff·미커밋 범위 두 토큰 — 규약↔스킬↔캐노니컬 카탈로그)·번호경고 규약↔스킬 정합·PR CI 확인 규약조각↔스킬 정합·E 리뷰 검증 규율 반증 시도·판정 계측·재작업 라운드 규약↔스킬↔템플릿 정합 + 계측 줄 골격 형식 정합 + 재검증 선언 + 교차·음성 통제 · F 문서 자기서술 정합 = 역할 앵커 추출·캐노니컬 행 실재·소비자 전파 + 케이스 수 자기 정합 · G 상호참조 무결성 = 인용 추출·앵커 실재 대조 + 추출 0건·이름 유일성·줄바꿈 인용 통제 + 규약 집합 밖 대상 인용의 파일별 앵커 대조(골격 조사 요구·주입 통제 — 대상 파일 부재는 경계 밖) · I 축 상태 주장 정합 = 표가 집행된다고 적은 축을 산문이 반대로 적는 자리(표지는 규약이 단일 선언처, 창=불릿 블록, 인용·이력 서술·무대상 세 통제 — 축 이름이 아닌 대상의 모순과 반대 방향은 경계 밖) · H 실행 환경 축 선언 정합 = 축 이름 추출·규약 표 행 실재·집합 일치·표의 job: 토큰이 가리킨 잡의 워크플로 실재와 선언 축 행 소속(고아 0)·커버리지(실재 잡의 등재 또는 면제 선언)·면제 선언의 실재·무토큰 축 통제·axis: 표기 양방향 정합·데이터 행 수 대조·음성 통제 — 잡을 지목하지 않는 집행 칸과 잡을 지목한 칸의 나머지 서술은 사람의 리뷰 영역이라 여기서 묻지 않음) 확인됨 (참조 구현 기준)"
