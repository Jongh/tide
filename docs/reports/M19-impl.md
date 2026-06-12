# M19 완료보고서 (impl)

## 개요

M19의 세 태스크를 모두 구현해 오케스트레이션 **4층(통합 검증)**을 세웠다 — 새 커맨드
`/tide:fleet-verify`(11번째)가 대상 부모의 통합 훅(`.tide-fleet/integration`, 옵트인·parent-level)을
읽어 부모 cwd에서 실행하고 **통합 pass/fail**을 보고한다. fleet-verify는 git·release·cross-repo git을
하지 않고 어떤 레포의 `.tide/phase`도 `release`로 쓰지 않는다(**verification-only 불변**). (T01) 규약을
4층 활성으로 갱신하고 통합 훅·fleet-verify·흐름을 단일 원본화 + 11번째 커맨드를 등록했고, (T02)
`skills/fleet-verify/SKILL.md`를 신설(+fleet-cycle 안내)했으며, (T03) `tests/fleet-verify/`에 훅 발견·옵트인
생략·pass/fail·verification-only·`.tide-fleet` 발견 무시 시나리오를 더해 sh·ps1 양쪽 **각 18/18 통과**시켰다.
**이로써 오케스트레이션 로드맵 1~4층이 모두 완성**됐다. 단일 레포·훅 미선언 동작 불변(옵트인 가산),
커맨드 10종·1.0 계약 불변. T01·T02·T03은 정규 spec 공통 인용으로 **3-way 병렬** 수행했다.

## 태스크별 수행 내용

- **M19-T01** — `docs/conventions.md`("멀티 레포 오케스트레이션" 절, snippet body 안쪽): 로드맵 **④ 4층을
  활성**으로 갱신("1~4층 모두 완성" 명기), 신규 `통합 검증 (/tide:fleet-verify)` 절을 단일 원본으로 추가
  (통합 훅 `.tide-fleet/integration` 옵트인·parent-level·BOM/주석 처리·부모 cwd 실행·발견 무시, fleet-verify
  발견·실행 exit0=pass/비0=fail·**verification-only 불변**·출력·fleet-cycle 흐름·훅 없음/발견 0 강등). 부수효과
  분리 불변을 4층까지 확장. 11번째 커맨드를 사이클 다이어그램·금지 행위 표(git 금지·verification-only)·1.0
  안정성(v1.6.0 가산)에 등록. 8종 stable·fleet/fleet-cycle framing 보존, 제외 용어 0.
- **M19-T02** — `skills/fleet-verify/SKILL.md` 신설(프론트매터 `description`·`argument-hint`, template 불필요).
  발견(fleet 규약·숨김 무시·`.tide-fleet` 미포함)·통합 훅 읽기(BOM 제거·주석/빈 줄 무시·없으면 graceful 생략)·
  부모 cwd 실행 exit0=pass/비0=fail(실패 요약)·출력 4부(대상 레포·훅 명령·결과·다음 안내)·**verification-only
  불변**(절대 금지: release/git commit/tag/push/cross-repo git/어떤 레포 phase=release 쓰기; 훅은 검증/테스트
  명령이어야 함 명시; tide-guard 백스톱)·발견 0 강등. `skills/fleet-cycle/SKILL.md` 핸드오프에 "release 전
  `/tide:fleet-verify`로 통합 확인(훅 선언 시)" 안내 한 줄.
- **M19-T03** — `tests/fleet-verify/run.sh`·`run.ps1`·`README.md`. 참조 구현 + 시나리오 5종: ① 훅 발견/파싱
  (BOM 제거·주석/빈 줄 무시, 명령 추출), ② 옵트인 생략(파일 없음/유효 줄 0 → skip), ③ pass/fail 분류(모의 훅
  exit 0/1·다중 단계 중 하나라도 비0→fail, git 동사 미사용), ④ verification-only(자동 계획에 release/git 단계
  없음 + **SKILL 산문 결합** grep: 금지 목록·verification-only 산문 존재), ⑤ `.tide-fleet/` 숨김 → 발견 무시
  (자식 레포만). run.ps1 ASCII 소스(0 non-ASCII)·run.sh BOM 없음.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `skills/fleet-verify/SKILL.md` (T02); `tests/fleet-verify/run.sh`·`run.ps1`·`README.md` (T03) |
