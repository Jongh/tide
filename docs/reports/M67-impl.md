# M67 완료보고서 (impl)

## 개요

`pr` 모드 마무리의 「조회는 됐는데 배당이 지목한 잡이 PR 체크 결과에 없음」 갈래를 release 스킬 문면에 넣고 규약에 병기어
(`absent-job:` `absent-job-unjudged`)로 선언해 결합했으며(T01), 그 선언과 재서술처의 정합을 `tests/discover` Part W가 물게
했다(T02). 함께 M66-T02가 찾은 기존 서술의 갈래 누락 후보 셋을 `lean-branches-stated` 형태로 참인 갈래에 한정했다 —
`external-tool` 축의 「실질 게이트」(T03) · 「라운드별 이력은 보존된다」(T04) · cycle 스킬의 「자동 상속」(T05). T05가 찾은 같은
형태의 넷째 자리(규약의 fleet-cycle 「리뷰 검증 규율 전이 상속」)도 T04와 같은 편집 묶음에서 고쳤다. 레벨 1(T01·T05)과
레벨 2(T02·T03)는 서브에이전트 둘씩 병렬로 디스패치했고(파일 비중첩), 레벨 3(T04)은 메인이 구현했다.

재작업 라운드(rework): 0

## 태스크별 수행 내용

- **M67-T01** (서브에이전트) — 병기어 `absent-job:` `absent-job-unjudged`를 세웠다.
  - **선언 자리는 마일스톤 T01의 ⑵ 갈래이되 정의 줄도 본체에 두었다.** Part W의 선언 추출(`decl_tail`/`DeclTail`)과 정의 줄 계수
    (`scope_defn`/`ScopeDefn`)가 둘 다 `docs/conventions.md`만 읽는다(`$CONV`). 마일스톤은 ⑵에서 「정의는 조각에」를 적었으나
    그렇게 두면 정의 줄 단언이 조각을 보지 못하므로 **정의 줄까지 본체에** 두었다(마일스톤 문면과의 차이 — 사유는 이것 하나).
  - `docs/conventions.md` 측정 배당 블록의 「조회가 실패하면 판정 없이 태그를 달지 않는다」 불릿 바로 뒤에 불릿을 두었다 —
    조회 성공 · 잡 부재가 ⓓ에서 조회 실패와 같은 경우라는 문장, 선언 줄 · 굵은 코드 스팬 정의 줄(판정 **상태**만 정의하고 절차
    문장은 조각에 남긴다), 재서술처 하나(`skills/release/SKILL.md`), 기계가 무는 것과 묻지 않는 것(그 갈래를 실제로 밟았는가 ·
    파일 전역 토큰이라 불릿 밖으로 옮겨도 초록).
  - `skills/release/SKILL.md` 「`pr` 모드」 merged → 마무리 불릿에 *"체크 목록은 받았어도 그 넘긴 축을 맡은 잡이 목록에 없으면 소비할
    판정이 없으므로(`absent-job-unjudged`) 같은 처분을 따른다"* 를 더했다 — 규약 정의문과 어순이 겹치지 않게 했다.
  - `docs/conventions-release.md` PR CI 확인 항목의 기존 문장에 토큰만 붙였다(포인터 — 결합 대상 아님).
  - **프리플라이트 2는 고치지 않았다** — 그 문면은 로컬에서 생략할 수 있는 축의 조건만 적고 태그 전 소비를 주장하지 않는다.
    토큰을 더하면 재서술처가 둘이 되어 규약의 「하나다」와 어긋나고, 파일 전역 판정이라 둘을 구별하지도 못한다.
- **M67-T02** (서브에이전트) — Part W에 `W73`~`W78`(6케이스)을 `W72` 바로 뒤에 두 사본 같은 순서로 더했다. 선언 줄 유일성 · 추출
  positive-control(폴백 `zzz-absent-job-unset`) · 규약 정의 줄 · release 스킬 백틱 토큰 · 배선(`zzz-other-absent` → `no`) · 꼬리
  구분자. 재서술처가 하나라 결합 케이스를 두지 않았다(M66 `W67`~`W72`와 같은 판단 — 러너 주석에 사유). 경계(파일 전역 토큰)를
  러너 주석·README에 적었다. README의 `cases:` 선언 · 파트 내역 · Part W 머리글·블록을 같은 편집에서 고쳤다.
