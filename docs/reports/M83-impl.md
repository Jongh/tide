# M83 완료보고서 (impl)

## 개요

M83의 다섯 태스크를 구현했다. 먼저 지울 산문을 읽던 판정을 쟀고(T01), 규약 "문서 커밋 경로" 절의 문서 커밋 전제와 에픽 등재 갈래를 이름 선언 `docs-commit-preconds:` · `docs-commit-epic-cases:`와 이름별 정의 항목으로 올렸다(T02).
release 스킬 · 단계 표 · 커맨드 카탈로그는 전제를 번호가 아니라 이름으로 가리킨다(T03). 두 러너 Part S에 선언 정합 · 덮음 · 잔재 판정과 변환 통제 `S31`~`S47`을 더했고(T04), 하니스 README를 맞췄다(T05).
다섯 태스크가 의존 사슬(T01 → T02 → T03 → T04 → T05)이고 T02 · T03이 같은 규약 파일과 그 재서술처를 함께 고치므로 메인이 순차로 구현했다.

**라운드 1** — 리뷰 라운드 0이 판정 `불가`로 반환했다(차단 1: 덮음 판정 `S39`가 스킬 절 **전체**의 언급을 보아, 절 안 다른 자리에 이름이 남은 채 절차 단계에서 전제를 빼도 초록 · 사소 3).
반환 넷을 닫았다 — R1 덮음을 **번호 단계 머리의 굵은 구획**(`N. **…**`)에 묶고 창의 변환 통제 `S46` · `S47`을 더함 · R2 T01의 Part L 까닭 정정 · R3 규약 고지 「위 세 파일 밖」 → 「위 세 자리 밖」 · R4 T01 sh 측정 범위를 편차로 적음. 되돌림과 상태표를 라운드 1 트리에서 다시 쟀다.

재작업 라운드(rework): 1

## 태스크별 수행 내용

- **M83-T01** — 지울 산문을 읽던 판정을 먼저 쟀다(`rf-98`).
  - HEAD 트리를 `.git` 없이 스크래치 사본(`git archive HEAD` → `t01head`)으로 뜨고, 아래 열 문장을 하나씩 바꾼 사본에서 하니스를 돌렸다. pwsh 7은 `tests/discover` 전수, Git Bash `sh`는 Part B · C · G · L · S다. 사본마다 원문으로 되돌린 뒤 다음 행으로 넘어갔고, 행마다 앵커 수가 정확히 1임을 단언했다(`ANCHOR-MISS` 0건).
  - **편차(R4)** — 마일스톤은 「`tests/discover` 전수를 두 러너로」였으나 sh는 다섯 파트만 돌렸다. 바뀐 파일을 읽는 파트(B · C · G · L · S)로 좁혔고, pwsh가 같은 사본을 전수로 돌렸다(두 러너의 총계 일치는 `F1`이 계약으로 문다). sh 다른 파트의 값은 이 표에 없다.
  - 드라이버는 스크래치패드의 `t01m83.ps1`(pwsh 전수)과 `t01m83sh.ps1`(sh 다섯 파트)이다.

  | 사본 | 바꾼 문장(파일) | 바꾼 방법 | 붉은 케이스(기준선 대비) |
  |---|---|---|---|
  | base | — | — | 기준선: pwsh 635/2(`T3` · `U6` — `.git` 없는 사본 · impl 보고서 없음) · sh B 14/0 · C 30/0 · G 18/0 · L 13/0 · S 30/0 |
  | a-precond-count | 「다음 셋을 **모두** 요구」(`docs/conventions-release.md`) | 수 낱말 셋 → 넷 | 없음 |
  | b-precond-drop | 전제 목록 둘째 항목(같은 파일) | 목록 항목 하나 지움 | 없음 |
  | c-epic-count | 「갈래는 셋이다」(같은 파일) | 셋 → 넷 | 없음 |
  | d-epic-drop | 에픽 갈래 셋째 항목(같은 파일) | 목록 항목 하나 지움 | 없음 |
  | e-order-num | 「**순서**: 첫째·둘째 전제」(같은 파일) | 둘째 → 셋째 | 없음 |
  | f-skill-12 | 「전제 ①②」(`skills/release/SKILL.md`) | ② → ③ | 없음 |
  | g-skill-3 | 「전제 ③」(같은 파일) | ③ → ④ | 없음 |
  | h-stage-table | 단계 표 release 행의 전제 서술(`docs/conventions.md`) | 전제 하나 지움 | 없음 |
  | i-commands | 「문서 커밋」 문단의 전제 서술(`docs/commands.md`) | 전제 하나 지움 | 없음 |
  | j-readme-s | Part S 「묻지 않는 것」의 「전제 셋」(`tests/discover/README.md`) | 셋 → 넷 | 없음 |

  - **결과** — 열 문장 모두 지금 아무 판정도 묻지 않는다. 그래서 선언화로 잃는 판정이 없고, 대신 세울 케이스도 없다(완료 기준 3).
  - **Part L이 두 수 문장을 묻지 않은 까닭(R2 정정)** — 라운드 0은 「한글 바로 뒤에 수 낱말이 붙어서」라고 적었으나 사실이 아니다. 두 문장 모두 수 낱말 앞이 공백이다. 실제 까닭은 둘이다.
    - 「다음 셋을」 — 「을」은 `count-copula:`(`docs/conventions.md`의 이다 · 이고 · 이며 · 이라 · 이니)에 없어 표지 후보가 아니다.
    - 「갈래는 셋이다」 — 표지 후보다. 그러나 Part L은 창 안의 `⑴`~`⒇` · `①`~`⑳` 열거만 세는데, 그 목록은 `- ` 글머리라 센 항목이 0이다(`tests/discover/README.md` Part L 「창의 명세」).
    - M82의 「갈래는 넷이다」가 물린 것은 그 뒤 열거가 `⑴`~`⑷`였기 때문이다.
