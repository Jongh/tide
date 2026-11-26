# tide 트래커 계약 규약 (conventions-tracker)

사이클 계획을 레포의 이슈 트래커에 두는 계약이다 — 규약 본체 `docs/conventions.md`에서 분리한 **조각**이며,
규약 문서 집합의 일부다. 방향과 근거는 에픽 `docs/epics/E5.md`가 들고, 이 조각은 그 방향이 쓰는 **이름**을 선언한다.
조각과 본체의 관계·인용 규칙은 `docs/conventions.md`의 "상호참조 무결성" 절이 정한다.

<!-- 아래 [start:body]~[end:body]는 사이트(site/docs/conventions-tracker.md)가 pymdownx.snippets로
     본문만 인클루드하기 위한 마커다. 위 도입 문단은 일부러 마커 밖에 두어 사이트에서는
     사이트 전용 도입부로 대체된다. 렌더에는 영향 없음. -->
<!-- --8<-- [start:body] -->
## 트래커 계약

**스킬이 소비하는 것은 아래 「읽기 항목」과 「판별 순서」다**(M98 · M99). 쓰기 · 대응 기록 · 유입 선별은 아직 어떤 스킬도 소비하지 않는다. 연결 설정이 없는 레포에서 읽는 파일과
고르는 규칙은 이 절이 서기 전과 같다 — 달라진 것은 출력의 알림 한 줄이다. 연결 설정이 GitHub을 적은 레포는 읽기 항목을 이슈에서 읽지만, 쓰기는 아직 로컬 문서에만 한다. 나머지 선언이 하는 일은 실측(M97 · `docs/reports/M97-impl.md`)이
확인한 대응을 이름으로 고정하는 것이다 — 다음 사이클들이 다시 정하지 않게 한다.

### 연산

스킬과 하니스는 플랫폼이 아니라 아래 연산만 안다. 플랫폼마다의 구현(어댑터)이 이 이름을 구현한다.

  - `tracker-ops:` to-detect to-read to-write to-map

  - **`to-detect`** — 이 레포의 트래커가 무엇이고 닿는가를 판정한다. 갈래는 아래 `tracker-detect-steps:`가 든다.
  - **`to-read`** — 열린 에픽 이슈 · 최대 번호 사이클 이슈 · 그 태스크 체크리스트와 상태 · 외부 이슈와 보류 이슈를 읽는다. 부수효과가 없다.
  - **`to-write`** — 에픽 · 사이클 이슈를 만들고, 체크리스트 상태를 바꾸고, 라벨을 붙이고, 이슈를 닫고, 링크 · 판정 · 흡수 댓글 한 줄을 단다.
    외부에 보이는 부수효과라 단계마다 쓸 수 있는 범위가 아래 `tracker-phase-writes:`로 정해진다.
  - **`to-map`** — 로컬 키(`E5` · `M97` · `M97-T01`)와 트래커 항목 번호의 짝을 읽고 쓴다. 변환의 멱등이 이 기록에 기댄다.

### 읽기 항목

`to-read`가 돌려주는 것을 항목으로 가른다. 스킬이 계획 문서의 **경로를 적어 읽던 자리**는 경로 대신 **이 이름으로 가리킨다**(M98) — 어디서 어떻게
읽는지는 어댑터가 정하고, 그 자리의 문면은 어댑터가 늘어도 그대로다. 경로 없이 「마일스톤 문서」 · 「태스크 목록」 같은 말로 계획을 읽는 자리에는
M99가 같은 이름을 붙였다 — 문장은 그대로 두고 그 스킬의 한 자리에서 「이 읽기는 이 항목이 돌려준다」로 묶었다. 옮기지 않은 자리는 아래 「묻지 않는 것」이 든다.

  - `tracker-read-items:` rd-cycle-latest rd-cycle-doc rd-cycle-all rd-epic-open

  - **`rd-cycle-latest`** — 번호가 가장 큰 사이클이다. 그 번호와 제목을 돌려주고, 사이클이 하나도 없으면 「없음」이다.
  - **`rd-cycle-doc`** — 번호를 준 사이클 하나의 계획이다. 목표 · 배경 · 태스크와 그 의존 · 태스크 상세 · 파일 변경 요약 · 완료 기준 · 메타데이터(릴리즈 표지 포함)를 돌려주고, 그 번호의 사이클이 없으면 「없음」이다.
  - **`rd-cycle-all`** — 모든 사이클의 계획이다. 사이클마다 `rd-cycle-doc`이 돌려주는 것과 같다.
  - **`rd-epic-open`** — 열린 에픽 전부다. 에픽마다 본문과 속한 사이클 목록을 돌려주고, 열린 에픽이 없으면 「없음」이다.

