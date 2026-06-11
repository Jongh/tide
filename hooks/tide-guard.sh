#!/bin/sh
# tide-guard — PreToolUse hook
# .tide/phase가 release가 아닌 동안 git commit/tag/push를 차단한다.
# 상태 파일이 없으면 아무것도 차단하지 않는다 (tide 미사용 프로젝트에 영향 없음).

input=$(cat)

phase_file="${CLAUDE_PROJECT_DIR:-.}/.tide/phase"
[ -f "$phase_file" ] || exit 0

phase=$(head -n 1 "$phase_file" | tr -d '[:space:]')
[ "$phase" = "release" ] && exit 0

if printf '%s' "$input" | grep -Eq 'git[^&|;]*[^a-zA-Z](commit|tag|push)([^a-zA-Z]|$)'; then
    echo "tide-guard: '$phase' 단계에서는 git commit/tag/push가 차단됩니다. git 작업은 /tide:release 단계에서만 허용됩니다." >&2
    exit 2
fi

exit 0
