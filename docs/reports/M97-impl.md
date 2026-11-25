# M97 완료보고서 (impl)

## 개요

M97 태스크 여섯(T01~T06)을 구현했습니다.
- GitHub(비공개 시험 저장소)과 사내 GitLab 14.9.3 CE(시험 프로젝트)에서 E5 대응표를 한 줄씩 손으로 재현했습니다(T01 · T02).
- 응답은 정제해 `docs/reports/M97-recordings/`에 남겼습니다(T03).
- 그 실측을 근거로 `docs/conventions-tracker.md`에 트래커 계약 선언 다섯을 세웠습니다(T04). 하니스 등록표에는 행 22(`F61`~`F82`)를 더했습니다(T05).
- E5에 「M97 실측」 소절을 더해 계획 시점 지식 셋을 실측 값으로 바꿨습니다(T06).

스킬 · 훅 동작은 바뀌지 않았습니다. 작업은 두 세션에 걸쳤습니다. 첫 세션이 T01 · T04 · T05와 GitHub 몫의 T03을 했고, 둘째 세션이 T02 · 나머지 T03 · T06과 되돌림 재측정을 했습니다.

**재작업 라운드 1**(리뷰 `docs/reports/M97-review.md` 판정 `불가` · 차단 3과 반환 여섯)에서 아래를 고쳤습니다.
- 새 조각의 조각 요건 셋을 채웠습니다 — `[start:body]` 마커, 사이트 셸과 nav, 본체 포인터. 기계가 묻지 않는 그 요건에 대한 「집행」 문장도 사실대로 좁혔습니다.
- `count` 행 다섯에 단독 되돌림 행을 더했고, `seps` 행의 함께 붉음에는 반례 시도를 붙였습니다.
- 정의마다 기록 파일을 인용했고, 완료 기준 4를 `부분`으로 다시 매겼습니다.
- E5 서술을 선언에 맞췄고, `tracker-labels:` 유일성은 경계로 적었습니다.
- `github.com` 판별 응답을 기록으로 더했습니다.

**재작업 라운드 2**(리뷰 라운드 1 판정 `불가` · 차단 1과 반환 여섯)에서 아래를 고쳤습니다.
- 보관 기록에 남아 있던 러너 등록 토큰(`gitlab-00-project.json`의 `runners_token`)을 자리표시자로 바꿨고, 정제 스캔에 키 이름 꼴을 더했습니다.
- GitHub 계정의 숫자 ID 29곳을 바꿨습니다. GitLab 내부 숫자 ID와 포트는 사용자 결정(2026-11-25)대로 남겼습니다.
- 목록 응답 여덟 파일의 `body`를 배열로 되돌렸습니다.
- 조각 「정의의 근거」의 `ti-absorb` 행을 실측 범위(흡수 댓글 한 줄)로 좁혔고, 닫힘 실측 문장도 사이클 이슈 범위로 좁혔습니다.
- 완료 기준 5를 `부분`으로 다시 매겼고, `seps` 기전 문장을 실제 함수 이름으로 고쳤습니다.
- 사소 다섯 자리(E5 「남은 것」 · `CLAUDE.md` 규약 행 · 기록 README 봉투 문장 · 판별 표의 호스트 · 라벨 이름)를 맞췄습니다.

재작업 라운드(rework): 2

## 태스크별 수행 내용

- **M97-T01 — GitHub 실측.** 실측 전용 비공개 시험 저장소를 만들고, 쓰기 목록을 보인 뒤 승인을 받아 재현했습니다. 이슈는 다섯이었습니다 — #1 에픽, #2 · #3 사이클(sub-issue), #4 · #5 외부. PR은 #6 하나였습니다.

  | 줄 | 명령 | 응답 요지 | 판정 | 대체 |
  |---|---|---|---|---|
  | 1 라벨 셋 | `gh label create tide:epic` 등 | 201 · 셋 생성. 새 비공개 저장소에는 기본 라벨(`bug` 등)이 없었다 | 재현됨 | — |
  | 2 에픽 추적 이슈 | `gh issue create --label tide:epic` | 본문 요지 · 링크 · `- [ ] #2` `- [ ] #3` 체크리스트 | 재현됨 | — |
  | 3 sub-issue | `gh issue create --parent 1` · `gh api …/issues/1/sub_issues` | 사이클 둘이 sub-issue로 보이고, 부모의 `sub_issues_summary`가 진척을 낸다 | 재현됨 | — |
  | 4 체크리스트 편집 | `gh issue edit 2 --body …` | 본문의 `- [x] M999-T01` 반영 | 재현됨 | — |
  | 5 에픽 체크리스트 참조의 닫힘 | 사이클 둘을 닫은 뒤 `gh api …/issues/1`(`body_html`) | **본문 자체가 `- [x] #2` `- [x] #3`로 바뀌었다**, `body_html` 체크박스 `checked` 2, `sub_issues_summary` 2/2 · 100% | 재현됨(자동 체크) | — |
  | 6 닫힘 둘 | PR 본문 `Closes #2` 머지 · 기본 브랜치 커밋 메시지 `Closes #3` push | 두 이슈 모두 `closed` 이벤트. push 경로는 이벤트에 `commit_id`가 있다 | 재현됨 | — |
  | 7 유입 | `gh issue list --search '-label:"tide:epic" -label:"tide:cycle" -label:"tide:backlog"'` · 댓글 · `tide:backlog` · sub-issue로 매달기 | 라벨 없는 #4와 `bug`만 붙은 #5가 걸러졌다. 흡수 뒤 에픽 sub-issue로 보인다 | 재현됨 | — |

