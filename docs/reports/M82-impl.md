# M82 완료보고서 (impl)

## 개요

M82의 네 태스크를 구현했다. 규약 "회고 후속 항목의 소비" 절의 순서 판정 갈래(옛 산문 ⑴~⑷)를 이름 선언 `retro-order-branches:` · 값 선언 `retro-order-verdict:` · 이름별 정의 항목으로 올렸고(T01),
두 러너의 순서 판정은 갈래 이름을 내고 이름과 값을 선언에서 읽는다(T02 · Part O `O60`~`O87`). `N58`의 경계 비교 필터에는 접미 ID 합성 러너 통제 `N63`을 더했고(T03 · `rf-87`), 하니스 README를 맞췄다(T04).
네 태스크가 의존 사슬(T01 → T02 → T03 → T04)이고 T02 · T03이 같은 두 러너 파일을 고치므로 메인이 순차로 구현했다.

**라운드 1** — 리뷰 라운드 0이 판정 `불가`로 반환했다(차단 1: 선언에 갈래를 하나 더해도 초록 · 권장 2: 절 안 갈래 이름 잔재 · 사소 6: 상태표의 후처리 추적). 반환 태스크 셋을 닫았다 —
R1 갈래 이름 수 = 러너 조건 수(`O84` · 통제 `O85`) · R2 규약 파일 안 `ro-` 백틱 토큰이 전부 선언된 이름(`O86` · 통제 `O87`) · R3 상태표에 ⑼ · ⑾ · ⒂ · ⒃ · ⒄의 태그 뒤 후처리 후 행. 되돌림과 상태표를 라운드 1 트리에서 다시 쟀다.

재작업 라운드(rework): 1

## 태스크별 수행 내용

- **M82-T01** — `docs/conventions.md` "회고 후속 항목의 소비" 절.
  - 「갈래는 넷이다」와 ⑴~⑷ 산문을 선언 두 줄(`retro-order-branches:` ro-first ro-release-commit ro-milestone-ahead ro-behind · `retro-order-verdict:` 이름=ok|no)과 이름별 정의 항목 넷으로 바꿨다. 정의 항목은 옛 문단의 문장(조건 · M69 · M70 판례 · ⓐ ⓑ 두 경로 · 복구)을 그대로 옮겼고 뜻을 바꾸지 않았다. `ro-behind`에는 옛 판정이 이미 하던 「회고 기준 버전이 빔」을 조건으로 적었다(옛 `backstop_verdict`의 첫 두 조건이 `-n "$1"`을 요구했다).
  - 「선언의 이름 순서가 러너가 갈래를 시험하는 순서다」와 「이름과 값을 러너 소스에 박지 않는다」를 선언 앞 문장에 적었다.
  - 「기계가 묻는 것」 · 「묻지 않는 것」 문단을 더했다(아래 고지 대응표). 라운드 1에서 「갈래 이름의 수가 러너의 조건 수와 같다」 · 「규약 파일 안에서 ro-로 시작하는 백틱 토큰이 전부 선언된 갈래 이름이다」를 더했고, 「묻지 않는 것」에 「러너 조건 · 조건 수 · 선언을 모두 함께 늘린 편집에서 새 조건이 옳은 이름에 붙는가」 · 「규약 파일 밖의 갈래 이름 토큰」을 더했다.
  - 같은 절에서 번호로 가리키던 두 자리(「위 ⑶의 정의다」 · 「⑶이 붉으면」)와 생명주기 갈래 표의 「백스톱」 열(열두 칸)을 갈래 이름으로 바꿨다.
  - **재서술처 훑기** — 패턴 `갈래는 넷|갈래 넷|넷째 갈래|⑶이 붉|⑷ \*\*그 밖`과 `둘째 머리|둘째와 같|갈래는 규약|⑶이 붉|⑵ 둘째|백스톱 갈래` · 대상 저장소 전체 파일(`docs/reports/` · `docs/milestones/` 제외 — 사이클 이력) · 대조 항목 「순서 판정의 갈래를 번호나 수로 재서술한 문장」 · 루트 저장소.
    결과: 규약 이 절 밖의 재서술은 없다. **절 안의 생명주기 갈래 표 「백스톱」 열(열두 칸 · ⑴~⑷)은 이 훑기 패턴이 놓쳤고**, 완료 기준 1 대조에서 찾아 갈래 이름으로 바꿨다. `skills/retro/SKILL.md`의 「갈래는 규약이 적는다」는 포인터라 그대로 두었다. `tests/discover/README.md`의 Part O 서술은 `O37`을 이름으로 가리키므로 T04가 새 소절만 더했다. `CHANGELOG.md`는 릴리즈 이력이라 고치지 않는다. ~~Part L은 이 절의 「넷」을 묻지 않았다~~ — **리뷰 사소로 정정**: Part L은 살아 있는 문서 전체를 훑으므로 HEAD의 「갈래는 넷이다」를 ⑴~⑷ 열거 수와 대조하고 있었다(리뷰 반증 실측 — HEAD 사본에서 「셋이다」로 바꾸면 Part L 12/1). 라운드 0은 그 수를 지우고 갈래 **수**를 무는 자리를 세우지 않았다(리뷰 차단 1) — 라운드 1의 `O84`가 그 자리다.
