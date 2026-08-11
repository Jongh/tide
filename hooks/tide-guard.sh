#!/bin/sh
# tide-guard — PreToolUse hook
# .tide/phase가 release가 아닌 동안 git commit/tag/push를 차단한다.
# 상태 파일이 없으면 아무것도 차단하지 않는다. 이 무차단은 두 경우를 함께 덮는다 —
#   (a) tide 미사용 프로젝트(영향 없음), (b) tide 레포인데 phase가 아직 없는 상태.
# (b)가 보호 창이다: .tide/phase는 gitignore 대상이라 fresh clone·신규 머신·플러그인 설치 직후에는
# git 쓰기 보호가 0이고, 창은 phase가 실제로 기록될 때 닫힌다 — 호출만으로는 닫히지 않는다
# (phase를 아예 쓰지 않는 커맨드가 있고, 쓰는 커맨드도 전제조건 검사에서 중단되면 기록 전에 끝난다).
# 어느 커맨드가 쓰는지·언제 쓰는지는 docs/conventions.md "상태 파일 (.tide/phase)" 절과 각 SKILL이
# 단일 원본이다 — 여기에 명단을 복제하지 않는다.
# 매처가 Bash|PowerShell이라 Edit/Write 도구 경로는 훅을 타지 않고, phase를 기록하는 주체가 LLM이라
# 기계적 가드의 전제조건 자체가 프롬프트 규율이다 — 보호는 조건부다. 창·우회 표면은 고지 후 수용이며,
# 단일 원본 = docs/conventions.md "tide-guard hook" 절, 3.0 후보 등재는 "2.0 안정성" 절.

raw_input=$(cat)

# 입력 견고화 — 선두 잡음 관용 파싱. 훅 입력은 항상 최상위 JSON *객체*이므로, 첫 '{' 앞에 붙어
# 도착한 바이트는 무엇이든 버린다. 형태를 열거하지 않고 부류 전체를 닫는 방식이라 선두 UTF-8
# BOM(EF BB BF)뿐 아니라 임의의 비-JSON 선두 바이트도 같은 한 자리가 덮는다. ps1 사본과 같은
# 의미다 — 다만 거기서는 이 정규화만으로 부족해 stdin을 바이트로 받아 UTF-8로 직접 디코드하는
# 단계가 앞에 붙는다([Console]::In의 디코딩이 콘솔 입력 코드페이지를 따라 여는 중괄호까지
# 삼키기 때문이다). POSIX 가드는 `cat`이 바이트를 그대로 넘겨 그 축이 애초에 없으므로 이 한
# 자리로 같은 의미가 선다. 잡음이 없으면 무동작이고, '{'가 아예 없으면 자르지 않고
# 기존 경로(추출 실패 -> 보수적 폴백)를 그대로 탄다.
# 판정 **규칙**은 불변이지만 **판정 자체가 불변인 것은 아니다** — 잡음 때문에 파싱에 실패하던 입력이
# 이제 성공하므로 그 입력의 답은 **잡음 없는 같은 입력의 답과 같아진다**(= cwd가 가리킨 레포의 phase가
# 판정을 끈다). 방향은 한쪽이 아니다(폴백이 우연히 더 엄격했던 구성에서는 차단 -> 통과로 움직인다).
# 앞선 판본이 여기 "판정은 불변"이라 적었다가 M42 리뷰의 반례로 무너졌다 — ps1 사본에 같은 주석이 있다.
#
# **두 사본을 나눠 든다**(M42-T09). `raw_input` = 도착한 그대로의 입력, `input` = 정규화된 사본.
#   * `input`은 **구조 파싱에만** 쓴다 — `cwd`·`command` 추출(jq 경로·sed 폴백) 두 자리뿐이다.
#   * 아래 `cmd` 추출이 실패했을 때 도는 **보수적 폴백 스캔은 `raw_input`을 훑는다.**
# 정규화한 문자열을 폴백에까지 물리면 첫 '{' 앞의 바이트가 **스캔 범위에서도** 사라진다. 실측:
# JSON이 아닌 원시 입력 `git commit -m "a{b}"`가 `{b}"`로 잘려 폴백이 git 쓰기를 못 보고 통과했다
# (수정 전 exit 0 / M42 이전 exit 2 — sh·pwsh 양쪽). 폴백의 존재 이유가 **파싱 불가 입력에서
# 과소 차단을 막는 것**이므로, 파싱을 돕자고 만든 절단이 그 자리의 시야를 좁혀서는 안 된다.
input=$raw_input
case $input in
    '{'*) : ;;
    *'{'*) input="{${input#*\{}" ;;
    *) : ;;
esac

# 명령이 실제 실행되는 작업 디렉터리(cwd)의 git 레포 루트에서 .tide/phase를 읽는다.
# 1) 훅 입력 JSON의 cwd 필드 → 2) git -C "$cwd" rev-parse --show-toplevel →
# 3) 못 구하면 기존 동작으로 폴백(${CLAUDE_PROJECT_DIR:-.}). 폴백해도 phase 없으면 무차단.
cwd=""
if command -v jq >/dev/null 2>&1; then
    cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