- **M67-T03** (서브에이전트) — `docs/conventions.md` `external-tool` 축 불릿 「이 부류의 성질」의 *"릴리즈 PR의 macOS 레그를 태그 전에
  읽는 것이 그 축의 실질 게이트다"* 를 고쳤다. 그 확인 자리가 `pr` 모드 마무리의 **사용자 확인**임을 적고(절차는
  `docs/conventions-release.md`의 "`pr` 모드" 절 한 줄 인용), 갈래 셋과 갈래별 성립을 하위 불릿으로 두어 주장을 ⑴로 한정했다.
  - ⑴ `pr` · 조회 성공 · macOS 레그 있음 — 참 ⑵ `pr` · 조회 실패 또는 잡 부재(`absent-job-unjudged`) — 참이 아니다 ⑶ push-only·
    `release` 모드 — 참이 아니다.
  - **측정 배당 여부** — `external-tool`의 집행 잡은 배당 잡과 같은 `posix`(macOS 레그)다. 그러나 ⑵·⑶의 대체 경로는 로컬 전수이고,
    같은 불릿 첫 문장대로 로컬 실측은 BSD 도구 축을 판정하지 못한다 — 그래서 ⑵·⑶에서 이 축은 **판정 없이 태그에 실린다**고 적었다.
  - 「게이트」 검색(아래 기준 3 근거)에서 이 축의 확인을 게이트로 부른 긍정 서술은 그 한 자리였다.
- **M67-T04** (메인) — `docs/conventions.md` "완료 기준 대조 (impl)" 절의 *"(라운드별 이력은 재작업 라운드 절이 이미 보존한다)"* 를
  *"라운드별 이력은 보존되지 않는다"* 로 고치고, 그 절이 남기는 것은 **라운드 값**(impl 보고서 개요 · 리뷰 계측 줄)이며 이 표와
  리뷰 보고서는 라운드마다 다시 쓰인다는 사실, 이력 장치의 물음은 `docs/reports/retro.md` 2026-09-14 회고 후속 표가 받는다는
  포인터를 적었다. 이력 장치 자체는 세우지 않았다(마일스톤 범위).
  - **함께 고친 자리(T05 발견)** — `docs/conventions.md` 멀티 레포 오케스트레이션의 fleet-cycle 「리뷰 검증 규율 전이 상속」 불릿이
    *"반증 시도·in-review 재검증·판정 계측이 레포마다 적용된다"* 로 cycle 스킬과 같은 형태였다. 적용되는 것이 갈래까지 포함한 절차임을
    적고 반증의 폴백 · 재검증의 수정 0건 · 재실행 · 환경상 불가를 이름으로 두었다. T05 서브에이전트는 이 파일을 편집하지 않도록
    지시받아 발견만 넘겼다.
- **M67-T05** (서브에이전트) — `skills/cycle/SKILL.md` review 단계의 「자동 상속」을 *"갈래까지 포함한 절차 전체"* 로 고쳐 반증의
  서브에이전트 경로 · 폴백, 재검증의 수정 0건 · 재실행 · 환경상 불가, 판정 계측(조건 갈래 없음 · 어느 반증 갈래로 돌았는지를 기록)을
  이름으로 적었다. continuous 재작업 불릿의 같은 형태 서술도 review 단계를 가리키도록 고쳤다. cycle의 review가 서브에이전트 맥락에서
  돌아 폴백이 실제로 닿는 갈래라는 주장은 **하지 않았다** — 스킬 문면이 그것을 적지 않아 확인할 수 없었다.

**「새 검사를 세울 때 함께 붙일 것」 대조** — 대상은 선언 키 `absent-job:`과 케이스 `W73`~`W78`이다.

