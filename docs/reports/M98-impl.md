# M98 완료보고서 (impl)

## 개요

M98 태스크 여섯(T01~T06)을 구현했습니다.
- 스킬과 규약에서 계획 문서 경로가 적힌 자리를 전부 찾아 읽기 · 쓰기 · 발견 신호 · 그 밖으로 갈랐습니다(T01).
- 조각 `docs/conventions-tracker.md`에 읽기 항목 선언 `tracker-read-items:`와 로컬 문서 어댑터 표, 남은 경로 자리의 선언 `tracker-path-sites:`를 세웠습니다(T02).
- 스킬 다섯의 읽기 자리와 규약 본체 「상태 확인 항목」 표의 두 행을 이름 포인터로 바꿨습니다(T03 · T04).
- 하니스 Part F에 케이스 19(`F83`~`F101`)를 더했습니다(T05 — 라운드 0에 18, 라운드 1에 하나).
- E5와 조각의 소비 서술을 갱신했습니다(T06).

읽는 파일과 고르는 규칙은 바뀌지 않았습니다. 마일스톤 문서와 달라진 점이 셋 있습니다.
- **이름의 접두를 `tr-`에서 `rd-`로 바꿨습니다.** `tr-`는 규약의 `lifecycle-transitions:`가 이미 쓰는 접두입니다(`tr-draft` · `tr-impl` 등).
- **`release`의 에픽 등재 확인은 바꾸지 않았습니다.** 문서 커밋 경로가 로컬 에픽 문서를 커밋할 때 작업 트리의 파일을 확인하는 절차라 계획 읽기가 아니라 `cite`로 분류했습니다.
- **`milestone`의 「파일 위치」 줄은 바꾸지 않았습니다.** 다음 번호 계산은 문서를 만드는 일의 일부라 쓰기로 분류했습니다. 그 줄의 구절은 `tr-draft:` 전이 선언의 문면 앵커이기도 합니다.

재작업 라운드(rework): 1

**라운드 1**(리뷰 라운드 0의 판정 「불가」 — 차단 1 · 권장 2 · 사소 4를 받았습니다)
- **차단 1 — 표 행 추출을 넓혔습니다.** 두 러너의 행 추출(`rd_rows` · `RdRows`)은 줄이 세로줄 · 공백 · 백틱 · `rd-`로 정확히 시작할 때만 행으로 보았습니다. 이제 앞 공백 · 탭을 벗긴 줄이 세로줄로 시작하면 행이고, 첫 칸에서 공백 · 탭 · 백틱을 벗긴 값이 `rd-`로 시작하면 그 값이 이름입니다. 리뷰가 든 세 꼴(첫 세로줄 뒤 공백 없음 · 앞 공백 · 백틱 없음)마다 통제(`F101`)와 되돌림 행을 두었습니다. 조각과 README의 문장에는 행의 정의를 적었습니다.
- **권장 2 — 단계 이름 대조를 세웠습니다.** `F96`이 `tracker-phase-writes:`의 `=` 앞 이름이 `skills/` 바로 아래 디렉터리 이름인지도 묻습니다. 통제 `F100`에 「단계 이름 하나를 스킬이 아닌 이름으로 바꾼 사본」을 더했습니다. 커맨드 명단(규약의 상태 파일 절)과의 대조는 세우지 않았고 경계로 적었습니다.
- **권장 3 · 사소 5 — 재고의 테두리를 적었습니다.** 재고는 경로 리터럴을 든 줄만 셌습니다. 경로 없이 계획을 읽는 자리(`cycle`의 의존 표기 읽기와 시작점 갈래 · `impl`의 시작 전 검사 · `retro`의 릴리즈 표지 읽기 · `status`의 다음 커맨드 판단)와 `milestone` 「파일 위치」 줄의 최대 번호 읽기는 이름으로 옮기지 않았습니다. 조각 첫 문단을 그 범위로 좁혔고, 조각 「묻지 않는 것」과 E5 「M98 결과」 · 사이클 배분 2에 남은 자리를 적었습니다. 스킬 문면은 이 라운드에서 바꾸지 않았습니다.
- **사소 4 · 6 · 7** — 규약 29줄의 부류별 수를 T01에 채웠습니다. 「다른 꼴의 경로」 예시에 디렉터리 없는 글롭(`M*.md` · `E*.md`)을 더했습니다. 행 추출이 표 하나에 한정되지 않아 어댑터 표가 늘면 러너를 고쳐야 한다는 점을 조각과 README에 적었습니다.
- 케이스는 하나 늘어 Part F가 107, 총계가 928입니다(`F101`).

## 태스크별 수행 내용