- **M97-T02 — GitLab 실측.** 접근 경로는 **tide 직접**입니다. 호스트와 토큰은 사용자 환경변수(`GITLAB_HOST` · `GITLAB_TOKEN`, 사용자 범위)에서 읽었고, 토큰 값은 어느 출력 · 기록에도 남기지 않았습니다. 시험 프로젝트는 사용자가 준 개인 네임스페이스 프로젝트입니다. 쓰기 목록(라벨 다섯 · 이슈 다섯 · 링크 · 브랜치 · MR · push · 댓글)을 보이고 승인을 받았습니다. 자체 서명 인증서는 없었습니다(HTTP).
  - **⑴ 버전**: `GET /version` 200 — `14.9.3` · 리비전 `ec11aba56f1`.
  - **⑵ 등급 기능 넷**(응답으로 판정):

    | 기능 | 요청 | 응답 | 판정 |
    |---|---|---|---|
    | 그룹 에픽 | `GET /groups/{소속 그룹}/epics` | 404 | 없음 |
    | `blocks` 링크 | `POST /projects/{p}/issues/1/links` `link_type=blocks` | **201, 저장된 `link_type`은 `relates_to`** | 없음(조용한 강등) |
    | 범위 라벨 배타 | `tide-probe::a` 뒤 `tide-probe::b`를 같은 이슈에 `add_labels` | 둘 다 남음 | 없음 |
    | Task work item | GraphQL `project.workItemTypes` · `IssueType` 열거 | `null` · `ISSUE` `INCIDENT` `TEST_CASE` `REQUIREMENT` | 없음 |

    덧붙여 `GET /license` 404, GraphQL 스키마에 `Epic` · `Iteration` 타입 없음, 그룹 이터레이션 404였습니다. 그래서 이 인스턴스는 **CE**(EE Free가 아님)입니다.
  - **⑶ 대응표 재현**(REST v4):

    | 줄 | 명령 | 응답 요지 | 판정 | 대체 |
    |---|---|---|---|---|
    | 1 라벨 | `POST /projects/{p}/labels` ×5 | 201 ×5 | 재현됨 | — |
    | 2 에픽 추적 이슈 | `POST /projects/{p}/issues` `labels=tide:epic` | 201 · 본문 `- [ ] #1` `- [ ] #2` | 재현됨 | — |
    | 3 sub-issue | — | 플랫폼에 없음(⑵) | 안 됨 | 에픽 본문 체크리스트 + `relates_to` 링크 둘(201) · `GET …/issues/3/links`가 둘을 돌려준다 |
    | 4 체크리스트 편집 | `PUT …/issues/1` `description` | 200 · 시스템 노트 「marked the task **T01 first task** as completed」 | 재현됨 | — |
    | 5 에픽 체크리스트 참조의 닫힘 | 사이클 둘을 닫은 뒤 `GET …/issues/3` · `POST /markdown`(gfm · project) | **본문은 `- [ ]` 그대로**, `task_completion_status` 0/2, 렌더 HTML의 체크박스 미체크 · 참조에 닫힘 표시 없음 | 안 됨 | 진척은 링크 목록(줄 3)의 이슈 `state`로 읽는다 |
    | 6a MR `Closes #1` 머지 | 브랜치 · 커밋 · `POST …/merge_requests` · `PUT …/merge` | MR 직후 `closes_issues` `[]`, 머지 첫 요청 406(「Branch cannot be merged」 — `merge_status` 계산 중), 재요청 200 · 이슈 1 `closed` · `closes_issues` 1건 | 재현됨 | — |
    | 6b 기본 브랜치 push `Closes #2` | `git push origin main`(인증은 `GIT_ASKPASS`) | 이슈 2 `closed` · `resource_state_events`에 `closed` | 재현됨 | — |
    | 7 유입 | `GET …/issues?state=opened&not[labels]=tide:epic,tide:cycle,tide:backlog` · 노트 한 줄 · `add_labels=tide:backlog` | 쓰기 전 #4 · #5, #4에 노트와 `tide:backlog`를 붙인 뒤 #5만(#4가 빠진 까닭은 라벨이다 — 조각의 이름으로는 보류 `ti-defer`의 쓰기이고, 기록 파일 이름의 `absorb`는 실측 당시의 표기다). `state=all`에서도 닫힌 사이클 둘(`tide:cycle`)이 빠진다 — 쉼표 목록은 「하나라도 있으면 뺀다」다. `labels=None`도 흡수 전 같은 둘 | 재현됨 | — |

  - **⑷ 판별의 실물**: `origin` URL(`http://{호스트}:{포트}/{네임스페이스}/{프로젝트}.git`)의 호스트가 환경변수 호스트와 같았습니다. 응답 코드는 아래와 같습니다.

    | 요청 | 토큰 | 응답 |
    |---|---|---|
    | `/version` | 있음 | 200 `{"version","revision"}` |
    | `/version` | 없음 · 틀림 | 401 `{"message":"401 Unauthorized"}` — GitLab 이름이 든 헤더 없음 |
    | 비공개 프로젝트 | 없음 | **404** `Project Not Found` |
    | 비공개 프로젝트 | 틀림 | 401 |
    | 없는 프로젝트 | 있음 | 404 |
    | `/personal_access_tokens/self` | 있음 | 404(14.9에 없음) |
    | `api.github.com`의 `/api/v4/version` | — | 404 |

    마지막 행은 GitHub **API 호스트**에서 잰 값입니다(라운드 2에서 호스트 표기를 고쳤습니다). `td-remote`가 읽는 `origin` 호스트(`github.com`) 자체에는 요청하지 않았습니다 — GitHub은 호스트 이름으로 먼저 갈리므로 그 요청이 판별에 쓰이지 않습니다.

    「권한 없는 프로젝트」는 **재지 못했습니다**. 쓴 토큰이 인스턴스 관리자의 것이라(`/user`의 `is_admin` 참) 모든 프로젝트를 읽기 때문입니다. 경계로 남깁니다(아래 후속 1).