**어댑터** — 읽는 법을 든 표가 어댑터마다 하나다. 어댑터의 이름은 아래 선언이 들고, 레포의 연결 설정(아래 「판별 순서」의 `td-explicit`)이 적는 값도 이 이름이다.
어느 표로 읽을지는 판별이 정한다.

  - `tracker-adapters:` local github

표마다 바로 위에 ASCII 표지 한 줄 `<!-- tracker-adapter:{이름} -->`을 둔다. 표는 그 표지 다음에 오는 **행의 연속**이다 — 표지와 첫 행 사이의 빈 줄은 건너뛰고,
행이 시작된 뒤 행이 아닌 첫 줄에서 끝난다.

**로컬 문서 어댑터** — 첫 구현이다. 판별이 로컬 문서 모드로 끝난 레포가 이 표로 읽는다.

<!-- tracker-adapter:local -->

| 항목 | 로컬 문서에서 읽는 법 |
|---|---|
| `rd-cycle-latest` | `docs/milestones/M*.md` 중 번호가 가장 큰 문서 — 파일 이름의 번호와 첫 줄 제목 |
| `rd-cycle-doc` | `docs/milestones/M{N}.md` — 번호 `{N}`을 준 그 문서 하나 |
| `rd-cycle-all` | `docs/milestones/M*.md` 전부 |
| `rd-epic-open` | `docs/epics/E*.md` 중 메타데이터가 `status: open`인 문서 — 속한 사이클은 「속한 마일스톤」 블록 |

경로는 대상 레포 루트 기준이다. 대상 레포에 이 조각이 없으면 플러그인 설치본의 이 표를 읽는다 — 도달 규칙의 단일 원본은
`docs/conventions.md`의 "멀티 레포 / 대상 레포" 절이다. 유입 읽기(외부 이슈 · 보류 이슈)는 로컬 문서에 자리가 없어 항목으로 두지 않았다.

**GitHub 어댑터** — 둘째 구현이다(M99). 판별이 `github`로 끝난 레포가 이 표로 읽는다. 명령은 대상 레포 루트에서 돌고, 라벨 이름은 아래 `tracker-labels:` 선언의 것이다.

<!-- tracker-adapter:github -->

| 항목 | GitHub에서 읽는 법 |
|---|---|
| `rd-cycle-latest` | `gh issue list --label tide:cycle --state all --limit 1000 --json number,title,state` — 제목이 `M{N}`과 공백으로 시작하는 이슈 가운데 `{N}`이 가장 큰 것의 번호와 제목 |
| `rd-cycle-doc` | 같은 목록에서 제목이 `M{N}`과 공백으로 시작하는 이슈 하나를 골라 `gh issue view {이슈 번호} --json number,title,body,state` — 본문을 아래 「사이클 이슈 본문의 읽기 꼴」로 읽는다 |
| `rd-cycle-all` | 같은 목록의 이슈 전부를 `rd-cycle-doc`과 같이 읽는다 |
| `rd-epic-open` | `gh issue list --label tide:epic --state open --limit 1000 --json number,title,body` — 속한 사이클은 `gh api repos/{owner}/{repo}/issues/{이슈 번호}/sub_issues`가 든 이슈와 본문 체크리스트의 `#{번호}` 참조를 합친 것이다 |

**사이클 이슈 본문의 읽기 꼴** — 구획의 제목은 로컬 마일스톤 문서와 같다. `## 목표` · `## 태스크 목록` · `## 완료 기준` · `## 메타데이터`는 있어야 하고,
`## 배경` · `## 태스크 상세` · `## 파일 변경 요약`은 있으면 읽는다. 태스크는 `## 태스크 목록`의 체크리스트 줄(`- [ ] M{N}-T01: … (deps: …)`)이고 체크가 그 태스크의 완료 상태다.
릴리즈 표지는 `## 메타데이터`의 `- released:` 줄로 읽는다 — 이슈의 닫힘은 사람이 손으로 할 수 있어 릴리즈와 같지 않다.
**읽지 못하면 「없음」으로 넘기지 않는다** — 있어야 하는 구획을 찾지 못했거나 같은 `M{N}`으로 시작하는 이슈가 둘 이상이면, 어느 이슈의 무엇을 찾지 못했는지 알리고 멈춘다.
이 꼴의 이슈를 만드는 쓰기는 아직 없다 — 이 표의 실측(M99)은 손으로 만든 이슈로 쟀다.

**M99 실측이 정한 것** — 기록은 `docs/reports/M99-recordings/`에 있고 대조표는 `docs/reports/M99-impl.md`가 든다.

