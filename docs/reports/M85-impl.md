# M85 완료보고서 (impl)

## 개요

M85의 아홉 태스크를 구현했다. 첫 태스크로 회고 후속 표의 장기 행 열세 건을 2026-10-30 사용자 결정대로 처분하고 이월 원장에 그룹 줄 셋을 썼다 — 열린 행이 27 → 14가 됐다(T01).
규약 "회고 후속 항목의 소비" 절에 표에 들어오고 나가는 길을 이름 선언 `retro-flow:`(rt-issue-gate rt-observations rt-cleanup-slot rt-ledger-group rt-review-mark) · 자리 선언 `retro-flow-sites:` · 값 선언 `retro-gate-since:` · `retro-review-after:`와 이름별 정의 항목으로 세웠고(T02), retro · milestone 스킬과 템플릿이 이름과 절 포인터로 따른다(T03 · T04).
작은 정리 셋(`rf-99` status의 재작업 라운드 대조 · `rf-94` release 운영 주의의 README 전제 · `rf-90` 새 케이스 없는 사이클의 되돌림 목록)을 닫았고(T05~T07), 두 러너 Part O에 `O88`~`O99`를 더했다(T08 · T09).
첫 실행(2026-10-30)은 구현까지 마친 뒤 사용자 지시로 실측 도중 멈췄고, 이어하기(2026-11-02 · 리뷰 전이라 라운드는 그대로)에서 되돌림 · 상태표 · 보고서 · 마지막 측정을 처음부터 다시 했다. 이어하기를 시작하며 열다섯 파일의 `git diff`를 줄 단위로 읽어 잰 예가 실파일에 남은 잔재가 없음을 확인했다.
이어하기의 되돌림이 sh 사본의 결함 하나를 찾았다 — 재심 기준 선언 줄을 지우면 ps1은 `O94`가 붉는데 sh는 초록이었다(아래 테스트 결과). 같은 편집에서 고치고 그 입력 변환의 통제를 `O95`에 더했다.
태스크가 같은 규약 · 러너 파일을 고치는 사슬이라 첫 실행에서 T03 · T04 · T06만 서브에이전트로 내렸고 나머지는 메인이 순차로 구현했다.

재작업 라운드(rework): 0

## 태스크별 수행 내용