- **M82-T02** — `tests/discover/run.sh` · `tests/discover/run.ps1`.
  - 옛 `backstop_verdict` · `BackstopVerdict`를 갈래 이름을 내는 `ro_branch` · `RoBranch`(조건 넷 — 순서가 선언 순서)와 값을 읽는 `ro_pairs` · `ro_value` · `RoPairs` · `RoValue`로 갈랐다. `backstop_verdict`는 그 둘의 합성이고 값이 `ok`일 때만 ok다 — 이름이 비거나 값이 없거나 `ok` 밖이면 no로 넘어진다.
  - 선언 읽기는 M79의 공용 헬퍼(`dn_names` · `dn_dup` · `dn_def_bad` · `dn_def_orphan` · `dn_def_order` · `Dn*`)를 그대로 쓴다. 값 쌍은 `floor-ask-cases:`와 같은 꼴(백틱 없는 `이름=값` 토큰)이라 `dn_names` 뒤에 `=` 거름을 둔다.
  - 판정 함수는 규약 파일을 선택 인자로 받는다. 합성 규약(`ro_fixture` · `RoFixture` — 갈래 넷과 정의 넷만 든다, 모드 아홉)을 먹여 변환마다 통제를 둔다(`rf-88`).
  - **출력 동일과 무는 범위**(M79 회고 메모 3) — `O18` · `O36`~`O40`의 기대값은 HEAD와 같고 두 러너에서 초록이다(출력 동일). 무는 범위는 **넓어졌다** — 옛 판정은 네 버전 값만 읽었고, 새 판정은 규약의 두 선언도 읽는다. 그래서 선언이 깨지면 실제 트리의 `O18`이 함께 붉을 수 있다(되돌림 `ro-val-flip`이 그 예다). 판정 조건 자체는 바뀌지 않았다 — 같은 네 값에 대해 같은 갈래로 떨어진다(아래 생명주기 상태표).
  - 라운드 0은 Part O에 24 케이스를 더했다 — 선언 정합 `O60`~`O69` · 갈래 고정 `O70`~`O74` · 변환 통제 `O75`~`O83`. 판정이 읽는 변환은 다섯이다: 이름 위치(`O75`) · 값 읽기(`O76`) · 값 쌍 파싱(`O77`) · 버전 추출(회고 머리 `O17` · CHANGELOG 첫째 · 둘째 `O78` · 기반 버전 `O39` · `O40`) · 선언 판정 헬퍼의 배선(`O79`~`O83`).
  - **라운드 1 (R1 · R2)** — 러너의 조건 수를 한 자리(`RO_CONDS` · `$RO_CONDS` = 4)에 두고 `ro_branch`의 마지막 갈래가 그 값을 쓰게 했다. 본 검사 `O84`(`ro_count_bad` · `RoCountBad` — 선언된 이름 수 = 조건 수)와 통제 `O85`(갈래를 하나 더한 합성 규약 `add`), 본 검사 `O86`(`ro_stray` · `RoStray` — 규약 파일 안 ro-로 시작하는 백틱 토큰이 전부 선언된 이름)과 통제 `O87`(합성 규약 `stray`)을 더했다. 갈래 고정은 이름을 위치로 읽으므로 선언에 이름이 끼어들어도 참이었다 — `O84`는 이름의 **수**를 위치와 무관하게 센다.
  - ps1 사본은 ASCII만 쓴다(`[^\x00-\x7F]` 0줄).
