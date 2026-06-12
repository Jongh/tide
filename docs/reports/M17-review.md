# M17 리뷰보고서 (review)

## 비판점

리뷰 결과 **차단 0건**. M17 세 태스크는 완료 기준을 충족하고, `/tide:fleet`이 `.tide/deps` `>= 버전`
계약을 비교해 `upstream behind` 경고를 내며 deps 파서가 BOM에 내성을 갖췄다. 병렬 산출물(규약·스킬·
테스트)이 정규 spec을 공통 인용해 일치한다.

### 차단 (0건)

없음. 옵트인 가산(버전 제약 없는 줄·BOM 없는 파일은 현행 동작)이고, fleet은 여전히 읽기 전용·
advisory만(경고도 차단·실행 아님). 위상정렬 순서·그래프는 버전 제약과 무관하게 불변, 커맨드 9종·
`.tide/phase`·tide-guard·1.0 계약·부수효과 분리 불변.

### 권장 (1건 — 후속 범위)

1. **연산자 확장** (M17-impl#1) — 이번은 `>=`(최소 버전)만 지원한다. `>`·`=`(정확)·`<=`·`<`(상한)은
   범위·핀고정 의존 표현에 쓰일 수 있어 자연스러운 다음 단계다. 의도적으로 제외했으니 차단이 아니며
   (미지원 연산자는 무시+경고로 안전 처리), 다음 사이클 후보다.

### 사소 (2건)

2. **참조 구현의 버전 파일 범위** — 실제 fleet 스킬은 의존 대상의 버전을 **모든 버전 파일 종류**
   (`package.json`/`Cargo.toml`/`pyproject.toml`/`plugin.json`)에서 읽지만, `tests/fleet`의 `ReadVersion`/
   `read_version` 참조 구현은 픽스처에 맞춰 **`package.json`만** 읽는다. 픽스처가 package.json이라 무영향
   이나, 다른 버전 파일 계약 비교는 세션 레벨/스킬 동작으로만 덮인다(저위험·수용). 더불어 semver 비교는
   `major.minor.patch`만 — pre-release/빌드 메타(`0.3.0-rc1`)는 **비교 생략(skip)**으로 보수 처리(오탐 없음).
3. **참조 구현 이중성 + 세션 레벨 upstream-behind 실증(이월/후속)** — 계약 비교·semver를 스킬 산문 +
   하니스가 각자 표현(conventions 단일 원본으로 완화). 실제 `/tide:fleet`의 `⚠ upstream behind` 출력은
   세션 레벨 수동 확인 영역 — 샌드박스 `svc-auth`(0.2.0)에 `svc-orders/.tide/deps`=`svc-auth >= v0.3.0`을
   넣고 1회 확인 권장(BOM 붙은 deps라 BOM 내성도 함께 실증됨).

## 수정 내용

- 리뷰 중 **코드/문서 수정 없음**. impl이 양 셸 23/23로 통과했고, T01·T02의 계약 비교 규칙 정합을
  확인했다(아래 검증). 권장 1·사소는 후속 성격이라 릴리즈를 막지 않으며 다음 단계로 명시한다.

## 검증

- **라이브 하니스**: `sh tests/fleet/run.sh` → **PASS=23 / FAIL=0**, `tests\fleet\run.ps1` → **PASS=23 /
  FAIL=0**(non-ASCII 0). 회귀: `sh tests/multi-repo/run.sh` → exit 0.
- **신규 시나리오**: 계약 만족(satisfied)·위반(violation/upstream behind)·연산자 외 무시(none)·버전
  파싱 불가(skip)·버전 제약 줄 토포 이름 의존 유지(auth 먼저)·BOM 내성(BOM+주석 첫 줄 무시·의존명 파싱·
  BOM'd 줄 계약 비교·BOM+의존명 매칭). 기존 15건 유지.
- **병렬 산출물 정합**: conventions "계약 비교 규칙"("순서 불변"·`⚠ upstream behind` 예시·advisory만·
  파싱 불가/미지원 연산자 경고만) ↔ fleet 스킬 ↔ tests/fleet이 동일 spec(`>=`만·semver major.minor.patch·
  BOM strip)을 서술. 통과 하니스가 결정적 동작을 고정.
- **불변 보존**: fleet 읽기 전용·부수효과 분리·정규 5버킷 요약(M15)·M16 위상정렬/순환/미선언 유지.
  위상정렬 순서는 버전 제약과 무관하게 불변. 1.0 안정성 절·커맨드 9종 framing 무변경.
- **제외 용어**: M17 신규/변경 텍스트(conventions 계약 절·fleet 스킬·tests/fleet·M17 문서) 외부 저장소명
  literal 0. 기존 `conventions.md:3`은 snippet 마커 밖(미변경). 빌드 출력 검증은 release/CI.

## 릴리즈 판정

**가능** — 추천 버전: **v1.4.0 (minor)**

- **완료 기준 충족**: 규약 계약 버전·BOM 단일 원본화(기준 1), fleet 제약 파싱·비교·`upstream behind`·BOM
  strip(기준 2), 하니스 계약 만족/위반/연산자외/파싱불가/BOM 시나리오 양 셸 통과(기준 3), 전부 가산·옵트인·
  advisory만(기준 4) 모두 충족.
- **차단 이슈 처리**: 차단 0. 권장 1(연산자 확장)은 후속, 사소 2건은 수용·저위험·수동 절차.
- **버전 근거**: 계약 버전 비교라는 **신규 능력**(의존 버전 미달 경고)이 옵트인 가산으로 더해진다 → minor.
  BOM 내성은 견고화(fix) 동반이나 버전은 큰 변경(신규 능력)을 따른다. 커맨드 9종·읽기 전용·부수효과
  분리·`.tide/phase` 계약 불변. 마일스톤 목표 v1.4.0과 일치.

## 다음 단계

- **릴리즈**: `/tide:release v1.4.0` — 프리플라이트(리뷰 "가능"·테스트·워킹트리·사이트 빌드 출력 제외
  용어 0건; mkdocs 미설치 시 CI) 후 배포. CHANGELOG는 제외 용어 없이 "2층 sub-step — `.tide/deps` `>=`
  계약 버전 비교(upstream behind 경고, 옵트인) + deps 파서 BOM 내성" 요약.
- **릴리즈 후**:
  - (사소 3) 샌드박스에 `svc-orders/.tide/deps`=`svc-auth >= v0.3.0` 추가 → `/tide:fleet`으로 `⚠ upstream
    behind`(svc-auth 0.2.0 < 0.3.0) 세션 실증.
  - **다음 마일스톤 후보**: (권장 1) `>`·`=`·`<=`·`<` 연산자 확장, 또는 **3층 — 교차 사이클 자동화**
    (`milestone→review`까지, release·cross-repo git 제외 불변). 유지된 샌드박스가 테스트 베드.
