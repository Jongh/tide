# tide

porpoise의 개발 방법론(마일스톤 → 구현 → 리뷰 → 릴리즈)을 **프로젝트 독립적인 Claude Code
슬래시 커맨드**로 옮긴 워크플로우 모음입니다. 어떤 저장소에든 얹어 동일한 개발 리듬과
문서화 규율을 그대로 적용할 수 있습니다.

## 사이클

```
/tide:kickoff  →  /tide:milestone  →  /tide:impl  →  /tide:review  →  /tide:release vX.Y.Z
   (세팅)           (계획)             (구현·테스트)    (리뷰·판정)       (배포)

              └──────────── /tide:cycle ────────────┘  (release 직전 정지)

              /tide:status — 언제든 현재 위치와 다음 커맨드 확인 (읽기 전용)
```

`/tide:cycle`은 `milestone → impl → review`를 한 번에 이어 실행하고(impl 단계에서
마일스톤 태스크의 `(deps:)`를 읽어 독립 태스크는 **서브에이전트로 동시 실행**·의존
태스크는 순차로 진행 — 변경 파일이 겹치면 그 부분만 순차 폴백), git 작업을 하는
`release`만은 자동 체이닝에서 빼고 직전에 멈춰 안내합니다.

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
| `/tide:kickoff` | 워크플로우 골격 생성 (+ 진행 중 프로젝트면 구조 문서화) | `docs/milestones/`·`docs/reports/`·`CHANGELOG.md`·`docs/conventions.md`·`docs/project-context.md` |
| `/tide:milestone` | 다음 마일스톤 문서 생성 | `docs/milestones/M{N}.md` |
| `/tide:impl [M번호]` | 마일스톤대로 구현 + 테스트 (생략 시 최신, 번호 지정 시 재실행) | 코드 + `docs/reports/M{N}-impl.md` (완료보고서) |
| `/tide:review` | 비판적 리뷰 + 릴리즈 판정 | `docs/reports/M{N}-review.md` (리뷰보고서) |
| `/tide:cycle [주제/M번호]` | `milestone→impl→review` 자동 체이닝 (deps 기반 실제 병렬[서브에이전트]/순차, release 직전 정지) | 위 단계들의 산출물 + 릴리즈 안내 |
| `/tide:release` | 프리플라이트 → 버전 범프 → CHANGELOG → commit → tag → push | 릴리즈 커밋·태그 |
| `/tide:retro` | 누적 사이클 회고 — 반복 문제·수용 트레이드오프·미반영 후속 집계 (읽기 전용) | `docs/reports/retro.md` (회고 문서) |
| `/tide:status` | 사이클 현재 상태 + 다음 권장 커맨드 (읽기 전용) | (없음 — 보고만) |

## 설치

### 플러그인 (권장)

```
/plugin marketplace add Jongh/tide
/plugin install tide@tide
```

커맨드 8종과 tide-guard hook이 **함께** 활성화됩니다. 프로젝트별 hook 설치 절차는
없습니다 — 가드는 플러그인이 `${CLAUDE_PLUGIN_ROOT}` 경로의 hook으로 직접 제공합니다.

> Windows 참고: hook은 `sh`로 실행되므로 Git for Windows가 필요합니다
> (Claude Code의 Bash 도구가 요구하는 것과 동일한 전제).

### 수동 복사 (비권장 — 가드 hook 미포함)

```bash
mkdir -p ~/.claude/skills
cp -r skills/* ~/.claude/skills/
```

이 경로는 tide-guard hook이 설치되지 않아 git 금지가 프롬프트 수준으로만 동작하며,
호출명도 네임스페이스 없는 `/kickoff`·`/milestone` 형태가 되어 다른 스킬과 충돌할 수
있습니다.

> **구버전에서 마이그레이션**:
> - **≤v0.2.0 (수동 복사)**: 프로젝트나 전역 `.claude/commands/`에 복사해 둔
>   `tide-*.md` 사본은 **플러그인 커맨드를 가리므로** 삭제하세요. v0.2.0 방식으로
>   설치한 `.claude/hooks/`와 settings.json의 hook 등록도 제거해야 가드가 중복
>   실행되지 않습니다.
> - **v0.3.0 → v0.4.0**: 호출명이 `/tide:tide-status`에서 `/tide:status` 형태로
>   바뀌었습니다. `claude plugin marketplace update tide` 후 재설치하면 새 호출명이
>   적용됩니다.

설치 후 프로젝트에서 `/tide:kickoff`로 시작하세요 (신규·진행 중 프로젝트 모두 지원).

## 저장소 구조

```
.claude-plugin/   plugin.json·marketplace.json (플러그인/마켓플레이스 매니페스트)
skills/           스킬 8종 — {단계}/SKILL.md (+ milestone·impl·review·retro는 template.md 동봉)
hooks/            hooks.json + tide-guard.sh·.ps1 (git 작업 가드)
docs/             규약·마일스톤·보고서·프로젝트 컨텍스트 (이 저장소 자체의 tide 사이클 기록)
```