- **M83-T02** — `docs/conventions-release.md` "문서 커밋 경로" 절.
  - 「문서 커밋 전제」의 번호 목록을 선언 한 줄(`docs-commit-preconds:` dc-phase-idle dc-no-debug-session dc-changes-declared)과 같은 깊이의 정의 항목 셋으로 바꿨다. 정의 문장은 옛 목록 항목을 그대로 옮겼다(`-uall` 사유 · 「커밋할 것 없음」 포함). 「선언의 이름 순서가 절차가 전제를 확인하는 순서다」를 선언 앞에 적었다.
  - 순서 문단은 「`dc-phase-idle` · `dc-no-debug-session` → 현재 브랜치 확인 → `dc-changes-declared` → 에픽 등재 확인 → 프리플라이트」로 이름을 쓴다.
  - 「에픽 등재 동반 규칙」의 「갈래는 셋이다」와 목록을 선언 한 줄(`docs-commit-epic-cases:` dc-epic-uncommitted dc-epic-missing dc-epic-committed)과 정의 항목 셋으로 바꿨다. Part M이 둘째 방어선이라는 문장은 `dc-epic-missing`에 그대로 옮겼다.
  - 같은 파일의 다른 자리(「문서 커밋 프리플라이트」 · 「문서 커밋 게시」 등 여섯 곳)의 「첫째 전제」 · 「셋째 전제」를 `dc-phase-idle` · `dc-changes-declared`로 바꿨다.
  - 「기계가 묻는 것(M83)」 · 「묻지 않는 것」 문단을 더했다(아래 고지 대응표). 산문 안의 접두어는 백틱 없이 「dc-」로 적었다 — 백틱으로 적으면 잔재 판정 `S40`이 접두어 자체를 이름으로 읽는다.
    라운드 1에서 덮음 고지를 「번호 단계 머리(`N. **…**`의 굵은 구획)가 가리킨 이름 집합」으로 좁히고 「절 안 산문이나 단계 본문의 언급은 덮음으로 치지 않는다」를 적었다. 「묻지 않는 것」에 「단계 머리에 이름을 둔 단계가 그 전제를 실제로 확인하는 문장을 갖는가」를 더했고, 「위 세 파일 밖」을 「위 세 자리 밖」으로 고쳤다(R3 — 첫 자리가 글롭 집합이다).
  - `docs/conventions.md` 단계 표 release 행의 「(문서 커밋 경로는 전제 — phase `idle` · debug 세션 없음 · 선언 밖 미커밋 변경 0)」을 「(문서 커밋 경로는 `docs-commit-preconds:`가 든 전제)」로 바꿨다.
  - **재서술처 훑기** — 패턴 `전제 [①②③]|첫째.*전제|둘째.*전제|셋째 전제|전제 셋|갈래는 셋|다음 셋을` · 대상 저장소 전체 파일 가운데 `*.md` · `*.sh` · `*.ps1` · `*.yml` · `*.json`(`docs/reports/` · `docs/milestones/` · `CHANGELOG.md` 제외 — 이력) · 대조 항목 「문서 커밋 전제 · 에픽 등재 갈래를 번호나 수로 가리키는 자리」 · 루트 저장소.
    결과: 남은 히트 다섯은 모두 다른 열거다 — `docs/epics/E2.md:177` · `:187` · `:195` · `:197` · `:298`(에픽의 축 ⑵ 「미측정 전제」 ⑴~⑹)과 `docs/project-context.md:331`(이월 원장의 「전제 ⑴·⑶」 — 같은 에픽 전제). 문서 커밋 전제를 가리키는 히트는 0이다.
