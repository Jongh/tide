# M14 완료보고서 (impl)

## 개요

M14의 네 태스크를 모두 구현했다 — (T01) `project-context.md`의 버전 숫자를 제거해 `plugin.json`을
단일 원본으로 가리키게 해 **문서↔릴리즈 드리프트를 구조적으로 차단**하고, (T02) `conventions.md`에
"멀티 레포 오케스트레이션" 절(4계층 로드맵·부수효과 분리 불변·발견/계획 규약)을 신설하며 `/tide:fleet`을
**읽기 전용 9번째 가산 커맨드**로 등록했고, (T03) `skills/fleet/SKILL.md`를 작성해 자식 tide 레포
발견·교차 상태·advisory 계획을 구현했으며, (T04) `tests/fleet/` 라이브 하니스로 발견·분류·강등을
sh·ps1 양쪽에서 **각 5/5 통과**시켰다. 결과적으로 상위 폴더 단일 세션에서 여러 자식 레포 상태를 한
번에 보고 조정 계획을 받는 가시성 1층이 갖춰졌다. 단일 레포 동작·커맨드 8종은 불변(가산)이다.
L1(T01∥T02)은 병렬 서브에이전트로, T03·T04는 메인이 순차로 수행했다.

## 태스크별 수행 내용

- **M14-T01** — `docs/project-context.md`의 `- **버전**: 0.7.0 (...)` 줄을 `- **버전 원본**:
  `.claude-plugin/plugin.json` (이 문서는 버전 숫자를 복제하지 않는다 — 드리프트 방지)`로 교체.
  설계 결정: 드리프트 해법으로 "release에 갱신 단계 추가"(유지비↑) 대신 **복제 제거**(단일 원본
  포인터화)를 택했다 — tide의 단일 원본 철학이자 "규약↔실행 동기화" 메타 규칙의 문서판. 현황도
  갱신: 디렉터리 표에 `tests/`·`site/` 행, 테스트 항목에 `tests/multi-repo`(+`tests/fleet`) 하니스,
  도메인 개념에 멀티 레포 토대(M13)·fleet 개요(M14) 반영, 메타의 옛 "커밋 4개"는 "최초 감지 시점
  기준" 역사값으로 표기. `skills/release/SKILL.md` 운영 주의에 "release는 `plugin.json`만 범프하고
  project-context는 갱신하지 않는다(복제 제거로 드리프트 차단)" 한 줄 추가.
- **M14-T02** — `docs/conventions.md`(snippet body 영역 안쪽)에 `## 멀티 레포 오케스트레이션` 절
  신설: **4계층 로드맵**(①1층 가시성=이번, ②2층 의존성/계약 선언, ③3층 교차 사이클 자동화
  milestone→review, ④4층 통합 검증 — 2~4층은 후속 마일스톤), **부수효과 분리 불변**(cross-repo git
  비자동화·release 레포별 수동·fleet advisory만), **자식 레포 발견 규약**(직속 1단계 git AND tide
  산출물), **advisory 계획 규칙**(status 분류 재사용·의존성 정렬은 2층 전까지 미지원). `/tide:fleet`을
  사이클 다이어그램(읽기 전용 보조)·금지 행위 표(`파일·phase·git` 금지)·1.0 안정성 절(8종 불변 +
  fleet은 v1.2.0 가산)에 등록. 커맨드 8종 안정 claim 보존, 제외 용어 누수 0.
- **M14-T03** — `skills/fleet/SKILL.md` 신규 작성(프론트매터 `description`·`argument-hint`, status처럼
  template 불필요). 동작: 대상 부모(기본 세션 cwd, 선택 인자) 직속 하위에서 자식 tide 레포 발견 →
  각 레포 루트 기준 status 5항목 조회 → 레포별 표 + 교차 요약 + 레포별 advisory 다음 커맨드(의존성
  정렬 미지원 명시). 읽기 전용 강제, 발견 0이면 단일 레포로 graceful 강등. `skills/status/SKILL.md`에
  "여러 자식 레포는 `/tide:fleet`" 포인터 한 줄 추가.
