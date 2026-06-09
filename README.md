# tide

porpoise의 개발 방법론(마일스톤 → 구현 → 리뷰 → 릴리즈)을 **프로젝트 독립적인 Claude Code
슬래시 커맨드**로 옮긴 워크플로우 모음입니다. 어떤 저장소에든 얹어 동일한 개발 리듬과
문서화 규율을 그대로 적용할 수 있습니다.

## 사이클

```
/tide-kickoff  →  /tide-milestone  →  /tide-impl  →  /tide-review  →  /tide-release vX.Y.Z
   (세팅)           (계획)             (구현·테스트)    (리뷰·판정)       (배포)
```

각 단계는 **부수효과를 엄격히 분리**합니다 — `impl`·`review`는 절대 git 작업을 하지 않고
(코드·보고서만 남김), git commit/tag/push는 오직 `release`에서만 일어납니다.

## 커맨드

| 커맨드 | 역할 | 산출물 |
|---|---|---|
| `/tide-kickoff` | 새 프로젝트에 워크플로우 골격 생성 | `docs/milestones/`·`docs/reports/`·`CHANGELOG.md`·`docs/conventions.md` |
| `/tide-milestone` | 다음 마일스톤 문서 생성 | `docs/milestones/M{N}.md` |
| `/tide-impl` | 최신 마일스톤대로 구현 + 테스트 | 코드 + `docs/reports/M{N}-impl.md` (완료보고서) |
| `/tide-review` | 비판적 리뷰 + 릴리즈 판정 | `docs/reports/M{N}-review.md` (리뷰보고서) |
| `/tide-release` | 버전 범프 → CHANGELOG → commit → tag → push | 릴리즈 커밋·태그 |

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

설치 후 새 프로젝트에서 `/tide-kickoff`로 시작하세요.

## 명명 규약

- 패턴: `tide-{단계}` — 다른 플러그인·내장 스킬과 충돌하지 않도록 `tide-` 접두사로 묶음
- `/tide-` 까지 입력하면 탭 자동완성으로 5종이 함께 표시됩니다

## 규약

마일스톤 문서 형식, 보고서 형식, 단계별 금지 행위, 버전·CHANGELOG 규칙은
[docs/conventions.md](docs/conventions.md)를 참고하세요.

## CHANGELOG

### [v0.1.0]
- tide 워크플로우 슬래시 커맨드 5종 신설: `tide-kickoff`·`tide-milestone`·`tide-impl`·`tide-review`·`tide-release`
- impl/review 단계 작업보고서(`docs/reports/M{N}-impl.md`·`M{N}-review.md`) 규약 포함
- 부수효과 분리 원칙(impl/review는 git 금지, release만 git 조작) 명문화
- `docs/conventions.md` 규약 문서 추가