- **M83-T03** — `skills/release/SKILL.md` · `docs/commands.md`.
  - 스킬 「스테이징 범위」의 「그 절의 전제 ③이」 → 「전제 `dc-changes-declared`가」, 「phase 복원」의 「자기 전제 ①에」 → 「자기 전제 `dc-phase-idle`에」, 2단계 「**전제 ①②**」 → 「**전제 `dc-phase-idle` · `dc-no-debug-session`**」(본문의 ① · ②도 이름으로), 4단계 「**전제 ③**」 → 「**전제 `dc-changes-declared`**」로 바꿨다.
  - `git diff -U0 skills/release/SKILL.md`의 hunk 넷(139 · 204 · 208~209 · 212행)이 모두 같은 줄 수의 문면 치환이다. 단계 번호 1~10과 그 순서는 HEAD와 같다.
  - **편차 하나** — T03 상세는 「스킬은 이름을 가리키기만 하고 정의 문장을 다시 적지 않는다」였다. 2 · 4단계에는 HEAD부터 전제의 운영 문장(「`.tide/phase`가 `idle`이다」 · `git status --porcelain -uall` 조건 등)이 있었고, 이것을 지우지 않았다. 사용자 실행 표면에서 절차의 동작 문장을 빼면 동작이 바뀔 수 있어, 이 사이클은 문면 치환만 했다(T03 「문면만 바꾸고 절차 단계를 더하거나 빼지 않는다」).
    그래서 규약에 처음 쓴 「스킬 · 문서는 … 정의 문장을 옮겨 적지 않는다」는 사실보다 넓은 주장이 되어, 라운드 0 보고서를 쓰기 전에 그 구절을 걷었다. 정의 문장의 뜻과 스킬 절차가 같은가는 규약 「묻지 않는 것」 첫 항목에 그대로 있다.
  - `docs/commands.md`의 「phase `idle` · 열린 debug 세션 없음 · 선언 밖 미커밋 변경 0일 때만」을 「`docs-commit-preconds:`가 든 전제를 모두 만족할 때만」으로 바꿨다.
- **M83-T04** — `tests/discover/run.sh` · `tests/discover/run.ps1`.
  - 선언 읽기는 M79의 공용 헬퍼(`dn_names` · `dn_dup` · `dn_def_bad` · `dn_def_orphan` · `dn_def_order` · `Dn*`)를 그대로 쓴다. 헬퍼가 이미 키와 규약 파일을 인자로 받으므로 `docs/conventions-release.md`(`$CONV_REL`)를 넘겼고 헬퍼는 고치지 않았다.
  - 새 헬퍼:
    - `dcn_toks` · `DcnToks` — 백틱 `dc-` 토큰을 중복 없이 뽑는다.
    - `dcn_heads` · `DcnHeads`(라운드 1) — 번호 단계 머리(줄 머리 `[0-9]+\. \*\*`)의 첫 굵은 구획만 낸다. 단계 본문과 절 산문은 내지 않는다.
    - `dcn_cover_bad` · `DcnCoverBad` — 스킬 「문서 커밋 경로」 절(`S15`와 같은 `dc_sec` 창) 안 **단계 머리**의 토큰 집합과 전제 선언의 이름 집합의 대칭차 크기.
    - `dcn_stray` · `DcnStray` — 규약 문서 집합(글롭) · release 스킬 · 커맨드 카탈로그 안 토큰 중 두 선언에 없는 것의 수.
    - `dcn_sum` · `DcnSum` — 두 키에 같은 `dn_*` 판정을 돌려 합한다.
    - `dcn_fixture` · `DcnFixture` — 합성 규약 · 합성 스킬 픽스처 일곱 모드(`defdrop` · `addname` · `outside` · `inside` · `prose` · `headtail` · `stray`). 실제 파일은 건드리지 않는다.
  - 덮음은 집합과 대칭차로 묻고 손 상수를 두지 않는다(`rf-97`). 수는 집합 크기로만 드러난다. 위치로 읽는 판정이 아니므로 이름이 끼어들어도 붉는다(M82 라운드 0 차단의 교훈).
  - **라운드 1(R1)** — 라운드 0의 덮음은 절 전체의 언급을 보아, `dc-phase-idle`처럼 절 안 다른 자리(「phase 복원」 산문)에 이름이 남으면 2단계에서 그 전제를 빼도 초록이었다. 덮음을 단계 머리의 굵은 구획에 묶어 닫았다(되돌림 `skill-step-drop` · `dcp-add-prose-only`). 지금 스킬의 두 단계 머리(2 · 4단계)가 전제 셋을 모두 든다.
  - 케이스 `S31`~`S47`: 선언 줄 수 `S31` · `S32` · 금지 구분자 `S33` · 추출 양성 통제 `S34`(라운드 1부터 단계 머리 토큰) · 본 검사 `S35`(유일) · `S36`(정의 정확히 하나) · `S37`(고아 정의) · `S38`(정의 순서) · `S39`(덮음) · `S40`(잔재) · 변환 통제 `S41`(정의 범위) · `S42`(이름 위치 · 덮음 배선) · `S43` · `S44`(스킬 절 창의 앞 · 안 — 단계 머리 꼴) · `S45`(백틱 토큰 추출 · 잔재 배선) · `S46`(절 안 산문 줄은 세지 않음) · `S47`(굵은 구획 뒤는 세지 않음).
  - ps1 사본은 ASCII만 쓴다(`[^\x00-\x7F]` 0줄 — Part F의 `F5`가 문다).
- **M83-T05** — `tests/discover/README.md`의 머리 `cases:` 선언, Part S의 수와 제목, 새 소절 「문서 커밋 전제와 에픽 등재 갈래를 이름으로 문다(`S31`~`S47` · M83)」와 소계를 더했다. Part S 「묻지 않는 것」 ⑴은 `docs-commit-preconds:` 포인터로 바꿨고 수 낱말을 새로 쓰지 않았다.
  - 라운드 1에서 「덮음과 수」를 단계 머리 기준으로 고쳤다 — 라운드 0의 「스킬에서만 지우면 붉다」는 리뷰 차단 1의 넓은 주장이었고 「단계 머리에서 지우면 붉다 — 절 안 산문이나 단계 본문에 이름이 남아 있어도 덮음으로 치지 않는다」로 바꿨다. 변환 통제에 단계 머리 창(`S46` · `S47`)을 적었다.
  - 처음에는 새 소절의 인용을 「규약 "문서 커밋 경로" 절」로 적었는데, 파일명이 없어 Part G `G4`가 README 자신의 절로 읽고 붉었다(자기참조 2건). `` `docs/conventions-release.md`의 "문서 커밋 경로" 절 `` 꼴로 고쳐 닫았다.

