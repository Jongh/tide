# M15 완료보고서 (impl)

## 개요

M15의 세 태스크를 모두 구현했다 — `/tide:fleet`의 advisory 출력을 **정규 분류 taxonomy**(5 position·
1:1 요약·인자 포함 권고·숨김 디렉터리 무시)로 통일해 스킬·규약·테스트 레퍼런스를 한 기준에 정합시켰다.
(T01) `skills/fleet/SKILL.md`, (T02) `docs/conventions.md` "멀티 레포 오케스트레이션" 절을 같은 taxonomy로
갱신하고, (T03) `tests/fleet/` 하니스를 5-position 분류·1:1 요약·숨김 무시·`보완 필요`(불가)로 정합해 sh·ps1
양쪽 **각 9/9 통과**시켰다. 기능 추가 없이 표기 정합·결정성만 높인 patch다. T01·T02는 병렬 서브에이전트,
T03은 메인이 수행했다.

## 태스크별 수행 내용

- **M15-T01** — `skills/fleet/SKILL.md`. 교차 요약을 `release 가능 N / review 대기 N / impl 진행 N /
  milestone 필요 N / 보완 필요 N`의 **5버킷 1:1**로 교체(impl·milestone 합산 서술 제거, 0건 버킷도 0으로
  명시). advisory 다음 행동 계획에 position→커맨드 매핑을 **인자 포함**해 고정: `impl 진행`→`/tide:impl M{N}`
  (마일스톤 번호 필수), `release 가능`→`/tide:release v{추천}`, `보완 필요`(불가)→보완 후 `/tide:impl M{N}`,
  `review 대기`→`/tide:review`, `milestone 필요`→`/tide:milestone`. 발견 절에 "이름이 `.`으로 시작하는
  숨김 디렉터리는 무시(`.git`·`.claude` 등)" 추가. 읽기 전용·부수효과 분리·의존성 정렬 미지원 서술은 유지.
- **M15-T02** — `docs/conventions.md` "멀티 레포 오케스트레이션" 절(snippet body 안쪽). advisory 계획 규칙을
  위 정규 taxonomy의 **단일 원본**으로 둠 — 5 position 1:1 요약·인자 포함 권고 매핑을 명시(스킬이 이를
  인용). 발견 규약에 숨김(dot) 디렉터리 무시 명문화. 의존성 정렬 미지원 포인트 유지, 1.0 안정성 절·커맨드
  수 서술 무변경, 제외 용어 누수 0(마커 안쪽 신규 텍스트에 외부 저장소명 없음).
- **M15-T03** — `tests/fleet/run.sh`·`run.ps1`·`README.md`. 참조 구현을 5-position taxonomy에 정합하고
  시나리오 보강: 픽스처를 repo-a(release 가능)·repo-b(review 대기)·repo-c(impl 진행)·repo-d(**보완 필요**=
  불가 리뷰)·repo-e(**milestone 필요**)로 5종 + 제외 케이스 plain(비-git)·notide(tide 산출물 없음)·
  **`.hidden-svc`(숨김)**. 검증 항목: 발견(숨김·비-tide 제외)·5분류 정확·`보완 필요`/`milestone 필요`·
  숨김 미발견·**교차 요약 5버킷 1:1**(`summarize` 참조 함수)·graceful 강등. sh·ps1 discover에 숨김(dot)
  무시 로직 반영(sh는 POSIX 글로브가 dotfile 미매치 + 명시 `case .*) continue`, ps1은 `-notlike '.*'` 필터).

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | (없음) |
| 수정 | `skills/fleet/SKILL.md` (T01); `docs/conventions.md` (T02); `tests/fleet/run.sh`·`run.ps1`·`README.md` (T03) |
| 삭제 | (없음) |

## 테스트 결과

자동 러너 없는 프로젝트라(도그푸딩) 라이브 하니스로 검증했다.

- **`sh tests/fleet/run.sh`** → **PASS=9 / FAIL=0 (exit 0)**.
- **`& tests\fleet\run.ps1`** → **PASS=9 / FAIL=0 (exit 0)**.

검증 시나리오(양 셸 공통): 발견 = tide 레포만(plain·notide·`.hidden-svc` 제외, 직속 1단계+숨김 무시),
5 position 분류 정확(release 가능/review 대기/impl 진행/보완 필요/milestone 필요), 숨김 디렉터리 미발견,
교차 요약 5버킷 1:1(`release=1 review=1 impl=1 milestone=1 fix=1`), tide 0개 → graceful 강등.

**구현 중 발견·수정한 이슈**
- (수정) **run.ps1 `git init` 순서 버그**: `& git -C $X init -q`를 디렉터리 생성 *전*에 호출해
  "cannot change to ... No such file or directory"로 실패 → .git 미생성 → discover 빈 결과. `GitInit`
  헬퍼(디렉터리 생성 후 init)로 교체해 해결(sh는 원래 `mkdir -p` 선행이라 무영향).
- (수정) **run.ps1 주석의 한글("불가")** → ASCII("blocked")로 정리(ps1 ASCII 소스 규약 유지 — 데이터
  토큰은 코드포인트 `$BAD`/`$OK`로 처리).

## 미해결·후속 메모

1. **샌드박스 `expect.ps1` 정합 필요(레포 밖)**: 사용자가 유지 중인 `D:\Code\private\test\expect.ps1`은
   M15 이전 taxonomy(4버킷, impl 인자 변동 가능)다. M15 정규 taxonomy(5버킷·인자 포함·숨김 무시)에 맞춰
   동기화하면 향후 fleet 실증이 깨끗이 대조된다(레포 릴리즈 범위 밖 — 별도 동기화, 리뷰/마무리에서 처리).
2. **참조 구현 ↔ 스킬 프롬프트 이중성(M14 이월)**: 정규 taxonomy를 conventions 단일 원본으로 못박아
   이중성을 완화했으나(스킬·테스트가 모두 conventions를 인용), 여전히 규약 변경 시 스킬·하니스·(샌드박스)
   expect를 함께 손봐야 한다. 저위험·구조적.
3. **fleet 세션 레벨 실동작 재확인**: 출력 형식 변경이므로, 정합 후 `/tide:fleet`을 샌드박스에 한 번 더
   돌려 5버킷·`/tide:impl M{N}` 인자·숨김 제외가 실제 출력에 반영되는지 눈으로 확인 권장(advisory 서술은
   스크립트 강제 밖 — README 수동 절차).
