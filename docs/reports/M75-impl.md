# M75 완료보고서 (impl)

## 개요

M75의 태스크 넷을 구현했다. 시작점 블록 · 형태 판정의 술어 목록(M73의 ①~⑨)을 규약의 선언 두 줄(`start-point-block-predicates:` ·
`start-point-form-predicates:`)과 이름별 정의 항목으로 옮겼고, 두 러너는 그 이름을 **읽어** 판정을 `이름=값` 꼴로 낸다. 선언된 이름 수와 판정이
내는 값 수가 어긋나면 `W156` · `W157`이 붉다. 문서 커밋 거부 접두사(M74의 `S12`)도 러너 소스에서 규약 조각의 `docs-commit-deny:` 한 줄로 올렸고,
비교는 ASCII 대소문자를 무시한다(`rf-75`). 무엇이 붉은가는 바뀌지 않았다(대소문자만 다른 거부 대상은 이제 붉다). `skills/` 변경은 0이다.

재작업 라운드(rework): 1

## 라운드 1 — 리뷰 라운드 0 반환 처리

- **차단 1(정의 항목이 선언보다 넓어도 초록)** — 역방향과 유일성을 세웠다. `W160`: 정의 항목마다 선언된 이름이 있다(고아 정의 0). `W161`: 두 선언을 통틀어
  이름이 유일하다. 리뷰 반증이 잰 세 편집(`orphan-def` · `dup-name` · `name-in-both`)이 이제 두 사본에서 붉다. 규약 서두 문장(「닫힌 것을 손으로 다시 적을
  자리가 없다」)을 「이름의 수와 집합을 세 쪽(선언 · 판정 값 · 정의 항목)에서 기계가 대조하고, 정의 문장의 뜻은 손으로 적고 리뷰가 본다」로 좁혔고, 경계 항목 ⑶을
  양방향 · 유일성으로 고쳤다. 후속 1도 같은 범위로 고쳤다.
- **권장 2(대소문자 접기가 「`docs/` 밖」까지)** — `S12`는 이제 원래 철자로 「`docs/` 밖」을 보고(ordinal), 소문자로 바꾼 값은 거부 접두사 비교에만 쓴다.
  `docs-upper-outside`(`Docs/epics/*`)가 두 사본에서 붉다. 규약 조각에 접기의 범위를 적었다.
- **사소 3(`W158`이 아무 줄이나 셈)** — 정의 항목을 「블록 술어 선언 줄부터 다음 제목까지, 걷은 문면이 `- **`이름`**`로 시작하는 줄」로 정의하고(`sp_defs`/`SpDefs`)
  `W158` · `W160`이 그 목록만 본다. `def-moved`가 `W158`로 붉다.
- **디스패치** — 이번 라운드는 메인이 순차로 했다. 처방 셋이 같은 판정(정의 항목의 정의)과 그것을 서술하는 규약 · README 문장을 함께 고치는 일이라 나눌 단위가 없었다.
- **되돌림 · 상태표를 라운드 1 트리로 다시 쟀다** — 아래 표와 상태표.

**병렬 디스패치** — T01(설계)은 메인이 했다. T02(규약 두 파일)와 T03(두 러너)은 예상 변경 파일이 겹치지 않아 동시에 돌렸다 — T02는 서브에이전트,
T03은 메인. T04(README · 되돌림 · 상태표)는 둘이 끝난 뒤 메인이 했다.

## 태스크별 수행 내용