- **M85-T01** — 최상단 회고 표에서 열세 행의 상태 열과 반영 위치 열만 고쳤다(항목 · 제안 출처 열 불변). 수용 넷(`rf-57` `rf-60` `rf-69` `rf-74`) · 대상 밖 둘(`rf-49` `rf-62` → 에픽 E3) · 병합 일곱(`rf-61` `rf-88` `rf-97` `rf-98` → `rf-104` · `rf-38` → `rf-103` · `rf-102` → `rf-81` · `rf-92` → `rf-93`). 받는 행 넷의 반영 위치 꼬리에 「(2026-10-30 병합으로 받음: …)」을 더했다. `docs/project-context.md` 이월 원장에 그룹 줄 셋(수용 · 대상 밖 · 병합)을 2026-10-29 선례와 같은 열 구성으로 더했다. **이 편집은 회고가 아니라 impl이 했다** — 근거는 2026-10-30 사용자 결정(마일스톤 배경)이고, 규약의 「그 편집은 그 사이클의 impl 보고서가 받는다」대로 두 파일을 아래 변경 파일 요약에 올린다. 행은 지우지 않았다. 처분 뒤 열린 행(미반영 + 미결) **14**(`rf-15` `rf-77` `rf-80` `rf-81` `rf-82` `rf-84` `rf-89` `rf-90` `rf-93` `rf-94` `rf-95` `rf-99` `rf-103` `rf-104`).
- **M85-T02** — 규약 "회고 후속 항목의 소비" 절에 「표에 들어오고 나가는 길」 항목을 세웠다: 선언 넷 · 이름별 정의 항목 다섯(발급 관문 ⒝ · 관측 지표 줄 ⒞ · 청소 슬롯 ⒟ · 그룹 원장 줄 ⒡ · 재심 표지 ⒜) · 시간 기반 게이트 금지와의 관계 · 자리 이름(`retro` · `milestone`)이 가리키는 두 파일 · 「기계가 묻는 것 / 묻지 않는 것」. 이름은 마일스톤 예시(`retro-issue-gate` 등) 대신 `rt-` 접두로 정했다 — 이 절의 다른 선언(`ro-` 갈래 이름)과 같은 꼴이고, 잔재 판정(`O92`)이 접두로 토큰을 모은다. 표지는 ASCII(`next:` · `kin:` · `review-due`)이고 적용 시작 키는 `rf-105`(이 사이클 뒤 첫 발급 키), 재심 기준은 5 회고다. 절 끝 「기계가 묻지 않는 것(정직 고지)」의 ⑶에 `kin:`은 확인했다는 기록이지 보증이 아니라는 단서를 더했다.
- **M85-T03** — `skills/retro/SKILL.md` 「행 키 발급」 절차 1에 발급 관문을, 절차 뒤에 관측 지표 · 재심 표지 항목을, 원장 문단에 그룹 줄 허용을 더했고, 폴백 섹션 목록에 「관측 지표」를 넣었다(6 → 7). `skills/retro/template.md`에 「관측 지표」 절과 후속 표 안내문(발급 관문 · 재심 표지 · 그룹 원장)을 더했다. 값(`rf-105` · 5)은 적지 않고 선언 이름으로 가리킨다.
- **M85-T04** — `skills/milestone/SKILL.md` 「회고 후속 항목(advisory)」 뒤에 청소 슬롯 항목을 더했고, `skills/milestone/template.md`의 `- retro-rows:` 안내문에 「청소 슬롯으로 곁들인 행도 이 줄에 함께 적는다」를 더했다(새 메타데이터 줄 없음).
- **M85-T05** — `skills/status/SKILL.md`의 판정 `불가` 갈래를 둘로 갈랐다 — impl 보고서 개요의 재작업 라운드가 리뷰 보고서 계측 줄의 값보다 크면 `/tide:review M{N}`, 아니면 종전대로. 값이 없으면 0(규약 "리뷰 검증 규율" 절 포인터). 재서술처인 규약 fleet 분류(`보완 필요`) 한 줄을 같은 편집에서 맞췄다. **cycle과의 관계**: `skills/cycle/SKILL.md`의 인자 없는 시작점은 판정 `불가`면 라운드를 보지 않고 **impl 단계부터**다(규약 `start-point-map:`이 그 줄을 고정한다) — **다른 판단이다.** 마일스톤대로 이번에는 status만 고쳤고 cycle은 후속으로 남긴다(아래 후속 1). cycle 문면의 「`/tide:status`는 `불가`에 재실행과 후속 계획을 둘 다 허용」은 status의 「아니면」 갈래로 여전히 참이다.
- **M85-T06** — 운영 주의 3의 「CHANGELOG/README 릴리즈 노트」를 「CHANGELOG 릴리즈 노트」로, 「이 문서들은」을 「이 문서는」으로 고쳤다. 운영 주의 5는 「CHANGELOG 발췌」 · 「3번과 동일 규약」만 들어 따라올 것이 없다.
- **M85-T07** — 규약 "되돌림 표의 선언 형식" 절에 「새 본 검사가 없는 사이클의 목록」 항목을 더했다 — 고친 파일을 실제로 읽는 기존 본 검사로 목록을 채우고 보고서가 그 사실을 한 줄 적는다. 면제 선언은 두지 않았다. **Part V가 그 꼴을 받는지**: 판정은 목록 이름이 이번에 새로 세운 것인지 묻지 않는다 — 그 꼴로 쓴 `M80-impl.md`(`B1` `C3` `C4` `F2`) · `M81-impl.md`(`B1` `F2`)가 트리에 있고 Part V가 이 트리에서 33/0이다(아래 마지막 측정). 그래서 규약 문장만 고쳤다.
- **M85-T08** — 두 러너 Part O에 본 검사 여섯(`O88` 선언 정합 · `O90` 재서술처 · `O92` 이름 잔재 · `O94` 값의 꼴 · `O96` 발급 관문 꼴 · `O98` 재심 표지 꼴)과 그 통제 여섯(홀수)을 더했다. 선언 정합은 공용 헬퍼 `dn_*` · `Dn*`를 재사용했고, 수는 손 상수가 아니라 선언 집합에서 읽는다. 발급 관문 판정은 **기존 `retro-followups` 마커 창**을 쓴다 — 새 창을 세우지 않았으므로 앵커 「있다 · 하나다」는 기존 `O12`가 이미 문다(규약 체크리스트 7번). 키 번호는 숫자로 견주고, 통제 `O97`의 below(시작 키보다 작지만 문자열로는 뒤 — 짧은 9 꼴) 꼴이 문자열 비교로 바뀐 러너를 잡는다(리뷰 정정: wide는 숫자로도 문자열로도 시작 키 이상이라 비교의 종류를 가르지 않는다 — 큰 키가 세어지는지를 본다). 재심 표지는 꼴만 묻는다. **이어하기에서 고친 것**: sh `rt_values_bad`가 재심 기준 선언 줄이 없을 때(awk 입력 0줄 → 본문이 돌지 않아 `exit 0`) 「맞음」을 냈다. `END`에서 판정하게 고쳤고, 선언 줄을 지운 합성 규약(`noafter`)을 `O95`의 셋째 칸으로 두 러너에 더했다(케이스 수 불변).
- **M85-T09** — `tests/discover/README.md`의 `cases:` 한 줄 · Part O 제목 · 소절 · 소계를 실측에 맞췄다(수는 그 선언처가 든다). `docs/commands.md`의 milestone · retro 항목에 청소 슬롯 · 발급 관문 · 관측 지표 · 재심 표지를 이름과 절 포인터로 더했다. `docs/epics/E2.md` 등재 한 줄(마일스톤 생성 시)과 `docs/epics/E3.md` 「회고에서 넘어온 실측 과제」 소절(`rf-49` · `rf-62` — 에픽 문서가 축별 소절로 짜여 있어 소절 하나로 받았다)을 더했다. `docs/project-context.md`에는 회고 후속 소비를 재서술하는 개념 블록이 없다(패턴 `회고 후속 항목의 소비|retro-row-claimed|retro-status` · 대상 그 파일 · 히트 1 — M54 원장 행) — 원장 그룹 줄 셋(T01)만 더했다.

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | 대조 스크립트(`crit1.py` — 최상단 마커 창의 행을 `git show HEAD:docs/reports/retro.md`와 키로 맞춤): 열세 키 상태 전부 `처분` · 항목 · 제안 출처 열이 HEAD와 다른 행 0(전 104행) · 바뀐 행 17(열세 + 받는 넷) · 받는 넷의 꼬리 `(2026-10-30 병합으로 받음: …)` 각 하나 · 원장의 `2026-10-30 · M85 청소 슬롯` 줄 셋의 항목 셀에서 열세 키가 각각 정확히 1회(병합 줄은 처분 셀에도 같은 키를 다시 적는다 — 센 것은 항목 셀이다) · 그 밖의 키 0. 열린 행 HEAD 27 → **14** |
| 2 | 충족 | 선언 넷이 각 한 줄 · 이름 유일 · 정의 이름마다 하나 · 고아 없음 · 순서(`O88` = `1111\|0\|0\|0\|0`). 같은 항목의 「시간 기반 게이트 금지와의 관계」 문단이 ⒜ · ⒟를 보이게 하는 장치로 적고 「시간 기반 게이트를 두지 않는다」가 그대로임을 적는다 |
| 3 | 충족 | 재서술처 네 파일의 hunk(`git diff -- skills/retro skills/milestone`): retro SKILL 세 hunk(절차 1 · 관측 지표와 재심 표지 항목 · 원장 그룹 줄) · retro 템플릿 두 hunk(관측 지표 절 · 후속 표 안내문) · milestone SKILL 한 hunk(청소 슬롯) · milestone 템플릿 한 hunk(`retro-rows` 안내문). 모두 병기어 백틱 · 절 포인터를 들고(`O90` 초록), 선언 값(`rf-105` · 5)은 0회(패턴 `rf-105\|회고 5\|5 회고\|5회` · 대상 네 파일 + status 스킬 · 커맨드 카탈로그 · 히트 0). 절차를 한 줄로 부르는 구절(「같은 부류의 기존 행을 먼저 찾아」)은 있다 — 규칙의 기준(언제 · 몇 회고)은 선언 이름으로만 가리킨다. 재서술 여부의 판단은 리뷰의 자리다 |
| 4 | 충족 | 아래 되돌림 표 — ⑴ `decl-drop` ⑵ `name-dup` ⑶ `def-drop` ⑷ `def-swap` ⑸ `site-token-drop` ⑹ `gate-nonext` ⑺ `gate-nokin` ⑻ `gate-strcmp-sh` · `gate-strcmp-ps1` ⑼ `since-badform` — 두 러너 각각 붉음(⑻은 고친 러너 쪽). ⑽ `below-open` 두 러너 초록. ⑹ ⑺은 실제 표에 시작 키 이상 행이 없어 「표지를 다 든 행에서 하나를 지움」 대신 「하나만 든 `rf-105` 행을 더함」으로 쟀다(같은 술어 입력) |
| 5 | 충족 | `skills/status/SKILL.md` 판정 `불가` 갈래 — 「impl 보고서 개요의 `재작업 라운드(rework)` 값이 그 리뷰 보고서 계측 줄의 값보다 크면 → … /tide:review M{N}」. M82 꼴(리뷰 0 · 불가, impl 1)은 1 > 0이라 review로 간다. cycle 시작점과의 관계는 T05 항목(다른 판단 · 후속 1) |
| 6 | 충족 | 운영 주의에서 README를 노트의 자리로 적는 문장 0(`grep -n README skills/release/SKILL.md` → 112행 「`README.md`는 …」 포인터 문장 하나 — 3단계, 노트가 없다는 쪽). 그 문장을 읽던 케이스: 두 러너에 `CHANGELOG/README` 리터럴 0(패턴 `CHANGELOG/README` · 대상 `tests/*/run.*`). 옛 문장의 HEAD 트리(v2.48.0 릴리즈 · CI 전수 초록)와 새 문장의 이 트리(아래 마지막 측정)가 모두 초록이라 이 문장에 결과가 걸린 케이스가 없다. 첫 실행의 서브에이전트도 바꾼 사본에서 pwsh 전수로 깨지는 케이스 0을 보고했다 |
| 7 | 충족 | 규약 항목은 T07. Part V 실측: 그 꼴의 `M80-impl.md` · `M81-impl.md`가 있는 이 트리에서 Part V 33/0(마지막 측정) — 판정은 목록 이름의 새로움을 묻지 않는다 |
| 8 | 충족 | 아래 생명주기 상태표 — 상태 목록 ⑴~⒇ · `st-fail-then-draft` 전부를 행으로 두었고, 발급 관문 판정의 입력을 바꾸는 `tr-retro`를 새 섹션 · 새 행 · 행 이동으로(C · C2), 처분 · 병합 편집을 별도 사본으로(C3 · 그리고 T01 자체가 처분 · 병합 편집이다 — 상태 A) 먹였다 |
| 9 | 충족 | 아래 테스트 결과의 마지막 측정(이 보고서를 쓴 뒤) — 두 PowerShell의 `tests/discover` 전수 FAIL 0 · 다른 하니스 여섯 FAIL 0(pwsh 7 · 5.1). 수는 `tests/discover/README.md`의 `cases:` 선언처가 든다. sh 전수는 `measure-axis:`대로 CI가 판정한다 |
| 10 | 충족 | `git diff --stat -- hooks/` 0줄. `git diff --name-only -- skills/` = milestone(SKILL · template) · release(SKILL) · retro(SKILL · template) · status(SKILL) 여섯 파일. 커맨드 수 12(`# result` 줄의 `N=12`) · phase 계약 · 가드 · 판정 표기(`가능`/`불가`) 불변 |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M85-impl.md` |
| 수정 | `docs/reports/retro.md`(최상단 후속 표의 상태 · 반영 위치 열 — T01) · `docs/project-context.md`(이월 원장 그룹 줄 셋 — T01) · `docs/conventions.md` · `skills/retro/SKILL.md` · `skills/retro/template.md` · `skills/milestone/SKILL.md` · `skills/milestone/template.md` · `skills/status/SKILL.md` · `skills/release/SKILL.md` · `docs/commands.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` · `docs/epics/E2.md` · `docs/epics/E3.md` |
| 삭제 | 없음 |

`docs/milestones/M85.md`는 직전 milestone 단계의 미커밋 산출물이라 git 기준으로는 신규 파일이다(이 단계가 만들지 않았다).

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (pwsh 7.6.9 · Windows PowerShell 5.1.26100 — 전수 / Git Bash `sh` — Part O · P · V · U) | pwsh **699/0** · 5.1 **699/0** · sh O 99/0 · sh P 23/0 · sh V 33/0 · sh U 7/0 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — 규약 `measure-axis:`의 배당) | 릴리즈 단계에서 확인 |

- **마지막 측정**(이 보고서를 쓴 뒤의 트리) — `pwsh` · `powershell` `tests/discover/run.ps1` → `# result: PASS=699 FAIL=0` · 나머지 하니스 여섯(`multi-repo` 37 · `fleet` 45 · `fleet-cycle` 24 · `fleet-verify` 30 · `site-includes` 51 · `mutation` 12)은 pwsh 7과 5.1에서 FAIL 0 · Git Bash `run.sh O` → 99/0 · `P` → 23/0 · `V` → 33/0 · `U` → 7/0. 한 백그라운드 명령 안에서 하나씩 차례로 돌렸다(드라이버 `final85.sh` · 결과 `final85.txt`). 그 뒤 이 절을 채웠으므로, 보고서를 읽는 판정(pwsh 전수 · sh P · V · U)을 한 번 더 돌려 같은 값을 확인했다. 수는 `tests/discover/README.md`의 `cases:` 선언처가 든다.
- **캐시가 아닌 실행임을 확인한 방법**(`measure-not-cached`) — 해석형 스크립트라 빌드 캐시가 없다. 보고서를 넣기 전 pwsh 전수가 `U6` 1 FAIL(698/1)이었고, 기준 9 자리표시자가 남은 동안은 `P5` 1 FAIL(698/1)이었다가 채운 뒤 699/0으로 바뀌었다 — 결과 줄이 이 보고서의 상태를 따라 움직였다.
- **이어하기에서 찾아 고친 것** — 되돌림 `decl-drop`에서 두 러너의 붉은 케이스가 갈렸다(ps1 `O88` · `O94`, sh `O88`만). sh `rt_values_bad`가 재심 기준 값을 `decl_tail | awk '{ exit !(…) }'`로 읽어, 선언 줄이 없으면 awk 본문이 한 번도 돌지 않고 `exit 0` — 「맞음」이 됐다. 판정을 `END`로 옮겼고, 선언 줄을 지운 합성 규약(`noafter`)을 통제 `O95`의 셋째 칸으로 두 러너에 더했다(`1|1|1` · 케이스 수 불변). 고친 뒤 Part O는 pwsh 99/0 · sh 99/0. 시작 키 쪽(`rt_since_num`)은 빈 출력이 곧 「틀림」이라 같은 결함이 없다.
- **구현 중 함정**(첫 실행) — status 스킬 한 줄에 `"불가"`와 규약 파일명 인용이 같이 있으면 `G1`이 `"불가"`를 인용으로 읽는다 · ps1 매개변수 `$root`가 스크립트 변수 `$ROOT`를 가린다(대소문자 무시) · ps1 `if` 식이 원소 하나인 배열을 풀어 `[long]$tok[0]`이 글자 코드가 된다 · rt- 잔재 추출은 자리 쌍의 `=` 앞만 본다.