**고지 대응표**(완료 기준 5 — 규약 「기계가 묻는 것(M83)」의 판정 ↔ 케이스)

| 고지의 판정 | 케이스 |
|---|---|
| 두 선언 줄이 키마다 정확히 하나 | `S31` · `S32` |
| 꼬리에 금지 구분자가 없다 | `S33` |
| 이름 추출이 비지 않는다 | `S34` |
| 이름이 유일하다 | `S35` |
| 이름마다 정의 항목이 정확히 하나이고 고아 정의가 없다 | `S36` · `S37` (통제 `S41`) |
| 정의 항목의 순서 = 선언의 이름 순서 | `S38` |
| 스킬 「문서 커밋 경로」 절의 번호 단계 머리가 가리킨 dc- 전제 이름 집합 = `docs-commit-preconds:`의 이름 집합 · 절 안 산문과 단계 본문의 언급은 치지 않는다 | `S39` (통제 `S42` · `S43` · `S44` · `S46` · `S47`) |
| 규약 문서 집합 · release 스킬 · 커맨드 카탈로그의 백틱 dc- 토큰이 전부 두 선언의 이름 | `S40` (통제 `S45`) |

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | `docs/conventions-release.md`에 `docs-commit-preconds:` · `docs-commit-epic-cases:` 선언 줄이 하나씩이고(`S31` · `S32`) 이름마다 정의 항목이 정확히 하나다(`S36` · `S37`). 절 안의 번호 · 수 지칭 0. 훑기는 다음과 같다. 패턴 `[①②③]\|첫째\|둘째\|셋째\|셋이\|셋을\|전제 셋\|갈래는 셋\|넷` · 대상 그 절(244행 `## 문서 커밋 경로`부터 파일 끝까지 — 뒤에 같은 깊이 제목이 없다) · 대조 항목 「전제 · 에픽 갈래를 번호나 수 낱말로 가리키는 자리」 · 루트 `docs/conventions-release.md`. pwsh `-match`로 줄마다 훑었다. 남은 히트 둘은 다른 열거다 — 309행 「둘째 방어선」(Part M의 자리 — T02가 옮기라고 한 문장) · 341행 「파트가 파일을 읽는 길은 셋이다」(`docs-commit-parts:`의 근거 열거) |
| 2 | 충족 | 스킬 「문서 커밋 경로 (docs)」 절(191~233행) 안의 번호 지칭 0. 패턴 `[①②③]\|첫째\|둘째\|셋째\|전제 셋` · 대상 그 절 · 대조 항목 「전제를 번호로 가리키는 자리」 · 루트 `skills/release/SKILL.md`로 pwsh에서 훑었다. 단계 머리의 백틱 `dc-` 토큰 집합과 선언 집합이 같다(`S39` 대칭차 0). 절차 단계 1~10의 수와 순서는 HEAD와 같다 — `git diff -U0`의 hunk 넷이 같은 줄 수의 문면 치환이다(T03 항목). 라운드 1은 스킬을 고치지 않았다 |
| 3 | 충족 | T01 표 — 열 문장 모두 「붉은 케이스」가 「없음」이다. 대신 세울 판정이 없다 |
| 4 | 충족 | 되돌림 표 — ⑴ `dcp-name-drop` ⑵ `dcp-name-dup` · `dce-name-dup` ⑶ `dcp-def-drop` ⑷ `dcp-def-extra` ⑸ `dcp-def-swap` ⑹ `dcp-add-end` ⑺ `dcp-add-mid` ⑻ `skill-name-drop`(절 안 언급이 하나뿐인 이름을 전부 지움) · `skill-step-drop`(절 안 다른 언급이 남은 이름을 단계 머리에서만 지움 — 라운드 1) ⑼ `dcp-rename-leftover` ⑽ `dce-name-drop` ⑾ `dcp-decl-indent`. ⑹의 이웃 갈래(선언에 더하고 절 산문에만 적음)는 `dcp-add-prose-only`. 전부 ps1 전수와 sh Part S에서 같은 케이스로 붉다 |
| 5 | 충족 | 위 「고지 대응표」 — 규약 「기계가 묻는 것(M83)」의 판정마다 케이스가 하나 이상이다 |
| 6 | 충족 | 아래 생명주기 상태표 — 상태 목록 전부와 판정별 격자. 판정이 읽는 입력(규약 조각 · release 스킬 · 커맨드 카탈로그)을 바꾸는 전이는 `tr-downstream`(해당 없음) 하나뿐이다. 라운드 1 트리에서 다시 쟀다 |
| 7 | 충족 | 마지막 측정(이 보고서를 쓴 뒤): 아래 테스트 결과. 수는 `tests/discover/README.md`의 `cases:` 선언처를 가리킨다. sh 전수는 `measure-axis:`대로 CI가 판정한다 |
| 8 | 충족 | `git diff --name-only -- hooks/ skills/` → `skills/release/SKILL.md` 하나. 그 diff는 기준 2의 문면 치환뿐이다. `hooks/` 변경 0 |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M83-impl.md` |
| 수정 | `docs/conventions-release.md` · `docs/conventions.md` · `docs/commands.md` · `skills/release/SKILL.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` · `docs/epics/E2.md` |
| 삭제 | (없음) |

`docs/milestones/M83.md`와 `docs/epics/E2.md`(등재 한 줄)는 직전 `/tide:milestone`의 미커밋 산출물이다. `docs/reports/M83-review.md`는 리뷰 라운드 0의 미커밋 산출물이다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (pwsh 7.6.9 · Windows PowerShell 5.1.26100 — 전수 / Git Bash `sh` — Part S 등 부분) | pwsh **654/0** · 5.1 **654/0** · sh S 47/0 · sh L 13/0 · sh G 18/0 · sh U 7/0 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — 규약 `measure-axis:`의 배당) | 릴리즈 단계에서 확인 |

- **마지막 측정**(이 보고서를 쓴 뒤의 트리) — `pwsh` · `powershell` `tests/discover/run.ps1` → `# result: PASS=654 FAIL=0` · 나머지 하니스 여섯(`multi-repo` 37 · `fleet` 45 · `fleet-cycle` 24 · `fleet-verify` 30 · `site-includes` 51 · `mutation` 12)은 pwsh 7과 5.1에서 FAIL 0 · Git Bash `bash tests/discover/run.sh S` → 47/0 · `L` → 13/0 · `G` → 18/0 · `U` → 7/0. 표의 값을 채운 뒤 pwsh 7 전수를 한 번 더 돌려 같은 654/0을 확인했다. 메모리 부족을 피해 측정은 명령마다 하나씩 포그라운드로 돌렸다.
- **라운드 1 기준선** — 라운드 1 코드를 넣고 이 보고서를 고치기 전의 트리에서 pwsh 전수 654/0(라운드 0 보고서가 있어 `U6`은 초록이다) · Git Bash `sh` Part S 47/0 · F 30/0 · G 18/0 · L 13/0.
- **캐시가 아닌 실행임을 확인한 방법**(`measure-not-cached`) — 하니스는 빌드 캐시가 없는 해석형 스크립트다. 라운드 1에서 케이스 수가 652 → 654로 바뀐 것이 결과 줄에 그대로 보였고, 되돌림 `heads-all-sh` · `heads-all-ps1`이 새 케이스 `S46` · `S47`을 실제로 붉혔다.
- **구현 중 발견한 것**
  1. README 인용의 파일명 누락으로 `G4`가 붉었다(T05 항목).
  2. 라운드 0의 첫 되돌림 드라이버는 백그라운드로 돌다가 시스템이 메모리 부족으로 멈췄다. 이어받을 때 행마다 포그라운드로 하나씩 다시 돌렸다.
  3. 되돌림 드라이버의 판정 쪽 행 셋(`cover-zero-sh` · `cover-zero-ps1` · `stray-zero-both`)은 처음에 앵커 문자열을 괄호로 감싸지 않았다. PowerShell 배열 리터럴에서 쉼표가 `+`보다 먼저 묶여 편집이 의도와 다른 자리에 들어갔다(sh 출력이 비거나 `S42`가 초록). 괄호로 감싸고, 편집 원소 수가 넷이 아니면 `ANCHOR-MISS`로 세게 드라이버를 고친 뒤 다시 쟀다.
  4. 첫 `dcp-add-end` 행은 정의를 `dc-changes-declared` **앞**에 넣어 `S38`(순서)도 함께 붉었다. 정의를 끝에 두게 고쳐 다시 쟀다(`S39` 단독).
  5. 라운드 1에서 README 여러 줄 앵커를 pwsh 치환으로 고치려다 세 곳이 0건 매치로 빠졌다(한 줄 치환만 성공 — 알려진 함정). 빠진 세 곳을 편집 도구로 고쳤고, 치환은 앵커 수를 단언하게 해 두어 조용히 넘어가지 않았다.