- **속한 사이클은 두 출처를 합친다.** 에픽 이슈에 sub-issue가 하나 달려 있고 다른 사이클은 체크리스트에만 있는 상태에서, 「sub-issue 목록이 비면 체크리스트」로 읽으면 뒤쪽 사이클이 빠졌다.
- **목록은 방금 만든 이슈를 바로 내지 않을 수 있다.** 이슈 둘을 만든 직후의 목록에는 둘 다 없었고 몇 초 뒤의 목록에는 있었다(한 번 관측). 읽기만 하는 지금은 드러나지 않지만,
  만든 직후에 읽는 쓰기 사이클은 만든 이슈의 번호를 목록이 아니라 만들기 응답에서 받아야 한다.
- **권한 없는 저장소와 없는 저장소는 가르지 않는다.** 없는 저장소는 `gh repo view`가 「Could not resolve to a Repository」로 끝났다. 남의 비공개 저장소의 응답은 재지 못했고, 둘 다 `tl-denied`로 둔다.
- **미인증은 두 꼴이다.** 인증 정보가 아예 없으면 `gh auth status`가 종료 코드 1이고 `gh repo view`는 4다. 틀린 토큰이 환경 변수에 있으면 둘 다 1이고 뒤쪽이 `HTTP 401`을 낸다. 어느 쪽이든 `gh auth status`가 먼저 실패하므로 `tl-unauth`다.

**스킬에 남은 경로** — 계획 문서 경로를 적어도 되는 스킬은 아래 선언이 든다. 토큰은 `{스킬 이름}={분류}[,{분류}…]`이고 분류는
셋이다. `write`는 문서를 만들거나 고치는 자리(`to-write`가 서는 사이클의 몫), `signal`은 레포가 tide 레포인지 가리는 발견 신호,
`cite`는 git 경로 조회와 작업 트리 확인 · 산출물 자리 서술이다. 여기 없는 스킬은 그 경로를 적지 않는다.

  - `tracker-path-sites:` cycle=write fleet=signal fleet-cycle=signal,cite fleet-verify=signal kickoff=signal,write milestone=write,cite release=write,cite

### 판별 순서

  - `tracker-detect-steps:` td-explicit td-remote td-reach td-local

  - **`td-explicit`** — 레포의 연결 설정 `.tide/tracker`를 읽는다. 한 줄짜리 파일이고 값은 위 `tracker-adapters:`의 이름이다. 값이 `local`이면 로컬 문서 모드로 결론을 내고,
    다른 어댑터 이름이면 그 플랫폼을 들고 다음 갈래로 간다. 파일이 없을 때의 결론은 아래 `tracker-connect:`가 정한다. 레포에 커밋하는 설정이다 — 같은 레포를 쓰는 사람이 같은 원본을 읽어야 한다.
    호스트 · 프로젝트를 따로 적는 꼴은 GitLab 어댑터가 서는 사이클이 더한다.
  - **`td-remote`** — `origin` URL의 호스트로 플랫폼을 본다. 설정이 플랫폼을 적었으면 호스트가 그 플랫폼의 것인지 확인하는 자리이고, 설정 없이 호스트만으로 추론하는 것은
    아래 연결 조건이 그것을 허용할 때다. GitHub 호스트면 GitHub이고, 그 호스트의 `/api/v4/version`이
    토큰을 실은 요청에 200과 `version` 필드를 내면 GitLab이다(M97 실측 — 토큰이 없거나 틀리면 같은 자리가 401이라 판별이 `td-reach`와 겹친다).
  - **`td-reach`** — 플랫폼이 정해지면 인증과 그 프로젝트의 읽기 권한을 확인한다. 실패의 꼴(미인증 · 권한 없음 · 응답 없음)을
    가려 둔다 — 다음 갈래의 알림 문구가 그 사유를 쓴다. GitLab 14.9는 비공개 프로젝트를 토큰 없이 읽으면 401이 아니라 404를 낸다(M97 실측).
    그래서 404만으로 「없는 프로젝트」와 「미인증」을 가르지 못하고, `/version`의 401을 먼저 본다.
  - **`td-local`** — 앞의 갈래가 트래커로 결론을 내지 못하면 로컬 문서 모드다. 지금의 `docs/epics/` · `docs/milestones/` 동작 그대로이고,
    출력에 알림 한 줄을 낸다. 문구는 아래 `tracker-local-reasons:`의 사유마다 정해져 있다.

이름의 순서가 적용 순서다. 처음 결론을 내는 갈래에서 멈춘다.

**연결 조건** — 연결 설정이 없는 레포를 어떻게 볼지는 값 하나가 정한다.

  - `tracker-connect:` explicit

`explicit`은 「연결 설정이 어댑터를 적은 레포만 트래커에서 읽는다」다. 설정이 없으면 `td-explicit`이 곧바로 로컬 문서 모드로 결론을 내고 `td-remote` · `td-reach`는 돌지 않는다.
쓰기가 서기 전에 읽기만 트래커로 가면 계획이 이슈와 로컬 문서 두 벌로 갈리기 때문이다 — `origin`이 GitHub이라는 사실만으로 연결하면 이미 tide를 쓰는 레포가 빈 트래커를 읽는다.
쓰기가 서는 사이클이 이 값을 다시 정한다.

