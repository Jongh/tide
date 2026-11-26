# M99 실측 기록 (정제본)

M99-T04에서 비공개 GitHub 시험 저장소(`tide-tracker-probe`)에 손으로 만든 이슈를 읽고, 판별 갈래를 한 번씩 밟은 결과다.
읽기 항목 대조표와 판별 표는 `docs/reports/M99-impl.md`가 든다. 보관 절차의 이름은 `docs/conventions-tracker.md`의 `tracker-record-steps:` 선언이 든다.

실측 환경은 Windows 11 · Git Bash · `gh` 2.94.0이고 날짜는 2026-11-26이다.

## 보관 절차를 어떻게 밟았는가

- **`rc-raw`** — 명령의 표준 출력 · 표준 오류를 파일로 바로 받았다. JSON을 읽어 다시 쓰지 않았고, 정제는 문자열 치환으로만 했다. 치환 전후에 JSON 파일마다 최상위 꼴(객체 · 배열과 그 길이)이 같은지 대조했다.
  표준 출력 · 표준 오류 가운데 빈 쪽은 파일로 두지 않았다(아래 표의 「없음」).
- **`rc-scan`** · **`rc-ids`** · **`rc-control`** — 스캔 항목마다 정제 전 원본에서의 건수(양성 통제)와 정제본에서의 건수를 따로 적는다.

| 스캔 항목 | 무엇을 찾는가 | 정제 전 원본 | 정제본 | 바꾼 값 |
|---|---|---|---|---|
| 값 패턴 | `gh?_…` · `github_pat_…` · `glpat-…` 꼴의 토큰 값(가려진 `gho_****`도 잡는다) | 2 | 0 | `TOKEN-MASKED` |
| 키 이름 꼴 | 이름에 `token` · `secret` · `password` · `passwd` · `private_key` · `api_key`가 든 JSON 키의 비어 있지 않은 문자열 값, 그리고 `Token:` · `Secret:` · `Password:`로 시작하는 줄의 값(자리표시자 값은 뺀다) | 2 | 0 | 위 치환이 함께 지웠다 |
| 계정 이름 | GitHub 계정 문자열(대소문자 무시) | 82 | 0 | `placeholder1` |
| 계정 숫자 ID | 계정의 숫자 ID와 같은 수(앞뒤가 숫자가 아닌 자리) | 4 | 0 | `1` |
| 노드 ID | `"node_id":"…"`의 값 | 5 | 0 | `NODE` |
| 아바타 URL | `avatars.githubusercontent.com/u/{숫자}` | 2 | 0 | `https://avatars.example/u` |
| 토큰 권한 범위 | `Token scopes:` 줄의 값(2026-11-26 사용자 결정으로 가렸다) | 2 | 0 | `SCOPES-MASKED` |

- 일곱 항목 모두 원본에서 1건 이상 잡혔다. 같은 스캔을 항목 일곱을 한 줄씩 심은 합성 문자열에도 돌려 각각 1건 이상을 확인했다(키 이름 꼴은 2건 — JSON 키 한 줄과 `Token:` 한 줄).
- 키 이름 꼴의 JSON 쪽은 원본에서 0건이었다 — 원본의 2건은 `gh auth status` 출력의 `Token:` 줄 둘이다. JSON 키 쪽의 양성은 합성 문자열로만 확인했다.
- **남긴 것**(2026-11-26 사용자 확인) — 저장소 이름 `tide-tracker-probe`, 이슈 번호와 이슈 · 저장소의 숫자 ID, 생성 시각, `gh` 버전이다. 라벨의 숫자 ID(`github-04-epic-sub-issues.json`의 `labels`)도 남아 있다 — 확인받은 목록에는 없었고 M99 리뷰가 찾았다. 비밀은 아니다. 응답 사이의 참조가 맞아야 가짜 어댑터 입력으로 쓸 수 있다.
- **가짜 어댑터 입력으로 쓸 때 알아 둘 것** — 계정 ID 자리의 `1`은 실제 ID 공간 안의 값이다. `gh issue list` · `gh issue view`의 출력은 `gh`가 `--json`으로 고른 필드만 다시 낸 것이라 REST 응답의 꼴이 아니다(어댑터 표가 읽는 것이 이 출력이다).

## 읽기 (어댑터 표의 명령 그대로)

