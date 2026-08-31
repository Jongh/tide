#!/bin/sh
# tide site-include resolution live test (POSIX / Git Bash)
#
# Verifies, WITHOUT invoking mkdocs, that the MkDocs snippet includes in the site
# shells actually resolve: include target exists, the referenced section marker pair
# is balanced (exactly one start/end, start before end), and the marker-delimited body
# region (what becomes site content) carries ZERO excluded terms. This is a deterministic
# static proxy for the release-preflight "build-output excluded-term 0" manual scan, so
# the local blind spot (snippet target/marker/term-leak) is closed without a full build.
#
# SCOPE BOUNDARY (important): this harness is NOT a substitute for `mkdocs build --strict`.
# It checks include-target resolution + section-marker balance + a static excluded-term
# guard only. Real render / nav / link breakage / mkdocs-config regression stays CI's job
# (.github/workflows/deploy-pages.yml). It also does NOT duplicate `tests/discover` Part B2
# (which only checks that a site page IS a snippet shell) -- T02 goes further by resolving
# the include targets/section markers and scanning the body region for excluded terms.
#
# Excluded-term single source: the term list is NOT hardcoded here (which would itself leak
# it into the source / drift from the convention). Per `docs/conventions.md` ("meta-term
# leak prevention" / "release build-output verification"), the excluded term is the external
# attribution kept OUT of the snippet body. We derive it from the masthead intro region that
# lives OUTSIDE the body markers (README.md / docs/conventions.md line-3 "<TERM>... methodology"
# pattern) -- pulling the rule from the convention's intent, self-updating, no duplicated list.
# A positive-control then re-confirms each derived term LITERALLY occurs in that masthead
# region -- otherwise a mis-extracted token (absent from the body) would pass the term scan
# vacuously (green for the wrong reason); this proves the scanner handles a REAL string.
#
# Usage: sh tests/site-includes/run.sh   (exit 0 if all pass, exit 1 if any fail)

set -u

# Repo root resolved from the script location (tests/fleet|discover convention).
ROOT=$(cd "$(dirname "$0")/../.." && pwd)

pass=0; fail=0
chk() { # <desc> <got> <want>
    if [ "$2" = "$3" ]; then pass=$((pass + 1)); printf 'PASS  %-60s (%s)\n' "$1" "$2"
    else fail=$((fail + 1)); printf 'FAIL  %-60s (got %s, want %s)\n' "$1" "$2" "$3"; fi
}

# --- sandbox (M57 — 워크플로 픽스처를 여기에 만든다) ---------------------------
SBX="${TMPDIR:-/tmp}/tide-site-includes-live.$$"
rm -rf "$SBX"; mkdir -p "$SBX"
trap 'rm -rf "$SBX"' EXIT

# --- derive the excluded term(s) from the masthead intro (outside body markers) --
# 도출은 **`tests/lib/excluded-terms.sh` 하나**가 한다(M57). 그 전에는 이 파일이 자기 구현을
# 가졌고, CI가 같은 도출을 하려면 **세 번째 구현**이 생길 참이었다 — 한쪽이 조용히 낡는 그
# 부류가 이 사이클이 무는 것 자체다. `.ps1` 사본은 두 사본 계약대로 자기 구현을 갖는다
# (sh 쪽은 소비자가 둘 — 이 러너와 워크플로 — 이고 ps1 쪽은 하나라 모을 대상이 없다).
. "$ROOT/tests/lib/excluded-terms.sh"

TERMS=$(excluded_terms "$ROOT" | tr '\n' ' ' | sed 's/ *$//')
MASTHEAD=$(excluded_masthead "$ROOT")

# Sanity: we must have derived at least one excluded term, else the term scan is vacuous.
chk "term: derived >=1 excluded term from masthead intro" "$([ -n "$TERMS" ] && echo ok || echo no)" "ok"

