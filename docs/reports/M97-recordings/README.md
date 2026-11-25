# M97 실측 기록 (정제본)

M97-T01(GitHub) · M97-T02(GitLab 14.9)에서 손으로 재현한 줄의 원 응답을 정제해 남긴 것이다.
다음 사이클들의 가짜 어댑터가 녹화 응답으로 쓴다. 재현표와 판정은 `docs/reports/M97-impl.md`가 든다.

## 정제 규칙

- 내부 호스트는 `gitlab.example`로, 사용자 이름 · 사용자명 · 이메일 · 아바타 URL · 노드 ID는 고정 자리표시자(`placeholder{N}` ·
  `name-placeholder` · `user@example.invalid` · `https://avatars.example/u` · `NODE`)로 바꿨다.
- 요청에 실은 토큰 · 쿠키 · 인증 헤더는 처음부터 기록하지 않았다. 다만 **응답 본문이 스스로 싣는 비밀 필드**가 하나 있었다 — `gitlab-00-project.json`의
  `runners_token`(러너 등록 토큰)이다. 재작업 라운드 2에서 `runners_token-placeholder`로 바꿨다(M97 리뷰 라운드 1이 잡았다).
- 토큰 스캔은 둘이다. 값 꼴(접근 토큰 값 · `gh?_…` · `glpat-` · `glrt-` · 러너 등록 토큰 접두)은 0건이다. 키 이름 꼴(`token` · `secret` · `password` ·
  `passwd` · `private_key` · `api_key`를 담은 키의 비어 있지 않은 문자열 값, 자리표시자 값은 뺀다)도 0건이다. 키 이름 스캔은 고치기 전 이 디렉터리와
  정제 전 원본에서 각각 1건(위 필드)을 잡았다(양성 통제).
- 고정 문자열 스캔(실제 내부 호스트 · 사용자 이름 · 사용자명 · 이메일 · 아바타 해시 · GitHub 계정 문자열)은 0건이다. 같은 스캔이 정제 전 원본에서는 660건을
  잡았다(양성 통제). GitHub 계정의 숫자 ID는 그 목록에 없어 남아 있었고, 재작업 라운드 2에서 `1`로 바꿨다(29곳 — 바꾼 뒤 그 숫자의 스캔은 0건).
- **남긴 것**(2026-11-25 사용자 결정): GitLab 내부 숫자 ID(사용자 · 프로젝트 · 그룹 · 이슈 · 노트 · 이벤트)와 내부 호스트의 포트, 커밋 SHA는 그대로다.
  호스트 이름이 `gitlab.example`이라 숫자만으로 인스턴스를 되짚을 수 없고, 응답 사이의 참조(이슈 ↔ 링크 ↔ 프로젝트)가 맞아야 가짜 어댑터 입력으로 쓸 수 있다.
  `gitlab-00-project.json`의 관리 필드(`permissions` · `creator_id` 등)도 같은 까닭으로 남겼다.
- GitHub 파일은 응답 본문 그대로다(`github-08-api-v4-version.json` 하나만 아래 봉투 꼴이다). GitLab 파일은 `{method, path, status, body}` 봉투이고,
  `status`가 HTTP 응답 코드다. `gitlab-08h-version-notoken-headers.json`은 예외로 `{headers, status, note}`다(헤더 이름 목록만 남겼다).
- **목록 응답의 꼴**: 목록 엔드포인트의 `body`는 배열이다. 여덟 파일은 저장 과정에서 원소 하나짜리 배열이 객체로, 빈 배열이 `null`로 풀려 있었다.
  재작업 라운드 2에서 배열로 되돌렸다 — `gitlab-00-labels-before.json` · `gitlab-06a-mr-closes-issues.json` · `gitlab-06a-mr-closes-issues-after.json` ·
  `gitlab-06a-cycle1-state-events.json` · `gitlab-06b-cycle2-state-events.json` · `gitlab-07c-open-untagged-after-absorb.json` ·
  `gitlab-07c-all-untagged-after-absorb.json` · `gitlab-09-open-after-cleanup.json`. 원본도 같은 꼴로 풀려 있어 원 응답 바이트와 대조하지는 못했다. 되돌린 것은
  꼴뿐이고 원소의 내용은 그대로다. 남은 객체 `body` 가운데 `GET` 200 응답은 모두 단일 자원 엔드포인트의 것이다(나머지 객체는 오류 본문 · GraphQL · 렌더 · 쓰기 응답이다).
