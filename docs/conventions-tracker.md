# tide 트래커 계약 규약 (conventions-tracker)

사이클 계획을 레포의 이슈 트래커에 두는 계약이다 — 규약 본체 `docs/conventions.md`에서 분리한 **조각**이며,
규약 문서 집합의 일부다. 방향과 근거는 에픽 `docs/epics/E5.md`가 들고, 이 조각은 그 방향이 쓰는 **이름**을 선언한다.
조각과 본체의 관계·인용 규칙은 `docs/conventions.md`의 "상호참조 무결성" 절이 정한다.

<!-- 아래 [start:body]~[end:body]는 사이트(site/docs/conventions-tracker.md)가 pymdownx.snippets로
     본문만 인클루드하기 위한 마커다. 위 도입 문단은 일부러 마커 밖에 두어 사이트에서는
     사이트 전용 도입부로 대체된다. 렌더에는 영향 없음. -->
<!-- --8<-- [start:body] -->
## 트래커 계약

**스킬이 소비하는 것은 아래 「읽기 항목」뿐이다**(M98). 판별 · 쓰기 · 대응 기록 · 유입 선별은 아직 어떤 스킬도 소비하지 않는다. 읽는 파일과
고르는 규칙은 이 절이 서기 전과 같다 — 스킬이 경로 대신 이름으로 가리키게 됐을 뿐이다. 나머지 선언이 하는 일은 실측(M97 · `docs/reports/M97-impl.md`)이
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
읽는지는 어댑터가 정하고, 그 자리의 문면은 어댑터가 늘어도 그대로다. 경로 없이 「마일스톤 문서」 · 「태스크 목록」 같은 말로 계획을 읽는 자리는
이 사이클의 대상이 아니었다 — 남은 자리는 아래 「묻지 않는 것」이 든다.

  - `tracker-read-items:` rd-cycle-latest rd-cycle-doc rd-cycle-all rd-epic-open

  - **`rd-cycle-latest`** — 번호가 가장 큰 사이클이다. 그 번호와 제목을 돌려주고, 사이클이 하나도 없으면 「없음」이다.
  - **`rd-cycle-doc`** — 번호를 준 사이클 하나의 계획이다. 목표 · 태스크와 그 의존 · 완료 기준 · 메타데이터를 돌려주고, 그 번호의 사이클이 없으면 「없음」이다.
  - **`rd-cycle-all`** — 모든 사이클의 계획이다. 사이클마다 `rd-cycle-doc`이 돌려주는 것과 같다.
  - **`rd-epic-open`** — 열린 에픽 전부다. 에픽마다 본문과 속한 사이클 목록을 돌려주고, 열린 에픽이 없으면 「없음」이다.

**로컬 문서 어댑터** — 첫 구현이고, 지금은 이것 하나다. 모든 레포가 이 표로 읽는다. 판별(`to-detect`)이 다른 결론을 낼 수 있게 되는
사이클이 어댑터 표를 하나 더 세우고, 그때 `td-local`의 알림 한 줄도 함께 선다.

| 항목 | 로컬 문서에서 읽는 법 |
|---|---|
| `rd-cycle-latest` | `docs/milestones/M*.md` 중 번호가 가장 큰 문서 — 파일 이름의 번호와 첫 줄 제목 |
| `rd-cycle-doc` | `docs/milestones/M{N}.md` — 번호 `{N}`을 준 그 문서 하나 |
| `rd-cycle-all` | `docs/milestones/M*.md` 전부 |
| `rd-epic-open` | `docs/epics/E*.md` 중 메타데이터가 `status: open`인 문서 — 속한 사이클은 「속한 마일스톤」 블록 |

경로는 대상 레포 루트 기준이다. 대상 레포에 이 조각이 없으면 플러그인 설치본의 이 표를 읽는다 — 도달 규칙의 단일 원본은
`docs/conventions.md`의 "멀티 레포 / 대상 레포" 절이다. 유입 읽기(외부 이슈 · 보류 이슈)는 로컬 문서에 자리가 없어 항목으로 두지 않았다.