- **M98-T01 — 재고 조사.** 검색 패턴은 `docs/milestones` · `docs/epics` · `M*.md` · `E*.md` 넷이고, 검색 루트는 `skills/`(모든 `.md`) · `hooks/` · `docs/conventions*.md` 셋입니다. `grep -rnE`로 한 번에 돌렸습니다. `hooks/`는 0줄입니다.

  **스킬**(17줄)

  | 자리 | 원문 요지 | 분류 | 처분 |
  |---|---|---|---|
  | `skills/cycle/SKILL.md` 시작점 판단 | `M{N}`은 `docs/milestones/M*.md` 중 가장 큰 번호 | 읽기 | `rd-cycle-latest` 포인터로 바꿈 |
  | `skills/cycle/SKILL.md` 사이클 실행 1단계 | `docs/milestones/M{N}.md`를 생성 | 쓰기 | 그대로 |
  | `skills/fleet/SKILL.md` 발견 조건 | tide 산출물을 가질 것 | 발견 신호 | 그대로 |
  | `skills/fleet-cycle/SKILL.md` 발견 조건 | 같은 신호 | 발견 신호 | 그대로 |
  | `skills/fleet-cycle/SKILL.md` 레포 기준 | 산출물은 그 레포 루트 기준 | 그 밖(산출물 자리 서술) | 그대로 |
  | `skills/fleet-verify/SKILL.md` 발견 조건 | 같은 신호 | 발견 신호 | 그대로 |
  | `skills/impl/SKILL.md` 대상 지정(번호) | 번호가 오면 `docs/milestones/M3.md` | 읽기 | `rd-cycle-doc` 포인터로 바꿈 |
  | `skills/impl/SKILL.md` 대상 지정(생략) | `docs/milestones/M*.md` 중 번호가 가장 큰 문서 | 읽기 | `rd-cycle-latest` 포인터로 바꿈 |
  | `skills/kickoff/SKILL.md` 감지 신호 | 기존 산출물 유무 | 발견 신호 | 그대로 |
  | `skills/kickoff/SKILL.md` 골격 생성 | 디렉터리 생성 | 쓰기 | 그대로 |
  | `skills/milestone/SKILL.md` 파일 위치 | `docs/milestones/M{N}.md`(가장 큰 번호 + 1) | 쓰기(번호 발급) | 그대로 |
  | `skills/milestone/SKILL.md` 에픽 | `docs/epics/E*.md` 중 `status: open` | 읽기 | `rd-epic-open` 포인터로 바꿈 |
  | `skills/milestone/SKILL.md` 번호 사전경고 | `git log -- "docs/milestones/M{N}.md"` | 그 밖(git 경로 조회) | 그대로 |
  | `skills/release/SKILL.md` 릴리즈 표지 | 문서 메타데이터에 한 줄을 더함 | 쓰기 | 그대로 |
  | `skills/release/SKILL.md` 에픽 등재 확인 | 문서가 작업 트리에 있는지 | 그 밖(작업 트리 확인) | 그대로 |
  | `skills/retro/SKILL.md` 수집 | `docs/milestones/M*.md` | 읽기 | `rd-cycle-all` 포인터로 바꿈 |
  | `skills/review/SKILL.md` 시작 전 검사 | `docs/milestones/M*.md` 중 최대 번호 | 읽기 | `rd-cycle-latest` 포인터로 바꿈 |

  읽기 6 · 쓰기 4 · 발견 신호 4 · 그 밖 3입니다. `M*.md` · `E*.md` 패턴만 맞는 줄은 위 줄들 밖에 없었습니다.

  **규약 문서 집합**(31줄) — 읽는 법을 재서술한 자리는 `docs/conventions.md` 「상태 확인 항목」 표의 `milestone` 행과 `open-epic` 행 둘입니다(T04가 바꿈). 나머지 29줄은 대상이 아닙니다. 부류와 줄 수는 아래와 같고 합이 29입니다(편집 전 `HEAD` 기준 · 라운드 1에서 수를 채웠습니다).
  - 문서의 **자리를 정하는** 문장 2 — 에픽 층 절의 「위치」, 마일스톤 문서 절의 「위치」.
  - `docs/conventions-release.md`의 문서 커밋 경로 선언과 그 설명 7.
  - 다른 에픽 · 마일스톤 문서를 근거로 인용한 줄 7(`E1` 둘 · `E2` · `E3` · `E4` · `E5` · `M43`).
  - 시점 기록물 범위를 적은 줄 4.
  - 발견 신호 정의와 산출물 앵커링 2.
  - 커버리지 토큰 설명 1, 번호 사전경고의 git 경로 조회 1, 하니스가 이 저장소의 계획 문서를 문다는 서술 1.
  - `tr-draft:` 선언의 문면 앵커 1(스킬 구절을 그대로 든다).
  - 조각 `docs/conventions-tracker.md` 자신의 3.

