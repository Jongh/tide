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
`/tide-kickoff`가 설치하는 PreToolUse hook이 `.tide/phase` 상태 파일을 보고,
`release` 단계가 아닌 동안 git commit/tag/push 명령을 차단합니다. 또한 각 단계는
시작 전 **전제조건 검사**(impl: 마일스톤 존재, review: 완료보고서 존재)를 하고,
`release`는 **프리플라이트**(리뷰 판정 "가능" + 테스트 통과 + 워킹트리 확인)를
통과해야 git 작업을 시작합니다.

## 커맨드

| 커맨드 | 역할 | 산출물 |
|---|---|---|
| `/tide-kickoff` | 새 프로젝트에 워크플로우 골격 + 가드 hook 설치 | `docs/milestones/`·`docs/reports/`·`CHANGELOG.md`·`docs/conventions.md`·`.claude/hooks/tide-guard.*` |
| `/tide-milestone` | 다음 마일스톤 문서 생성 | `docs/milestones/M{N}.md` |
| `/tide-impl [M번호]` | 마일스톤대로 구현 + 테스트 (생략 시 최신, 번호 지정 시 재실행) | 코드 + `docs/reports/M{N}-impl.md` (완료보고서) |
| `/tide-review` | 비판적 리뷰 + 릴리즈 판정 | `docs/reports/M{N}-review.md` (리뷰보고서) |
| `/tide-release` | 프리플라이트 → 버전 범프 → CHANGELOG → commit → tag → push | 릴리즈 커밋·태그 |
| `/tide-status` | 사이클 현재 상태 + 다음 권장 커맨드 (읽기 전용) | (없음 — 보고만) |

## 설치

### 프로젝트 단위
대상 저장소의 `.claude/commands/`로 커맨드 파일을 복사합니다.

```bash
mkdir -p <your-project>/.claude/commands
cp .claude/commands/tide-*.md <your-project>/.claude/commands/
```

### 전역 (모든 프로젝트에서 사용)
```bash
mkdir -p ~/.claude/commands
cp .claude/commands/tide-*.md ~/.claude/commands/
```

설치 후 새 프로젝트에서 `/tide-kickoff`로 시작하세요. tide-guard hook
(git 작업 차단 가드, [hooks/](hooks/) 원본)은 별도로 복사할 필요 없이
`/tide-kickoff`가 대상 프로젝트의 `.claude/hooks/`에 설치합니다.

## 명명 규약

- 패턴: `tide-{단계}` — 다른 플러그인·내장 스킬과 충돌하지 않도록 `tide-` 접두사로 묶음
- `/tide-` 까지 입력하면 탭 자동완성으로 6종이 함께 표시됩니다

## 규약

마일스톤 문서 형식, 보고서 형식, 단계별 금지 행위, 버전·CHANGELOG 규칙은
[docs/conventions.md](docs/conventions.md)를 참고하세요.

## CHANGELOG

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