- **가짜 어댑터 입력으로 쓸 때 알아 둘 어긋남**: 자리표시자는 고정 문자열별로 번호가 달라, `gitlab-00-project.json` 안에서 `name_with_namespace`와
  `path_with_namespace`의 자리표시자 번호가 서로 다르다. GitHub 계정 ID 자리의 `1`은 실제 ID 공간 안의 값이다. 키 이름 스캔은 키 전체가 영문자와 밑줄인
  문자열 값만 본다(이 디렉터리의 다른 꼴 키는 `+1` · `-1`뿐이다).
- `gitlab-00-labels-before.json`의 라벨 이름은 이름 키 규칙에 걸려 자리표시자가 돼 있었다. 사람 이름이 아니라서 원래 값(`Doing`)으로 되돌렸다.
- 인스턴스 관리자 전용 프로젝트 응답 하나(권한 없는 프로젝트를 재려던 요청)는 인스턴스 내부 정보라 보관하지 않았다.

## GitHub (비공개 시험 저장소 · `gh api`)

| 파일 | 줄 | 무엇의 응답인가 |
|---|---|---|
| `github-01-label-tide-{epic,cycle,backlog}.json` | 1 | 라벨 만들기 `POST /repos/{o}/{r}/labels` |
| `github-02-epic.json` | 2 | 에픽 추적 이슈 만들기 |
| `github-03-sub-issues.json` | 3 | 에픽의 `GET …/issues/{n}/sub_issues` — 사이클 이슈 둘 |
| `github-04-cycle-checklist.json` | 4 | 사이클 이슈 본문의 체크리스트 한 칸을 바꾼 뒤 |
| `github-05-epic-full.json` | 5 | 사이클 둘을 닫은 뒤 에픽(`body` · `body_html` · `sub_issues_summary`) — 체크리스트가 `[x]`로 바뀌었다 |
| `github-06a-pr-close-timeline.json` | 6 | PR 본문 `Closes #N` 머지로 닫힌 이슈의 타임라인 |
| `github-06b-push-close-timeline.json` | 6 | 기본 브랜치 커밋 메시지 `Closes #N`으로 닫힌 이슈의 타임라인 |
| `github-07a-open-issues.json` | 7 | 열린 이슈 전체(에픽 · 라벨 없는 외부 이슈 · `bug`만 붙은 외부 이슈) — `--search` 필터 질의의 입력 |
| `github-07b-backlog-sub-issue.json` | 7 | 흡수한 외부 이슈를 에픽에 sub-issue로 단 뒤 에픽 |
| `github-08-api-v4-version.json` | 판별 | GitHub API 호스트의 `GET /api/v4/version`(토큰 없음) — 404. GitLab 판별 경로가 GitHub 호스트와 갈린다(재작업 라운드 1에서 기록) |

## GitLab 14.9.3 (시험 프로젝트 · REST v4 · GraphQL)

