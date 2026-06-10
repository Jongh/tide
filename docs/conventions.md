# tide 규약 (conventions)

tide는 porpoise의 개발 방법론(마일스톤 → 구현 → 리뷰 → 릴리즈)을 프로젝트
독립적인 슬래시 커맨드로 옮긴 워크플로우다. 이 문서는 각 단계가 따르는 규약을 정의한다.

## 사이클

```
/tide-kickoff  →  /tide-milestone  →  /tide-impl  →  /tide-review  →  /tide-release vX.Y.Z
   (세팅)           (계획)             (구현·테스트)    (리뷰·판정)       (배포)

                          /tide-status — 언제든 현재 위치 확인 (읽기 전용)
```

**핵심 원칙 — 부수효과 분리**: `impl`·`review`는 **절대 git 작업을 하지 않는다**(문서·코드만
남김). git commit/tag/push는 오직 `release`에서만 일어난다. impl/review가 남긴 보고서는
다음 `release` 커밋에 함께 포함된다. 이 원칙은 프롬프트 지시에 더해 **tide-guard hook**으로
기계적으로 강제된다(아래 참조).

## 상태 파일 (.tide/phase)

- 위치: `.tide/phase` — 현재 단계명 한 줄 (`milestone` / `impl` / `review` / `release` / `idle`)
- 각 커맨드는 시작 시 자기 단계명을 기록하고, 최종 보고 직전 `idle`로 되돌린다
  (`/tide-status`는 읽기 전용이라 변경하지 않음)
- `.tide/`는 `.gitignore` 대상이다 (로컬 상태일 뿐 커밋하지 않음)

## tide-guard hook

- PreToolUse(Bash|PowerShell 매처) hook. `/tide-kickoff`가 `.claude/hooks/tide-guard.sh`·
  `.ps1`을 설치하고 `.claude/settings.json`에 등록한다.
- 동작: `.tide/phase`가 `release`가 **아닌** 동안 `git commit` / `git tag` / `git push`
  패턴의 셸 명령을 차단한다(exit 2 + 안내 메시지).
- 상태 파일이 없으면 아무것도 차단하지 않는다 — tide를 쓰지 않는 프로젝트나
  사용자의 수동 git 작업(idle 상태가 아니라 파일 자체가 없는 경우)에 영향을 주지 않는다.
- **`idle`에서도 차단된다** — tide 도입 후에는 Claude를 통한 git commit/tag/push가 항상
  `/tide-release`로만 일어나는 것이 의도된 동작이다. tide 사이클 밖에서 Claude에게
  git 작업을 시키려면 `.tide/phase` 파일을 삭제해 가드를 해제한다.
- 원본 스크립트는 이 저장소 `hooks/`에 있으며, kickoff 커맨드에 동일 내용이 내장돼
  있다(전역 설치 시에도 자급자족하도록). 둘을 수정할 때는 반드시 함께 갱신한다.

## 전제조건 · 프리플라이트

| 커맨드 | 시작 전 검사 | 실패 시 |
|---|---|---|
| `/tide-impl` | 대상 마일스톤 문서 존재 | 구현 없이 `/tide-milestone` 안내 후 중단 |
| `/tide-review` | `docs/reports/M{N}-impl.md` 존재 | 리뷰 없이 `/tide-impl` 안내 후 중단 |
| `/tide-release` | ① review 판정 "가능" ② 테스트 통과 ③ 워킹트리 확인 | git 작업 없이 사유 보고 후 중단 |

release 1번 검사는 사용자가 버전 인자와 함께 강행 의사를 명시한 경우에만 경고 후 통과할 수 있다.

## 마일스톤 문서

- 위치: `docs/milestones/M{N}.md` (가장 큰 번호 + 1, 없으면 M1)
- 필수 섹션 7개: **목표 / 배경 / 태스크 목록 / 태스크 상세 / 파일 변경 요약 / 완료 기준 / 메타데이터**
- 태스크 ID: `M{N}-T01`, `M{N}-T02` …
- 태스크는 한 번에 끝낼 수 있는 크기로 분해하고, 가능한 한 서로 독립적으로 설계
- 선행 의존이 있으면 태스크 끝에 `(deps: M{N}-T01, …)` 로 표기
- `/tide-impl M{N}` 처럼 번호를 지정해 특정 마일스톤을 재실행·이어하기 할 수 있다

## 보고서

- 완료 보고서: `docs/reports/M{N}-impl.md`
  - 개요 / 태스크별 수행 내용 / 변경 파일 요약 / 테스트 결과 / 미해결·후속 메모
- 리뷰 보고서: `docs/reports/M{N}-review.md`
  - 비판점(심각도: 차단/권장/사소) / 수정 내용 / 검증 / 릴리즈 판정(+추천 버전) / 다음 단계
- 동일 마일스톤 재실행 시 기존 보고서를 갱신한다.

## 버전 · CHANGELOG

- 버전 파일은 프로젝트 스택에 맞춤: `Cargo.toml` / `package.json` / `pyproject.toml` 등
- 버전은 SemVer. 리뷰 단계에서 major/minor/patch를 추천한다.
- `CHANGELOG.md` 최상단과 `README.md`의 `## CHANGELOG` 섹션 최상단에 **동일한** 릴리즈 노트를 둔다.
- 커밋 메시지: `Release {버전}: {핵심 변경사항 한 줄 요약}`

## 단계별 금지 행위 요약

| 단계 | 금지 | 강제 수단 |
|---|---|---|
| kickoff | git 작업 | 프롬프트 |
| milestone | 작업지시서 생성 / 코드 구현 / 테스트 실행 / git 작업 | 프롬프트 + hook(git) |
| impl | 코드 리뷰 / git commit / git tag / git push | 프롬프트 + hook(git) |
| review | git commit / git tag / git push | 프롬프트 + hook(git) |
| status | 파일 생성·수정 / git 작업 | 프롬프트 |
| release | (없음 — 유일하게 git 조작 허용) | 프리플라이트 통과 필요 |
