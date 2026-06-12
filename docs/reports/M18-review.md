# M18 리뷰보고서 (review)

## 비판점

리뷰는 ultracode 적대적 검증 워크플로(release·cross-repo git 비자동화 **불변**을 3각도로 반증 시도 +
정합·완전성 감사)로 수행했다. **차단 0건**이나, 적대 검증이 안전 서술의 실질 결함 3건을 적발했고
**전부 리뷰에서 수정**했다. fleet-cycle의 실제 실행 경로에서 불변은 성립한다(어떤 레포도 release하지
않음)이 확인됐다.

### 차단 (0건)

없음. M18 4개 완료 기준 모두 충족, T01(규약)·T02(스킬)·T03(테스트) spec 정합, 10번째 커맨드 3곳
등록, 양 셸 하니스 통과. 단일 레포·미선언 동작 불변, 커맨드 9종·1.0 계약 불변.

### 권장 (3건 — **전부 리뷰에서 수정 완료**)

1. **release 제외의 "2층 기계 백스톱" 주장 과장** (적대 검증 refuter A·B·C 수렴) — 규약·스킬·마일스톤이
   release 제외를 "(a)프롬프트 (b)tide-guard 기계 강제"의 2층 방어로 서술했으나, **가드는 phase≠release인
   동안 git을 막는 *phase 잠금*이지 *release 차단기가 아니다*** — `/tide:release`는 git 전에 phase=release를
   먼저 써서 가드를 **푼다**. 즉 release 미발생의 실제 보장은 **프롬프트 규율**(fleet-cycle이 release를
   호출하지도, phase=release를 쓰지도 않음)이고, 가드는 그 레포의 git을 막는 백스톱일 뿐이다. → **수정**:
   `docs/conventions.md`·`skills/fleet-cycle/SKILL.md`의 release 제외/부수효과 분리 서술을 정밀화(가드 역할
   정확화, 실제 보장=규율 명시).
2. **stale phase=release + cross-repo cwd 누수 가능** (refuter B, 원 평가 blocking) — 가드는 디스크의 phase를
   읽어 판정하는데, 어떤 자식 레포가 **이전 중단된 수동 release의 잔재로 phase=release**로 남아 있으면
   가드가 그 레포의 git을 풀어줄 수 있다(cwd 규율이 프롬프트 규약이라 M13부터 스크립트 미강제 — 복합
   조건). fleet-cycle은 처리 전 자식 phase를 점검하지 않았다. → **수정**: 스킬·규약에 **사전 점검(필수)**
   추가 — 처리 시작 전 각 자식 `.tide/phase`를 읽어 `release` 잔재 레포는 **처리에서 제외·경고**(가드가
   풀린 레포에서 사이클을 돌리지 않음). 비차단으로 본 이유: 누수는 fleet-cycle이 만드는 경로가 아니라
   외부 손상 상태(중단된 release) + cwd 혼동의 복합이며, 사전 점검으로 그 경로를 막았다.
3. **release 제외 테스트가 동어반복** (refuter C, 원 평가 blocking) — `plan_stages`가 테스트 내부의
   하드코딩 리터럴 `milestone impl review`라, 단계열 검증이 "내가 쓴 문자열이 내가 쓴 문자열과 같다"에
   그쳐 불변을 강제하는 아티팩트(스킬 금지 목록·가드)와 **무결합**이다 — 금지 목록을 지워도 green.
   → **수정**: `tests/fleet-cycle/run.sh`·`run.ps1`에 **SKILL 아티팩트 결합 검증** 추가 — 실제
   `skills/fleet-cycle/SKILL.md`를 grep해 (a)금지 목록 산문(`release / git commit / … / cross-repo git`)과
   (b)phase=release 백스톱/사전점검 산문이 **존재함**을 단언(삭제 시 fail). ASCII 부분문자열만 매칭해
   run.ps1 ASCII 규약 유지.

### 사소 (3건)

4. **fleet-cycle 러너의 미지원 연산자/비표준 버전 미커버** — `>=` 정상 경로만. `>`·`=`·`<=`·`<`·비표준
   버전(conventions가 무시+경고로 규정)은 fleet(M16/M17) 러너가 다루므로 의도된 분리. 회귀 강건성 minor.
5. **failed 레포의 핸드오프 표기 통합 미실증** — `classify_on_failure`가 `failed`를 반환하나 핸드오프
   보류 분류와 연결한 테스트는 없음(출력 통합은 README 수동 절차 — LLM 행위 분리).
6. **가드 raw-$input grep 거칠음** (M13 기존) — cwd 경로 부분문자열로 거짓 차단 가능(안전 측 과차단).
   fleet-cycle 고유 경로 아님. 별도 가드 견고화 후보(M13 회고 이월).

## 수정 내용

- **이슈 1**: `docs/conventions.md`(부수효과 분리 불변 + 교차 사이클 자동화 절)·`skills/fleet-cycle/SKILL.md`
  (release 제외 + 부수효과 분리 절)의 백스톱 서술을 "가드는 phase 잠금(release 차단기 아님), 실제 보장은
  규율"로 정밀화.