- **M82-T03** — 대응 없는 접미 ID 케이스(`N98b`) 하나만 든 합성 러너 두 벌(`fa_suffix_fixture sh|ps1` · `FaSuffixFixture`)을 `fa_case_unmapped` · `FaCaseUnmapped`에 먹여 미대응 1을 단언하는 `N63`을 더했다. 규약 `floor-ask-cases:`에 `case-mapped=N63`을 더했다(`case-mapped`가 Part N 꼬리 케이스 전부를 대응에 요구한다).
- **M82-T04** — `tests/discover/README.md`의 머리 `cases:` 선언(608 → 637)과 파트별 수(Part N 62 → 63 · Part O 59 → 87), Part N 서술에 `N63`, Part O에 새 소절(선언 정합 · 갈래 고정 · 변환 통제 · 갈래 수와 이름 잔재 · 묻지 않는 것)과 소계를 더했다.

**고지 대응표**(완료 기준 5 — 규약 「기계가 묻는 것」의 판정 ↔ 케이스)

| 고지의 판정 | 케이스 |
|---|---|
| 두 선언 줄이 키마다 정확히 하나 | `O60` · `O61` |
| 꼬리에 금지 구분자가 없다 | `O63` |
| 이름과 값 쌍의 추출이 비지 않는다 | `O62` |
| 이름이 유일하다 | `O64` (배선 `O79`) |
| 이름마다 정의 항목이 정확히 하나 · 고아 정의 없음 | `O65` · `O66` (배선 `O80`) |
| 정의 항목의 순서 = 선언의 이름 순서 | `O67` (배선 `O81`) |
| 값 선언의 이름 집합 = 갈래 이름 집합 | `O68` (배선 `O82`) |
| 값이 `ok` · `no` 안 | `O69` (배선 `O83`) |
| 갈래 고정 | `O70`~`O74` |
| 이름과 값을 선언에서 읽는다 | `O75` · `O76` · `O77` |
| 갈래 이름의 수 = 러너의 조건 수 | `O84` (통제 `O85`) |
| 규약 파일 안 ro- 백틱 토큰이 전부 선언된 이름 | `O86` (통제 `O87`) |
| 실제 선언의 값 넷 | `O18` · `O36` · `O37` · `O38` (리뷰 라운드 0 실측) |

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | 규약 "회고 후속 항목의 소비" 절에 `retro-order-branches:` · `retro-order-verdict:` 선언 줄이 하나씩(`O60` · `O61`)이고 정의 항목 넷이 있다(`O65` · `O66`). 절 안에서 갈래를 번호로 가리키는 자리 0 — 훑기: 패턴 `[⑴⑵⑶⑷]` · 대상 그 절(제목 `## 회고 후속 항목의 소비`부터 다음 같은 깊이 제목 전까지) · 대조 항목 「순서 판정 갈래를 가리키는 번호」 · 루트 `docs/conventions.md`. 남은 히트는 다른 열거(처분 의무 ⑴⑵ · 도입 번호 파생 ⑴~⑶ · 정직 고지 ⑴~⑶)다. **처음 훑기는 생명주기 갈래 표의 「백스톱」 열(열두 칸)을 놓쳤다** — 기준 1을 대조하며 찾았고 같은 편집에서 이름으로 바꿨다. 라운드 1부터 이름의 잔재는 `O86`이 상시로 문다 |
| 2 | 충족 | 러너 소스에 갈래 이름 문자열 0 — 패턴 `ro-first\|ro-release-commit\|ro-milestone-ahead\|ro-behind` · 대상 `tests/discover/run.sh` · `tests/discover/run.ps1` · 대조 항목 「갈래 이름 리터럴」 · 루트 저장소 → 0줄. 이름은 `dn_names`/`DnNames`로 선언 위치에서 읽고(`O75`), 값은 `ro_pairs`/`RoPairs`로 읽는다(`O76` · `O77`) |
| 3 | 충족 | `O18` · `O36`~`O40`의 기대값 문자열은 HEAD와 같고(이 사이클의 diff가 그 여섯 `chk`/`Chk` 줄을 건드리지 않았다 — `git diff -U0`에서 그 줄의 `+`/`-` 0건) 두 러너 · 네 실행 환경에서 초록이다. 같은 네 버전 값이면 같은 갈래로 떨어진다 — 아래 생명주기 상태표의 사본 열두 개에서 `O18` 결과가 규약이 정의한 갈래와 같다 |
| 4 | 충족 | 되돌림 표 — ⑴ `ro-name-drop` ⑵ `ro-name-dup` · `ro-name-dup-only` ⑶ `ro-def-drop` ⑷ `ro-def-extra` · `ro-def-extra-zz` ⑸ `ro-def-swap` ⑹ `ro-val-flip` ⑺ `ro-val-drop` ⑻ `ro-val-bad` ⑼ `ro-order-sh` · `ro-order-ps1` ⑽ `fa-filter-zero`. 열 교란 전부 두 사본에서 붉다(⑼는 사본마다 따로 깨고 따로 쟀다). 라운드 1이 더한 교란(이름 추가 끝 · 중간 · 이름 잔재)도 붉다 |
| 5 | 충족 | 위 「고지 대응표」 — 규약 「기계가 묻는 것」(M82)의 판정마다 케이스가 하나 이상이다 |
| 6 | 충족 | 아래 생명주기 상태표 — 상태 목록 스물하나 전부와 판정별 격자. 라운드 1에서 ⑼ · ⑾ · ⒂ · ⒃ · ⒄을 태그 뒤 후처리 후까지 따라갔다 |
| 7 | 충족 | 마지막 측정(이 보고서를 쓴 뒤): 아래 테스트 결과. 수는 `tests/discover/README.md`의 `cases:` 선언처를 가리킨다. sh 전수는 `measure-axis:`대로 CI가 판정한다 |
| 8 | 충족 | `git diff --name-only` → `docs/conventions.md` · `docs/epics/E2.md` · `tests/discover/README.md` · `tests/discover/run.ps1` · `tests/discover/run.sh`. `skills/` · `hooks/` 변경 0 |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M82-impl.md` |
| 수정 | `docs/conventions.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` · `docs/epics/E2.md` |
| 삭제 | (없음) |

`docs/milestones/M82.md`와 `docs/epics/E2.md`(등재 한 줄)는 직전 `/tide:milestone`의 미커밋 산출물이다. `docs/reports/M82-review.md`는 리뷰 라운드 0의 미커밋 산출물이다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (pwsh 7.6.9 · Windows PowerShell 5.1.26100 — 전수 / Git Bash `sh` — Part N · O 부분) | pwsh **637/0** · 5.1 **637/0** · sh N 63/0 · sh O 87/0 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — 규약 `measure-axis:`의 배당) | 릴리즈 단계에서 확인 |

- **마지막 측정**(이 보고서를 쓴 뒤의 트리) — `pwsh` · `powershell` `tests/discover/run.ps1` → `# result: PASS=637 FAIL=0` · 나머지 하니스 여섯(`multi-repo` 37 · `fleet` 45 · `fleet-cycle` 24 · `fleet-verify` 30 · `site-includes` 51 · `mutation` 12)은 pwsh 7과 5.1에서 FAIL 0 · Git Bash `sh tests/discover/run.sh N` → 63/0 · `sh … O` → 87/0. 메모리 부족을 피해 측정은 명령마다 하나씩 포그라운드로 돌렸다.
- **라운드 1 기준선** — 라운드 1 코드를 넣고 이 보고서를 고치기 전의 트리에서 pwsh · 5.1 전수 637/0(라운드 0 보고서가 있어 `U6`은 초록이다) · Git Bash `sh` Part O 87/0 · Part N 63/0.
- **캐시가 아닌 실행임을 확인한 방법**(`measure-not-cached`) — 하니스는 빌드 캐시가 없는 해석형 스크립트다. 라운드 1에서 케이스 수가 633 → 637로 바뀐 것이 결과 줄에 그대로 보였고, 라운드 1 작업 중 `O86`이 새 규약 문장의 백틱 `ro-`(접두어만 쓴 토큰)를 실제로 붉혔다(문장을 백틱 없이 고쳐 닫았다).
- **구현 중 발견한 것** — ⑴ 라운드 0: `cases:` 선언을 처음 634로 적었다가(새 케이스 25로 셈) `F1` · `F1b`가 붉어 633으로 고쳤다. ⑵ 라운드 1: README의 새 문장에 옛 「갈래는 넷이다」를 인용하자 Part L `L7`이 그 수 낱말을 선언으로 읽어 붉었다(`README.md:1318:넷이다:4/1`) — 수 낱말 없이 고쳤다. ⑶ 라운드 1: 규약 고지에 백틱 `ro-`를 쓰자 `O86`이 붉었다 — 백틱 없이 고쳤다. ⑷ 되돌림 드라이버에 `-Only` 배열을 `pwsh -File`로 넘기자 배열로 받지 않아 아무 행도 돌지 않았다(알려진 함정) — 같은 세션 안에서 `&`로 불러 다시 쟀다.

