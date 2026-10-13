# M74 완료보고서 (impl)

## 개요

M74의 태스크 넷을 구현했다. 에픽 · 회고 문서를 릴리즈 밖에서 커밋하는 경로를 `/tide:release docs` 동작으로 열었다. 허용 경로는
`docs/conventions-release.md`의 `docs-commit-paths:` 한 줄이 들고, release 스킬의 새 절 「문서 커밋 경로」는 그 선언을 가리키기만 한다.
전제는 셋이다 — phase `idle` · 열린 debug 세션 없음 · 선언 밖 미커밋 변경 0. 그래서 하니스가 잰 작업 트리와 커밋되는 트리가 같다.
`pr` 모드면 `docs/{날짜}` 브랜치와 PR로 간다. 커맨드 12종 · phase 값 집합 · tide-guard 계약은 바뀌지 않았고, `tests/discover` Part S에
`S8`~`S19`가 섰다.

재작업 라운드(rework): 2

**라운드 2의 병렬 디스패치** — 리뷰 라운드 1의 반환을 다시 파일로 갈랐다. 스킬 · 규약 조각(차단 1 · 2, 권장 3 · 5, 사소 8)은 서브에이전트 하나에,
두 러너 · 하니스 README · 이 보고서(권장 4, 사소 6 · 7)는 메인에 두고 동시에 돌렸다(예상 변경 파일 비겹침).

**라운드 1의 병렬 디스패치** — 리뷰 라운드 0의 반환을 파일로 둘로 갈랐다. 스킬 · 규약 조각 · `README.md`(차단 1~4 · 권장 7 · 8 · 사소 10)는
서브에이전트 하나에, 두 러너 · 하니스 README(권장 5 · 6)는 메인에 두고 동시에 돌렸다(예상 변경 파일 비겹침). `docs/commands.md` 요약 표 한 줄과
이 보고서는 메인이 그 뒤에 고쳤다.

**라운드 0의 병렬 디스패치** — T01(설계)은 메인이 했다. 다음 레벨의 T02(규약 · 카탈로그 · `CLAUDE.md`)와 T03(`skills/release/SKILL.md`)은 예상 변경 파일이
겹치지 않아 **한 메시지에서 서브에이전트 둘로** 동시에 내렸다. 두 반환 모두 계약(수행 내용 · 변경 파일 · 검증 · 미해결)을 채웠다. T02는
마일스톤이 적지 않은 재서술처 하나(`docs/project-context.md`의 개념 블록)를 찾아 같은 편집에서 고쳤다. T04(두 러너 · README)는 두 서브에이전트가
도는 동안 메인이 썼다 — 러너 파일은 두 태스크와 겹치지 않는다.

## 라운드 2 — 리뷰 라운드 1 반환 처리

- **차단 1(`pr`이 아닌 모드 · 다른 브랜치에서 거짓 성공)** — 스킬 4단계를 **현재 브랜치 확인**으로 바꾸고 **모든 모드**에서 ③ 앞에 돌린다.
  기본 브랜치면 다음 단계로 간다. `docs/*`면 `gh`로 PR을 조회한다(없거나 조회가 실패하면 멈춰 안내). 그 밖의 브랜치면 멈춘다(기능 브랜치에서
  `docs/{날짜}`를 따거나 그 위에 커밋하지 않게). 11단계는 「머지 뒤 어느 모드로든 `/tide:release docs`를 다시 실행」으로 고쳤다. 규약
  「문서 커밋 전제」의 순서 문단과 「문서 커밋 게시」의 「현재 브랜치 확인(모든 모드)」 블록을 같은 편집에서 고쳤다.
- **차단 2(CI 판정을 소비하지 않는데 측정 배당을 씀)** — 이 경로는 **측정 배당을 쓰지 않는다**. 모든 축을 로컬에서 돈다. 규약 「문서 커밋
  프리플라이트」에 까닭(배당의 성립 조건인 「되돌릴 수 없는 단계 전에 CI 판정을 읽는 단계」가 이 경로에 없다)을 적었다.
- **권장 3(PR 없음 · 이름 충돌 · 브랜치 삭제)** — `docs/*`인데 PR이 없으면(push 거절이나 `gh pr create` 실패 뒤) `pr` 모드는 phase를 쓰고 브랜치를
  push한 뒤 PR을 연다. 다른 모드는 멈춰 안내한다. 브랜치 이름은 로컬과 원격(`git ls-remote --heads`)을 모두 보고 `-2` · `-3`을 붙인다. 로컬 삭제는
  버전 경로의 브랜치 정리를 따라 `-d`를 먼저, `gh`가 머지를 확인했을 때만 `-D`로 한다. 원격 브랜치는 지우지 않고(그것은 push다) 남아 있으면 보고한다.
- **권장 4(`/` 없는 선언 토큰)** — `S11`이 꼬리에서 `/`가 없는 값 모양 토큰을 형태 위반으로 센다(`dc_slashless`/`DcSlashless` — 공백 · 탭 · CR · VT · FF만으로
  된 토큰은 빼서 `S9`의 단독 행을 지킨다. `pwsh`는 같은 문자 집합을 명시해 `Trim()`의 NBSP 차이를 막았다). 되돌림 행 `slashless-token`을 더했다.