**생명주기 상태표**(`lifecycle-state-table`) — 기계 판정을 새로 세웠으므로 단다. 라운드 1 트리에서 다시 쟀다.

- **판정이 읽는 입력**: `docs/conventions*.md`(글롭 — `S40`) · 그중 `docs/conventions-release.md`의 두 선언과 정의 항목 · `skills/release/SKILL.md`의 「문서 커밋 경로」 절(덮음은 그 절의 단계 머리) · `docs/commands.md`.
- **그 입력을 바꾸는 전이**(판정별 격자 ②): `tr-downstream`(대상 레포에는 이 하니스가 돌지 않는다 — 아래 ⒅) 하나뿐이다. 나머지 전이 `tr-draft` · `tr-impl` · `tr-review` · `tr-release-commit` · `tr-forced` · `tr-debug-release` · `tr-pr-create` · `tr-continuous-stop` · `tr-tag` · `tr-pr-finalize` · `tr-retro` · `tr-retro-skip` · `tr-debug-open` · `tr-debug-done` · `tr-part-select`는 마일스톤 · 보고서 · CHANGELOG · 버전 파일 · 회고 · `.tide/`만 바꾼다. 위 세 입력은 건드리지 않으므로 이 판정에 항등이다.
- **사본 다섯**(A~E) — 작업 트리를 `.git` 없이 스크래치패드로 복사하고(`st83.ps1`) 상태를 만든 뒤 세 실행 환경에서 Part S를 돌렸다. 항등인 전이도 대표 상태마다 실제 사본으로 쟀다. 상태를 만드는 치환은 앵커가 없으면 드라이버가 멈추게 했다.