# Positive-control: each derived term must LITERALLY occur in the masthead region it was
# extracted from. If a derived term is absent there, extraction fabricated / mis-extracted a
# token -- which would never appear in the body, making the term scan pass VACUOUSLY (green
# for the wrong reason). This proves the scanner handles a REAL string. Handles >1 token.
ctrl_missing=0
for term in $TERMS; do
    n=$(printf '%s\n' "$MASTHEAD" | grep -cF "$term")
    [ "$n" -ge 1 ] || ctrl_missing=$((ctrl_missing + 1))
done
chk "term: each derived term literally present in masthead region" "$ctrl_missing" "0"

# --- enumerate snippet shells and their include directives --------------------
# An include line looks like:  --8<-- "<target>:<section>"
# A "snippet shell" = a site/docs/*.md that has >=1 such include. Discover by scanning
# (do not hardcode the 4) so new shells are caught. The hand-written pages
# (index/concepts/getting-started) have 0 includes and are simply not shells.
INCLUDE_RE='--8<--[[:space:]]*"[^"]*:[^"]*"'

shells=0          # site pages that are shells
includes_total=0  # total include directives across all shells

for page in "$ROOT"/site/docs/*.md; do
    [ -f "$page" ] || continue
    pname=$(basename "$page")
    lines=$(grep -oE -e "$INCLUDE_RE" "$page" 2>/dev/null)
    [ -n "$lines" ] || continue   # not a shell (0 includes) -> skip (hand-written page)
    shells=$((shells + 1))

    ninc=$(printf '%s\n' "$lines" | grep -c .)
    chk "shell $pname: include count >=1" "$([ "$ninc" -ge 1 ] && echo ok || echo no)" "ok"

    # iterate each include via a here-string-free temp (POSIX): use a tmpfile of specs
    specs=$(printf '%s\n' "$lines" | sed -n 's/.*"\([^"]*\)".*/\1/p')
    oldifs=$IFS; IFS='