## 명명 규약

- 호출: `/tide:{단계}` — 플러그인 네임스페이스가 내장 스킬·다른 플러그인과의 충돌을 방지
- `/tide:` 까지 입력하면 탭 자동완성으로 8종이 함께 표시됩니다

## 규약

마일스톤 문서 형식, 보고서 형식, 단계별 금지 행위, 버전·CHANGELOG 규칙은
[docs/conventions.md](docs/conventions.md)를 참고하세요.

## CHANGELOG

### [v0.11.0]
- **안정화 라운드 + 병렬 디스패치 런타임 실증**: M9의 "독립 태스크 서브에이전트 동시 디스패치"를 **실제로 사용해 이 사이클을 구현** — 비중첩 태스크 3개를 한 메시지에서 병렬 디스패치(폴백 없음, 벽시계 = 합산 아닌 최댓값)해 M9 병렬 기능의 **첫 런타임 실증**
- `skills/release/SKILL.md`에 "운영 주의" 절: phase↔git 분리(가드가 명령 전 phase를 읽음)·멀티라인 커밋 메시지는 환경 문법에 맞춤·릴리즈 노트의 제외 용어 literal 회피
- `skills/milestone/template.md`에 태스크별 "변경 파일" 권장 필드 — 병렬 겹침 감지를 휴리스틱에서 결정적으로(하위 호환, 필수 아님)
- `docs/conventions.md`에 메타 용어 누수 방지 + 릴리즈 빌드 출력 검증 규약 추가(snippets로 사이트 반영), `docs/project-context.md` 반영. 매니페스트 무수정·자동 발견

### [v0.10.0]
- **진짜 병렬 실행 신설**: `/tide:impl`·`/tide:cycle`의 impl 단계가 deps 위상에서 독립(무의존) 태스크를 서브에이전트로 **동시 디스패치**(같은 메시지에 복수 Agent 호출 = 동시 실행, 레벨 간 배리어) — "병렬은 스케줄링 해석일 뿐"이던 것을 실제 동시 실행으로 전환. 메커니즘·전달 컨텍스트·반환 계약은 `skills/impl/SKILL.md`의 "병렬 디스패치" 절이 단일 원본
- 파일 충돌 안전장치(예상 변경 파일 겹침 → 겹치는 태스크만 순차 폴백, 워크트리 격리는 선택·기본 비활성), 결과 병합(단일 impl 보고서)·부분 실패 처리, tide-guard 정합(서브에이전트도 phase=impl이라 git 차단). Agent 부재·레벨 단일 태스크·deps 이상은 순차 폴백(하위 호환)
- `skills/cycle/SKILL.md`의 "실제 병렬 실행 수단은 구현 판단에 맡긴다" 문장을 impl 단일 원본 참조로 교체, `docs/conventions.md`·`README.md`·`docs/project-context.md` 반영(매니페스트 무수정·자동 발견)
- 회귀 수정: v0.9.0 changelog 노트의 검증 문장에 들어간 외부 저장소명 literal이 단일 원본화(snippets)로 사이트에 유입된 것을 리워딩으로 제거 — 사이트 외부 귀속 표기 0건 회복

### [v0.9.0]
- **tide-guard 차단 메시지 한국어화**: git commit/tag/push 차단 안내를 한국어로("'{phase}' 단계에서는 git commit/tag/push가 차단됩니다. git 작업은 /tide:release 단계에서만 허용됩니다") — `tide-guard.sh`·`.ps1` 동일 문구. **인코딩 규약 확정**: sh=BOM 없는 UTF-8(Git Bash shebang 보호), ps1=BOM 포함 UTF-8(Windows PowerShell 5.1 한글 보존)
- **사이트 문서 단일 원본화**: `pymdownx.snippets`로 사이트 `conventions`·`changelog`가 저장소 원본 `docs/conventions.md`·`CHANGELOG.md`를 인클루드 — 사본 이중 갱신 부채 제거. 원본 도입부의 외부 귀속은 섹션 마커로 사이트에서 제외(빌드 출력 0건 유지)
- **패키지 위생 재확정**: 설치가 추적 파일 트리를 미러링함을 캐시로 실측, 공식 제외 수단 부재로 수용 재확정(`docs/project-context.md` "배포 위생" 절)
- 검증: `mkdocs build --strict` 통과 + 인클루드 정상 + 빌드 출력 외부 귀속 표기 0건 실증, 편집본 가드 sh 한국어 차단(exit 2) 실증