| 상태 | 사본(만든 방법) | 기대 | 실제(pwsh · 5.1 · sh Part S) |
|---|---|---|---|
| ⑴ 사이클 중 (`tr-draft` `tr-impl`) | A — 현재 트리 그대로 | 초록 | 47/0 · 47/0 · 47/0 |
| ⑵ 리뷰 뒤 (+`tr-review`) | A — 리뷰 보고서는 Part S 입력이 아니다(라운드 1 트리에 리뷰 보고서가 있다) | 초록 | A와 같음 |
| ⑶ 릴리즈 커밋 (+`tr-release-commit` · 같은 트리를 `tr-continuous-stop` · `tr-pr-create`) | B — `plugin.json` 2.47.0 · CHANGELOG 표지 다음에 v2.47.0 머리 · M83에 `- released:` | 초록 | 47/0 · 47/0 · 47/0 |
| ⑷ 태그 뒤 후처리 전 (+`tr-tag`/`tr-pr-finalize`) | B — 태그는 트리를 바꾸지 않는다 | 초록 | B와 같음 |
| ⑸ 태그 뒤 후처리 후 (+`tr-retro`) | C — B + 회고 최상단 제목을 v2.47.0으로 | 초록 | 47/0 · 47/0 · 47/0 |
| ⑹ ⑵에서 다음 초안 (+`tr-draft`) | D — `docs/milestones/M84.md` 초안(기반 v2.46.0) | 초록 | 47/0 · 47/0 · 47/0 |
| ⑺ ⑶에서 다음 초안 (+`tr-draft`) | B · D와 같은 입력 — 세 입력 파일이 A와 바이트 같다 | 초록 | B · D와 같음 |
| ⑻ ⑷에서 회고 건너뛰고 초안 (+`tr-retro-skip` `tr-draft`) | 같은 까닭 | 초록 | B · D와 같음 |
| ⑼ debug 릴리즈 커밋 | B와 같은 입력(CHANGELOG · 버전 파일만 다르다) | 초록 | B와 같음 |
| ⑽ 후처리 건너뛴 뒤 debug 릴리즈 커밋 | 같은 까닭 | 초록 | B와 같음 |
| ⑾ 강행 릴리즈 커밋 (+`tr-forced`) | B — 트리가 릴리즈 커밋과 같다 | 초록 | B와 같음 |
| ⑿ 파트 선택 실행 (`tr-part-select`) | 사본 다섯 전부가 `-Part S` · `run.sh S`로 돌았다 | 전수와 같은 답 | 실제 트리에서 부분 47/0 · 전수의 Part S도 0 붉음 |
| ⒀ ⑴·⑵에서 debug 릴리즈 태그 뒤 후처리 후 | C와 같은 입력 | 초록 | C와 같음 |
| ⒁ ⑹에서 debug 릴리즈 태그 뒤 후처리 후 | C · D와 같은 입력 | 초록 | C · D와 같음 |
| ⒂ ⑹에서 직전만 강행 릴리즈 | B · D와 같은 입력 | 초록 | B · D와 같음 |
| ⒃ ⑹에서 다음 사이클까지 마치고 함께 릴리즈 | 같은 까닭 — impl · 리뷰 보고서는 입력이 아니다 | 초록 | B · D와 같음 |
| ⒄ 다음이 impl만 마친 채 직전 강행 릴리즈 | 같은 까닭 | 초록 | B · D와 같음 |
| ⒅ 대상 레포에서 처음 도는 릴리즈 (`tr-downstream`) | 문면 — 이 판정은 하니스(`tests/discover`)에만 있고 하니스는 대상 레포에서 돌지 않는다. 대상 레포에서 규칙은 release 스킬 `docs` 절차로 돈다 — 2 · 4단계가 전제의 운영 문장(`.tide/phase`가 `idle` · `.tide/debug-session` 없음 · `git status --porcelain -uall`의 모든 경로가 `docs-commit-paths:` 선언 안이고 하나 이상)을 그대로 들고 있어(T03 편차), 대상 레포 규약에 `docs-commit-preconds:`가 없어도 dc- 이름을 풀지 않고 같은 확인을 한다. 이 저장소의 선언 값(이름)은 대상 레포의 판정 값이 되지 않는다 — 이름은 지칭일 뿐 확인의 입력이 아니다 | 대상 레포에서 같은 세 확인 | 문면 대조(위 2 · 4단계 · `skills/release/SKILL.md` 208~209 · 212~215행) |
| ⒆ debug 세션이 열린 채 (⑴·⑵ + `tr-debug-open`) | E — `.tide/debug-session` · 판정 없는 `docs/reports/debug-3.md` | 초록 | 47/0 · 47/0 · 47/0 |
| ⒇ 판정 `불가`인 채 재작업 전 | A — 리뷰 판정은 입력이 아니다 | 초록 | A와 같음 |
| `st-fail-then-draft` | D — 같은 까닭 | 초록 | D와 같음 |