- **권장 5(가드를 일찍 엶)** — phase는 가드가 막는 git 쓰기(commit · push) **직전에만** 쓴다 — 8단계(커밋 앞)와 4단계 「PR 없음」 갈래(push 앞).
  머지 동기화(`fetch` · checkout · `pull` · 브랜치 삭제)는 phase를 쓰지 않는다. 버전 경로와 같은 규칙이다.
- **사소 6 · 7 · 8** — 이 보고서 후속 3의 중복 문장을 지웠다. `run.ps1` Part S 머리 주석을 라운드 1 · 2의 `S11` · `S12` 규칙에 맞췄다. `argument-hint`의
  괄호를 버전 형태에만 붙이고 `docs`에는 따로 짧은 설명을 붙였다.
- **되돌림 표를 라운드 2 트리로 전부 다시 쟀다** — 스무 행과 새 행 `slashless-token`, 표 밖 셋. 라운드 1과 값이 다른 행은 없다. 생명주기 상태 아홉도
  라운드 2 트리로 다시 쟀다(`life2/{상태}`) — 값은 같다.

## 라운드 1 — 리뷰 라운드 0 반환 처리

- **차단 1(`pr` 동기화에 닿지 못함)** — 스킬의 단계를 다시 놓았다: ①② → **`docs/*` 브랜치 상태**(4단계) → ③(5단계) → 에픽 등재 확인 →
  프리플라이트. 머지된 `docs/*` 브랜치에서 작업 트리가 깨끗하면 커밋할 것이 없어도 4단계가 동기화한다. 변경이 남아 있으면 동기화하지 않고
  멈춰 안내한다(checkout 충돌과 「잰 트리 ≠ 커밋 트리」를 피한다). 프리플라이트는 동기화 **뒤**에 돈다. 규약 「문서 커밋 전제」에 **순서** 문단을,
  「문서 커밋 게시」에 같은 순서를 적었다.
- **차단 2(phase 복원)** — 「phase를 `release`로 쓴 뒤의 모든 끝(중단 · 대기 · 끝냄 · 실패)은 `idle`로 되돌린 뒤 보고한다」를 절 머리의 공통
  규칙으로 두고, 규약에도 같은 규칙을 더했다. 미머지로 닫힌 PR은 회복 경로(기본 브랜치로 돌아가 로컬 브랜치 정리)를 보고하고 결정은 사용자에게 둔다
  (지우면 머지되지 않은 커밋을 버리기 때문이다).
- **차단 3(에픽 등재 동반이 대상 레포에서 넓음)** — 스킬에 **에픽 등재 확인** 단계(6단계)를 더했다. 바뀐 에픽 문서의 등재 블록에 있는
  `M{N}`마다 `docs/milestones/M{N}.md`가 작업 트리에 있어야 한다. ③ 뒤라 「있고 porcelain에 없다」는 「커밋돼 있고 바뀌지 않았다」이다. 그래서 이
  단계가 어느 레포에서든 고아 커밋을 막는다. 규약의 갈래 (ii)는 「이 단계가 막고, Part M은 이 저장소에서만 덧대는 백스톱」으로 고쳤다.
- **차단 4(모드 기억)** — 이 경로는 게시 모드를 **기억하지 않는다**. 「기억」 질문을 하지 않고 `.tide/release-mode`를 쓰지 않는다 — 그 파일은
  커밋되는 파일이라 ③이 막는다. 저장값도 인자도 없으면 이번 실행에서만 묻는다.
- **권장 5(`S12`가 글롭 · `..` · debug 보고서를 못 봄)** — 거부 접두사에 `docs/reports/debug-`를 더했다. 글롭 값 `X/*`는 **덮는 범위**로
  판정한다 — 거부 접두사가 `X/`로 시작하면 붉다(`docs/reports/*` · `docs/*`). `..` · `.` · 빈 경로 마디는 `S11`(형태)이 거부한다. 되돌림 행 셋을
  더했다(`deny-glob-reports` · `deny-debug` · `dotdot-escape`).
- **권장 6(`S11` 두 사본 갈림)** — `run.ps1`의 집합을 Ordinal `HashSet`으로 바꿨다. `case-cond` 행이 두 사본에서 같이 붉다.
- **권장 7 · 8** — ③을 `git status --porcelain -uall`로 적고 까닭(통째로 미추적인 디렉터리가 한 줄로 접힌다)을 붙였다. push 거절(원격이 앞섬
  등)은 자동 pull · force 없이 커밋을 로컬에 두고 「게시되지 않은 문서 커밋」으로 사유와 남은 push 줄을 보고한다.
- **사소 9** — 완료 기준 4의 근거 칸을 고쳤다. `S19`가 무는 것은 「세 파일(규약 본체 · `docs/commands.md` · `CLAUDE.md`)에 키가 **어딘가** 있는가」다.
- **사소 10** — `skills/release/SKILL.md`의 `description` · `argument-hint`, `README.md` 커맨드 표, `docs/commands.md` 요약 표의 `/tide:release` 행에
  `docs`를 더했다. 두 표의 첫 칸(서명)은 하니스가 맞추므로 그대로 두었다.