**생명주기 상태표**(`lifecycle-state-table`) — 판정 조건은 바뀌지 않았지만 판정이 읽는 입력(규약 선언 둘)이 늘었으므로 단다. 라운드 1 트리에서 다시 쟀다.

- **판정이 읽는 입력**: 최상단 회고 섹션 제목의 기준 버전 · CHANGELOG 첫째 · 둘째 머리 · 최대 번호 마일스톤의 기반 버전 · 규약의 두 선언.
- **그 입력을 바꾸는 전이**(판정별 격자 ②): `tr-draft`(최대 번호 · 기반 버전) · `tr-release-commit` · `tr-forced` · `tr-debug-release` · `tr-pr-create` · `tr-continuous-stop`(CHANGELOG 첫째) · `tr-retro`(회고 기준 버전) · `tr-downstream`(규약 선언의 유무). `tr-impl` · `tr-review` · `tr-tag` · `tr-pr-finalize` · `tr-retro-skip` · `tr-debug-open` · `tr-debug-done` · `tr-part-select`는 이 판정에 항등이다(그 입력을 바꾸지 않는다).
- **사본 열두 개**(A~K) — 작업 트리를 `.git` 없이 스크래치패드로 복사하고(`st82.ps1`), CHANGELOG 표지 줄 다음에 머리를 넣거나(올림) · 회고 제목의 버전을 바꾸거나 · `docs/milestones/M83.md`(기반 버전 줄만 든 초안)를 더해 상태를 만든 뒤 세 실행 환경에서 Part O를 돌렸다. 버전 넷이 같은 상태는 같은 사본을 쓴다.