- **M97-T03 — 정제와 보관.** 원 응답은 작업 트리 밖 scratchpad에 두었습니다(GitHub 11 · GitLab 64). 정제 스크립트는 다음을 바꿨습니다.
  - 노드 ID · 아바타 URL · `*email` 키 값 · 사용자 이름 키 값 · 실제 내부 호스트 · 계정 식별자 문자열을 고정 자리표시자로 바꿨습니다.
  - GraphQL 응답은 이름 키 규칙에서 뺐습니다. 스키마 타입 이름이 증거라서입니다.

  관리자 전용 인스턴스 프로젝트 응답 하나는 보관하지 않았고, 대응 기록 파일(`gitlab-ids.json`)도 뺐습니다. 보관한 것은 json 75건과 목록 `README.md`입니다. 그중 json 74건은 정제본이고, `github-08-api-v4-version.json` 하나는 재작업 라운드 1에서 더했습니다. 그 파일은 토큰 없이 공개 엔드포인트를 부른 응답이라 식별자가 없습니다. 스캔은 이렇게 했습니다.
  - 패턴: 실제 내부 호스트 · 사용자 이름 · 사용자명 · 이메일 둘 · 아바타 해시 · GitHub 몫 네 항목. 고정 문자열 대조(`Select-String -SimpleMatch`)입니다.
  - 대상: 보관 디렉터리 `docs/reports/M97-recordings/` 전체 76 파일(json 75 · README). 정제 직후에는 scratchpad `rec-clean` 75 파일에도 같은 스캔을 돌렸습니다.
  - 대조: 같은 패턴을 원본 76 파일(대응 기록 둘 포함)에 먼저 돌렸고, **660건**을 잡았습니다(양성 통제). 이 수는 열 항목의 합계입니다. 리뷰 라운드 2의 반증이 항목별로 다시 셌고, 줄 수는 11 · 0 · 4 · 68 · 233 · 68 · 209 · 4 · 63 · 0입니다. 두 항목은 원본에서도 0건이라 그 둘의 「보관본 0건」에는 통제가 없습니다. 한 항목은 목록에 두 번 들어 68이 두 번 세어졌고, 중복 없는 일치 줄은 478입니다.
  - 루트: 저장소의 보관 디렉터리, 그리고 scratchpad의 `rec` · `rec-clean`.
  - 결과: 보관 디렉터리 **0건**(재작업 라운드 1 · 2에서 다시 쟀습니다 — 라운드 2 값은 대조 660건 · 대상 0건). GitLab 접근 토큰 값 스캔은 원본 · 정제본 모두 0건이고, `gh?_…` · `glpat-…` 꼴 정규식도 정제본 0건입니다.
  - **이 스캔이 놓친 것(라운드 1 리뷰 차단)**: 위 패턴은 요청에 실은 접근 토큰과 두 접두 꼴만 봅니다. 응답 본문이 스스로 싣는 비밀 필드는 그 밖이라, `gitlab-00-project.json`의 `runners_token`(러너 등록 토큰)이 평문으로 남아 있었습니다. 라운드 0 · 1의 「토큰 0건」은 그 패턴 범위 안에서만 사실이었습니다.
  - **재작업 라운드 2의 정제**(스크립트는 scratchpad의 `r2fix.py`):
    - 토큰: 그 값을 `runners_token-placeholder`로 바꿨습니다(1곳).
    - 키 이름 스캔을 더했습니다. 패턴은 `token` · `secret` · `password` · `passwd` · `private_key` · `api_key`를 담은 키의 비어 있지 않은 문자열 값(대소문자 무시, 값이 `-placeholder`로 끝나면 뺀다)입니다. 대상은 보관 디렉터리의 json 75입니다. 대조는 같은 패턴을 고치기 전 보관 디렉터리와 scratchpad 원본 `rec`에 돌린 것이고, 각각 **1건**(그 필드)을 잡았습니다(양성 통제). 루트는 저장소의 보관 디렉터리와 scratchpad `rec`입니다. 결과는 고친 뒤 **0건**입니다. 이 정규식이 보는 범위는 좁습니다 — 키 전체가 영문자와 밑줄일 때만 잡고(숫자 · 하이픈이 든 키는 못 잡습니다), 값이 문자열일 때만 봅니다. 리뷰 라운드 2의 반증이 JSON을 파싱해 넓은 키 패턴으로 다시 훑었고, 서로 다른 키 373개 가운데 비밀 꼴 키의 문자열 값은 자리표시자가 된 그 필드 하나였습니다.
    - 값 꼴 스캔에 러너 등록 토큰 접두와 `glrt-`를 더했습니다. 대상은 보관 디렉터리 76 파일이고 0건입니다. 러너 접두 꼴은 고치기 전 같은 디렉터리에서 1건이었습니다.
    - GitHub 계정 숫자 ID: `"id":` 뒤의 그 값 29곳을 `1`로 바꿨습니다. 그 숫자를 어떤 꼴로든 찾는 스캔은 고치기 전 29건, 고친 뒤 0건입니다(대상 76 파일).
    - 남긴 것: GitLab 내부 숫자 ID · 포트 · 커밋 SHA · 프로젝트 응답의 관리 필드입니다. 사용자 결정(2026-11-25 · 「남긴다」)이고, 사유는 기록 README에 적었습니다.
    - 목록 응답의 꼴: 여덟 파일의 `body`가 객체(원소 하나) 또는 `null`(0개)로 풀려 있었습니다. 배열로 되돌렸습니다. scratchpad 원본도 같은 꼴이라 원 응답 바이트와는 대조하지 못했습니다 — 되돌린 것은 꼴뿐입니다. 고친 뒤 GitLab 봉투 62개의 `body`는 배열 15 · 객체 47이고, 객체 가운데 `GET` 200은 일곱이며 모두 단일 자원 엔드포인트(`projects/{p}` · `version` · `issues/{n}` · `merge_requests/{n}`)입니다. json 75개는 모두 파싱됩니다.
    - `gitlab-00-labels-before.json`의 라벨 이름은 이름 키 규칙에 걸려 자리표시자가 돼 있었습니다. 사람 이름이 아니라 원래 값(`Doing`)으로 되돌렸습니다.
    - 기록 README의 정제 규칙 절을 이 사실대로 다시 적었습니다(토큰 문장 · 스캔 범위 · 남긴 것 · 봉투 예외 둘 · 목록 꼴).
  - 보관 자리 `docs/reports/M97-recordings/`는 하니스와 사이트 빌드를 붉히지 않았습니다. 하니스가 이 디렉터리에서 읽는 것은 `M*` 꼴 Markdown 보고서와 `retro.md`뿐이고, 하위 폴더는 열거하지 않습니다(`run.sh`의 `"$1"/M*.md` 글롭 · `RETRO` 경로). 사이트 `docs_dir`은 `site/docs`입니다. 그래서 대체 자리(보고서 부록)는 쓰지 않았습니다.
