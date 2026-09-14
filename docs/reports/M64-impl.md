# M64 완료보고서 (impl)

## 개요

측정 배당(판정의 책임처와 보고서 값의 출처를 가르는 선언)을 규약에 세우고(T01) impl·release 스킬과
impl 템플릿이 가리키게 했으며(T02), `tests/discover` 두 사본에 파트 선택 실행 경로를 세웠고(T03),
배당 선언의 정합을 하니스가 물게 했다(T04). **이번 실행은 두 번째 재작업이다**(리뷰 판정 `불가` 두 번).
라운드 1이 배당의 적용 범위를 참조 구현 저장소로 한정하고 태그 전 소비 조건을 세웠고, 라운드 2가
**`pr` 마무리의 CI 조회 실패 경로**를 닫고, 스킬에서 참조 구현의 축·잡 이름을 **직접 금지**했으며,
release 스킬 프리플라이트 2를 규약 문장 복제 없이 다시 썼다.

재작업 라운드(rework): 2

## 태스크별 수행 내용

- **M64-T01** — `docs/conventions.md`의 측정 시점 규율 블록(`measure-order:`·`measure-cache:`) 바로
  아래에 배당 선언을 두었다 — `measure-axis:` (값 `axis-judged-by-ci` `axis-valued-locally`) ·
  `measure-axis-job:` (값 `posix`) · **`measure-axis-names:`**(값 `sh dash bash pwsh` — 라운드 2). 산문으로
  배당의 근거 · 역방향 근거(`docs/reports/debug-2.md`) · 적용 범위 · 비공허 조건 넷 · 못 무는 것 · 집행을 적었다.
  - **라운드 1** — 병기어 정의를 대상 레포 일반의 문장으로 바꾸고 축·잡 이름을 「적용 범위」 불릿에
    참조 구현 저장소의 사정으로 한정했다. 비공허 조건에 ⓓ(판정이 태그 전에 소비된다)를 더하고 그것이
    성립하는 모드가 `pr` 하나임을 적었으며, CI 실행 식별자를 산출물에 적으라는 요구를 걷었다.
  - **라운드 2에서 고친 것** —
    - **조회 실패 경로를 닫았다**(리뷰 차단 1) — ⓓ 아래에 불릿을 더해 *"`gh` 부재·조회 실패는 보고도 결정도
      남기지 않으므로 그 경로에서 ⓓ는 성립하지 않는다"* 를 적고, 마무리가 **CI에 넘겨 로컬에서 생략했던
      축의 로컬 전수를 태그 전에 돌리고 실패하면 태그 없이 중단한다**는 절차를 규약으로 세웠다. 같은 규칙을
      `docs/conventions-release.md` PR CI 확인 항목의 「조회 불가도 말한다」 불릿에 세우고(그 파일이 릴리즈
      게시 절차의 단일 원본이다), 규약은 그 항목을 한 줄 안에서 실재 이름으로 가리키게 고쳤다(리뷰 사소 8).
    - **대상 레포 기본값을 적었다**(리뷰 권장 5) — *"대상 레포 자신의 규약에 배당 선언이 없으면 넘긴 축은
      없다"* 와 그 이유(플러그인 설치본으로 읽히는 선언은 참조 구현 저장소의 것).
    - **참조 구현의 축 이름을 선언했다**(`measure-axis-names:`) — 집행이 그 이름을 읽어 스킬에서 금지한다
      (리뷰 차단 2). 선언처가 두 줄에서 세 줄로 늘어 「선언처는 아래 세 줄뿐이다」로 고쳤다.
    - 「기계가 못 무는 것」의 집행 주장을 **실제 검사 형태 그대로** 적었다 — *"스킬 셋에 선언된 축·잡
      이름의 백틱 토큰이 없음 · 「백틱 이름 + 축」 형태가 없음까지"* 와, 묻지 않는 것(백틱 없는 이름 ·
      조회 실패 뒤 로컬 전수를 실제로 돌았는가).
