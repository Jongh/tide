# M24 리뷰보고서 (review)

## 개요

M24(릴리즈 게시 모드 gh + read_deps 단일 원본화)를 리뷰했다. 회고 교훈 #1("가산·정리 사이클은 단일 비판
리뷰")에 따라 집중 비판 리뷰로 수행하되, 교훈 #2("테스트 통과 ≠ 정합")에 따라 핵심 위험을 직접 확인했다 —
특히 ① 게시 절차의 **부수효과 순서 안전성**(검증 게이트가 작업 트리 편집을 보호하는지)과 ② sn2 리팩터의
**우연한 green**(로컬 정의가 라이브러리를 섀도잉해 dedup이 실제로 일어나지 않았는데 통과) 가능성. 전자에서
검증 순서 결함을 적발해 **리뷰에서 직접 수정**했다.

**차단 결함 0. 최종 판정: 가능 — 추천 v2.3.0 (minor).**

## 비판점

### 차단 (0건)

없음.

### 권장 (1건 — 리뷰에서 수정 완료)

1. **게시 검증 게이트가 작업 트리 편집(버전 범프·CHANGELOG) *뒤*에 있어, 명시 모드 검증 실패 시 트리가
   더럽혀짐** — `skills/release/SKILL.md`의 단계 배치가 ①버전 파일 ②CHANGELOG ③게시 모드 해석·검증
   ④게시 분기 순이었다. `pr`/`release`를 인자/저장값으로 **명시**했는데 검증 ④(원격 GitHub 등록·`gh`
   인증 등)가 실패하면, step 1~2에서 이미 버전 파일·CHANGELOG가 편집된 채(커밋 전) 중단돼 **작업 트리가
   더럽혀진 상태로 남았다**. M24 마일스톤이 명시한 설계 요점("검증을 부수효과 발생 전에 두어 명시 모드
   실패 시 어중간하게 새지 않게")이 commit/push에는 적용됐으나 **작업 트리 파일 편집까지 확장되지 못한
   갭**. **영향**: 회복 가능(`git checkout`)이나, 게시를 명시한 사용자가 의도치 않은 미커밋 편집을 떠안는다.
   **수정**: 게시 모드 해석·검증을 **step 1로 올려**(버전 범프·CHANGELOG 앞) 명시 모드 검증 실패 시 **작업
   트리 무변경으로 중단**하도록 절차를 재배치했다. `docs/conventions.md` "릴리즈 게시 (gh)"의 검증 게이트
   절에도 "명시 모드에선 버전 범프·CHANGELOG 편집 전에 검증" 순서를 명문화해 규약↔절차를 정합시켰다.

### 사소 (3건 — 수용)

- **[sn1] 게시 모드는 라이브 하니스 비대상**(출처: M24-impl 후속1) — `/tide:release`의 gh 분기(`pr`/`release`
  흐름·검증 게이트·`.tide/release-mode` 선호도·원격 불가 처리)는 프롬프트 스킬이라 자동 테스트로 덮이지
  않는다. **수용 사유**: tide 전체가 자동 러너 없는 프롬프트/셸 플러그인이고(project-context "테스트" 절),
  검증 수단은 정적 검토 + 도그푸딩이다. 이번 리뷰에서 conventions↔SKILL 정합·절차 안전 순서를 정적으로
  확인했고, 실제 `gh` 게시는 다음 release 도그푸딩 시 라이브 회수한다.
- **[sn2] `pr` 모드 머지 후 태그/릴리즈 핸드오프 미구현** — `pr` 모드는 "PR 열림"까지만 하고 태그·GitHub
  릴리즈를 머지 후로 미룬다. 머지 후 후속(태그·릴리즈 생성)을 사람이 수동으로 하며 자동 경로는 없다.
  **수용 사유(범위 결정)**: 이번 목적은 "게시 방식 택1"이고, 머지 후 자동화는 별도 설계가 필요한 차기 후보다.
- **[sn3] `fleet-verify`의 `strip_bom`/`StripBom` 미추출** — fleet-verify는 `read_deps`/`toposort`를 쓰지
  않아 sn2(`read_deps` 한정) 범위 밖으로 의도적 미변경. 자체 `strip_bom`이 남아 있으나 deps 파싱과 무관.
  **수용 사유**: 저위험 향후 정리 후보(M23 sn2 패턴의 잔여).

## 수정 내용

- **이슈 1 (검증 순서)**: `skills/release/SKILL.md`의 게시 절차를 **게시 모드 해석·검증(1) → 버전 범프(2) →
  CHANGELOG(3) → 게시 분기(4)** 로 재배치했다. 검증 게이트 항목에 "명시 모드 검증 실패 시 **버전 범프·
  CHANGELOG 편집 전에 중단**(작업 트리 무변경·조용한 강등 금지)"을 명시. 별도였던 "원격 불가/검증 실패
  처리" 단계는 검증 게이트로 흡수해 중복 제거. `docs/conventions.md`의 검증 게이트 절도 "명시 모드에선 버전
  범프·CHANGELOG 편집 전"·"release 스킬은 이 순서를 절차로 고정"으로 강화.

## 검증

**① sn2 참조 구현 단일 원본화 — 우연한 green 배제(교훈 #2 직접 확인)**:
- **섀도잉 아님(진짜 dedup)**: fleet·fleet-cycle(× 2셸)의 로컬 `read_deps`/`ReadDeps`/`dep_name`/`DepName`/
  `strip_bom`/`StripBom` 정의 수 = **전부 0**(grep 확인 — source 라인 + 브레드크럼 주석 + 호출부만 잔존).
- **라이브러리 단일 정의·클린**: `tests/lib/deps.{sh,ps1}`가 각 함수를 **정확히 1개** 정의, top-level
  부수효과(픽스처·실행) **0**(순수 함수 정의). 헤더에 추출 범위·source 순서 명시.
- **source 순서 정합**: fleet·fleet-cycle 4개 하니스 모두 `discover → deps → toposort` 순으로 source/dot-source
  (toposort가 read_deps 호출 → deps 먼저). `toposort.{sh,ps1}` 주석도 새 순서 반영(본문 무변경).
- **로직 동등성 실증(드리프트 화해)**: 계약 비교 전용 함수(범위 밖·로컬 유지)가 라이브러리 보조(`strip_bom`/
  `DepLines`/`DepName`)를 재사용하고, **fleet-cycle 계약 비교가 정본 `DepName`(`(>=|<=|==|=|>|<).*$`)을
  거쳐 통과** → fleet-cycle 옛 로컬 `DepName`(`\s*[<>=].*$`)과의 로직 동등성이 실증됐다(드리프트 화해 완료).

**② 게시 절차 정합(정적 검토)**:
- 수정 후 절차는 검증→편집→게시 순으로, 명시 모드 검증 실패가 작업 트리/commit/push 어디도 더럽히지 않는다.
- `pr` 모드만 직접 push 흐름과 갈라짐(릴리즈 브랜치+PR, 태그/릴리즈 미룸) — 분기 전 검증로 commit 누수 차단.
- tide-guard 비확장 확인: 가드는 git 토큰만 차단(2.0 stable), `gh`는 게이트 안 함 — "게시는 release에서만"은
  스킬 절차가 phase=release 안에서 `gh`를 호출해 보존(conventions·SKILL 양쪽 일치).
- `.tide/release-mode`는 `.tide/deps`와 동급 커밋(gitignore는 `.tide/phase`만) — release 커밋/PR 브랜치에 포함.

**라이브 실증(양 셸, M23 baseline 동일)**:

| 하니스 | sh | ps1 |
|---|---|---|
| discover · fleet · fleet-cycle · fleet-verify · multi-repo | 19·41·23·29·10 / FAIL 0 | 19·41·23·29·10 / FAIL 0 |

- 모든 러너 exit 0, M23 baseline과 PASS 수 동일(동작 보존). 리뷰 수정(SKILL 재배치·conventions 강화) 후
  discover 재실행도 **PASS=19 FAIL=0 (N=11)** 유지.
- **드리프트 가드 불변**: discover B1(`11종` 선언 정합)·B2(사이트 스니펫 셸)·B3(커맨드 이름 완전성) 통과.
  카탈로그 release 행은 `[pr/release]`(슬래시 — 파이프 아님)로 표 무손상, `/tide:release ` 토큰·11종 유지.
- **인코딩 규율**: `tests/lib/deps.ps1`·`toposort.ps1` 비ASCII **0**, 신규/수정 셸·라이브러리 8개 **BOM 없음**.

**완료 기준 8개 충족**: ①gh 두 모드 분기·gh 부재 바이트 동일 ②모드 선택/선호도(`.tide/release-mode`)
③명령 검증·원격 불가 처리·tide-guard 비확장 ④conventions 단일 원본·SKILL 참조·arg-hint ⑤`tests/lib/deps`
단일 정의·로컬 중복 제거·toposort 주석 ⑥전 하니스 baseline 동일·인코딩·드리프트 가드 불변 ⑦commands.md
11종·셸·이름 불변·project-context 동기화 ⑧2.0 stable 계약 불변·옵트인 가산.

## 릴리즈 판정

**가능** — 추천 **v2.3.0 (minor)**.

근거: 차단 0. 권장 1건(검증 순서)은 **리뷰에서 직접 수정**(검증을 작업 트리 편집 전으로 재배치, 규약↔절차
정합), 사소 3건은 수용. M24는 `/tide:release`에 **새 사용자 대면 능력**(gh 게시 모드 `pr`/`release`)을
옵트인으로 가산하므로 patch 아닌 **minor**가 영향도에 맞다(`gh` 부재 시 동작은 바이트 동일, 동봉 sn2는 내부
정리). 2.0 stable 계약(11종 커맨드 호출명·역할·오케스트레이션 규약·`.tide/phase`/tide-guard·보고서·마일스톤
형식)·M22 드리프트 가드(discover B1/B2/B3) 전부 불변. M23이 시작한 참조 구현 단일 원본화(sn2)를 종결했다.

## 다음 단계

- `.tide/phase`를 `idle`로 되돌리고 **`/tide:release v2.3.0`**을 사용자에게 넘긴다(cycle은 release 제외 —
  git은 사용자 몫).
- **도그푸딩 기회**: 이 릴리즈 자체를 새 게시 모드로 회수할 수 있다 — `/tide:release v2.3.0 release`(GitHub
  릴리즈) 또는 `v2.3.0 pr`(PR)로 sn1(게시 모드 라이브 미검증)을 실제 환경에서 닫는다. `gh` 미설치/미인증/
  원격 비-GitHub면 인자 없이 push-only로 진행해도 현행과 동일.
- 릴리즈 후(비차단): sn2(`pr` 머지 후 태그/릴리즈 핸드오프 자동화)·sn3(`fleet-verify` strip_bom 정리)는
  저위험 차기 후보. mkdocs 빌드 출력 검증은 환경-이월 지속(다음 release 프리플라이트도 동일).
