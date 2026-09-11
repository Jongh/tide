#!/bin/sh
# tests/mutation — 케이스가 자기 대상을 실제로 무는지 기계가 확인한다 (M47)
#
# 무엇을 하는가: 대상 러너(`tests/discover/run.sh`)에 적힌 `# mutates:` 선언마다
#   ⑴ 트리를 사본으로 뜨고 ⑵ 선언이 지목한 **파일의 토큰을 깨고** ⑶ 대상 하니스를 돌려
#   ⑷ 선언이 지목한 **케이스가 FAIL 목록에 나타나는지**를 본다.
# 나타나지 않으면 그 케이스는 **동어반복**이다 — 판정을 망가뜨렸는데 붉어지지 않는 통제는
# 통제가 아니다(규약 "차단 등급 판례" 절의 M47 일반화).
#
# 왜 이 형태인가(M47-T01 실측):
#   - **접두 식별자로는 매칭할 수 없다** — discover 172 케이스 중 접두가 유일한 것은 72건(42%)뿐이고
#     M46이 신설한 아홉 중 여섯이 중복 접두다. 반면 **라벨의 보간 앞 안정 접두는 161/161 유일**이라
#     이것을 열쇠로 쓴다. 두 러너의 라벨은 언어가 다르므로 **각 사본이 자기 라벨을 읽는다**.
#   - **대상은 판정 코드까지 넓다(M63)** — 앞 판본은 *"판정 코드의 무력화는 형태가 매번 달라 선언으로
#     표현되지 않는다. 코드 쪽은 케이스별 되돌림 실측(사람)이 계속 덮는다"* 로 대상을 데이터 파일의
#     선언 토큰에 한정했다. **그 배당이 실제로 덮지 못한다는 것이 M62에서 실측됐다** — 사람의 되돌림
#     표는 **산출물 교란**만 다루므로 러너 자신의 변이를 겨냥한 행이 하나도 없었고, 그 사이에 적대
#     통제 하나가 **죽은 채** 통과했다(굵기 요구를 지워도 양 축 전건 초록). 막고 있던 것은 원리가
#     아니라 **문법**이었다 — 토큰이 영숫자·하이픈으로 제한돼 코드 리터럴을 적을 수 없었을 뿐이다.
#   - **그래서 치환이 리터럴이어야 한다** — 넓힌 토큰에는 `.`·`*`·`[`·`|`가 들어오고 `sed`는 그것을
#     **정규식 메타문자**로 읽는다. ps1 사본은 처음부터 `[string]::Replace`(리터럴)였으므로 **두 사본이
#     이미 갈려 있었다**(M63 실측). 아래 `lit_replace`가 sh를 ps1에 맞추고 `X6`이 그 동형을 문다 —
#     **다만 「한 줄·LF 내용에서」까지다.** `awk`는 CR을 선벗기고 파일 끝 개행을 보충하므로 **CRLF
#     파일·끝 개행 없는 파일에서는 두 사본이 여전히 갈린다**(M63 리뷰 실측 — 오늘 선언 셋 중 둘이
#     겨냥하는 `docs/conventions.md`가 CRLF다. 앞 판본의 `sed`도 같았으니 회귀는 아니다).
#     경계의 단일 원본은 `tests/mutation/README.md`의 "두 사본이 어디까지 같은 답을 내는가" 절이다.
#   - **비용이 범위를 가른다** — 뮤테이션 1건 = 사본 + 대상 하니스 1회다. **이 기계의 실측(M63)**:
#     sh 쪽 discover 1회 **407~679초**, pwsh 1회 **약 19초**(20배 이상 비대칭 — Windows 프로세스 생성
#     비용). **그 수를 잰 조건을 함께 적는다** — 위 값은 **다른 무거운 작업이 동시에 돌지 않는 상태**의
#     값이고, 경합 중에는 같은 축이 1652~1932초까지 갔다(M62 실측).
#     **경합이 없어도 같은 축이 1.7배로 흔들린다**(M63 리뷰 실측: 같은 트리·같은 세션에서 Git Bash
#     `sh` 679초 · `dash` 448초). **그래서 이 자리는 한 점이 아니라 범위여야 한다** — 점으로 적으면
#     다음 측정이 곧바로 낡히고, M63이 이 줄을 두 번 고친 이유가 그것이다. 앞 판본이 적은 *"약 72초"* 는
#     케이스가 172이던 시절의 값이라 **6배 낡아 있었다**. 전수는 로컬에서 불가하고 CI ubuntu가 빨라
#     전수가 가능하다. 그래서 로컬 기본은 **선언한 것만**이다.
set -u

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SBX="${TMPDIR:-/tmp}/tide-mutation.$$"
TARGET_REL="tests/discover/run.sh"
TARGET="$ROOT/$TARGET_REL"
README="$(dirname "$0")/README.md"