- **M14-T04** — `tests/fleet/`에 라이브 하니스 작성·**실행**. fleet은 프롬프트 스킬이라 실행 바이너리가
  없어, 그 **결정적 핵심**(발견 규약 + status 분류)을 **동일 로직의 참조 셸 절차**로 재현해 픽스처
  (서로 다른 사이클 위치의 자식 5개)에 대해 검증한다. `run.sh`(POSIX)·`run.ps1`(PowerShell)·`README.md`.
  `run.ps1`은 ASCII 소스 유지 + 한글 판정 토큰("가능"/"불가")을 코드포인트(`[char]0xAC00`…)로 구성해
  BOM 의존 제거(M13 인코딩 교훈 계승). 차단 동사 미사용(발견은 `git init`만).

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `skills/fleet/SKILL.md` (T03); `tests/fleet/run.sh`·`run.ps1`·`README.md` (T04) |
| 수정 | `docs/project-context.md`·`skills/release/SKILL.md` (T01); `docs/conventions.md` (T02); `skills/status/SKILL.md` (T03) |
| 삭제 | (없음) |

## 테스트 결과

자동 테스트 러너가 없는 프로젝트라(도그푸딩) **라이브 실증 하니스**로 검증했다.

- **`sh tests/fleet/run.sh`** → **PASS=5 / FAIL=0 (exit 0)**.
- **`& tests\fleet\run.ps1`** → **PASS=5 / FAIL=0 (exit 0)**.
- **회귀**: `sh tests/multi-repo/run.sh` → exit 0(M13 가드 하니스 무영향 확인).

검증 시나리오(양 셸 공통): ① 발견 = tide 레포만(`repo-a`·`repo-b`·`repo-c`), 비-git(`plain`)·tide
산출물 없는 git(`notide`) **제외**(직속 1단계), ② 분류 정확 — repo-a=release-ready / repo-b=review-pending
/ repo-c=impl-inprogress, ③ tide 레포 0개 부모 → graceful 강등(빈 결과).

**구현 중 결정·처리한 사항**
- (설계) 오케스트레이션 에픽 전체가 한 사이클에 안 들어가므로 **1층(읽기 전용 가시성)만** 구현하고
  자동화 2~4층은 로드맵으로 분리(마일스톤 스코핑대로). cross-repo git 비자동화로 부수효과 분리 유지.
- (테스트 한계) fleet은 프롬프트라 advisory 서술은 스크립트로 강제 불가 → 결정적 핵심만 참조 구현으로
  덮고 서술 품질은 README 세션 레벨 수동 절차로 분리(M13 앵커링 수동 절차와 동일 분리 — 정직하게 명시).
- (인코딩) run.ps1의 한글 판정 토큰을 코드포인트로 구성해 ASCII 소스 유지 — M13의 run.ps1 인코딩
  교훈을 선제 적용(파서 오류 0).

## 미해결·후속 메모

1. **참조 구현 ↔ 스킬 프롬프트 이중성**: T04 하니스는 발견·분류 로직을 러너에 **재구현**해 규약의
   결정적 동작을 고정한다. 스킬 프롬프트가 단일 원본이고 하니스는 회귀 가드지만, 둘이 같은 규칙을
   각자 표현하므로 규약 변경 시 양쪽을 함께 손봐야 한다(리뷰에서 이 이중성의 수용/대안 판단 바람).
2. **fleet 세션 레벨 실동작 미실증**: 발견·분류·강등은 스크립트로 덮었으나, 실제 `/tide:fleet` 호출의
   출력 형식·advisory 서술·읽기 전용 준수는 상위 폴더 단일 세션에서 수동 확인 영역이다(README 절차).
   멀티 레포 실투입 전 1회 권장.
3. **다중 자리 마일스톤 정렬**: 참조 분류는 픽스처가 M1뿐이라 `sort -V`/`Sort-Object Name`으로 충분.
   실제 M10+ 다중 자리 정렬은 fleet 스킬이 status 규칙을 그대로 따르므로 동일하나, 하니스 픽스처는
   단자리만 덮는다(저위험).
4. **상위 오케스트레이션 2~4층**: 의존성/계약 선언·교차 사이클 자동화(review까지)·통합 검증 훅은
   후속 마일스톤. 특히 3층은 cross-repo git 비자동화 불변을 지켜야 한다.
5. **커맨드 9종 확장의 문서 정합**: project-context 디렉터리 표의 "스킬 8종" 서술은 T01 시점엔
   정확했으나 T03이 fleet을 추가했다 — 리뷰에서 9종 반영 여부를 점검 바람(가산 정합).
