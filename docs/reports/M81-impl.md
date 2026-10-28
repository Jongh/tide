# M81 완료보고서 (impl)

## 개요

M81의 두 태스크를 구현했다. T01은 `site/docs/getting-started.md` 「5분 워크스루」의 release 항목에서 갱신 대상의 README를 빼, release 스킬의 실제 동작과 맞췄다(release가 고치는 문서는 CHANGELOG이고 README는 고치지 않는다. 버전 파일과 마일스톤 릴리즈 표지도 고치지만 워크스루는 기본 흐름만 적는다).
T02는 M80이 기준끼리의 충돌로 남긴 제목 줄 「### 수동 복사 (비권장 — 가드 hook 미포함)」의 줄표를 쉼표로 바꿨다(`README.md` · `getting-started.md`). 사이트 빌드의 제목 `id`가 전후 같고 저장소 안 링크가 0건임을 먼저 쟀다.
두 태스크가 같은 파일(`getting-started.md`)을 고치므로 겹침 판정대로 메인이 순차로 구현했다.

재작업 라운드(rework): 0

## 태스크별 수행 내용

- **M81-T01** — 「5분 워크스루」 5번의 「버전 범프 → CHANGELOG/README 갱신 → commit → tag → push」를 「버전 범프 → CHANGELOG 갱신 → commit → tag → push」로 고쳤다. 순서와 나머지 문장은 그대로다.
  - **같은 항목의 나머지 문장 대조**(기준: `skills/release/SKILL.md`의 프리플라이트 · 게시 분기 · 운영 주의)
    - 「우선 프리플라이트(판정 "가능" + 테스트 통과 + 워킹트리 확인)를 검사합니다」 — **맞음**. 스킬의 프리플라이트 다섯 가운데 모든 저장소에 걸리는 셋이다(리뷰 사소로 정정 — 셋째 워킹트리 확인은 막지 않고, 확인을 받은 뒤 진행하며 `continuous`면 확인 없이 진행한다. 문장은 「검사합니다」만 말하므로 결론은 그대로다). 나머지 둘은 사이트가 있는 프로젝트에만 걸리는 빌드 출력 스캔과 막지 않는 커버리지 advisory라, 기본 흐름만 적는 워크스루가 빼도 사실이 어긋나지 않는다.
    - 「추가로 `gh`(GitHub CLI)가 있으면 GitHub 릴리즈 게시와 릴리즈 PR 생성 중 하나를 옵트인으로 고를 수 있습니다」 — **맞음**. 게시 모드 `release` · `pr`이 그 둘이고, 모드 우선순위의 기본은 push-only다.
    - 「해당 단계는 tide 사이클에서 **git을 만지는 유일한 단계**입니다」 — **맞음**. git 쓰기는 `.tide/phase`가 `release`일 때만 가드를 통과한다. 문서 커밋 경로(`/tide:release docs`)도 같은 커맨드 안이다.
  - 범위어(「만」 · 「항상」 · 「할 수 있다」)를 바꾼 문장은 없다(`rf-92` 부류 — 사실을 더하지 않았다).
  - **같은 서술의 다른 자리 훑기** — 패턴 `수동 복사|비권장|README 갱신|README를 (고치|갱신)|CHANGELOG/README` · 대상 저장소 전체 파일(`docs/reports/` · `docs/milestones/` 제외 — 사이클 이력이라 고치지 않는다) · 대조 항목 「release가 README를 갱신한다는 서술」과 T02 제목 줄의 자리 · 루트 저장소(리뷰 사소로 정정 — 앞 판본은 실제로 돌린 검색보다 좁은 패턴 · 대상을 적었다).
    결과는 `getting-started.md`의 고친 줄 하나와 `skills/release/SKILL.md` 운영 주의 3의 「CHANGELOG/README 릴리즈 노트에 … 제외 용어를 literal로 쓰지 않는다」 하나다. 뒤의 것은 README를 갱신한다는 서술이 아니라 두 문서 모두에 쓰지 말라는 주의라 대상이 아니다(완료 기준 6도 `skills/` 변경을 막는다). `README.md` · `docs/commands.md`에는 같은 서술이 없다.