pass=0
fail=0
chk() { # <desc> <got> <want>
    if [ "$2" = "$3" ]; then pass=$((pass + 1)); printf 'PASS  %-56s (%s)\n' "$1" "$2"
    else fail=$((fail + 1)); printf 'FAIL  %-56s (got %s, want %s)\n' "$1" "$2" "$3"; fi
}
trap 'rm -rf "$SBX"' EXIT INT TERM
mkdir -p "$SBX"

# --- 리터럴 치환 ---------------------------------------------------------
# **정규식이 아니다.** 넓힌 토큰(판정 코드의 리터럴)에는 `.`·`*`·`[`·`|`가 들어오고 `sed`의 BRE는
# 그것을 메타문자로 읽어 **의도한 자리가 아닌 곳**을 바꾼다. ps1 사본은 처음부터 `[string]::Replace`
# (리터럴)였으므로 앞 판본의 두 사본은 **같은 선언에 다른 답**을 낼 수 있었다 — `X6`이 그 동형을 문다.
# **동형은 「한 줄·LF 내용」까지다** — 이 구현은 줄 단위라 **CR을 선벗기고 파일 끝 개행을 보충한다**.
# 선언한 토큰의 치환 결과는 두 사본이 같고 갈리는 것은 **대상 파일의 줄 끝**이다(M63 리뷰 실측).
# 경계의 단일 원본은 `tests/mutation/README.md`의 "두 사본이 어디까지 같은 답을 내는가" 절이다.
# **토큰은 `ENVIRON`으로 넘긴다** — `awk -v`는 값의 백슬래시 이스케이프를 처리해 토큰 자신을 바꾼다
# (이 저장소가 `-v` 전송에서 이미 데인 자리이고, 규약이 개행 금지를 그래서 적는다).
lit_replace() { # <파일> <토큰> <대체> → 치환 결과를 표준출력으로
    [ -n "$2" ] || { cat "$1"; return; }
    _lr_tok=$2 _lr_rep=$3 LC_ALL=C awk '
        BEGIN { tok = ENVIRON["_lr_tok"]; rep = ENVIRON["_lr_rep"]; n = length(tok) }
        {
            line = $0; out = ""
            while ((p = index(line, tok)) > 0) {
                out = out substr(line, 1, p - 1) rep
                line = substr(line, p + n)
            }
            print out line
        }
    ' "$1"
}

# --- 선언 추출 -----------------------------------------------------------
# 형식 둘:
#   `# mutates:    <파일> :: <토큰> :: <케이스 라벨 안정 접두> :: <caught|missed>`
#   `# mutates-to: <파일> :: <원본> :: <대체> :: <케이스 라벨 안정 접두> :: <caught|missed>`
# **둘째 형태가 M63에서 생겼다.** 첫 형태는 토큰을 **고정 무의미 문자열**로 바꾸므로 *"이 리터럴이
# 하중을 받는가"* 까지만 묻는다 — 판정 코드에 쓰면 ⑴ 문법이 깨져 러너가 통째로 죽거나(그러면 지목한
# 케이스가 FAIL 목록에 아예 없어 `missed`가 된다) ⑵ 죽지 않더라도 **판정을 느슨하게 만드는 회귀**
# (예: 굵은 코드 스팬 요구 → 맨 백틱)를 **표현할 수 없다**. M62가 실제로 당한 것이 후자다.
# 둘째 형태는 **무엇으로 바꿀지**를 선언이 정해 그 회귀를 그대로 재현한다.
# **두 형태를 별개 키워드로 둔다** — 한 키워드에 필드 수를 둘 허용하면 토큰에 구분자가 섞여 필드가
# 밀린 줄과 정상 5필드 줄을 `X5`가 가르지 못한다.
# `LC_ALL=C`: 정렬·비교를 바이트 동등으로 고정한다(로케일이 걸리면 두 셸이 갈린다).
LC_ALL=C grep -E '^# mutates(-to)?:' "$TARGET" > "$SBX/ann.txt" 2>/dev/null || :
NANN=$(LC_ALL=C grep -c . "$SBX/ann.txt")

# (X1) 추출 positive-control — 선언이 0건이면 아래 루프가 통째로 돌지 않아 `0 == 0`으로
# 조용히 통과한다(체크리스트 ⑴). 이 하니스가 가장 먼저 막아야 하는 자기 공허다.
chk "X1: mutates 선언 추출 positive-control(>0)" "$([ "$NANN" -gt 0 ] && echo ok || echo no)" "ok"