**생명주기 상태표**(`lifecycle-state-table`) — 기계 판정을 새로 세웠으므로 단다.

- **판정이 읽는 입력**: 규약 문서 집합(`O88` `O90` `O92` `O94`) · retro · milestone 스킬과 템플릿(`O90` `O92`) · `docs/reports/retro.md` 최상단 마커 창(`O96` `O98`).
- **그 입력을 바꾸는 전이**(판정별 격자 ②): `tr-retro`(최상단에 새 섹션 · 새 행 발급 · 집은 행 이동 · 마커가 새 섹션으로 감) · 처분 · 병합 편집(회고 또는 이 사이클의 T01처럼 impl이 사용자 결정으로 — 전이 표에서는 `tr-retro`와 `tr-impl`에 걸친다) · `tr-impl`(규약 · 스킬 편집 — 상태가 아니라 편집이라 되돌림 행이 문다) · `tr-downstream`(⒅). `tr-draft` · `tr-review` · `tr-release-commit` · `tr-tag` · `tr-debug-*` · `tr-pr-*` · `tr-continuous-stop` · `tr-forced` · `tr-retro-skip`은 이 판정들의 입력을 바꾸지 않는다(항등) — 그래도 대표 사본으로 먹였다. **부류 일곱으로 얹은 결과가 하나로 묶인다**(리뷰 보충): 이 판정들은 마일스톤 문서 · 보고서를 읽지 않으므로 `tr-retro`를 미릴리즈 없음 · 하나(리뷰 전 · `가능` · `불가`) · 둘의 어느 부류에 얹어도 판정 입력이 같다(파생 규칙 4 ⓑ) — 칸은 C · C2 · C3 셋이다.
- **사본 여덟**(`st85.py`) — 작업 트리를 `.git` 없이 복사해 상태를 만들고 Part O를 pwsh 7 · Windows PowerShell 5.1 · Git Bash `sh`로 돌렸다. 상태를 만드는 치환은 앵커가 정확히 하나가 아니면 멈춘다. sh 사본 수정 **뒤**의 트리에서 쟀다.

