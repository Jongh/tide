# 개념

tide를 떠받치는 설계 원칙입니다. 형식·규칙의 세부는 **[규약](conventions.md)** 에
있고, 이 페이지는 "왜 이렇게 동작하는가"를 설명합니다.

## 부수효과 분리

tide의 핵심 원칙입니다. **`impl`·`review`는 절대 git 작업을 하지 않습니다** — 코드와
보고서만 남깁니다. git commit/tag/push는 오직 **`release`** 에서만 일어납니다.
impl/review가 남긴 보고서는 다음 `release` 커밋에 함께 포함됩니다.

이 분리 덕분에 구현·리뷰 중에 의도치 않은 커밋이 끼어들지 않고, "무엇이 언제
배포됐는가"가 release 커밋 하나로 깔끔하게 모입니다. 원칙은 프롬프트 지시에 더해
아래 **tide-guard hook**으로 기계적으로 강제됩니다.

## 상태 파일 `.tide/phase`

- 위치: `.tide/phase` — 현재 단계명 한 줄
  (`milestone` / `impl` / `review` / `release` / `idle`).
- 각 커맨드는 시작 시 자기 단계명을 기록하고, 최종 보고 직전 `idle`로 되돌립니다
  (`/tide:status`·`/tide:retro`는 읽기 전용이라 변경하지 않습니다).
- `.tide/`는 `.gitignore` 대상입니다 — 로컬 상태일 뿐 커밋하지 않습니다.

## tide-guard hook

`.tide/phase` 상태를 보고 git 작업을 기계적으로 막는 PreToolUse hook입니다.

- **플러그인이 직접 제공합니다** — `hooks/hooks.json`이
  `${CLAUDE_PLUGIN_ROOT}/hooks/tide-guard.sh`를 등록하므로 플러그인 설치만으로
  활성화되고, 프로젝트별 설치 절차가 없습니다.
- **동작**: `.tide/phase`가 `release`가 **아닌** 동안 `git commit` / `git tag` /
  `git push` 패턴의 셸 명령을 차단합니다(exit 2 + 안내 메시지).
- **상태 파일이 없으면 아무것도 차단하지 않습니다** — tide를 쓰지 않는 프로젝트나
  사용자의 수동 git 작업에는 영향을 주지 않습니다.
- **`idle`에서도 차단됩니다** — tide 도입 후에는 Claude를 통한 git commit/tag/push가
  항상 `/tide:release`로만 일어나는 것이 의도된 동작입니다. tide 사이클 밖에서
  Claude에게 git 작업을 시키려면 `.tide/phase` 파일을 삭제해 가드를 해제합니다.

!!! note "Windows"
    가드 스크립트 원본은 `hooks/tide-guard.sh` 한 곳이며, `tide-guard.ps1`은 `sh`를 쓸
    수 없는 환경을 위한 보조 사본입니다. Windows에서는 Git for Windows의 `sh`로
    실행됩니다.

## 전제조건 · 프리플라이트

각 단계는 시작 전 전제조건을 검사하고, 미충족이면 작업 없이 안내 후 멈춥니다.

| 커맨드 | 시작 전 검사 | 실패 시 |
|---|---|---|
| `/tide:impl` | 대상 마일스톤 문서 존재 | 구현 없이 `/tide:milestone` 안내 후 중단 |
| `/tide:review` | `docs/reports/M{N}-impl.md` 존재 | 리뷰 없이 `/tide:impl` 안내 후 중단 |
| `/tide:release` | ① review 판정 "가능" ② 테스트 통과 ③ 워킹트리 확인 | git 작업 없이 사유 보고 후 중단 |

`release`의 ① 검사는 사용자가 버전 인자와 함께 강행 의사를 명시한 경우에만 경고 후
통과할 수 있습니다.

## 프로젝트 컨텍스트

`/tide:kickoff`는 대상 저장소가 신규인지 진행 중인지 판별합니다(커밋 이력·기존
산출물·소스 규모 기준). **진행 중**이면 코드베이스를 조사해 `docs/project-context.md`
(스택·디렉터리 구조·진입점·도메인 개념)를 만들어, 이후 `/tide:milestone`·`/tide:impl`이
매번 재조사하지 않고 기존 구조를 참조하게 합니다. **신규(빈)** 프로젝트면 이 문서는
만들지 않고 골격만 세웁니다.
