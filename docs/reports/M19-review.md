# M19 리뷰보고서 (review)

## 비판점

리뷰는 ultracode 적대 검증(verification-only 불변 반증 + 통합 훅 공격 표면 + M18 일관성 + 정합·완전성)
으로 수행했다. **차단 0건** — `/tide:fleet-verify` 자체는 어떤 경로로도 git/release를 유발하지 않음이
확인됐다(brokeInvariant=false). 적대 검증이 M18 정밀도 미계승 1건을 적발했고 **리뷰에서 수정**했다.
이로써 오케스트레이션 로드맵 1~4층이 모두 완성된다.

### 차단 (0건)

없음. M19 4개 완료 기준 모두 충족, T01(규약)·T02(스킬)·T03(테스트) spec 정합(3-way 일치), 11번째
커맨드 3곳 등록, 양 셸 하니스 18/18, 로드맵 1~4층 활성/완성. 단일 레포·훅 미선언 동작 불변, 커맨드
10종·1.0 계약 불변.

### 권장 (1건 — **리뷰에서 수정 완료**)

1. **백스톱 서술이 M18 정밀도 미계승 + 통합 훅 stale-release 경고 부재** (적대 검증 HOLE 1·2) —
   fleet-verify 자체는 git/release를 안 하고 phase=release를 안 쓰므로 직접 경로는 닫혀 있다. 그러나
   **통합 훅은 프로젝트 정의 명령**(작성자가 작성)이라 공격 표면이다: 훅이 `cd 자식 && git push`처럼
   cross-repo git을 하고 그 자식이 **이전 중단된 수동 release의 잔재로 phase=release**로 남아 있으면,
   M18이 밝힌 그대로 가드가 풀려 git이 통과할 수 있다. M18은 이 사각을 (a)"가드는 phase 잠금이지
   release 차단기가 아니다 + stale-release면 풀린다"는 정밀 서술과 (b)fleet-cycle **사전 점검**으로 다뤘으나,
   M19 fleet-verify는 그 정밀도를 계승하지 않고 "가드 백스톱이 그대로 적용"이라고만 적어 **백스톱 보장을
   과대 서술**했다. → **수정**: `skills/fleet-verify/SKILL.md`·`docs/conventions.md`의 verification-only 백스톱
   서술을 M18과 동일하게 정밀화(phase 잠금≠release 차단기, stale-release 사각 명시) + **통합 훅에 cross-repo
   git 금지·의심 시 자식 phase release 잔재 점검** 경고 추가. 비차단으로 본 이유: 누수는 fleet-verify가
   만드는 경로가 아니라 외부 손상 상태(중단된 release) + 훅 오작성의 복합이며, 훅 작성자 책임 + 정밀
   서술로 닫았다(fleet-verify는 부모 한 곳에서 훅 1회 실행이라 fleet-cycle보다 표면이 좁다).

### 사소 (3건)

2. **통합 훅 git-verb 사전 차단 미구현** — 훅 실행 전 git 동사 포함 여부를 grep해 거부하면 HOLE 1 경로를
   규약→가드라일로 격상할 수 있으나, 훅 의미를 바꾸는 일이라(검증 명령에 git이 합법적으로 필요한 변형
   가능) major-safe하게 advisory로 유지. 후속 후보.
3. **fleet-verify 세션 레벨 실동작 미실증** — 훅 발견·옵트인·pass/fail 결정적 핵심은 하니스로 덮었으나
   실제 `/tide:fleet-verify`가 부모에서 훅을 돌리고 release/git 미발생·결과 보고하는지는 세션 레벨 수동
   확인 영역(README). 샌드박스 `.tide-fleet/integration` 선언으로 릴리즈 후 1회 권장.
4. **참조 구현 이중성(이월·회고 군집)** — tests/fleet-verify가 훅 파싱·분류 로직 재구현. conventions 단일
   원본 인용으로 관리(저위험 수용). T03이 SKILL 결합 anchor를 `verification-only`(fleet-verify 고유)로 잡은
   것은 정확(스펙 OR 충족).

## 수정 내용