- **M75-T01**(읽기 전용 설계)
  - **⑴ 술어 이름** — 블록 판정 일곱 값에 `sp-ptr-count` · `sp-parent` · `sp-pointer` · `sp-branches` · `sp-after-item` · `sp-before-item` · `sp-shape-count`,
    형태 판정 세 값에 `sp-form-count` · `sp-form-same` · `sp-form-cont`. 형태 판정은 값 셋을 내는데 규약은 술어 둘(⑧ · ⑨)로 적었으므로, **값과 이름을
    일대일로** 맞췄다(⑧을 수 · 같음 둘로 갈랐다). `sp-form-cont`는 「이어진 줄이 있는가」라 정상 값이 `no`다.
  - **⑵ 선언 형태** — 블록과 형태를 두 줄로 갈랐다(키별로 「이름 수 = 값 수」를 따로 대조하려고). 정의 항목은 블록 술어 선언 줄부터 다음 제목까지에서 걷은 문면이
    `- **`이름`**`로 시작하는 줄이다(라운드 0은 「`**`이름`**`을 담은 줄」이었고 리뷰 사소 3이 좁혔다). 거부 접두사는 `docs/conventions-release.md`의 `docs-commit-deny:` 한 줄.
  - **⑶ 출력 형태** — `이름=값`. 판정(`_cyc_block`/`CycBlock` · `form_probe`/`FormProbe`)과 기대값 양쪽에 같은 헬퍼(`sp_name`/`SpName`)로 이름을 붙인다.
    이름은 선언에서 읽고 러너 소스에 리터럴이 없다. 위치 값(`_cyc_block_raw`/`CycBlockRaw`)은 그대로 두어 `W156` · `W157`이 값의 수를 센다.
  - **⑷ 대소문자** — `sh`는 `LC_ALL=C`의 `tolower`(ASCII만), `pwsh`는 A–Z만 손으로 접는다(`AsciiLower` — .NET의 `ToLower` · `OrdinalIgnoreCase`는 비-ASCII
    글자까지 접어 두 사본이 갈린다).
  - **⑸ 규약 산문** — 「닫힌 경계와 열린 경계」의 ①~⑨ 열거와 `start-point-block`의 (a)~(f)를 지우고 선언을 가리키게 했다. 숫자로 술어를 가리키던 자리(⑤ · ⑥ · ⑦ ·
    (f) · ⑨)는 이름으로 바꿨다. 열린 경계와 그 예는 그대로다.
  - **⑹ 생명주기** — 판정 조건이 바뀌므로 상태표를 남긴다(아래).
  - **⑺ 회귀 방향과 되돌림 행의 대응**:

    | 방향 | 되돌림 행 |
    |---|---|
    | 술어 선언의 중복 · 금지 구분자 · 소실 | `spb-dup` · `spf-dup` · `spb-trailing-tab` · `spb-gone` |
    | 이름 하나 삭제 · 추가(값 수와 어긋남) | `spb-drop-name` · `spf-drop-name` · `spb-add-name` |
    | 정의 항목 복제 · 삭제 | `def-dup` · `def-gone` |
    | (라운드 1) 정의 → 선언 역방향 · 이름 중복 · 정의 머리 밖의 굵은 이름 · 「`docs/` 밖」 대소문자 | `orphan-def` · `dup-name` · `name-in-both` · `dup-name-clean` · `def-moved` · `docs-upper-outside` · `spb-drop-clean` · `spf-drop-clean` |
    | 러너가 이름을 박아 둠(배선) | `judge-name-pinned` |
    | 거부 선언의 중복 · 금지 구분자 · 빈 값 | `deny-dup` · `deny-trailing-tab` · `deny-emptied` |
    | 대소문자만 다른 거부 대상 · debug 보고서 · 판정 보고서를 덮는 글롭 | `case-upper-value` · `deny-debug` · `deny-glob-reports` |
    | M73 블록 · 형태 판정이 새 출력 형태에서도 붉는가 | `tail-paren` · `lazy-continuation` |
    | **오탐 방향 · 열린 경계**(초록이어야 한다) | `ok-def-prose` · `spb-reorder`(표 밖) |
