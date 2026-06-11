# 프로젝트 컨텍스트 (project-context)

> `/tide:kickoff`가 진행 중 프로젝트를 감지해 생성하는 문서. 이후 `/tide:milestone`·
> `/tide:impl`이 기존 구조를 재조사 없이 참조한다. 구조가 바뀌면 갱신한다.

## 스택 · 의존성

- **형태**: Claude Code 플러그인 (코드 런타임 없음 — 마크다운 프롬프트 + 셸 hook으로 구성)
- **언어**: Markdown(스킬·문서), POSIX sh + PowerShell(가드 hook), JSON(매니페스트)
- **외부 의존성**: 런타임 의존성 없음. Windows에서 hook 실행에 Git for Windows의 `sh` 필요
- **버전**: 0.4.0 (`.claude-plugin/plugin.json`이 단일 버전 원본)

## 디렉터리 구조

| 경로 | 역할 |
|---|---|
| `.claude-plugin/` | `plugin.json`·`marketplace.json` — 플러그인/마켓플레이스 매니페스트 (버전 원본) |
| `skills/` | 스킬 6종 — `{kickoff,milestone,impl,review,release,status}/SKILL.md`. milestone·impl·review는 `template.md` 동봉 |
| `hooks/` | `hooks.json`(PreToolUse 등록) + `tide-guard.sh`(원본 로직)·`tide-guard.ps1`(보조 사본) |
| `docs/milestones/` | 마일스톤 문서 `M{N}.md` |
| `docs/reports/` | 완료보고서 `M{N}-impl.md`·리뷰보고서 `M{N}-review.md` |
| `docs/conventions.md` | 단계별 규약 단일 원본 |
| `.tide/` | 로컬 상태 파일(`phase`) — `.gitignore` 대상, 커밋 안 함 |

## 진입점 · 빌드/테스트

- **진입점**: 슬래시 커맨드 `/tide:{단계}` (플러그인 설치 시 노출). 가드는 PreToolUse hook으로 자동 활성
- **빌드**: 없음 (해석형 마크다운/셸)
- **테스트**: 자동화된 테스트 러너 없음. 검증 수단은 **플러그인 재설치 후 새 세션 드라이런/도그푸딩**
  (스킬 노출 확인, 가드 차단/통과 확인, 템플릿 경로 치환 확인). 가드 스크립트 수정 시
  `.sh`·`.ps1` 두 사본을 함께 갱신
- **개발 사이클**: tide 자신을 도그푸딩 — `/tide:milestone → impl → review → release`

## 핵심 도메인 개념

- **사이클**: kickoff → milestone → impl → review → release. `status`는 읽기 전용 현재 위치 보고
- **부수효과 분리**: impl·review는 git 작업 금지(코드·보고서만), git commit/tag/push는 release에서만
- **tide-guard**: `.tide/phase`가 `release`가 아니면 git commit/tag/push를 기계적으로 차단(exit 2).
  상태 파일이 없으면 차단하지 않음
- **상태 파일 `.tide/phase`**: 현재 단계명 한 줄(`milestone`/`impl`/`review`/`release`/`idle`).
  각 스킬이 시작 시 기록하고 종료 시 `idle`로 되돌림
- **템플릿 단일 원본**: 마일스톤·보고서 형식은 각 스킬의 `${CLAUDE_SKILL_DIR}/template.md`가 원본
- **태스크 표기**: `M{N}-T01` … , 선행 의존은 `(deps: M{N}-T01, …)`

## 메타

- 생성: `/tide:kickoff` 브라운필드 감지 (M4 자기적용) — 2026-06-11 기준
- 감지 근거: 커밋 4개 + 기존 스킬/hook 소스 + M1~M6 마일스톤 보유 → 진행 중 프로젝트