| 수정 | `docs/conventions.md` (T01); `skills/fleet-cycle/SKILL.md` (T02, 안내 한 줄) |
| 삭제 | (없음) |

## 테스트 결과

자동 러너 없는 프로젝트라(도그푸딩) 라이브 하니스로 검증했다.

- **`sh tests/fleet-verify/run.sh`** → **PASS=18 / FAIL=0 (exit 0)** (BOM 없음).
- **`& tests\fleet-verify\run.ps1`** → **PASS=18 / FAIL=0 (exit 0)** (non-ASCII 0).
- **회귀**: `sh tests/fleet-cycle/run.sh` exit 0, `sh tests/fleet/run.sh` exit 0, `sh tests/multi-repo/run.sh` exit 0.

검증 시나리오(양 셸): 훅 발견/파싱(BOM·주석·빈 줄), 옵트인 생략(skip), pass/fail(exit 코드 매핑), verification-only
(자동 계획에 release/git 없음 + 스킬 산문 결합), `.tide-fleet` 발견 무시.

**구현 메모**
- T01·T02·T03이 마일스톤 정규 spec 공통 인용 → 3-way 병렬에도 정합. 메인이 양 셸 18/18 재확인.
- **verification-only 표상 + 스킬 결합**: M18 패턴 계승 — 자동 계획에 release/git 단계 부재를 표상하고, 실제
  불변을 강제하는 스킬 산문(금지 목록·verification-only)을 grep해 결합(회귀 시 fail). T03이 SKILL 결합 anchor를
  `phase=release`(fleet-cycle 고유 토큰) 대신 `verification-only`(fleet-verify 스킬에 6회 등장)로 잡은 것은
  정확한 판단(스펙의 OR 충족).
- 통합 훅은 **parent-level**(`.tide-fleet/`, cross-repo 개념) — `.tide/deps`(레포별)와 대비. 숨김이라 발견 무시.

## 미해결·후속 메모

1. **통합 훅이 공격 표면(verification-only는 훅 작성자 책임)**: fleet-verify 자체는 git/release를 안 하지만,
   통합 훅은 **프로젝트 정의 명령**이라 작성자가 git/release를 넣을 수 있다. 규약·스킬이 "훅은 검증/테스트
   명령이어야 함"을 명시하고 tide-guard가 phase≠release 레포의 git을 막는 백스톱이나, 훅이 자식 레포에서
   stale phase=release를 만나면 M18과 동일한 false-allow 가능(복합 조건). 리뷰에서 백스톱 정밀도·문서 명시
   점검 바람.
2. **fleet-verify 세션 레벨 실동작 미실증**: 훅 발견·옵트인·pass/fail 결정적 핵심은 하니스로 덮었으나, 실제
   `/tide:fleet-verify`가 부모에서 훅을 돌리고 **어떤 레포에도 release/git 미발생**·결과 보고하는지는 세션 레벨
   수동 확인 영역(README). 샌드박스에 `.tide-fleet/integration` 선언으로 릴리즈 후 1회 권장.
3. **참조 구현 이중성(이월·회고 군집)**: fleet-verify도 프롬프트 스킬이라 tests/fleet-verify가 훅 파싱·분류
   로직 재구현. conventions 단일 원본 인용으로 관리(저위험 수용).
4. **로드맵 완성 후**: 1~4층 완성. M17 연산자 확장(`>`·`=`·`<=`·`<`) + 1~4층 완성 누적 회고가 후속 후보.
