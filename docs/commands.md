# 커맨드 레퍼런스

tide가 제공하는 슬래시 커맨드의 역할·인자·산출물·금지 행위를 한곳에 모은 레퍼런스다.

<!-- 아래 [start:body]~[end:body]는 사이트(site/docs/commands.md)가 pymdownx.snippets로
     본문만 인클루드하기 위한 마커다. 위 도입 문단은 일부러 마커 밖에 두어 사이트에서는
     사이트 전용(외부 귀속 없는) 도입부로 대체된다. 렌더에는 영향 없음. -->
<!-- --8<-- [start:body] -->
tide는 11종의 슬래시 커맨드를 제공합니다. 호출은 모두 `/tide:{단계}` 형태이며,
`/tide:` 까지 입력하면 탭 자동완성으로 11종이 함께 표시됩니다. 앞의 8종은 단일 레포 사이클,
뒤의 3종(`fleet`·`fleet-cycle`·`fleet-verify`)은 상위 폴더에서 여러 자식 레포를 가로지르는
**멀티 레포 오케스트레이션**입니다 — 실전 사용법은 [오케스트레이션 가이드](orchestration.md).

## 한눈에 보기

| 커맨드 | 역할 | 산출물 | git |
|---|---|---|---|
| `/tide:kickoff` | 워크플로우 골격 생성 (+ 진행 중 프로젝트면 구조 문서화) | `docs/` 골격·`CHANGELOG.md`·`conventions.md`·`project-context.md` | ✗ |
| `/tide:milestone` | 다음 마일스톤 문서 생성 | `docs/milestones/M{N}.md` | ✗ |
| `/tide:impl [M번호]` | 마일스톤대로 구현 + 테스트 | 코드 + `docs/reports/M{N}-impl.md` | ✗ |
| `/tide:review` | 비판적 리뷰 + 릴리즈 판정 | `docs/reports/M{N}-review.md` | ✗ |
| `/tide:cycle [주제/M번호]` | `milestone→impl→review` 자동 체이닝 | 위 단계들의 산출물 + 릴리즈 안내 | ✗ |
| `/tide:release vX.Y.Z` | 프리플라이트 → 버전 범프 → CHANGELOG → commit → tag → push | 릴리즈 커밋·태그 | ✓ |
| `/tide:retro` | 누적 사이클 회고 (읽기 전용) | `docs/reports/retro.md` | ✗ |
| `/tide:status` | 현재 상태 + 다음 권장 커맨드 (읽기 전용) | (없음 — 보고만) | ✗ |
| `/tide:fleet [부모 경로]` | 상위 폴더의 여러 자식 tide 레포 교차 개요 (읽기 전용, 멀티 레포) | (없음 — 보고만) | ✗ |
| `/tide:fleet-cycle [부모 경로]` | 자식 레포 `milestone→review`를 의존성 순서로 교차 자동 실행 + 순서 release 핸드오프 (멀티 레포, release 제외) | 각 레포 산출물 + 순서 핸드오프 | ✗ |
| `/tide:fleet-verify [부모 경로]` | 부모 레벨 통합 훅으로 레포 간 통합 검증 + pass/fail (멀티 레포, verification-only) | (없음 — 보고만) | ✗ |

---

## `/tide:kickoff`

- **역할**: tide 워크플로우 골격을 만듭니다. 진행 중 프로젝트면 코드베이스를 조사해
  `docs/project-context.md`까지 생성합니다.
- **인자**: 없음
- **산출물**: `docs/milestones/`·`docs/reports/` 디렉터리, `CHANGELOG.md`,
  `docs/conventions.md`, (진행 중 프로젝트면) `docs/project-context.md`
- **금지**: git 작업

## `/tide:milestone`

- **역할**: 현재 맥락을 바탕으로 다음 마일스톤 문서를 만듭니다.
- **인자**: 없음(맥락에서 주제 도출). 사이클에서 주제 문자열을 받을 수 있습니다.
- **산출물**: `docs/milestones/M{N}.md` (가장 큰 번호 + 1). 목표·배경·태스크 목록·태스크
  상세·파일 변경 요약·완료 기준·메타데이터 7개 섹션.
- **금지**: 코드 구현 / 테스트 실행 / git 작업

## `/tide:impl [M번호]`

- **역할**: 마일스톤대로 구현하고 테스트를 실행한 뒤 완료보고서를 남깁니다.
- **인자**: `M{N}` (선택) — 생략 시 최신 마일스톤, 번호 지정 시 그 마일스톤을
  재실행·이어하기.
- **전제조건**: 대상 마일스톤 문서가 존재해야 합니다(없으면 `/tide:milestone` 안내 후
  중단).
- **산출물**: 코드 변경 + `docs/reports/M{N}-impl.md` (개요·태스크별 수행·변경 파일·테스트
  결과·미해결/후속 메모)