**판별 절차** — 갈래마다 확인하는 법과, 로컬 문서 모드로 끝날 때 내는 사유다. 스킬은 이 표를 따르고 갈래와 명령을 다시 적지 않는다.

<!-- tracker-detect-table -->

| 갈래 | 확인하는 법 | 결론 | 로컬 문서 모드로 끝날 때의 사유 |
|---|---|---|---|
| `td-explicit` | `.tide/tracker`의 첫 줄을 읽는다(앞뒤 공백과 줄 끝 CR을 벗긴다) | 값이 `local`이면 로컬 문서 모드 · 파일이 없으면 연결 조건대로 로컬 문서 모드 · 값이 다른 어댑터 이름이면 다음 갈래로 | `tl-forced` · `tl-unset` · `tl-unsupported`(값이 어댑터 이름이 아니다) |
| `td-remote` | `git remote get-url origin`의 호스트를 본다 | 설정이 `github`이고 호스트가 `github.com`이거나 `gh auth status`가 든 호스트면 다음 갈래로 · GitLab 판정은 아직 없다 | `tl-unsupported`(`origin`이 없다 · 호스트가 설정한 플랫폼의 것이 아니다) |
| `td-reach` | `gh`의 가용 · 인증 · 저장소 조회를 차례로 본다 — 명령은 `docs/conventions-release.md`의 "검증 게이트" 절이 든 것과 같다 | 셋이 모두 통과하면 설정이 적은 어댑터로 읽는다 | `tl-no-response`(`gh`가 없다 · 응답이 없다) · `tl-unauth` · `tl-denied` |
| `td-local` | 앞 갈래가 낸 사유를 받는다 | 로컬 문서 어댑터로 읽고 알림 한 줄을 낸다 | — |

**알림** — 로컬 문서 모드로 끝나면 출력에 한 줄을 낸다. 실행 한 번에 한 번이다 — 스킬이 다른 스킬의 단계를 이어 돌아도 다시 내지 않는다.

  - `tracker-local-reasons:` tl-unset tl-forced tl-unsupported tl-unauth tl-denied tl-no-response

  - **`tl-unset`** — 연결 설정이 없다. 문구는 「로컬 문서 모드(트래커 연결 설정 없음)」다. tide를 쓰는 레포 대부분이 보는 줄이라 가장 짧다.
  - **`tl-forced`** — 설정이 `local`이다. 문구는 「로컬 문서 모드(설정으로 고정)」다.
  - **`tl-unsupported`** — 설정한 플랫폼을 쓸 수 없다. 값이 어댑터 이름이 아니거나, `origin`이 없거나, 그 호스트가 설정한 플랫폼의 것이 아니다.
    문구는 「트래커 미연결 — 로컬 문서로 관리합니다(설정한 플랫폼을 쓸 수 없음: {값 또는 호스트})」다.
  - **`tl-unauth`** — 플랫폼에 인증돼 있지 않다. 문구는 「트래커 미연결 — 로컬 문서로 관리합니다(미인증)」이다.
  - **`tl-denied`** — 인증은 됐지만 그 저장소를 읽지 못한다. 권한이 없거나 저장소가 없는 것이고, 응답으로 둘을 가르지 못하면 가르지 않는다.
    문구는 「트래커 미연결 — 로컬 문서로 관리합니다(저장소를 읽지 못함)」이다.
  - **`tl-no-response`** — `gh`가 없거나 응답이 오지 않는다. 문구는 「트래커 미연결 — 로컬 문서로 관리합니다(응답 없음)」이다.

**판별을 부르는 스킬** — 계획을 읽기 전에 판별을 하는 스킬이다. 읽기 항목을 이름으로 소비하는 스킬은 모두 여기 든다.

  - `tracker-detect-sites:` cycle impl milestone retro review status

스킬은 이 절의 `tracker-detect-steps:`를 가리키는 한 문장만 두고 갈래 · 명령 · 문구를 다시 적지 않는다. 여기 없는 스킬은 판별을 하지 않는다 —
`fleet` 계열은 자식 레포를 「상태 확인 항목」 표로 읽되 판별 없이 로컬 문서 어댑터로 읽고, `release`가 계획을 읽는 자리(릴리즈 표지의 대상을 고르는 읽기)도 로컬 문서 그대로다.

