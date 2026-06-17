# M24 완료보고서 (impl)

## 개요

M24의 4개 태스크를 모두 구현했다. **①** `/tide:release`에 `gh` CLI 옵트인 게시 모드(`pr`/`release` 택1)를
더했다 — 규약 단일 원본을 `docs/conventions.md`에 신설하고, 사용자 보강 4종(모드 미지정 시 대화형 선택·
git/gh 명령 검증·첫 선택 기억 `.tide/release-mode`·원격 미등록 처리)을 절차에 반영했다. **②** M23 후속 sn2를
종결해 `read_deps`/`ReadDeps`(+`strip_bom`/`dep_name`)를 `tests/lib/deps.{sh,ps1}` 공유 라이브러리로 추출하고
fleet·fleet-cycle 하니스를 source로 전환했다. 의존 위상은 Level0(T01·T03 병렬) → Level1(T02) → Level2(T04)로
스케줄했고, T01·T03은 파일 비중첩이라 서브에이전트 2개로 동시 실행했다.

## 태스크별 수행 내용

- **M24-T01** — `docs/conventions.md`에 **"릴리즈 게시 (gh)"** 절을 신설(버전·CHANGELOG 절 뒤, 단계별 금지
  요약 절 앞, 사이트 스니펫 마커 안쪽). 게시 모드의 단일 원본으로 검증 게이트(git→gh→인증→원격 GitHub 등록
  4단계)·모드 우선순위(명시 인자 > `.tide/release-mode` > 대화형)·선호도 기억·`release`(가산)/`pr`(분기) 두
  흐름·원격 불가 처리·명시 의도 비폴백·부수효과 분리(tide-guard 비확장 사유)를 규정. 검증을 commit/push **전**에
  둔다는 설계 요점 명시. release 스킬은 이 절을 참조만 한다(스킬=절차, conventions=규약 분담).
- **M24-T02** — `skills/release/SKILL.md`에 게시 모드 구현. 인자 파싱을 버전+모드 토큰으로 확장하고,
  프리플라이트·phase 기록·버전 범프·CHANGELOG 단계는 현행 유지한 채 그 뒤에 **게시 모드 해석·검증 → 게시
  분기(push-only / `release` / `pr`) → 원격 불가 처리**를 추가. 상세는 재서술하지 않고 conventions "릴리즈
  게시 (gh)" 절을 참조. 운영 주의에 gh 항목(5번) 추가 — 게시 명령도 phase=release에서만, 멀티라인 본문·제외
  용어 규약, 검증을 부수효과 전에.
- **M24-T03** — `tests/lib/deps.{sh,ps1}` 신설(`read_deps`/`ReadDeps` + 보조 `strip_bom`/`dep_name`/`DepName`,
  ps1은 공유 `DepLines`도 포함해 계약 함수 중복까지 제거). 식별한 드리프트: sh `read_deps`(fleet awk+sed ↔
  fleet-cycle sed 2단)·ps1 `DepName` 정규식(fleet `(>=|<=|==|=|>|<).*$` ↔ fleet-cycle `\s*[<>=].*$`). **정본
  = fleet판**(상세·M17 BOM·M20 전체 연산자 이름 보존). fleet·fleet-cycle 양 셸을 source로 전환(순서
  discover→deps→toposort), `toposort.{sh,ps1}`는 주석만 새 source 순서로 갱신(본문 무변경). 계약 비교 전용
  함수는 추출 범위 밖이라 fleet 로컬 유지.
- **M24-T04** — 카탈로그·컨텍스트 동기화. `docs/commands.md`의 release 행/절에 gh 게시 모드 반영(커맨드 11종·
  셸·이름 가드 불변 — `/tide:release ` 토큰·"11종" 선언 유지). `skills/release/SKILL.md` frontmatter
  `argument-hint`를 `v0.1.0 [pr|release]`로 갱신. `docs/project-context.md`의 `.tide/` 행에 `release-mode`,
  `tests/` 행에 `tests/lib/deps`(source 순서), "릴리즈 위생" 개념에 gh 게시 모드 단일 원본 포인터 추가.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `tests/lib/deps.sh`, `tests/lib/deps.ps1` |