- **M64-T02** — 세 자리에 배당을 가리키는 문면을 붙였다. 라운드 1이 축·잡 이름을 걷고 대상 레포 일반의
  문면으로 바꿨고, 재서술처 둘(`tests/discover/README.md` · `tests/site-includes/README.md`의 「실행」 절)을
  모드 조건에 맞췄다.
  - **라운드 2에서 고친 것** —
    - `skills/release/SKILL.md` 프리플라이트 2를 **다시 썼다**(리뷰 권장 4·5) — 규약 문장의 복제
      (*"태그를 다는 시점에 CI 실행이 없다"*)를 걷고, *"로컬에서 생략할 수 있는 축은 대상 레포 자신의 규약이
      측정 배당으로 CI에 넘긴 축뿐이고, 그것도 모드가 `pr`로 정해졌을 때만"* · *"배당 선언은 대상 레포
      자신의 규약에서만 읽는다 — 선언이 없으면 생략할 축도 없다"* · 조건이 **넷**이라는 포인터 · 규약 도달
      폴백(플러그인 설치본 — 프리플라이트 5와 같은 형태)을 적었다.
    - 같은 스킬의 `pr` 마무리에 *"`gh` 부재·조회 실패면 그 사실을 한 줄 알리고, 프리플라이트 2가 CI에 넘겨
      건너뛴 축이 있었으면 그 축을 로컬 전수로 돌린 뒤에만 진행한다 — 실패면 태그 없이 중단"* 을 넣었다.
    - `skills/impl/SKILL.md`의 *"넘길 수 있는 조건(릴리즈 모드)"* 를 *"조건(넷)"* 으로 고치고, 선언을 두지
      않은 대상 레포라면 템플릿 둘째 행이 「없음」임을 적었다. 이 줄은 처음에 규약 문장과 거의 같은 어순으로
      적었다가 아래 완료 기준 1의 대조 전에 고쳤다.
  - `docs/epics/E4.md` 사이클 배분 1에 *"릴리즈가 `pr` 모드일 때 — 성립 조건은 규약이 든다"* 를 더했다
    (리뷰 사소 9).
- **M64-T03** — 두 사본에 파트 선택 인자를 세웠다(`sh run.sh W` · `pwsh run.ps1 -Part W`). 케이스 계산
  구간을 파트 단위로 가드했고, 명단에 없는 표지는 FAIL · 부분 실행의 결과 줄은 접두가 다르며 `F1`은 전수에서만
  돈다. 새 케이스 `F18`·`F19`·`F20`. 서브에이전트가 기준선 재대조 직전에 멈춰 메인이 이어받아 대조를 마쳤다.
  라운드 1에서 하니스 README Part F 절의 드리프트 서술을 이력에 맞게 고쳤다.
- **M64-T04** — Part W를 넓혔다. 라운드 0: `W31`~`W41`(선언 유일성 · 추출 positive-control 셋 · 양방향
  결합 · 잡 실재 · 배선 · 꼬리 구분자). `W35`가 무는 러너 리터럴은 `tests/mutation`의 `# mutates-to:` 선언으로
  표현했다. 라운드 1: `W42`(스킬 셋에 「백틱 이름 + 축」 형태 없음)·`W43`(픽스처 통제). 리뷰가 형태를
  「공백 0개 이상」으로 넓혔다.
  - **라운드 2에서 더한 것** — **`W44`~`W48`**. 규약이 선언한 참조 구현의 축 이름과 지목한 잡 이름을 스킬
    셋에서 **백틱 토큰으로 직접 센다**(`W46`). 선언 유일성(`W44`) · 추출 positive-control(`W45` — 0이면 `W46`이
    잡 이름 하나만 세는 반쪽 검사가 된다) · 픽스처 통제(`W47` — 차이로) · 꼬리 구분자(`W48`). `W42`의 형태만으로
    지나가던 「로컬 값은 `pwsh`(과 5.1)」·「CI `posix` 잡」 같은 줄이 이제 붉다(되돌림 `backtick-pwsh-in-skill` ·
    `backtick-job-in-skill`).
    - **`W43` 픽스처를 두 줄로 늘렸다**(리뷰 사소 7) — 공백 하나 형태와 붙여 쓴 형태. 기댓값이 2가 되어
      정규식의 「공백 0개 이상」을 공백 하나로 되돌리면 `W43`이 붉다(되돌림 `w42-single-space-revert`).
    - **백틱 없는 이름은 여전히 묻지 않는다** — `sh`·`bash`는 맨 낱말·명령 조각으로 흔히 나와 맨 낱말 금지는
      오탐이 되고, 「이름 + 축」 형태는 release 스킬의 게시 가용성 축 서술(백틱 없는 `push` + 축)과 충돌한다.
      적대 변이 둘(`axis-name-unbacked` · `unbacked-pwsh-in-skill`)을 **초록으로 실측**해 고지로 처분했고,
      서술처는 규약 「기계가 못 무는 것」 · 하니스 README Part W 절 · 러너 주석이다.
    - `W46`의 기준선은 0이다 — 세 스킬에서 `` `sh` `` · `` `dash` `` · `` `bash` `` · `` `pwsh` `` · `` `posix` ``
      백틱 토큰을 `grep -nE`로 셌고 0줄이었다(아래 테스트 결과의 정적 확인과 같은 실행).