| 상태 | 사본(만든 방법) | 기대 | 실제(Part O — pwsh · 5.1 · sh) |
|---|---|---|---|
| ⑴ 사이클 중 · ⒆의 앞 · T01의 처분 · 병합 편집이 얹힌 트리 | A — 현재 트리(`tr-draft` `tr-impl`) | 초록 | 99/0 · 99/0 · 99/0 |
| ⑶ 릴리즈 커밋 · ⑷ 태그 뒤 · ⑽ ⑾ ⒂ ⒃ ⒄(이 판정의 입력이 같다) | B — `plugin.json` 2.49.0 · CHANGELOG `[v2.49.0]` 머리 · M85 표지 `- released: v2.49.0`(`tr-release-commit` · `tr-tag`) | 초록 | 99/0 · 99/0 · 99/0 |
| ⑸ 태그 뒤 후처리 후 · ⑼ ⒀ ⒁(⑼는 ⑸ 위의 debug 릴리즈라 회고가 쌓인 트리다 — 리뷰 정정) | C — B + `tr-retro`: 최상단에 v2.49.0 섹션 · 마커를 새 섹션으로 옮김 · 집은 행 넷(`rf-90` `rf-94` `rf-99` `rf-103`)을 `반영`으로 · 표지를 다 든 새 행 `rf-105` | 초록 | 99/0 · 99/0 · 99/0 |
| `tr-retro`가 관문을 어긴 새 행을 낸 트리(격자가 낸 목록 밖 상태 — 정상 상태가 아니다) | C2 — C에서 `rf-105`의 `next:`를 뺌 | `O96` 붉음(의도) | 98/1(`O96`) · 98/1(`O96`) · 98/1(`O96`) |
| 처분 · 병합 편집 뒤(격자 — 시작 키 이상 행의 처분과 열린 옛 행의 재심 표지) | C3 — B + `tr-retro`, `rf-105`는 `처분`(표지 없음) · 열린 옛 행 `rf-15`에 `review-due` | 초록 | 99/0 · 99/0 · 99/0 |
| ⑹ ⑺ ⑻ · `st-fail-then-draft`(초안 쪽) | D — `docs/milestones/M86.md` 초안(`tr-draft`) | 초록 | 99/0 · 99/0 · 99/0 |
| ⒆ debug 세션이 열린 채 | E — `.tide/debug-session` · 판정 없는 `debug-3.md`(`tr-debug-open`) | 초록 | 99/0 · 99/0 · 99/0 |
| ⑵ 리뷰 뒤 · ⒇ 판정 `불가`인 채 · `st-fail-then-draft`(판정 쪽) | F — 판정 `불가`인 `M85-review.md`(`tr-review`) | 초록 | 99/0 · 99/0 · 99/0 |
| ⑿ 파트 선택 실행 | 사본 전부가 `-Part O` · `run.sh O`로 돌았다(`tr-part-select`) | 전수와 같은 답 | 실물 트리 전수의 Part O도 0 붉음(마지막 측정) |
| ⒅ 대상 레포에서 처음 도는 릴리즈 | 문면 — 판정은 이 저장소 하니스에만 있고 하니스는 대상 레포에서 돌지 않는다. 대상 레포에서 retro · milestone 스킬은 선언을 「대상 레포에 없으면 플러그인 설치본」 규칙으로 읽으므로 `retro-gate-since:` rf-105가 그 레포의 키 번호에 그대로 적용된다 — 그 레포의 최대 키가 105보다 작으면 관문 표지 요구가 아직 걸리지 않는 쪽으로 기운다(막지 않는 절차라 거짓 붉음은 없다). 후속 2 | — | — |

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: O88 O90 O92 O94 O96 O98 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| decl-drop | 규약에서 `retro-review-after:` 선언 줄을 지움(⑴) | adversarial | O88;O94 | ps1 전수 695/4 · sh O 97/2(sh 수정 뒤 재측정 — 수정 전 sh는 O88만 · 98/1) |
| name-dup | `retro-flow:` 끝에 `rt-issue-gate`를 한 번 더(⑵) | adversarial | O88;O89;O91 | ps1 전수 694/5 · sh O 96/3 |
| def-drop | `rt-ledger-group` 정의 머리를 백틱 없는 굵은 글로(⑶) | adversarial | O88 | ps1 전수 696/3 · sh O 98/1 |
| def-swap | 정의 첫 둘의 이름을 맞바꿈(⑷) | adversarial | O88 | ps1 전수 696/3 · sh O 98/1 |
| site-token-drop | `skills/milestone/template.md`에서 백틱 `rt-cleanup-slot`을 지움(⑸) | adversarial | O90 | ps1 전수 696/3 · sh O 98/1 |
| site-pair-drop | `retro-flow-sites:`에서 `rt-ledger-group=retro` 쌍을 지움 | adversarial | O90 | ps1 전수 696/3 · sh O 98/1 |
| rt-stray | retro 스킬에 선언에 없는 백틱 `rt-bogus`를 더함 | adversarial | O92 | ps1 전수 696/3 · sh O 98/1 |
| after-zero | 재심 기준 값을 5 → 0 | adversarial | O94 | ps1 전수 696/3 · sh O 98/1 |
| since-badform | 시작 키 값을 `rf-105` → `M85`(⑼) | adversarial | O94;O97 | ps1 전수 695/4 · sh O 97/2 |
| gate-nonext | 최상단 표에 `kin:`만 든 미반영 `rf-105` 행을 더함(⑹) | adversarial | O96 | ps1 전수 696/3 · sh O 98/1 |
| gate-nokin | 같은 자리에 `next:`만 든 행(⑺) | adversarial | O96 | ps1 전수 696/3 · sh O 98/1 |
| review-done | `반영` 행 `rf-100`의 반영 위치에 `review-due`를 더함 | adversarial | O98 | ps1 전수 696/3 · sh O 98/1 |
| below-open | 시작 키 미만 미반영 행 `rf-99`에 `next:`만 더함(⑽ — 문자열로는 `rf-105` 뒤) | adversarial | 없음 | ps1 전수 697/2 · sh O 99/0(초록 — 기대) |
| gate-strcmp-sh | `run.sh` 관문의 키 비교를 문자열 비교로(⑻) | broken | O96;O97 | sh O 97/2(ps1은 깨지 않음 — 전수 697/2) |
| gate-strcmp-ps1 | `run.ps1` 관문의 키 비교를 `-clt` 문자열 비교로(⑻) | broken | O96;O97 | ps1 전수 695/4(sh는 깨지 않음 — O 99/0) |
| gate-zero-both | 두 러너의 관문 판정을 함께 「항상 0」으로 | broken | O97 | ps1 전수 696/3 · sh O 98/1 |
| site-zero-both | 두 러너의 재서술처 판정을 함께 「항상 0」으로 | broken | O91 | ps1 전수 696/3 · sh O 98/1 |
| after-empty-sh | `run.sh` 재심 기준 판정을 수정 전 형태(본문 `exit`)로 되돌림 | broken | O95 | sh O 98/1(ps1은 깨지 않음 — 전수 697/2) |