- **M81-T02** — 두 파일의 제목을 「### 수동 복사 (비권장, 가드 hook 미포함)」로 바꿨다. 두 파일의 문면은 같다.
  - **사이트 앵커** — 고치기 전 트리와 후 트리에서 각각 `mkdocs build --strict -f site/mkdocs.yml`(레포 루트 · 스크래치패드 venv)을 돌려 `getting-started/index.html`의 `id` 목록 전체를 `diff`로 비교했다. 차이 0이다. 그 제목의 `id`는 전후 모두 `hook`이다 — `toc` 확장의 기본 slugify가 비 ASCII 글자와 문장 부호를 버리고 `hook`만 남긴다.
  - **저장소 안 링크** — 패턴 `#hook\b|#%EC%88%98|수동-복사|getting-started(\.md|/)#|README\.md#` · 대상 `README.md` · `site/`(`.md` · `.yml`) · `docs/`(`docs/reports/` · `docs/milestones/` 제외) · `skills/` · `CHANGELOG.md` · 대조 항목 「그 제목의 사이트 `id`나 GitHub식 앵커를 가리키는 링크」 · 루트 저장소.
    결과는 `CHANGELOG.md`의 `README.md#changelog` 한 건이고, 다른 제목을 가리키므로 대상이 아니다. 같은 명령이 그 한 건을 잡는 것이 이 검색의 양성 통제다. 그 제목을 가리키는 링크는 0건이다.
  - **GitHub 앵커** — README의 GitHub 앵커는 제목 문면을 따르므로 바뀐다(`#수동-복사-비권장--가드-hook-미포함` → `#수동-복사-비권장-가드-hook-미포함`). 저장소 밖 링크는 잴 수 없다. 릴리즈 노트에 한 줄로 적을 것을 후속 1로 넘긴다.

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | `git diff --word-diff=plain -- site/docs/getting-started.md` → `[-CHANGELOG/README-]{+CHANGELOG+} 갱신`. 그 항목(5번)의 두 줄에 「README」 낱말이 없고 「CHANGELOG 갱신」이 남았다. 사이트 빌드 출력 `getting-started/index.html`에 「CHANGELOG 갱신」이 1건 있다 |
| 2 | 충족 | 위 T01 항목 — 나머지 세 문장이 각각 「맞음」이고 근거가 붙었다. 고친 문장은 하나이고 전후가 기준 1의 근거에 있다 |
| 3 | 충족 | ⑴로 닫혔다 — 두 파일의 제목이 같은 문면이다(`git diff --word-diff=plain` 두 줄이 `[-(비권장 —-]{+(비권장,+}`로 같다). 사이트 `id` 목록 전후 `diff` 차이 0 · 그 제목 `id`는 `hook`. 저장소 안 링크 훑기는 위 T02 항목의 네 축으로 0건(양성 통제 1건) |
| 4 | 충족 | 마지막 측정(이 보고서를 쓴 뒤): 아래 테스트 결과. 수는 `tests/discover/README.md`의 `cases:` 선언처를 가리킨다. sh 전수는 `measure-axis:`대로 CI가 판정한다 |
| 5 | 충족 | `mkdocs build --strict -f site/mkdocs.yml`(mkdocs 1.6.1) 정상 종료 · 산출물 55파일. 제외 용어(도출 1개 · `tests/lib/excluded-terms.sh`) Git Bash `grep -rlF` 스캔 0건(exit 1). 같은 명령을 그 용어를 담은 `README.md` 사본 하나가 든 대조 디렉터리에 돌리면 1건(exit 0) |
| 6 | 충족 | `git diff --name-only` → `README.md` · `docs/epics/E3.md` · `site/docs/getting-started.md`(미추적은 `docs/milestones/M81.md` · 이 보고서). `skills/` · `hooks/` · `docs/conventions*.md` · `tests/`는 0이다 |
| 7 | 충족 | 고친 문장은 기존 하십시오체 문장 안의 낱말 하나와 제목의 줄표 하나다. 새로 들어간 산문 줄표와 「」는 0이다(`git diff --word-diff=plain`의 더한 토큰이 `CHANGELOG` · `(비권장,` 둘뿐이다) |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M81-impl.md` |
| 수정 | `site/docs/getting-started.md` · `README.md` · `docs/epics/E3.md` |
| 삭제 | (없음) |

`docs/milestones/M81.md`와 `docs/epics/E3.md`(등재 한 줄)는 직전 `/tide:milestone`의 미커밋 산출물이다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (pwsh 7.6.9 · Windows PowerShell 5.1.26100 — 전수 / Git Bash `sh` — Part B · F 부분) | pwsh **608/0** · 5.1 **608/0** · sh B 14/0 · F 30/0(보고서 이전 기준선) |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — 규약 `measure-axis:`의 배당) | 릴리즈 단계에서 확인 |

- **마지막 측정**(이 보고서를 쓴 뒤의 트리) — 아래 값은 보고서를 쓴 뒤 다시 돌려 채웠다.
  - `pwsh -NoProfile -File tests/discover/run.ps1` → `# result: PASS=608 FAIL=0`
  - `powershell -NoProfile -File tests/discover/run.ps1` → `# result: PASS=608 FAIL=0`
  - 나머지 하니스 여섯(`multi-repo` 37 · `fleet` 45 · `fleet-cycle` 24 · `fleet-verify` 30 · `site-includes` 51 · `mutation` 12) → pwsh 7과 5.1에서 FAIL 0