**「새 검사를 세울 때 함께 붙일 것」 대조** — 대상은 이 사이클이 세운 선언 키 셋과 케이스 `W31`~`W48`·
`F18`~`F20`이다.

| 항목 | 대조 |
|---|---|
| 1. 추출 positive-control | `W33`(값) · `W34`(잡) · `W35`(재서술처 토큰) · `W45`(참조 구현 축 이름) · `F18`(표지 명단 — 추출이 비면 빈 문자열로 붉음) |
| 2. 선언 줄 유일성 | `W31` · `W32` · `W44` |
| 3. 되돌림 실측 | 아래 표 33행. 새 케이스 21개 전부가 어느 행에서든 붉었다 |
| 4. 되돌림의 방향 둘 | `broken` 17행 · `adversarial` 16행. 초록으로 지나간 적대 변이 **2**(`axis-name-unbacked` · `unbacked-pwsh-in-skill`) — 둘 다 백틱 없는 이름이고 고지로 처분했다(위 T04, 사유: 맨 낱말 금지는 오탐이고 「이름 + 축」 전역 금지는 release 스킬의 정당한 서술을 붉힌다) |
| 5. 무는 대상 집합의 명세 | 재서술처는 발견이 아니라 **명시한 세 경로**(`skills/impl/SKILL.md` · `skills/impl/template.md` · `skills/release/SKILL.md`)라 확장자·숨김 의미론의 축이 없다. 형태(`axis-` 접두 토큰 · 「백틱 이름 + 공백 0개 이상 + 축」 · 선언된 이름의 백틱 토큰)는 하니스 README Part W 절에 적었다 |
| 6. 통제는 판정의 반응을 묻는다 | `W43`·`W47`은 차이(픽스처 − 실물)로 묻는다. `W39`·`F19`는 **인자로 준 토큰 하나만 읽어 기준선이 구조로 상수**인 자리이고 그 사유를 러너의 같은 자리 주석에 적었다(규약이 허용하는 예외 형태 ⑴) |

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | 선언 줄 유일성은 `W31`·`W32`·`W44`가 문다(아래 마지막 측정 PASS, 되돌림 `dup-ma-decl`·`dup-mj-decl`·`dup-names-decl` 단독 붉음). 복제 부재 — 검색 루트 레포 루트, 대상 파일 `skills/impl/SKILL.md` · `skills/impl/template.md` · `skills/release/SKILL.md`, 패턴은 규약 배당 블록과 `docs/conventions-release.md` PR CI 확인 항목의 정의·조건 문장에서 뽑은 고정 문자열 18개(`넘긴 축은 없다` · `넘긴 축도 없다` · `판정 없이 태그를` · `태그를 다는 시점` · `CI 실행이 없다` · `태그 전에 소비` · `태그 전에 돌리고` · `보고도 결정도` · `참조 구현` · `플러그인 설치본으로 읽히는` · `대상 레포 일반` · `막지 않는다` · `비용의` · `발견 루프` · `실제로 돈` · `어느 실행 환경에서 났는지` · `로컬에서 생략했던` · `조회 실패는 그 축의 판정이 없다`), 대조 항목은 「규약 문장을 옮긴 줄인가」. **히트 0**. 짧은 조각 둘을 따로 봤다 — `태그 없이 중단`은 release 스킬 139행(이번 마무리 절차의 조각)과 140행(HEAD부터 있던 버전 sanity)이고, `플러그인 설치본`은 세 스킬 공통의 규약 도달 폴백 문구다. 둘 다 규약 문장이 아니라 절차의 조각이라 대상 밖이다. **줄 단위 검색이 줄바꿈에 걸린 문장을 못 보는 한계**가 라운드 1에서 실제로 났으므로, 프리플라이트 2와 마무리 두 문단은 다시 쓴 뒤 사람이 문단 단위로 규약 문장과 대조했다 |
| 2 | 충족 | 교란 넷이 각각 붉었다(양 축). 선언 줄 삭제 `del-ma-decl` → `W31;W33;W37` · 값 하나 삭제 `del-ma-value` → `W37` · **스킬 문면의 축 이름을 선언에 없는 값으로** — ⑴ 값 토큰 `undeclared-skill-token` → `W36;W37` ⑵ 백틱 이름 + 축 `axis-name-backtick` → `W42` ⑶ 참조 구현 축·잡 이름의 백틱 토큰 `backtick-pwsh-in-skill` · `backtick-job-in-skill` → `W46` · 지목한 잡을 워크플로에 없는 이름으로 `job-decl-nowhere` → `W38`. **셋째 교란의 해석** — 라운드 1 이후 스킬 문면은 축을 병기어로만 가리키고 이름을 적지 않으므로, 「스킬 문면의 축 이름」 교란은 위 ⑴~⑶ 셋이다. 백틱 없는 이름은 묻지 않는다(`axis-name-unbacked` · `unbacked-pwsh-in-skill` 초록 — 위 T04의 경계) |
| 3 | 충족 | 없는 파트 표지 — `sh run.sh ZZ` · `pwsh -Part ZZ` 모두 FAIL · exit 1(아래 마지막 측정). 추출 대상을 비움 — `empty-part-labels` → `F18;F1b` 양 축 붉음 |
| 4 | 충족 | 인자 없는 전수가 `cases:` 선언과 같은 수를 낸다 — `F1`(총계)·`F1b`(파트별 내역 합) PASS(아래 마지막 측정). T03 시점의 기준선 줄 단위 대조(378 → 381, 차이가 신설 셋뿐)가 인자 없는 경로의 동형을 확인했고, 그 뒤 더한 케이스는 전부 신설이다 |
| 5 | 충족 | 전수 `# 결과:` / `# result:`, 부분 `# 부분 결과(Part W):` / `# partial result (Part W):`. `F20`이 같은 함수로 그 다름을 확인하고 `same-result-prefix`에서 단독으로 붉었다. 이 기준이 말하는 것은 **사람이 읽을 때의 어긋남**이다 — 보고서를 읽어 부분 총계를 찾는 집행은 없다 |
| 6 | 충족 | `docs/conventions.md` 배당 항목의 「배당이 `vacuous-pass`가 아닌 조건 넷」 불릿에 조건(발견 루프 · 차단 · 무스킵 · 태그 전 소비)과 *"넷 중 하나라도 깨지면 … `vacuous-pass`로 이름 붙인 부류가 된다"* 가 같은 불릿 안에 있다(마일스톤이 요구한 셋을 포함한다). 넷째가 깨지는 경로(조회 실패)와 그때의 절차가 바로 아래 하위 불릿에 있다 |
| 7 | 충족 | 양 축 전수를 **이 보고서가 존재하는 같은 트리**(라운드 2)에서 돌려 판정 집합을 대조했다 — 대상은 `tests/discover` 두 사본의 전수 출력(`sh` = Git Bash · `pwsh` 7.6.6), 대조 항목은 `PASS`/`FAIL`로 시작하는 결과 줄에서 뽑은 **「판정 + 케이스 ID」의 다중집합**(라벨 언어가 두 사본에서 달라 ID로 맞췄고, 이름 없는 통제 `W:` 등은 다중도로 센다), 비교는 정렬 후 `diff`. 결과 줄 수 399 = 399, (판정, ID) 묶음 311 = 311, **차이 0**. 두 축 모두 399/0이다 |
| 8 | 충족 | `docs/epics/E4.md`의 마커 블록에 `- M64 — …` 한 줄이 있고 `docs/milestones/M64.md`의 메타데이터가 `epic: E4`다(양방향) |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M64-impl.md` · `docs/reports/M64-review.md`(리뷰 산출물) |
| 수정 | `docs/conventions.md` · `docs/conventions-release.md` · `skills/impl/SKILL.md` · `skills/impl/template.md` · `skills/release/SKILL.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` · `tests/mutation/README.md` · `tests/site-includes/README.md` · `docs/epics/E4.md` |
| 삭제 | (없음) |

기준선은 이 단계 시작 시점의 워킹트리다. `docs/milestones/M64.md`와 `docs/epics/E4.md`는 **직전
단계들의 미커밋 산출물**이라 git 기준으로는 신규 파일이며(`E4.md`는 라운드 2가 한 문장을 고쳤다),
`docs/epics/E1.md`·`E2.md`·`E3.md`·`docs/reports/retro.md`도 이 사이클 이전의 미커밋 변경이다.
`docs/conventions-release.md`(라운드 2 — 조회 실패 절차) · `tests/mutation/README.md`(T04의 뮤테이션 선언) ·
`tests/site-includes/README.md`(라운드 1 — 재서술처 정합)는 마일스톤의 파일 변경 요약에 없던 파일이다.
리뷰가 두 라운드에 걸쳐 in-review로 고친 자리(하니스 README의 수·머리글, `W42` 정규식, 규약의 적용 범위
문장)도 이 트리에 들어 있다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (`pwsh` 7.6.6 Core) | `tests/discover` 전수 **399 / 0** · 20초 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 — CI `posix` 잡) | 릴리즈 단계에서 확인(`pr` 마무리의 PR CI 확인, 조회 실패 시 로컬 전수 — 후속 1·2) |

**마지막 측정** — 이 보고서를 쓴 뒤 같은 트리에서 돌렸다.

| 하니스 | 실행 환경 | 결과 |
|---|---|---|
| `tests/discover` | `pwsh` 7.6.6 | PASS=399 FAIL=0 · exit 0 · 20초 |
| `tests/discover` | Windows PowerShell 5.1 | PASS=399 FAIL=0 · exit 0 · 42초 |
| `tests/discover` | Git Bash `sh` (**이 사이클에 한해** — 기준 7의 근거) | PASS=399 FAIL=0 · exit 0 · 597초 |
| `tests/mutation` | `pwsh` 7.6.6 | PASS=11 FAIL=0 (선언 4) · 98초 |
| `tests/fleet` · `fleet-cycle` · `fleet-verify` · `multi-repo` · `site-includes` | `pwsh` 7.6.6 | 45/0 · 24/0 · 30/0 · 37/0 · 51/0 |

- **없는 파트 표지**(기준 3) — `sh run.sh ZZ` → `# 부분 결과(Part ZZ): PASS=0 FAIL=1` · exit 1 /
  `pwsh -Part ZZ` → `# partial result (Part ZZ): PASS=0 FAIL=1` · exit 1.
