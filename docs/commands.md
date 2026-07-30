# 커맨드 레퍼런스

tide가 제공하는 슬래시 커맨드의 역할·인자·산출물·금지 행위를 한곳에 모은 레퍼런스다.

<!-- 아래 [start:body]~[end:body]는 사이트(site/docs/commands.md)가 pymdownx.snippets로
     본문만 인클루드하기 위한 마커다. 위 도입 문단은 일부러 마커 밖에 두어 사이트에서는
     사이트 전용(외부 귀속 없는) 도입부로 대체된다. 렌더에는 영향 없음. -->
<!-- --8<-- [start:body] -->
tide는 12종의 슬래시 커맨드를 제공합니다. 호출은 모두 `/tide:{단계}` 형태이며,
`/tide:` 까지 입력하면 탭 자동완성으로 12종이 함께 표시됩니다. 앞의 8종은 단일 레포의
**계획 우선** 사이클, `debug`는 사이클 밖에서 발견한 에러를 세션으로 묶는 **발견 우선**
진입점, 뒤의 3종(`fleet`·`fleet-cycle`·`fleet-verify`)은 상위 폴더에서 여러 자식 레포를
가로지르는 **멀티 레포 오케스트레이션**입니다 — 실전 사용법은
[오케스트레이션 가이드](orchestration.md).

## 한눈에 보기

<!-- role-anchors: review=refutation release=gh fleet-verify=verification-only -->
<!-- 역할 앵커 맵(기계 판독용) — 규약은 docs/conventions.md "문서 자기서술 정합"의 역할 앵커 전파 절.
     각 앵커는 아래 표의 해당 커맨드 행에 실재해야 하고, 그 커맨드를 소개하는 소비자 문서
     (README.md · site/docs/getting-started.md)에도 전파돼야 한다. 집행 = tests/discover Part F. -->

| 커맨드 | 역할 | 산출물 | git |
|---|---|---|---|
| `/tide:kickoff` | 워크플로우 골격 생성 (+ 진행 중 프로젝트면 구조 문서화) | `docs/` 골격·`CHANGELOG.md`·`conventions.md`·`project-context.md` | ✗ |
| `/tide:milestone` | 다음 마일스톤 문서 생성 | `docs/milestones/M{N}.md` | ✗ |
| `/tide:impl [M번호]` | 마일스톤대로 구현 + 테스트 | 코드 + `docs/reports/M{N}-impl.md` | ✗ |
| `/tide:review` | 비판적 리뷰 + 반증 시도(refutation) 후 릴리즈 판정 | `docs/reports/M{N}-review.md` (판정 계측 줄 포함) | ✗ |
| `/tide:cycle [주제/M번호]` | `milestone→impl→review` 자동 체이닝 | 위 단계들의 산출물 + 릴리즈 안내 | ✗ |
| `/tide:release vX.Y.Z [pr/release]` | 프리플라이트 → 버전 범프 → CHANGELOG → commit → tag → push. `gh` 있으면 GitHub 릴리즈/PR 게시 택1(옵트인) | 릴리즈 커밋·태그 (+선택 gh 릴리즈/PR) | ✓ |
| `/tide:retro` | 누적 사이클 회고 (읽기 전용) | `docs/reports/retro.md` | ✗ |
| `/tide:status` | 현재 상태 + 다음 권장 커맨드 (읽기 전용) | (없음 — 보고만) | ✗ |
| `/tide:debug [증상 / done]` | 발견한 에러를 세션으로 묶어 수정·누적 + 릴리즈 판정 (사이클 밖, 발견 우선) | `docs/reports/debug-{N}.md` | ✗ |
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
- **번호 사전경고(advisory)**: 다음 번호 `M{N}`이 다른 ref에 이미 도입됐으면 경고합니다(읽기 전용·
  번호 자동 변경 없음 — 병렬 브랜치 간 재할당 캐스케이드 예방). 충돌이 없으면 조용합니다.
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
- **반증 시도(refutation)·재검증**: 판정 **직전** 자기 판정 후보를 반박하는 독립 패스를 한 번
  거칩니다(Agent 서브에이전트에 판정 후보·근거만 넘겨 원자료를 직접 읽게 하고, 불가하면 메인이
  수행한 뒤 **폴백 사실을 보고서에 기록**). 리뷰 중 고친 것이 1건이라도 있으면 **검증을 재실행**한
  결과를 적은 뒤에 판정합니다(불가하면 미검증 잔여 리스크로 명시). 단일 원본은
  `docs/conventions.md`의 "리뷰 검증 규율" 절.