- **M97-T04 — 계약 선언.** `docs/conventions-tracker.md`(새 조각)의 「트래커 계약」 절에 선언 다섯과 이름별 정의 항목을 두었습니다. 선언은 `tracker-ops:` · `tracker-detect-steps:` · `tracker-labels:` · `tracker-phase-writes:` · `tracker-intake-verdicts:`입니다. 실측이 바꾼 자리는 셋이고, 둘째 세션에서 정의 문장만 고쳤습니다(이름 · 선언 줄은 그대로).
  - `td-remote`: 원격 추론에도 토큰을 실어 200 · `version`을 본다.
  - `td-reach`: GitLab은 토큰 없는 비공개 프로젝트에 404를 내므로 `/version`의 401을 먼저 본다.
  - `ti-defer`: sub-issue가 없으면 체크리스트 + `relates_to`(`blocks`는 강등된다).

  닫힘 경로 문장도 GitLab 두 경로를 더해 기록 자리를 가리킵니다. 절 머리에 「아직 어떤 스킬도 소비하지 않는다」를, 절 끝에 「기계가 묻는 것 · 묻지 않는 것」을 적었습니다.

  재작업 라운드 1에서 다섯 가지를 더 고쳤습니다.
  - **조각 요건 셋**(`docs/conventions.md`의 "상호참조 무결성" 절)을 채웠습니다.
    - ① 조각에 `[start:body]`/`[end:body]` 마커를 두고 도입 문단을 마커 밖에 두었습니다.
    - ② 사이트 셸 `site/docs/conventions-tracker.md`와 `site/mkdocs.yml` nav 항목 「트래커 계약 규약」을 만들었습니다.
    - ③ 본체에 「트래커 계약 (분리된 조각)」 포인터 절을 두었습니다.
  - **재서술처**: `docs/project-context.md`의 조각 행과 사이트 스니펫 셸 목록을 고쳤습니다.
  - **「집행」 문장**: 같은 절의 「Part G가 FAIL로 집행한다」 범위를 `xr-asks:` 이름들로 좁혔습니다. 그리고 조각 요건 셋은 기계가 묻지 않는다는 문단을 더했습니다 — `xr-asks:`에 이름이 없고, `tests/site-includes`는 셸이 없는 조각을 찾지 않습니다. 판정을 더하는 일은 후속 6으로 넘겼습니다.
  - **「정의의 근거」**: 실측이 닿은 정의마다 기록 파일 이름을 표로 인용하고, 실측 대상이 아닌 정의와 그 사유를 적었습니다.
  - **「묻지 않는 것」**: `tracker-labels:` 라벨 유일성을 경계로 적었습니다.
  - 셸이 하나 늘어 `tests/site-includes`의 발견형 케이스가 6 늘었습니다. 그래서 그 README의 `cases:` 선언을 고쳤습니다.

  재작업 라운드 2에서 조각의 세 자리를 실측 범위로 좁혔습니다(선언 줄과 정의 항목은 그대로입니다).
  - **「정의의 근거」 `ti-absorb` 행**: 근거를 흡수 댓글 한 줄(`gitlab-07b-absorb-note.json`)로 좁혔습니다. 라운드 1이 인용한 `github-07b-backlog-sub-issue.json`은 보류(`ti-defer`)를 보이는 기록이고, `gitlab-07c-open-untagged-after-absorb.json`은 `tide:backlog`를 붙여서 빠진 것이라 흡수의 근거가 아니었습니다. 「사이클의 닫힘이 함께 닫는다」와 한 줄에 여러 이슈를 닫는 꼴은 재지 않았다고 적었습니다.
  - **「단계별 쓰기 범위」의 실측 문장**: 두 경로가 닫은 것은 사이클 이슈 하나라고 좁혔습니다.
  - **「묻지 않는 것」 곁의 틈**: 흡수한 이슈는 라벨이 없어 사이클이 닫힐 때까지 후보 읽기에 다시 잡힌다는 점을 경계로 적었습니다.
- **M97-T05 — 등록표.** 두 러너의 등록표에 같은 꼴로 행 22를 더했습니다(`CONV_TRK`).
  - 선언 다섯마다 `count` · `seps` 둘.
  - 이름 선언 셋마다 `dup` · `def` · `orphan` · `order` 넷 — 본 검사 12.
  - `cases:` 887 → 909, Part F 66 → 88.
  - `tests/**/*.ps1`에 넣은 것은 ASCII뿐입니다(F5 초록).