| 상태 | 사본(만든 방법) | 기대 | 실제(pwsh · 5.1 · sh Part O) |
|---|---|---|---|
| ⑴ 사이클 중 (`tr-draft` `tr-impl`) | A — 현재 트리 그대로(회고 = CHANGELOG 첫째 v2.45.2 · 기반 v2.45.2) | `ro-first` 초록 | 87/0 · 87/0 · 87/0 |
| ⑵ 리뷰 뒤 (+`tr-review`) | A — 리뷰 보고서는 Part O 입력이 아니다 | `ro-first` 초록 | A와 같음 |
| ⑶ 릴리즈 커밋 (+`tr-release-commit` · 같은 트리를 `tr-continuous-stop` · `tr-pr-create`) | B — CHANGELOG에 v2.46.0 머리 | `ro-release-commit` 초록 | 87/0 · 87/0 · 87/0 |
| ⑷ 태그 뒤 후처리 전 (+`tr-tag`/`tr-pr-finalize`) | B — 태그는 트리를 바꾸지 않는다 | `ro-release-commit` 초록 | B와 같음 |
| ⑸ 태그 뒤 후처리 후 (+`tr-retro`) | C — B + 회고 v2.46.0 | `ro-first` 초록 | 87/0 · 87/0 · 87/0 |
| ⑹ ⑵에서 다음 초안 (+`tr-draft`) | D — M83 초안(기반 v2.45.2) | `ro-first` 초록 | 87/0 · 87/0 · 87/0 |
| ⑺ ⑶에서 다음 초안 (+`tr-draft`) | E — B + M83 초안(기반 v2.46.0) | `ro-milestone-ahead` 붉음(순서 규칙 — 의도) | 86/1(`O18`) · 86/1 · 86/1 |
| ⑻ ⑷에서 회고 건너뛰고 초안 (+`tr-retro-skip` `tr-draft`) | E — 같은 트리 | `ro-milestone-ahead` 붉음(의도) | E와 같음 |
| ⑼ debug 릴리즈 커밋 (⑸ + debug 셋) | F — C + v2.46.1 머리 | `ro-release-commit` 초록 | 87/0 · 87/0 · 87/0 |
| ⑼ → 태그 뒤 후처리 후 (+`tr-tag` `tr-retro`) | J — F + 회고 v2.46.1 | `ro-first` 초록 | 87/0 · 87/0 · 87/0 |
| ⑽ 후처리 건너뛴 뒤 debug 릴리즈 커밋 | G — B + v2.46.1 머리(회고 v2.45.2) | `ro-behind` 붉음(의도 — 수동 `/tide:retro`가 복구) | 86/1(`O18`) · 86/1 · 86/1 |
| ⑾ 강행 릴리즈 커밋 (⑴ + `tr-forced`) | B — 트리가 릴리즈 커밋과 같다 | `ro-release-commit` 초록 | B와 같음 |
| ⑾ → 태그 뒤 후처리 후 | C — 강행 커밋의 트리가 릴리즈 커밋과 같으므로 그 뒤 회고 트리도 같다 | `ro-first` 초록 | C와 같음 |
| ⑿ 파트 선택 실행 (`tr-part-select`) | 사본 열두 개 전부가 `-Part O` · `run.sh O`로 돌았다 | 전수와 같은 답 | 실제 트리에서 부분 87/0 · 전수의 Part O도 0 붉음 |
| ⒀ ⑴·⑵에서 debug 릴리즈 태그 뒤 후처리 후 | H — v2.45.3 머리 + 회고 v2.45.3 | `ro-first` 초록 | 87/0 · 87/0 · 87/0 |
| ⒁ ⑹에서 debug 릴리즈 태그 뒤 후처리 후 | I — D + v2.45.3 머리 + 회고 v2.45.3 | `ro-first` 초록 | 87/0 · 87/0 · 87/0 |
| ⒂ ⑹에서 직전만 강행 릴리즈 | B2 — M83 초안(기반 v2.45.2) + v2.46.0 머리 | `ro-release-commit` 초록 | 87/0 · 87/0 · 87/0 |
| ⒂ · ⒃ · ⒄ → 태그 뒤 후처리 후 | K — B2 + 회고 v2.46.0 | `ro-first` 초록 | 87/0 · 87/0 · 87/0 |
| ⒃ ⑹에서 다음 사이클까지 마치고 함께 릴리즈 | B2 — impl · 리뷰 보고서는 이 판정의 입력이 아니다 | `ro-release-commit` 초록 | B2와 같음 |
| ⒄ 다음이 impl만 마친 채 직전 강행 릴리즈 | B2 — 같은 까닭 | `ro-release-commit` 초록 | B2와 같음 |
| ⒅ 대상 레포에서 처음 도는 릴리즈 (`tr-downstream`) | 해당 없음 — 이 판정은 하니스(`tests/discover`)에만 있고 하니스는 이 저장소에서만 돈다. 대상 레포의 스킬은 순서 advisory만 내고(`skills/milestone/SKILL.md`) 두 선언을 읽지 않는다. 그래서 이 저장소의 선언 값이 대상 레포로 새지 않는다 | — | — |
| ⒆ debug 세션이 열린 채 (⑴·⑵ + `tr-debug-open`) | A — 세션 파일 · 판정 없는 debug 보고서는 Part O 입력이 아니다 | `ro-first` 초록 | A와 같음 |
| ⒇ 판정 `불가`인 채 재작업 전 | A — 리뷰 판정은 입력이 아니다(이 라운드의 실제 트리가 이 상태다) | `ro-first` 초록 | A와 같음 |
| `st-fail-then-draft` | D — 같은 까닭 | `ro-first` 초록 | D와 같음 |

