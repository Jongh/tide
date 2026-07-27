# M31 완료보고서 (impl)

## 개요

M31의 세 태스크를 모두 구현했다 — 브랜치 간 협업에서 조용히 새던 두 구멍을 **읽기 전용·advisory**
검사로 닫았다: ① `/tide:release` 프리플라이트의 **커버리지 체크**(마지막 태그 이후 변경 중 미릴리즈
보고서가 설명하지 않는 파일 노출 — 비-tide 커밋의 릴리즈 편승), ② `/tide:milestone`의 **번호
사전경고**(다음 `M{N}`이 다른 ref에 선점됐으면 경고 — 재할당 캐스케이드 예방). 두 규약을
`docs/conventions.md` 단일 원본에 신설하고 각 스킬에 배선한 뒤, `tests/discover`에 **Part D**
(규약↔스킬 선언 정합)를 가산해 드리프트를 고정했다. 카탈로그·컨텍스트에도 반영했다. 전 하니스 양 셸
FAIL 0.

## 태스크별 수행 내용

- **M31-T01 (릴리즈 커버리지 체크, advisory)** — `docs/conventions.md`에 **## 릴리즈 커버리지 체크**
  절을 신설했다: 마지막 태그를 기준(`git tag` — 기존 "태그-트리 포함" 릴리즈 판정 재사용)으로
  `git diff --name-only <태그>..HEAD`의 변경 파일에서 bookkeeping(`docs/reports/*`·`docs/milestones/*`·
  `CHANGELOG.md`·버전 파일·`.tide/*`)을 뺀 나머지가 **미릴리즈 보고서**(리뷰 + 미릴리즈 debug — 릴리즈
  경로의 근거 집합과 동일 대상) 본문에 경로로 언급되는지 확인해, 미언급 파일을 **비차단 advisory**로
  경고한다. `skills/release/SKILL.md` 프리플라이트에 **4번째(advisory) 단계**로 배선했다(기존 3게이트
  불변). 매칭이 경로 부분일치 휴리스틱임을 명시(fleet-verify git-verb 가드라일과 동형 — 정밀 게이트가
  아니라 편승 노출이 목적).
- **M31-T02 (마일스톤 번호 사전경고, advisory)** — `docs/conventions.md` "마일스톤 문서" 절에 번호
  사전경고 항목을 추가했다: 다음 번호 `M{N}` 결정 **직후·문서 생성 전에**
  `git log --all --diff-filter=A -- "docs/milestones/M{N}.md"`(읽기)로 다른 ref 선점을 확인해 경고하되
  **번호를 자동 변경하지 않는다**(사용자 판단). `skills/milestone/SKILL.md`의 번호 결정과 생성 사이에
  배선했다. 경로 충돌은 git이 머지에서 이미 막으므로, 이 경고의 목적은 **재할당 캐스케이드 예방**임을
  규약에 못박았다.
- **M31-T03 (집행 배선 + 카탈로그·컨텍스트, deps: T01·T02)** — `tests/discover`(양 셸)에 **Part D**를
  가산했다: (D1) `git diff --name-only`가 conventions와 release SKILL 둘 다에, (D2) `git log --all`이
  conventions와 milestone SKILL 둘 다에 등장하는지 결합(한 곳만 고치면 FAIL). ASCII 메커니즘 토큰을
  써 ps1의 ASCII-only 원본 규율과 정합. **교차 통제**(각 토큰이 반대 스킬엔 부재) + **음성 통제**(가짜
  토큰 부재)로 구별력 입증. `docs/commands.md`의 milestone·release 상세에 advisory 한 줄씩 반영
  (**12종 이름·카운트·표 구조 불변**). `docs/project-context.md`에 도메인 개념 + 이월 원장 M31 행 추가.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M31-impl.md` (이 보고서) |
| 수정 | `docs/conventions.md`, `skills/release/SKILL.md`, `skills/milestone/SKILL.md`, `tests/discover/run.sh`, `tests/discover/run.ps1`, `docs/commands.md`, `docs/project-context.md` |
| 삭제 | (없음) |

기준선 = 이 impl 단계 시작 시점의 워킹트리. `docs/milestones/M31.md`는 직전 milestone 단계의
**미커밋 산출물**이라 git 기준으로는 신규 파일이며 이 impl이 만든 것이 아니다(부수효과 분리 — 커밋은
release에서만). 위 "수정" 7개 파일은 모두 v2.8.0 태그 트리에 있던 커밋된 베이스라인이므로 git
기준으로도 "수정"이다(어긋남 없음).

## 테스트 결과

자동 러너 없는 레포라 `tests/`의 자기완결 라이브 하니스로 검증했다. **수정한 `tests/discover` 포함
전 하니스 양 셸 FAIL 0**:

| 하니스 | sh | ps1 |
|---|---|---|
| `tests/discover` (Part D 가산: +8/셸) | **36/36** | **36/36** |
| `tests/multi-repo` | 30/30 | 30/30 |
| `tests/site-includes` | 28/28 (shells=4 includes=4 terms=[제외 용어]) | 28/28 |
| `tests/fleet` | 41/41 | 41/41 |
| `tests/fleet-cycle` | 23/23 | 23/23 |
| `tests/fleet-verify` | 29/29 | 29/29 |

- **구현 중 발견·수정한 이슈(가드가 스스로 잡음)**: 최초 실행에서 **D1(release SKILL 배선)이 FAIL**
  했다 — `skills/release/SKILL.md`에서 `git`과 `diff --name-only`가 **줄바꿈으로 갈라져** 토큰이
  끊겼기 때문이다. Part D가 의도대로 규약↔스킬 정합을 잡은 것이다. 토큰을 한 줄로 붙여 재실행,
  36/36로 통과. (conventions·milestone의 토큰은 처음부터 연속이라 통과했다.)
- **사이트 인클루드 영향 확인**: `conventions.md`·`commands.md`는 사이트 스니펫 인클루드 대상이라
  `site-includes`(인클루드 타깃·섹션 마커·제외 용어)를 양 셸로 재확인 — 28/28, 제외 용어 0건 유지.

## 미해결·후속 메모

1. **런타임 발화는 미실증(정직 유보)** — 두 검사의 실제 경고가 올바른 상황에서 뜨는지는 **프롬프트
   규율**이라 하니스로 집행되지 않는다. Part D는 **선언 정합만** 고정한다(M29/M30이 프롬프트 자산
   한계를 남긴 것과 동형). 리뷰가 이 한계를 판정에 반영할 것.
2. **커버리지 체크 매칭의 위양성 여지** — 미릴리즈 보고서가 파일을 변경 파일 요약에 안 적었을 뿐인데
   "미상"으로 경고할 수 있다. advisory·비차단이라 수용 가능하나, 실사용에서 소음이 잦으면 매칭 기준
   (예: 보고서 표 파싱 강화)을 재검토할 후보다.
3. **debug-{N} 번호 충돌은 이번 범위 밖** — 번호 사전경고는 `/tide:milestone`(M번호)만 다룬다.
   `debug-{N}` 독립 수열도 같은 브랜치 간 충돌을 겪지만, `/tide:debug`에 대칭 배선하는 것은 별도
   판단으로 남긴다(저비용 후속 후보).
4. **다인·혼성 팀 라이브 도그푸딩 부재** — 이 마일스톤은 예측 가능한 무결성 구멍을 실증 전에 닫았다.
   실제 브랜치 간 협업 사례가 생기면 두 경고가 유용했는지 확인 후 원장에 근거로 기록.