판정별 격자 ③(남은 전이 × 마일스톤 단계 부류 일곱)이 낸 목록 밖 상태는 없다. 남은 전이 가운데 이 판정의 입력을 바꾸는 것이 없어 모든 조합이 A와 같은 입력으로 모인다.

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: S35 S36 S37 S38 S39 S40 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| dcp-name-drop | `docs-commit-preconds:`에서 `dc-no-debug-session`을 지움 | adversarial | S37 · S39 · S40 | ps1 전수 650/4 · sh S 44/3 |
| dcp-name-dup | 전제 선언 끝에 `dc-phase-idle`을 한 번 더 붙임 | adversarial | S35 · S41 | ps1 전수 651/3 · sh S 45/2 |
| dce-name-dup | 에픽 갈래 선언 끝에 `dc-epic-missing`을 한 번 더 붙임 | adversarial | S35 | ps1 전수 652/2 · sh S 46/1 |
| dcp-def-drop | `dc-no-debug-session` 정의 항목의 머리를 백틱 없는 굵은 글로 바꿈 | adversarial | S36 | ps1 전수 652/2 · sh S 46/1 |
| dcp-def-extra | 선언에 없는 정의 항목 `zz-extra`를 같은 깊이에 더함 | adversarial | S37 | ps1 전수 652/2 · sh S 46/1 |
| dcp-def-swap | 정의 항목 첫 둘의 이름을 맞바꿈 | adversarial | S38 | ps1 전수 652/2 · sh S 46/1 |
| dcp-add-end | 선언 끝에 `dc-extra` · 정의 항목을 끝에 더하고 스킬은 그대로 둠 | adversarial | S39 | ps1 전수 652/2 · sh S 46/1 |
| dcp-add-mid | `dc-extra`를 선언 둘째 자리에 끼우고 정의도 같은 자리에 둠 · 스킬은 그대로 | adversarial | S39 | ps1 전수 652/2 · sh S 46/1 |
| dcp-add-prose-only | 선언 끝에 `dc-extra` · 정의를 더하고 스킬은 절 안 「phase 복원」 산문에만 `dc-extra`를 적음(리뷰 라운드 0 차단 1의 반대 방향) | adversarial | S39 | ps1 전수 652/2 · sh S 46/1 |
| skill-name-drop | 스킬의 백틱 `dc-no-debug-session`을 전부 백틱 없는 낱말로 | adversarial | S39 | ps1 전수 652/2 · sh S 46/1 |
| skill-step-drop | 2단계 머리를 「**전제 `dc-no-debug-session`**」으로 줄여 `dc-phase-idle`을 단계에서만 뺌 — 절 안 「phase 복원」 산문의 언급은 남김(리뷰 라운드 0 차단 1) | adversarial | S39 | ps1 전수 652/2 · sh S 46/1 |
| dcp-rename-leftover | 선언 · 정의 머리의 `dc-no-debug-session`만 `dc-no-session`으로 바꾸고 스킬 · 규약 산문의 옛 이름을 남김 | adversarial | S39 · S40 | ps1 전수 651/3 · sh S 45/2 |
| dc-stray-only | `docs/conventions.md` 단계 표에 선언에 없는 백틱 `dc-old-name`을 더함 | adversarial | S40 | ps1 전수 652/2 · sh S 46/1 |
| dce-name-drop | 에픽 갈래 선언에서 `dc-epic-committed`를 지움 | adversarial | S37 · S40 | ps1 전수 651/3 · sh S 45/2 |
| dcp-decl-indent | 전제 선언 줄을 두 칸 더 들여씀(정의 항목은 그대로) | adversarial | S36 · S41 | ps1 전수 651/3 · sh S 45/2 |
| cover-zero-sh | `run.sh`의 `dcn_cover_bad` 합산을 「항상 0」으로 | broken | S42 · S44 | sh S 45/2(ps1은 깨지 않음 — 전수 653/1) |
| cover-zero-ps1 | `run.ps1`의 `DcnCoverBad` 반환을 「항상 0」으로 | broken | S42 · S44 | ps1 전수 651/3(sh는 깨지 않음 — S 47/0) |
| heads-all-sh | `run.sh`의 `dcn_heads`를 `cat`으로(절의 모든 줄을 단계 머리로 침) | broken | S46 · S47 | sh S 45/2(ps1은 깨지 않음 — 전수 653/1) |
| heads-all-ps1 | `run.ps1`의 `DcnHeads`가 단계 머리 거름 없이 모든 줄을 냄 | broken | S46 · S47 | ps1 전수 651/3(sh는 깨지 않음 — S 47/0) |
| stray-zero-both | 두 러너의 `dcn_stray` · `DcnStray` 반환을 함께 「항상 0」으로 | broken | S45 | ps1 전수 652/2 · sh S 46/1 |

<!-- reversal-table:end -->