- **정적 확인** — `sh -n`·`dash -n` 통과. 줄 끝은 `run.sh` CR 0 · `run.ps1` CR 4939 = 줄 4939 ·
  `docs/conventions.md` 2732 = 2732 · `docs/conventions-release.md` 240 = 240 · `skills/impl/SKILL.md`
  113 = 113 · `skills/release/SKILL.md` 171 = 171. `run.ps1` 비-ASCII 0줄. `W46` 기준선 — 세 스킬에서
  `` `(sh|dash|bash|pwsh|posix)` `` 백틱 토큰이 든 줄 0.
- **동시 실행 조건** — `sh` 전수·5.1 전수·`pwsh` 하니스 여섯이 같은 시각에 돌았으므로 벽시계는 **경합
  조건의 값**이다. 판정 대조(기준 7)에는 닿지 않는다.
- **캐시가 아님의 확인**(`measure-not-cached`) — 하니스는 캐시 없는 셸 스크립트이고, 이번 실행들은 라운드
  2가 더한 다섯 케이스로 전수가 394 → 399로 **바뀐 값**을 냈으며 되돌림 기준선도 같은 399였다. 값이 이
  트리를 보았다는 근거가 그것이다.

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: W31 W32 W36 W37 W38 W40 W41 W42 W44 W46 W48 F18 F20 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| w42-single-space-revert | 두 사본의 `W42` 정규식 「공백 0개 이상」을 공백 하나로 되돌림 | broken | W43 | ps1 398/1 · sh Part W 49/1 |
| dup-names-decl | 같은 `measure-axis-names:` 선언 줄을 하나 더 둠 | adversarial | W44 | ps1 398/1 · sh Part W 49/1 |
| del-names-decl | 규약의 `measure-axis-names:` 선언 줄 삭제 | broken | W44;W45;W47 | ps1 396/3 · sh Part W 47/3 |
| names-unshaped | 이름 값을 이름 형태가 아닌 대문자로(줄은 남김) | broken | W45;W47 | ps1 397/2 · sh Part W 48/2 |
| tab-tail-names | `measure-axis-names:` 선언 줄 끝에 탭 한 글자 | adversarial | W48 | ps1 398/1 · sh Part W 49/1 |
| backtick-pwsh-in-skill | impl 스킬에 참조 구현 축 이름을 **백틱 토큰으로**(「축」 없이) | adversarial | W46 | ps1 398/1 · sh Part W 49/1 |
| backtick-job-in-skill | release 스킬에 지목한 잡 이름을 **백틱 토큰으로** | adversarial | W46 | ps1 398/1 · sh Part W 49/1 |
| unbacked-pwsh-in-skill | 같은 자리에 축 이름을 **백틱 없이** | adversarial | (없음 — 경계로 고지) | ps1 399/0 · sh Part W 50/0 |
| w47-fixture-break | 두 사본의 `W47` 픽스처에서 백틱을 뺌 | broken | W47 | ps1 398/1 · sh Part W 49/1 |
| axis-name-backtick | impl 스킬 문면에 축 이름을 **백틱으로** 적음(`powershell` + 축) | adversarial | W42 | ps1 398/1 · sh Part W 49/1 |
| axis-name-unbacked | 같은 자리에 축 이름을 **백틱 없이** 적음 | adversarial | (없음 — 경계로 고지) | ps1 399/0 · sh Part W 50/0 |
| w43-regex-break | 두 사본의 축 이름 판정 정규식이 아무것도 못 잡게 | broken | W43 | ps1 398/1 · sh Part W 49/1 |
| w33-values-unshaped | 선언 값을 이름 형태가 아닌 대문자로(줄은 남김) | broken | W33;W37 | ps1 397/2 · sh Part W 48/2 |
| w34-job-unshaped | 잡 값을 이름 형태가 아닌 대문자로(줄은 남김) | broken | W34;W38 | ps1 397/2 · sh Part W 48/2 |
| del-ma-decl | 규약의 `measure-axis:` 선언 줄 삭제 | broken | W31;W33;W37 | ps1 396/3 · sh Part W 47/3 |
| dup-ma-decl | 같은 `measure-axis:` 선언 줄을 하나 더 둠 | adversarial | W31 | ps1 398/1 · sh Part W 49/1 |
| del-mj-decl | 규약의 `measure-axis-job:` 선언 줄 삭제 | broken | W32;W34;W38 | ps1 396/3 · sh Part W 47/3 |
| dup-mj-decl | 같은 `measure-axis-job:` 선언 줄을 하나 더 둠 | adversarial | W32 | ps1 398/1 · sh Part W 49/1 |
| del-ma-value | 선언에서 값 `axis-valued-locally` 삭제 | broken | W37 | ps1 398/1 · sh Part W 49/1 |
| rename-tpl-token | impl 템플릿의 값 토큰을 접두가 다른 이름으로 | broken | W36 | ps1 398/1 · sh Part W 49/1 |
| undeclared-skill-token | impl 스킬의 값 토큰을 선언에 없는 `axis-` 이름으로 | adversarial | W36;W37 | ps1 397/2 · sh Part W 48/2 |
| orphan-release-token | release 스킬에 선언에 없는 값 토큰을 덧붙임 | adversarial | W37 | ps1 398/1 · sh Part W 49/1 |
| job-decl-nowhere | 선언이 지목한 잡을 `nowhere`로 | broken | W38 | ps1 398/1 · sh Part W 49/1 |
| wf-job-rename | 워크플로의 잡 키 `posix`를 다른 이름으로(선언은 그대로) | adversarial | W38;H7;H11 | ps1 396/3 · sh Part W 49/1 |
| tab-tail-ma | `measure-axis:` 선언 줄 끝에 탭 한 글자 | adversarial | W40 | ps1 398/1 · sh Part W 49/1 |
| tab-tail-mj | `measure-axis-job:` 선언 줄 끝에 탭 한 글자 | adversarial | W41 | ps1 398/1 · sh Part W 49/1 |
| nbsp-ma | `measure-axis:` 꼬리의 값 구분자를 NBSP로 | adversarial | W33;W37;W40 | ps1 396/3 · sh Part W 47/3 |
| wiring-break | 두 사본의 재서술처 결합 함수가 인자를 보지 않게 | broken | W39 | ps1 398/1 · sh Part W 49/1 |
| zzz-site-prefix | 두 사본의 재서술처 토큰 추출 리터럴 접두를 바꿈 | broken | W35 | ps1 398/1 · sh Part W 49/1 |
| empty-part-labels | README `cases:` 줄의 파트 표지를 전부 추출 불가 형태로 | broken | F18;F1b | ps1 397/2 · sh Part F 28/2 |
| relabel-part | README 내역의 표지 하나를 명단에 없는 표지로(수는 그대로) | adversarial | F18 | ps1 398/1 · sh Part F 29/1 |
| break-part-known | 두 사본의 표지 판정이 언제나 yes | broken | F19 | ps1 398/1 · sh Part F 29/1 |
| same-result-prefix | 두 사본의 부분 결과 접두가 전수 접두로 시작하게 | broken | F20 | ps1 398/1 · sh Part F 29/1 |