| 파일 | 줄 | 무엇의 응답인가 |
|---|---|---|
| `gitlab-00-project.json` · `gitlab-00-labels-before.json` | — | 시험 프로젝트와 실측 전 라벨 |
| `gitlab-01-version.json` | 버전 | `GET /version` — `14.9.3` |
| `gitlab-01-label-*.json` | 1 | 라벨 다섯(`tide:` 셋 · 범위 라벨 시험용 둘) |
| `gitlab-02-epic.json` | 2 | 에픽 추적 이슈(본문 체크리스트 `- [ ] #1` · `- [ ] #2`) |
| `gitlab-02a-license.json` | 등급 | `GET /license` — 404(엔드포인트 없음) |
| `gitlab-02b-group-epics.json` · `gitlab-02f-group-iterations.json` | 등급 | 그룹 에픽 · 이터레이션 — 둘 다 404 |
| `gitlab-02c-link-blocks.json` · `gitlab-02c-cycle1-links.json` | 등급 | `link_type=blocks` 요청 — 201이지만 `link_type`은 `relates_to`로 저장됐다 |
| `gitlab-02c-link-type-enum.json` | 등급 | GraphQL `IssueLinkType` 타입 — 없음 |
| `gitlab-02d-scoped-{a,b}.json` | 등급 | 범위 라벨 `tide-probe::a` 뒤 `::b`를 붙였다 — 둘 다 남았다(배타 없음) |
| `gitlab-02e-workitem-types.json` · `gitlab-02e-issue-type-enum.json` | 등급 | Task work item — `workItemTypes`는 null, `IssueType`에 `TASK` 없음 |
| `gitlab-02g-schema-type-names.json` | 등급 | GraphQL 스키마 타입 이름 전부 — `Epic` · `Iteration` 타입 없음 |
| `gitlab-03a-cycle1.json` · `gitlab-03b-cycle2.json` | 3 | 사이클 이슈 둘(sub-issue가 없어 체크리스트 · 링크가 대체) |
| `gitlab-03c-link-relates.json` · `gitlab-03d-link-relates2.json` · `gitlab-03e-epic-links.json` | 3 | 사이클 → 에픽 `relates_to` 링크와 에픽 쪽 링크 목록 |
| `gitlab-04-cycle-checklist.json` | 4 | 사이클 이슈 본문 체크리스트 한 칸을 바꾼 뒤 |
| `gitlab-05-epic-full.json` · `gitlab-05-epic-after-close.json` | 5 | 사이클 둘이 닫힌 뒤 에픽 — 본문은 `- [ ]` 그대로, `task_completion_status` 0/2 |
| `gitlab-05-epic-rendered.json` | 5 | `POST /markdown`(gfm) 렌더 — 체크박스 미체크, 참조에 닫힘 표시 없음 |
| `gitlab-06a-*.json` | 6 | 브랜치 · 커밋 · MR(`Closes #1`) · 머지(첫 시도 406, 재시도 200) · `closes_issues`(만든 직후 빈 배열, 머지 뒤 1건) · 닫힌 이슈 |
| `gitlab-06b-*.json` | 6 | 기본 브랜치 git push 커밋 메시지 `Closes #2`로 닫힌 이슈와 그 노트 · 상태 이벤트 |
| `gitlab-07-external-{a,b}.json` | 7 | 라벨 없는 외부 이슈 둘 |
| `gitlab-07a-*.json` | 7 | `not[labels]=tide:epic,tide:cycle,tide:backlog` · `labels=None` · 전체 질의 |
| `gitlab-07b-absorb-{note,label}.json` | 7 | 외부 이슈에 댓글 한 줄 달기와 `tide:backlog` 붙이기(파일 이름의 `absorb`는 실측 당시의 표기다 — 규약 조각의 이름으로는 라벨 붙이기가 보류 `ti-defer`의 쓰기다) |
| `gitlab-07c-*.json` | 7 | 그 뒤 같은 질의(열림 · 전체) — `tide:backlog`가 붙은 이슈와 닫힌 사이클 이슈가 빠졌다 |
| `gitlab-08a-version-notoken.json` · `gitlab-08b-version-badtoken.json` · `gitlab-08h-version-notoken-headers.json` | 판별 | `/version` 토큰 없음 · 잘못된 토큰 — 둘 다 401, GitLab 이름이 든 헤더 없음 |
| `gitlab-08c-project-missing.json` | 판별 | 없는 프로젝트 — 404 |
| `gitlab-08e-token-self.json` | 판별 | `GET /personal_access_tokens/self` — 404(14.9에 없음) |
| `gitlab-08f-project-notoken.json` · `gitlab-08g-project-badtoken.json` | 판별 | 비공개 프로젝트를 토큰 없이 읽으면 404, 잘못된 토큰이면 401 |
| `gitlab-09-*.json` | 정리 | 남은 열린 이슈 셋을 닫은 응답과 닫은 뒤 열린 이슈 0건 |