'
    for spec in $specs; do
        IFS=$oldifs
        includes_total=$((includes_total + 1))
        target=${spec%%:*}
        section=${spec#*:}
        tfile="$ROOT/$target"
        label="$target:$section"

        # (2a) target file exists (path is repo-root-relative)
        if [ -f "$tfile" ]; then texists=ok; else texists=no; fi
        chk "shell $pname -> $label: target file exists" "$texists" "ok"

        # (2b/3) exactly one balanced marker pair for <section> in target.
        # Match the FULL pymdownx snippets marker "--8<-- [start:<section>]" (inside an
        # HTML comment), not just the "[start:<section>]" substring -- the latter also
        # appears in explanatory comments / prose, which are not real markers. The
        # "--8<-- " prefix is what distinguishes a real section marker from a mention.
        # (grep -e is required because the pattern begins with "--".)
        if [ -f "$tfile" ]; then
            ns=$(grep -cF -e "--8<-- [start:$section]" "$tfile")
            ne=$(grep -cF -e "--8<-- [end:$section]" "$tfile")
            ls=$(grep -nF -e "--8<-- [start:$section]" "$tfile" | head -1 | cut -d: -f1)
            le=$(grep -nF -e "--8<-- [end:$section]" "$tfile" | head -1 | cut -d: -f1)
        else
            ns=0; ne=0; ls=; le=
        fi
        chk "target $label: start marker count == 1" "$ns" "1"
        chk "target $label: end marker count == 1"   "$ne" "1"
        balanced=bad
        if [ "$ns" = "1" ] && [ "$ne" = "1" ] && [ -n "$ls" ] && [ -n "$le" ] && [ "$ls" -lt "$le" ]; then
            balanced=ok
        fi
        chk "target $label: balanced pair (start before end)" "$balanced" "ok"

        # (4) excluded-term scan inside the marker-delimited body region
        leak=0
        if [ "$balanced" = ok ]; then
            body=$(sed -n "$((ls + 1)),$((le - 1))p" "$tfile")
            for term in $TERMS; do
                n=$(printf '%s\n' "$body" | grep -cF "$term")
                leak=$((leak + n))
            done
        fi
        chk "body $label: excluded-term occurrences == 0" "$leak" "0"
        IFS='
'
    done
    IFS=$oldifs
done

# At least one shell must exist (the site is snippet-driven); 0 shells = drift.
chk "site: discovered >=1 snippet shell" "$([ "$shells" -ge 1 ] && echo ok || echo no)" "ok"
chk "site: discovered >=1 include directive" "$([ "$includes_total" -ge 1 ] && echo ok || echo no)" "ok"

# === case-count self-consistency (M38-T01) ==============================
# The completion guard (M37) catches a runner that ABORTS; it does not catch one that stays alive
# and RUNS LESS -- and this harness is DISCOVERY-DRIVEN (shells x include targets), so "found
# fewer shells than last time" is exactly the silent shrink it must not survive. The expected
# case count has a single declaration site -- this harness's README (convention: the document
# self-description section of docs/conventions.md) -- never hardcoded here. If the declaration
# cannot be read (file missing / no `cases` token) the extraction is empty and this FAILS:
# "could not read it, so skip the check and pass" is the very class this kills.
# The case is itself a case, so it goes LAST and compares running-total + 1 (same shape as
# tests/discover F1; identical assertion name and verdict in both shells).
HARNESS_README="$ROOT/tests/site-includes/README.md"
declared_cases() {
    # **첫 매치 고정** — sed의 선행 `.*`는 탐욕이라 한 줄에 `cases:`가 둘이면 **마지막**을 집는데
    # ps1의 `[regex]::Match`는 **첫 번째**를 집는다(M38 리뷰 사소 4의 실측: 같은 입력에 sed 7 ↔
    # .NET 42). `grep -o`는 매치를 파일·줄 순서대로 내므로 `head -1`이 곧 첫 매치다 — 양 셸 동형.
    grep -o 'cases:[^0-9]*[0-9][0-9]*' "$HARNESS_README" 2>/dev/null | head -1 |
        grep -o '[0-9][0-9]*' | head -1
}
# --- CI build-output scan wiring (M57) ---------------------------------------
# 규약이 「분담해서 집행한다」고 적은 것 중 **빌드 산출물의 제외 용어**를 무는 것은 CI의 스캔
# 스텝뿐이다(①은 사람 손·②는 렌더·③은 이 하니스가 보는 소스). 그 스텝이 조용히 사라지거나
# **업로드 뒤로 밀리면** 게이트가 아니게 되는데, 오늘까지는 그래도 아무것도 붉지 않았다.
# 여기서 무는 것은 **배선**이다 — 스텝이 실재하는가와 순서가 맞는가. 스텝 이름이 아니라
# **도출 단일 원본을 읽는다는 사실**로 찾는다(이름은 바뀔 수 있고, 읽는 파일은 계약이다).
PAGES_WF="$ROOT/.github/workflows/deploy-pages.yml"
SCAN_REF="tests/lib/excluded-terms.sh"
UPLOAD_REF="upload-pages-artifact"

wf_line() { # <파일> <토큰> → 그 토큰이 **주석이 아닌 줄**에 처음 나온 줄 번호 (없으면 0)
    # **주석은 배선이 아니다**(적대 축 `adv-scan-commented`가 연 자리 — 스캔 줄을 주석 처리해도
    # 토큰이 남아 41/0 초록이었다). 토큰을 **말하는** 줄과 **쓰는** 줄을 가른다. YAML의 `run: |`
    # 블록 안에서도 선두 `#`는 셸 주석이라 그 줄은 실행되지 않는다 — 같은 규칙이 양쪽에 통한다.
    [ -f "$1" ] || { echo 0; return; }
    LC_ALL=C grep -nF -- "$2" "$1" 2>/dev/null         | LC_ALL=C awk -F: '{ rest = substr($0, index($0, ":") + 1); sub(/^[ 	]+/, "", rest); if (substr(rest, 1, 1) != "#") { print $1; exit } }'         | grep . || echo 0
}
wf_order() { # <파일> → 스캔이 업로드보다 앞이면 ok (둘 중 하나라도 없으면 no)
    _ws=$(wf_line "$1" "$SCAN_REF"); _wu=$(wf_line "$1" "$UPLOAD_REF")
    if [ "$_ws" -le 0 ] || [ "$_wu" -le 0 ]; then echo no; return; fi
    [ "$_ws" -lt "$_wu" ] && echo ok || echo no
}
wf_fixture() { # <모드> → 워크플로 사본 (drop: 스캔 삭제 · after: 업로드 뒤로 · noise: 무관한 스텝)
    _wf="$SBX/pages-$1.yml"
    LC_ALL=C awk -v mode="$1" -v scan="$SCAN_REF" -v up="$UPLOAD_REF" '
        index($0, scan) > 0 {
            if (mode == "drop") next
            if (mode == "after") { held = $0; next }
        }
        index($0, up) > 0 && mode == "after" && held != "" { print; print held; held = ""; next }
        { print }
        END { if (mode == "noise") print "      - run: echo zzz-unrelated-step" }
    ' "$PAGES_WF" > "$_wf"
    printf '%s' "$_wf"
}
chk "ci-scan: workflow reads the excluded-term single source" "$([ "$(wf_line "$PAGES_WF" "$SCAN_REF")" -gt 0 ] && echo ok || echo no)" "ok"
chk "ci-scan: the scan sits BEFORE the artifact upload" "$(wf_order "$PAGES_WF")" "ok"
# 픽스처 통제 — **실제 판정을 사본에 건다**(M46 판례). 두 방향을 각각 깬다.
chk "ci-scan: control -- removing the scan step is caught" "$(wf_order "$(wf_fixture drop)")" "no"
chk "ci-scan: control -- moving it after the upload is caught" "$(wf_order "$(wf_fixture after)")" "no"
# 오탐 방향 — 무관한 스텝이 늘어도 배선은 그대로다. 여기서 붉으면 과하게 무는 것이다.
chk "ci-scan: false-positive direction -- an unrelated step passes" "$(wf_order "$(wf_fixture noise)")" "ok"
# 워크플로에 제외 용어를 하드코딩하면 그 자리가 **두 번째 선언처**가 되고 소스에 용어가 남는다.
# **`grep -i`와 `-F`를 함께 쓰지 않는다(실측 — 이 자리가 데였다)**: Git Bash의 GNU grep 3.0은 그
# 조합에서 **크래시**한다(`-i` 단독·`-F` 단독은 정상, 파일과 무관). 크래시하면 출력이 비고, 앞선
# 판본은 `|| echo 0`으로 그것을 **0으로 받아** 케이스가 **공허하게 초록**이었다 — 검사가 죽은 것을
# 검사가 통과로 읽는 형태다. 양쪽을 소문자로 낮춘 뒤 `-F`만 쓰고, **빈 출력은 크게 붉힌다**.
wf_lower() { LC_ALL=C tr '[:upper:]' '[:lower:]'; }
wf_literal=0
for term in $TERMS; do
    _wl=$(wf_lower < "$PAGES_WF" | LC_ALL=C grep -cF -- "$(printf '%s' "$term" | wf_lower)")
    # 출력이 비면 세는 도구가 죽은 것이다 — 0으로 받지 않는다(그것이 공허 통과의 경로였다).
    [ -n "$_wl" ] || _wl=999
    wf_literal=$((wf_literal + _wl))
done
chk "ci-scan: no excluded-term literal in the workflow" "$wf_literal" "0"

# --- 워크플로 블록 스칼라 무결성 (M57 impl 실측이 연 자리) --------------------
# `run: |` 블록 안에서 명령 인자에 **개행을 리터럴로** 쓰면 그 줄이 **열 0**에서 시작해야 하고,
# 그러면 블록 스칼라가 거기서 끊겨 **워크플로 전체가 YAML로 파싱되지 않는다.** 그 상태가 실제로
# 한 번 트리에 들어왔는데 위 배선 케이스 여섯은 **전부 초록이었다** — «스텝이 있고 업로드보다
# 앞이다»는 참인데 워크플로가 뜨지 않으므로 게이트는 **없다**. 이 사이클이 무는 부류 그 자체다.
# 네 실행 환경 어디에도 YAML 파서를 요구할 수 없으므로 **열 0 규율**을 대신 문다: 열 0의 비어
# 있지 않은 줄은 **최상위 키**이거나 **주석**뿐이다.
wf_col0_bad() { # <파일> → 열 0의 비어 있지 않은 줄 중 최상위 키·주석이 아닌 줄 수
    [ -f "$1" ] || { echo 999; return; }
    LC_ALL=C awk -v cr="$(printf '\r')" '
        { s = $0; if (length(s) > 0 && substr(s, length(s), 1) == cr) s = substr(s, 1, length(s) - 1) }
        s == "" { next }
        substr(s, 1, 1) == " " { next }
        substr(s, 1, 1) == "\t" { next }
        substr(s, 1, 1) == "#" { next }
        s ~ /^[A-Za-z_][A-Za-z0-9_.-]*:/ { next }
        { n++ }
        END { print n + 0 }
    ' "$1"
}
wf_col0_keys() { # <파일> → 최상위 키 줄 수 (추출 positive-control — 0이면 검사가 공허하다)
    [ -f "$1" ] || { echo 0; return; }
    LC_ALL=C awk -v cr="$(printf '\r')" '
        { s = $0; if (length(s) > 0 && substr(s, length(s), 1) == cr) s = substr(s, 1, length(s) - 1) }
        s ~ /^[A-Za-z_][A-Za-z0-9_.-]*:/ { n++ }
        END { print n + 0 }
    ' "$1"
}
wf_col0_total() { # → 워크플로 전부의 위반 합
    _wct=0
    for _wcf in "$ROOT"/.github/workflows/*.yml; do
        [ -f "$_wcf" ] || continue
        _wct=$((_wct + $(wf_col0_bad "$_wcf")))
    done
    echo "$_wct"
}
wf_key_total() { # → 워크플로 전부의 최상위 키 줄 합
    _wkt=0
    for _wcf in "$ROOT"/.github/workflows/*.yml; do
        [ -f "$_wcf" ] || continue
        _wkt=$((_wkt + $(wf_col0_keys "$_wcf")))
    done
    echo "$_wkt"
}
wf_yaml_fixture() { # <모드> → 사본 (break: run 블록 안에 열 0 줄 · addkey: 최상위 키 하나 더)
    _wyf="$SBX/pages-yaml-$1.yml"
    LC_ALL=C awk -v mode="$1" '
        { print }
        mode == "break" && hit == 0 && index($0, "run: |") > 0 { print "zzz-broken-continuation"; hit = 1 }
        END { if (mode == "addkey") print "zzz-extra-key: 1" }
    ' "$PAGES_WF" > "$_wyf"
    printf '%s' "$_wyf"
}
chk "wf-yaml: top-level key extraction positive-control(>0)" "$([ "$(wf_key_total)" -gt 0 ] && echo ok || echo no)" "ok"
chk "wf-yaml: no column-0 line outside the YAML top level" "$(wf_col0_total)" "0"
# 픽스처 통제 — **실제 판정을 사본에 건다**(M46 판례). 끊긴 블록이 실제로 붉는지 확인한다.
chk "wf-yaml: control -- a column-0 continuation is caught" "$(wf_col0_bad "$(wf_yaml_fixture break)")" "1"
# 오탐 방향 — 최상위 키가 늘어도 초록이다. 여기서 붉으면 정상 워크플로를 무는 것이다.
chk "wf-yaml: false-positive direction -- a new top-level key passes" "$(wf_col0_bad "$(wf_yaml_fixture addkey)")" "0"

chk "case-count: README cases declaration == actual" "$(declared_cases)" "$((pass + fail + 1))"

echo
echo "# result: PASS=$pass FAIL=$fail (shells=$shells includes=$includes_total terms=[$TERMS])"
[ "$fail" -eq 0 ] || exit 1
echo "# site-include resolution (target exists + balanced [start]/[end] marker pair + excluded-term 0 in body + derived terms real in masthead) confirmed -- NOT a mkdocs --strict substitute (render/nav/link = CI)"