### [v0.8.0]
- **tide 소개 GitHub Pages 사이트 신설**: MkDocs Material 기반 한국어 문서 사이트(홈·시작하기·개념·커맨드 레퍼런스·규약·변경 이력 6페이지)를 `site/`에 구성하고, GitHub Actions(`.github/workflows/deploy-pages.yml`)로 `main` 푸시 시 자동 빌드·배포 — 사이트 소스를 tide 사이클 기록(`docs/`)과 격리(`site/`, `site_dir: _build` 명시)해 충돌 회피
- 콘텐츠는 `README.md`·`docs/conventions.md`·`CHANGELOG.md`·`skills/*/SKILL.md`에서 정제, tide를 독립 워크플로우로 서술(외부 저장소 귀속 표현 제외). 사이클 다이어그램은 Mermaid로 재구성. **원본 문서는 무수정**
- `mkdocs build --strict` 통과 검증(격리 venv), `site/` 전체 외부 귀속 0건, `.gitignore`에 빌드 출력 `site/_build/` 추가
- 배포에는 저장소 Settings → Pages → Source를 "GitHub Actions"로 1회 전환 필요(코드 외 수동 단계)

### [v0.7.0]
- **`/tide:retro` 회고 신설**: 누적된 마일스톤·보고서를 가로질러 반복 문제·이슈 군집, 수용된 트레이드오프, "후속"의 반영/미반영 추적, 릴리즈 판정·버전 추이를 집계하는 읽기 전용 회고 스킬 — 산출물은 갱신형 단일 문서 `docs/reports/retro.md`(회고 시점마다 최상단 누적), 형식은 `skills/retro/template.md` 동봉
- `/tide:status`와 동일한 읽기 전용 원칙 — 회고 문서 하나만 생성/갱신하고 `.tide/phase`·git에는 손대지 않음
- `docs/conventions.md`(보고서 절·금지 행위 표)·`README.md`(커맨드 표)·`docs/project-context.md`에 retro 반영, 스킬 8종으로 갱신
- 첫 회고 산출 — M1~M5 사이클을 집계한 `docs/reports/retro.md` 생성(반복 군집 4·수용 트레이드오프 6·후속 반영 7/미반영 3·버전 추이 v0.2.0~v0.6.0 전부 minor)

### [v0.6.0]
- **`/tide:cycle` 오케스트레이션 신설**: `milestone → impl → review`를 한 번의 호출로 자동 체이닝 — 각 단계 진입 시 `.tide/phase` 기록, 사이클 종료 시 `idle` 복원, 한 단계라도 전제조건 미충족·실패 시 사이클 전체를 중단하고 중단 지점·사유 보고. git 작업을 하는 `release`만은 체이닝에서 제외하고 review "가능" 판정 후 `/tide:release vX.Y.Z`를 안내 (부수효과 분리·tide-guard와 정합)
- impl 단계에서 마일스톤 태스크의 `(deps:)` 표기를 파싱해 독립=병렬·의존=순차로 스케줄링하는 규칙 명시 (순환 의존·미존재 의존 ID는 감지·보고 후 순차 폴백)
- 무인자 호출 시 최대 번호 마일스톤의 보고서 상태로 시작점 3분기 (impl 없음→impl / impl만 있음→review 이어하기 / 둘 다 완료→새 milestone)
- 신규 스킬이 매니페스트 수정 없이 `skills/*/SKILL.md` 자동 발견됨을 확인 — `plugin.json`·`marketplace.json` 무변경
- `docs/conventions.md`·`README.md`·`docs/project-context.md`에 cycle 반영 (사이클 다이어그램·금지 행위 표·커맨드 표·스킬 7종)

### [v0.5.0]
- **브라운필드 킥오프**: `/tide:kickoff`가 대상 저장소를 신규/진행-중으로 판별(커밋 이력·기존 산출물·소스 규모 기준)하고, 진행-중이면 코드베이스를 조사해 `docs/project-context.md`(스택·디렉터리 구조·진입점·도메인 개념)를 생성 — 이후 단계가 매번 재조사하지 않도록
- `/tide:milestone`·`/tide:impl`이 `docs/project-context.md`가 있으면 먼저 읽어 기존 구조를 파악(조건부 — 없으면 평소대로, 하위 호환)
- `docs/conventions.md`에 "프로젝트 컨텍스트" 절 신설, README 커맨드 표·저장소 구조·설치 절을 브라운필드 동작에 맞게 갱신
- 로드맵 마일스톤 추가 — M5(`/tide:cycle` 오케스트레이션)·M6(`/tide:retro` 회고) 문서를 독립 진행 가능하도록 작성

### [v0.4.0]
- **호출명 개편**: `/tide:tide-status` → `/tide:status` — 커맨드 6종을 공식 권장 `skills/{이름}/SKILL.md` 구조로 전환하며 `tide-` 접두사 중복 제거 (기능·frontmatter 동등, 이력 보존 이동)
- 템플릿을 각 스킬에 동봉 — `skills/{milestone,impl,review}/template.md`, 참조는 `${CLAUDE_SKILL_DIR}/template.md`로 전환 (중앙 `templates/` 폐지)
- 저장소 전체 호출 표기를 실동작과 일치 — 스킬 상호 안내, 가드 차단 메시지(sh·ps1), README·conventions
- 패키지 위생 조사 종결 — 플러그인 파일 제외 수단은 공식 미지원으로 확인, 수용 결정 (근거: M3 보고서)
- README 마이그레이션 노트에 v0.3.0 → v0.4.0 호출명 변경 안내 추가

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
