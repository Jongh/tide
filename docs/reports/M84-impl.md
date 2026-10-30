# M84 완료보고서 (impl)

## 개요

M84의 아홉 태스크를 구현했다. 규약 "전제조건 · 프리플라이트" 절의 release 시작 전 검사를 이름 선언 `release-preflights:`(pf-verdict pf-tests pf-worktree pf-site-scan pf-coverage)와 이름별 정의 항목으로 올렸다(T02).
release 스킬의 프리플라이트 단계 머리 · 재서술처 · 소개 문서가 번호 대신 이름이나 선언 포인터로 가리킨다(T03 · T04). 두 러너 Part S에 선언 정합 · 덮음 · 차례 · 잔재 판정과 창 안 · 앞 · 뒤 통제를 더했고(T05), 창 통제를 규약 체크리스트 7번째 항목으로 적었다(T06).
작은 정리 다섯도 닫았다(T07 · T08). 태스크가 같은 러너 · 규약 파일을 고치는 사슬이라 메인이 순차로 구현했다.
첫 실행(2026-10-29)은 사용자 요청으로 시간을 줄였고, 이어하기(2026-10-30 · 리뷰 전이라 라운드는 그대로)에서 남긴 것을 채웠다 — 판정 쪽 되돌림 다섯 행 · `F22` 단독 행 · 생명주기 상태표 · 하니스 여섯의 5.1 측정.

재작업 라운드 1(2026-10-30)은 리뷰 라운드 0의 차단 1을 닫았다 — 프리플라이트 창의 끝 앵커가 있는지를 아무것도 묻지 않아, 스킬 끝 줄 문구나 러너 앵커 상수를 바꾸면 창이 파일 끝까지 넓어지고 창 뒤 통제 `S62`가 아무것도 심지 못한 채 초록이었다. 두 러너 Part S에 앵커 판정 `S68`과 통제 `S69` · `S70`을 더했다.

재작업 라운드(rework): 1

## 태스크별 수행 내용

- **M84-T01** — 지울 번호 문장을 읽던 판정을 먼저 쟀다(`rf-98`). 작업 트리를 `.git` 없이 사본(`t01m84base`)으로 뜨고, 번호 참조를 파일 무리마다 한꺼번에 바꾼 사본에서 하니스를 돌렸다(드라이버 `t01m84.ps1`). 앵커 수는 무리마다 단언했다.

  | 사본 | 바꾼 것(편집 수) | 붉은 케이스(기준선 대비) |
  |---|---|---|
  | base | — | 기준선: pwsh 전수 652/2(`T3` — `.git` 없음 · `U6` — 보고서 없음) |
  | conv | `docs/conventions.md`의 표 행 · 「release 1번 검사」 · 「①②③ 게이트」 · 「게이트 ①」 · 「3게이트」 둘 · 「프리플라이트 1/1b/2」(12) | 없음 |
  | convrel | `docs/conventions-release.md`의 「프리플라이트 3」 · 「게이트 ①②③」 · 「프리플라이트 2/4」(4) | 없음 |
  | skill | release 스킬 단계 머리 번호 셋과 본문의 번호 참조(14) | 없음 |
  | cycle | 「프리플라이트 1~5」(1) | 없음 |
  | commands | 「③ 워킹트리 확인」(1) | 없음 |
  | intro | README · 시작하기 · 개념 페이지 서술(3) | 없음 |
  | ctx | `docs/project-context.md` · E2 · E4의 번호(4 중 3 — 「프리플라이트 3게이트」가 원장에도 있어 앵커 수 2로 빠짐) | 없음 |
  | all | 위 전부(39 — 위 한 건 빠짐) | 없음 — pwsh 전수 652/2 · **sh 전수 652/2**(둘 다 `T3` `U6`) |

  - 결과: 지운 번호 문장을 묻던 판정은 없다. 대신 세울 케이스가 없다. sh는 합친 사본 한 행만 전수로 돌렸다(약 25분) — 행마다 sh 전수는 돌리지 않았다(편차).