설정이 트래커를 적었는데 닿지 않아 로컬 문서 모드로 끝난 실행은 계획을 로컬 문서에서 읽는다. 그 레포의 원본이 트래커라면 읽은 것이 낡았을 수 있으므로,
`tl-unsupported` · `tl-unauth` · `tl-denied` · `tl-no-response`의 문구는 「트래커 미연결」로 시작해 설정 없는 레포의 줄과 갈린다.

### 라벨

  - `tracker-labels:` tide:epic tide:cycle tide:backlog

tide가 트래커에 붙이는 라벨은 이 셋뿐이다. 에픽 추적 이슈 · 사이클 이슈 · 선별됐으나 일정이 없는 외부 이슈에 차례로 붙는다.
이슈에 이미 붙은 다른 라벨은 tide가 붙이거나 떼지 않는다. 라벨이 하나도 없는 열린 이슈가 곧 「tide가 아직 안 본」 외부 이슈다 —
「선별 전」 라벨을 따로 두지 않는다.

### 단계별 쓰기 범위

  - `tracker-phase-writes:` milestone=to-write:create,intake impl=to-write:checklist review=to-write:verdict release=to-write:close status=to-read fleet=to-read

토큰은 `{단계}={연산}[:{범위},…]`이다. 단계에 없는 연산은 그 단계가 부르지 않는다. 트래커 쓰기는 git이 아니라 tide-guard가 보지 못한다 —
이 선언이 그 자리를 대신하는 규약이고, 기계 집행은 소비자가 선 뒤의 일이다(아래 「묻지 않는 것」).
`release`의 `close`는 사이클 이슈와 그 사이클이 흡수한 외부 이슈를 닫는다. `pr` 모드에서는 릴리즈 PR 본문의 `Closes #{번호}`가 머지 때 닫고,
push-only 모드에서는 기본 브랜치 커밋 메시지의 같은 줄이 닫는다(M97 실측 — GitHub · GitLab 14.9 모두 두 경로가 **사이클 이슈 하나**를 닫았다. GitLab은 MR 설명 ·
기본 브랜치 git push 커밋 메시지다. 흡수한 외부 이슈까지 함께 닫는 것은 재지 않았다 — 아래 「정의의 근거」). 기록은 `docs/reports/M97-recordings/`에 있다.

### 유입 선별

다른 작업 중에 등록된 외부 이슈(`tracker-labels:`의 라벨이 하나도 없는 열린 이슈)를 `/tide:milestone`이 후보로 읽을 때, 사용자가
이슈마다 고르는 결론이다. 쓰기는 승인 뒤에만 한다.

  - `tracker-intake-verdicts:` ti-absorb ti-promote ti-defer ti-debug ti-close

  - **`ti-absorb`** — 기본 결론이다. 새 사이클 이슈 본문의 흡수 줄이 그 이슈를 가리키고, 사이클의 닫힘이 함께 닫는다. 외부 이슈에는 흡수 댓글
    한 줄을 단다. 등록자의 제목 · 본문을 고치지 않는다.
  - **`ti-promote`** — 그 이슈 하나가 곧 한 사이클의 크기일 때 `tide:cycle`을 붙여 사이클 이슈로 쓴다. 계획은 본문을 고치지 않고 첫 댓글로 단다.
  - **`ti-defer`** — 받았지만 이번 사이클이 아니다. `tide:backlog`를 붙이고, 들어갈 에픽이 있으면 그 에픽 이슈에 매단다(sub-issue가 있는
    플랫폼은 sub-issue로, 없으면 체크리스트와 `relates_to` 링크로 — GitLab 14.9의 `blocks` 요청은 `relates_to`로 저장된다, M97 실측).
  - **`ti-debug`** — 재현되는 결함이면 `/tide:debug`의 입력으로 넘긴다. debug 보고서가 그 이슈를 가리킨다.
  - **`ti-close`** — 중복 · 대상 밖이면 사유 댓글과 함께 닫는다. 외부에 보이는 부수효과라 매번 승인을 받는다.

**정의의 근거**(M97) — 실측이 닿은 정의는 아래 기록 파일(`docs/reports/M97-recordings/` 안)과 `docs/reports/M97-impl.md`의 T01 · T02 재현표 줄을 근거로 한다.