# (X2a·X4a) **선언 줄 유일성**(체크리스트 ⑵) — 값을 읽기 **전에** 그 선언 줄이 정확히 하나인지 센다.
# 첫 판본은 `head -1`로 첫 매치만 취해 **유일성을 묻지 않았고**, 리뷰가 그 공허를 실측으로 재현했다:
# 진짜 선언을 `cases: 99`로 낡게 두고 **그보다 앞 줄 산문에 `cases: 5`** 를 넣으니(이 저장소가 산문에
# 과거 수치를 적는 실제 습관이다) 낡은 선언인 채 **5/0 초록**이었다. 규약이 이 실패를 문장으로 예측한다 —
# *"유일성이 없으면 절 순서나 산문 한 줄이 집합을 통째로 바꾼다."* `tests/discover`의 `F14`와 같은 형태다.
DECL_MUT_N=$(LC_ALL=C grep -cE 'mutations: *[0-9]' "$README")
chk "X2a: mutations 선언 줄 유일성" "$DECL_MUT_N" "1"

# (X2) 선언 수 정합 — README의 `mutations:` 한 줄이 단일 선언처이고 실측과 대조한다.
# 양 사본이 **같은 선언처**를 보므로 이것이 두 러너의 선언 수 동수를 간접 보장한다.
DECL=$(LC_ALL=C sed -n 's/.*mutations: *\([0-9][0-9]*\).*/\1/p' "$README" | head -1)
chk "X2: README mutations 선언 == 실측 선언 수" "${DECL:-none}" "$NANN"