- **M84-T02** — `docs/conventions.md` "전제조건 · 프리플라이트" 절.
  - 표 release 행을 선언 포인터로 바꾸고, 표 아래에 선언 한 줄과 정의 항목 다섯을 두었다. 정의는 무엇을 묻는가 + 처분(막음 · 확인 · advisory) + 상세 단일 원본 절 포인터다. 「선언의 이름 순서가 스킬이 프리플라이트를 도는 순서」를 적었다.
  - 같은 파일의 번호 참조 열한 곳과 `docs/conventions-release.md` 네 곳을 이름 · 포인터로 바꿨다. 「게이트 ①②③의 집합·순서·판정 로직은 불변」은 마무리 경로의 확인이 **새 프리플라이트가 아니라는** 문맥이라 다섯 전부의 집합으로 보고 「`release-preflights:`가 든 프리플라이트의 집합·순서·처분」으로 적었다. 「프리플라이트 ①②③ 게이트와 별개의 advisory」는 막는 것만 가리키므로 「막는 프리플라이트와 별개 — `pf-coverage`」로 적었다.
  - 「기계가 묻는 것(M84)」 · 「묻지 않는 것」 문단을 두었다(아래 고지 대응표).
  - **재서술처 훑기** — 패턴 `프리플라이트 ?(게이트 )?[①②③④⑤]|프리플라이트 [1-5]|① (review |판정)|② 테스트|③ (워킹트리|사이트)` · 대상 저장소의 `*.md` · `*.sh` · `*.ps1` · `*.yml` · `*.json`(`docs/reports/` · `docs/milestones/` · `CHANGELOG.md` 제외) · 대조 항목 「release 프리플라이트를 번호로 가리키는 자리」 · 루트 저장소(pwsh `Select-String`).
    남긴 히트: `docs/conventions.md` 「① 판정이 읽는 입력」(생명주기 격자의 다른 열거) · `docs/project-context.md`의 이월 원장 두 줄(처분 기록 — 이력) · `tests/discover/run.sh`의 Part N 픽스처 문자열 셋(합성 입력 — 참조가 아니다).