- **되돌림 표를 라운드 1 트리로 전부 다시 쟀다** — 기존 열여섯 행과 새 행 넷, 표 밖 셋. 기존 행 중 `deny-conventions`만 값이 바뀌었다(`S12` →
  `S12` · `S15`). 스킬의 에픽 등재 확인 단계가 `docs/conventions.md`를 인용해, 절 안에 그 경로가 생겼기 때문이다. `S12`의 단독 행은 이제 `deny-debug`다.

## 태스크별 수행 내용

- **M74-T01**(읽기 전용 설계)
  - **⑴ 인자** — `docs`는 게시 모드와 다른 축의 **동작 토큰**이다. 버전 토큰과 함께 오면 git 작업 없이 중단한다. `release` 모드는 이
    경로에서 GitHub 릴리즈 객체를 만들지 않으므로 push-only와 같게 동작한다.
  - **⑵ 선언** — 줄은 `docs/conventions-release.md`에 둔다(Part S가 이미 그 조각의 선언을 `CONV_REL`로 읽는다). 값은
    `docs/reports/retro.md` · `docs/epics/*` · `docs/project-context.md@docs/reports/retro.md`이다. 값은 꼬리를 ASCII 공백 **하나**로 쪼갠 토큰 중
    `/`를 담은 것이다. `/*`는 한 단계 아래 파일만 맞추고, 그 밖의 `*`는 없다. `@{값}`은 「같은 실행에 그 다른 선언 값도 바뀔 때만」이다 —
    이월 원장은 회고와 함께일 때만 허용된다(원장의 처분 행을 쓰는 것은 회고뿐이다).
  - **⑶ 전제 셋** — ① phase `idle`(파일 없음 = `idle`) ② `.tide/debug-session` 없음 ③ `git status --porcelain`의 모든 경로(미추적 포함)가
    선언 안이고 하나 이상이다(0이면 「커밋할 것 없음」으로 끝난다). 자율 수준과 무관하고, 어기면 어긴 경로를 보이고 중단한다.
  - **⑷ 에픽 등재 동반** — 갈래 셋이다(`lean-branches-stated`). (라운드 1에서 고쳤다 — 라운드 0은 (ii)를 Part M에 기대 별도 단계를 두지 않았고,
    리뷰가 「하니스는 대상 레포에서 돌지 않는다」로 반환했다.)
    - (i) 에픽이 등재한 `M{N}`의 문서가 미커밋이면, 그 문서가 선언 밖이라 ③이 멈춘다.
    - (ii) 그 문서가 아예 없으면, 스킬의 **에픽 등재 확인** 단계가 멈춘다 — 어느 레포에서든 성립한다. 이 저장소에서는 프리플라이트 하니스의
      Part M이 한 번 더 붉다(백스톱).
    - (iii) 이미 커밋돼 있으면 커밋된 트리도 정합하다.
    - 세 갈래 모두에서 고아 커밋이 나가지 않는다. 규칙의 문면은 규약의 「에픽 등재 동반 규칙」 항목이 든다.
  - **⑸ 프리플라이트** — release의 프리플라이트 2(테스트)와 4(사이트 빌드 출력 스캔)를 돌린다. (라운드 2에서 고쳤다 — 라운드 0 · 1은 프리플라이트 2의
    측정 배당까지 그대로 썼으나, 이 경로에는 CI 판정을 읽는 단계가 없어 **모든 축을 로컬에서** 돈다.) 1(판정 근거)과 5(커버리지)는
    돌지 않는다 — 버전을 내보내지 않고, ③이 선언 밖 스테이징이 없음을 보장한다.
  - **⑹ `pr` 상태 분기** — **③보다 먼저** 본다(라운드 1). 현재 브랜치가 `docs/*`이고 그 PR이 머지됐으면, 작업 트리가 깨끗할 때만 기본 브랜치를
    최신화하고 로컬 브랜치를 정리한 뒤 ③으로 간다(변경이 있으면 멈춰 안내). 열려 있으면 대기하고, 미머지로 닫혔으면 중단해 회복 경로를 보고한다.
    다른 `docs/*` PR이 열려 있으면 쌓지 않고 대기한다.
  - **⑺ 생명주기** — `lifecycle-transitions:`의 새 전이가 **아니다**. 작업 트리의 판정 입력을 바꾸지 않고 git만 쓰며, PR 브랜치를 만들어도 내용은 같다.
  - **⑻ 회귀 방향과 되돌림 행의 대응**:

    | 방향 | 되돌림 행 |
    |---|---|
    | 선언 중복 · 금지 구분자 · 빈 값 | `decl-dup` · `decl-trailing-tab` · `decl-emptied` |
    | 값의 형태(`@` 조건이 선언 밖) | `form-bad-cond` |
    | 값에 규칙의 원천(`docs/conventions.md`) 추가 | `deny-conventions` |
    | (라운드 1) 판정 보고서를 덮는 글롭 · debug 보고서 · `..`으로 `docs/` 밖 · `@` 조건의 대소문자 | `deny-glob-reports` · `deny-debug` · `dotdot-escape` · `case-cond` |
    | 실재하지 않는 값 | `value-missing` |
    | 스킬이 선언을 가리키지 않음 | `skill-key-gone` |
    | 스킬이 경로를 직접 열거함(재서술) | `skill-reenum` |
    | 회고 「돌지 않는 분기」에서 `docs` 동작이 빠지거나 앵커가 둘이 됨 | `item-docs-dropped` · `anchor-dup` |
    | 재서술처 셋 중 하나만 고침 | `claude-key-gone` · `commands-key-gone` · `conv-key-gone` |
    | 판정 함수 · 픽스처의 무력화 | `judge-dup-zero` · `judge-item-yes` |
    | 자율 조건을 이 경로에 닮(바닥 게이트) | `autonomy-in-docs` |
    | **오탐 방향 · 열린 경계**(초록이어야 한다) | `ok-docs-prose` · `ok-reenum-before` · `ok-item-meaning`(표 밖) |