else
    # 키를 JSON 구조 경계({·,·공백)로 앵커링해 "..._cwd" 같은 부분일치 오인을 줄인다(판정 불변).
    cwd=$(printf '%s' "$input" | sed -n 's/.*[{,[:space:]]"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    # sed 폴백은 JSON 이스케이프를 직접 푼다 (jq는 자동 처리).
    if [ -n "$cwd" ]; then
        cwd=$(printf '%s' "$cwd" | sed -e 's/\\\\/\\/g' -e 's/\\\//\//g')
    fi
fi

root=""
if [ -n "$cwd" ]; then
    root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
fi

if [ -n "$root" ]; then
    phase_file="$root/.tide/phase"
else
    phase_file="${CLAUDE_PROJECT_DIR:-.}/.tide/phase"
fi
[ -f "$phase_file" ] || exit 0

phase=$(head -n 1 "$phase_file" | tr -d '[:space:]')
[ "$phase" = "release" ] && exit 0

# ── git 쓰기/읽기 판정 ───────────────────────────────────────────────
# release가 아닌 phase에서 git *쓰기* 서브커맨드만 차단한다(읽기는 통과 — 맥락 파악용).
# verb(commit·tag·push)는 git **서브커맨드 위치**에서만 본다 — git 뒤 전역 옵션(인자 소비형은
# 그 인자까지)을 건너뛴 첫 비-옵션 토큰. 옵션 값(--grep=commit)·경로(HEAD:src/tag.rs)·복합
# 서브커맨드 이름(commit-graph·cat-file commit)의 부분일치는 무시한다. tag는 읽기 옵션만/인자
# 없음이면 목록(읽기), 쓰기 옵션이나 목록 옵션 없는 위치 인자(태그명)면 생성/삭제(쓰기).
# 단일 원본 규약 = docs/conventions.md "tide-guard hook" 절. 집행 = tests/multi-repo.
seg_is_write() {
    # 토큰 분리는 기본 IFS(공백·탭·개행)로 — 호출부가 IFS=개행으로 세그먼트를 돌리므로
    # 여기서 잠시 기본 분리로 되돌린 뒤 위치 파라미터로 토큰화한다.
    _oifs=$IFS; unset IFS
    set -f
    # shellcheck disable=SC2086
    set -- $1
    set +f
    IFS=$_oifs
    found_git=0
    while [ $# -gt 0 ]; do
        case $1 in
            git|*/git|git.exe|*/git.exe) found_git=1; shift; break ;;
            *) shift ;;
        esac
    done
    [ "$found_git" = 1 ] || return 1
    sub=""
    while [ $# -gt 0 ]; do
        case $1 in
            -C|-c|--git-dir|--work-tree|--namespace|--super-prefix|--exec-path)
                shift; [ $# -gt 0 ] && shift; continue ;;
            -*) shift; continue ;;
            *) sub=$1; shift; break ;;
        esac
    done
    case $sub in
        commit|push) return 0 ;;
        tag) ;;
        *) return 1 ;;
    esac
    wopt=0; rlist=0; pos=0
    while [ $# -gt 0 ]; do
        case $1 in
            '>'*|'<'*|'1>'*|'2>'*|'&>'*) break ;;
            -a|--annotate|-s|--sign|-u|--local-user|-m|--message|-F|--file|-e|--edit|-f|--force|-d|--delete|--create-reflog) wopt=1 ;;
            -m?*|-F?*|-u?*) wopt=1 ;;
            -l|--list|--contains|--no-contains|--points-at|--merged|--no-merged|--column|--no-column|-i|--ignore-case|-v|--verify|--omit-empty) rlist=1 ;;
            -n|-n[0-9]*) rlist=1 ;;
            --sort|--sort=*|--format|--format=*) rlist=1 ;;
            -*) : ;;
            *) pos=1 ;;
        esac
        shift
    done
    [ "$wopt" = 1 ] && return 0
    [ "$pos" = 1 ] && [ "$rlist" = 0 ] && return 0
    return 1
}

# 실제 셸 명령을 추출한다(서브커맨드 판정용) — 추출은 **정규화된 `input`** 위에서 한다.
# 추출 실패 시 보수적으로 기존 부분일치 규칙으로 폴백하며, 그 스캔은 **정규화되지 않은
# `raw_input`**을 훑는다(위 정규화 블록 주석 참조) — 파싱 불가 입력에서 과소 차단을 막는다.
if command -v jq >/dev/null 2>&1; then
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
else
    cmd=$(printf '%s' "$input" | sed -n 's/.*[{,[:space:]]"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    if [ -n "$cmd" ]; then
        cmd=$(printf '%s' "$cmd" | sed -e 's/\\"/"/g' -e 's/\\\\/\\/g' -e 's/\\\//\//g')
    fi
fi

block_msg="tide-guard: '$phase' 단계에서는 git 쓰기(commit·태그 생성/삭제·push)가 차단됩니다 — 읽기는 허용됩니다. git 쓰기는 /tide:release 단계에서만 가능합니다."

if [ -n "$cmd" ]; then
    oldIFS=$IFS
    IFS='
'
    for seg in $(printf '%s' "$cmd" | tr '&|;' '\n\n\n'); do
        if seg_is_write "$seg"; then
            IFS=$oldIFS
            echo "$block_msg" >&2
            exit 2
        fi
    done
    IFS=$oldIFS
    exit 0
else
    # 보수적 폴백 — **원본**(`raw_input`)을 훑는다. 정규화 사본을 쓰면 첫 '{' 앞의 git 쓰기가
    # 스캔 범위 밖으로 나간다(위 정규화 블록의 실측).
    if printf '%s' "$raw_input" | grep -Eq 'git[^&|;]*[^a-zA-Z](commit|tag|push)([^a-zA-Z]|$)'; then
        echo "$block_msg" >&2
        exit 2
    fi
    exit 0
fi