| 항목 | 대조 |
|---|---|
| 1. 추출 positive-control | `W74` |
| 2. 선언 줄 유일성 | `W73` |
| 3. 되돌림 실측 | 아래 표 8행. 새 케이스 6개 전부가 어느 행에서든 붉었다 |
| 4. 되돌림의 방향 둘 | `broken` 4행 · `adversarial` 4행이 표에 있고 전부 붉었다. **초록으로 지나간 적대 변이 1** — 토큰을 마무리 불릿 밖으로 옮긴 변이(표 아래 고지). 규약·러너 주석·README가 그 경계를 적었고, 실측치는 리뷰가 규약·README에 더했으며 부인 기록은 `docs/reports/M67-review.md`에 있다(M67 리뷰 정정) |
| 5. 무는 대상 집합의 명세 | 선언·정의 줄은 `docs/conventions.md`, 토큰은 `skills/release/SKILL.md` 한 경로. 발견 집합이 아니다. `docs/conventions-release.md`의 토큰은 포인터라 결합하지 않는다(README에 적음) |
| 6. 통제는 판정의 반응을 묻는다 | `W77`은 인자로 준 토큰 하나만 읽어 **기준선이 구조로 상수**인 자리이고 사유를 러너 같은 자리 주석에 적었다(`W71`과 같은 형태). 반응은 되돌림 `wiring-absent-break`가 확인했다 |

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | `skills/release/SKILL.md` merged → 마무리 불릿이 「체크 목록은 받았어도 넘긴 축의 잡이 목록에 없음」 갈래와 「같은 처분」(같은 불릿 앞 문장의 태그 전 로컬 전수 · 실패면 태그 없이 중단)을 담고 `` `absent-job-unjudged` `` 토큰으로 가리킨다(`W76`). 선언 줄은 `docs/conventions.md`에 하나(`W73`) · 정의 줄은 굵은 코드 스팬(`W75`). 선언 자리와 사유는 위 T01 항목이 적는다(마일스톤 ⑵ 갈래, 정의 줄 위치는 마일스톤 문면과 다름 — 헬퍼가 본체만 읽는다) |
| 2 | 충족 | 교란 여섯이 각각 붉었다 — 선언 삭제 `del-absent-decl` · 복제 `dup-absent-decl` · 정의 굵은 표기 제거 `strip-absent-defn-bold` · 스킬 토큰 삭제 `del-rel-skill-absent` · 백틱만 제거 `strip-rel-skill-absent-bt` · 꼬리 탭 `tab-tail-absent`. 값은 아래 되돌림 표 |
| 3 | 충족 | `external-tool` 불릿이 갈래 ⑴~⑶과 갈래별 성립을 적고 주장을 ⑴로 한정한다. 측정 배당 여부는 위 T03 항목. 「게이트」 검색 범위 — 패턴 `게이트` · 대상 `docs/conventions*.md`와 `skills/**` · 대조 항목 「macOS 레그나 PR CI 확인을 게이트로 부르는가」 · 검색 루트 레포 루트. 긍정 서술 히트는 옛 「실질 게이트」 한 자리(고침), 「게이트가 아니다」로 이미 적은 히트 넷은 유지, 나머지(프리플라이트·바닥·검증 게이트 등)는 다른 대상이라 뺐다. 대상 밖 `CHANGELOG.md`·과거 보고서·회고의 같은 낱말은 이력 기록이라 고치지 않았다 |
| 4 | 충족 | "완료 기준 대조 (impl)" 절이 「보존되지 않는다」로 적고 보존되는 것(라운드 값)과 아닌 것(라운드별 판정·차단)을 가르며 회고 후속 표를 가리킨다. 재서술 검색 범위 — 패턴 `이력(은\|을\|이)? ?(보존\|남)\|라운드별 이력\|라운드마다.*(보존\|남)` · 대상 `docs/*.md` · `skills/**/*.md` · `tests/*/README.md` · `CLAUDE.md` · 대조 항목 「리뷰 라운드별 이력이 보존된다고 주장하는가」 · 검색 루트 레포 루트. 히트 넷 중 대상은 이 한 자리이고, 나머지 셋(규약 회고 절의 「이력 보존」 · `docs/project-context.md`의 버전 가산 이력 · retro 스킬의 회고 문서 누적)은 리뷰 라운드 이력이 아니라 뺐다 |
| 5 | 충족 | `skills/cycle/SKILL.md` review 단계가 반증의 **폴백**과 재검증의 **환경상 불가**를 이름으로 적는다(continuous 재작업 불릿은 그 단계를 가리킨다). 다른 체이닝 서술 검색 범위 — 패턴 `상속\|그대로 따르`(대상 `skills/**`) · `상속된다\|상속되\|자동 상속\|전이 상속`(대상 레포 전체에서 `docs/milestones/**`·`docs/reports/**` 제외) · `review\|반증\|재검증`(대상 `skills/fleet-cycle/SKILL.md`) · 대조 항목 「체이닝 단계가 리뷰 검증 절차를 갈래 없이 상속한다고 주장하는가」 · 검색 루트 레포 루트. 같은 형태 히트는 cycle 스킬 두 자리와 규약의 fleet-cycle 전이 상속 한 자리였고 셋 다 고쳤다. 뺀 히트 — `skills/cycle/SKILL.md`의 continuous 모드가 release 스킬을 따른다는 줄(리뷰 절차 아님) · `skills/review/refutation.md`·`skills/impl/SKILL.md`의 「상속」(서브에이전트에 git 금지·레포 루트를 넘기는 뜻) · `skills/fleet-cycle/SKILL.md`(cycle 규칙을 따른다고만 적고 리뷰 절차를 재서술하지 않음) · 규약 "다른 절차에 기대는 주장의 분기" 절의 예시 낱말(규칙 서술) |
| 6 | 충족 | 아래 「이 사이클이 적은 기대는 주장」 표가 목록이다. 발화는 형태로 판정되지 않으므로(M66-T02) 목록은 **손으로 읽어** 만들었다 — 대상은 이 사이클이 고친 추적 파일 일곱의 추가된 줄(`git diff -U0`의 `+` 줄: `docs/conventions.md` · `docs/conventions-release.md` · `skills/release/SKILL.md` · `skills/cycle/SKILL.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md`)과 이 보고서, 대조 항목은 「다른 절·파일의 절차를 근거로 자기 주장을 세우는가」, 검색 루트 레포 루트. 서브에이전트가 쓴 줄은 각 반환의 기대는 주장 목록을 받아 메인이 원문과 대조했다 |
| 7 | 충족 | `docs/epics/E2.md` 마커 블록에 `- M67 — …` 한 줄이 있고 `docs/milestones/M67.md` 메타데이터가 `epic: E2`다(양방향 — Part M) |

