---
description: "[tide] 새 프로젝트에 tide 워크플로우 골격 생성 (마일스톤/리포트/CHANGELOG/규약/가드 hook)"
argument-hint: "[프로젝트 한 줄 설명(선택)]"
---
이 저장소에 tide 개발 사이클 골격을 세팅해줘. 한 줄 설명: "$ARGUMENTS"

생성/확인 (기존 파일은 덮어쓰지 말고 누락된 것만 보강):
1. docs/milestones/ 및 docs/reports/ 디렉터리
2. CHANGELOG.md (없으면 "# CHANGELOG" 헤더로 생성)
3. README.md에 "## CHANGELOG" 섹션이 없으면 추가
4. docs/conventions.md — 마일스톤 7개 섹션 형식, 태스크 ID·(deps:) 표기,
   단계별 금지행위(impl/review는 git 금지), 보고서 형식, 버전 파일 위치,
   상태 파일(.tide/phase) 규약 명시
5. .gitignore에 `.tide/` 항목이 없으면 추가 (상태 파일은 커밋 대상 아님)
6. 버전 파일(Cargo.toml/package.json/pyproject.toml 등) 감지 후 현재 버전 보고
7. tide-guard hook 설치 (아래 절차)

## tide-guard hook 설치

`.tide/phase`가 `release`가 아닌 동안 git commit/tag/push를 기계적으로 차단하는
PreToolUse hook이다. 다음을 수행해줘 (이미 있는 파일·설정은 건드리지 않음):

1. `.claude/hooks/tide-guard.sh` 와 `.claude/hooks/tide-guard.ps1` 을 아래 내용
   **그대로** 생성. POSIX 환경이면 sh 파일에 실행 권한(chmod +x) 부여.
2. `.claude/settings.json`의 hooks.PreToolUse에 아래 항목을 병합
   (기존 hooks 설정은 보존, tide-guard가 이미 등록돼 있으면 건너뜀).
   command는 현재 플랫폼에 맞는 것 **하나만** 등록:
   - Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/tide-guard.ps1`
     (상대 경로 — hook은 프로젝트 루트에서 실행되며, cmd에서는 `$VAR`가 확장되지 않으므로
     변수 경로를 쓰면 가드가 조용히 무력화된다)
   - macOS/Linux: `"$CLAUDE_PROJECT_DIR/.claude/hooks/tide-guard.sh"`

settings.json 병합 형태:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|PowerShell",
        "hooks": [
          { "type": "command", "command": "<위 플랫폼별 command>" }
        ]
      }
    ]
  }
}
```

tide-guard.sh 내용:

```sh
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
    echo "tide-guard: git commit/tag/push is blocked during phase '$phase'. Git operations are allowed only in /tide-release." >&2
    exit 2
fi

exit 0
```

tide-guard.ps1 내용:

```powershell
# tide-guard — PreToolUse hook
# .tide/phase가 release가 아닌 동안 git commit/tag/push를 차단한다.
# 상태 파일이 없으면 아무것도 차단하지 않는다 (tide 미사용 프로젝트에 영향 없음).

$inputJson = [Console]::In.ReadToEnd()

$root = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { "." }
$phaseFile = Join-Path $root ".tide/phase"
if (-not (Test-Path $phaseFile)) { exit 0 }

$phase = (Get-Content $phaseFile -TotalCount 1).Trim()
if ($phase -eq "release") { exit 0 }

$cmd = $inputJson
try {
    $parsed = $inputJson | ConvertFrom-Json
    if ($parsed.tool_input -and $parsed.tool_input.command) { $cmd = $parsed.tool_input.command }
} catch {}

if ($cmd -match 'git[^&|;]*[^a-zA-Z](commit|tag|push)([^a-zA-Z]|$)') {
    [Console]::Error.WriteLine("tide-guard: git commit/tag/push is blocked during phase '$phase'. Git operations are allowed only in /tide-release.")
    exit 2
}

exit 0
```

git 작업은 하지 마. 완료 후 hook 설치 결과(settings.json 반영 여부 포함)와 함께
다음 단계(/tide-milestone)를 안내해줘.