| 정의 | GitHub 기록 | GitLab 기록 |
|---|---|---|
| `to-read` | `github-03-sub-issues.json` · `github-07a-open-issues.json` | `gitlab-03e-epic-links.json` · `gitlab-07a-open-untagged-notlabels.json` |
| `to-write` | `github-02-epic.json` · `github-04-cycle-checklist.json` | `gitlab-02-epic.json` · `gitlab-04-cycle-checklist.json` · `gitlab-03c-link-relates.json` |
| `td-remote` | `github-08-api-v4-version.json` | `gitlab-01-version.json` · `gitlab-08a-version-notoken.json` · `gitlab-08h-version-notoken-headers.json` |
| `td-reach` | — | `gitlab-08b-version-badtoken.json` · `gitlab-08c-project-missing.json` · `gitlab-08f-project-notoken.json` · `gitlab-08g-project-badtoken.json` |
| `tracker-labels:` | `github-01-label-tide-epic.json` 외 둘 | `gitlab-01-label-tide-epic.json` 외 둘 |
| `ti-absorb`(흡수 댓글 한 줄까지) | — | `gitlab-07b-absorb-note.json` |
| `ti-defer` | `github-07b-backlog-sub-issue.json` | `gitlab-07b-absorb-label.json` · `gitlab-02c-link-blocks.json` |
| `release`의 `close` | `github-06a-pr-close-timeline.json` · `github-06b-push-close-timeline.json` | `gitlab-06a-mr-closes-issues-after.json` · `gitlab-06b-cycle2-state-events.json` |

`ti-absorb`에서 실측이 닿은 것은 **흡수 댓글 한 줄**뿐이다. 「사이클의 닫힘이 함께 닫는다」는 재지 않았다 — 닫힘 실측은 `Closes #N` 한 줄에 이슈 하나씩이었고,
여러 이슈를 한 줄로 닫는 꼴은 두 플랫폼 어디서도 재지 않았다. GitHub 쪽 댓글 응답은 보관하지 않았다. 흡수가 사이클과 함께 닫히는 경로는 유입을 구현하는
사이클(E5 사이클 배분의 「GitHub 어댑터와 유입」)이 잰다. `td-reach`의 GitHub 쪽 응답은 M99가 남겼다 — `docs/reports/M99-recordings/`의 `detect-05`~`detect-09` 기록이고, 위 표는 M97 시점 그대로 둔다.

실측 대상이 아닌 정의는 E5의 결정(`docs/epics/E5.md`)을 근거로 한다 — `to-detect`는 갈래를 묶는 이름이고, `to-map` · `td-explicit` · `td-local` ·
`ti-promote` · `ti-debug` · `ti-close` · 나머지 단계 범위는 트래커의 응답이 아니라 tide 쪽 동작이라 트래커 실측으로 확인할 대상이 없다.

### 응답 보관

트래커의 응답을 저장소에 보관할 때 밟는 절차다(M99 — 회고 행 `rf-127`). 보관한 응답은 뒤 사이클의 가짜 어댑터 입력이 되므로 꼴이 원 응답과 같아야 하고,
저장소에 들어가므로 비밀과 계정 식별자가 없어야 한다. 하니스 네 축이 초록인 채 비밀이 두 라운드를 지난 일이 M97에 있었다.

  - `tracker-record-steps:` rc-raw rc-scan rc-ids rc-control

  - **`rc-raw`** — 원 응답 문자열을 그대로 저장한다. 읽어서 다시 직렬화하지 않는다 — 원소 하나짜리 배열이 객체로, 빈 배열이 `null`로 풀린다(M97 실측). 정제는 문자열 치환으로 하고,
    치환 전후에 최상위 꼴(객체 · 배열과 그 길이)이 같은지 대조한다.
  - **`rc-scan`** — 값 패턴(토큰 값의 꼴)과 키 이름 꼴(이름에 `token` · `secret` · `password` 같은 낱말이 든 키의 값)을 함께 스캔한다. 값 패턴만 보면 응답이 스스로 싣는 비밀 필드를 놓친다.
  - **`rc-ids`** — 계정 이름 · 계정 숫자 ID · 노드 ID · 아바타 URL을 자리표시자로 바꾸고, 바꾸기 전 값의 스캔이 보관본에서 0건인지 확인한다.
  - **`rc-control`** — 스캔 항목마다 양성 통제를 따로 둔다. 합계 한 줄로 두지 않는다 — 원본에서도 0건인 항목은 통제 없이 「0건」이 된다. 원본에 양성이 없는 항목은 합성 입력으로 확인하고 그 사실을 적는다.

항목별 결과와 남긴 식별자는 보관 디렉터리의 `README.md`에 적는다. 남기는 식별자는 보관 전에 사용자에게 보이고 확인받는다. 이 절차로 보관한 디렉터리는 아래 선언이 든다.

  - `tracker-record-dirs:` docs/reports/M99-recordings

그 디렉터리의 기록 파일은 이름이 영숫자 · 점 · 밑줄 · 붙임표만이고 `.json` 또는 `.txt`로 끝난다. `README.md`는 파일마다 그 이름을 백틱으로 한 번 이상 든다.
`docs/reports/M97-recordings/`는 이 절차가 서기 전의 기록이라 여기 들지 않는다(그 README는 이름을 중괄호로 묶어 적는다).