- **기준선** — 라운드 1 코드를 넣은 트리(이 보고서 갱신 전)의 사본에서 ps1 전수 **653/1**(`T3` — 사본에 `.git`이 없어 추적 파일 양성 통제가 빈다) · sh S **47/0**. 표의 ps1 결과는 그 기준선에서의 값이고, 「붉은 케이스」는 기준선 밖에서 붉은 것만 적는다.
  - 드라이버는 스크래치패드의 `rev83.ps1`이고 결과는 `rev83r1.txt`다(라운드 0 값은 `rev83.txt` · `rev83b.txt`). 실행마다 작업 트리를 `.git` 없이 새 사본(`rev83base`)으로 뜨고, 행마다 편집 전 원문을 메모리에 두었다가 행 끝에 되돌린다. 작업 트리는 건드리지 않는다.
  - 행마다 편집의 앵커 수를 단언했다(한 번 바꾸는 편집은 정확히 1 · 전부 바꾸는 편집은 1 이상 · 편집 원소 수 넷 — 어긋나면 `ANCHOR-MISS`, 결과 0건). 결과 줄 수가 요청 행 수(기준선 1 + 20)와 같다. sh는 `C:\Program Files\Git\bin\bash.exe`로 불렀다.
- **본 검사 단독 행** — 목록 줄의 여섯은 각각 자기 하나만 붉는 행이 있다 — `S35` `dce-name-dup` · `S36` `dcp-def-drop` · `S37` `dcp-def-extra` · `S38` `dcp-def-swap` · `S39` `skill-step-drop`(또 `dcp-add-end` · `dcp-add-mid` · `dcp-add-prose-only` · `skill-name-drop`) · `S40` `dc-stray-only`.
  선언 줄 수 `S31` · `S32`와 금지 구분자 `S33` · 양성 통제 `S34`는 선언 꼴의 기반 검사라 목록에 넣지 않았다. 변환 통제 `S41`~`S47`도 목록 밖이다.
- **방향** — 판정 쪽(`broken`): 덮음 대조 · 단계 머리 창 · 잔재 수. 입력 쪽(`adversarial`): 이름 · 정의의 지움 · 복제 · 더함 · 맞바꿈 · 이름 바꿈 뒤 잔재 · 스킬 쪽 이름 지움(전부 · 단계에서만) · 산문에만 적음 · 선언 줄 들여쓰기(입력 꼴 — `rf-01`). 공용 헬퍼 `dn_*` · `Dn*`의 판정 쪽 되돌림은 M79 · M82의 행이 이미 든다 — 이 사이클은 헬퍼를 고치지 않았다.

## 미해결·후속 메모

1. **스킬이 전제의 운영 문장을 다시 적는다** — 2 · 4단계에 HEAD부터 있던 동작 문장을 지우지 않았다(T03 편차). 뜻이 규약 정의와 같은가는 규약 「묻지 않는 것」에 있다. 이 문장을 걷어 스킬이 이름만 가리키게 하려면 그 단계의 동작을 규약 읽기에 맡겨도 되는지 먼저 정해야 한다.
2. **단계 머리는 이름을 든다는 것까지만 묻는다** — 이름을 단계 머리에 남긴 채 그 단계 본문에서 확인 문장을 지우면 초록이다(규약 「묻지 않는 것」). 덮음은 「어느 단계가 그 전제를 건다고 선언했는가」를 묻고, 그 단계가 실제로 무엇을 하는가는 프롬프트 절차다.
3. **스킬이 이름을 선언 순서대로 가리키는가** — `S39`는 집합만 묻는다. 순서를 바꾼 스킬은 초록이다(규약 「묻지 않는 것」). 이번 무리의 순서는 스킬 단계 번호가 들고 있고, 현재 브랜치 확인이 두 전제 사이에 끼므로 선언 순서와 스킬 순서가 줄 단위로 같지 않다.
4. **에픽 갈래 이름은 스킬이 가리키지 않는다** — 덮음을 묻지 않는다. 대신 잔재(`S40`)와 선언 정합(`S35`~`S38`)이 갈래 선언을 문다. 스킬 단계 머리에 에픽 갈래 이름을 적으면 `S39`가 붉는다 — 조용히 넘어가지 않는 쪽이다.
5. **잔재 판정의 범위는 세 자리다** — 규약 문서 집합 · release 스킬 · 커맨드 카탈로그. 하니스 README · 보고서 · 사이트의 dc- 토큰은 보지 않는다(규약 「묻지 않는 것」).
6. **Part L이 묻지 않는 수 문장 꼴** — `count-copula:` 밖의 조사가 붙은 수 낱말(「셋을」 등)과, 뒤 열거가 `⑴`/`①`이 아닌 목록인 수 문장은 Part L이 대조하지 않는다(T01 정정). 이번에는 그 문장을 지웠으므로 잃은 판정이 없다. 다른 자리의 같은 꼴 문장은 그대로 묻히지 않는다.
7. **`rf-86`의 나머지** — release 게이트 ①②③ · 도입 번호 파생 ⑴~⑶ · 고지 절 일곱 · Part W `sp_*`의 `dn_*` 흡수는 그대로 산문이다. 이 사이클은 문서 커밋 전제 무리 하나만 집었다.