- **금지**: 코드 리뷰 / git commit·tag·push

## `/tide:review`

- **역할**: 방금 구현을 비판적으로 리뷰하고 릴리즈 판정과 추천 버전을 냅니다.
- **인자**: 없음(최신 impl 보고서 대상)
- **전제조건**: `docs/reports/M{N}-impl.md`가 존재해야 합니다(없으면 `/tide:impl` 안내 후
  중단).
- **산출물**: `docs/reports/M{N}-review.md` (비판점[차단/권장/사소]·수정 내용·검증·릴리즈
  판정+추천 버전·다음 단계)
- **금지**: git commit·tag·push

## `/tide:cycle [주제/M번호]`

- **역할**: `milestone → impl → review`를 한 번의 호출로 이어 실행합니다. `release`는
  체이닝에서 **제외**하고 직전에 멈춰 안내합니다.
- **인자**: 주제 문자열(→ milestone부터) / `M{N}`(→ 그 마일스톤 impl부터) / 없음(최신
  마일스톤 보고서 상태로 시작점 결정).
- **동작**: impl 단계에서 마일스톤 태스크의 `(deps:)`를 읽어 독립 태스크는 병렬, 의존
  태스크는 순차로 스케줄링합니다. 한 단계라도 전제조건 미충족·실패면 사이클 전체를
  중단하고 중단 지점·사유를 보고합니다.
- **산출물**: 거쳐 간 단계들의 산출물 + 릴리즈 안내
- **금지**: git commit·tag·push (release는 사용자 몫)

## `/tide:release vX.Y.Z`

- **역할**: tide에서 **git을 만지는 유일한 단계**입니다.
- **인자**: `vX.Y.Z` — 릴리즈 버전(리뷰가 추천한 값).
- **전제조건(프리플라이트)**: ① review 판정 "가능" ② 테스트 통과 ③ 워킹트리 확인.
  통과해야 git 작업을 시작합니다.
- **동작**: 버전 범프 → `CHANGELOG.md`·`README.md` 갱신 → commit → tag → push.
- **커밋 메시지**: `Release {버전}: {핵심 변경사항 한 줄 요약}`

## `/tide:retro`

- **역할**: 누적된 마일스톤·보고서를 가로질러 반복 문제·이슈 군집, 수용된 트레이드오프,
  "후속"의 반영/미반영, 릴리즈 판정·버전 추이를 집계합니다.
- **인자**: 없음
- **산출물**: `docs/reports/retro.md` (갱신형 단일 문서 — 회고 시점마다 최상단 누적)
- **금지**: 회고 문서 외 파일 생성·수정 / `.tide/phase` 변경 / git 작업 (읽기 전용)

## `/tide:status`

- **역할**: 사이클 현재 상태(마일스톤·보고서·판정·버전·phase)와 다음 권장 커맨드를
  보고합니다.
- **인자**: 없음
- **산출물**: 없음 — 보고만 (완전 읽기 전용, 파일·git·phase 무변경)

---

다음 3종은 상위 폴더 단일 세션에서 여러 자식 tide 레포를 가로지르는 **멀티 레포 오케스트레이션**
커맨드입니다. 실전 사용법·워크드 예제는 [오케스트레이션 가이드](orchestration.md)를 보세요.

## `/tide:fleet [부모 경로]`

- **역할**: 상위 폴더의 자식 tide 레포들을 발견해 **교차 상태 개요 + 권장 처리 순서**(advisory)를
  보고합니다. 읽기 전용.
- **인자**: 부모 폴더 경로(선택, 생략 시 현재 세션 위치).
- **산출물**: 없음 — 보고만 (파일·git·phase 무변경).
- **금지**: 파일/phase/git 변경. fleet은 advisory만 — 어떤 레포도 자동 실행하지 않습니다.

## `/tide:fleet-cycle [부모 경로]`

- **역할**: 발견된 자식 레포의 `milestone → review`를 **의존성 순서**(`.tide/deps` 위상정렬)로
  교차 자동 실행하고, **순서 있는 release 핸드오프**를 제시합니다.
- **인자**: 부모 폴더 경로(선택).
- **산출물**: 각 레포의 마일스톤·보고서 + 순서 핸드오프.
- **금지**: `release`·cross-repo git (release 제외 불변 — 레포별 수동 `/tide:release`로 넘깁니다).

## `/tide:fleet-verify [부모 경로]`

- **역할**: 부모 레벨 통합 훅(`.tide-fleet/integration`)을 부모에서 실행해 **레포 간 통합
  pass/fail**을 보고합니다.
- **인자**: 부모 폴더 경로(선택).
- **산출물**: 없음 — 보고만 (통합 결과 + 다음 안내).
- **금지**: release·git commit·tag·push·cross-repo git (verification-only 불변).
<!-- --8<-- [end:body] -->
