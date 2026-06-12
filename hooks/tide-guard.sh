#!/bin/sh
# tide-guard — PreToolUse hook
# .tide/phase가 release가 아닌 동안 git commit/tag/push를 차단한다.
# 상태 파일이 없으면 아무것도 차단하지 않는다 (tide 미사용 프로젝트에 영향 없음).

input=$(cat)

# 명령이 실제 실행되는 작업 디렉터리(cwd)의 git 레포 루트에서 .tide/phase를 읽는다.
# 1) 훅 입력 JSON의 cwd 필드 → 2) git -C "$cwd" rev-parse --show-toplevel →
# 3) 못 구하면 기존 동작으로 폴백(${CLAUDE_PROJECT_DIR:-.}). 폴백해도 phase 없으면 무차단.
cwd=""
if command -v jq >/dev/null 2>&1; then
    cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
else
    cwd=$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
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

if printf '%s' "$input" | grep -Eq 'git[^&|;]*[^a-zA-Z](commit|tag|push)([^a-zA-Z]|$)'; then
    echo "tide-guard: '$phase' 단계에서는 git commit/tag/push가 차단됩니다. git 작업은 /tide:release 단계에서만 허용됩니다." >&2
    exit 2
fi

exit 0
