# M68 완료보고서 (impl)

## 개요

release 스킬의 두 병기어 토큰(`scan-same-form-control` · `absent-job-unjudged`)이 파일 전역이 아니라 자기 단계를 가리키는 **앵커와 같은
항목 창**에 있는지를 하니스가 묻게 했다. 창의 정의와 앵커를 먼저 실측으로 정했고(T01), 규약에 병기어마다 단계 앵커를 선언하고 경계
고지를 실측치로 고쳤으며(T02), 두 러너 사본에 항목 창 헬퍼와 Part W 케이스 `W79`~`W90`을 더했다(T03). 세 태스크가 사슬 의존이라 레벨마다
태스크가 하나여서 메인이 순차로 구현했다(병렬 디스패치 폴백 조건).

재작업 라운드(rework): 0

## 태스크별 수행 내용

- **M68-T01** (읽기 전용 실측) — 창 정의 둘을 `skills/release/SKILL.md`에 적용하고, 마일스톤 완료 기준 3의 이동 변이 셋을 스크래치패드
  사본에 걸어 각 정의가 무엇을 잡는지 쟀다. 결과와 범위는 아래 「T01 실측」 절이 적는다.
  - **창 정의** — Part N의 `floor_hits_in` 창(최상위 항목의 부분 트리)은 쓰지 않았다. 그 정의로는 「게시 분기」 항목 전체가 한 창(113~148행)이라
    `absent-job-unjudged`를 같은 `pr` 모드 불릿의 `open → 대기`로 옮겨도 앵커와 같은 창에 남는다. **토큰이 든 가장 안쪽 목록 항목의
    부분 트리**를 창으로 삼았다(136~147행). 그래서 **Part N과 함수를 공유하지 않는다**(`N20`~`N22` 무변경).
  - **앵커** — 스캔 단계는 `mkdocs build`(51행), 부재 잡은 `gh pr checks`(137행). 둘 다 파일에서 **한 창에만** 나오고 단계를 설명하는
    **본문 문장**에 속한다. `merged`는 세 창에 나와 탈락했다. 유일한 ASCII 앵커가 있어 대체 경로(스킬 문면에 표지를 새로 두는 안)는 택하지
    않았고 `skills/release/SKILL.md`는 고치지 않았다.
- **M68-T02** — `docs/conventions.md`에 선언 줄 둘을 새 키로 두었다.
  - `absent-job:` 항목(측정 배당 블록)에 `absent-job-anchor:` `` `gh pr checks` ``와 **항목 창의 정의**(가장 안쪽 항목의 부분 트리 · 빈 줄은 창을
    끊지 않음 · 앵커는 그 창 안에만) · `floor-marks:` 창과 다른 이유(T01 실측)를 적었다. 이 블록이 파일에서 앞에 있어 정의를 한 번 여기 두었다.
  - "릴리즈 빌드 출력 검증" 절 `scan-control:` 블록에 `scan-control-anchor:` `` `mkdocs build` ``를 두고 창 정의는 위 항목을 가리키게 했다.
  - **새 키를 둔 이유** — 앵커 값에 공백이 있어 기존 `scan-control:`·`absent-job:` 줄의 꼬리를 늘리면 `W68`·`W74`의 첫 토큰 추출과 섞인다.
    값은 백틱 구획으로 적고(`floor-marks:`와 같은 형태) 첫 백틱 구획을 읽는다.
  - **경계 고지를 고쳤다** — 두 블록의 *"토큰은 파일 전역에서 찾으므로 … 옮겨도 초록"* 과 부인 기록 포인터를, 창에 묶인 뒤의 사실(M66·M67
    변이가 이제 붉음)과 **남는 경계** ⑴ 토큰과 앵커를 함께 옮기는 편집(실측 초록) ⑵ 창 안 둘레 문장의 낡음(묻지 않음)으로 바꿨다.
    마일스톤이 셋째로 적은 「앵커 문자열이 다른 단계에 새로 등장」은 경계가 아니라 **앵커 유일성 단언이 받는다**(되돌림 실측).