- **M98-T02 — 선언과 어댑터 표.** 조각의 "트래커 계약" 절에 소절 「읽기 항목」을 더했습니다.
  - `tracker-read-items:` — `rd-cycle-latest` · `rd-cycle-doc` · `rd-cycle-all` · `rd-epic-open` 넷입니다. 계획 시점 후보 가운데 태스크 읽기는 따로 두지 않았습니다. 태스크는 사이클 문서 안에 있어 `rd-cycle-doc`이 돌려주는 것에 넣었습니다. 라운드 0은 「태스크만 따로 읽는 스킬 자리가 없다」고 적었는데 틀렸습니다 — `skills/cycle/SKILL.md`가 태스크 목록의 의존 표기를 읽습니다. 그 자리는 경로를 적지 않아 재고에 들지 않았고, 이름으로 옮기지 않았습니다(아래 라운드 1). `retro`가 모든 문서를 읽어 `rd-cycle-all`을 더했습니다.
  - 로컬 문서 어댑터 표 — 이름마다 한 행입니다.
  - `tracker-path-sites:` — 경로를 아직 적는 스킬 일곱과 분류(`write` · `signal` · `cite`)입니다. T01 표의 「그 밖」이 `cite`입니다.

- **M98-T03 — 스킬 포인터.** 스킬 다섯의 여섯 자리를 바꿨습니다. 한 스킬에서 도달 규칙 문장은 한 번만 적었습니다. `impl`은 두 자리 아래에 포인터 한 줄을 더했습니다(바뀐 줄 2 · 더한 줄 1). 나머지 넷은 한 줄씩입니다.

- **M98-T04 — 「상태 확인 항목」 표.** `milestone` 행은 조각을 인용하고, `open-epic` 행은 「위 `milestone` 행이 가리키는 조각」으로 가리킵니다. `open-epic` 행에 조각 파일 이름을 직접 적으면 같은 줄의 자기 참조(「에픽 (방향) 층」 절)가 조각의 앵커 집합으로 대조돼 `G1`이 붉었습니다(pwsh 7 전수 `got 1, want 0`). 그래서 파일 이름을 그 줄에 두지 않았습니다. 본체 「트래커 계약 (분리된 조각)」 절의 소비 서술과 `docs/project-context.md`의 조각 행도 맞췄습니다.

- **M98-T05 — 하니스.** 두 러너에 같은 케이스 19를 넣었습니다(라운드 0에 18, 라운드 1에 `F101`).
  - 등록표 행 8(`F83`~`F90`) — `tracker-read-items:`의 줄 수 · 금지 구분자 · 이름 유일 · 정의 하나 · 고아 정의 · 정의 차례, `tracker-path-sites:`의 줄 수 · 금지 구분자.
  - 손 케이스 11(`F91`~`F101`) — 추출 positive-control 1, 본 검사 5(표 대응 `F92` · 잔재 `F93` · 소비처 없는 이름 `F94` · 박힌 경로 `F95` · 연산 소속 `F96`), 통제 5(`F97`~`F101`, 차이로 묻습니다).
  - 단계 이름의 소속은 라운드 0에서 세우지 않았고, 「대조할 선언처가 없다」고 적었습니다. 그 근거는 좁았습니다 — 키 꼴 선언은 없지만 그 이름 여섯은 모두 `skills/` 디렉터리 이름입니다. 라운드 1에서 `F96`에 그 대조를 더했습니다(아래 라운드 1).
  - ps1 헬퍼의 매개변수 이름을 처음에 `$root`로 썼다가 `$ROOT`를 가려(PowerShell은 변수 이름의 대소문자를 가리지 않습니다) Part F가 중단됐고, `$skBase`로 바꿨습니다.

- **M98-T06 — 서술 갱신.** 조각 머리의 소비 서술과 「기계가 묻는 것」 · 「묻지 않는 것」, E5의 「M98 결과」 소절과 사이클 배분의 둘째 항목, 하니스 README Part F 절을 고쳤습니다.

**동작 불변 대조**

| 자리 | 옛 문면의 경로와 선택 | 새 포인터가 닿는 어댑터 표 행 | 같음 |
|---|---|---|---|
| `cycle` 시작점 | `docs/milestones/M*.md` 중 가장 큰 번호 | `rd-cycle-latest` — `docs/milestones/M*.md` 중 번호가 가장 큰 문서 | 같음 |
| `impl` 번호 지정 | `docs/milestones/M3.md`(준 번호의 문서) | `rd-cycle-doc` — `docs/milestones/M{N}.md` | 같음 |
| `impl` 생략 | `docs/milestones/M*.md` 중 번호가 가장 큰 문서 | `rd-cycle-latest` | 같음 |
| `review` 시작 전 검사 | `docs/milestones/M*.md` 중 최대 번호 | `rd-cycle-latest` | 같음 |
| `retro` 수집 | `docs/milestones/M*.md` | `rd-cycle-all` — `docs/milestones/M*.md` 전부 | 같음 |
| `milestone` 에픽 | `docs/epics/E*.md` 중 `status: open` | `rd-epic-open` — `docs/epics/E*.md` 중 `status: open` | 같음 |
| 규약 `milestone` 행 | `docs/milestones/M*.md` 중 최대 번호 — 번호와 제목 | `rd-cycle-latest` — 파일 이름의 번호와 첫 줄 제목 | 같음 |
| 규약 `open-epic` 행 | `docs/epics/E*.md` 중 `status: open` — 「속한 마일스톤」 마지막 항목 | `rd-epic-open` — 속한 사이클은 「속한 마일스톤」 블록 | 같음 |

