# M100 실측 기록 (정제본)

M100-T04에서 비공개 GitHub 시험 저장소(`tide-tracker-probe`)에 쓰기 표의 명령으로 사이클 이슈 둘을 만들고, 그 이슈에 단계마다의 쓰기를 한 번씩 한 뒤 읽기 표의 명령으로 되읽은 결과다.
대조표는 `docs/reports/M100-impl.md`가 든다. 쓰기 항목의 이름과 쓰기 표는 `docs/conventions-tracker.md`의 `tracker-write-items:` 선언과 그 소절이, 보관 절차의 이름은 같은 조각의 `tracker-record-steps:` 선언이 든다.

실측 환경은 Windows 11 · Git Bash · `gh` 2.94.0이고 날짜는 2026-11-26이다. 명령은 시험 저장소의 사본 루트에서 표에 적힌 그대로 돌렸다. **표의 명령을 손으로 돌린 것이고 스킬을 돌린 것이 아니다.**

## 보관 절차를 어떻게 밟았는가

- **`rc-raw`** — 명령의 표준 출력 · 표준 오류를 파일로 바로 받았다. JSON을 읽어 다시 쓰지 않았고 정제는 문자열 치환으로만 했다. 치환 전후에 JSON 파일 열여섯마다 최상위 꼴(객체 · 배열과 그 길이)이 같은지 대조했고 어긋남은 0이었다.
  표준 출력 · 표준 오류 가운데 빈 쪽은 파일로 두지 않았다. PR 머지 명령은 두 쪽이 모두 비어 파일이 없다.
- **`rc-scan`** · **`rc-ids`** · **`rc-control`** — 스캔 항목마다 정제 전 원본에서의 건수와 정제본에서의 건수, 양성 통제를 따로 적는다.

| 스캔 항목 | 무엇을 찾는가 | 정제 전 원본 | 정제본 | 합성 양성 통제 | 바꾼 값 |
|---|---|---|---|---|---|
| 값 패턴 | `gh?_…` · `github_pat_…` · `glpat-…` 꼴의 토큰 값 | 0 | 0 | 1 | `TOKEN-MASKED` |
| 키 이름 꼴 | 이름에 `token` · `secret` · `password` · `passwd` · `private_key` · `api_key`가 든 JSON 키의 비어 있지 않은 문자열 값 | 0 | 0 | 1 | 해당 없음 |
| 계정 이름 | GitHub 계정 문자열(대소문자 무시) | 472 | 0 | 1 | `placeholder1` |
| 계정 숫자 ID | 계정의 숫자 ID와 같은 수(앞뒤가 숫자가 아닌 자리) | 34 | 0 | 1 | `1` |
| 노드 ID | `"node_id":"…"`의 값 | 35 | 0 | 1 | `NODE` |
| 아바타 URL | `avatars.githubusercontent.com/u/{숫자}` | 17 | 0 | 1 | `https://avatars.example/u` |

- 값 패턴과 키 이름 꼴은 원본에서 0건이었다. 이번 기록에는 인증 상태를 내는 명령이 없다. 그래서 두 항목의 양성은 항목마다 한 줄씩 심은 합성 문자열로만 확인했다. 나머지 넷은 원본에서 1건 이상이고 같은 합성 문자열에서도 1건씩 잡혔다.
- **남긴 것**(2026-11-26 사용자 확인) — 저장소 이름 `tide-tracker-probe`, 이슈 · PR 번호(1 · 6 · 7 · 8), 이슈 · 저장소 · 라벨 · 댓글 · 이벤트의 숫자 ID, 생성 시각, 닫힘 이벤트의 커밋 SHA 하나다. 응답 사이의 참조가 맞아야 가짜 어댑터 입력으로 쓸 수 있다.
- 정제본에 남은 메일 꼴 문자열은 `git@github.com` 하나다(저장소의 SSH 주소). 계정의 메일은 응답에 없었다.
- **가짜 어댑터 입력으로 쓸 때 알아 둘 것** — 계정 ID 자리의 `1`은 실제 ID 공간 안의 값이다. `gh issue view` · `gh issue list`의 출력은 `gh`가 `--json`으로 고른 필드만 낸 것이고, `gh api`의 출력은 REST 응답 그대로다.

## 사이클 이슈 하나 — 만들기부터 PR 머지의 닫힘까지 (이슈 6)