판정별 격자 ③(남은 전이 × 마일스톤 단계 부류 일곱)이 낸 목록 밖 상태는 없다 — 남은 전이가 바꾸는 값은 버전 넷뿐이고, 버전 넷의 조합은 갈래 넷으로 모인다. 위 사본은 갈래 넷을 모두 밟는다(`ro-first` A · C · D · H · I · J · K · `ro-release-commit` B · B2 · F · `ro-milestone-ahead` E · `ro-behind` G).

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: O64 O65 O66 O67 O68 O69 O84 O86 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| ro-name-drop | `retro-order-branches:`에서 `ro-behind`를 지움 | adversarial | O66 · O68 · O73 · O74 · O84 · O86 | ps1 전수 631/6 · sh O 81/6 |
| ro-name-dup | 갈래 선언 끝에 `ro-first`를 한 번 더 붙임 | adversarial | O64 · O84 | ps1 전수 635/2 · sh O 85/2 |
| ro-name-dup-only | 갈래 선언의 `ro-behind`를 `ro-milestone-ahead`로(수 넷 유지) · `ro-behind`의 값 · 정의 머리 · 백틱 토큰을 지움 | adversarial | O64 | ps1 전수 636/1 · sh O 86/1 |
| ro-def-drop | `ro-behind` 정의 항목의 머리를 백틱 없는 굵은 글로 바꿈 | adversarial | O65 | ps1 전수 636/1 · sh O 86/1 |
| ro-def-extra | 선언에 없는 정의 항목 `ro-extra`를 같은 깊이에 더함 | adversarial | O66 · O86 | ps1 전수 635/2 · sh O 85/2 |
| ro-def-extra-zz | 선언에 없는 정의 항목 `zz-extra`를 같은 깊이에 더함 | adversarial | O66 | ps1 전수 636/1 · sh O 86/1 |
| ro-def-swap | 정의 항목 첫 둘의 이름을 맞바꿈 | adversarial | O67 | ps1 전수 636/1 · sh O 86/1 |
| ro-val-flip | `ro-first=ok`를 `ro-first=no`로 | adversarial | O18 | ps1 전수 636/1 · sh O 86/1 |
| ro-val-drop | 값 선언에서 `ro-behind=no`를 지움 | adversarial | O68 | ps1 전수 636/1 · sh O 86/1 |
| ro-val-bad | `ro-behind=no`를 `ro-behind=maybe`로 | adversarial | O69 | ps1 전수 636/1 · sh O 86/1 |
| ro-order-sh | `run.sh`의 갈래 조건 둘째 · 셋째의 위치 번호를 맞바꿈 | broken | O36 · O37 · O71 · O72 | sh O 83/4(ps1은 깨지 않음) |
| ro-order-ps1 | `run.ps1`의 갈래 조건 둘째 · 셋째의 위치 번호를 맞바꿈 | broken | O36 · O37 · O71 · O72 | ps1 전수 633/4(sh는 깨지 않음) |
| fa-filter-zero | 두 러너의 `N58` 경계 필터를 함께 「접미 ID → 0」으로 | broken | N63 | ps1 전수 636/1 · sh N 62/1 |
| ro-decl-indent | 갈래 선언 줄을 두 칸 더 들여씀(정의 항목은 그대로) | adversarial | O65 | ps1 전수 636/1 · sh O 86/1 |
| ro-name-add-end | 선언 끝에 `ro-extra` · 값 `ro-extra=no` · 정의 항목을 함께 더함(리뷰 라운드 0 반증 ⒜) | adversarial | O84 | ps1 전수 636/1 · sh O 86/1 |
| ro-name-add-mid | `ro-extra`를 `ro-behind` 앞에 끼우고 값 · 정의도 같은 자리에 둠(리뷰 라운드 0 반증 ⒝) | adversarial | O84 | ps1 전수 636/1 · sh O 86/1 |
| ro-rename-leftover | 선언 · 값 · 정의 머리의 `ro-behind`만 `ro-lag`로 바꾸고 산문 · 표의 옛 이름을 남김(리뷰 라운드 0 권장 2) | adversarial | O86 | ps1 전수 636/1 · sh O 86/1 |

