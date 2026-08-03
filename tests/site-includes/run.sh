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

# --- derive the excluded term(s) from the masthead intro (outside body markers) --
# The external attribution sits in the line-3 intro of README/conventions, in the form
# "<TERM>... <KO_METHODOLOGY>". That intro is deliberately kept OUTSIDE [start:body], so
# the term must never appear inside the body region. We extract the word immediately
# before the Korean "methodology" phrase. The KO phrase is built from its UTF-8 bytes so
# the source carries no hardcoded excluded term (parity with the ASCII-only .ps1 twin).
# 팔진(`\357`류)으로 쓴다 — `\xHH`는 POSIX printf에 없어 dash가 글자 그대로 내보낸다. 지금까지
# 우분투에서도 통과한 것은 dash가 남긴 `\xec…` 글자를 **GNU sed가 정규식에서 다시 이스케이프로
# 해석**해 준 우연이다(비-GNU sed에서는 깨진다). 팔진이면 여기서 실제 바이트가 만들어져 sed는
# 리터럴만 보면 된다 — 셸·sed 구현 어느 쪽에도 기대지 않는다.
ko_methodology=$(printf '\354\235\230 \352\260\234\353\260\234 \353\260\251\353\262\225\353\241\240')  # "<eui> <gaebal> <bangbeomnon>"

extract_term() { # <file> -> term word (or empty)
    [ -f "$1" ] || return
    # token (ASCII word) immediately preceding the KO methodology phrase
    sed -n "s/.*[ \\t([]\\([A-Za-z][A-Za-z0-9_-]*\\)${ko_methodology}.*/\\1/p; s/^\\([A-Za-z][A-Za-z0-9_-]*\\)${ko_methodology}.*/\\1/p" "$1" | head -1
}

# The masthead intro is line 3 of each source (the line we extract the term from).
# We keep that exact source region so a positive-control can re-confirm the derived
# term LITERALLY occurs in it (not a fabricated / mis-extracted token).
masthead_region() { # <file> -> the masthead intro line (line 3), or empty
    [ -f "$1" ] || return
    sed -n '3p' "$1"
}

# Collect excluded terms (dedup) from the two masthead sources, remembering for each
# derived term the masthead source region it was extracted from (for the positive-control).
TERMS=""
MASTHEAD=""   # accumulated masthead intro text across the scanned sources
for src in "$ROOT/README.md" "$ROOT/docs/conventions.md"; do
    t=$(extract_term "$src")
    [ -n "$t" ] || continue
    MASTHEAD="$MASTHEAD
$(masthead_region "$src")"
    case " $TERMS " in *" $t "*) : ;; *) TERMS="$TERMS $t" ;; esac
done
TERMS=$(echo "$TERMS" | sed 's/^ *//; s/ *$//')

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

echo
echo "# result: PASS=$pass FAIL=$fail (shells=$shells includes=$includes_total terms=[$TERMS])"
[ "$fail" -eq 0 ] || exit 1
echo "# site-include resolution (target exists + balanced [start]/[end] marker pair + excluded-term 0 in body + derived terms real in masthead) confirmed -- NOT a mkdocs --strict substitute (render/nav/link = CI)"