**스킬에 남은 경로** — 계획 문서 경로를 적어도 되는 스킬은 아래 선언이 든다. 토큰은 `{스킬 이름}={분류}[,{분류}…]`이고 분류는
셋이다. `write`는 문서를 만들거나 고치는 자리(`to-write`가 서는 사이클의 몫), `signal`은 레포가 tide 레포인지 가리는 발견 신호,
`cite`는 git 경로 조회와 작업 트리 확인 · 산출물 자리 서술이다. 여기 없는 스킬은 그 경로를 적지 않는다.

  - `tracker-path-sites:` cycle=write fleet=signal fleet-cycle=signal,cite fleet-verify=signal kickoff=signal,write milestone=write,cite release=write,cite

### 판별 순서

  - `tracker-detect-steps:` td-explicit td-remote td-reach td-local

  - **`td-explicit`** — 레포의 `.tide/` 아래 트래커 설정(플랫폼 · 호스트 · 프로젝트 · 로컬 강제)이 있으면 그것을 따른다.
  - **`td-remote`** — 설정이 없으면 `origin` URL의 호스트로 플랫폼을 추론한다. GitHub 호스트면 GitHub이고, 그 호스트의 `/api/v4/version`이
    토큰을 실은 요청에 200과 `version` 필드를 내면 GitLab이다(M97 실측 — 토큰이 없거나 틀리면 같은 자리가 401이라 판별이 `td-reach`와 겹친다).
  - **`td-reach`** — 플랫폼이 정해지면 인증과 그 프로젝트의 읽기 권한을 확인한다. 실패의 꼴(설정 없음 · 미인증 · 권한 없음 · 응답 없음)을
    가려 둔다 — 다음 갈래의 알림 문구가 그 사유를 쓴다. GitLab 14.9는 비공개 프로젝트를 토큰 없이 읽으면 401이 아니라 404를 낸다(M97 실측).
    그래서 404만으로 「없는 프로젝트」와 「미인증」을 가르지 못하고, `/version`의 401을 먼저 본다.
  - **`td-local`** — 앞의 갈래 가운데 하나라도 결론을 내지 못하면 로컬 문서 모드다. 지금의 `docs/epics/` · `docs/milestones/` 동작 그대로이고,
    출력에 「트래커 미연결 — 로컬 문서로 관리합니다」와 그 사유를 한 줄로 알린다.

이름의 순서가 적용 순서다. 처음 결론을 내는 갈래에서 멈춘다.

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
사이클(E5 사이클 배분의 「GitHub 어댑터와 유입」)이 잰다.

실측 대상이 아닌 정의는 E5의 결정(`docs/epics/E5.md`)을 근거로 한다 — `to-detect`는 갈래를 묶는 이름이고, `to-map` · `td-explicit` · `td-local` ·
`ti-promote` · `ti-debug` · `ti-close` · 나머지 단계 범위는 트래커의 응답이 아니라 tide 쪽 동작이라 트래커 실측으로 확인할 대상이 없다.

