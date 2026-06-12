# M15 리뷰보고서 (review)

## 비판점

리뷰 결과 **차단 0건**. M15 세 태스크는 완료 기준을 충족하고, fleet advisory 출력이 정규
taxonomy로 통일돼 스킬·규약·테스트가 한 기준에 정합한다. 병렬로 수정된 T01(스킬)·T02(규약)이
서로 일치함을 확인했다.

### 차단 (0건)

없음. 기능 추가 없는 정합·견고화 patch이며, fleet 호출명·역할·읽기 전용·부수효과 분리 불변,
커맨드 9종·1.0 안정 계약을 건드리지 않는다.

### 권장 (1건 — 레포 밖, 다음 단계 처리)

1. **샌드박스 `expect.ps1` 미정합** (M15-impl#1) — 사용자가 유지 중인 `D:\Code\private\test\expect.ps1`은
   M15 이전 taxonomy(4버킷·impl 인자 변동 가능)다. M15 정규 taxonomy(5버킷·`/tide:impl M{N}`·숨김 무시)에
   맞춰 동기화해야 향후 `/tide:fleet` 실증이 깨끗이 대조된다. **레포 릴리즈 범위 밖**(tide 저장소 파일이
   아님)이라 이 리뷰의 수정·커밋 대상이 아니며, 릴리즈 후 별도로 동기화한다(다음 단계).

### 사소 (2건)

2. **참조 구현 ↔ 스킬 프롬프트 이중성** (M14 이월·완화) — fleet은 프롬프트 스킬이라 출력이 산문으로만
   규정돼, `tests/fleet/`가 발견·분류 로직을 재구현해 회귀를 고정한다. M15가 **정규 taxonomy를
   conventions 단일 원본으로 못박아** 스킬·테스트가 모두 그것을 인용하게 함으로써 이중성을 줄였으나,
   규약 변경 시 스킬·하니스·(샌드박스 expect)를 함께 손봐야 하는 구조는 남는다. 저위험·수용.
3. **fleet 세션 레벨 출력 재확인** — 출력 형식이 바뀌었으므로(5버킷·인자), 정합 후 `/tide:fleet`을
   샌드박스에 한 번 더 돌려 실제 출력에 5버킷·`/tide:impl M{N}`·숨김 제외가 반영되는지 눈으로 확인
   권장(advisory 서술은 스크립트 강제 밖 — README 수동 절차). 비차단.

## 수정 내용

- 리뷰 중 **코드/문서 수정 없음**. impl이 양 셸 9/9로 통과했고, 병렬 T01·T02의 taxonomy 정합을
  확인했다(아래 검증). 권장 1(샌드박스 expect.ps1)은 레포 밖이라 리뷰 커밋에 포함하지 않고 릴리즈 후
  별도 동기화로 처리한다.

## 검증

- **라이브 하니스**: `sh tests/fleet/run.sh` → **PASS=9 / FAIL=0**, `tests\fleet\run.ps1` → **PASS=9 / FAIL=0**.
  회귀: `sh tests/multi-repo/run.sh` → exit 0(M13 가드 하니스 무영향).
- **검증 시나리오**: 발견(plain·notide·`.hidden-svc` 제외, 직속 1단계+숨김 무시), 5 position 분류 정확
  (release 가능/review 대기/impl 진행/보완 필요/milestone 필요), 숨김 미발견, 교차 요약 5버킷 1:1
  (`release=1 review=1 impl=1 milestone=1 fix=1`), graceful 강등.
- **T01↔T02 정합(병렬 산출물 일치)**: `skills/fleet/SKILL.md`와 `docs/conventions.md` "멀티 레포
  오케스트레이션" 절이 **동일 taxonomy**를 서술 — 5 position·advisory 인자(`/tide:impl M{N}`·
  `/tide:release v{추천}`)·1:1 5버킷 요약·숨김(dot) 무시. conventions가 단일 원본, 스킬이 인용함을 명시.
- **불변 보존**: fleet 읽기 전용·부수효과 분리(advisory만·cross-repo git 비자동화)·의존성 정렬 미지원
  (2층 전) 서술 유지. 1.0 안정성 절·커맨드 9종 framing 무변경.
- **제외 용어**: M15 신규/변경 텍스트(fleet 스킬·conventions 오케스트레이션 절·tests/fleet·M15 문서)에
  외부 저장소명 literal 0. 기존 `conventions.md:3`은 snippet 마커 밖(미변경). 빌드 출력 검증은 release/CI.
- **구현 중 수정 검증**: run.ps1 `git init` 순서 버그(디렉터리 선생성 `GitInit`)·ASCII 주석 정리 반영
  후 ps1 9/9 통과 재확인.

## 릴리즈 판정

**가능** — 추천 버전: **v1.2.1 (patch)**

- **완료 기준 충족**: fleet 스킬 5버킷·인자·숨김(기준 1), conventions 단일 원본 정합(기준 2), tests/fleet
  5-position·숨김·`보완 필요` 시나리오 양 셸 통과(기준 3), 전부 정합·견고화로 patch(기준 4) 모두 충족.
- **차단 이슈 처리**: 차단 0. 권장 1은 레포 밖(릴리즈 후 별도), 사소 2는 수용·저위험.
- **버전 근거**: 신규 기능·계약 변경 없이 fleet advisory 출력의 결정성과 스킬·규약·테스트 정합만 잡는
  정리 → SemVer **patch**. 마일스톤 목표 버전 v1.2.1과 일치.

## 다음 단계

- **릴리즈**: `/tide:release v1.2.1` — 프리플라이트(리뷰 "가능"·테스트·워킹트리·사이트 빌드 출력 제외 용어
  0건; mkdocs 미설치 시 CI) 후 배포. CHANGELOG 노트는 제외 용어 없이 "fleet 출력 정합(5버킷·인자·숨김)" 요약.
- **릴리즈 후**:
  - (권장 1) 샌드박스 `D:\Code\private\test\expect.ps1`를 5버킷·`/tide:impl M{N}`·숨김 무시로 동기화 +
    `/tide:fleet` 1회 재실행해 실제 출력 정합 확인(사소 3).
  - **별도 마일스톤(M16+)**: 오케스트레이션 2층(의존성/계약 선언 → 순서 인식). 샌드박스 유지된 멀티 레포
    픽스처가 테스트 베드로 재사용.