- **M74-T02**(서브에이전트) — `docs/conventions-release.md`에 「문서 커밋 경로」 절(선언 줄 · 값의 의미 · 전제 셋 · 에픽 등재 동반 규칙 ·
  프리플라이트 · 게시 · 경계 · 집행 포인터)을 `[end:body]` 앞에 더했다. 재서술처를 같은 편집에서 고쳤다.
  - `docs/conventions.md`: tide-guard 절에 한 항목 · 「단계별 금지 행위 요약」의 release 행 · 「회고 후속 항목의 소비」의 회고가 돌지 않는 분기와 회고 산출물의 커밋 경로
  - `docs/commands.md`: `/tide:release` 상세 절의 인자 · 회고 분기 · 새 항목. 요약 표의 첫 칸은 하니스가 서명을 맞추므로 그대로 두었다.
  - `CLAUDE.md`: release 단계 줄
  - `docs/project-context.md`: 개념 블록의 「부수효과 분리」
- **M74-T03**(서브에이전트) — `skills/release/SKILL.md`에 넷을 더했다.
  - 인자 해석에 `docs` 동작
  - 「스테이징 범위」에 한 줄: 정의는 둘로 만들지 않았다.
  - 회고 「돌지 않는 분기」에 `docs` 동작: 셋 → 넷.
  - 새 절 `## 문서 커밋 경로 (docs)`: 열 단계.

  `autonomy` 줄 수는 3 그대로이고, 새 절에 `mkdocs build` · `gh pr checks` · 측정 배당 토큰 · 선언 값 경로가 없다(앵커 창 판정과 `S15`가 그것을 문다).