- **M84-T03** — release 스킬 프리플라이트 창의 단계 머리 다섯을 `N. **`pf-…`** …` 꼴로 바꾸고, 창 머리 줄에 선언 포인터를 더했다. 본문의 번호 참조 아홉 곳을 이름으로 바꿨다. `skills/cycle/SKILL.md` 「프리플라이트 1~5」와 `docs/commands.md` 전제조건 줄은 선언 포인터로 바꿨다. 단계 수 · 순서 · 처분과 단계 본문의 동작 문장은 그대로다(문면 치환뿐).
- **M84-T04** — `README.md` · `site/docs/getting-started.md` · `site/docs/concepts.md`의 서술을 막는 셋(판정 · 테스트 · 사이트 산출물 스캔)과 막지 않는 둘(워킹트리 확인 · 커버리지)로 맞췄다. 원문자 번호와 수 낱말을 쓰지 않고 메일 어투로 적었다.
- **M84-T05** — 두 러너 Part S `S48`~`S66`.
  - 창: 스킬에서 「프리플라이트 (」로 시작하는 줄 다음부터 「프리플라이트 통과 후」로 시작하는 줄 앞까지(`pf_sec` · `PfSec`). 그 안 번호 단계 머리의 첫 굵은 구획만 센다(M83 `dcn_heads` · `DcnHeads` 재사용).
  - 본 검사: 선언 줄 `S48` · 금지 구분자 `S49` · 추출 `S50` · 유일 `S51` · 정의 `S52` · 고아 `S53` · 정의 순서 `S54` · 덮음 `S55`(대칭차) · 차례 `S56` · 잔재 `S57`. 통제: `S58`~`S66`(정의 범위 · 이름 추가 · 창 앞 · 안 · 뒤 · 산문 · 굵은 구획 뒤 · 맞바꾼 차례 · 토큰 추출).
  - **차례 판정을 덮음과 떼었다** — 처음에는 두 집합의 차례를 통째로 견줘 집합이 다르면 `S56`도 늘 붉었다(그러면 `S55`가 단독 행을 갖지 못한다). 양쪽에 다 있는 이름끼리의 차례만 견주게 고쳤다.
  - 구현 중 두 결함을 잡았다: ps1 매개변수 `$conv`가 대소문자를 가리지 않는 스크립트 변수 `$CONV`를 가렸고(`S55` 등 붉음), `OrdSet` 반환을 파이프에 바로 물려 집합 하나가 흘렀다(`S57`). 이름을 바꾸고 원소를 도는 꼴로 고쳤다.
- **M84-T06** — 규약 "새 검사를 세울 때 함께 붙일 것" 체크리스트에 7번째 항목(집합 판정의 창 안 · 앞 · 뒤 통제 · `rf-101`)을 더하고, 그 목록을 가리키는 수 낱말 넷(「여섯」 셋 · 「`1.`~`6.`」)을 같은 편집에서 고쳤다. Part S `S67`이 문서 커밋 절 다음 제목 뒤에 심은 단계 머리를 세지 않는지 묻는다.
- **M84-T07** — `rf-07`: `CLAUDE.md` 마커 항목을 「위 설명 주석과 옛 릴리즈 노트에도」로 고치고 판별법(마커 줄 + 아래 제목 앵커 · 앵커 수 1 단언)을 같은 항목에 적었다. 줄 수 40 그대로. `rf-40`: 「3분담이 2분담으로」 → 「분담 하나가 빠진 것을」. `rf-48`: `.tide/NEXT-SESSION.md`를 지웠다(이력 밖 참조 0 — 위 훑기와 같은 루트에서 `NEXT-SESSION` 검색).
- **M84-T08** — `rf-28`: Part F `F21`~`F23`(README 파트 제목 수 ↔ `cases:` 줄). **처음 돌리자 Part G 제목이 16으로 남아 있어(`cases:`는 18) 붉었다** — T09에서 고쳤다. `rf-44`: 규약 "판정 계측" 절에 `metrics-filled-since:` M58을 두고 Part P `P20`~`P23`이 계측 줄의 값을 묻는다. 수 자리 개수는 규약 고정 형식 줄의 `{n}` 수에서 읽는다(손 상수 없음). M58 미만은 부인 필드가 없는 옛 꼴이라 묻지 않는다(M32~M57 실측: 전부 옛 꼴, M58 이상 전부 새 꼴).
- **재작업 라운드 1 — 리뷰 차단 1(창 경계 앵커)** — `pf_anchor_bad` · `PfAnchorBad`가 릴리즈 스킬에서 시작 앵커(「프리플라이트 (」) 줄 수 · 끝 앵커(「프리플라이트 통과 후」) 줄 수 · 차례를 읽어 결함 수를 낸다(시작 ≠ 1 · 끝 ≠ 1 · 끝이 시작보다 앞마다 하나).
  본 검사 `S68`(0) · 통제 `S69`(끝 줄 머리에 `zz `를 붙인 사본 — 차이 1) · `S70`(끝 줄을 시작 줄 바로 앞으로 옮긴 사본 — 차이 1). 판정이 러너의 앵커 상수 그대로를 쓰므로, 상수를 바꾸는 러너 편집도 `S68`에서 붉다.
  규약 「기계가 묻는 것(M84)」에 앵커 판정을 더하고, 체크리스트 7번에 「창 경계를 정하는 앵커가 정확히 하나씩 있고 차례가 맞는지도 본 검사로 단언한다」를 같은 편집에서 더했다. 하니스 README의 `cases:`(681 → 684) · Part S 제목 · 소절 · 소계(20 → 23 · 합계 70)를 맞췄다.
- **M84-T09** — `tests/discover/README.md`의 `cases:`(654 → 681)와 파트별 수 · 제목(Part F · G · P · S), Part S · F · P 새 소절과 Part S 소계.

**고지 대응표**(완료 기준 5 — 규약 「기계가 묻는 것(M84)」)

| 고지의 판정 | 케이스 |
|---|---|
| 선언 줄 정확히 하나 · 금지 구분자 없음 | `S48` · `S49` |
| 창의 시작 · 끝 줄이 각각 정확히 하나이고 끝이 시작 뒤 | `S68` (통제 `S69` · `S70`) |
| 이름 추출이 비지 않는다 | `S50` |
| 이름 유일 | `S51` |
| 이름마다 정의 하나 · 고아 정의 없음 | `S52` · `S53` (통제 `S58`) |
| 정의 순서 = 선언 순서 | `S54` |
| 창 단계 머리의 이름 집합 = 선언 집합 | `S55` (통제 `S59` · `S61`) |
| 그 차례 = 선언 순서 | `S56` (통제 `S65`) |
| 창 안 산문 · 단계 본문 · 창 앞뒤 언급은 세지 않는다 | `S60` · `S62` · `S63` · `S64` |
| 네 자리의 pf- 토큰이 전부 선언된 이름 | `S57` (통제 `S66`) |

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | 선언 줄 하나(`S48`) · 정의 항목 정확히 하나(`S52` · `S53`). 번호 지칭 훑기는 T02 항목(패턴 · 대상 · 대조 항목 · 루트 · 남긴 히트의 사유) |
| 2 | 충족 | 창 단계 머리의 집합 · 차례가 선언과 같다(`S55` · `S56`). `git diff -U0 skills/release/SKILL.md`의 창 안 hunk는 단계 머리 다섯과 본문 번호 참조의 문면 치환뿐이다 — 단계 수 다섯 · 순서 · 처분 문장 그대로 |
| 3 | 충족 | T01 표 — 전 무리 「없음」(합친 사본은 두 러너 전수) |
| 4 | 충족 | 아래 되돌림 표 — ⑴ `pfs-name-drop` ⑵ `pfs-dup-solo` ⑶ `pfs-def-drop` ⑷ `pfs-def-extra` ⑸ `pfs-def-swap` ⑹ `pfs-add-end` ⑺ `skill-step-drop` ⑻ `skill-head-swap` · `skill-head-swap34` ⑼ `pfs-rename-leftover` ⑽ `pfs-decl-indent` ⑾ `pf-window-open-sh` · `pf-window-open-ps1`(끝 조건 지움) · `pf-anchor-const-sh` · `pf-anchor-const-ps1`(앵커 상수 바꿈 — 재작업 라운드 1) · `skill-end-reword` · `skill-end-before`(스킬 쪽 앵커 상실 — 라운드 1)(창 앞 · 뒤에 심은 머리는 실물 트리에서 `S60` · `S62`가 초록으로 지킨다) ⑿ `dc-window-open-sh` · `dc-window-open-ps1` ⒀ `readme-head` · `readme-head-b` ⒁ `metrics-blank`. 전부 두 러너에서 붉다(러너 한쪽만 깬 행은 그 러너에서). 판정 쪽 「항상 0」 행도 이어하기에서 쟀다 |
| 5 | 충족 | 위 고지 대응표 |
| 6 | 충족 | 아래 생명주기 상태표 — 사본 일곱(상태 목록 전부를 대표 사본으로 덮고 판정별 격자가 낸 `tr-review` · 미기입 리뷰 상태를 더함) · 세 실행 환경 |
| 7 | 충족 | `CLAUDE.md` 40줄(HEAD 40) · `.tide/NEXT-SESSION.md` 없음 · 이력 밖 참조 0 |
| 8 | 충족 | 아래 테스트 결과 — `tests/discover` 전수와 나머지 하니스 여섯을 두 PowerShell에서 쟀다. sh 전수는 `measure-axis:`대로 CI가 판정한다 |
| 9 | 충족 | `hooks/` 변경 0 · `skills/`는 release · cycle 스킬의 문면 치환뿐 |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M84-impl.md` |
| 수정 | `docs/conventions.md` · `docs/conventions-release.md` · `docs/commands.md` · `skills/release/SKILL.md` · `skills/cycle/SKILL.md` · `README.md` · `site/docs/getting-started.md` · `site/docs/concepts.md` · `CLAUDE.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` · `docs/epics/E2.md` · `docs/epics/E4.md` · `docs/project-context.md` |
| 삭제 | `.tide/NEXT-SESSION.md` |

`docs/milestones/M84.md`와 `docs/epics/E2.md`의 등재 한 줄은 `/tide:milestone`의 미커밋 산출물이다. `docs/reports/retro.md`와 `docs/project-context.md`의 원장 여섯 줄은 2026-10-29 장기 이월 정리의 미커밋 변경이다(이 마일스톤 변경이 아니다). `docs/epics/E4.md`는 마일스톤 표에 없던 번호 참조 두 곳을 같은 훑기로 고쳤다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (pwsh 7.6.9 · Windows PowerShell 5.1.26100 — 전수 / Git Bash `sh` — Part S · F · P) | pwsh **684/0** · 5.1 **684/0** · sh S 70/0 · sh F 33/0 · sh P 23/0 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — 규약 `measure-axis:`의 배당) | 릴리즈 단계에서 확인 |

- **마지막 측정**(이 보고서를 갱신한 뒤의 트리) — `pwsh` · `powershell` `tests/discover/run.ps1` → `# result: PASS=684 FAIL=0`(재작업 라운드 1 뒤) · 나머지 하니스 여섯(`multi-repo` 37 · `fleet` 45 · `fleet-cycle` 24 · `fleet-verify` 30 · `site-includes` 51 · `mutation` 12)은 pwsh 7과 5.1에서 FAIL 0 · Git Bash `run.sh S` → 70/0 · `F` → 33/0 · `P` → 23/0. 명령마다 하나씩 차례로 돌렸다(한 백그라운드 명령 안에서 순차 — 결과는 `final84r1.txt`). 이 값을 적은 뒤 보고서를 읽는 판정(pwsh 전수 · sh P)을 한 번 더 돌려 같은 값을 확인했다. (첫 실행의 마지막 측정에서는 이 보고서의 판정 값 「일부 충족」이 `criteria-verdict:` 밖이라 `P5`가 붉어 고쳤다.)
- **캐시가 아닌 실행임을 확인한 방법**(`measure-not-cached`) — 해석형 스크립트이고, 케이스 수 654 → 681 → 684가 결과 줄에 보였으며 보고서가 생기자 `U6`이 초록으로 바뀌었다.
- **구현 중 발견한 것** — ⑴ Part G 제목 수 어긋남(16 대 18)을 새 판정 `F22`가 처음 잡았다 ⑵ ps1 매개변수가 같은 이름의 스크립트 변수를 가림 ⑶ `OrdSet` 반환을 파이프에 물림 ⑷ 차례 판정이 덮음과 결합(위 T05) ⑸ T01 드라이버의 해시 리터럴 문법 오류.
**생명주기 상태표**(`lifecycle-state-table`) — 기계 판정을 새로 세웠으므로 단다(이어하기에서 쟀다).

- **판정이 읽는 입력**: 규약 문서 집합 · release 스킬 · cycle 스킬 · 커맨드 카탈로그(`S48`~`S70`) · `tests/discover/README.md`(`F21`~`F23`) · `metrics-filled-since:` 이상의 리뷰 보고서와 규약 고정 형식 줄(`P20`~`P23`).
- **그 입력을 바꾸는 전이**(판정별 격자 ②): `tr-review`(새 리뷰 보고서 — `P22`) · `tr-impl`(하니스 사이클이면 README의 `cases:`와 제목을 함께 바꾼다 — 같은 편집의 규율이고 상태가 아니라 편집이라 사본으로 두지 않았다) · `tr-downstream`(⒅). 나머지는 이 판정들에 항등이다.
- **사본 일곱**(`st84.ps1`) — 작업 트리를 `.git` 없이 복사해 상태를 만들고 Part S · F · P를 pwsh 7 · 5.1 · sh로 돌렸다. 상태를 만드는 치환은 앵커가 없으면 멈춘다.

| 상태 | 사본(만든 방법) | 기대 | 실제(pwsh · 5.1 · sh — S · F · P — 라운드 0 측정) |
|---|---|---|---|
| ⑴ 사이클 중 · ⒇ 판정 `불가`인 채 · `st-fail-then-draft`의 앞 | A — 현재 트리 | 초록 | 67/0 · 33/0 · 23/0 (세 환경 같음) |
| ⑶ 릴리즈 커밋 · ⑷ 태그 뒤 · ⑼ ⑽ ⑾ ⒂ ⒃ ⒄(CHANGELOG · 버전 파일만 다름) | B — `plugin.json` 2.48.0 · CHANGELOG v2.48.0 머리 · M84 표지 | 초록 | 세 환경 67/0 · 33/0 · 23/0 |
| ⑸ 태그 뒤 후처리 후 · ⒀ ⒁ | C — B + 회고 제목 v2.48.0 | 초록 | 같음 |
| ⑹ ⑺ ⑻ · `st-fail-then-draft` | D — `docs/milestones/M85.md` 초안 | 초록 | 같음 |
| ⒆ debug 세션이 열린 채 | E — `.tide/debug-session` · 판정 없는 `debug-3.md` | 초록 | 같음 |
| ⑵ 리뷰 뒤(`tr-review`) | F — 계측 줄이 채워진 리뷰 보고서 `M84-review.md` | 초록 | 같음 |
| 리뷰 보고서가 템플릿 그대로(격자가 낸 목록 밖 상태 — 정상 상태가 아니다) | G — 리뷰 템플릿을 `M84-review.md`로 | `P22` 붉음(의도) | 세 환경 S 67/0 · F 33/0 · P 21/2(`P22` · `P23`) |
| ⑿ 파트 선택 실행 | 사본 전부가 `-Part` · `run.sh <파트>`로 돌았다 | 전수와 같은 답 | 실제 트리 전수의 S · F · P도 0 붉음 |
| ⒅ 대상 레포에서 처음 도는 릴리즈 | 문면 — 판정은 하니스에만 있고 하니스는 대상 레포에서 돌지 않는다. 대상 레포에서 프리플라이트는 release 스킬 단계 본문(운영 문장 그대로)으로 돈다. `metrics-filled-since:`는 이 저장소 보고서의 꼴을 가르는 값이라 대상 레포로 새지 않는다(스킬은 그 선언을 읽지 않는다) | — | — |

- **라운드 1의 앵커 판정(`S68`~`S70`)** — 읽는 입력은 릴리즈 스킬 하나이고, 위 사본 일곱은 스킬을 바꾸지 않으므로 이 판정에는 항등 전이다. 스킬을 바꾸는 전이는 `tr-impl`(스킬 편집)뿐이고 그것은 상태가 아니라 편집이라 되돌림 행 `skill-end-reword` · `skill-end-before`가 문다. 실물 트리(상태 A)에서 세 환경 모두 초록이다(아래 마지막 측정).
- G의 `P23`은 통제의 기준선 문제다 — 통제가 가장 큰 번호 보고서(G에서는 템플릿 그대로인 `M84-review.md`)의 사본을 쓰므로 실물 쪽이 이미 붉어 차이가 0이 된다(규약 체크리스트 6번의 「다른 케이스가 이미 붉은 동안」 경우). 정상 상태(F)에서는 초록이다.

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: S51 S52 S53 S54 S55 S57 F22 P22 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| pfs-name-drop | 선언에서 `pf-worktree`를 지움 | adversarial | S53 · S55 · S57 | ps1 전수 676/5 · sh S 64/3 |
| pfs-dup-solo | 선언 끝에 `pf-coverage`를 한 번 더 붙이고 창에 같은 이름의 단계 머리를 더함 | adversarial | S51 | ps1 전수 678/3 · sh S 66/1 |
| pfs-def-drop | `pf-tests` 정의 머리를 백틱 없는 굵은 글로 | adversarial | S52 | ps1 전수 678/3 · sh S 66/1 |
| pfs-def-extra | 선언에 없는 정의 항목 `zz-extra`를 더함 | adversarial | S53 | ps1 전수 678/3 · sh S 66/1 |
| pfs-def-swap | 정의 첫 둘의 이름을 맞바꿈 | adversarial | S54 | ps1 전수 678/3 · sh S 66/1 |
| pfs-add-end | 선언 끝 · 정의 끝에 `pf-extra`를 더하고 스킬은 그대로 | adversarial | S55 | ps1 전수 678/3 · sh S 66/1 |
| skill-step-drop | 1단계 머리에서 `pf-verdict`를 빼고 창 안 본문의 언급은 남김 | adversarial | S55 · S65 | ps1 전수 677/4 · sh S 65/2 |
| skill-head-swap | 1 · 2단계 머리의 이름을 맞바꿈 | adversarial | S56 · S65 | ps1 전수 677/4 · sh S 65/2 |
| skill-head-swap34 | 3 · 4단계 머리의 이름을 맞바꿈 | adversarial | S56 · S65 | ps1 전수 677/4 · sh S 65/2 |
| pfs-rename-leftover | 선언 · 정의의 `pf-worktree`만 `pf-wt`로 바꾸고 스킬의 옛 이름을 남김 | adversarial | S55 · S57 | ps1 전수 677/4 · sh S 65/2 |
| pfs-decl-indent | 선언 줄을 두 칸 더 들여씀 | adversarial | S52 · S58 | ps1 전수 677/4 · sh S 65/2 |
| pf-stray-only | 카탈로그에 선언에 없는 백틱 `pf-old-name`을 더함 | adversarial | S57 | ps1 전수 678/3 · sh S 66/1 |
| readme-head | README Part A 제목 수를 7 → 8 | adversarial | F22 · F23 | ps1 F 31/2 · sh F 31/2 |
| metrics-blank | `docs/reports/M70-review.md` 계측 줄의 rework 값을 비움 | adversarial | P22 | ps1 P 22/1 · sh P 22/1 |
| pf-window-open-sh | `run.sh` 프리플라이트 창의 끝 조건을 지움 | broken | S62 | sh S 66/1(ps1은 깨지 않음 — S 67/0) |
| pf-window-open-ps1 | `run.ps1` 프리플라이트 창의 끝 조건을 지움 | broken | S62 | ps1 S 66/1 |
| dc-window-open-sh | `run.sh` 문서 커밋 절 창이 다음 제목에서 닫히지 않게 | broken | S15 · S67 | sh S 65/2(ps1은 깨지 않음 — S 67/0) |
| dc-window-open-ps1 | `run.ps1` 같은 편집 | broken | S15 · S67 | ps1 S 65/2 |

| readme-head-b | README Part B 제목 수를 14 → 15(첫 제목이 아니라 통제 픽스처와 떨어짐) | adversarial | F22 | ps1 F 32/1 · sh F 32/1 |
| pf-cover-zero-sh | `run.sh`의 `pf_cover_bad` 합산을 「항상 0」으로 | broken | S59 · S61 | sh S 65/2(ps1은 깨지 않음 — S 67/0) |
| pf-cover-zero-ps1 | `run.ps1`의 `PfCoverBad` 반환을 「항상 0」으로 | broken | S59 · S61 | ps1 S 65/2 |
| pf-order-zero-both | 두 러너의 차례 판정을 함께 「항상 0」으로 | broken | S65 | ps1 S 66/1 · sh S 66/1 |
| pf-stray-zero-both | 두 러너의 잔재 판정을 함께 「항상 0」으로 | broken | S66 | ps1 S 66/1 · sh S 66/1 |
| part-head-zero-both | 두 러너의 README 제목 수 판정을 함께 「항상 0」으로 | broken | F23 | ps1 F 32/1 · sh F 32/1 |
| meas-zero-both | 두 러너의 계측 줄 판정을 함께 「항상 0」으로 | broken | P23 | ps1 P 22/1 · sh P 22/1 |
| skill-end-reword | 스킬 끝 줄 머리를 「프리플라이트를 모두 통과하면」으로 바꿈(라운드 1) | adversarial | S68 · S69 · S70 | ps1 S 67/3 · sh S 67/3 |
| skill-end-before | 스킬 끝 줄을 시작 줄 바로 앞으로 옮김(라운드 1) | adversarial | S68 · S69 · S70 | ps1 S 67/3 · sh S 67/3 |
| pf-anchor-const-sh | `run.sh`의 끝 앵커 상수를 「…통과 뒤」로(라운드 1) | broken | S68 · S69 · S70 | sh S 67/3 |
| pf-anchor-const-ps1 | `run.ps1`의 끝 앵커 상수 끝 코드포인트를 0xD6C4 → 0xB4A4로(라운드 1) | broken | S68 · S69 · S70 | ps1 S 67/3 |
| pf-anchor-zero-both | 두 러너의 앵커 판정을 함께 「항상 0」으로(라운드 1) | broken | S69 · S70 | ps1 S 68/2 · sh S 68/2 |

<!-- reversal-table:end -->

- **기준선** — 이 보고서를 쓰기 전 트리의 사본(`rev84base`)에서 ps1 전수 **679/2**(`T3` · `U6`) · sh S **67/0**. 표의 「붉은 케이스」는 기준선 밖만 적는다. 드라이버 `rev84.ps1` · 결과 `rev84.txt`. 앵커 수 · 편집 원소 수를 단언했다(`ANCHOR-MISS` 0). 첫 실행 마지막 여섯 행과 이어하기의 여덟 행은 pwsh도 해당 파트만 돌렸고(행마다 전수 대신), 이어하기는 갱신된 트리에서 사본을 새로 떴다(기준선 S 67/0 두 러너).
- **본 검사 단독 행** — `S51` `pfs-dup-solo` · `S52` `pfs-def-drop` · `S53` `pfs-def-extra` · `S54` `pfs-def-swap` · `S55` `pfs-add-end` · `S57` `pf-stray-only` · `F22` `readme-head-b` · `P22` `metrics-blank`.
  - **라운드 1의 기준선과 드라이버** — 라운드 1 편집 뒤 트리를 `.git` 없이 행마다 새로 복사했다(`r1-*`). 기준선 sh S **70/0** · ps1 S **70/0**. 드라이버 `rev84r1.sh` · `rev84r1.py`(앵커 수 1 단언 — `ANCHOR-OK` 다섯) · 결과 `rev84r1.txt`. 라운드 1 행은 두 러너 모두 Part S만 돌렸다(행마다 전수 대신).
- **`S68`은 목록에서 뺐다** — 앵커를 잃는 편집은 통제 `S69` · `S70`도 함께 붉힌다. 두 통제는 사본과 실물의 **차이**를 묻는데, 실물이 이미 앵커를 잃었으면 실물 쪽 값이 1이라 차이가 0이 된다(규약 체크리스트 6번 「다른 케이스가 이미 붉은 동안」의 경우 — `S56`과 같은 결합). 스킬 쪽 두 길과 러너 상수 쪽 두 길로 쟀고 넷 다 같았다.
- **`S56`은 목록에서 뺐다** — 단계 머리 차례를 흔드는 행은 차례 통제 `S65`도 함께 붉힌다. `S65`는 첫 두 이름을 맞바꾼 사본과 실물의 **차이**를 묻는데, 실물의 차례가 이미 어긋나 있으면 실물 쪽 값이 1이라 차이가 0이 된다(규약 체크리스트 6번 「다른 케이스가 이미 붉은 동안 그 통제가 아무것도 못 재는 것은 결함이 아니다」의 경우). 셋째 · 넷째를 맞바꾼 행(`skill-head-swap34`)으로도 같았다 — 차례 판정이 0/1 값이라 어느 쌍을 흔들어도 같다.

## 미해결·후속 메모

1. **`S56` · `S68` 단독 불가의 경계** — 위 되돌림 절. 차례 판정을 값(어긋난 쌍 수)으로 바꾸면 통제 `S65`와 떼어 낼 수 있다.
2. **`P23`의 기준선 의존** — 가장 큰 번호 리뷰 보고서가 비어 있는 상태(G)에서는 통제가 함께 붉는다. 정상 흐름에서는 그 상태가 리뷰 작성 중의 잠깐뿐이다.
3. **T01의 sh 전수는 합친 사본 한 행만** — 무리마다 sh 전수는 돌리지 않았다(편차 · 약 25분).
4. **`rf-100`의 나머지** — 도입 번호 파생 ⑴~⑶ · 고지 절 · Part W `sp_*`의 `dn_*` 흡수는 산문이다.