- **M68-T03** — 두 러너 사본의 `W78` 바로 뒤에 같은 순서·같은 의미로 넣었다.
  - 헬퍼: `anchor_of`/`AnchorOf`(선언 꼬리의 첫 백틱 구획) · `item_win_probe`/`ItemWinProbe`(`"<창 안 앵커 yes|no> <파일의 앵커 줄 수> <창 안 앵커 줄 수>"`)
    · `win_unique`/`WinUnique`. 들여쓰기는 공백만 세고 sh 사본은 줄 끝 CR을 먼저 벗긴다(ps1은 `ReadAllLines`가 벗긴다). 항목 판정은 `- ` 또는
    `[0-9]+. `(ps1은 ASCII 범위 문자 클래스)로 두 사본이 같다.
  - 케이스(병기어마다 여섯): 앵커 선언 줄 유일성(`W79`·`W85`) · 앵커 추출 positive-control(`W80`·`W86`) · 토큰-앵커 같은 창(`W81`·`W87`) ·
    앵커가 파일에서 그 창 안에만(`W82`·`W88`) · 픽스처 통제(`W83`·`W89` — 앵커와 다른 항목에 토큰을 둔 픽스처를 **같은 헬퍼**가 잡는다) ·
    앵커 선언 꼬리 구분자(`W84`·`W90`). `W70`·`W76`은 남겼다.
  - README의 `cases:` 선언 · 파트 내역 · Part W 머리글·블록을 같은 편집에서 고쳤고, M66·M67 두 경계 불릿과 두 사본의 M66·M67 주석의
    *"파일 전역이라 옮겨도 초록 · 좁히지 않았다"* 를 `W81`·`W82` / `W87`·`W88`을 가리키는 현재 사실로 고쳤다.

**「새 검사를 세울 때 함께 붙일 것」 대조** — 대상은 선언 키 `scan-control-anchor:` · `absent-job-anchor:`와 케이스 `W79`~`W90`이다.

| 항목 | 대조 |
|---|---|
| 1. 추출 positive-control | `W80` · `W86` |
| 2. 선언 줄 유일성 | `W79` · `W85` |
| 3. 되돌림 실측 | 아래 표 14행. 새 케이스 12개 전부가 어느 행에서든 붉었다 |
| 4. 되돌림의 방향 둘 | `broken` 5행 · `adversarial` 9행이 표에 있고 전부 붉었다. **초록으로 지나간 적대 변이 1**(토큰과 앵커를 함께 옮김 — 표 아래 고지). 닫으려면 앵커 자체가 단계를 가리키는지를 의미로 판정해야 해 규약·README에 실측치와 함께 고지했다 |
| 5. 무는 대상 집합의 명세 | 선언은 `docs/conventions.md`, 토큰·앵커는 `skills/release/SKILL.md` 한 경로. 발견 집합이 아니다 |
| 6. 통제는 판정의 반응을 묻는다 | `W83`·`W89`는 실제 헬퍼에 픽스처를 먹인다. 헬퍼를 파일 전체 한 창으로 망가뜨리자 둘이 붉었다(`whole-file-window`) |

## T01 실측 — 창 정의와 앵커

- **범위** — 대상 파일 `skills/release/SKILL.md` 하나(검색 루트 레포 루트). 창 정의 ⒜ `floor_hits_in`과 같은 끊기(같거나 얕은 들여쓰기의 항목 ·
  빈 줄 뒤 들여쓰기 0의 비-항목 줄) ⒝ 토큰 줄에서 위로 올라가 만나는 가장 안쪽 항목의 부분 트리. 앵커 후보 검색 패턴은 리터럴
  `site/mkdocs.yml` · `mkdocs build` · `mkdocs` · `gh pr checks` · `merged`이고, 대조 항목은 「후보가 든 ⒜ 창의 수」다. 이동 변이 셋은
  스크래치패드 사본에만 걸었다(실물 무변경 — `git diff`로 확인).

