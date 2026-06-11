# tide

porpoise의 개발 방법론(마일스톤 → 구현 → 리뷰 → 릴리즈)을 **프로젝트 독립적인 Claude Code
슬래시 커맨드**로 옮긴 워크플로우 모음입니다. 어떤 저장소에든 얹어 동일한 개발 리듬과
문서화 규율을 그대로 적용할 수 있습니다.

## 사이클

```
/tide-kickoff  →  /tide-milestone  →  /tide-impl  →  /tide-review  →  /tide-release vX.Y.Z
   (세팅)           (계획)             (구현·테스트)    (리뷰·판정)       (배포)

              /tide-status — 언제든 현재 위치와 다음 커맨드 확인 (읽기 전용)
```

각 단계는 **부수효과를 엄격히 분리**합니다 — `impl`·`review`는 절대 git 작업을 하지 않고
(코드·보고서만 남김), git commit/tag/push는 오직 `release`에서만 일어납니다.

이 원칙은 프롬프트 지시에 더해 **tide-guard hook**으로 기계적으로 강제됩니다:
플러그인이 직접 제공하는 PreToolUse hook이 `.tide/phase` 상태 파일을 보고,
`release` 단계가 아닌 동안 git commit/tag/push 명령을 차단합니다. 또한 각 단계는
시작 전 **전제조건 검사**(impl: 마일스톤 존재, review: 완료보고서 존재)를 하고,
`release`는 **프리플라이트**(리뷰 판정 "가능" + 테스트 통과 + 워킹트리 확인)를
통과해야 git 작업을 시작합니다.

## 커맨드

| 커맨드 | 역할 | 산출물 |
|---|---|---|
| `/tide-kickoff` | 새 프로젝트에 워크플로우 골격 생성 | `docs/milestones/`·`docs/reports/`·`CHANGELOG.md`·`docs/conventions.md` |
| `/tide-milestone` | 다음 마일스톤 문서 생성 | `docs/milestones/M{N}.md` |
| `/tide-impl [M번호]` | 마일스톤대로 구현 + 테스트 (생략 시 최신, 번호 지정 시 재실행) | 코드 + `docs/reports/M{N}-impl.md` (완료보고서) |
| `/tide-review` | 비판적 리뷰 + 릴리즈 판정 | `docs/reports/M{N}-review.md` (리뷰보고서) |
| `/tide-release` | 프리플라이트 → 버전 범프 → CHANGELOG → commit → tag → push | 릴리즈 커밋·태그 |
| `/tide-status` | 사이클 현재 상태 + 다음 권장 커맨드 (읽기 전용) | (없음 — 보고만) |

## 설치

### 플러그인 (권장)

```
/plugin marketplace add Jongh/tide
/plugin install tide@tide
```

커맨드 6종과 tide-guard hook이 **함께** 활성화됩니다. 프로젝트별 hook 설치 절차는
없습니다 — 가드는 플러그인이 `${CLAUDE_PLUGIN_ROOT}` 경로의 hook으로 직접 제공합니다.

> Windows 참고: hook은 `sh`로 실행되므로 Git for Windows가 필요합니다
> (Claude Code의 Bash 도구가 요구하는 것과 동일한 전제).

### 수동 복사 (비권장 — 가드 hook 미포함)

```bash
mkdir -p ~/.claude/commands
cp commands/tide-*.md ~/.claude/commands/
```

이 경로는 tide-guard hook이 설치되지 않아 git 금지가 프롬프트 수준으로만 동작합니다.

> **구버전(≤v0.2.0)에서 마이그레이션**: 프로젝트나 전역 `.claude/commands/`에 복사해 둔
> `tide-*.md` 사본은 **플러그인 커맨드를 가리므로** 삭제하세요. 같은 이름의 프로젝트
> 커맨드가 플러그인 커맨드보다 우선합니다. v0.2.0 방식으로 설치한 `.claude/hooks/`와
> settings.json의 hook 등록도 제거해야 가드가 중복 실행되지 않습니다.