<!-- reversal-table:end -->

- **기준선** — 라운드 1 코드를 넣은 트리(이 보고서 갱신 전)에서 ps1 전수 **637/0** · sh O 87/0 · sh N 63/0. 라운드 0 보고서가 트리에 있어 `U6`은 초록이고, 표의 ps1 결과는 그 기준선에서의 값이다.
  - 드라이버는 스크래치패드의 `rev82.ps1`이다. 백업 키는 저장소 경로(`docs__conventions.md` · `tests__discover__run.sh` · `tests__discover__run.ps1`)이고, **라운드를 넘기며 백업 `bak82`를 지우고 라운드 1 기준선에서 새로 떴다**(옛 백업이 남으면 행마다 하는 복원이 라운드 1 수정을 덮는다 — M79 교훈).
  - 행마다 편집의 앵커 수를 단언했다(한 번 바꾸는 편집은 정확히 1 · 전부 바꾸는 편집은 1 이상 — 어긋나면 `ANCHOR-MISS`, 0건). 매 행 앞과 끝에서 세 파일을 백업으로 되돌리고 해시로 대조했다(`RESTORE-MISMATCH` 0건 · 끝에 `RESTORED-OK`). 결과 줄 수가 요청 행 수(15 + 2)와 같다. sh는 `C:\Program Files\Git\bin\bash.exe`로 불렀다.