| 파일 | 읽기 항목 | 명령과 상태 |
|---|---|---|
| `github-01-cycle-list.json` | `rd-cycle-latest` · `rd-cycle-all` | `gh issue list --label tide:cycle --state all --limit 1000 --json number,title,state` — 사이클 이슈 둘(열림 `M2` · 닫힘 `M1`)이 있을 때 |
| `github-02-cycle-doc-open.json` | `rd-cycle-doc` | `gh issue view 3 --json number,title,body,state` — 진행 중인 사이클(선택 구획 없음) |
| `github-02-cycle-doc-released.json` | `rd-cycle-doc` | `gh issue view 2 --json number,title,body,state` — 릴리즈 표지가 있는 닫힌 사이클(구획 일곱) |
| `github-03-epic-open.json` | `rd-epic-open` | `gh issue list --label tide:epic --state open --limit 1000 --json number,title,body` — 본문 체크리스트가 `#2` · `#3`을 든다 |
| `github-04-epic-sub-issues.json` | `rd-epic-open` | `gh api repos/{owner}/{repo}/issues/1/sub_issues` — sub-issue는 `#2` 하나다(`#3`은 체크리스트에만 있다) |
| `github-05-cycle-doc-malformed.json` | `rd-cycle-doc` | `gh issue view 4 --json number,title,body,state` — `## 완료 기준` 구획을 지운 사이클 이슈 |
| `github-06a-cycle-list-stale.json` | `rd-cycle-latest` | 같은 목록 명령 — 이슈 `#4` · `#5`를 만든 직후에 돌렸고 **둘 다 빠져 있다** |
| `github-06-cycle-list-duplicate.json` | `rd-cycle-latest` | 같은 목록 명령 — 몇 초 뒤 다시 돌렸다. `M3`으로 시작하는 이슈가 둘(`#4` · `#5`)이다 |

## 판별

| 파일 | 갈래 | 명령 | 종료 코드 | 다른 쪽 출력 |
|---|---|---|---|---|
| `detect-01-remote-url.out.txt` | `td-remote` | `git remote get-url origin` | 0 | 표준 오류 없음 |
| `detect-02-gh-version.out.txt` | `td-reach` | `gh --version` | 0 | 표준 오류 없음 |
| `detect-03-auth-ok.out.txt` | `td-reach` | `gh auth status` | 0 | 표준 오류 없음 |
| `detect-04-repo-view-ok.out.txt` | `td-reach` | `gh repo view --json nameWithOwner,isPrivate,viewerPermission` | 0 | 표준 오류 없음 |
| `detect-05-auth-none.err.txt` | `td-reach` · 미인증 | `gh auth status`(빈 `GH_CONFIG_DIR` · 빈 `GH_TOKEN`) | 1 | 표준 출력 없음 |
| `detect-06-repo-view-noauth.err.txt` | `td-reach` · 미인증 | `gh repo view --json nameWithOwner`(같은 환경) | 4 | 표준 출력 없음 |
| `detect-07-auth-badtoken.err.txt` | `td-reach` · 미인증 | `gh auth status`(`GH_TOKEN`에 틀린 값) | 1 | 표준 출력 없음 |
| `detect-08-repo-view-badtoken.err.txt` | `td-reach` · 미인증 | `gh repo view --json nameWithOwner`(같은 환경) | 1 | 표준 출력 없음 |
| `detect-09-repo-view-missing.err.txt` | `td-reach` · 저장소를 읽지 못함 | `gh repo view {계정}/tide-tracker-probe-does-not-exist --json nameWithOwner` | 1 | 표준 출력 없음 |
| `detect-10-remote-url-none.err.txt` | `td-remote` · `origin` 없음 | `git remote get-url origin`(원격 없는 저장소) | 2 | 표준 출력 없음 |
| `detect-11-repo-view-noorigin.err.txt` | `td-remote` · `origin` 없음 | `gh repo view --json nameWithOwner`(같은 저장소) | 1 | 표준 출력 없음 |

- 틀린 토큰은 실측용으로 지어낸 값이고 출력에 나타나지 않는다. `gh auth logout`은 쓰지 않았다 — 환경 변수로만 가렸다.
- **재지 않은 것** — 다른 계정의 비공개 저장소(권한 없음)의 응답이다. 읽을 수 없는 남의 비공개 저장소를 알지 못한다. 없는 저장소의 응답(`detect-09-repo-view-missing.err.txt`)과 같은 꼴인지는 확인하지 못했다.
- 연결 설정 파일의 세 칸(값 `local` · 값 `github` · 파일 없음)은 `gh`를 부르지 않는 파일 읽기라 응답이 없다. 결과는 impl 보고서의 판별 표에 있다.
