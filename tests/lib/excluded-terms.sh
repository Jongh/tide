#!/bin/sh
# tide — 제외 용어 도출 (sh 쪽 단일 원본)
#
# 무엇인가: 사이트 콘텐츠에서 빠져 있어야 하는 **제외 용어**를 마스트헤드 도입부에서 도출한다.
# 목록을 하드코딩하지 않는다 — 하드코딩하면 그 자리가 두 번째 선언처가 되고, 소스에 용어를
# 그대로 남기게 된다. 규약의 단일 원본은 `docs/conventions.md`의 "릴리즈 빌드 출력 검증" 절이다.
#
# 왜 라이브러리인가(M57): 같은 도출을 **하니스와 CI가 각자 구현**하면 한쪽이 조용히 낡는다.
# 그것이 이 사이클이 무는 부류 그 자체다. sh 쪽 구현을 여기 하나로 모으고
# `tests/site-includes/run.sh`와 `.github/workflows/deploy-pages.yml`이 **둘 다 이 파일을 읽는다**.
# `.ps1` 사본은 두 사본 계약대로 자기 구현을 갖는다(러너 쌍의 동형성이 그 층의 요구다).
#
# 쓰는 법:
#   . "$ROOT/tests/lib/excluded-terms.sh"
#   terms=$(excluded_terms "$ROOT")            # 한 줄에 하나
#   region=$(excluded_masthead "$ROOT")        # 양성 통제용 원본 구역
#
# 도출이 0건이면 **호출자가 실패해야 한다** — 0건인 채로 스캔하면 «검출 0»이 공허하게 성립한다.

# 외부 귀속은 README/규약의 **3행 도입부**에 `<TERM>… <한국어 방법론 어구>` 형태로 있다. 그 도입부는
# 일부러 `[start:body]` **밖**에 두므로 용어가 본문 구역에 나타나면 안 된다. 한국어 어구는 UTF-8
# 바이트로 조립해 **이 소스에 제외 용어도 한글 리터럴도 남기지 않는다**.
# 팔진(`\357`류)으로 쓴다 — `\xHH`는 POSIX printf에 없어 dash가 글자 그대로 내보낸다.
_EXTERM_KO=$(printf '\354\235\230 \352\260\234\353\260\234 \353\260\251\353\262\225\353\241\240')

# 도출 대상 소스. 마스트헤드를 가진 두 파일이며 순서가 곧 중복 제거 우선순위다.
_exterm_sources() { # <레포 루트> → 소스 경로 한 줄씩
    printf '%s\n' "$1/README.md" "$1/docs/conventions.md"
}

_exterm_extract() { # <파일> → 그 파일에서 도출한 용어 하나 (없으면 빈 출력)
    [ -f "$1" ] || return 0
    # 한국어 방법론 어구 **바로 앞**의 ASCII 낱말
    LC_ALL=C sed -n "s/.*[ \\t([]\\([A-Za-z][A-Za-z0-9_-]*\\)${_EXTERM_KO}.*/\\1/p; s/^\\([A-Za-z][A-Za-z0-9_-]*\\)${_EXTERM_KO}.*/\\1/p" "$1" | head -1
}

# **경로에 공백이 있어도 도출된다(M57 리뷰 — in-review 수정)**: 소스 목록은 **한 줄에 하나**이므로
# 단어 분할을 **개행으로만** 한다. 기본 IFS로 인용 없는 `$(...)`를 돌리면 `/c/tide repo/README.md`가
# 두 낱말로 갈려 **도출이 0건**이 되고, 그러면 본문 스캔이 0회 돌아 아무것도 세지 않는다. 이 저장소는
# 「레포 경로의 공백」을 **도달 가능한 트리거의 실례**로 이미 등록해 두었다(규약의 도달 가능성 가중).
# 라이브러리로 모으기 전 `tests/site-includes/run.sh`의 구현은 경로를 인용해 두어 안전했으므로,
# 이것은 **모으면서 생긴 회귀**다 — 선언처를 하나로 모으는 편집이 무엇을 잃을 수 있는지의 실례다.
excluded_terms() { # <레포 루트> → 도출된 제외 용어 (중복 제거, 한 줄에 하나)
    _et_out=''
    _et_oifs=$IFS
    IFS='
'
    set -- $(_exterm_sources "$1")
    IFS=$_et_oifs
    for _et_src in "$@"; do
        _et_t=$(_exterm_extract "$_et_src")
        [ -n "$_et_t" ] || continue
        case " $_et_out " in *" $_et_t "*) : ;; *) _et_out="$_et_out $_et_t" ;; esac
    done
    for _et_t in $_et_out; do printf '%s\n' "$_et_t"; done
}

excluded_masthead() { # <레포 루트> → 도출에 쓴 마스트헤드 구역(3행)을 이어 붙인 것
    # 양성 통제가 이 구역에서 «도출된 용어가 실제로 들어 있는가»를 다시 확인한다 — 잘못 뽑은
    # 토큰은 본문에도 없으므로 용어 스캔이 **공허하게 초록**이 된다(M46 판례의 동어반복).
    _et_oifs=$IFS
    IFS='
'
    set -- $(_exterm_sources "$1")
    IFS=$_et_oifs
    for _et_src in "$@"; do
        [ -f "$_et_src" ] || continue
        [ -n "$(_exterm_extract "$_et_src")" ] || continue
        sed -n '3p' "$_et_src"
    done
}