| 대상 | ⒜ 창 | ⒝ 창 |
|---|---|---|
| `scan-same-form-control`(56행) | 50~56 | 50~56 |
| `absent-job-unjudged`(142행) | 113~148 | 136~147 |
| 변이 1: 스캔 토큰을 커버리지 체크 머리 줄로 | 57~84 | 57~83 |
| 변이 2: 부재 잡 토큰을 「완료 후」 줄 뒤로 | 149~151 | 창 없음 |
| 변이 3: 부재 잡 토큰을 `open → 대기`로 | **113~148(원래와 같음)** | 134~134 |

| 앵커 후보 | 등장 줄 | ⒜ 창 수 | 그 단계의 본문 문장에 속하는가 |
|---|---|---|---|
| `site/mkdocs.yml` | 51 | 1 | 예 — 스캔 단계가 무엇을 보고 발동하는지를 적는 본문 낱말 |
| `mkdocs build` | 51 | 1 | 예 — 스캔 단계의 **행위**를 적는 본문 낱말 |
| `mkdocs` | 51 | 1 | 예 — 같은 줄의 부분 문자열이라 위 둘과 같은 자리 |
| `gh pr checks` | 137 | 1 | 예 — 마무리 불릿의 **행위**를 적는 본문 낱말 |
| `merged` | 105 · 136 · 175 | 3 | 아니다 — 136만 해당 항목의 머리 낱말이고 105·175는 다른 단계의 서술이다(창 수 3으로 이미 탈락) |

- **판단** — ⒜는 변이 3을 원래 창에 남겨 완료 기준 3의 셋째 교란을 잡지 못한다 → ⒝를 택하고 Part N과 공유하지 않는다. 앵커는 한 창에만 나오고
  단계의 본문 문장에 속하는 `mkdocs build`와 `gh pr checks`를 택했다(`site/mkdocs.yml`도 조건을 만족하나 단계의 **행위**를 적는 쪽을 골랐다).

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | 위 「T01 실측」 절 — 두 토큰의 창 줄 범위(두 정의), 앵커 후보마다 창 수와 본문 소속, 택한 앵커(`mkdocs build` · `gh pr checks`)와 창을 공유하지 않는 판단. 대체 경로는 택하지 않았다(유일한 ASCII 앵커가 있었다) |
| 2 | 충족 | 앵커 선언 줄은 키마다 하나(`W79`·`W85`, 되돌림 `dup-*-anchor-decl` 단독 붉음). 경계 고지 검색 범위 — 패턴 `파일 전역\|FILE-WIDE\|옮겨도 초록\|좁히는 일은\|좁히지 않은 사유\|not done \(reason: scope` · 대상 `docs/conventions*.md` · `tests/discover/{README.md,run.sh,run.ps1}` · `skills/**/*.md` · 대조 항목 「release 스킬 토큰이 파일 전역이라 옮겨도 초록이라는 현재형 주장인가」 · 검색 루트 레포 루트. `docs/conventions*.md` 히트 0. README·러너 히트는 M66·M67 판본의 과거형 서술 · `W70`·`W76`의 현재 동작 설명 · 다른 파트(P·O·V·W 창)의 서술이라 대상 밖이다. 남는 경계 ⑴(실측 초록 값)·⑵를 두 블록에 적었고, 마일스톤의 ⑶은 앵커 유일성 단언이 받는다(`scan-anchor-elsewhere` · `absent-anchor-elsewhere`) |
| 3 | 충족 | 교란 각각이 붉었다 — 스캔 토큰을 커버리지 체크 머리 줄로 `move-scan-token-to-coverage` · 부재 잡 토큰을 「완료 후」 뒤로 `move-absent-token-to-end` · `open → 대기`로 `move-absent-token-to-open` · 앵커 선언 삭제 `del-scan-anchor-decl`·`del-absent-anchor-decl` · 복제 `dup-scan-anchor-decl`·`dup-absent-anchor-decl` · 앵커를 다른 단계 본문에 하나 더 `scan-anchor-elsewhere`·`absent-anchor-elsewhere` · 두 사본 헬퍼가 파일 전체를 한 창으로 `whole-file-window`. 값은 아래 되돌림 표 |
| 4 | 충족 | `W70`·`W76`이 남아 있고 토큰 삭제 `del-scan-token`(W70 포함) · `del-absent-token`(W76 포함)에서 붉었다 |
| 5 | 충족 | 헬퍼를 Part N과 **공유하지 않았다**(T01 판단). `floor_hits_in`·`FloorHitsIn` 코드는 고치지 않았고, 두 사본의 `git diff` 변경 구획이 Part W의 `W67`~`W90` 구역에만 있음을 아래 테스트 결과 절이 적는다 |
| 6 | 충족 | 아래 「이 사이클이 적은 기대는 주장」 표. 대상은 이 사이클이 고친 추적 파일 넷(`docs/conventions.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md`)의 추가된 줄과 이 보고서이고, 대조 항목은 「다른 절·파일의 절차나 동작을 근거로 자기 주장을 세우는가」, 검색 루트 레포 루트. **검색 패턴은 없다** — 발화가 형태로 판정되지 않아 그 대상의 추가된 줄을 **전수 정독**했다(패턴 축을 빈 채로 두고 「검사했다」로 적지 않는다) |
| 7 | 충족 | `docs/epics/E2.md` 마커 블록에 `- M68 — …` 한 줄이 있고 `docs/milestones/M68.md` 메타데이터가 `epic: E2`다(Part M) |