| 수정 | `docs/conventions.md`(릴리즈 게시 절), `skills/release/SKILL.md`(gh 모드 분기 + 운영 주의 + arg-hint), `tests/fleet/run.sh`·`run.ps1`, `tests/fleet-cycle/run.sh`·`run.ps1`(deps source 전환), `tests/lib/toposort.sh`·`toposort.ps1`(주석), `docs/commands.md`(release 행/절), `docs/project-context.md`(`.tide/`·`tests/`·릴리즈 위생) |
| 삭제 | 없음 (하니스 로컬 함수 정의 제거는 파일 삭제 아님) |

런타임 상태 `/.tide/release-mode`는 release 실행 시 선호도 저장으로 생성되며 impl이 만드는 파일이 아니다.

## 테스트 결과

자동 러너가 없는 플러그인이라 **자기완결형 라이브 하니스**(양 셸)로 검증했다. 전 러너 exit 0, **M23 베이스라인과
동일 PASS 수**(동작 보존):

| 하니스 | sh | ps1 |
|---|---|---|
| discover | PASS=19 FAIL=0 (N=11, B1/B2/B3 가드 정합) | PASS=19 FAIL=0 |
| fleet | PASS=41 FAIL=0 | PASS=41 FAIL=0 |
| fleet-cycle | PASS=23 FAIL=0 | PASS=23 FAIL=0 |
| fleet-verify | PASS=29 FAIL=0 | PASS=29 FAIL=0 |
| multi-repo | PASS=10 FAIL=0 | PASS=10 FAIL=0 |

추가 검증:
- **단일 원본화 실증(sn2)**: fleet·fleet-cycle의 로컬 `read_deps`/`ReadDeps`/`dep_name`/`DepName`/`strip_bom`
  정의 = **0**(source + 브레드크럼 주석만). fleet-cycle이 정본 deps로 통과 → 두 구현의 로직 동등성 실증.
- **인코딩 규율**: `tests/lib/deps.ps1`·`toposort.ps1` 비ASCII 바이트 **0**, 신규/수정 셸·라이브러리 8개 모두
  **BOM 없음**.
- **드리프트 가드 불변(T04)**: 카탈로그 편집 후에도 discover B1(11종 선언 정합)·B2(사이트 셸)·B3(이름 완전성)
  전부 통과 — 커맨드 수·셸·이름 불변.

## 미해결·후속 메모

1. **게시 모드는 라이브 하니스 대상이 아님** — `/tide:release`의 gh 분기(`pr`/`release` 흐름, 검증 게이트,
   `.tide/release-mode` 선호도, 원격 불가 처리)는 프롬프트 스킬이라 자동 테스트로 덮이지 않는다. 리뷰에서
   절차 정합(검증을 부수효과 전에 둠·명시 모드 비폴백·tide-guard 비확장)과 conventions↔SKILL 분담을 정적
   검토로 확인 필요. 실제 `gh` 게시는 다음 release 도그푸딩 시 라이브 회수.
2. **`pr` 모드 머지 후 태그/릴리즈 핸드오프** — `pr` 모드는 "PR 열림"까지만 하고 태그·GitHub 릴리즈를 머지
   후로 미룬다. 머지 후 후속 단계(태그·릴리즈 생성)를 사람이 수동으로 하는지, 별도 경로를 둘지는 이번 범위
   밖 — 차기 마일스톤 후보(저위험).
3. **fleet-verify의 `strip_bom`/`StripBom` 미추출** — fleet-verify는 `read_deps`/`toposort` 미사용이라 sn2
   범위 밖으로 의도적 미변경. 자체 `strip_bom`이 남아 있으나 deps 파싱과 무관(저위험 향후 정리 후보).