# (X5) **선언 줄의 필드 수**(M63) — 토큰 문법을 넓히면서 **유일하게 남긴 금지**가 필드 구분자
# ` :: `다. 토큰이 그 문자열을 품으면 `awk -F' :: '`가 필드를 하나 더 쪼개 **`$4`가 판정값이 아닌
# 것**을 집는다. 앞 판본은 필드 수를 묻지 않아 그 어긋남이 **조용했다** — 넓히는 편집이 여는 자리라
# 같은 편집에서 닫는다.
BADFIELDS=0
while IFS= read -r _xline; do
    [ -n "$_xline" ] || continue
    case "$_xline" in
        '# mutates-to:'*) _xwant=5; _xbody=${_xline#\# mutates-to:} ;;
        *)                _xwant=4; _xbody=${_xline#\# mutates:} ;;
    esac
    _xnf=$(printf '%s' "$_xbody" | LC_ALL=C awk -F' :: ' '{ print NF }')
    [ "$_xnf" -eq "$_xwant" ] || BADFIELDS=$((BADFIELDS + 1))
done < "$SBX/ann.txt"
chk "X5: 선언 줄의 필드 수가 키워드별 규정과 같다" "$BADFIELDS" "0"

# (X6) **리터럴 치환 자기 시험**(M63) — 정규식이면 `a.c`가 `abc`에도 걸린다. 리터럴이면 `a.c`만
# 걸린다. **두 사본이 같은 픽스처에 같은 답을 내야** 넓힌 문법이 축을 가르지 않는다(ps1 사본에
# 같은 이름·같은 픽스처의 케이스가 있다). 앞 판본의 sh는 `sed`(정규식)라 이 픽스처에서 `Z Z`를 냈다.
LITFX="$SBX/litfix.txt"
printf 'abc a.c\n' > "$LITFX"
chk "X6: 리터럴 치환 - 정규식 메타문자 토큰" "$(lit_replace "$LITFX" 'a.c' 'Z')" "abc Z"

# --- 뮤테이션 루프 -------------------------------------------------------
i=0
while IFS= read -r line; do
    [ -n "$line" ] || continue
    i=$((i + 1))
    case "$line" in
        '# mutates-to:'*)
            body=${line#\# mutates-to:}
            rep=$(printf '%s' "$body" | awk -F' :: ' '{print $3}' | sed 's/^ *//;s/ *$//')
            lab=$(printf '%s' "$body" | awk -F' :: ' '{print $4}' | sed 's/^ *//;s/ *$//')
            want=$(printf '%s' "$body"| awk -F' :: ' '{print $5}' | sed 's/^ *//;s/ *$//')
            ;;
        *)
            body=${line#\# mutates:}
            rep="MUTATED-BY-tide-mutation"
            lab=$(printf '%s' "$body" | awk -F' :: ' '{print $3}' | sed 's/^ *//;s/ *$//')
            want=$(printf '%s' "$body"| awk -F' :: ' '{print $4}' | sed 's/^ *//;s/ *$//')
            ;;
    esac
    f=$(printf '%s' "$body"  | awk -F' :: ' '{print $1}' | sed 's/^ *//;s/ *$//')
    tok=$(printf '%s' "$body" | awk -F' :: ' '{print $2}' | sed 's/^ *//;s/ *$//')

    W="$SBX/m$i"
    rm -rf "$W"; mkdir -p "$W"
    # 사본: .git 과 사이트 빌드 산출물은 판정에 쓰이지 않으므로 뺀다(비용).
    (cd "$ROOT" && tar cf - --exclude=.git --exclude=site/_build .) | (cd "$W" && tar xf -)

    # 토큰을 깬다. 토큰은 **필드 구분자 ` :: `만 금지**하고 그 밖의 문자를 허용한다(M63 — README의
    # 선언 규율). 금지가 지켜지는지는 `X5`가 선언 줄의 필드 수로 묻는다.
    # **치환이지 덧붙이기가 아니다** — 첫 판본은 `$tok-MUTANT`로 바꿨는데 그 값이 원본을 **부분
    # 문자열로 포함**해 `has_token` 류의 부분일치 검사가 여전히 찾았고, 뮤테이션이 통째로 무효였다.
    # 이 하니스의 **첫 실행이 그것을 `missed`로 보고해** 잡았다(M47 자기 관측).
    # **`sed -i`를 쓰지 않는다** — GNU는 인자 없는 `-i`를, BSD(macOS)는 `-i ''`를 요구해 **두 계열을
    # 동시에 만족하는 형태가 없다**. 첫 판본이 `sed -i`를 들여왔고(기존 러너 여섯 종은 한 번도 쓰지
    # 않는다) CI가 하니스를 **파일시스템에서 발견**하므로 macOS 레그에서 깨질 자리였다. 이 저장소가
    # `debug-1`을 연 것과 같은 구조(GNU는 받고 BSD는 거부)라 임시 파일 + `mv`로 되돌렸다.
    # 임시 파일은 **사본 트리 밖**(`$SBX`)에 둔다 — 첫 판본은 `$W/$f.mut`에 썼고, `sed`가 실패하면
    # `&&`가 `mv`를 막아 **잔재가 사본 안에 남은 채** 대상 하니스가 돌 수 있었다(리뷰 사소 2).
    # 대상이 `tests/` 아래 파일이 되면 그 잔재가 발견 집합에 섞이지 않는다는 보장이 사라진다.
    # ps1 사본은 메모리에서 치환해 잔재가 아예 없다 — 이 편집으로 두 사본이 같은 성질이 된다.
    if [ -f "$W/$f" ]; then
        lit_replace "$W/$f" "$tok" "$rep" > "$SBX/mut.tmp" && mv "$SBX/mut.tmp" "$W/$f"
    fi

    got=$(sh "$W/$TARGET_REL" 2>&1 | LC_ALL=C grep '^FAIL' | LC_ALL=C grep -cF "$lab")
    r=$([ "$got" -gt 0 ] && echo caught || echo missed)
    chk "X3[$want]: $lab" "$r" "$want"
    rm -rf "$W"
done < "$SBX/ann.txt"

# (X4) 케이스 수 자기 정합 — README의 `cases:` 선언과 **실제 케이스 수**를 대조한다. 기존 하니스
# 여섯 종이 전부 갖고 있는 형태인데 이 하니스만 빠져 있었고(리뷰 차단 1), **README는 대조한다고
# 적고 있었다** — 선언을 하나 더하면 케이스가 늘어도 선언은 그대로인데 아무것도 붉지 않는 자리였다.
# `+ 1`은 자기 자신을 센다(discover의 `F1`과 같은 관용구).
DECL_CASES_N=$(LC_ALL=C grep -cE 'cases: *[0-9]' "$README")
chk "X4a: cases 선언 줄 유일성" "$DECL_CASES_N" "1"
DECL_CASES=$(LC_ALL=C sed -n 's/.*cases: *\([0-9][0-9]*\).*/\1/p' "$README" | head -1)
chk "X4: README cases 선언 == 실제 케이스 수" "${DECL_CASES:-none}" "$((pass + fail + 1))"

echo
# **변수 뒤에 다중바이트 문자가 오면 반드시 `${...}`로 이름 경계를 명시한다.** `$NANN건`은 이 기계의
# bash 5.2·dash에서는 이름이 `NANN`에서 끊겨 정상이지만, macOS가 `sh`로 쓰는 **bash 3.2는 뒤따르는
# 바이트를 이름에 포함**해 `set -u`가 `unbound variable`로 죽인다(v2.19.1 릴리즈 PR의
# `posix (macos-latest)` 실측 — 로컬 네 환경과 우분투는 전부 초록이었다).
echo "# 결과: PASS=$pass FAIL=$fail (뮤테이션 ${NANN}건 · 대상 $TARGET_REL)"
[ "$fail" -eq 0 ] || exit 1
echo "# mutation: 선언 토큰을 깨면 지목한 케이스가 붉어지는지 확인함 — 동어반복 케이스 검출 (참조 구현 기준)"
