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
#   - **대상은 선언 토큰 케이스에 한정한다** — 데이터 파일의 리터럴 토큰을 깨는 것은 일반화되지만
#     판정 코드의 무력화는 형태가 매번 달라 선언으로 표현되지 않는다. 코드 쪽은 규약이 요구하는
#     **케이스별 되돌림 실측**(사람)이 계속 덮는다.
#   - **비용이 범위를 가른다** — 뮤테이션 1건 = 사본 + 대상 하니스 1회다. 이 기계에서 sh 쪽 discover는
#     1회 **약 72초**(pwsh는 약 6초, 12배 비대칭 — Windows 프로세스 생성 비용). 전수(161건)는 로컬에서
#     불가하고 CI ubuntu는 13배 빨라 전수가 가능하다. 그래서 로컬 기본은 **선언한 것만**이다.
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

# --- 선언 추출 -----------------------------------------------------------
# 형식: `# mutates: <파일> :: <토큰> :: <케이스 라벨 안정 접두> :: <caught|missed>`
# `LC_ALL=C`: 정렬·비교를 바이트 동등으로 고정한다(로케일이 걸리면 두 셸이 갈린다).
LC_ALL=C grep -E '^# mutates:' "$TARGET" > "$SBX/ann.txt" 2>/dev/null || :
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

# --- 뮤테이션 루프 -------------------------------------------------------
i=0
while IFS= read -r line; do
    [ -n "$line" ] || continue
    i=$((i + 1))
    body=${line#\# mutates:}
    f=$(printf '%s' "$body"  | awk -F' :: ' '{print $1}' | sed 's/^ *//;s/ *$//')
    tok=$(printf '%s' "$body" | awk -F' :: ' '{print $2}' | sed 's/^ *//;s/ *$//')
    lab=$(printf '%s' "$body" | awk -F' :: ' '{print $3}' | sed 's/^ *//;s/ *$//')
    want=$(printf '%s' "$body"| awk -F' :: ' '{print $4}' | sed 's/^ *//;s/ *$//')

    W="$SBX/m$i"
    rm -rf "$W"; mkdir -p "$W"
    # 사본: .git 과 사이트 빌드 산출물은 판정에 쓰이지 않으므로 뺀다(비용).
    (cd "$ROOT" && tar cf - --exclude=.git --exclude=site/_build .) | (cd "$W" && tar xf -)

    # 토큰을 깬다. 토큰은 영숫자·하이픈으로 제한돼 있어 구분자 충돌이 없다(README의 선언 규율).
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
        LC_ALL=C sed "s|$tok|MUTATED-BY-tide-mutation|g" "$W/$f" > "$SBX/mut.tmp" && mv "$SBX/mut.tmp" "$W/$f"
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
echo "# 결과: PASS=$pass FAIL=$fail (뮤테이션 $NANN건 · 대상 $TARGET_REL)"
[ "$fail" -eq 0 ] || exit 1
echo "# mutation: 선언 토큰을 깨면 지목한 케이스가 붉어지는지 확인함 — 동어반복 케이스 검출 (참조 구현 기준)"