<!-- reversal-table:end -->

**기준선은 ps1 전수 399/0이다.** 33행 전부 라운드 2의 트리에서 **다시** 쟀다 — 앞 라운드의 값은 스킬 문면과
러너 정규식이 바뀌기 전의 것이라 옮겨 적지 않았다. sh 축은 **부분 실행**(`W` 또는 `F`)으로 쟀으므로 파트
밖의 붉음을 보지 못한다(`wf-job-rename`의 `H7;H11`이 ps1 전수에만 있는 이유). 두 축은 **모든 행에서 파트 안의
같은 케이스 집합**을 붉혔다.

- **방법** — 대상 파일 여덟(`docs/conventions.md` · 스킬 셋 · 워크플로 · 하니스 README · 러너 두 사본)의
  사본을 스크래치패드에 **경로를 키로** 뜨고 매 행 시작에서 복원했다. 변이는 바이트를 그대로 두는
  리터럴 치환이고 **한 줄 앵커만** 쓴다(CRLF 파일에서 여러 줄 앵커는 조용히 빠진다). 치환이 실패하면
  스크립트가 `MUTFAIL` 줄을 찍게 했고 33행의 출력 어디에도 그 줄이 없었다. 마지막에 여덟 파일을 사본과
  `cmp`로 대조해 **전부 같음**을 확인했다.