## 이 사이클이 적은 기대는 주장

완료 기준 6의 목록이다. 형태는 규약 "다른 절차에 기대는 주장의 분기" 소절(`lean-branches-stated`)을 따른다.

| 주장 | 기대는 절차 | 갈래 | 갈래별 성립 |
|---|---|---|---|
| **release 스킬: 잡 부재면 「같은 처분」을 따른다** | 같은 불릿의 조회 실패 처분 | ⑴ 넘긴 축이 있었다 ⑵ 넘긴 축이 없었다 | ⑴ 참 — 태그 전 로컬 전수 · 실패면 태그 없이 중단 ⑵ 참 — 처분에 조건이 없어 알리고 진행하며 `docs/conventions-release.md`의 「넘긴 축이 없었으면 … 진행한다」와 같다 |
| **`external-tool`: 그 확인이 판정을 태그 전에 싣는 것은 ⑴뿐이다** | `docs/conventions-release.md` PR CI 확인 항목 | 위 T03 항목의 ⑴~⑶ · ⑷ `pr` · 조회 성공 · **macOS 레그만** 결과에 없음 | ⑴ 참 ⑵·⑶ 거짓(적었다) ⑷ 거짓 — 처음에는 적지 않았다(`absent-job-unjudged`가 잡만 말했다). 리뷰가 병기어를 건너뜀·레그 단위까지 넓혀 ⑷를 ⑵에 담았고, ⑵의 처분 갈래(넘긴 축 있음 → 로컬 전수 · 없음 → 알리고 진행)는 어느 쪽이든 이 축을 재지 못한다고 적었다(M67 리뷰 정정) |
| **fleet-cycle 전이 상속: 레포마다 어느 갈래로 돌았는지가 그 레포의 리뷰 보고서에 남는다** | 규약 "리뷰 검증 규율" 절 | ⑴ 반증 서브에이전트 ⑵ 반증 폴백 ⑶ 재검증 수정 0건 ⑷ 재실행 ⑸ 환경상 불가 | ⑴ 참 — 계측 줄 `수행` ⑵ 참 — 폴백 기록 의무 · 계측 줄 `폴백` ⑶ 참 — 계측 줄의 in-review 수정 수가 0 ⑷ 참 — `## 검증`에 재실행 결과 ⑸ 참 — 미검증 잔여 리스크 명시 의무 · ⑹ 재작업 라운드가 있음 — 처음 문장은 거짓이었다(리뷰 보고서가 라운드마다 다시 쓰여 이전 라운드의 갈래가 남지 않는다). 규약 문장을 「마지막 라운드의 갈래」로 좁혔다(M67 리뷰 정정) |
| **완료 기준 대조 절: 리뷰 보고서는 라운드마다 다시 쓰여 이전 라운드는 서술로 적은 만큼만 되짚인다** | 리뷰 보고서 파일 규칙(`docs/reports/M{N}-review.md` 한 파일) | ⑴ 재리뷰가 파일을 덮어쓴다 ⑵ 재리뷰가 이전 내용을 서술로 옮겨 남긴다 | ⑴ 참 — M64·M62의 실례(회고 후속 표 행) ⑵ 참 — 「서술로 적은 만큼」이 이 갈래를 담는다. 파일명에 라운드가 없어 이전 판본을 따로 두는 갈래는 없다 |
| **cycle 스킬: 계측 줄이 어느 반증 갈래로 돌았는지를 기록한다** | 규약 "리뷰 검증 규율" 절 판정 계측 | ⑴ `수행` ⑵ `폴백` | ⑴·⑵ 참 — 고정 형식의 필드 값이다 |
| **Part W 러너 주석·README: 토큰을 마무리 불릿 밖으로 옮겨도 초록이다** | `scope_tok`의 파일 전역 탐색 | ⑴ 토큰이 파일 안 다른 자리에 백틱으로 남는다 ⑵ 파일에서 사라지거나 백틱이 벗겨진다 | ⑴ 참 — 이번에 실측(표 아래 `move-rel-skill-absent`) ⑵ 해당 없음 — `W76`이 붉는다(`del-rel-skill-absent` · `strip-rel-skill-absent-bt`) |
| **규약 `absent-job` 불릿: 무는 것은 선언 유일성 · 정의 줄 · 재서술처 공존까지다** | `tests/discover` Part W | ⑴ T02가 들어간 트리 ⑵ T02 이전 트리 | ⑴ 참 — `W73`~`W78` ⑵ 거짓 — 이 보고서의 트리는 ⑴이다 |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M67-impl.md` |
| 수정 | `docs/conventions.md` · `docs/conventions-release.md` · `skills/release/SKILL.md` · `skills/cycle/SKILL.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` |
| 삭제 | (없음) |

기준선은 이 단계 시작 시점의 워킹트리다. `docs/milestones/M67.md`와 `docs/epics/E2.md`의 역방향 등재 한 줄은 직전 milestone 단계의
미커밋 산출물이다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (Windows 11 · `pwsh` 7.6.6 · Windows PowerShell 5.1 · Git Bash `sh` · `dash`) | 아래 표 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — CI `posix` 잡) | 릴리즈 단계에서 확인 |

| 하니스 | 실행 환경 | 결과 |
|---|---|---|
| `tests/discover` 전수 | `pwsh` 7.6.6 | PASS=429 FAIL=0 |
| `tests/discover` 전수 | Windows PowerShell 5.1 | PASS=429 FAIL=0 |
| `tests/discover` Part W (부분) | Git Bash `sh` | PASS=80 FAIL=0 |
| `tests/discover` Part W (부분) | `dash` | PASS=80 FAIL=0 |
| `tests/fleet` | `pwsh` | PASS=45 FAIL=0 |
| `tests/fleet-cycle` | `pwsh` | PASS=24 FAIL=0 |
| `tests/fleet-verify` | `pwsh` | PASS=30 FAIL=0 |
| `tests/multi-repo` | `pwsh` | PASS=37 FAIL=0 |
| `tests/mutation` | `pwsh` | PASS=12 FAIL=0 |
| `tests/site-includes` | `pwsh` | PASS=51 FAIL=0 |

- **순서(`measure-after-artifacts`)** — 위 값은 이 보고서를 쓴 뒤 잰 측정이다. 보고서가 입력으로 읽혔다는 **증거는 `U6`이 초록으로 바뀐
  두 행**(`tests/discover` 전수 · `pwsh`와 Windows PowerShell 5.1 — 보고서 이전 428/1)에만 있다. `sh`·`dash`의 Part W 부분 실행과 나머지
  여섯 하니스에는 `U6`이 없어 근거는 실행 순서뿐이다. 이 절을 채운 뒤 `pwsh` `tests/discover` 전수를 한 번 더 돌려 **429/0**을 얻었다(이 문장을 고친 뒤에도 한 번 더 돌렸고 값이 같았다).
- **캐시 아님(`measure-not-cached`)** — 하니스는 빌드 캐시가 없는 스크립트이고, 하니스마다 실행 시간(`discover` `pwsh` 22초 · 5.1 44초 ·
  `mutation` 127초 등)과 출력 줄 수를 기록해 매번 실제로 돌았음을 확인했다.
- **`sh` 축은 전수를 로컬에서 돌지 않았다** — 규약 측정 배당이 그 축을 CI `posix` 잡에 넘기고 이 저장소의 게시 모드는 `pr`이다. 갈래는
  M66 보고서의 같은 행과 같다(`pr` · 체크 초록이면 참 · 붉음·미완료면 사용자 확인 · 조회 실패 또는 잡 부재면 태그 전 로컬 전수 · `pr` 밖
  모드면 로컬 전수) — 이번 사이클이 넣은 `absent-job-unjudged`로 셋째 갈래가 스킬 문면에도 닿는다. 로컬 `sh`·`dash`는 이번에 고친
  **Part W**만 부분 실행했다.
- **제외 토큰 부재** — 대상 파일 둘(`docs/conventions.md` · `skills/release/SKILL.md`)에서 `zzz-absent-job-unset` · `zzz-other-absent`를
  `pwsh` `Select-String -SimpleMatch -ErrorAction Stop`으로 찾아 **각 0건**(명령 오류 없음). 같은 명령 형태의 양성 통제
  (`absent-job-unjudged`)는 4건이었다.

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: W73 W75 W76 W77 W78 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| del-absent-decl | 규약의 `absent-job:` 선언 줄 삭제 | broken | W73;W74;W75;W76 | ps1 424/5 · sh Part W 76/4 |
| dup-absent-decl | 같은 `absent-job:` 선언 줄을 하나 더 둠 | adversarial | W73 | ps1 427/2 · sh Part W 79/1 |
| empty-absent-value | 선언 줄은 두고 값만 비움 | broken | W74;W75;W76 | ps1 425/4 · sh Part W 77/3 |
| strip-absent-defn-bold | 규약 정의 줄의 굵은 표기만 벗김 | adversarial | W75 | ps1 427/2 · sh Part W 79/1 |
| del-rel-skill-absent | release 스킬의 병기어 토큰 삭제 | broken | W76 | ps1 427/2 · sh Part W 79/1 |
| strip-rel-skill-absent-bt | release 스킬의 토큰에서 백틱만 벗김 | adversarial | W76 | ps1 427/2 · sh Part W 79/1 |
| tab-tail-absent | `absent-job:` 선언 줄 끝에 탭 한 글자 | adversarial | W78 | ps1 427/2 · sh Part W 79/1 |
| wiring-absent-break | 두 사본의 `W77`이 실제 병기어를 인자로 받게 | broken | W77 | ps1 427/2 · sh Part W 79/1 |

<!-- reversal-table:end -->

**기준선은 `tests/discover` ps1 전수 428/1 · `sh` Part W 80/0이다.** ps1 전수의 유일한 FAIL은 `U6`(이 보고서가 없던 동안의 진행
신호)이고, 결과 칸의 ps1 총계는 전 행에서 그 하나를 포함하며 붉은 케이스 칸에서는 뺐다. `sh` 축은 **부분 실행**(Part W · Git Bash
`sh`)이라 파트 밖의 붉음을 보지 못한다. 두 축은 **모든 행에서 Part W 안의 같은 케이스 집합**을 붉혔다.

- **방법** — 대상 파일 넷(규약 · release 스킬 · 러너 두 사본)의 사본을 스크래치패드에 **경로를 키로** 뜨고 매 행 시작에서 복원했다.
  변이는 리터럴 치환이고 치환 대상이 정확히 한 번 나오지 않으면 그 행을 `MUTFAIL`로 적게 했다(출력에 없었다). 두 묶음 끝에서 넷을
  사본과 해시로 대조해 **전부 같음**을 확인했다.
- **`strip-absent-defn-bold`가 함께 답한 물음** — 규약에는 T03이 더한 평문 백틱 언급(`external-tool` 갈래 ⑵)이 있어, 정의 줄의 굵은
  표기를 벗겼을 때 `W75`가 그 언급을 정의로 잘못 세어 초록으로 남을 수 있는지가 T02 반환의 열린 물음이었다. 그 행에서 `W75`가 붉었다 —
  정의 줄 계수는 굵은 코드 스팬만 센다.
- **목록(`reversal-table-main`)에서 뺀 케이스 — `W74` 하나**(M67 리뷰 정정: 처음에는 `W77`도 빼고 「통제라 단독 행 요구의 대상이
  아니다」로만 적었다. `W77`은 전용 행 `wiring-absent-break`가 있어 목록에 넣었다). `W74`는 **단독으로 붉을 수 없다**(`infeasible-evidenced`).
  - **어느 형태에서** — 선언 줄 꼬리의 첫 토큰 추출이 폴백 토큰(`zzz-absent-job-unset`)이 되는 경우다.
  - **왜 성립하는가** — `W74`가 붉으면 추출값이 폴백 토큰이고, 그때 `W75`(정의 줄 계수)와 `W76`(스킬 백틱 토큰)이 그 폴백 토큰을
    찾는데 폴백 토큰은 대상 파일 어디에도 없어(아래 테스트 결과의 제외 토큰 검색 0건) 둘도 함께 붉는다.
  - **반례 탐색** — 선언 삭제(`del-absent-decl`) · 값 비움(`empty-absent-value`) 두 행에서 `W74`는 언제나 `W75`·`W76`과 함께만 붉었다.
- **초록으로 지나간 적대 변이 하나(고지)** — `move-rel-skill-absent`: release 스킬의 토큰을 마무리 불릿에서 빼 스킬 끝의 「완료 후
  `.tide/phase`를 `idle`로」 줄 뒤로 옮기자 **ps1 428/1(`U6`만) · `sh` Part W 80/0 초록**이었다. 결합은 토큰이 지워지는 편집만 막고 자리를
  옮기는 편집은 막지 않는다 — 규약 `absent-job` 불릿 · 러너 주석 · README가 이 경계를 이미 적었고, 이번에 실측치를 얻었다. M66의 스캔
  토큰과 같은 열린 경계이며 창을 단계로 좁히는 헬퍼(M66 리뷰 후속 ⑵)가 이제 토큰 둘을 받는다.

## 미해결·후속 메모

1. **macOS 레그만 결과에 없는 경우 — M67 리뷰가 닫았다**(병기어를 건너뜀·레그 단위로 넓히고 `external-tool` ⑵에 담았다 · 아래는 impl 시점의 서술) — 조회는 됐고 `posix`의 우분투·윈도우 레그는 있는데 `macos-latest` 레그만 없을 때 release 절차가
   그것을 「지목한 잡 부재」로 알아채는지가 열려 있다. `absent-job-unjudged`는 잡을 말하고 레그를 말하지 않는다. `external-tool` 불릿은
   그 경우를 주장하지 않도록 ⑴을 「macOS 레그 있음」으로 적었다(T03 서브에이전트 발견).
2. **파일 전역 토큰 창** — 위 고지. release 스킬의 병기어 토큰 둘(`scan-same-form-control` · `absent-job-unjudged`)이 같은 열린 경계를
   가진다.
3. **`docs/conventions-release.md`의 토큰은 결합하지 않았다** — 포인터이고 절차 문장의 단일 원본이라 재서술처로 세지 않는다. 그 토큰이
   지워져도 초록이다(README에 적음).
4. **회고 후속 표의 「라운드별 리뷰 보고서가 덮어써져 반환 이력이 파일에 남지 않는다」 행은 처분되지 않았다** — T04는 규약의 거짓 주장만
   사실로 좁혔고 이력 장치는 세우지 않았다.
5. **M66-T02가 손으로 읽지 않은 규약 나머지 구간** — 이번에도 전수 재조사하지 않았다. T05의 검색이 넷째 자리(규약 fleet-cycle 전이 상속)를
   찾은 것은 「같은 형태가 더 있다」의 실례다.
6. **되돌림 드라이버의 도구 함정 둘** — `pwsh -File`로 `-Rows a,b` 배열 인자를 넘기면 **문자열 하나**로 들어오고, 원소가 하나인
   `@(@(x,y,z))`는 **평탄화**되어 행 정의가 글자로 쪼개졌다. 첫째는 행 다섯이 변이 없이 한 행으로 돌아 결과 줄 수로, 둘째는 크래시로
   드러났다(크래시는 쓰기 전이었고 해시 대조로 트리 무변경을 확인했다). 결과 행 수를 요청 행 수와 대조하지 않았다면 첫째는 기준선 값이
   네 행의 결과로 읽힐 수 있었다.