- **보고서 이전 기준선** — 보고서가 없던 트리에서 pwsh 전수는 607/1이었다(`U6` — 완료 기준 대조가 M81을 건너뛴 수 1). 다른 붉음은 없었다. Git Bash `sh` Part B 14/0 · Part F 30/0.
- **캐시가 아닌 실행임을 확인한 방법**(`measure-not-cached`) — 하니스는 빌드 캐시가 없는 해석형 스크립트다. 보고서 이전과 이후의 전수 결과가 607/1 → 608/0으로 바뀌었고, 바뀐 것은 이 보고서를 읽는 `U6` 하나다.
- **생명주기 상태표** — 이 사이클은 기계 판정을 새로 세우거나 판정 조건을 바꾸지 않았다(러너 · 규약 변경 0). 그래서 `lifecycle-state-table`은 걸리지 않는다.

## 되돌림 실측

이 사이클은 새 케이스를 세우지 않았다. 그래서 M80과 같은 형태로, 고친 파일을 읽는 기존 본 검사가 그 파일에서 여전히 붉는지 잰다. 목록 줄의 둘은 고친 두 파일을 입력으로 읽는 기존 본 검사다.
규약 "되돌림 표의 선언 형식 (기계가 읽는다)" 절은 목록 줄을 「그 사이클이 새로 세운 본 검사」의 자리로 정의하고, 비우면 침묵 판정이 붉다. 새 케이스 없는 사이클의 형태는 규약에 없고 회고 `rf-90`이 받는다.

<!-- reversal-table:start -->
<!-- reversal-table-main: B1 F2 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| b1-gs | `getting-started.md`의 「커맨드 12종과 tide-guard hook이」를 「13종」으로 | adversarial | B1 | ps1 전수 605/3 · sh B 12/2 |
| b1-readme | README의 「현재 커맨드는 총 12종이며」를 「13종」으로 | adversarial | B1 | ps1 전수 606/2 · sh B 13/1 |
| f2-readme | README의 `verification-only`를 전부 `verification only`로 | adversarial | F2 | ps1 전수 606/2 · sh F 29/1 |

<!-- reversal-table:end -->

- **기준선** — 보고서 이전 트리에서 ps1 전수 **607/1**(`U6` — 보고서 부재) · sh B 14/0 · F 30/0. 표의 ps1 결과는 전부 `U6` 하나를 포함한 값이고, `붉은 케이스` 열에는 그 행이 더한 붉음만 적었다(`b1-gs`의 B1 둘은 같은 ID의 chk 둘 — 선언 수 · 드리프트 통제).
  - 드라이버는 스크래치패드의 `rev81.ps1`이다. 백업 키는 저장소 경로(`README.md` · `site__docs__getting-started.md`)이고, 백업 `bak81`은 이 사이클의 기준선에서 새로 떴다.
  - 행마다 앵커 수를 단언했다(한 번 바꾸는 행은 정확히 1 · 전부 바꾸는 행은 1 이상 — 어긋나면 `ANCHOR-MISS`, 0건). 매 행 앞과 끝에서 두 파일을 백업으로 되돌리고 해시로 대조했다(`RESTORE-MISMATCH` 0건 · 끝에 `RESTORED-OK`). 결과 줄 수가 요청 행 수(3)와 같다.
- **본 검사 단독 행** — 목록 줄의 둘은 각각 자기 하나만 붉는 행이 있다.
- **`adversarial` 행만 있는 까닭** — 판정 코드를 바꾸지 않았으므로 `broken`(판정을 무력화하는 변이)을 잴 대상이 없다. 재는 것은 고친 문서가 그 판정의 입력으로 여전히 쓰이는가 하나다.

## 미해결·후속 메모

1. **README GitHub 앵커가 바뀐다** — T02의 제목 변경으로 GitHub의 README 앵커가 `#수동-복사-비권장--가드-hook-미포함`에서 `#수동-복사-비권장-가드-hook-미포함`으로 바뀐다. 저장소 안에는 그 앵커를 가리키는 링크가 없고, 저장소 밖 링크는 잴 수 없다. 릴리즈 노트에 한 줄로 적는다(마일스톤 T02).
2. **되돌림 드라이버의 bash 경로** — 첫 실행에서 `C:\Program Files\Git\usr\bin\bash.exe`로 `sh`를 부르자 출력이 비었다(sh 결과 칸이 빈 채로 끝남 — 붉음도 초록도 아니다). `C:\Program Files\Git\bin\bash.exe`로 바꿔 다시 쟀고 표의 값은 그 실행의 것이다. 이미 알려진 함정이고(`rf-21` 군집) 이번에도 결과 행을 하나씩 읽어 잡았다.
3. **새 케이스 없는 사이클의 되돌림 목록** — M80에 이어 두 번째로 기존 본 검사로 채웠다. 규약이 이 형태를 정하는 것은 회고 `rf-90`의 몫이다.
4. **병렬 디스패치** — 두 태스크의 예상 변경 집합이 `site/docs/getting-started.md`에서 겹쳐, 규약대로 메인이 순차로 구현했다.