**기계가 묻는 것**(M97 · M98) — 이 조각의 선언 줄이 키마다 정확히 하나이고 꼬리에 금지 구분자가 없다 · 이름 선언(`tracker-ops:` ·
`tracker-detect-steps:` · `tracker-intake-verdicts:` · `tracker-read-items:`)은 이름이 유일하고, 이름마다 정의 항목이 정확히 하나이며 고아 정의가 없고, 정의 항목의
순서가 선언 순서와 같다(`tests/discover` Part F의 등록표 행). 읽기 항목에는 판정이 더 있다(M98) — 선언된 이름마다 로컬 문서 어댑터 표의 행이 정확히 하나이고
선언 밖 이름의 행이 없다(행은 앞 공백 · 탭을 벗긴 줄이 세로줄로 시작하고 첫 칸 뒤에 세로줄이 하나 더 있는 줄이고, 이름은 첫 칸에서 공백 · 탭 · 백틱을 벗긴 값이 `rd-`로 시작할 때의 그 값이다 — 조각 전체에서 본다) · 스킬 문서(`skills/{이름}/*.md`)와 규약 본체의 백틱 `rd-` 토큰이 전부 선언된 이름이고, 이름마다 그런 소비처가 하나 이상이다 ·
계획 문서 경로(`docs/milestones` · `docs/epics`)를 적은 스킬의 집합이 `tracker-path-sites:`가 든 스킬의 집합과 같고 분류가 `write` · `signal` · `cite` 안이다 ·
`tracker-phase-writes:`의 연산 토큰이 전부 `tracker-ops:`의 이름이고 `=` 앞의 단계 이름이 전부 `skills/` 바로 아래 디렉터리 이름이다. 케이스 목록의 단일 선언처는 `tests/discover/README.md`다.
**묻지 않는 것** — 정의 문장과 어댑터 표의 「읽는 법」이 실제 동작과 같은가 · 스킬이 포인터를 실제로 따라가 그 행을 읽는가 · `tracker-phase-writes:`의 단계 이름이
그 단계에서 실제로 도는 커맨드인가(스킬 디렉터리 이름과만 대조한다 — 커맨드 명단과의 대조는 세우지 않았다) · 판별 · 쓰기 · 대응 기록 · 유입 선별의 이름을 스킬이 쓰는가(소비자가 아직 없다 — 소비자가 서는 사이클이 판정을 세운다).
경로 판정은 **스킬 단위**다 — `tracker-path-sites:`에 든 스킬 안에 읽기 경로를 다시 적어도, 경로를 적은 줄이 선언한 분류와 다른 종류여도 초록이다(줄 단위로 세면
문장을 다듬을 때마다 붉는다). 백틱 없이 적은 이름, 다른 꼴로 적은 경로(디렉터리 없이 적은 글롭 `M*.md` · `E*.md`, 역슬래시, 조립한 경로), `skills/` 밖의 재서술처(`docs/commands.md` · `README.md` · `site/`)도 보지 않는다.
**경로 없이 계획을 읽는 자리는 모으지 않았다**(M98 리뷰가 지목) — 재고는 경로 리터럴을 든 줄만 셌다. 남은 자리는 `cycle`이 태스크 목록의 의존 표기를 읽는 자리와 시작점 갈래,
`impl`의 시작 전 검사, `retro`의 릴리즈 표지 읽기, `status`의 다음 커맨드 판단이다. `milestone`의 「파일 위치」 줄이 다음 번호를 내려고 최대 번호를 읽는 것도 `rd-cycle-latest` 밖이다(번호 발급의 일부라 `write`로 두었다).
어댑터가 하나 더 서는 사이클이 이 자리들을 이름으로 옮길지 정한다. 그 사이클은 행 추출도 고쳐야 한다 — 지금은 표 하나에 한정하지 않고 조각 전체의 행을 세므로, 같은 이름의 행을 든 둘째 표를 세우면 붉다.
첫 칸이 `rd-`로 시작하지 않는 행(이름을 굵게 감싸거나 앞에 전각 공백 · 역슬래시 같은 다른 글자를 둔 행)은 행으로 세지 않는다. 세로줄로 시작하지 않는 줄(앞 세로줄을 뺀 행 · 인용 표지 뒤의 행)과
첫 칸 뒤에 세로줄이 없는 줄도 세지 않는다(M98 리뷰 라운드 1이 지목). `tracker-phase-writes:`의 단계 이름 대조는 점으로 시작하는 디렉터리 이름을 스킬로 보지 않는다.
`tracker-labels:` 안의 라벨 이름이 유일한가도 묻지 않는다 — 등록표가 이 키에 줄 수 · 금지 구분자 행만 두므로 라벨을 두 번 적어도 초록이다. 이 사이클은 판정을 더하지 않고 경계로 남긴다(M97 리뷰가 지목). 소비자가 라벨 목록을 읽게 되는 사이클이 `dup` 행을 더할 자리다.
**정의 사이에 열린 틈 하나** — 「라벨」은 라벨이 하나도 없는 열린 이슈를 「아직 안 본」 외부 이슈로 정하는데, `ti-absorb`는 라벨을 붙이지 않는다. 그래서 흡수한
이슈는 그 사이클이 닫힐 때까지 다음 후보 읽기에 다시 잡힌다. 흡수 줄을 읽어 거를지 라벨을 붙일지는 유입의 소비자가 서는 사이클이 정한다(M97 리뷰 라운드 1이 지목).
<!-- --8<-- [end:body] -->