- **M74-T04**(메인) — 두 러너 Part S에 `S8`~`S19`, README Part S에 설명과 합 줄을 더했다. 케이스 수는 `tests/discover/README.md`의 `cases:` 한 줄이
  선언한다. 헬퍼는 파트 가드 **밖**에서 정의했다(`rf-60` — 가드 안 정의는 파트 선택에서 끊긴다). Part W의 `sec_span`은 가드 안이라 쓰지 않고
  같은 형태의 `dc_sec`/`DcSec`를 새로 두었다.
  - **`CLAUDE.md` 줄 상한** — T02가 더한 두 줄로 `F15`(40줄 상한)가 붉어, 메인이 같은 뜻을 기존 두 줄에 합쳤다(40줄).

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | `skills/release/SKILL.md` 「문서 커밋 경로」 절의 1~11단계가 인자 · 모드 검증(기억하지 않음) · 전제 ①② · 현재 브랜치 확인(모든 모드 · 라운드 2 — `docs/*`면 PR 상태와 동기화) · 전제 ③ · 에픽 등재 확인 · 프리플라이트(모든 축 로컬 · 라운드 2) · phase `release`(별도 단계) · 스테이징과 커밋 · push 또는 PR(거절 결과 포함) · phase `idle`을 적고, 절 머리가 「`release`를 쓴 뒤의 모든 끝은 `idle`로 되돌린다」를 적는다. 12단계가 버전 파일 · CHANGELOG · 태그 · 표지 · `gh release create` · 회고 자동 실행을 **하지 않는다**고 적는다. **범위 선언**: 패턴 `CHANGELOG` · `tag` · `released:` · `gh release create`, 대상 `skills/release/SKILL.md`의 그 절(제목부터 `## 운영 주의` 직전까지), 대조 항목은 그 단계를 **수행**하는 문장이 있는가, 루트 저장소 루트. 결과: 금지 목록(12단계) 안에만 있다. 절차가 정상 흐름에서 각 갈래에 닿는지는 하니스가 묻지 않는다(프롬프트 절차) — 라운드 1이 리뷰의 반환 넷을 순서와 갈래로 고쳤다 |
| 2 | 충족 | 선언 줄은 `docs/conventions-release.md`에 하나다(`S8`). 스킬은 키를 가리키고(`S14`) 절 안에 경로를 다시 적지 않는다(`S15`, 픽스처 `S16`). 두 러너가 유일성 · 추출(`S10`) · 금지 구분자(`S9`) · 허용 집합(`S11` 형태 · `S12` 행동 표면 · `S13` 실재)을 문다 — 두 사본 Part S 19/0 |
| 3 | 충족 | 스킬 「돌지 않는 분기」 항목에 `` `docs` `` 동작이 있고, `S17`이 앵커 첫 줄부터 그보다 깊은 연속 줄까지의 창과 앵커 유일성(`yes 1`)을 문다(픽스처 `S18`). 두 사본 초록 |
| 4 | 충족 | **범위 선언**: 패턴 `docs-commit-paths`, 대상 파일 `CLAUDE.md` · `docs/conventions.md` · `docs/commands.md` · `docs/project-context.md`, 대조 항목은 재서술처마다 문서 커밋 경로를 반영한 줄의 존재, 루트 저장소 루트. 결과: `CLAUDE.md` 19행(release 단계 줄) · `docs/conventions.md` 298행(tide-guard 절) · 1022행(회고 후속 항목의 소비) · 2175행(단계별 금지 행위 요약의 release 행) · `docs/commands.md` 144행(`/tide:release` 상세 절) · `docs/project-context.md` 100행(개념 블록). **`S19`가 무는 것은 「규약 본체 · `docs/commands.md` · `CLAUDE.md` 세 파일에 키가 어딘가 있는가」뿐이다** — 규약 본체의 세 자리 중 하나를 지워도 초록이고(`conv-key-gone`은 셋을 다 지웠다), 자리마다의 반영은 이 범위 선언(사람)이 본다. 사용자 표면 재서술(`argument-hint` · `description` · `README.md`와 `docs/commands.md`의 커맨드 표)은 라운드 1에서 더했다. **대상 밖으로 둔 것**(사실이 그대로라 고치지 않음): `README.md`의 가드 서술 · `docs/conventions.md`의 「git 쓰기는 release 단계에서만」 다른 자리 · `docs/conventions-release.md`의 「부수효과 분리·가드 불변」 · `site/docs/getting-started.md`의 「git을 만지는 유일한 단계」. 이 경로도 그 단계 안이라 모두 참이다 |
| 5 | 충족 | T01 ⑻의 방향마다 행이 있다(위 대응 표). 표의 열여섯 행 모두 두 사본에서 지목한 케이스가 붉다. 오탐 방향 · 열린 경계 셋은 두 사본 Part S 19/0이다. 값은 아래 되돌림 표 |
| 6 | 충족 | `ls skills/*/SKILL.md`가 12개다(B1). `git diff --stat -- hooks/`가 비었다. `docs/conventions.md`의 diff 덩어리 넷(296 · 1017 · 1020 · 2175행) 중 어느 것도 「상태 파일 (.tide/phase)」 절의 값 목록에 닿지 않는다. `autonomy-lines:` · `floor-marks:`는 전수에서 초록이다(`N12` · `N20` · Part L — 아래 테스트 결과). `autonomy-in-docs` 행이 그 결합을 실측했다(`N12` 붉음) |
| 7 | 충족 | F1 · F5는 `tests/discover` Part F가 문다 — 결과는 아래 「테스트 결과」 표. `run.ps1` 비-ASCII 바이트 **0**(`tr -d '\000-\177'` 뒤 0바이트) |
| 8 | 충족 | T01 ⑷에 갈래 셋과 갈래마다의 성립을 적었다 — (i) ③ · (ii) 스킬의 **에픽 등재 확인** 단계(어느 레포에서든 · 이 저장소에서는 Part M이 덧댄다) · (iii) 정합. 라운드 0은 (ii)를 Part M에 기대 대상 레포 갈래가 비어 있었고(리뷰 차단 3), 라운드 1이 그 갈래를 무는 단계를 스킬에 세웠다. 그 단계가 실제로 도는가는 프롬프트 절차이고 하니스는 묻지 않는다 |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M74-impl.md` |
| 수정 | `docs/conventions-release.md` · `docs/conventions.md` · `docs/commands.md` · `CLAUDE.md` · `docs/project-context.md` · `README.md`(라운드 1 · 커맨드 표) · `skills/release/SKILL.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` |
| 삭제 | (없음) |

기준선은 이 단계 시작 시점의 워킹트리다. `docs/milestones/M74.md`와 `docs/epics/E1.md`의 등재 한 줄은 milestone 단계의 미커밋 산출물이고,
`docs/reports/retro.md`는 v2.39.0 태그 뒤의 자동 회고 산출물이다. `docs/project-context.md`는 마일스톤의 파일 변경 요약에 없던 재서술처다(T02가 찾았다).

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (`pwsh` 7.6.6 Core · Windows PowerShell 5.1 · Git Bash `sh` · `dash`) | 아래 「마지막 측정」 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 전수 — `dash` · `bash`) | 릴리즈 단계에서 확인 |

**마지막 측정**(이 보고서를 쓴 뒤의 실행 — `measure-after-artifacts`):
- `pwsh -NoProfile -File tests/discover/run.ps1` — 552/0
- `powershell -NoProfile -File tests/discover/run.ps1` — 552/0
- `sh tests/discover/run.sh S` · `dash tests/discover/run.sh S` — 19/0
- `site-includes` · `fleet` · `fleet-cycle` · `fleet-verify` · `multi-repo` · `mutation`의 `run.ps1`(`pwsh` 7) — FAIL 0

**캐시·스킵이 아님을 확인한 방법**(`measure-not-cached`): 하니스는 빌드 캐시가 없는 셸 스크립트이고 실행마다 출력을 새로 낸다. 케이스 수가
540 → 552로 바뀌어 옛 트리의 값과 가려지고, 같은 트리에서 되돌림 행이 실파일 편집에 맞춰 붉었다가 복원 뒤 19/0으로 돌아오는 것을 행마다 보았다.

**구현 중 발견·수정한 이슈**
- `F15`(`CLAUDE.md` 40줄 상한)가 T02 편집 뒤 42줄로 붉었다. 같은 뜻을 기존 두 줄에 합쳐 40줄로 맞췄다.
- 되돌림 드라이버의 PowerShell 배열 펼침(`@(@(...))` 한 원소)으로 첫 실행이 전부 편집 실패했다. 실파일은 쓰기 전에 멈췄고 백업 대조가 깨끗했다. `@(,@(...))`로 고쳐 다시 쟀다.
- `ok-reenum-outside` 행은 변이를 「운영 주의」 제목 **앞**, 곧 문서 커밋 절 **안**에 넣어 `S15`가 붉었다. 판정이 아니라 드라이버의 자리 오류다. 절 제목 앞에 넣은 `ok-reenum-before`로 다시 재어 초록을 얻었다.

**생명주기 상태표**(`lifecycle-state-table`) — 새 판정 `S8`~`S19`가 읽는 입력은 `docs/conventions-release.md` · `docs/conventions.md` ·
`docs/commands.md` · `CLAUDE.md` · `skills/release/SKILL.md`와, `S13`이 실재를 묻는 선언 값의 경로(`docs/reports/retro.md` · `docs/epics/` ·
`docs/project-context.md`)다. 상태는 작업 트리 밖(세션 스크래치패드의 `life/{상태}`)에 `docs` · `skills` · `tests` · `hooks` · `.claude-plugin` · `.github` ·
`CHANGELOG.md` · `CLAUDE.md` · `README.md`를 복사해 만들었다. 결과는 상태마다 `sh`(Git Bash) · `pwsh` 7 두 경로의 Part S다. 라운드 1이 `S11` · `S12`의
판정 조건을 바꿨으므로 측정한 상태 아홉을 **라운드 1 트리로 다시** 쟀다(`life1/{상태}`) — 값은 라운드 0과 같다.

| 상태 | 사본에서 만든 방법 | 기대 | 실제 |
|---|---|---|---|
| ⑴ 사이클 중 | 사본 기준선 | 초록 | `sh` 19/0 · `pwsh` 19/0 |
| ⑵ 리뷰 뒤 릴리즈 전 | ⑴ + 판정 `가능`인 `docs/reports/M74-review.md` | 초록 | `sh` 19/0 · `pwsh` 19/0 |
| ⑶ 릴리즈 커밋 | ⑵ + `.claude-plugin/plugin.json`을 2.40.0으로 | 초록 | `sh` 19/0 · `pwsh` 19/0 |
| ⑷ 태그 뒤 후처리 전 | 해당 없음 — 트리가 ⑶과 같다(하니스는 git을 읽지 않는다) | — | — |
| ⑸ 태그 뒤 후처리 후 | 해당 없음 — `tr-retro`는 회고 문서의 내용만 바꾸고, `S13`은 그 파일의 실재만 본다 | — | — |
| ⑹ ⑵에서 다음 마일스톤 초안 | ⑵ + `docs/milestones/M75.md` | 초록 | `sh` 19/0 · `pwsh` 19/0 |
| ⑺ ⑶에서 다음 마일스톤 초안 | 해당 없음 — ⑶ · ⑹이 초록이고 둘이 바꾸는 입력이 모두 이 판정 밖이다 | — | — |
| ⑻ ⑷에서 다음 마일스톤 초안 | 해당 없음 — 같은 사유 | — | — |
| ⑼ debug 릴리즈 커밋 | 해당 없음 — `tr-debug-*`가 바꾸는 것은 debug 보고서와 `.tide/debug-session`이다(⒆에서 확인) | — | — |
| ⑽ 후처리 건너뛴 뒤 debug 릴리즈 커밋 | 해당 없음 — 같은 사유 | — | — |
| ⑾ 강행 릴리즈 커밋 | 해당 없음 — ⑶과 트리 형태가 같다 | — | — |
| ⑿ 파트 선택 실행 | 이 사이클의 되돌림 · 상태 측정이 전부 `run.sh S` · `run.ps1 -Part S`였다 | 전수와 같은 판정 | 두 사본 19/0 — 전수의 Part S 몫과 일치 |
| ⒀ ⑴·⑵에서 debug 릴리즈 뒤 후처리 후 | 해당 없음 — ⑼ · ⑸와 같은 사유 | — | — |
| ⒁ ⑹에서 debug 릴리즈 뒤 후처리 후 | 해당 없음 — 같은 사유 | — | — |
| ⒂ ⑹에서 직전만 릴리즈(강행) | 해당 없음 — ⑹ · ⑾의 입력이 모두 판정 밖이다 | — | — |
| ⒃ ⑹에서 둘을 한 태그로 | 해당 없음 — 같은 사유 | — | — |
| ⒄ 다음이 impl만 마친 채 강행 | 해당 없음 — 같은 사유 | — | — |
| ⒅ 대상 레포에서 처음 도는 릴리즈 | 사본 규약 조각에서 `docs-commit-paths:` 선언 줄을 지웠다 | 선언을 읽는 케이스가 붉는다 | 두 사본 **16/3** — `S8` · `S10` · `S16`. 이어서 `docs/project-context.md`가 없는 사본(대상 레포의 흔한 모양)은 두 사본 **18/1**(`S13`)이다. **문면으로 적는 값**: 하니스는 대상 레포에서 돌지 않는다. 대상 레포에서 도는 것은 스킬 절차이고, 선언은 플러그인 설치본의 규약 조각으로 해소된다 |
| ⒆ debug 세션 열림 | ⑴ + `.tide/debug-session`(내용 `3`) · `docs/reports/debug-3.md` | 초록 | `sh` 19/0 · `pwsh` 19/0 |
| ⒇ 판정 `불가`인 채 재작업 전 | ⑴ + 판정 `불가`인 `docs/reports/M74-review.md` | 초록 | `sh` 19/0 · `pwsh` 19/0 |
| `st-fail-then-draft` | ⒇ + `docs/milestones/M75.md` | 초록 | `sh` 19/0 · `pwsh` 19/0 |

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: S8 S9 S11 S12 S13 S14 S15 S17 S19 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| decl-dup | 선언 줄을 하나 더 | adversarial | S8 | sh-S 18/1 · ps1-S 18/1 |
| decl-trailing-tab | 선언 줄 끝에 공백과 탭 | adversarial | S9 | sh-S 18/1 · ps1-S 18/1 |
| decl-emptied | 선언 값을 모두 비움 | broken | S10;S16 | sh-S 17/2 · ps1-S 17/2 |
| form-bad-cond | `@` 조건이 선언에 없는 값을 가리킴 | adversarial | S11 | sh-S 18/1 · ps1-S 18/1 |
| deny-conventions | 값에 `docs/conventions.md` 추가 | adversarial | S12;S15 | sh-S 17/2 · ps1-S 17/2 |
| value-missing | 실재하지 않는 `docs/epicz/*` 추가 | broken | S13 | sh-S 18/1 · ps1-S 18/1 |
| skill-key-gone | 스킬에서 선언 키 세 자리를 지움 | broken | S14 | sh-S 18/1 · ps1-S 18/1 |
| skill-reenum | 스킬 문서 커밋 절에 `docs/epics/*`를 직접 적음 | adversarial | S15 | sh-S 18/1 · ps1-S 18/1 |
| anchor-dup | 문서 커밋 절에 `docs` 없는 「돌지 않는 분기」 항목을 하나 더 | adversarial | S17 | sh-S 18/1 · ps1-S 18/1 |
| item-docs-dropped | 「돌지 않는 분기」 항목에서 `docs` 토큰을 지움 | broken | S17;S18 | sh-S 17/2 · ps1-S 17/2 |
| claude-key-gone | `CLAUDE.md`에서 선언 키를 지움 | broken | S19 | sh-S 18/1 · ps1-S 18/1 |
| commands-key-gone | `docs/commands.md`에서 선언 키를 지움 | broken | S19 | sh-S 18/1 · ps1-S 18/1 |
| conv-key-gone | 규약 본체에서 선언 키 세 자리를 지움 | broken | S19 | sh-S 18/1 · ps1-S 18/1 |
| judge-dup-zero | 재열거 판정이 늘 0을 내게 | broken | S16 | sh-S 18/1 · ps1-S 18/1 |
| judge-item-yes | 회고 분기 판정이 늘 yes를 내게 | broken | S18 | sh-S 18/1 · ps1-S 18/1 |
| autonomy-in-docs | 문서 커밋 절에 자율 토큰 한 줄 | adversarial | N12 | sh-N 28/1 · ps1-N 28/1 |
| deny-glob-reports | 값에 `docs/reports/*` 추가(판정 보고서를 덮는 글롭 · 라운드 1) | adversarial | S12;S16 | sh-S 17/2 · ps1-S 17/2 |
| deny-debug | 값에 `docs/reports/debug-1.md` 추가(라운드 1) | adversarial | S12 | sh-S 18/1 · ps1-S 18/1 |
| dotdot-escape | 값에 `docs/../skills/release/SKILL.md` 추가(라운드 1) | adversarial | S11 | sh-S 18/1 · ps1-S 18/1 |
| case-cond | `@` 조건을 `@DOCS/reports/retro.md`로(대소문자 · 라운드 1) | adversarial | S11 | sh-S 18/1 · ps1-S 18/1 |
| slashless-token | 선언 줄 끝에 `/` 없는 ` CHANGELOG.md`(라운드 2) | adversarial | S11 | sh-S 18/1 · ps1-S 18/1 |

<!-- reversal-table:end -->

기준선은 두 사본 Part S **19/0**이다. 백업 키는 저장소 경로이고(파일 일곱 — 규약 본체 · 규약 조각 · 카탈로그 · `CLAUDE.md` · release 스킬 · 두 러너),
행마다 치환 건수를 단언했다(어긋나면 `EDIT-COUNT`로 멈춘다). 매 행 뒤 일곱 파일을 바이트 그대로 복원하고 `cmp`로 대조했다. 측정은 포그라운드
묶음(묶음당 7~9행)이었다. **라운드 2 트리로 표의 스물한 행과 표 밖 셋을 전부 다시 쟀다**(백업을 새로 떴다 — 라운드 1과 값이 다른 행 없음). 라운드 1에서도
**표의 스무 행과 표 밖 셋을 라운드 1 트리로 전부 다시 쟀다**(백업을 새로 떴다) — 라운드 0에서 잰 열여섯 행 중 값이 바뀐 것은
`deny-conventions` 하나다(`S12` → `S12` · `S15`: 라운드 1의 에픽 등재 확인 단계가 절 안에서 `docs/conventions.md`를 인용한다).

- **표 밖 행(초록이어야 한다)** — 전부 두 사본 Part S **19/0**:
  - 오탐 방향 `ok-docs-prose`: 문서 커밋 절에 경로 없는 산문 한 줄
  - 열린 경계 `ok-reenum-before`: 문서 커밋 절 **밖**(제목 앞)에 `docs/epics/*`를 적음 — `S15`는 절 안만 본다
  - 열린 경계 `ok-item-meaning`: `` `docs` `` 토큰을 둔 채 「회고를 그래도 돈다」로 항목의 뜻을 뒤집음 — `S17`은 토큰만 본다

  셋 다 README Part S가 「묻지 않는 것」으로 적는다.
- **`decl-emptied`는 `S16`도 붉힌다** — 픽스처가 첫 선언 값을 심는데 값이 비어 심을 것이 없다. 원인은 `S10`이 이름으로 지목한다.
- **`item-docs-dropped`는 `S18`도 붉힌다** — 통제가 원본과 사본의 차이를 묻는데 원본도 이미 `no`다. `S17`의 단독 행은 `anchor-dup`이다.
- **본 검사가 아닌 것의 사유**(`infeasible-evidenced`)
  - **`S10` · `S16` · `S18`** — 추출 positive-control과 픽스처 통제다. 각각 `decl-emptied` · `judge-dup-zero` · `judge-item-yes`가 붉힌다
    (`S16` · `S18`은 단독).
- **`deny-glob-reports`는 `S16`도 붉힌다** — 픽스처가 심는 첫 값(`docs/reports/retro.md`)이 새 값 `docs/reports/*`의 접두사에도 걸려 차이가 2가 된다.
  `S12`의 단독 행은 `deny-debug`다.
- **`adversarial` 행은 열둘이다** — 선언 쪽 아홉(중복 · 꼬리 구분자 · `@` 조건 · 규칙의 원천 · 판정 보고서 글롭 · debug 보고서 · `..` 탈출 · `@`
  대소문자 · `/` 없는 토큰)과 스킬 쪽 둘(직접 열거 · 앵커 중복), 자율 결합 하나다.

## 미해결·후속 메모

1. **런타임 동작은 묻지 않는다** — 전제 셋 · `pr` 상태 분기 · 브랜치 이름 규칙이 실제로 그렇게 도는지는 프롬프트 절차다(`rf-43` 부류).
   이 저장소에서 첫 실사용은 바로 v2.39.0의 미커밋 회고(`docs/reports/retro.md`)다. 다만 지금 트리에는 M74 사이클의 산출물이 있어 전제 ③이 막는다 —
   (가)의 설계대로다.
2. **절 밖의 재열거 · 「돌지 않는 분기」 항목의 뜻은 열린 경계다** — 표 밖 두 행이 그것을 쟀다. 막는 것은 리뷰의 몫이다.
3. **`S12`의 거부 집합은 러너에 있다** — `docs/` 밖 · `docs/conventions*` · `docs/commands.md` · `docs/milestones` · `docs/reports/M` · `docs/reports/debug-`(라운드 1에서 더함). 글롭 값은 덮는 범위로 접두사만 보고 깊이를 따지지 않는다(보수적). 규약은 「규칙의 원천과 판정을 가진 사이클 산출물」이라는 사유를 적지만 목록 자체는 러너가 든다. 선언으로 올릴지는 후속 판단이다(`rf-72`와 같은 부류 — 닫힌 것을 산문이 아니라 러너 값에서 파생하는 구조).
4. **`docs/epics/*` 커밋은 다음 릴리즈의 커버리지 advisory를 낼 수 있다** — 의도한 경계다(사이클 밖에서 바뀐 방향을 다음 릴리즈가 드러낸다).
   규약 「문서 커밋 경로」 절이 적는다.
5. **대상 레포에서 `docs/project-context.md`가 없으면 하니스는 `S13`을 붉힐 것이다**(⒅) — 하니스는 대상 레포에서 돌지 않으므로 사실은 아니다.
   스킬 절차에서 그 경로는 「없으면 맞출 변경이 없다」일 뿐이다.