- **초록으로 지나간 적대 변이 2** — `axis-name-unbacked` · `unbacked-pwsh-in-skill`. 둘 다 백틱 없는 이름이며
  고지로 처분했다(위 T04).
- **통제 `W33`·`W34`·`W45`의 행** — 각각 전용 행이 있고 **단독으로 붉을 수는 없다** — 값 추출이 비면
  재서술처 토큰이 전부 선언 밖이 되어 `W37`이, 잡 추출이 비면 `W38`이, 이름 추출이 비면 픽스처의 첫 이름이
  사라져 `W47`이 **구조상 함께** 붉는다.
- **이 표를 잰 뒤의 편집 하나** — `skills/impl/SKILL.md` 110행의 문구를 바꿨다(규약 문장과 어순이 거의 같던
  줄 — 위 T02). 되돌림 앵커가 쓰는 108행과 병기어 토큰은 그대로이고, 편집 뒤 `pwsh -Part W`가 50/0이었다.
  아래 마지막 측정이 그 편집 뒤의 트리다.

## 미해결·후속 메모

1. **조회 실패 뒤 로컬 전수는 절차(프롬프트 규율)다** — 규약·릴리즈 규약·release 스킬이 같은 규칙을 들고
   있으나 *"실제로 돌았는가"* 를 묻는 기계는 없다. 릴리즈 단계의 보고에서 사람이 확인한다.