| 파일 | 쓰기 항목 · 읽기 항목 | 명령과 상태 |
|---|---|---|
| `write-00-cycle-list-before.json` | `rd-cycle-latest` | `gh issue list --label tide:cycle --state all --limit 1000 --json number,title,state` — 만들기 전. 사이클 이슈 넷(M99가 남긴 것) |
| `write-01-cycle-create.out.txt` | `wr-cycle-create` | `gh issue create --title "M4 — …" --label tide:cycle --body-file {본문 파일}` — 종료 코드 0, 표준 출력은 URL 한 줄 |
| `write-02-cycle-doc-after-create.json` | `rd-cycle-doc` | `gh issue view 6 --json number,title,body,state` — 만든 직후 번호로 읽었다 |
| `write-03-cycle-list-stale.json` | `rd-cycle-latest` | 위 목록 명령 — 만든 직후에 돌렸고 **이슈 6이 빠져 있다** |
| `write-03b-cycle-list-later.json` | `rd-cycle-latest` | 같은 목록 명령 — 다음 명령 묶음에서 다시 돌렸다. 이슈 6이 있다 |
| `write-04-epic-attach.json` | `wr-epic-attach` | `gh api repos/{owner}/{repo}/issues/1/sub_issues -X POST -F sub_issue_id={숫자 ID}` — 종료 코드 0, 응답은 에픽 이슈 |
| `write-05-epic-sub-issues-after.json` | `rd-epic-open` | `gh api repos/{owner}/{repo}/issues/1/sub_issues` — sub-issue가 이슈 2 · 6이다 |
| `write-05b-epic-open-after.json` | `rd-epic-open` | `gh issue list --label tide:epic --state open --limit 1000 --json number,title,body` — 에픽 이슈의 본문은 그대로다(체크리스트는 이슈 2 · 3) |
| `write-06-task-check-before.json` | `wr-task-check` | `gh issue view 6 --json number,title,body,state` — 고쳐 쓰기 전의 본문 |
| `write-07-task-check-edit.out.txt` | `wr-task-check` | `gh issue edit 6 --body-file {본문 파일}` — 종료 코드 0, 표준 출력은 URL 한 줄 |
| `write-08-cycle-doc-after-check.json` | `rd-cycle-doc` | 같은 읽기 명령 — 첫 태스크가 체크됐다. **읽기 출력의 끝 개행을 벗기지 않고 쓴 본문이라 끝 개행이 둘이다**(이 뒤에 하나로 되돌렸다) |
| `write-09-reread-changed.json` | `wr-task-check` | 같은 읽기 명령 — 첫 읽기와 쓰기 사이에 메타데이터 한 줄을 고친 뒤의 다시 읽기. 첫 읽기와 다르다(이 뒤에 그 줄을 되돌렸다) |
| `write-10-verdict-note.out.txt` | `wr-verdict-note` | `gh issue comment 6 --body-file {댓글 파일}` — 종료 코드 0, 표준 출력은 댓글 URL 한 줄 |
| `write-11-release-mark-edit.out.txt` | `wr-release-mark` | `gh issue edit 6 --body-file {본문 파일}` — 종료 코드 0 |
| `write-12-cycle-doc-after-mark.json` | `rd-cycle-doc` | 같은 읽기 명령 — 메타데이터 끝에 릴리즈 표지 줄이 있고 이슈는 열림이다 |
| `write-13-pr-create.out.txt` | `wr-cycle-close` | `gh pr create --base main --head release/v0.2.0 --title … --body-file {본문 파일}` — 본문에 닫힘 줄 한 줄. 브랜치와 그 커밋은 `gh api`로 만들었다 |
| `write-15-cycle-doc-after-close-pr.json` | `rd-cycle-doc` | 같은 읽기 명령 — `gh pr merge 7 --merge` 뒤. 이슈가 닫혔고 릴리즈 표지 줄은 그대로다 |
| `write-16-close-pr-timeline.json` | `wr-cycle-close` | `gh api repos/{owner}/{repo}/issues/6/timeline` — 라벨 · sub-issue 연결 · 댓글 · PR 참조 · 닫힘 |

## 사이클 이슈 둘째 — 기본 브랜치 커밋 메시지의 닫힘 (이슈 8)

| 파일 | 쓰기 항목 · 읽기 항목 | 명령과 상태 |
|---|---|---|
| `write-17-cycle-create-2.out.txt` | `wr-cycle-create` | 같은 만들기 명령(제목 `M5 — …`, 있어야 하는 구획 넷만) — 종료 코드 0 |
| `write-18-cycle-list-after-create-2.json` | `rd-cycle-latest` | 위 목록 명령 — 만든 직후에 돌렸고 **이슈 8이 바로 있다** |
| `write-19-cycle-doc-after-close-push.json` | `rd-cycle-doc` | `gh issue view 8 --json number,title,body,state` — 닫힘 줄이 든 커밋이 기본 브랜치에 올라간 뒤. 이슈가 닫혔다 |
| `write-20-close-push-timeline.json` | `wr-cycle-close` | `gh api repos/{owner}/{repo}/issues/8/timeline` — 라벨 · 닫힘(커밋이 닫았다) |

## 닿지 않을 때

| 파일 | 명령 | 종료 코드 |
|---|---|---|
| `write-21-comment-noauth.err.txt` | `gh issue comment 6 --body …`(빈 `GH_CONFIG_DIR` · 빈 `GH_TOKEN`) | 4 |
| `write-22-create-noauth.err.txt` | `gh issue create --title … --label tide:cycle --body …`(같은 환경) | 4 |

- 두 명령 뒤 이슈 6의 댓글 수와 저장소의 이슈 목록은 그대로였다. `gh auth logout`은 쓰지 않았다.
- 기본 브랜치의 커밋과 릴리즈 브랜치는 `git`이 아니라 `gh api`(브랜치 참조 만들기 · 파일 올리기)로 만들었다. tide의 릴리즈가 하는 `git push`와 같은 경로가 아니다 — 닫힘 줄이 든 커밋이 기본 브랜치에 닿는다는 점만 같다.
- **재지 않은 것** — 라벨이 없는 저장소에서의 만들기(시험 저장소에는 라벨 셋이 이미 있었다) · 에픽 이슈를 찾지 못한 경우 · 웹 화면에서 고친 본문(줄 끝이 CRLF일 수 있다) · 릴리즈 커밋 메시지와 PR 본문에 닫힘 줄이 함께 있을 때 · 다시 읽기와 쓰기 사이에 끼어든 편집 · 다른 계정의 권한 없는 저장소에 쓰기.