- **M75-T02**(서브에이전트) — `docs/conventions.md`: 선언 두 줄 · 이름별 정의 항목 열 · 「기계가 묻는 것과 리뷰의 자리」 경계 항목 · ①~⑨ 열거와 (a)~(f)를
  선언 포인터로. `docs/conventions-release.md`: `docs-commit-deny:` 선언과 거부 접두사 · 거부의 까닭 항목. `docs/project-context.md` · `CLAUDE.md`는 술어나
  거부 목록을 재서술하지 않아 손대지 않았다.
- **M75-T03**(메인) — 두 러너. 헬퍼(`sp_names` · `sp_count` · `sp_name` · `sp_defs` · `sp_def_bad` · `sp_def_orphan` · `sp_name_dup` · `sp_wire_fixture` / `SpNames` ·
  `SpCount` · `SpName` · `SpDefs` · `SpDefBad` · `SpDefOrphan` · `SpNameDup` · `SpWireFixture` — 뒤의 셋은 라운드 1)는 **파트 가드 밖**에 두었다(`rf-60`). 기존 판정 열여섯(`W118`~`W120` · `W132`~`W137` · `W141`~`W146` · `W151`)의 판정과 기대값을 이름 붙인
  형태로 바꿨다. 새 케이스 `W152`~`W159` · `S20`~`S22`. `S12`는 러너의 목록 대신 선언을 읽는다.
  - **구현 중 발견한 결함 — 이름이 비면 본 검사가 공허하게 초록이다.** `pwsh` 사본의 `SpNames`가 매개변수를 `$conv`로 받아 **전역 `$CONV`를 가렸다**
    (PowerShell 변수는 대소문자를 가리지 않는다). 이름이 빈 채 판정과 기대값이 둘 다 `?=값`이 되어 `W137` 등은 초록이었고, `W154` · `W156` · `W157` · `W159`만
    붉었다. 매개변수를 `$spConv`로 바꿔 닫았고, 그 사실을 README에 적었다 — 새 케이스가 바로 그 공허를 잡도록 세운 것이 첫 실행에서 맞았다.