- **M97-T06 — E5 반영.** `docs/epics/E5.md`를 다섯 군데 고쳤습니다.
  - 「GitLab 14.9가 정하는 하한」 아래에 「M97 실측」 소절을 더했습니다(줄별 두 플랫폼 재현표 · 등급 기능 · 판별 · 계획 시점 지식 셋의 결론).
  - 「개념 대응」의 sub-issue 문장: 체크리스트가 체크되지 않는다는 실측으로 바꿨습니다.
  - 「계약」 머리: 이름을 다시 열거하지 않고 `docs/conventions-tracker.md`의 "트래커 계약" 절을 가리킵니다.
  - 「판별 순서」 2: 토큰이 필요하다는 점을 더했습니다.
  - 「사용자 판단」의 「남은 것」: 확인 완료로 고쳤습니다.

  재작업 라운드 1에서 E5가 선언 내용을 다시 늘어놓던 자리를 선언을 가리키게 바꿨습니다. 그 자리의 E5 문장은 선택의 까닭만 남깁니다.

  | 자리 | 바꾼 것 |
  |---|---|
  | 「라벨 이름」 항목 | `tracker-labels:`를 가리킴 |
  | 「유입」 3 | `tracker-intake-verdicts:`와 `ti-*` 이름 — 흡수 · 보류의 까닭만 남김 |
  | 「계약」 연산 목록 | `tracker-ops:` 이름 넷 |
  | 「판별 순서와 로컬 대체」 | `tracker-detect-steps:` — 실패 사유 셋/넷 어긋남은 정의 항목으로 넘겨 해소 |
  | 「부수효과의 자리」 | 낡은 미래형과 다섯 단계 재열거를 `tracker-phase-writes:` 포인터로 |
  | 「개념 대응」 표의 「사이클 닫힘」 행 | push-only 경로를 조각과 같은 「기본 브랜치 커밋 메시지」로 |

  재작업 라운드 2에서 E5 두 문장을 고쳤습니다. 「유입」의 `Closes #{사이클} #45 #51` 꼴에는 재지 않았다는 점을 붙였습니다. 「사용자 판단」의 「남은 것」에는 재지 못한 두 칸(권한 없는 프로젝트의 응답 · 흡수 이슈의 함께 닫힘)과 그것을 받을 사이클을 적었습니다. `CLAUDE.md`의 「어디를 읽어야 하는가」 표 규약 행도 조각을 글롭(`docs/conventions-*.md`)으로 가리키게 바꿨습니다.

  `docs/project-context.md`의 개념 블록은 트래커를 말하지 않아 고치지 않았습니다. `트래커` · `tracker`로 grep한 히트가 0입니다(라운드 1에서 고친 것은 그 파일의 저장소 구조 표 두 행입니다 — T04).

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | T01 표 — 줄 1~7마다 명령 · 응답 요지 · 판정 · 대체가 있습니다. 줄 5는 관측값(본문이 `[x]`로 바뀜 · `checked` 2 · 요약 2/2)이고, 줄 6은 두 경로의 `closed` 이벤트입니다. 기록은 `github-05-epic-full.json` · `github-06a-pr-close-timeline.json` · `github-06b-push-close-timeline.json`입니다. |
| 2 | 충족 | T02 ⑴~⑷ — 버전 `14.9.3`, 등급 기능 넷의 응답 코드 · 본문(그룹 에픽 404 · `blocks` 201→`relates_to` · 범위 라벨 배타 없음 · Task 타입 없음), 대응표 줄 1~7 재현표, 판별 응답 코드 표가 있습니다. 접근 경로는 **tide 직접**입니다. ⑷의 「권한 없는 프로젝트」 한 칸은 관리자 토큰이라 재지 못했고, 그 사실과 사유를 적었습니다. |
| 3 | 충족 | 라운드 1까지의 「충족」은 틀렸습니다 — 러너 등록 토큰이 한 파일에 남아 있었습니다(T03 「이 스캔이 놓친 것」). 라운드 2에서 그 값을 바꾼 뒤 다시 쟀습니다. 고정 문자열 스캔은 보관 디렉터리 76 파일 0건 · 원본 660건(양성 통제)입니다. 토큰은 값 꼴 스캔 0건과 키 이름 스캔 0건이고, 키 이름 스캔은 고치기 전 디렉터리와 원본에서 1건씩 잡았습니다(양성 통제). 범위 네 축은 T03 항목에 있습니다. 스캔이 덮는 것은 그 패턴들까지입니다 — 패턴 밖의 비밀 꼴이 없다는 주장은 아닙니다. |
| 4 | 부분 | `docs/conventions-tracker.md`에는 선언 다섯과, 이름 선언 셋의 정의 항목 13(연산 4 · 판별 4 · 유입 5)이 있습니다. 「정의의 근거」 표는 실측이 닿은 정의 여덟(`to-read` · `to-write` · `td-remote` · `td-reach` · 라벨 · `ti-absorb` · `ti-defer` · `release`의 `close`)마다 기록 파일 이름을 인용합니다. 나머지(`to-detect` · `to-map` · `td-explicit` · `td-local` · `ti-promote` · `ti-debug` · `ti-close` · 나머지 단계 범위)는 실측 근거를 가리키지 않고 E5 결정을 근거로 적었습니다. 그 정의들은 트래커의 응답이 아니라 tide 쪽 동작이라(설정 파일 · 로컬 대체 · 대응 기록 · 사용자 선택), 트래커를 불러 확인할 대상이 없습니다. 시도한 것은 그 동작을 트래커 응답으로 바꿔 쓸 수 있는가였고, 각 정의 문장이 트래커 응답을 하나도 말하지 않아 대응할 기록이 없었습니다. 그래서 기준 문면 「정의마다」에는 못 미칩니다. |
| 5 | 부분 | 기준 문면은 「새 등록표 행마다 … 단독으로 붉는다」인데, 22행 가운데 `seps` 다섯 행은 단독 붉음을 보이지 못했습니다(`F26`과 함께 붉습니다 — 근거는 되돌림 표 아래). 나머지 17행과 하니스 값은 채웠습니다. 아래 「마지막 측정」 — pwsh 7 · Windows PowerShell 5.1 전수 FAIL 0이고 총계가 `cases:` 선언과 같습니다. sh 축 전수(`dash` · `bash`)는 `measure-axis:` 배당대로 CI `posix` 레그가 판정합니다. 로컬 Git Bash sh로는 Part F를 쟀습니다. 되돌림 표에서 새 행 22가 모두 붉고, 행마다 두 러너의 붉은 집합이 같습니다. 단독 붉음은 본 검사 12와 `count` 행 다섯(재작업 라운드 1)이 보였습니다. `seps` 행 다섯은 `F26`과 함께만 붉는다는 근거를 표 아래 세 요소로 적었습니다. |
| 6 | 충족 | `git diff --stat -- skills hooks` 출력 0줄, `git status --short -- skills hooks` 0줄(새 파일 없음)입니다. |
| 7 | 충족 | E5 「M97 실측」 소절 — 판정 셋을 실측 값으로 바꿨습니다. ⑴ Free 기능은 없음(+ `blocks` 조용한 강등). ⑵ 체크리스트 닫힘 표시는 GitHub 자동 체크 · GitLab 표시 없음으로 갈림. ⑶ 판별 순서는 성립하되 원격 추론에도 토큰이 필요함. 「사용자 판단」의 「남은 것」도 확인 완료로 고쳤습니다. |
| 8 | 충족 | 처분 — 시험 항목은 실측 뒤 모두 닫았습니다(GitLab 열린 이슈 0건 확인 · `gitlab-09-open-after-cleanup.json`). 그다음 사용자 결정(2026-11-23 · 「작업이 끝나면 삭제」)대로 정제 기록을 보관한 뒤 둘 다 **지웠습니다**. GitHub 시험 저장소는 `gh repo delete` 뒤 `gh repo view`가 「Could not resolve」입니다. GitLab 시험 프로젝트는 `DELETE /projects/{p}` 202 뒤 `GET` 404입니다. 로컬 clone은 scratchpad에만 있었습니다. |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/conventions-tracker.md` · `site/docs/conventions-tracker.md` · `docs/reports/M97-recordings/README.md` · `docs/reports/M97-recordings/*.json`(75) · `docs/reports/M97-impl.md` |
| 수정 | `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` · `tests/site-includes/README.md` · `docs/epics/E5.md` · `docs/conventions.md` · `docs/project-context.md` · `site/mkdocs.yml` · `CLAUDE.md` |
| 삭제 | 없음 |

`docs/milestones/M97.md`(추가)와 `docs/epics/E5.md`의 2026-11-23 사용자 논의분(대응 확정 · 유입 축 ⑸ · 공개 저장소 실측표 · M97 등재)은 직전 `/tide:milestone` 단계까지의 미커밋 산출물입니다. `docs/reports/M97-review.md`는 리뷰의 산출물입니다(지금 문면은 라운드 1). 라운드 0 리뷰가 고친 셋(README Part F 열거 · 조각 「정의의 근거」 문단 · 이 보고서 T03 문장)은 이 사이클의 편집과 함께 실립니다. 라운드 1 리뷰는 고친 것이 없습니다. 재작업 라운드 2가 고친 파일은 보관 기록 json 17개(GitHub 계정 숫자 ID 여덟 · 러너 토큰 하나 · 목록 꼴 여덟 — 라운드 1의 정제본 사본과 해시로 대조한 수), 기록 README, 조각, E5, `CLAUDE.md`, 이 보고서입니다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (pwsh 7.7.0 · Windows PowerShell 5.1 · Git Bash sh 파트별 · `tests/site-includes` 세 런타임 · mkdocs `--strict` 빌드) | 아래 「마지막 측정」 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — `dash` · `bash`) | 릴리즈 단계에서 PR CI `posix` 레그로 확인 |

**마지막 측정**(이 보고서를 쓴 뒤의 트리):

- **pwsh 7.7.0 전수** `pwsh -NoProfile -File tests/discover/run.ps1` — 909/0
- **Windows PowerShell 5.1 전수** `powershell.exe -NoProfile -File tests/discover/run.ps1` — 909/0
- **Git Bash sh 파트별** `sh tests/discover/run.sh {X}` — F 87/0(전수에서만 도는 `F1`을 더하면 Part F 88) · G 37/0 · P 47/0 · U 7/0 · V 73/0. 고른 파트는 셋입니다. 이 사이클이 고친 등록표(F), 라운드 1에서 고친 본체 인용 · 앵커를 무는 파트(G), impl 보고서를 읽는 파트(P · U · V)입니다. 나머지 파트의 sh 값은 CI가 판정합니다(위 표).
- **`tests/site-includes`**(재작업 라운드 1 — 셸이 늘었다) `sh tests/site-includes/run.sh` · `pwsh -NoProfile -File tests/site-includes/run.ps1` · `powershell.exe -NoProfile -File tests/site-includes/run.ps1` — 셋 다 57/0(`shells=6 includes=6`).
- **사이트 빌드** `mkdocs build --strict -f site/mkdocs.yml` — 성공. 산출물 `conventions-tracker/index.html`에 `tracker-ops`가 3번 나타나고, `start:body` · `end:body` 마커는 0번입니다(본문만 인클루드됨).
- **보고서 뒤 재측정**: 이 절을 채운 뒤 pwsh 7 · Windows PowerShell 5.1 전수와 sh F · P · U · V를 다시 돌렸습니다. 값은 위와 같습니다.
- **재작업 라운드 2의 마지막 측정**: 위 값은 모두 라운드 2 편집과 이 보고서 갱신을 마친 뒤 다시 잰 것입니다(pwsh 7 전수 · Windows PowerShell 5.1 전수 · sh F · G · P · U · V · `tests/site-includes` 세 런타임 · mkdocs `--strict`). 라운드 2는 러너 코드와 선언을 건드리지 않아 수는 라운드 1과 같습니다.

**캐시가 아닌 실행의 확인**(`measure-not-cached`): 하니스는 빌드 캐시가 없는 셸 스크립트입니다. 이 트리에서 돈 값이라는 근거는 둘입니다.
- 총계 909와 새 케이스 줄 22(`F61`~`F82`)가 pwsh 출력에 있습니다.
- `tests/site-includes`의 결과 줄이 `shells=6`입니다. 새 셸을 두기 전에는 같은 명령이 케이스 수 불일치(`got 51, want 57`)로 붉었습니다.

mkdocs는 `-d`로 매번 비운 디렉터리에 빌드했습니다(`Cleaning site directory`).

**생명주기 상태표**(`lifecycle-state-table`) — 새 판정은 등록표 행 22입니다. 판정이 읽는 입력은 규약 조각 `docs/conventions-tracker.md`의 선언 줄과 정의 항목 하나입니다.
- 전이 표에서 그 입력을 바꾸는 전이는 `tr-downstream`(선언이 없는 대상 레포)뿐입니다. 나머지 전이는 마일스톤 · 보고서 · 버전 파일 · CHANGELOG · 회고 · `.tide/`만 바꾸므로 이 판정에게 항등입니다(파생 규칙 ⓑ).
- 그래서 판정별 격자가 낸 목록 밖 상태는 없습니다.
- 재작업 라운드 2도 판정을 세우거나 조건을 바꾸지 않았습니다(러너 · 선언 줄 · 정의 항목 무변경 — 조각은 산문 세 자리만 고쳤습니다).
- 재작업 라운드 1은 판정을 새로 세우거나 조건을 바꾸지 않았습니다. 규약 · 문서 편집과 `tests/site-includes` `cases:` 선언의 수만 바뀌었습니다. 그래서 아래 표는 라운드 0과 같고, ⑴ 행의 값만 마지막 측정입니다.

| 상태 | 사본에서 만든 방법 | 기대 | 실제 (sh · ps1) |
|---|---|---|---|
| ⑴ 사이클 중(`tr-draft` `tr-impl`) | 이 사이클의 편집을 마친 작업 트리 | 초록 | 아래 「마지막 측정」 |
| ⑵ · ⒇ · `st-fail-then-draft` | 해당 없음(리뷰 보고서 · 다음 마일스톤만 늘어난다 — 이 판정이 읽지 않는 입력) | — | ⑴과 같다 |
| ⑶ · ⑷ · ⑸ · ⑾ · ⒂ · ⒃ · ⒄ | 해당 없음(버전 파일 · CHANGELOG · 릴리즈 표지 · 태그 · 회고만 바뀐다) | — | ⑴과 같다 |
| ⑹ · ⑺ · ⑻ | 해당 없음(마일스톤 문서 · 에픽 등재만 바뀐다) | — | ⑴과 같다 |
| ⑼ · ⑽ · ⒀ · ⒁ · ⒆ | 해당 없음(debug 보고서 · `.tide/` · 버전 파일만 바뀐다) | — | ⑴과 같다 |
| ⑿ 파트 선택 실행(`tr-part-select`) | 되돌림 22행과 기준 사본 모두 `run.sh F` · `run.ps1 F`로 돌렸습니다 | 기준 사본 Part F 초록 · 행마다 기대 케이스만 붉음 | 아래 되돌림 표 |
| ⒅ 대상 레포에서 처음 도는 릴리즈(`tr-downstream`) | 해당 없음 — 하니스는 이 저장소에서만 돕니다. 대상 레포에는 이 조각이 없고, 이 절을 읽는 스킬도 아직 없습니다. 그래서 대상 레포에서 이 판정이 도는 값이 없습니다 | — | — |

## 되돌림 실측

각 행은 같은 기준 사본(`m97base2` — 이 사이클의 편집을 마친 작업 트리를 `.git` 없이 복사)에서 새로 뜬 사본 하나에 변이 **하나**를 건 것입니다. 사본마다 `pwsh -NoProfile -File tests/discover/run.ps1 F`와 Git Bash `sh tests/discover/run.sh F`를 돌렸습니다.
- 기준선(변이 없음)은 두 러너 모두 Part F 87/0입니다(`F1`은 전수에서만 돈다).
- 첫 세션의 사본 c1~c7은 변이 여럿을 한 사본에 묶어, 본 검사의 단독 붉음을 보이지 못했습니다. 그래서 이 표는 둘째 세션에서 단일 변이로 다시 잰 값입니다.
- 둘째 세션의 첫 배치는 s00~s16에서 메모리 부족으로 멈췄습니다. s17~s22는 한 사본씩 포그라운드로 다시 돌렸습니다.
- 재작업 라운드 1의 다섯 행(`r-*-move`)은 라운드 1 편집을 마친 트리를 새로 복사한 기준 사본(`m97base3`)에서 쟀습니다. 그 기준선도 두 러너 모두 Part F 87/0입니다. 변이는 선언 줄과 바로 아래 들여쓴 정의 항목을 조각에서 지우고 `docs/conventions.md` 끝에 붙이는 것입니다 — 리뷰 반증이 지목한 꼴입니다.

<!-- reversal-table:start -->
<!-- reversal-table-main: F63 F64 F65 F66 F69 F70 F71 F72 F75 F76 F77 F78 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| r-ops-dup | `tracker-ops:` 선언 끝에 첫 이름 `to-detect`를 한 번 더 | broken | F63 | sh F 86/1 · ps1 F 86/1 |
| r-ops-def | `to-read` 정의 항목을 지움 | broken | F64 | sh F 86/1 · ps1 F 86/1 |
| r-ops-orphan | 마지막 정의 뒤에 선언에 없는 `to-zz` 정의를 더함 | broken | F65 | sh F 86/1 · ps1 F 86/1 |
| r-ops-order | 정의 항목 `to-detect` · `to-read`의 차례를 바꿈(이름 · 정의는 모두 그대로) | adversarial | F66 | sh F 86/1 · ps1 F 86/1 |
| r-td-dup | `tracker-detect-steps:` 선언 끝에 `td-explicit`를 한 번 더 | broken | F69 | sh F 86/1 · ps1 F 86/1 |
| r-td-def | `td-reach` 정의 항목을 지움 | broken | F70 | sh F 86/1 · ps1 F 86/1 |
| r-td-orphan | 마지막 정의 뒤에 `td-zz` 정의를 더함 | broken | F71 | sh F 86/1 · ps1 F 86/1 |
| r-td-order | 정의 항목 `td-explicit` · `td-remote`의 차례를 바꿈 | adversarial | F72 | sh F 86/1 · ps1 F 86/1 |
| r-ti-dup | `tracker-intake-verdicts:` 선언 끝에 `ti-absorb`를 한 번 더 | broken | F75 | sh F 86/1 · ps1 F 86/1 |
| r-ti-def | `ti-defer` 정의 항목을 지움 | broken | F76 | sh F 86/1 · ps1 F 86/1 |
| r-ti-orphan | 마지막 정의 뒤에 `ti-zz` 정의를 더함 | broken | F77 | sh F 86/1 · ps1 F 86/1 |
| r-ti-order | 정의 항목 `ti-absorb` · `ti-promote`의 차례를 바꿈 | adversarial | F78 | sh F 86/1 · ps1 F 86/1 |
| r-ops-line | `tracker-ops:` 선언 줄을 복제 | broken | F25;F61 | sh F 85/2 · ps1 F 85/2 |
| r-ops-tab | `tracker-ops:` 꼬리의 첫 토큰 사이 공백을 탭으로 | broken | F26;F62 | sh F 85/2 · ps1 F 85/2 |
| r-td-line | `tracker-detect-steps:` 선언 줄을 복제 | broken | F25;F67 | sh F 85/2 · ps1 F 85/2 |
| r-td-tab | `tracker-detect-steps:` 꼬리에 탭 | broken | F26;F68 | sh F 85/2 · ps1 F 85/2 |
| r-ti-line | `tracker-intake-verdicts:` 선언 줄을 복제 | broken | F25;F73 | sh F 85/2 · ps1 F 85/2 |
| r-ti-tab | `tracker-intake-verdicts:` 꼬리에 탭 | broken | F26;F74 | sh F 85/2 · ps1 F 85/2 |
| r-lb-line | `tracker-labels:` 선언 줄을 복제 | broken | F25;F79 | sh F 85/2 · ps1 F 85/2 |
| r-lb-tab | `tracker-labels:` 꼬리에 탭 | broken | F26;F80 | sh F 85/2 · ps1 F 85/2 |
| r-pw-line | `tracker-phase-writes:` 선언 줄을 복제 | broken | F25;F81 | sh F 85/2 · ps1 F 85/2 |
| r-pw-tab | `tracker-phase-writes:` 꼬리에 탭 | broken | F26;F82 | sh F 85/2 · ps1 F 85/2 |
| r-ops-move | `tracker-ops:` 선언 줄과 정의 넷을 본체 끝으로 옮김 | broken | F61 | sh F 86/1 · ps1 F 86/1 |
| r-td-move | `tracker-detect-steps:` 선언 줄과 정의 넷을 본체 끝으로 옮김 | broken | F67 | sh F 86/1 · ps1 F 86/1 |
| r-ti-move | `tracker-intake-verdicts:` 선언 줄과 정의 다섯을 본체 끝으로 옮김 | broken | F73 | sh F 86/1 · ps1 F 86/1 |
| r-lb-move | `tracker-labels:` 선언 줄을 본체 끝으로 옮김 | broken | F79 | sh F 86/1 · ps1 F 86/1 |
| r-pw-move | `tracker-phase-writes:` 선언 줄을 본체 끝으로 옮김 | broken | F81 | sh F 86/1 · ps1 F 86/1 |

<!-- reversal-table:end -->

`order` 세 행은 적대 축입니다. 이름 · 정의 · 고아는 그대로 두고 차례만 바꿔 `dup` · `def` · `orphan` 판정을 모두 통과하게 만든 사본이고, 차례가 뜻인 선언에서 그것만 붉는지 묻습니다. `count` · `seps` 열 행(`F61` · `F62` · `F67` · `F68` · `F73` · `F74` · `F79`~`F82`)은 선언 위생 행이라 본 검사 목록에 넣지 않았습니다.
- **`count` 행 다섯**: 라운드 0은 「단독 붉음이 성립하지 않는다」고 적었는데, 그 주장은 틀렸습니다. 선언 절을 본체로 옮기면 단독으로 붉습니다(`r-*-move` 다섯 행).
- **`seps` 행 다섯**: `F26`과 함께만 붉는다는 근거는 셋입니다.
  - ⑴ 주장 — `F62` · `F68` · `F74` · `F80` · `F82`는 `F26` 없이 붉지 않는다.
  - ⑵ 기전 — 두 판정은 **다른 함수**입니다(라운드 1은 「같은 함수」라고 잘못 적었습니다). `F26`은 `decl_disc_seps`(ps1 `DeclDiscSeps`)로 문서 집합 `docs/conventions*.md`의 모든 선언 줄을 보고, 등록표 행은 `bad_seps`(ps1 짝)로 조각 파일에서 그 키의 첫 매치 줄을 봅니다. 함께 쓰는 것은 금지 구분자 정규식 하나입니다. 그래도 함께 붉는 까닭은 셋입니다. 두 구현이 선언 줄을 같은 꼴로 알아보고, 꼬리를 같은 자리에서 자르며, 같은 구분자 집합을 씁니다. 그래서 등록표 행이 보는 줄은 `F26`이 보는 줄의 부분집합입니다.
  - ⑶ 시도한 반례 — `count` 행을 단독으로 붉힌 「본체로 옮김」에 꼬리 탭을 더한 사본(`r-ops-move` + 본체 쪽 `tracker-ops:` 꼬리에 탭)입니다. 두 러너 모두 Part F 85/2 `F26;F61`이었고, `F62`는 초록이었습니다(조각에 선언이 없으니 볼 꼬리가 없다). 조각 쪽 꼬리에 탭을 둔 사본은 위 `r-*-tab` 행이고, `F26`이 함께 붉었습니다.

    리뷰 라운드 1의 반증 패스가 한 가지를 더 시도했습니다. 조각의 `tracker-phase-writes:` 꼬리에 NBSP를 넣은 사본이고, pwsh 7 · Windows PowerShell 5.1 · Git Bash sh 모두 Part F 85/2 `F26;F82`였습니다.

  그래서 `F26`이 초록이면서 등록표 `seps` 행만 붉는 트리는 찾지 못했습니다. 찾지 못한 것이고, 없음을 보인 것은 아닙니다 — 그래서 완료 기준 5는 `부분`입니다.

## 미해결·후속 메모

1. **GitLab 「권한 없는 프로젝트」 응답은 재지 못했다.** 쓴 토큰이 인스턴스 관리자의 것이었습니다. `td-reach`의 「권한 없음」 꼴은 GitLab 어댑터 사이클(E5 사이클 배분 4)이 관리자 아닌 토큰으로 재야 합니다. 토큰 없는 비공개 프로젝트가 404라는 점을 보면, 권한 없음도 404일 가능성이 큽니다. 그러면 404만으로는 「없음」과 「권한 없음」을 가르지 못합니다.
2. **GitLab `blocks`는 오류 없이 `relates_to`로 저장된다.** 어댑터는 링크를 만든 뒤 응답의 `link_type`을 확인해야 합니다. 의존(deps)을 트래커에 옮기는 설계는 GitLab CE에서 이 링크에 기댈 수 없습니다.
3. **GitLab 에픽 진척은 체크리스트로 읽을 수 없다.** 사이클이 닫혀도 에픽 본문 체크박스는 그대로입니다. 읽기 경로(사이클 배분 2 · 3)가 에픽 진척을 낼 때는 GitLab에서 링크 목록의 상태를 읽어야 합니다. 「체크리스트를 tide가 직접 고친다」는 갈래도 있지만 `tracker-phase-writes:`의 `release`에 `close`만 있어 지금 선언 밖입니다.
4. **MR 머지 API는 만든 직후 406을 낼 수 있다.** `merge_status` 계산이 끝나기 전입니다. 이번에는 재요청 한 번으로 통과했습니다. 어댑터가 머지를 부른다면 재시도 규율이 필요합니다(지금 tide는 MR 머지를 부르지 않습니다).
5. **웹 화면의 참조 닫힘 표시는 재지 않았다.** API · `/markdown` 렌더에는 나타나지 않았습니다. tide가 읽는 자리가 아니라 대상 밖으로 두었습니다.
6. **조각 요건 셋을 묻는 판정이 없다.** `docs/conventions.md`의 "상호참조 무결성" 절은 이제 이 사실을 적습니다(라운드 1). 셋을 판정으로 세우면 다음 조각이 같은 자리를 초록으로 지나가지 않습니다. 셋은 마커 쌍, 셸과 nav, 본체 포인터입니다. 이 줄기의 범위 밖이라 회고 후보로 넘깁니다. 원인 쪽 후보도 있습니다. 마일스톤 생성이 새 조각을 계획할 때 그 절을 읽게 하는 일입니다.
7. **`tracker-labels:` 라벨 유일성은 묻지 않는다.** 조각 「묻지 않는 것」에 적었습니다. 소비자가 라벨 목록을 읽는 사이클(E5 사이클 배분 2 · 3)이 `dup` 행을 더할 자리입니다.
8. **정제 스캔은 값 패턴만 보았다.** 응답 본문이 스스로 싣는 비밀 필드를 두 라운드 동안 놓쳤고 리뷰 라운드 1의 반증이 잡았습니다. 외부 응답을 저장소에 보관하는 다음 사이클(가짜 어댑터)은 키 이름 스캔과 숫자 ID 대조를 처음부터 넣어야 합니다. 회고 후보입니다.
9. **녹화 응답의 꼴을 보관 때 대조하는 절차가 없다.** 원소 0 · 1개 배열이 저장 과정에서 풀린 것을 원본도 그대로 갖고 있었습니다. 이번에는 꼴만 되돌렸고 원 응답 바이트와 대조하지 못했습니다. 가짜 어댑터가 서는 사이클은 원 응답 문자열을 그대로 저장해야 합니다. 회고 후보입니다.
10. **흡수한 이슈의 함께 닫힘과 한 줄 다중 `Closes`는 재지 않았다.** 조각 「정의의 근거」와 E5 「유입」에 그 사실을 적었습니다. 유입을 구현하는 사이클(E5 사이클 배분 3)이 잽니다.