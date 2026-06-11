# 규약

tide는 **마일스톤 → 구현 → 리뷰 → 릴리즈** 사이클을 프로젝트 독립적인 슬래시
커맨드로 구현한 워크플로우입니다. 이 페이지는 각 단계가 따르는 형식·규칙을
정의합니다. 설계 원칙의 "왜"는 **[개념](concepts.md)** 을 참고하세요.

## 사이클

```
/tide:kickoff  →  /tide:milestone  →  /tide:impl  →  /tide:review  →  /tide:release vX.Y.Z
   (세팅)           (계획)             (구현·테스트)    (리뷰·판정)       (배포)

                  └──────────── /tide:cycle ────────────┘  (release 직전 정지)

                          /tide:status — 언제든 현재 위치 확인 (읽기 전용)
```

**수동 단계별 호출 vs `/tide:cycle` 자동 체이닝**: 평소엔 각 단계를 직접 호출하지만,
`/tide:cycle`은 `milestone → impl → review`를 한 번에 이어 실행합니다(필요 시
milestone부터, `M{N}` 인자면 impl부터). `release`만은 자동 체이닝에서 **제외** — git
작업을 하는 유일한 단계이므로 review "가능" 판정 후 사이클을 끝내고 사용자에게
`/tide:release vX.Y.Z`를 넘깁니다. cycle은 각 단계의 전제조건을 그대로 검사하고, 한
단계가 미충족·실패로 멈추면 사이클 전체를 중단하며 중단 지점·사유를 보고합니다.
impl 단계에서는 마일스톤 태스크의 `(deps:)` 표기를 읽어 독립 태스크는 병렬, 의존
태스크는 순차로 스케줄링합니다.

## 마일스톤 문서

- 위치: `docs/milestones/M{N}.md` (가장 큰 번호 + 1, 없으면 M1)
- 필수 섹션 7개: **목표 / 배경 / 태스크 목록 / 태스크 상세 / 파일 변경 요약 / 완료
  기준 / 메타데이터**
- 태스크 ID: `M{N}-T01`, `M{N}-T02` …
- 태스크는 한 번에 끝낼 수 있는 크기로 분해하고, 가능한 한 서로 독립적으로 설계
- 선행 의존이 있으면 태스크 끝에 `(deps: M{N}-T01, …)` 로 표기
- `/tide:impl M{N}` 처럼 번호를 지정해 특정 마일스톤을 재실행·이어하기 할 수 있습니다

## 보고서

- **완료 보고서** `docs/reports/M{N}-impl.md`
  : 개요 / 태스크별 수행 내용 / 변경 파일 요약 / 테스트 결과 / 미해결·후속 메모
- **리뷰 보고서** `docs/reports/M{N}-review.md`
  : 비판점(심각도: 차단/권장/사소) / 수정 내용 / 검증 / 릴리즈 판정(+추천 버전) / 다음 단계
- **회고 문서** `docs/reports/retro.md` (`/tide:retro` 산출물 — 갱신형 단일)
  : 집계 범위 / 반복된 문제·이슈 군집 / 수용된 트레이드오프 / 후속 항목 추적 / 릴리즈
  판정·버전 추이 / 회고 메모. 마일스톤별이 아니라 **누적 사이클을 가로질러** 봅니다.
  회고 시점마다 문서 최상단에 새 섹션을 누적합니다(이력 보존).
- 동일 마일스톤 재실행 시 기존 보고서를 갱신합니다.

## 템플릿

마일스톤·보고서 형식의 단일 원본은 각 스킬 디렉터리에 동봉된 `template.md`입니다
(`skills/milestone/template.md` 등). 스킬은 이를 읽어 그 구조 그대로 문서를 생성합니다.
형식을 바꾸려면 스킬의 산문이 아니라 템플릿 파일을 수정합니다.

## 버전 · CHANGELOG

- 버전 파일은 프로젝트 스택에 맞춤: `Cargo.toml` / `package.json` / `pyproject.toml` 등
- 버전은 SemVer. 리뷰 단계에서 major/minor/patch를 추천합니다.
- `CHANGELOG.md` 최상단과 `README.md`의 `## CHANGELOG` 섹션 최상단에 **동일한** 릴리즈
  노트를 둡니다.
- 커밋 메시지: `Release {버전}: {핵심 변경사항 한 줄 요약}`

## 단계별 금지 행위 요약

| 단계 | 금지 | 강제 수단 |
|---|---|---|
| kickoff | git 작업 | 프롬프트 |
| milestone | 작업지시서 생성 / 코드 구현 / 테스트 실행 / git 작업 | 프롬프트 + hook(git) |
| impl | 코드 리뷰 / git commit / git tag / git push | 프롬프트 + hook(git) |
| review | git commit / git tag / git push | 프롬프트 + hook(git) |
| status | 파일 생성·수정 / git 작업 | 프롬프트 |
| retro | 회고 문서(`docs/reports/retro.md`) 외 파일 생성·수정 / `.tide/phase` 변경 / git 작업 | 프롬프트 |
| cycle | git commit / git tag / git push (release 단계는 체이닝에서 제외) | 프롬프트 + hook(git) |
| release | (없음 — 유일하게 git 조작 허용) | 프리플라이트 통과 필요 |

상태 파일(`.tide/phase`)·tide-guard hook의 동작은 **[개념](concepts.md)** 에서 자세히
다룹니다.