- **산출물**: `docs/reports/M{N}-review.md` (비판점[차단/권장/사소]·수정 내용·검증·릴리즈
  판정+추천 버전·다음 단계). `## 릴리즈 판정` 섹션에는 `계측: in-review 수정 … · 반증 시도 … ·
  재작업 라운드(rework) …` 한 줄이 필수로 남습니다 — 판정 표기·추천 버전의 형식·위치는 불변이라
  프리플라이트·`/tide:status`·fleet 계열의 판정 읽기는 그대로입니다.
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

- **역할**: tide에서 **git을 만지는 유일한 단계**입니다. `gh` CLI가 있으면 push 위에 **GitHub
  릴리즈**를 만들거나 **PR**을 여는 게시 모드를 옵트인으로 고를 수 있습니다.
- **인자**: `vX.Y.Z` — 릴리즈 버전(리뷰가 추천한 값). (선택) 게시 모드 토큰 `pr`/`release`.
- **전제조건(프리플라이트)**: ① review 판정 "가능" ② 테스트 통과 ③ 워킹트리 확인.
  통과해야 git 작업을 시작합니다.
- **커버리지 체크(advisory)**: 프리플라이트에서 마지막 태그 이후 변경된 파일 중 **어떤 미릴리즈
  보고서도 설명하지 않는 것**을 경고합니다(차단 아님 — tide를 거치지 않은 변경이 미검토·CHANGELOG
  누락으로 태그에 편승하는지 릴리즈 시점에 노출). 전부 커버되면 조용합니다.
- **동작**: 버전 범프 → `CHANGELOG.md`·`README.md` 갱신 → commit → tag → push.
- **게시 모드(`gh` 옵트인)**: 우선순위 = 명시 인자 > `.tide/release-mode` 저장값 > (검증 통과 시)
  대화형 질문. `release` = push 후 `gh release create`(가산), `pr` = 릴리즈 브랜치 + `gh pr create`로
  PR을 연 뒤 **머지 후 같은 명령을 다시 실행하면 태그·릴리즈로 자동 마무리**(상태 인지·멱등 — merged면
  finalize, open이면 대기). 게시 전 `git`·`gh`·인증·원격 GitHub 등록을 검증하고, `gh` 부재/검증 실패면
  현행 push-only로 **바이트 동일**. 단일 원본은 `docs/conventions-release.md`의 "릴리즈 게시 (gh)" 절.
  tide-guard는 `gh`로 확장하지 않습니다.
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

## `/tide:debug [증상 / done]`

- **역할**: 빌드 후 사용자 테스트 등에서 **발견한 에러를 그 자리에서 고치고**, 그 발견-수정을
  하나의 세션으로 묶어 보고서 하나로 남깁니다. 계획 우선 사이클(`milestone → impl → review`)과
  달리 **발견 우선**이라 마일스톤·태스크·`deps`를 요구하지 않습니다. `/tide:cycle` 자동 체이닝의
  대상은 **아니며**(체이닝은 계획 우선 전용), 출구는 사이클과 같은 `/tide:release`입니다.
- **인자**: 증상 설명(→ 세션 열기/이어가기, 그 문자열을 첫 증상으로 취급) / `done`(→ 세션 종료) /
  없음(→ 열린 세션이 있으면 이어가기, 없으면 세션만 열고 증상을 물음).
- **동작**: 세션을 열면 `.tide/debug-session`에 보고서 번호 N을, `.tide/phase`에 `debug`를
  기록합니다. 증상마다 재현 → 진단 → 수정 → 검증을 하고 **항목이 끝날 때마다 보고서에
  append**합니다(못 고친 것·원인만 밝힌 것도 상태를 달아 남깁니다 — 상태는 `수정함`/`미해결`/
  `원인만 규명`/`확인함` 네 가지). `done`이 개요·판정을 채워 마무리하고 `.tide/debug-session`을
  지운 뒤 phase를 `idle`로 되돌립니다 — 열린 세션이 없으면 보고서를 만들지 않고 안내만 하고
  중단합니다.
- **산출물**: `docs/reports/debug-{N}.md` (개요·항목별 기록·변경 파일 요약·미해결/후속·릴리즈
  판정). 판정은 **리뷰보고서와 동일한 형식**이라 `/tide:release` 프리플라이트가 그대로 판정
  근거로 읽습니다(추천 버전 기본은 patch).
- **정오표**: 세션 중 **이미 릴리즈된 다른 보고서**(impl·review·debug 무엇이든)의 사실 오류를
  발견하면 본문을 고치지 않고 **그 보고서** 말미에 `## 정오표`를 append합니다(본문은 증거 —
  미릴리즈면 본문 직접 수정). 자기 보고서에 쓰는 섹션이 아닙니다.
- **금지**: git commit·tag·push / 마일스톤 문서 생성·수정 / 버전 파일·`CHANGELOG.md` 편집
  (그것은 release의 일)

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