**포인터 도달**

| 자리 | 따라가는 경로 |
|---|---|
| `skills/cycle/SKILL.md` | 「시작점 판단」 첫 줄 → `docs/conventions-tracker.md` → "트래커 계약" 절 → 「읽기 항목」 소절 → 어댑터 표의 `rd-cycle-latest` 행 |
| `skills/impl/SKILL.md` | 대상 지정 셋째 줄 → 같은 절 → `rd-cycle-doc` 행과 `rd-cycle-latest` 행 |
| `skills/review/SKILL.md` | 시작 전 검사 줄 → 같은 절 → `rd-cycle-latest` 행 |
| `skills/retro/SKILL.md` | 「수집」 첫 항목 → 같은 절 → `rd-cycle-all` 행 |
| `skills/milestone/SKILL.md` | 「에픽(방향)」 항목 → 같은 절 → `rd-epic-open` 행 |
| `docs/conventions.md` `milestone` 행 | 같은 절 → `rd-cycle-latest` 행 |
| `docs/conventions.md` `open-epic` 행 | 위 `milestone` 행 → 같은 절 → `rd-epic-open` 행 |

대상 레포에 조각이 없을 때는 스킬 문장이 설치본을 읽으라고 적고, 조각은 설치본에 실립니다(`docs/`는 플러그인 배포에 들어 있습니다 — 지금 설치본 `2.59.1`의 `docs/conventions.md`를 스킬이 같은 문장으로 읽습니다). 이 사이클의 조각은 릴리즈 뒤의 설치본부터 그 표를 가집니다.

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | T01 표 — 검색 패턴 넷(`docs/milestones` · `docs/epics` · `M*.md` · `E*.md`), 검색 루트 셋(`skills/` · `hooks/` · `docs/conventions*.md`), 대조 항목은 줄마다의 분류와 처분입니다. T03 · T04 뒤 같은 명령을 `skills/`에 다시 돌린 결과는 11줄이고 전부 쓰기 · 발견 신호 · 그 밖입니다(읽기 0줄). 규약 쪽 두 행도 경로가 없습니다. 대상 밖 29줄의 사유는 T01에 부류별로 적었습니다. |
| 2 | 충족 | `docs/conventions-tracker.md`의 「읽기 항목」 소절 — 선언 한 줄(이름 넷) · 정의 항목 넷 · 어댑터 표 행 넷입니다. `F83` · `F86` · `F92`가 초록입니다. |
| 3 | 충족 | 위 「동작 불변 대조」 표 — 여덟 자리, 다름 0입니다. 대조 항목은 경로 글롭 · 최대 번호 선택 · `status: open` 선택 · 번호 지정 시의 대상 넷입니다. 대조는 옛 문면(`git diff`의 지워진 줄)과 어댑터 표 행을 눈으로 견준 것입니다. 스킬을 실제로 돌려 같은 파일을 읽는지는 재지 않았습니다. |
| 4 | 충족 | 위 「포인터 도달」 표 — 바꾼 스킬 다섯과 규약 표 두 행의 경로입니다. Part G는 pwsh 7과 Git Bash sh에서 37/0입니다. |
| 5 | 부분 | 아래 「마지막 측정」 — pwsh 7 · Windows PowerShell 5.1 전수 FAIL 0이고 총계가 `cases:` 선언과 같습니다. sh 축 전수(`dash` · `bash`)는 `measure-axis:` 배당대로 CI `posix` 레그가 판정합니다. 로컬 sh는 Part F · G · U만 돌렸습니다. |
| 6 | 충족 | 아래 되돌림 표 — 기준이 든 교란 아홉이 모두 있고(행 이름은 표 아래 대응 목록), 각각 그 판정의 케이스가 두 러너에서 붉었습니다. |
| 7 | 충족 | `git diff --stat -- hooks` 0줄입니다. `git diff --stat -- skills`는 다섯 파일(`cycle` · `impl` · `milestone` · `retro` · `review`)이고 `kickoff` · `fleet` · `fleet-cycle` · `fleet-verify` · `status` · `debug` · `release`는 0줄입니다. 바뀐 줄은 T03에 적은 대로 스킬마다 한 줄(`impl`은 두 줄과 더한 한 줄)입니다. |
| 8 | 충족 | E5에 「M98 결과」 소절이 있고, 사이클 배분의 둘째 항목이 닫힘과 넘긴 결정(판별 · 알림 한 줄)을 적습니다. 조각 머리는 「스킬이 소비하는 것은 읽기 항목뿐」으로 바뀌었습니다. |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M98-impl.md` |
| 수정 | `docs/conventions-tracker.md` · `docs/conventions.md` · `docs/project-context.md` · `docs/epics/E5.md` · `skills/cycle/SKILL.md` · `skills/impl/SKILL.md` · `skills/review/SKILL.md` · `skills/retro/SKILL.md` · `skills/milestone/SKILL.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` |
| 삭제 | 없음 |

`docs/milestones/M98.md`(추가)와 `docs/epics/E5.md`의 M98 등재 한 줄은 직전 `/tide:milestone` 단계의 미커밋 산출물입니다. 마일스톤이 예상한 `skills/release/SKILL.md`는 바꾸지 않았습니다(개요의 둘째 차이).

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (pwsh 7.7.0 · Windows PowerShell 5.1 · Git Bash sh Part F · G · U · `tests/site-includes` pwsh 7 · mkdocs `--strict` 빌드) | 아래 「마지막 측정」 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — `dash` · `bash`) | 릴리즈 단계에서 PR CI `posix` 레그로 확인 |

**마지막 측정**(이 보고서를 쓴 뒤의 트리):

| 실행 환경 | 명령 | 결과 |
|---|---|---|
| pwsh 7.7.0 | `pwsh -NoProfile -File tests/discover/run.ps1` (전수) | PASS=928 FAIL=0 |
| Windows PowerShell 5.1 | `powershell.exe -NoProfile -File tests/discover/run.ps1` (전수) | PASS=928 FAIL=0 |
| Git Bash sh | `bash tests/discover/run.sh F` | Part F PASS=106 FAIL=0 |
| Git Bash sh | `bash tests/discover/run.sh G` | Part G PASS=37 FAIL=0 |
| Git Bash sh | `bash tests/discover/run.sh U` | Part U PASS=7 FAIL=0 |
| pwsh 7.7.0 | `pwsh -NoProfile -File tests/site-includes/run.ps1` | PASS=57 FAIL=0 |
| mkdocs | `mkdocs build --strict -f site/mkdocs.yml -d {빈 디렉터리}` | 빌드 성공(exit 0) · 산출물에 `tracker-read-items` 3회 |

표의 값은 모두 라운드 1의 값입니다. 두 PowerShell 전수 · 사이트 하니스 · mkdocs는 이 표를 적은 뒤의 트리에서 돌렸습니다. sh 세 파트는 되돌림 표와 후속 메모를 고친 뒤, 이 표를 적기 전의 트리에서 잰 값입니다(그 사이에 바뀐 것은 이 표의 수뿐입니다). sh의 나머지 파트는 로컬에서 돌리지 않았습니다.

**캐시가 아닌 실행의 확인**(`measure-not-cached`): 하니스는 빌드 캐시가 없는 셸 스크립트입니다. 이 트리에서 돈 값이라는 근거는 총계가 이 사이클의 수(직전 태그보다 19 많음)이고 새 케이스 줄 `F83`~`F101`이 출력에 있다는 것입니다. mkdocs는 `-d`로 매번 비운 디렉터리에 빌드했습니다(`Cleaning site directory`).

**생명주기 상태표**(`lifecycle-state-table`) — 새 판정은 등록표 행 8과 손 케이스 11입니다. 판정이 읽는 입력은 넷입니다 — 조각 `docs/conventions-tracker.md`의 선언 줄 · 정의 항목 · 어댑터 표, `skills/{이름}/*.md`와 `skills/` 바로 아래 디렉터리 이름(라운드 1의 단계 이름 대조), `docs/conventions.md`, 러너 소스.
- 전이 표에서 그 입력을 바꾸는 전이는 `tr-downstream`(선언이 없는 대상 레포)뿐입니다. 나머지 전이는 마일스톤 · 보고서 · 버전 파일 · CHANGELOG · 회고 · `.tide/`만 바꾸므로 이 판정에게 항등입니다.
- 스킬 문서와 규약 본체는 사이클의 구현 단계가 고치는 입력이지만 전이 표가 드는 판정 입력이 아닙니다. 그 편집이 판정을 붉히는 경우는 되돌림 표의 행들이 덮습니다.
- 그래서 판정별 격자가 낸 목록 밖 상태는 없습니다.

| 상태 | 사본에서 만든 방법 | 기대 | 실제 (sh · ps1) |
|---|---|---|---|
| ⑴ 사이클 중(`tr-draft` `tr-impl`) | 이 사이클의 편집을 마친 작업 트리 | 초록 | 아래 「마지막 측정」 |
| ⑵ · ⒇ · `st-fail-then-draft` | 해당 없음(리뷰 보고서 · 다음 마일스톤만 늘어난다 — 이 판정이 읽지 않는 입력) | — | ⑴과 같다 |
| ⑶ · ⑷ · ⑸ · ⑾ · ⒂ · ⒃ · ⒄ | 해당 없음(버전 파일 · CHANGELOG · 릴리즈 표지 · 태그 · 회고만 바뀐다) | — | ⑴과 같다 |
| ⑹ · ⑺ · ⑻ | 해당 없음(마일스톤 문서 · 에픽 등재만 바뀐다) | — | ⑴과 같다 |
| ⑼ · ⑽ · ⒀ · ⒁ · ⒆ | 해당 없음(debug 보고서 · `.tide/` · 버전 파일만 바뀐다) | — | ⑴과 같다 |
| ⑿ 파트 선택 실행(`tr-part-select`) | 되돌림 행과 기준 사본 모두 `run.sh F` · `run.ps1 F`로 돌렸습니다 | 기준 사본 Part F 초록 · 행마다 기대 케이스가 붉음 | 아래 되돌림 표 |
| ⒅ 대상 레포에서 처음 도는 릴리즈(`tr-downstream`) | 해당 없음 — 하니스는 이 저장소에서만 돕니다. 대상 레포에서는 스킬이 설치본의 조각을 읽고, 이 판정이 도는 값이 없습니다 | — | — |

## 되돌림 실측

각 행은 이 사이클의 편집을 마친 작업 트리를 `.git` 없이 복사한 사본 하나에 변이 **하나**를 건 것입니다. 사본마다 `pwsh -NoProfile -File tests/discover/run.ps1 F`와 Git Bash `bash tests/discover/run.sh F`를 차례로 돌렸습니다. 드라이버는 scratchpad의 파이썬 스크립트 하나이고, 변이가 파일을 바꾸지 못하면 그 행을 오류로 적게 했습니다.

기준 사본(변이 없음)은 두 러너 모두 라운드 0에 Part F 105/0, 라운드 1에 106/0이었습니다(전수에서만 도는 `F1`은 파트 선택 실행에 들지 않습니다). 결과 칸에 「(라운드 1)」이 붙은 열세 행은 라운드 1의 트리에서 잰 값이고, 붙지 않은 열일곱 행은 라운드 0의 값입니다(리뷰 라운드 1이 수를 바로잡았습니다 — 기준 사본은 표의 행이 아닙니다)(그때의 Part F는 105 케이스였습니다).

<!-- reversal-table:start -->
<!-- reversal-table-main: F85 F86 F87 F88 F92 F93 F94 F95 F96 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| r-rd-dup | `tracker-read-items:` 선언 끝에 첫 이름 `rd-cycle-latest`를 한 번 더 | broken | F85 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| r-rd-def | `rd-cycle-doc` 정의 항목을 지움 | broken | F86 | sh F 104/1 · ps1 F 104/1 |
| r-rd-orphan | 마지막 정의 뒤에 선언에 없는 `rd-zz` 정의를 더함 | broken | F87 | sh F 104/1 · ps1 F 104/1 |
| r-rd-order | 정의 항목 `rd-cycle-latest` · `rd-cycle-doc`의 차례를 바꿈(이름 · 정의는 그대로) | adversarial | F88 | sh F 104/1 · ps1 F 104/1 |
| r-rd-row | 어댑터 표의 `rd-cycle-all` 행을 지움 | broken | F92 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| r-rd-addrow | 어댑터 표 끝에 선언에 없는 이름 `rd-zz`의 행을 더함 | broken | F92 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| a-rd-rowname | `rd-cycle-all` 행의 이름을 `rd-cycle-doc`로 바꿈(행 수는 그대로 · 든 이름은 모두 선언된 것) | adversarial | F92 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| a-rd-row-tight | 어댑터 표 끝에 선언에 없는 이름의 행을 첫 세로줄 뒤 공백 없이 더함(`rd-zz`) | adversarial | F92 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| a-rd-row-indent | 같은 행을 앞 공백 둘을 두고 더함 | adversarial | F92 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| a-rd-row-bare | 같은 행을 이름에 백틱 없이 더함 | adversarial | F92 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| r-rd-stray | `skills/status/SKILL.md` 끝에 선언에 없는 백틱 토큰 `rd-zz` 한 줄 | broken | F93 | sh F 104/1 · ps1 F 104/1 |
| r-rd-unused | `skills/retro/SKILL.md`의 유일한 소비 토큰 `rd-cycle-all`을 산문으로 바꿈 | broken | F94 | sh F 104/1 · ps1 F 104/1 |
| a-rd-bare | 같은 토큰에서 백틱만 벗김(이름 글자는 그대로 남는다) | adversarial | F94 | sh F 104/1 · ps1 F 104/1 |
| r-rd-path | 경로 선언에 없는 `skills/status/SKILL.md`에 `docs/milestones/M1.md` 한 줄 | broken | F95 | sh F 104/1 · ps1 F 104/1 |
| a-rd-path-aux | 경로 선언에 없는 스킬의 보조 문서 `skills/review/refutation.md`에 `docs/epics/E1.md` 한 줄 | adversarial | F95 | sh F 104/1 · ps1 F 104/1 |
| r-rd-dropsite | `tracker-path-sites:`에서 `fleet=signal`을 지움 | broken | F95 | sh F 104/1 · ps1 F 104/1 |
| a-rd-class | `tracker-path-sites:`의 `cycle=write`를 셋 밖의 부류 `cycle=read`로 바꿈 | adversarial | F95;F99 | sh F 103/2 · ps1 F 103/2 |
| r-rd-op | `tracker-phase-writes:`의 `status=to-read`를 `status=to-zz`로 바꿈 | broken | F96 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| a-rd-noeq | `tracker-phase-writes:`의 `fleet=to-read`를 `=` 없는 `fleet`로 바꿈 | adversarial | F96 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| r-rd-phase | `tracker-phase-writes:`의 `status=to-read`를 스킬이 아닌 이름 `zz=to-read`로 바꿈 | broken | F96 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| r-rd-line | `tracker-read-items:` 선언 줄을 한 번 더 적음 | broken | F25;F83 | sh F 103/2 · ps1 F 103/2 |
| r-rd-tab | `tracker-read-items:` 꼬리의 첫 공백을 탭으로 바꿈 | broken | F26;F84 | sh F 103/2 · ps1 F 103/2 |
| r-ps-line | `tracker-path-sites:` 선언 줄을 한 번 더 적음 | broken | F25;F89 | sh F 103/2 · ps1 F 103/2 |
| r-ps-tab | `tracker-path-sites:` 꼬리의 첫 공백을 탭으로 바꿈 | broken | F26;F90 | sh F 103/2 · ps1 F 103/2 |
| n-table | 러너의 표 대응 헬퍼(`rd_table_bad` · `RdTableBad`)가 늘 0을 내게 함 | broken | F97;F101 | sh F 104/2 · ps1 F 104/2 (라운드 1) |
| n-stray | 잔재 헬퍼(`rd_stray` · `RdStray`)가 늘 0을 내게 함 | broken | F98 | sh F 104/1 · ps1 F 104/1 |
| n-unused | 소비처 헬퍼(`rd_unused` · `RdUnused`)가 늘 0을 내게 함 | broken | F98 | sh F 104/1 · ps1 F 104/1 |
| n-site | 박힌 경로 헬퍼(`rd_site_bad` · `RdSiteBad`)가 늘 0을 내게 함 | broken | F99 | sh F 104/1 · ps1 F 104/1 |
| n-phase | 연산 소속 헬퍼(`rd_phase_bad` · `RdPhaseBad`)가 늘 0을 내게 함 | broken | F100 | sh F 105/1 · ps1 F 105/1 (라운드 1) |
| n-tokens | 토큰 추출 헬퍼(`rd_tokens` · `RdTokens`)가 아무것도 내지 않게 함 | broken | F91;F94;F98 | sh F 103/3 · ps1 F 103/3 (라운드 1) |

<!-- reversal-table:end -->

**완료 기준 6의 교란 아홉과 행의 대응**: 이름을 두 번 → `r-rd-dup` · 정의 항목 삭제 → `r-rd-def` · 표 행 삭제 → `r-rd-row` · 선언에 없는 이름의 행 → `r-rd-addrow` · 선언되지 않은 토큰 → `r-rd-stray` · 소비자 전부 삭제 → `r-rd-unused` · 선언에 없는 스킬에 경로 → `r-rd-path` · 선언에서 스킬 삭제 → `r-rd-dropsite` · 연산 토큰 바꿈 → `r-rd-op`. 아홉 모두 그 판정의 케이스 하나만 두 러너에서 붉었습니다.

**실측 중 고친 것 하나**: 첫 실측에서 `r-rd-dup`이 `F97;F85`로 붉었습니다. 표 대응 헬퍼가 중복된 선언 이름을 두 번 세어, 통제 `F97`의 「행 하나를 지운 사본」이 차이 2를 냈기 때문입니다. 헬퍼가 서로 다른 이름만 세도록 두 러너를 고쳤고(중복 자체는 `F85`가 뭅니다), 그 헬퍼를 지나는 행 넷(`r-rd-dup` · `r-rd-row` · `a-rd-rowname` · `n-table`)과 기준 사본을 다시 쟀으며 `r-rd-addrow`도 고친 뒤에 쟀습니다. 위 표의 그 다섯 행은 고친 뒤의 값입니다. 나머지 스물한 행은 고치기 전의 트리에서 잰 값이고, 그 사이에 바뀐 것은 그 헬퍼 한 줄씩뿐입니다(이 문단의 수는 라운드 0의 26행 표 기준입니다).

**라운드 1에서 다시 잰 범위**: 라운드 1이 고친 헬퍼는 행 추출(`rd_rows` · `RdRows`)과 연산 소속(`rd_phase_bad` · `RdPhaseBad`) 둘입니다. 그 둘을 지나는 행 아홉과 기준 사본(`r-rd-dup` · `r-rd-row` · `r-rd-addrow` · `a-rd-rowname` · `r-rd-op` · `a-rd-noeq` · `n-table` · `n-phase` · `n-tokens`)을 다시 쟀고, 새 행 넷(`a-rd-row-tight` · `a-rd-row-indent` · `a-rd-row-bare` · `r-rd-phase`)을 더했습니다. 새 행 넷은 각각 그 판정의 케이스 하나만 두 러너에서 붉었습니다. 라운드 0의 트리에서는 `a-rd-row-*` 세 꼴이 초록으로 지나갔습니다(리뷰 라운드 0의 반증 패스 실측). 나머지 열일곱 행은 그 두 헬퍼를 지나지 않아 다시 재지 않았습니다. 통제 `F101`은 `n-table`에서 `F97`과 함께 붉었습니다.

**함께 붉는 행**: `a-rd-class`는 부류 값이 셋 밖이면 통제 `F99`의 기준값이 달라져 함께 붉습니다. `F95`가 혼자 붉는 행은 `r-rd-path` · `a-rd-path-aux` · `r-rd-dropsite` 셋입니다. `n-tokens`는 추출이 비면 추출 통제 `F91`과 그 추출에 기대는 `F94` · `F98`이 함께 붉습니다. `F93`은 그때 초록입니다 — 토큰이 없으면 잔재도 없기 때문이고, 그 공허한 초록을 `F91`이 붉음으로 알립니다.

**본 검사 목록에 넣지 않은 행**: `count` · `seps` 네 행(`F83` · `F84` · `F89` · `F90`)은 선언 위생 행이라 목록에 넣지 않았습니다. 위 `r-*-line` · `r-*-tab` 행에서 각각 `F25` · `F26`과 함께 붉었습니다. 이 넷이 혼자 붉는 사본(M97의 「선언 절을 본체로 옮김」 같은 것)은 이번에 만들지 않았습니다 — 못 하는 것이 아니라 하지 않은 것입니다.

**초록으로 지나가는 편집(경계)**: 박힌 경로 판정 `F95`는 스킬 단위입니다. 경로 선언에 이미 든 스킬(`cycle` · `milestone` · `release` 등) 안에 계획 문서를 읽는 경로를 다시 적어도 붉지 않습니다. 선언의 부류 값(`write` · `signal` · `cite`)이 실제 줄의 쓰임과 맞는지도 기계가 묻지 않습니다. 이 둘은 리뷰가 T01 재고표와 견주어 보는 자리입니다.

## 미해결·후속 메모

1. **스킬을 실제로 돌려 포인터가 같은 파일로 이어지는지는 재지 않았습니다.** 대조는 문면과 표를 견준 것입니다. 이 저장소의 다음 사이클(`/tide:review M98`부터)이 바뀐 스킬의 첫 실사용이지만, 설치본이 `2.59.1`인 동안은 옛 문면이 돕니다. 릴리즈 뒤 설치본이 올라간 첫 사이클에서 확인됩니다.
2. **경로 판정은 스킬 단위입니다.** `tracker-path-sites:`에 든 스킬 안에 읽기 경로를 다시 적어도 초록입니다(조각 「묻지 않는 것」). 쓰기 자리가 계약으로 옮겨 가는 사이클(E5 사이클 배분의 셋째)에서 선언이 줄면 이 틈도 함께 줄어듭니다.
3. **`tracker-phase-writes:`의 단계 이름은 스킬 디렉터리 이름과만 대조합니다**(라운드 1). 그 이름이 규약의 커맨드 명단에 있는지, 그 단계에서 실제로 도는 커맨드인지는 묻지 않습니다. 세우지 않은 것이고, 쓰기의 소비자가 서는 사이클이 세울 자리입니다.
4. **판별과 「로컬 문서 모드」 알림 한 줄은 넣지 않았습니다**(마일스톤의 범위 결정). E5 완료 신호의 셋째는 그 알림이 서는 사이클에서 충족됩니다.
5. **소개 문서(`README.md` · `docs/commands.md` · `site/`)의 경로 서술은 그대로입니다.** 하니스의 경로 판정은 `skills/` 안만 봅니다.
6. **마일스톤 문서의 이름 접두(`tr-`)는 고치지 않았습니다.** 이 보고서 개요가 `rd-`로 바꾼 사유를 적습니다.
7. **경로 없이 계획을 읽는 스킬 자리는 이름으로 옮기지 않았습니다**(리뷰 라운드 0이 지목). `cycle`의 의존 표기 읽기와 시작점 갈래, `impl`의 시작 전 검사, `retro`의 릴리즈 표지 읽기, `status`의 다음 커맨드 판단, `milestone` 「파일 위치」 줄의 최대 번호 읽기입니다. 이 목록은 리뷰의 반증 패스가 `마일스톤 문서` · `열린 에픽` 두 낱말로 `skills/`를 찾아 낸 것이고, 그 밖의 낱말로 계획을 가리키는 자리가 더 없는지는 재지 않았습니다. E5 사이클 배분의 셋째가 이어받습니다.
8. **표 행 추출은 조각 전체를 봅니다.** 같은 이름의 행을 든 둘째 어댑터 표를 세우면 `F92`가 붉습니다(붉는 방향). 어댑터 표를 늘리는 사이클이 추출을 표 단위로 고쳐야 합니다. 첫 칸이 `rd-`로 시작하지 않는 행은 행으로 세지 않습니다.