<!-- reversal-table:end -->

- **기준선** — 행마다 작업 트리를 `.git` 없이 새로 복사했다(`rev85-{행}` — 행이 끝나면 지움). 기준선 사본에서 ps1 전수 **697/2**(`T3` — 사본에 `.git`이 없다 · `U6` — 이 보고서가 아직 없다) · sh Part O **99/0**. 표의 「붉은 케이스」는 기준선 밖만 적는다. 드라이버 `rev85.py`(치환마다 앵커 수 1 단언 — 열아홉 행 모두 `ANCHOR-OK`) · 결과 `rev85.txt`. ps1은 행마다 전수, sh는 Part O만 돌렸다(행당 약 4분 30초). 첫 아홉 행(`name-dup` ~ `gate-nonext`)은 sh 수정 전 트리, 나머지와 `decl-drop` 재측정은 수정 뒤 트리에서 쟀다 — 수정은 `rt_values_bad`와 `O95` 픽스처만 바꾸므로 앞 아홉 행의 붉은 케이스 가운데 바뀔 수 있는 것은 `decl-drop`의 `O94`뿐이고, 그 행을 다시 쟀다.
- **본 검사 단독 행** — `O88` `def-drop` · `def-swap` / `O90` `site-token-drop` · `site-pair-drop` / `O92` `rt-stray` / `O94` `after-zero` / `O96` `gate-nonext` · `gate-nokin` / `O98` `review-done`.
- **`name-dup`이 통제 `O89` · `O91`을 함께 붉힌다** — 두 통제의 합성 규약이 실제 선언의 이름 목록으로 만들어지므로, 실물에 중복이 있으면 기준 픽스처에도 중복이 들어가 차이가 0이 된다(규약 체크리스트 6번 「다른 케이스가 이미 붉은 동안」의 경우). `O88`의 단독 행은 `def-drop` · `def-swap`이다.
- **`decl-drop`이 두 러너를 갈랐다** — 이 사이클 되돌림의 수확이다. 수정 전 sh는 선언 줄이 없을 때 `O94`가 초록이었다(입력 0줄의 awk). 고친 뒤 두 러너 모두 `O88` · `O94`이고, 수정 전 형태로 되돌린 `after-empty-sh`를 `O95`의 새 칸이 붉힌다.
- **`O96`은 이 트리에서 구성상 0이다** — 실제 표에 키가 `rf-105` 이상인 행이 아직 없다. 판정이 공허하지 않다는 것은 되돌림(`gate-nonext` · `gate-nokin`)과 상태 C · C2(회고가 새 행을 낸 트리)가 보인다.

