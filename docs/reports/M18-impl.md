# M18 완료보고서 (impl)

## 개요

M18의 세 태스크를 모두 구현해 오케스트레이션 **3층(교차 사이클 자동화)**을 세웠다 — 새 커맨드
`/tide:fleet-cycle`(10번째)이 자식 tide 레포들의 `milestone → impl → review`를 의존성 순서로 교차
자동 실행하고 의존성 순서 release 핸드오프를 제시하되, **release·cross-repo git은 절대 자동화하지
않는다**(부수효과 분리 불변). (T01) 규약을 3층 활성으로 갱신하고 fleet-cycle 규약을 단일 원본화 +
10번째 커맨드를 등록했고, (T02) `skills/fleet-cycle/SKILL.md`를 신설(+fleet 포인터)했으며, (T03)
`tests/fleet-cycle/`에 처리 순서·release 제외·contract-blocked·downstream-skip 참조 구현과 시나리오를
더해 sh·ps1 양쪽 **각 21/21 통과**시켰다. 단일 레포·미선언 동작 불변(옵트인 가산), 커맨드 9종·1.0
계약 불변. T01·T02·T03은 마일스톤 정규 spec을 공통 인용해 **3-way 병렬** 수행했다.

## 태스크별 수행 내용

- **M18-T01** — `docs/conventions.md`("멀티 레포 오케스트레이션" 절, snippet body 안쪽): 로드맵 **③ 3층을
  활성**으로 갱신, 신규 `교차 사이클 자동화 (/tide:fleet-cycle)` 절을 단일 원본으로 추가(발견·위상정렬
  순서·레포별 앵커 cycle·**release 제외 불변**·M17 계약 인식 upstream-behind 보류·실패 시 downstream
  skip·집계/순서 release 핸드오프·발견 0 강등). 부수효과 분리 불변을 3층까지 확장. 10번째 커맨드를 사이클
  다이어그램·"단계별 금지 행위" 표(git 금지·release/cross-repo git 비자동화)·"1.0 안정성"(v1.5.0 가산)에
  등록. stable-8 + fleet(v1.2.0) framing 보존, 제외 용어 0.
- **M18-T02** — `skills/fleet-cycle/SKILL.md` 신설(프론트매터 `description`·`argument-hint`[부모 경로 선택],
  template 불필요). 발견·위상정렬(fleet/M16 재사용)·레포별 앵커(M13 cwd) `/tide:cycle` 의미(보고서 상태로
  시작점 → milestone→impl→review, 각 레포 `.tide/phase` 기록)·**release 절대 미실행**·계약 인식
  (upstream-behind→contract-blocked)·실패 시 downstream skip(독립 레포 계속)·집계 출력(처리 순서 표 +
  의존성 순서 release 핸드오프, 보류 사유 표기)·발견 0 graceful 강등. "부수효과 분리(불변)"에 절대 금지
  목록(release/git commit/tag/push/cross-repo git, milestone→review만 자동화). `skills/fleet/SKILL.md`에
  "순서대로 실제 실행은 `/tide:fleet-cycle`(release 제외)" 포인터 한 줄.
- **M18-T03** — `tests/fleet-cycle/run.sh`·`run.ps1`·`README.md`. tests/fleet 결정적 핵심(발견·deps 파싱·
  BOM strip·toposort·semver/계약) 재사용 + fleet-cycle 전용 참조 함수: **처리 순서**(위상정렬, 전이 포함),
  **release 제외**(자동 계획 단계 = `milestone impl review`만, `release` 부재·계획은 milestone 시작·review
  종료), **contract-blocked**(orders가 auth>=0.3.0 요구·auth 0.2.0→보류, gateway auth>=0.2.0→가능),
  **downstream skip**(역방향 도달 BFS — auth 중단 시 orders·gateway·notify[전이] skip, 독립 solo=ok;
  orders 중단 시 notify만 skip, gateway·solo ok). run.ps1 ASCII 소스(0 non-ASCII)·run.sh BOM 없음.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `skills/fleet-cycle/SKILL.md` (T02); `tests/fleet-cycle/run.sh`·`run.ps1`·`README.md` (T03) |
| 수정 | `docs/conventions.md` (T01); `skills/fleet/SKILL.md` (T02, 포인터) |
| 삭제 | (없음) |

## 테스트 결과

자동 러너 없는 프로젝트라(도그푸딩) 라이브 하니스로 검증했다.

- **`sh tests/fleet-cycle/run.sh`** → **PASS=21 / FAIL=0 (exit 0)** (BOM 없음).
- **`& tests\fleet-cycle\run.ps1`** → **PASS=21 / FAIL=0 (exit 0)** (non-ASCII 0).
- **회귀**: `sh tests/fleet/run.sh` → exit 0, `sh tests/multi-repo/run.sh` → exit 0.

검증 시나리오(양 셸): ① 처리 순서 = 위상정렬(auth가 orders·gateway보다, orders가 notify보다 앞, 전이
포함, 순환 아님), ② **release 제외 불변**(자동 계획 단계 = milestone·impl·review만, `release` 부재,
milestone 시작·review 종료), ③ contract-blocked(upstream-behind 의존 레포 보류 분류), ④ downstream skip
(중단 레포의 의존자 전이 skip, 무관 독립 레포 ok).

**구현 메모**
- T01·T02·T03이 마일스톤 정규 spec을 공통 인용해 3-way 병렬에도 정합(conventions=단일 원본, 스킬·테스트가
  인용). 메인이 양 셸 21/21 재확인.
- **release 제외 불변의 표상**: fleet-cycle은 프롬프트 스킬이라 실제 사이클 실행은 LLM 행위지만, 자동화
  계획을 고정 단계 시퀀스로 표상해 `release`가 자동 단계에 없음을 결정적으로 검증(프롬프트 불변을 스크립트로
  덮는 최선의 표상). 실제 cross-cycle 실행 품질은 README 세션 레벨 수동 절차로 분리.
- downstream skip은 역방향 도달(전이 의존자) BFS로 구현 — 한 레포 중단이 그에 의존하는 모든 레포(직·간접)에
  전파되고 독립 레포는 보존됨.

## 미해결·후속 메모

1. **참조 구현 이중성(이월·회고 군집)**: fleet-cycle도 프롬프트 스킬이라 tests/fleet-cycle가 처리 순서·
   release 제외·계약·downstream 로직을 재구현. conventions 단일 원본 인용으로 관리하나 구조적 이중성 잔존
   (M14~M17 회고가 유일 신규 반복 군집으로 식별, 저위험 수용). 규약 변경 시 스킬·하니스 동기화 필요.
2. **fleet-cycle 세션 레벨 실동작 미실증**: 처리 순서·release 제외·핸드오프의 결정적 핵심은 하니스로
   덮었으나, 실제 `/tide:fleet-cycle`이 상위 폴더에서 각 레포 milestone→review를 앵커 실행하고 **어떤
   레포에도 release/git이 일어나지 않으며** 순서 핸드오프를 내는지는 세션 레벨 수동 확인 영역(README).
   유지된 샌드박스(svc-* + 의존 그래프 + orders 계약 upstream-behind)로 릴리즈 후 1회 권장.
3. **연산자 확장·다중 자리 픽스처 등(이월)**: M17 후속 연산자 확장, 단자리 마일스톤 픽스처는 이번 범위 밖.
4. **4층(통합 검증 훅)**: 오케스트레이션 마지막 계층은 별도 마일스톤. cross-repo git 비자동화 불변 유지.