- **이슈 1**: `skills/fleet-verify/SKILL.md`·`docs/conventions.md`의 verification-only 백스톱 서술을 M18 정밀
  어구로 교체("가드는 phase 잠금이지 release 차단기가 아니다; fleet-verify 자체로는 안 풀리나 통합 훅이
  stale phase=release 자식에서 git하면 풀릴 수 있다") + 통합 훅에 cross-repo git 금지·자식 phase release
  잔재 점검 경고 추가. 스킬 결합 검증(금지 목록·verification-only 산문 grep)은 수정 후에도 통과(18/18).

## 검증

- **라이브 하니스(수정 후)**: `sh tests/fleet-verify/run.sh` → **PASS=18 / FAIL=0**, `tests\fleet-verify\run.ps1`
  → **PASS=18 / FAIL=0**. run.ps1 non-ASCII 0, run.sh BOM 없음. 회귀: fleet-cycle·fleet·multi-repo 전부 exit 0.
- **적대 검증 결과**: brokeInvariant=**false** — fleet-verify 자체는 git/release/phase=release 미실행(직접
  경로 닫힘). HOLE 1·2(백스톱 과대 서술·stale-release 경고 부재)를 수정해 M18/M19 백스톱 서술 일관성 회복.
- **감사(정합·완전성)**: T01·T02·T03이 동일 spec(옵트인 parent-level 훅·발견·실행 pass/fail·verification-only·
  fleet-cycle 흐름·graceful) 기술, 발견된 divergence는 stale-release 점검 미러 부재 1건(수정으로 해소). 4개
  완료 기준 met. 11번째 커맨드가 사이클 다이어그램·금지 행위 표(git 금지·verification-only)·1.0 안정성(v1.6.0
  가산) 3곳 등록, stable-8 + fleet/fleet-cycle framing 보존, 부수효과 분리 불변 4층 확장, **로드맵 1~4층 완성**.
- **제외 용어**: M19 신규/변경 텍스트(conventions·fleet-verify 스킬·tests·M19 문서) 외부 저장소명 literal 0.
  기존 `conventions.md:3`은 snippet 마커 밖(미변경). 빌드 출력 검증은 release/CI.

## 릴리즈 판정

**가능** — 추천 버전: **v1.6.0 (minor)**

- **완료 기준 충족**: 규약 4층 활성·통합 훅/fleet-verify 단일 원본·11번째 커맨드 등록(기준 1), 스킬 발견·훅
  실행 pass/fail·verification-only·강등(기준 2), 하니스 5핵심 + 스킬 결합 양 셸 통과(기준 3), 전부 가산·옵트인·
  로드맵 1~4 완성(기준 4) 모두 충족.
- **차단 이슈 처리**: 차단 0. 적대 검증이 적발한 권장 1건(백스톱 과대 서술·stale-release 경고)을 **리뷰에서
  수정**해 M18/M19 안전 서술 일관성을 회복했다. 사소 3건은 수용·저위험·이월.
- **버전 근거**: 통합 검증이라는 **신규 능력**(자식 레포 가로지르는 통합을 프로젝트 정의 훅으로 검증)이 새
  커맨드 `/tide:fleet-verify`로 가산 → minor. 단일 레포·훅 미선언 불변, 커맨드 10종·읽기 전용 fleet·부수효과
  분리·`.tide/phase` 계약 불변. git·release 자동화 없음(verification-only). 마일스톤 목표 v1.6.0과 일치.

## 다음 단계

- **릴리즈**: `/tide:release v1.6.0` — 프리플라이트(리뷰 "가능"·테스트·워킹트리·사이트 빌드 출력 제외 용어
  0건; mkdocs 미설치 시 CI) 후 배포. CHANGELOG는 제외 용어 없이 "4층 — `/tide:fleet-verify` 통합 검증(통합
  훅 `.tide-fleet/integration` 옵트인, **verification-only**), 오케스트레이션 로드맵 1~4층 완성" 요약.
- **릴리즈 후**:
  - 세션 레벨 실증(README): 샌드박스에 `.tide-fleet/integration` 선언 → `/tide:fleet-verify` 실행 → 통합
    pass/fail + **어떤 레포에도 release/git 미발생** 확인. 훅 없음 → 생략 강등 확인.
  - **다음 마일스톤 후보**: 오케스트레이션 1~4층 완성 후 — M17 연산자 확장(`>`·`=`·`<=`·`<`), 또는 1~4층
    완성 시점 **누적 회고**(fleet 사가 전체 조망). 유지된 샌드박스가 테스트 베드.