## 미해결·후속 메모

1. **`/tide:cycle` 시작점이 판정 `불가`에서 재작업 라운드를 보지 않는다** — status는 이번에 갈랐지만 cycle의 인자 없는 시작점은 여전히 impl 단계부터다(`start-point-map:` 고정 줄 · Part W). M82 꼴 상태에서 인자 없는 `/tide:cycle`은 impl을 다시 돌아 라운드를 잘못 올린다. 규약 선언 · Part W를 함께 움직이는 한 사이클 몫이다.
2. **status의 새 갈래를 무는 케이스가 없다** — `W121`은 status와 cycle의 판정 값 집합만 견준다. 라운드 대조 문장을 지워도 하니스는 초록이다(이번 범위는 Part O — 마일스톤 T05가 「없으면 재서술처 공존 정도만」이라 했고, `retro-flow:` 이름에 status가 들 자리가 없어 얹지 않았다).
3. **대상 레포에서 `retro-gate-since:`의 값** — 이 저장소의 키 번호(rf-105)가 설치본 폴백으로 대상 레포에 그대로 간다(상태표 ⒅). 막지 않는 절차라 해는 작지만 `rf-61`(병합으로 `rf-104`)과 같은 부류다.
4. **열린 행 14 가운데 이 사이클이 집은 넷**(`rf-90` · `rf-94` · `rf-99` · `rf-103`)은 릴리즈 뒤 회고가 `반영`으로 옮긴다 — impl은 상태 열을 바꾸지 않았다(T01의 처분 열셋만).
5. **`rf-103`이 `반영`으로 옮겨 갈 때 병합으로 받은 `rf-38`의 몫이 함께 닫히면 안 된다**(리뷰 보충) — `rf-38`(선언되지 않은 행의 통째 삭제를 Part O가 보지 못한다)은 이 사이클이 다루지 않았다(T01 「지우는 편집은 범위 밖」). 릴리즈 뒤 회고가 그 몫을 열린 행으로 남겨야 한다.