- **이슈 2**: 위 두 파일에 **사전 점검(필수)** 추가 — 처리 전 phase=release 잔재 레포 제외·경고. 금지
  목록에 "어떤 레포의 `.tide/phase`를 `release`로 쓰기"를 명시 추가.
- **이슈 3**: `tests/fleet-cycle/run.sh`·`run.ps1`에 스킬 결합 검증 2건씩 추가(금지 목록·백스톱/사전점검
  산문 존재 grep).

## 검증

- **라이브 하니스(수정 후)**: `sh tests/fleet-cycle/run.sh` → **PASS=23 / FAIL=0**, `tests\fleet-cycle\run.ps1`
  → **PASS=23 / FAIL=0**(21→23, +결합 검증 2). run.ps1 non-ASCII 0, run.sh BOM 없음. 회귀: `sh tests/fleet/run.sh`
  exit 0, `sh tests/multi-repo/run.sh` exit 0.
- **적대 검증 결과**: 3 refuter 중 (A) 실제 실행 경로에서 불변 반증 실패(fleet-cycle은 어떤 레포도 release
  하지 않음), (B)(C) 과장 주장·stale phase·동어반복 테스트를 적발 → 전부 수정. 수정 후 불변의 보장 사슬이
  정확히 서술됨: **규율(release/phase=release 미기록) + 사전 점검(잔재 제외) + 가드 백스톱(phase≠release git
  차단)**.
- **감사(정합·완전성)**: T01·T02·T03이 동일 fleet-cycle spec(발견+위상정렬·앵커 milestone→review·release
  제외·contract-blocked·downstream-skip·핸드오프) 기술, divergence 0. 4개 완료 기준 met. 10번째 커맨드가
  사이클 다이어그램·금지 행위 표(git 금지)·1.0 안정성(v1.5.0 가산) 3곳 등록, stable-8 + fleet framing 보존,
  부수효과 분리 불변 3층 확장.
- **제외 용어**: M18 신규/변경 텍스트(conventions·fleet-cycle 스킬·tests·M18 문서) 외부 저장소명 literal 0.
  기존 `conventions.md:3`은 snippet 마커 밖(미변경). 빌드 출력 검증은 release/CI.

## 릴리즈 판정

**가능** — 추천 버전: **v1.5.0 (minor)**

- **완료 기준 충족**: 규약 3층 활성·fleet-cycle 단일 원본·10번째 커맨드 등록(기준 1), 스킬 발견·앵커
  milestone→review·release 제외·계약·downstream-skip(기준 2), 하니스 4핵심 + 결합 검증 양 셸 통과(기준 3),
  전부 가산·옵트인·부수효과 분리 불변(기준 4) 모두 충족.
- **차단 이슈 처리**: 차단 0. 적대 검증이 적발한 권장 3건(안전 주장 과장·stale phase 누수·동어반복 테스트)을
  **리뷰에서 전부 수정**해 안전 서술·방어·회귀 결합을 강화했다. 사소 3건은 수용·저위험·이월.
- **버전 근거**: 교차 사이클 자동화라는 **신규 능력**(여러 레포 milestone→review 의존성 순서 자동 + 순서
  release 핸드오프)이 새 커맨드 `/tide:fleet-cycle`로 가산 → minor. 단일 레포·미선언 불변, 커맨드 9종·읽기
  전용 fleet·부수효과 분리·`.tide/phase` 계약 불변. release·cross-repo git 자동화 제외(불변). 마일스톤 목표
  v1.5.0과 일치.

## 다음 단계

- **릴리즈**: `/tide:release v1.5.0` — 프리플라이트(리뷰 "가능"·테스트·워킹트리·사이트 빌드 출력 제외 용어
  0건; mkdocs 미설치 시 CI) 후 배포. CHANGELOG는 제외 용어 없이 "3층 — `/tide:fleet-cycle` 교차 사이클
  자동화(milestone→review 의존성 순서 + 순서 release 핸드오프, **release·cross-repo git 제외 불변**, 사전
  점검) 요약.
- **릴리즈 후**:
  - 세션 레벨 실증(README 절차): 샌드박스에서 `/tide:fleet-cycle` 실행 → 각 레포 milestone→review 앵커
    실행되고 **어떤 레포에도 release/git 미발생**, 순서 release 핸드오프(svc-orders contract-blocked 포함)
    확인. 특히 한 자식을 phase=release로 두고 **사전 점검이 그 레포를 제외**하는지 확인.
  - **다음 마일스톤 후보**: **4층 — 통합 검증 훅**(오케스트레이션 로드맵 마지막 계층, cross-repo git
    비자동화 불변 유지), 또는 M17 후속 연산자 확장(`>`·`=`·`<=`·`<`). 유지된 샌드박스가 테스트 베드.