**기계가 묻는 것**(M97 · M98) — 이 조각의 선언 줄이 키마다 정확히 하나이고 꼬리에 금지 구분자가 없다 · 이름 선언(`tracker-ops:` ·
`tracker-detect-steps:` · `tracker-intake-verdicts:` · `tracker-read-items:`)은 이름이 유일하고, 이름마다 정의 항목이 정확히 하나이며 고아 정의가 없고, 정의 항목의
순서가 선언 순서와 같다(`tests/discover` Part F의 등록표 행). 읽기 항목에는 판정이 더 있다(M98) — 선언된 이름마다 어댑터 표의 행이 정확히 하나이고
선언 밖 이름의 행이 없다(행은 앞 공백 · 탭을 벗긴 줄이 세로줄로 시작하고 첫 칸 뒤에 세로줄이 하나 더 있는 줄이고, 이름은 첫 칸에서 공백 · 탭 · 백틱을 벗긴 값이 `rd-`로 시작할 때의 그 값이다 — M99부터 표 단위로 센다) · 스킬 문서(`skills/{이름}/*.md`)와 규약 본체의 백틱 `rd-` 토큰이 전부 선언된 이름이고, 이름마다 그런 소비처가 하나 이상이다 ·
계획 문서 경로(`docs/milestones` · `docs/epics`)를 적은 스킬의 집합이 `tracker-path-sites:`가 든 스킬의 집합과 같고 분류가 `write` · `signal` · `cite` 안이다 ·
`tracker-phase-writes:`의 연산 토큰이 전부 `tracker-ops:`의 이름이고 `=` 앞의 단계 이름이 전부 `skills/` 바로 아래 디렉터리 이름이다.
M99가 더한 판정은 이렇다 — 어댑터 표는 표 단위로 센다(표는 표지 줄 다음에 오는 행의 연속이고, 표 밖의 `rd-` 행은 어긋남이다) · `tracker-adapters:`의 이름마다 어댑터 표지가 정확히 하나이고 선언에 없는 이름의 표지가 없다 ·
판별 절차 표지가 하나이고 `tracker-detect-steps:`의 이름마다 그 표의 행이 정확히 하나이며 선언 밖 갈래의 행이 없다 · 그 표의 행 안 백틱 `tl-` 토큰 집합이 `tracker-local-reasons:`의 이름 집합과 같다 ·
판별 포인터(백틱 `tracker-detect-steps:`)를 든 스킬의 집합이 `tracker-detect-sites:`가 든 집합과 같고 백틱 `rd-` 토큰을 든 스킬이 모두 거기 든다 · 스킬 문서의 백틱 `td-` · `tl-` 토큰이 전부 선언된 이름이다 ·
`tracker-record-dirs:`가 든 디렉터리마다 기록 파일 이름 집합과 그 `README.md`가 백틱으로 든 이름 집합이 같다 · 새 선언 여섯의 줄 수와 꼬리 금지 구분자, 값이 하나인 `tracker-connect:`를 뺀 다섯의 이름 유일, 정의 항목이 있는 둘의 정의 하나 · 고아 정의 0 · 정의 차례. 케이스 목록의 단일 선언처는 `tests/discover/README.md`다.
**묻지 않는 것** — 정의 문장과 어댑터 표의 「읽는 법」이 실제 동작과 같은가 · 스킬이 포인터를 실제로 따라가 그 행을 읽는가 · `tracker-phase-writes:`의 단계 이름이
그 단계에서 실제로 도는 커맨드인가(스킬 디렉터리 이름과만 대조한다 — 규약에 커맨드 명단의 선언 줄이 없어 M99도 대조를 세우지 않았다. 하니스의 커맨드 집합은 `skills/` 디렉터리에서 발견한 것이고 지금의 대조 대상이 그 집합이다) · 쓰기 · 대응 기록 · 유입 선별의 이름을 스킬이 쓰는가(소비자가 아직 없다 — 소비자가 서는 사이클이 판정을 세운다) ·
판별 절차 표의 「확인하는 법」 · 「결론」과 알림 문구가 옳은가 · 스킬이 판별 포인터를 실제로 따라가는가와 알림을 실행 한 번에 한 번만 내는가 · 연결 설정 파일의 값이 `tracker-adapters:`의 이름인가(레포마다의 파일이라 하니스가 읽지 않는다 — 판별의 `tl-unsupported`가 실행 때 받는다) ·
GitHub 어댑터 표의 명령이 실제로 그 값을 내는가(M99 실측은 손으로 만든 이슈 다섯에서 쟀다 — 사이클이 천 개를 넘는 저장소 · 제목이 `M{N}`으로 시작하되 사이클이 아닌 이슈 · 본문의 줄 끝이 CRLF인 이슈 · `gh`가 고르는 기본 저장소가 `origin`과 다른 레포(포크) · sub-issue가 한 쪽을 넘는 에픽은 재지 않았다) · 이슈 본문의 읽기 꼴을 실제 이슈가 지키는가(쓰기가 서는 사이클의 몫이다) ·
보관 기록의 내용(정제가 실제로 됐는가 · README가 적은 스캔 건수가 맞는가) · 권한 없는 저장소의 응답이 없는 저장소의 응답과 같은가(M99가 재지 못했다 — 읽을 수 없는 남의 비공개 저장소가 없었다) · `tracker-connect:`의 값이 무엇이고 몇 개인가(줄 수와 금지 구분자만 묻는다) · `tracker-record-dirs:`에 없는 보관 디렉터리와 선언된 디렉터리의 하위 폴더(선언하지 않으면 README 대응을 묻지 않는다) · 판별 포인터가 스킬의 어느 문서에 있는가. M99의 새 판정 가운데 **통제가 없는 갈래가 넷**이다 — 스킬의 `tl-` 토큰 소속 · 선언에 없는 스킬이 판별 포인터를 든 방향 · 판별 절차 표지의 수 · README가 없는 보관 디렉터리. 판정은 붉지만 러너의 그 분기를 지워도 통제가 붉지 않는다(M99 리뷰가 지목).
경로 판정은 **스킬 단위**다 — `tracker-path-sites:`에 든 스킬 안에 읽기 경로를 다시 적어도, 경로를 적은 줄이 선언한 분류와 다른 종류여도 초록이다(줄 단위로 세면
문장을 다듬을 때마다 붉는다). 백틱 없이 적은 이름, 다른 꼴로 적은 경로(디렉터리 없이 적은 글롭 `M*.md` · `E*.md`, 역슬래시, 조립한 경로), `skills/` 밖의 재서술처(`docs/commands.md` · `README.md` · `site/`)도 보지 않는다.
**경로 없이 계획을 읽는 자리**(M98 리뷰가 지목 · M99가 이름을 붙였다) — `cycle`의 의존 표기 읽기와 「마일스톤 문서가 하나도 없음」, `impl`의 시작 전 검사 · 태스크 상세 · 완료 기준, `review`의 완성도 대조,
`retro`의 메타데이터 읽기, `status`의 확인 항목, `milestone`의 최대 번호 읽기는 그 스킬의 한 문장이 읽기 항목 이름으로 묶는다. 문장마다 토큰을 단 것이 아니라 스킬마다 한 자리에서 묶었으므로, 그 스킬에 계획을 읽는 문장을 더해도 기계는 모른다.
**옮기지 않은 자리** — `release`가 릴리즈 표지의 대상을 고르려고 마일스톤 문서와 그 메타데이터를 읽는 자리(쓰기와 한 절차라 쓰기가 서는 사이클이 함께 옮긴다) · `review`의 반증 패스 문서(`refutation.md`)가 넘기는 「대상 마일스톤」(본 스킬의 한 문장이 덮는다) ·
`fleet` 계열이 자식 레포를 읽는 자리(판별 없이 로컬 문서 어댑터로 읽는다 — 자식 레포마다 판별을 할지는 멀티 레포를 트래커에 올리는 사이클이 정한다) · 이 저장소 하니스가 자기 `docs/milestones/`를 읽는 자리.
첫 칸이 `rd-`로 시작하지 않는 행(이름을 굵게 감싸거나 앞에 전각 공백 · 역슬래시 같은 다른 글자를 둔 행)은 행으로 세지 않는다. 세로줄로 시작하지 않는 줄(앞 세로줄을 뺀 행 · 인용 표지 뒤의 행)과
첫 칸 뒤에 세로줄이 없는 줄도 세지 않는다(M98 리뷰 라운드 1이 지목). `tracker-phase-writes:`의 단계 이름 대조는 점으로 시작하는 디렉터리 이름을 스킬로 보지 않는다.
`tracker-labels:` 안의 라벨 이름이 유일한가도 묻지 않는다 — 등록표가 이 키에 줄 수 · 금지 구분자 행만 두므로 라벨을 두 번 적어도 초록이다. 이 사이클은 판정을 더하지 않고 경계로 남긴다(M97 리뷰가 지목). 소비자가 라벨 목록을 읽게 되는 사이클이 `dup` 행을 더할 자리다.
**정의 사이에 열린 틈 하나** — 「라벨」은 라벨이 하나도 없는 열린 이슈를 「아직 안 본」 외부 이슈로 정하는데, `ti-absorb`는 라벨을 붙이지 않는다. 그래서 흡수한
이슈는 그 사이클이 닫힐 때까지 다음 후보 읽기에 다시 잡힌다. 흡수 줄을 읽어 거를지 라벨을 붙일지는 유입의 소비자가 서는 사이클이 정한다(M97 리뷰 라운드 1이 지목).
<!-- --8<-- [end:body] -->