- **본 검사 단독 행** — 목록 줄의 여덟은 각각 자기 하나만 붉는 행이 있다 — `O64` `ro-name-dup-only` · `O65` `ro-def-drop` · `O66` `ro-def-extra-zz` · `O67` `ro-def-swap` · `O68` `ro-val-drop` · `O69` `ro-val-bad` · `O84` `ro-name-add-end` · `O86` `ro-rename-leftover`.
  라운드 1에서 `O84`가 이름 수를 세므로 이름 복제(`ro-name-dup`)와 `ro-` 정의 추가(`ro-def-extra`)는 둘 이상이 붉게 됐다 — 수를 넷으로 지키는 복제(`ro-name-dup-only`)와 `ro-`로 시작하지 않는 정의(`ro-def-extra-zz`)를 더해 단독 행을 다시 세웠다.
  갈래 고정(`O70`~`O74`)과 변환 통제(`O75`~`O83` · `O85` · `O87`) · `N63`은 통제라 목록에 넣지 않았다.
- **방향** — 판정 쪽(`broken`): 러너 조건 순서 · 경계 필터. 입력 쪽(`adversarial`): 이름 · 정의 · 값의 지움 · 복제 · 더함 · 맞바꿈 · 집합 밖 값 · 이름 잔재 · 선언 줄 들여쓰기(입력 꼴 — `rf-01`). 빈 회고 버전 · 빈 첫째 · 둘째는 갈래 고정 `O74`가 상시로 문다.

## 미해결·후속 메모

1. **이 축의 고지가 산문이다** — 규약 「기계가 묻는 것」(M82)은 판정 이름과 케이스의 대응을 선언(`floor-asks:` 형태)으로 들지 않는다. 이 보고서의 고지 대응표가 손이다. 다른 축으로 고지 대응을 넓히는 일은 `rf-86`의 나머지(고지 절)와 같은 자리이고, 케이스가 한 파트에 몰린 이 축은 `floor-ask-from:` 형태를 그대로 쓸 수 있다.
2. **이름과 정의를 함께 같은 순서로 바꾼 편집** — 이름이 다른 조건에 붙는다. 실제 트리에서는 그 이름의 값이 따라오므로 정상 상태의 `O18`이 붉는 경우가 많지만 보장하지 않는다(규약 「묻지 않는 것」). 값까지 함께 맞바꾸면 초록이다.
3. **러너 조건 · 조건 수 · 선언을 모두 함께 늘린 편집** — `O84`는 수의 일치만 묻는다. 새 조건이 옳은 이름에 붙는가는 규약 「묻지 않는 것」으로 남는다.
4. **`ro-` 잔재 판정의 범위는 규약 파일 하나다** — 하니스 README · 보고서에 남은 옛 이름은 보지 않는다(규약 「묻지 않는 것」). 갈래 이름을 ro-로 시작하지 않게 바꾸면 이 판정이 볼 토큰이 없어진다 — 이름 꼴은 선언이 정하므로 열린 경계다.
5. **`rf-86`의 나머지** — release 게이트 ①②③ · 도입 번호 파생 ⑴~⑶ · 문서 커밋 전제 셋 · 고지 절 일곱 · Part W `sp_*`의 `dn_*` 흡수는 그대로 산문이다. 이 사이클은 순서 판정 갈래 하나만 집었다.
6. **판정 함수의 넓어진 입력** — 판정이 규약의 선언을 읽으므로, 선언 줄이 지워진 규약에서는 `O18`도 붉는다(`O60` · `O62`와 함께). 대상 레포에는 이 판정이 돌지 않는다(하니스는 이 저장소에서만 돈다 — 상태표 ⒅).
7. **리뷰 라운드 0의 사소 7 · 8** — README의 케이스 수 중복(기존 관행)과 sh `ro_value`의 백슬래시 해석(이름이 ASCII 영숫자 · 하이픈뿐)은 리뷰가 경계로 기록했고 이 라운드에서 고치지 않았다.