2. **이 저장소의 릴리즈 모드 설정은 `pr`이다** — 이 사이클의 릴리즈가 마무리의 PR CI 확인에서 `posix` 잡
   초록을 보고하거나, 조회 실패 시 `sh` 축 전수를 로컬에서 돌아야 배당이 성립한다.
3. **배당 조건 ⓐ~ⓒ와 「이번 릴리즈가 `pr` 모드였는가」는 기계가 묻지 않는다.** 누가 `posix` 잡에
   `continue-on-error`를 붙이거나 모드를 바꿔 릴리즈하면 `W38`은 여전히 초록이다.
4. **백틱 없는 축 이름은 묻지 않는다** — 경계로 고지했다(위 T04). 스킬 문면에 영문 축 이름을 백틱 없이 다시
   적는 편집은 리뷰의 자리다.
5. **같은 문단이 두 라운드 연속 반환되었다**(release 스킬 프리플라이트 2 · 규약 ⓓ). 라운드 0은 문면의 적용
   범위를, 라운드 1은 그 문면이 기대는 **다른 절차 문단**(마무리의 조회 실패)을 열었다. 한 문단의 주장이
   다른 문단의 절차에 기댈 때 **기대는 쪽 문단의 모든 분기**를 함께 읽어야 한다는 것이 이 두 라운드의 교훈이다.
6. **T03이 가드하지 못한 파트의 명단**은 하니스 README 「파트 선택 실행」 절의 표(항상 실행 셋)까지다.
   파트별 벽시계를 전부 재지는 않았다. 파트 선택은 `tests/discover`에만 있다.
7. **마일스톤 목표 문장이 구현보다 넓다**(라운드 0 리뷰 사소 8) — 부분 실행 결과가 보고서에 실리지 않음을
   기계로 고정하는 집행은 없고 `docs/epics/E4.md` 완료 신호의 해당 항목은 열려 있다.
8. **서브에이전트 중단이 트리를 편집 중 상태로 남긴다**(T03) — 회고 표의 「세션 편집 도구가 산출물을
   손상시키는 부류」와 같은 층이다.
9. **`.tide/NEXT-SESSION.md`가 M62 시점에 멈춰 있다** — git 추적 대상이라 다음 릴리즈 커밋에 낡은
   인수인계가 실린다. impl 단계는 그 파일을 고치지 않았다.
