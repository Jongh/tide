# M25 완료보고서 (impl)

## 개요

M25의 3개 태스크를 모두 구현했다. M24가 남긴 sn2 — `pr` 모드의 PR 머지 후 태그/릴리즈 핸드오프 —를
자동화해, `pr` 모드를 **상태 인지 재실행**으로 만들었다. 새 커맨드·토큰 없이 같은 `/tide:release v{버전} pr`를
PR 상태(merged/open/closed/none)로 분기시켜, 머지 후 재실행하면 태그·`gh release create`까지 한 커맨드로
마무리한다. 규약(conventions)·절차(SKILL)·카탈로그(commands·project-context)를 정합시켰다. 태스크는 모두
release 문서/스킬을 건드려 의존 사슬(T01→T02→T03)로 순차 구현했다.

## 태스크별 수행 내용

- **M25-T01** — `docs/conventions.md` "릴리즈 게시 (gh)"의 `### `pr` 모드` 절을 **상태 인지·finalize 규약**으로
  확장했다. `pr` 모드를 재실행 가능한 상태 인지로 규정하고, 검증 게이트 통과 후·**버전 범프·CHANGELOG 편집
  전에** 릴리즈 PR(`release/v{버전}` 또는 제목 `Release v{버전}`)을 `gh`로 조회해 분기함을 명시: **없음**→생성
  (M24 동작), **open**→대기(부수효과 0), **closed(미머지)**→중단, **merged**→마무리(기본 브랜치 최신화 →
  버전 sanity → 태그·push → `gh release create`, 버전 범프·CHANGELOG 건너뜀). 멱등·안전(미머지 태그 금지·
  태그/릴리즈 중복 생성 회피·버전 sanity)을 별도 규정하고, 이 확장이 `pr` 모드 한정임을 명시했다.
- **M25-T02** — `skills/release/SKILL.md`의 `pr` 모드를 상태 인지로 구현했다. ① 게시 모드 해석·검증(step 1)에
  "`pr` 모드 상태 인지" 항목을 추가해 검증 후·파일 편집 전에 PR 상태로 분기하고 **마무리·대기·중단 경로는
  버전 범프·CHANGELOG(2·3)를 건너뜀**을 명시. ② step 2에 그 건너뜀 조건을 한 줄 부기. ③ step 4의 `pr` 모드
  항목을 4분기(없음→생성 / open→대기 / closed→중단 / merged→finalize)로 재작성. ④ 운영 주의 #5에 finalize의
  태그·`gh release create`도 phase=release에서만·merged 확인 후에만 태그·멱등 보고를 보강. 상세는 재서술하지
  않고 conventions "릴리즈 게시 (gh)" 절을 참조(스킬=절차/conventions=규약 분담 유지).
- **M25-T03** — 카탈로그·컨텍스트 동기화. `docs/commands.md`의 `/tide:release` 절 게시 모드 설명에 `pr`가
  "머지 후 같은 명령 재실행으로 태그·릴리즈 자동 마무리(상태 인지·멱등)"함을 반영(커맨드 11종·셸·이름
  불변). `docs/project-context.md`의 "릴리즈 위생"에 `pr` 모드 머지 후 자동 마무리를 한 줄 첨언(단일 원본
  위치 불변·버전 숫자 미복제).

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | 없음 |
| 수정 | `docs/conventions.md`(`pr` 모드 상태 인지·finalize 규약), `skills/release/SKILL.md`(`pr` 모드 상태 인지 구현 + step1/step2 분기 + 운영 주의 #5), `docs/commands.md`(release 절 `pr` 마무리 반영), `docs/project-context.md`(릴리즈 위생 한 줄) |
| 삭제 | 없음 |

## 테스트 결과

M25는 프롬프트 스킬 로직(`pr` finalize)·문서 변경이라 신규 코드·테스트가 없다(마일스톤 범위/주의대로 하니스
비대상). 회귀 검증으로 **카탈로그 편집이 드리프트 가드를 깨지 않는지**와 전 하니스 보존을 확인했다 — 양 셸
라이브 하니스 전부 exit 0, 베이스라인 동일:

| 하니스 | sh | ps1 |
|---|---|---|
| discover | PASS=19 FAIL=0 (N=11, B1/B2/B3 가드 정합) | PASS=19 FAIL=0 |
| fleet | PASS=41 FAIL=0 | PASS=41 FAIL=0 |
| fleet-cycle | PASS=23 FAIL=0 | PASS=23 FAIL=0 |
| fleet-verify | PASS=29 FAIL=0 | PASS=29 FAIL=0 |
| multi-repo | PASS=10 FAIL=0 | PASS=10 FAIL=0 |

- 커맨드 11종·셸·이름 완전성 가드(discover B1/B2/B3) 불변 — `pr` 마무리 반영이 새 커맨드·토큰을 더하지 않음.
- `pr` finalize 자체(상태 분기·태그·`gh release create`)는 `gh`·실제 머지 상태 의존이라 자기완결형 하니스로
  덮을 수 없다 — 정적 검토(conventions↔SKILL 정합·분기·멱등)로 확인했고 리뷰에서 재확인 대상.

## 미해결·후속 메모

1. **`pr` finalize 라이브 미검증(M24 sn1과 동질)** — 상태 인지 분기·머지 감지·태그/릴리즈 마무리는 프롬프트
   스킬이라 자동 테스트 비대상. 다음 `pr` 모드 릴리즈 도그푸딩(M25 자신을 `/tide:release v2.4.0 pr`로 회수)
   시 생성→머지→재실행(finalize) 전체 경로를 라이브로 확인 가능. 리뷰에서 절차 정합·멱등·안전(미머지 태그
   금지·버전 sanity) 정적 검토 필요.
2. **sn3(fleet-verify strip_bom 정리)** — M24부터의 저위험 향후 정리 후보로 이번 범위 밖. 잔존.