## 이 사이클이 적은 기대는 주장

완료 기준 6의 목록이다. 형태는 규약 "다른 절차에 기대는 주장의 분기" 소절(`lean-branches-stated`)을 따른다.

| 주장 | 기대는 절차 | 갈래 | 갈래별 성립 |
|---|---|---|---|
| **규약 두 블록 · README Part W의 M66·M67 경계 불릿: M66·M67 변이와 `open → 대기` 변이가 이제 붉는다** | `tests/discover` Part W 실행 | ⑴ `pwsh` 전수 ⑵ `sh` Part W 부분 ⑶ `sh`·`dash` 전수 · Windows PowerShell 5.1 | ⑴·⑵ 참 — 되돌림에서 실측 ⑶ 되돌림으로는 재지 않았다 — 주장은 「`pwsh` 전수·`sh` Part W」로 범위를 적었다 |
| **규약 `absent-job` 블록: 토큰과 앵커를 함께 옮기는 편집은 초록이다** | 같은 헬퍼 `item_win_probe` | ⑴ 스캔 병기어로 잰 변이 ⑵ 부재 잡 병기어 | ⑴ 참 — `move-scan-token-with-anchor` 440/1 · 92/0 ⑵ 재지 않았다 — 문장이 「이 병기어로는 따로 재지 않았다」로 적는다 |
| **규약 `scan-control` 블록: 남는 경계는 앵커가 단계의 본문 낱말이라는 전제에 기댄다** | release 스킬 문면 | ⑴ 앵커가 단계 본문에 남아 있음 ⑵ 앵커 낱말이 단계에서 사라짐 ⑶ 앵커 낱말이 다른 단계에 생김 | ⑴ 참 — T01 실측(51행 · 137행) ⑵ 재지 않았다 — 판정상 파일의 앵커 줄 수가 0이면 `W82`·`W88`이 거짓이다(`del-*-anchor-decl`은 선언 줄을 지운 행이라 이 갈래의 실측이 아니다) ⑶ 앵커 유일성이 붉는다(`*-anchor-elsewhere`) |
| **러너 주석·README: `W70`·`W76`은 창 판정이 망가져도 토큰 삭제에서 붉어야 한다** | `scope_tok`/`ScopeTok`(창 헬퍼와 별개 함수) | ⑴ 창 헬퍼가 망가짐 ⑵ 토큰이 삭제됨 | ⑴ `W70`·`W76`은 창 헬퍼를 부르지 않는다(`whole-file-window`에서 둘 다 초록) ⑵ 참 — `del-scan-token`·`del-absent-token`에서 붉었다 |
| **규약 `scan-control` 블록 · README Part W의 M68 블록: 항목 창의 정의는 위 `absent-job:` 항목이 적는다** | 규약 같은 파일의 앞선 항목 | ⑴ 그 항목이 정의를 담음 | ⑴ 참 — 가장 안쪽 항목의 부분 트리 · 빈 줄 · 앵커 유일성을 적었다 |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M68-impl.md` |
| 수정 | `docs/conventions.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` |
| 삭제 | (없음) |

기준선은 이 단계 시작 시점의 워킹트리다. `docs/milestones/M68.md`와 `docs/epics/E2.md`의 역방향 등재 한 줄은 직전 milestone 단계의
미커밋 산출물이다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (Windows 11 · `pwsh` 7.6.6 · Windows PowerShell 5.1 · Git Bash `sh` · `dash`) | 아래 표 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — CI `posix` 잡) | 릴리즈 단계에서 확인 |

| 하니스 | 실행 환경 | 결과 |
|---|---|---|
| `tests/discover` 전수 | `pwsh` 7.6.6 | PASS=441 FAIL=0 |
| `tests/discover` 전수 | Windows PowerShell 5.1 | PASS=441 FAIL=0 |
| `tests/discover` Part W (부분) | Git Bash `sh` | PASS=92 FAIL=0 |
| `tests/discover` Part W (부분) | `dash` | PASS=92 FAIL=0 |
| `tests/fleet` | `pwsh` | PASS=45 FAIL=0 |
| `tests/fleet-cycle` | `pwsh` | PASS=24 FAIL=0 |
| `tests/fleet-verify` | `pwsh` | PASS=30 FAIL=0 |
| `tests/multi-repo` | `pwsh` | PASS=37 FAIL=0 |
| `tests/mutation` | `pwsh` | PASS=12 FAIL=0 |
| `tests/site-includes` | `pwsh` | PASS=51 FAIL=0 |

- **순서(`measure-after-artifacts`)** — 위 값은 이 보고서를 쓴 뒤 잰 측정이다. 보고서가 입력으로 읽혔다는 **증거는 `U6`이 초록으로 바뀐
  두 행**(`tests/discover` 전수 · `pwsh`와 Windows PowerShell 5.1 — 보고서 이전 440/1)에만 있다. `sh`·`dash`의 Part W 부분 실행과 나머지 여섯
  하니스에는 `U6`이 없어 근거는 실행 순서뿐이다. 이 절을 채운 뒤 `pwsh` `tests/discover` 전수를 한 번 더 돌려 **441/0**(448줄)을 얻었고, 이 문장을
  사실로 고친 뒤에도 한 번 더 돌렸다.
- **캐시 아님(`measure-not-cached`)** — 하니스는 빌드 캐시가 없는 스크립트이고, 하니스마다 실행 시간(`discover` `pwsh` 20초 · 5.1 43초 ·
  `mutation` 121초 등)과 출력 줄 수(`discover` 전수 448줄 — 케이스 441 반영)를 기록해 매번 실제로 돌았음을 확인했다.
- **`sh` 축은 전수를 로컬에서 돌지 않았다** — 규약 측정 배당이 그 축을 CI `posix` 잡에 넘기고 이 저장소의 게시 모드는 `pr`이다. 갈래는
  M67 보고서의 같은 항목과 같다(`pr` · 체크가 레그마다 결과에 있고 초록이면 참 · 붉음·미완료면 사용자 확인 · 조회 실패 또는 잡·레그의
  부재·건너뜀이면 태그 전 로컬 전수 · `pr` 밖 모드면 로컬 전수). 로컬 `sh`·`dash`는 이번에 고친 **Part W**만 부분 실행했다.
- **Part N 무변경(완료 기준 5)** — `git diff -U0`의 변경 구획은 `tests/discover/run.sh`에서 4360행·4377행·4390행 셋, `tests/discover/run.ps1`에서
  4797행·4820행·4839행 셋이고 전부 Part W의 `W67`~`W90` 구역이다. diff 안의 `floor_hits_in`·`FloorHitsIn` 두 건은 새 `W79` 주석이 그 함수를
  **이름으로 언급**한 줄이며 Part N 코드는 고치지 않았다. `N20`~`N22`는 위 전수 두 행에서 초록이다.

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: W79 W82 W84 W85 W88 W90 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| move-scan-token-to-coverage | 스캔 토큰을 사이트 빌드 출력 스캔 단계에서 커버리지 체크 머리 줄로 옮김 | adversarial | W81;W82 | ps1 438/3 · sh Part W 90/2 |
| move-absent-token-to-end | 부재 잡 토큰을 마무리 불릿에서 스킬 끝 「완료 후」 줄로 옮김 | adversarial | W87;W88 | ps1 438/3 · sh Part W 90/2 |
| move-absent-token-to-open | 부재 잡 토큰을 같은 `pr` 모드 불릿의 `open → 대기`로 옮김 | adversarial | W87;W88 | ps1 438/3 · sh Part W 90/2 |
| del-scan-anchor-decl | 규약의 `scan-control-anchor:` 선언 줄 삭제 | broken | W79;W80;W81;W82 | ps1 436/5 · sh Part W 88/4 |
| del-absent-anchor-decl | 규약의 `absent-job-anchor:` 선언 줄 삭제 | broken | W85;W86;W87;W88 | ps1 436/5 · sh Part W 88/4 |
| dup-scan-anchor-decl | 같은 `scan-control-anchor:` 선언 줄을 하나 더 둠 | adversarial | W79 | ps1 439/2 · sh Part W 91/1 |
| dup-absent-anchor-decl | 같은 `absent-job-anchor:` 선언 줄을 하나 더 둠 | adversarial | W85 | ps1 439/2 · sh Part W 91/1 |
| scan-anchor-elsewhere | 스캔 앵커 문자열을 프리플라이트 2 본문에 하나 더 둠 | adversarial | W82 | ps1 439/2 · sh Part W 91/1 |
| absent-anchor-elsewhere | 부재 잡 앵커 문자열을 `open → 대기` 본문에 하나 더 둠 | adversarial | W88 | ps1 439/2 · sh Part W 91/1 |
| whole-file-window | 두 사본의 헬퍼가 토큰이 있으면 파일 전체를 한 창으로 봄 | broken | W83;W89 | ps1 438/3 · sh Part W 90/2 |
| del-scan-token | release 스킬의 스캔 토큰 삭제 | broken | W70;W81;W82 | ps1 437/4 · sh Part W 89/3 |
| del-absent-token | release 스킬의 부재 잡 토큰 삭제 | broken | W76;W87;W88 | ps1 437/4 · sh Part W 89/3 |
| tab-tail-scan-anchor | `scan-control-anchor:` 선언 줄 끝에 탭 한 글자 | adversarial | W84 | ps1 439/2 · sh Part W 91/1 |
| tab-tail-absent-anchor | `absent-job-anchor:` 선언 줄 끝에 탭 한 글자 | adversarial | W90 | ps1 439/2 · sh Part W 91/1 |

<!-- reversal-table:end -->

**기준선은 `tests/discover` ps1 전수 440/1 · `sh` Part W 92/0이다.** ps1 전수의 유일한 FAIL은 `U6`(이 보고서가 없던 동안의 진행 신호)이고,
결과 칸의 ps1 총계는 전 행에서 그 하나를 포함하며 붉은 케이스 칸에서는 뺐다. `sh` 축은 **부분 실행**(Part W · Git Bash `sh`)이다. 두 축은
**모든 행에서 Part W 안의 같은 케이스 집합**을 붉혔다.

- **방법** — 대상 파일 넷(규약 · release 스킬 · 러너 두 사본)의 사본을 스크래치패드에 **경로를 키로** 뜨고 매 행 시작에서 복원했다. 치환 대상이
  정확히 한 번 나오지 않으면 `MUTFAIL`로 적게 했고(출력에 없었다), 결과 줄 수가 요청 행 수와 같음을 묶음마다 확인했으며, 세 묶음 끝에서 넷을
  사본과 해시로 대조해 **전부 같음**을 확인했다.
- **목록(`reversal-table-main`)에서 뺀 케이스** — 통제 `W80`·`W86`(추출)과 `W83`·`W89`(픽스처)는 단독 행 요구의 대상이 아니며 각자 붉는
  행이 있다. 나머지 둘은 구조적 불가 주장이다(`infeasible-evidenced`).
  - **`W81`·`W87`은 단독으로 붉을 수 없다** — 어느 형태에서: 창 안 앵커 줄 수 `nin`이 0이 되는 모든 변이. 왜: `W81`은 `nin > 0`을 묻고
    `W82`는 `na > 0 ∧ na == nin`을 묻는데, `nin = 0`이면 `na = 0`이든 아니든 `W82`도 거짓이다(`W82`가 참이면 `W81`도 참 — 논리적 약화형).
    반례 탐색: 이동 셋 · 앵커 선언 삭제 둘 · 토큰 삭제 둘에서 `W81`/`W87`은 언제나 `W82`/`W88`과 함께만 붉었다.
  - **`W83`·`W89`를 따로 붉히는 행을 두지 않았다**(「불가능하다」가 아니라 **하지 않았다** — 사유: 범위) — 두 병기어가 **같은 헬퍼**를
    쓰므로 헬퍼를 망가뜨리는 변이는 둘을 함께 붉힌다(`whole-file-window`). 따로 붉히려면 되돌림 대상에 든 러너 두 사본에서 **그 통제 자신의
    픽스처 생성 줄만** 변이해야 하고, 그것은 판정의 회귀가 아니라 통제 입력의 변경이라 행으로 두지 않았다. 앞 판본은 이것을 「행이 없다」는
    구조적 불가 주장으로 적었으나 위 반례가 있어 `infeasible-evidenced`의 주장에서 뺀다(M68 리뷰 반증 지적 ③).
- **초록으로 지나간 적대 변이 하나(고지)** — `move-scan-token-with-anchor`: 스캔 토큰을 커버리지 체크 머리 줄로 옮기면서 앵커 문자열도 원래 자리
  (`(예: mkdocs build)`)에서 빼 그 머리 줄로 함께 옮기자 **ps1 440/1(`U6`만) · `sh` Part W 92/0 초록**이었다. 창 판정은 「토큰이 앵커와 같은
  창인가」까지이고 **그 앵커가 정말 그 단계를 가리키는가**는 의미 판정이다. 규약 두 블록과 README에 실측치와 함께 고지했다.

## 미해결·후속 메모

1. **토큰과 앵커를 함께 옮기는 편집은 초록이다** — 위 고지. 닫으려면 앵커가 단계를 가리키는지를 의미로 판정해야 한다. 앵커가 단계의 본문 낱말이라
   옮기려면 단계 서술을 함께 고쳐야 한다는 것이 지금 기대는 전제다.
2. **부재 잡 병기어로는 「함께 옮김」 변이를 재지 않았다** — 같은 헬퍼라 형태가 같을 것이나 실측은 스캔 병기어 한 행이다(규약에 그렇게 적었다).
3. **되돌림은 `pwsh` 전수와 `sh` Part W 두 축으로만 쟀다** — `dash`·Windows PowerShell 5.1과 `sh` 전수는 되돌림으로 재지 않았다(`sh` 축 전수 판정은
   측정 배당에 따라 CI `posix` 잡).
4. **M66·M67 리뷰의 부인 기록 원인이 닫혔다** — 두 리뷰가 초록으로 잰 이동 변이가 이제 붉는다(`move-scan-token-to-coverage` · `move-absent-token-to-end`).
   리뷰가 부인 연속을 끊을 수 있는지는 리뷰의 판단이다.
5. **되돌림 드라이버의 도구 함정 하나가 또 났다** — 행 정의의 괄호 하나가 빠져 첫 실행이 파싱 단계에서 멈췄다(트리 무변경 · 백업 미생성).
   `pwsh -File`은 파싱 오류를 실행 전에 내므로 이번에는 변이 없이 끝났다.