설치 후 새 프로젝트에서 `/tide-kickoff`로 시작하세요.

## 저장소 구조

```
.claude-plugin/   plugin.json·marketplace.json (플러그인/마켓플레이스 매니페스트)
commands/         슬래시 커맨드 6종
hooks/            hooks.json + tide-guard.sh·.ps1 (git 작업 가드)
templates/        마일스톤·완료보고서·리뷰보고서 템플릿 (형식의 단일 원본)
docs/             규약·마일스톤·보고서 (이 저장소 자체의 tide 사이클 기록)
```

## 명명 규약

- 패턴: `tide-{단계}` — 다른 플러그인·내장 스킬과 충돌하지 않도록 `tide-` 접두사로 묶음
- `/tide-` 까지 입력하면 탭 자동완성으로 6종이 함께 표시됩니다

## 규약

마일스톤 문서 형식, 보고서 형식, 단계별 금지 행위, 버전·CHANGELOG 규칙은
[docs/conventions.md](docs/conventions.md)를 참고하세요.

## CHANGELOG

### [v0.3.0]
- **Claude Code 플러그인으로 전환** — `/plugin marketplace add Jongh/tide` → `/plugin install tide@tide` 한 번으로 커맨드 6종 + tide-guard hook이 함께 활성화 (`.claude-plugin/plugin.json`·`marketplace.json` 신설, 커맨드를 `commands/`로 이동)
- tide-guard hook을 플러그인이 직접 제공 — `hooks/hooks.json`이 `${CLAUDE_PLUGIN_ROOT}` 경로로 등록, 프로젝트별 hook 설치 절차 폐지. kickoff 내장 스크립트 제거로 가드 원본이 `hooks/` 한 곳으로 단일화
- 템플릿 파일화 — `templates/`(마일스톤·완료보고서·리뷰보고서)가 형식의 단일 원본. milestone/impl/review 커맨드가 템플릿을 직접 읽어 생성 (부재 시 폴백)
- 버전 파일 목록에 `.claude-plugin/plugin.json` 추가 (release/status/kickoff)
- README에 구버전(≤v0.2.0) 마이그레이션 노트 추가 — 수동 복사 사본의 플러그인 커맨드 섀도잉, 구 hook 설치물 중복 실행 주의

### [v0.2.0]
- `/tide-status` 신설 — 사이클 현재 상태(마일스톤/보고서/판정/버전/phase)와 다음 권장 커맨드 제시 (읽기 전용)
- tide-guard hook 도입 — `.tide/phase`가 `release`가 아닌 동안 git commit/tag/push를 기계적으로 차단 (`hooks/tide-guard.sh`·`.ps1`, `/tide-kickoff`가 대상 프로젝트 `.claude/hooks/`에 설치)
- 상태 파일(`.tide/phase`) 규약 도입 — 각 커맨드가 시작/종료 시 단계 기록, `.gitignore` 처리
- 전제조건 검사 — impl(마일스톤 문서 존재)·review(완료보고서 존재) 미충족 시 안내 후 중단
- release 프리플라이트 — 리뷰 판정 "가능" + 테스트 통과 + 워킹트리 확인 후에만 git 작업 진행
- `/tide-impl M{N}` 번호 지정 인자 — 특정 마일스톤 재실행·이어하기 지원
- 규약 문서에 상태 파일·tide-guard·단계별 강제 수단 명시

### [v0.1.0]
- tide 워크플로우 슬래시 커맨드 5종 신설: `tide-kickoff`·`tide-milestone`·`tide-impl`·`tide-review`·`tide-release`
- impl/review 단계 작업보고서(`docs/reports/M{N}-impl.md`·`M{N}-review.md`) 규약 포함
- 부수효과 분리 원칙(impl/review는 git 금지, release만 git 조작) 명문화
- `docs/conventions.md` 규약 문서 추가