- **M75-T04**(메인) — README Part W M73 블록에 M75 항목(무는 것 · 공허 경로 · 묻지 않는 것)과 합 줄(Part W 154), Part S의 `S12` 설명(선언 · 대소문자)과
  합 줄(Part S 22), 두 파트 머리의 케이스 수, `cases:` 한 줄(552 → 563, 라운드 1에서 565)을 고쳤다.

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | `docs/conventions.md` 108 · 110행에 선언 두 줄, 116~126행에 정의 항목 열이 있다(`W152` · `W153` · `W158` · `W160`). **범위 선언**: 패턴 `①`~`⑨`(U+2460~U+2468) · `(a)`~`(f)`, 대상 파일 `docs/conventions.md`의 "상태 확인 항목과 시작점 판단 (선언)" 절(47~172행), 대조 항목은 술어를 가리키는 번호 열거의 존재, 루트 저장소 루트. 결과: 0건(T02 서브에이전트의 PowerShell 스캔과 메인의 재확인). 절에 남은 번호는 경계 항목의 ⑴~⑷뿐이다 |
| 2 | 충족 | 두 러너의 블록 · 형태 판정이 `sp_name`/`SpName`으로 이름을 붙인다(`W137` 등의 기대값도 같은 헬퍼). **범위 선언**: 패턴 `sp-ptr-count` · `sp-parent` · `sp-pointer` · `sp-branches` · `sp-after-item` · `sp-before-item` · `sp-shape-count` · `sp-form-count` · `sp-form-same` · `sp-form-cont`, 대상 파일 `tests/discover/run.sh` · `tests/discover/run.ps1`, 대조 항목은 리터럴 존재 건수, 루트 저장소 루트. 결과: **0건**. 배선은 `W159`가 문다(`judge-name-pinned` 행이 단독으로 붉힌다) |
| 3 | 충족 | 이름 삭제 · 추가 · 중복 · 정의 항목 복제 · 삭제 · 고아 정의가 두 사본에서 붉다 — `spb-drop-clean`(`W156`) · `spf-drop-clean`(`W157`) · `spb-add-name`(`W156` · `W158`) · `def-dup` · `def-gone` · `def-moved`(`W158`) · `orphan-def`(`W160`) · `dup-name-clean`(`W161`). 라운드 0은 정의 → 선언 방향을 묻지 않아 정의 항목을 더하는 편집이 초록이었다(리뷰 차단 1) — 라운드 1이 `W160` · `W161`로 닫았다. 값은 아래 되돌림 표 |
| 4 | 충족 | `docs/conventions-release.md` 268행에 `docs-commit-deny:`가 있고 `S12`가 그것을 읽는다(`S20`~`S22`). **범위 선언**: 패턴 `docs/reports/M` · `docs/reports/debug-` · `docs/milestones` · `docs/commands.md` · `'docs/conventions'`, 대상 파일 두 러너, 대조 항목은 **거부 목록으로 쓰이는** 리터럴(판정이 비교에 쓰는 목록 상수), 루트 저장소 루트. 결과: 그런 목록 상수 0건 — 패턴 자체는 경로를 만드는 줄(`run.ps1` 4038 · 4698행 등)과 주석에 걸리고, 그것은 거부 목록이 아니다. M74의 S8–S19 머리 주석(`run.ps1`)이 접두사를 손으로 다시 적고 있던 것은 리뷰 라운드 1이 선언 포인터로 바꿨다. `case-upper-value`(`docs/Reports/M74-review.md`)가 두 사본에서 `S12`로 붉다 |
| 5 | 충족 | T01 ⑺의 방향마다 행이 있고(위 대응 표) 표의 행 모두 두 사본에서 지목한 케이스가 붉다. M73 블록 · 형태(`tail-paren` · `lazy-continuation`)와 M74 `S12`(`deny-debug` · `deny-glob-reports`) 행이 새 형태에서 같은 케이스로 붉다. 오탐 방향 `ok-def-prose`는 두 사본 156/0(라운드 1 트리) |
| 6 | 충족 | 규약 「기계가 묻는 것과 리뷰의 자리」 항목과 README Part W M75 항목이 「묻는 것은 유일성 · 추출 · 금지 구분자 · 이름 수 = 값 수 · 정의 항목과 선언의 양방향 · 이름 유일성 · 배선까지, 정의 문장의 뜻과 이름 순서는 묻지 않는다」를 적는다(라운드 1에서 양방향 · 유일성을 더하고 규약 서두 문장을 같은 범위로 좁혔다). 순서 경계는 `spb-reorder`(두 사본 156/0)로 실측했다 |
| 7 | 충족 | F1 · F5는 `tests/discover` Part F가 문다 — 결과는 아래 「테스트 결과」 표. `run.ps1` 비-ASCII 바이트 **0** |
| 8 | 충족 | `git status --porcelain -- skills/`가 빈 출력이다 |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M75-impl.md` |
| 수정 | `docs/conventions.md` · `docs/conventions-release.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` |
| 삭제 | (없음) |

기준선은 이 단계 시작 시점의 워킹트리다. `docs/milestones/M75.md`와 `docs/epics/E2.md`의 등재 한 줄은 milestone 단계의 미커밋 산출물이고,
`docs/reports/retro.md`는 v2.40.0 태그 뒤의 자동 회고 산출물이다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (`pwsh` 7.6.6 Core · Windows PowerShell 5.1 · Git Bash `sh` · `dash`) | 아래 「마지막 측정」 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 전수 — `dash` · `bash`) | 릴리즈 단계에서 확인 |

**마지막 측정**(이 보고서를 쓴 뒤의 실행 — `measure-after-artifacts`): `pwsh -NoProfile -File tests/discover/run.ps1` · `powershell -NoProfile -File tests/discover/run.ps1` 565/0 · `sh` · `dash` `tests/discover/run.sh W` 156/0 · `run.sh S` 22/0 · `site-includes` · `fleet` · `fleet-cycle` · `fleet-verify` · `multi-repo` · `mutation`의 `run.ps1`(`pwsh` 7) FAIL 0

**캐시·스킵이 아님을 확인한 방법**(`measure-not-cached`): 하니스는 빌드 캐시가 없는 셸 스크립트이고 실행마다 출력을 새로 낸다. 케이스 수가 552 → 563(라운드 0) → 565(라운드 1)으로
바뀌어 옛 트리의 값과 가려지고, 같은 트리에서 되돌림 행이 실파일 편집에 맞춰 붉었다가 복원 뒤 초록으로 돌아오는 것을 행마다 보았다.

**생명주기 상태표**(`lifecycle-state-table`) — 바뀐 판정(`W118`~`W120` · `W132`~`W137` · `W141`~`W146` · `W151`의 출력 형태, 새 `W152`~`W159`, `S12`의 거부 출처 ·
대소문자, 새 `S20`~`S22`)이 읽는 입력은 `docs/conventions.md` · `docs/conventions-release.md` · `skills/cycle/SKILL.md` · `skills/release/SKILL.md`다.
상태는 작업 트리 밖(세션 스크래치패드의 `life75r1/{상태}` — 라운드 1 트리로 다시 잼)에 `docs` · `skills` · `tests` · `hooks` · `.claude-plugin` · `.github` · `CHANGELOG.md` · `CLAUDE.md` ·
`README.md`를 복사해 만들었다. 결과는 상태마다 `sh`(Git Bash) · `pwsh` 7 두 경로의 Part W · Part S다.

| 상태 | 사본에서 만든 방법 | 기대 | 실제 |
|---|---|---|---|
| ⑴ 사이클 중 | 사본 기준선 | 초록 | W: `sh` 156/0 · `pwsh` 156/0 · S: `sh` 22/0 · `pwsh` 22/0 |
| ⑵ 리뷰 뒤 릴리즈 전 | ⑴ + 판정 `가능`인 `docs/reports/M75-review.md` | 초록 | W 156/0 · S 22/0(두 경로) |
| ⑶ 릴리즈 커밋 | ⑵ + `.claude-plugin/plugin.json`을 2.41.0으로 | 초록 | W 156/0 · S 22/0(두 경로) |
| ⑷ 태그 뒤 후처리 전 | 해당 없음 — 트리가 ⑶과 같다(하니스는 git을 읽지 않는다) | — | — |
| ⑸ 태그 뒤 후처리 후 | 해당 없음 — `tr-retro`가 바꾸는 회고 문서를 이 판정들은 읽지 않는다(`S13`은 그 파일의 실재만 본다) | — | — |
| ⑹ ⑵에서 다음 마일스톤 초안 | ⑵ + `docs/milestones/M76.md` | 초록 | W 156/0 · S 22/0(두 경로) |
| ⑺ ⑶에서 다음 마일스톤 초안 | 해당 없음 — ⑶ · ⑹이 초록이고 둘이 바꾸는 입력이 모두 이 판정 밖이다 | — | — |
| ⑻ ⑷에서 다음 마일스톤 초안 | 해당 없음 — 같은 사유 | — | — |
| ⑼ debug 릴리즈 커밋 | 해당 없음 — `tr-debug-*`가 바꾸는 것은 debug 보고서와 `.tide/debug-session`이다(⒆에서 확인) | — | — |
| ⑽ 후처리 건너뛴 뒤 debug 릴리즈 커밋 | 해당 없음 — 같은 사유 | — | — |
| ⑾ 강행 릴리즈 커밋 | 해당 없음 — ⑶과 트리 형태가 같다 | — | — |
| ⑿ 파트 선택 실행 | 이 사이클의 되돌림 · 상태 측정이 전부 `run.sh W`/`S` · `run.ps1 -Part W`/`S`였다 | 전수와 같은 판정 | 두 사본 W 156/0 · S 22/0 — 전수의 몫과 일치 |
| ⒀ ⑴·⑵에서 debug 릴리즈 뒤 후처리 후 | 해당 없음 — ⑼ · ⑸와 같은 사유 | — | — |
| ⒁ ⑹에서 debug 릴리즈 뒤 후처리 후 | 해당 없음 — 같은 사유 | — | — |
| ⒂ ⑹에서 직전만 릴리즈(강행) | 해당 없음 — ⑹ · ⑾의 입력이 모두 판정 밖이다 | — | — |
| ⒃ ⑹에서 둘을 한 태그로 | 해당 없음 — 같은 사유 | — | — |
| ⒄ 다음이 impl만 마친 채 강행 | 해당 없음 — 같은 사유 | — | — |
| ⒅ 대상 레포에서 처음 도는 릴리즈 | 사본 규약에서 술어 선언 두 줄과 `docs-commit-deny:` 줄을 지웠다 | 선언을 읽는 케이스가 붉는다 | 두 사본 W **150/6**(`W152` · `W153` · `W154` · `W156` · `W157` · `W159`) · S **20/2**(`S20` · `S21`). 이름이 비면 판정과 기대값이 함께 `?=값`이라 `W137` 등은 초록이고, 그 공허를 이 여섯이 드러낸다. **문면으로 적는 값**: 하니스는 대상 레포에서 돌지 않는다 |
| ⒆ debug 세션 열림 | ⑴ + `.tide/debug-session`(내용 `3`) · `docs/reports/debug-3.md` | 초록 | W 156/0 · S 22/0(두 경로) |
| ⒇ 판정 `불가`인 채 재작업 전 | ⑴ + 판정 `불가`인 `docs/reports/M75-review.md` | 초록 | W 156/0 · S 22/0(두 경로) |
| `st-fail-then-draft` | ⒇ + `docs/milestones/M76.md` | 초록 | W 156/0 · S 22/0(두 경로) |

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: W152 W153 W155 W156 W157 W158 W160 W161 S20 S22 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| spb-dup | 블록 술어 선언 줄을 하나 더 | adversarial | W152 | sh-W 155/1 · ps1-W 155/1 |
| spf-dup | 형태 술어 선언 줄을 하나 더 | adversarial | W153 | sh-W 155/1 · ps1-W 155/1 |
| spb-trailing-tab | 블록 술어 선언 줄 끝에 공백과 탭 | adversarial | W155 | sh-W 155/1 · ps1-W 155/1 |
| spb-drop-clean | 블록 선언과 정의 항목에서 `sp-shape-count`를 함께 지움(라운드 1) | adversarial | W156 | sh-W 155/1 · ps1-W 155/1 |
| spf-drop-clean | 형태 선언과 정의 항목에서 `sp-form-cont`를 함께 지움(라운드 1) | adversarial | W157 | sh-W 155/1 · ps1-W 155/1 |
| spb-drop-name | 블록 선언에서 `sp-shape-count`만 지움(정의는 남음) | adversarial | W156;W160 | sh-W 154/2 · ps1-W 154/2 |
| spf-drop-name | 형태 선언에서 `sp-form-cont`만 지움(정의는 남음) | adversarial | W157;W160 | sh-W 154/2 · ps1-W 154/2 |
| spb-add-name | 블록 선언에 정의 없는 이름 `sp-extra`를 더함 | adversarial | W156;W158 | sh-W 154/2 · ps1-W 154/2 |
| spb-gone | 블록 술어 선언 줄 삭제 | broken | W152;W154;W156;W158;W159 | sh-W 151/5 · ps1-W 151/5 |
| def-dup | `sp-parent` 정의 항목을 하나 더 | adversarial | W158 | sh-W 155/1 · ps1-W 155/1 |
| def-gone | `sp-parent` 정의 항목의 굵은 표기를 지움 | broken | W158 | sh-W 155/1 · ps1-W 155/1 |
| def-moved | `sp-after-item` 항목 머리의 굵은 이름을 지우고 같은 줄 가운데에 굵게(라운드 1 · 리뷰 사소 3) | adversarial | W158 | sh-W 155/1 · ps1-W 155/1 |
| orphan-def | 선언되지 않은 정의 항목 `sp-shape-depth`를 더함(라운드 1 · 리뷰 차단 1) | adversarial | W160 | sh-W 155/1 · ps1-W 155/1 |
| dup-name | 블록 선언의 `sp-pointer`를 `sp-parent`로(이름 중복 · 정의는 남음 · 리뷰 차단 1) | adversarial | W160;W161 | sh-W 154/2 · ps1-W 154/2 |
| name-in-both | 형태 선언의 `sp-form-same`을 `sp-parent`로(두 선언에 같은 이름 · 리뷰 차단 1) | adversarial | W160;W161 | sh-W 154/2 · ps1-W 154/2 |
| dup-name-clean | 이름 중복과 함께 `sp-pointer` 정의 항목도 지움(라운드 1) | adversarial | W161 | sh-W 155/1 · ps1-W 155/1 |
| judge-name-pinned | 이름 헬퍼가 주어진 규약 사본을 무시하게(배선 끊음) | broken | W159 | sh-W 155/1 · ps1-W 155/1 |
| tail-paren | cycle 스킬 불가 갈래 줄 꼬리에 괄호 설명(M73 행 · 새 출력 형태) | adversarial | W118;W137 | sh-W 154/2 · ps1-W 154/2 |
| lazy-continuation | 불가 갈래 아래 같은 깊이의 이어지는 줄(M73 행 · 새 출력 형태) | adversarial | W137 | sh-W 155/1 · ps1-W 155/1 |
| deny-dup | 거부 선언 줄을 하나 더 | adversarial | S20 | sh-S 21/1 · ps1-S 21/1 |
| deny-trailing-tab | 거부 선언 줄 끝에 공백과 탭 | adversarial | S22 | sh-S 21/1 · ps1-S 21/1 |
| deny-emptied | 거부 접두사를 모두 비움 | broken | S21 | sh-S 21/1 · ps1-S 21/1 |
| case-upper-value | 허용 선언에 `docs/Reports/M74-review.md`(대소문자만 다름) | adversarial | S12 | sh-S 21/1 · ps1-S 21/1 |
| docs-upper-outside | 허용 선언에 `Docs/epics/*`(`docs/` 밖 · 라운드 1 · 리뷰 권장 2) | adversarial | S12 | sh-S 21/1 · ps1-S 21/1 |
| deny-debug | 허용 선언에 `docs/reports/debug-1.md`(M74 행 · 선언 출처) | adversarial | S12 | sh-S 21/1 · ps1-S 21/1 |
| deny-glob-reports | 허용 선언에 `docs/reports/*`(M74 행 · 선언 출처) | adversarial | S12;S16 | sh-S 20/2 · ps1-S 20/2 |

<!-- reversal-table:end -->

기준선은 두 사본 Part W **156/0** · Part S **22/0**이다(라운드 1 트리). 백업 키는 저장소 경로이고(파일 다섯 — 규약 본체 · 규약 조각 · cycle 스킬 · 두 러너), 행마다
치환 건수를 단언했다(어긋나면 `EDIT-COUNT`로 멈춘다). 매 행 뒤 다섯 파일을 바이트 그대로 복원하고 `cmp`로 대조했다. **라운드 1 트리로 표의 행 전부와 표 밖 행을 다시
쟀다** — 라운드 0과 값이 바뀐 행은 `spb-drop-name` · `spf-drop-name`(남은 정의 항목이 이제 고아라 `W160`도 붉다 — `W156` · `W157`의 단독 행은 새 `*-clean` 행)과
`spb-gone`(정의 항목을 블록 선언 줄부터 세므로 선언이 없으면 정의를 하나도 못 찾아 `W158`도 붉다)이다.

- **측정이 한 번 시간 상한을 넘겼다** — 첫 묶음(아홉 행)이 포그라운드 10분을 넘겨 백그라운드로 넘어갔고, 그 사이 시작한 둘째 묶음은 드라이버의 사전 대조
  (`DIRTY-BEFORE`)에서 트리가 변이 중임을 보고 **아무것도 바꾸지 않고** 멈췄다. 첫 묶음이 끝난 뒤 다섯 파일이 백업과 바이트 같음을 확인하고, 나머지를 3~6행 묶음으로 쟀다.
- **표 밖 행(초록이어야 한다)** — 두 사본 Part W **156/0**:
  - 오탐 방향 `ok-def-prose`: `sp-parent` 정의 문장의 문구만 고침 — 정의의 뜻은 묻지 않는다.
  - 열린 경계 `spb-reorder`: 블록 선언에서 `sp-parent`와 `sp-pointer`의 순서를 맞바꿈 — 판정과 기대값이 같은 이름 순서로 짝지어져 이름만 바꿔 달리고
    판정은 같다. 규약과 README가 「이름 순서가 값의 위치와 맞는가는 묻지 않는다」로 적는 경계다.
- **`deny-glob-reports`는 `S16`도 붉힌다** — M74와 같은 사유(픽스처가 심는 첫 값이 새 글롭 값의 접두사에도 걸린다).
- **본 검사가 아닌 것의 사유**(`infeasible-evidenced`)
  - **`W154` · `S21`** — 추출 positive-control이다. 각각 `spb-gone` · `deny-emptied`가 붉힌다(`S21`은 단독).
  - **`W159`** — 배선 통제다. `judge-name-pinned`가 단독으로 붉힌다.
- **`adversarial` 행은 스물둘이다** — 술어 선언 · 정의 쪽 열넷, M73 스킬 행 둘, 거부 선언 · 허용 값 쪽 여섯이다(표의 축 칸 그대로).

## 미해결·후속 메모

1. **정의 문장의 뜻과 이름 순서는 묻지 않는다** — 닫힌 목록의 **수와 정체(이름)**는 기계가 들지만, 각 이름의 정의가 러너의 계산과 같은 뜻인지와 이름 순서가 값의
   위치와 맞는지는 리뷰의 자리다(`spb-reorder`가 초록). M73이 다섯 번 걸린 층 중 **목록의 넓이** 쪽은 이제 세 쪽(선언 · 판정 값 · 정의 항목)의 수와 집합을
   양방향으로 대조해 닫혔고(라운드 0은 정의 → 선언 방향이 비어 있었다 — 리뷰 차단 1), **정의의 뜻** 쪽은 남았다. 정의 항목은 「블록 술어 선언 줄부터 다음
   제목까지」의 항목 머리로 정해지므로, 그 범위 **밖**(다른 절, 그리고 같은 절의 선언 줄 위)에 쓴 줄과 다른 목록 표기 · 백틱 없는 굵은 이름은 정의 항목으로 세지 않는다 — 형태와 범위의 경계다
   (리뷰 라운드 1 실측 · 규약 경계 항목에 기록).
2. **다른 산문 열거는 그대로다** — 이번 범위는 시작점 술어와 문서 커밋 거부 접두사 둘이다. 같은 형태(산문이 닫힌 목록을 손으로 적는 자리)가 규약에 더 있는지는
   훑지 않았다(`rf-72`의 나머지).
3. **러너의 기존 판정 열여섯의 기대값이 이름 헬퍼에 기대게 됐다** — 이름 추출이 비면 판정과 기대값이 함께 `?=값`이 되어 초록이다. 그 공허는 `W154` · `W156` ·
   `W157`이 받는다(구현 중 실제로 그 경로를 밟았다 — 위 T03).
