# M80 완료보고서 (impl)

## 개요

M80의 태스크 넷(T01~T04)을 구현했다. 사이트가 직접 가진 소개 문서 넷(`README.md` · `site/docs/index.md` · `site/docs/getting-started.md` · `site/docs/concepts.md`)의
산문을 사용자의 업무 메일 어투로 다시 썼다. 하십시오체는 그대로 두고, 한 문장에 사실 하나 · 단정 대신 「~것으로 보입니다 / ~하시면 됩니다」 · 섹션마다 목적 문장 → 항목 → 「추가로」로 짰다.
코드 블록 · 백틱 토큰 · 링크 · 숫자 · 제목 · 표 구조는 네 파일 모두 HEAD와 같고, 하니스가 무는 자리(`B1` · `C3` · `C4` · `F2`)도 그대로 문다.
T02와 T03은 파일이 겹치지 않아 서브에이전트 둘로 병렬 디스패치했다. 메일 자료는 저장소 밖에 있고, 이 보고서와 문서 어디에도 원문을 옮기지 않았다.

재작업 라운드(rework): 0

## 태스크별 수행 내용

- **M80-T01**(읽기 전용 — 확정 결과)
  - **어투 기준표**는 마일스톤 T01의 표를 그대로 쓴다(끝맺음 · 판단 · 구성 · 제목 · 문장 · 연결어 · 강조 · 넣지 않는 것 · 커밋 메시지 아홉 행). 메일 원문은 적지 않는다.
  - **보존 목록과 계측 스크립트** — 스크래치패드 `m80-preserve.ps1`(저장소 밖)이 HEAD(`git show HEAD:{파일}`)와 작업 트리에서 다음을 뽑아 비교한다.
    코드 블록(펜스 안 전체의 SHA-256) · 코드 밖 백틱 토큰 다중집합 · 링크 대상 집합(`](...)`) · 백틱 · 링크를 지운 뒤의 숫자 토큰 다중집합 · 제목 줄 · 표 줄의 열 수 목록.
    어투 계측은 표 줄을 뺀 산문에서 백틱 토큰을 지우고 줄표(U+2014) · 「」(U+300C/U+300D) · 굵게(`**` 쌍)를 센다. 제목 줄은 산문 쪽에 들어간다.
  - **하니스가 무는 자리**(`tests/discover/run.sh`를 읽어 확정)
    - `B1` — README · `getting-started.md`에 「12종」이 있고 「13종」이 없다(`declared_has_count`).
    - `C3` — `concepts.md`에서 일곱 낱말(phase · milestone · impl · review · release · debug · cycle)이 모두 든 **첫 줄**의 백틱 토큰이 기록 명단 여섯이고, 비기록 명단 여섯이 4줄 창 안에 있다. 다른 문서에는 그런 줄 · 창이 없어야 한다.
    - `C4` — README에서 stable 열한 토큰이 4줄 창 안에 있고 그 창에 `/tide:debug`가 섞이지 않는다.
    - `F2` — README · `getting-started.md`가 review · release · fleet-verify를 언급하면 `refutation` · `gh` · `verification-only`가 있다(`role-anchors:`).
    - 추가로 README 3행의 외부 귀속 문장은 `tests/lib/excluded-terms.sh`가 제외 용어를 도출하는 자리라 뜻을 바꾸지 않는다.
    - **위 넷은 이 파일들을 「특정 문장으로」 읽는 케이스다. 파일 전체를 훑는 판정은 따로 있다**(리뷰 권장 1로 더함). 패턴 `site/docs|README\.md|\$README|SITE_GS|CONCEPTS`(주석 줄 · 다른 하니스 README 제외) ·
      대상 `tests/discover/run.sh` · `tests/site-includes/run.sh` · 대조 항목 「네 파일을 입력으로 읽는 판정」 · 루트 저장소로 훑은 결과다.
      Part G(`living_docs` — README와 `site/docs/*.md`의 인용 골격 · 제목 실재) · Part L(같은 살아 있는 문서 목록) · `tests/site-includes`(`site/docs/*.md` 전부와 README의 마커 · 제외 용어)가 더 있다.
      이 셋은 되돌림 목록에 넣지 않았다 — 고친 문장 중 그 판정의 입력이 되는 자리(인용 줄)는 손대지 않았고, 셋 모두 전수 초록으로만 확인했다.
      Part L은 소개 문서의 새 수 낱말을 묻지 않는다 — 리뷰가 `index.md`의 「아래 네 가지입니다」를 「다섯 가지」로 바꿔 sh Part L이 13/0 그대로인 것을 쟀다. 그래서 그 수 낱말은 리뷰가 지웠다(사소 2).
  - **변환 예시**(사이트 홈 `index.md`의 mermaid 다음 문단)
    - 전: 「`/tide:cycle`은 `milestone → impl → review`를 한 번에 이어 실행하고, git 작업을 하는 `release`만은 자동 체이닝에서 빼고 직전에 멈춰 안내합니다. `/tide:status`로는 언제든 현재 위치와 다음 커맨드를 읽기 전용으로 확인할 수 있습니다.」
    - 후: 「`/tide:cycle`은 `milestone → impl → review`를 한 번에 이어서 실행합니다. 대신 git 작업을 하는 `release`는 자동 체이닝에서 빼 두었고, 그 직전에 멈춰 다음 단계를 안내하도록 되어 있습니다. 추가로 `/tide:status`를 쓰시면 언제든 현재 위치와 다음 커맨드를 읽기 전용으로 확인할 수 있습니다.」
- **M80-T02** — `README.md`(서브에이전트 1)
  - 도입 · 사이클 산문 · 설치 · 명명 규약 · 규약 · 2.0 안정성 · 가산 이력 인용문 · gitignore 인용문 · CHANGELOG 문장을 기준표대로 고쳤다. 표는 `/tide:review` 행의 셀 하나만 고쳤다(굵게와 줄표를 괄호로).
  - stable 열한 토큰은 124행 한 줄에 남고 `/tide:debug`는 다음 줄에만 있다. `[docs/conventions.md](docs/conventions.md)의 "tide-guard hook" 절` 인용은 한 줄 그대로다.
  - 굵게 셋: 「오직 `release`에서만」(git 쓰기 규칙 — **HEAD에는 굵게가 아니었고 새로 넣었다**) · 「플러그인 커맨드를 가리므로」(옛 사본이 조용히 가리는 경고 — 남김) · 「하위 호환을 깨는 변경…은 다음 major(v3.0.0)에서만」(호환 약속 — 남김).
- **M80-T03** — `site/docs/index.md` · `getting-started.md` · `concepts.md`(서브에이전트 2)
  - `index.md` — 도입과 mermaid 뒤 문단을 문장마다 사실 하나로 나눴다. 「핵심 가치」는 목적 문장 한 줄 뒤에 굵게 + 줄표 머리를 「라벨:」 꼴로 바꿨다. 「시작하기」는 목적 문장과 읽을 곳 목록으로 바꿨다.
  - `getting-started.md` — 「설치」 · 「단축 경로」에 목적 문장을 더했다. 워크스루 1~5는 「`/tide:...`: ...」 꼴로 바꾸고 커맨드의 굵게를 뺐다. admonition(`!!! note` · `??? info`)의 여는 줄과 4칸 들여쓰기는 그대로다.
  - `concepts.md` — 항목 머리를 「제공 방식:」 · 「동작:」 꼴로 바꾸고 줄표와 굵게 대부분을 뺐다. 기록 명단 줄(19행)과 비기록 명단 창(23~25행 · 세 줄) · 인용 줄(47행)의 제약을 지켰다. 표는 그대로다.
  - 굵게 다섯: `index.md` 「상태 파일이 아직 없는 구간(fresh clone 직후)에는 보호가 없습니다.」(**HEAD에는 굵게가 아니었고 새로 넣었다**) · `getting-started.md` 「플러그인 커맨드를 가리므로」 · 「git을 만지는 유일한 단계」 · `concepts.md` 「`impl`·`review`는 절대 git 작업을 하지 않습니다.」 · 「fresh clone·신규 머신·플러그인 설치 직후에는 보호가 0」. 전부 조용히 깨지는 자리의 경고 또는 git 쓰기 규칙이다.
- **M80-T04** — 검증(아래 완료 기준 대조 · 테스트 결과 · 되돌림 실측). 보정할 것은 없었다.
- **마일스톤 밖 변경(이 사이클 트리에 함께 있다)** — 마일스톤 생성 뒤 사용자 요청으로 더했다.
  - `CLAUDE.md` — 함정 목록에 어투 항목 한 줄(「소개 문서와 커밋 메시지는 사용자의 메일 어투로 쓴다 — 기계가 묻지 않는다. 기준표는 `docs/milestones/M80.md`의 T01.」). 40줄 상한(`F15`)을 지키려고 정렬 항목의 「집행: F9~F13.」을 앞 줄에 붙였다(내용 손실 없음).
  - `docs/epics/E2.md` — 「M80 계획 중 드러난 것」 소절: 진입 문서 상한이 줄 수만 세어, 줄을 합치거나 늘려 상한을 피하는 경로가 있다는 실측과 처방 후보. 다음 사이클 후보다.
  - `docs/epics/E3.md` — 「속한 마일스톤」에 M80 등재.

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | `m80-preserve.ps1`(스크래치패드) 마지막 실행 — 대상 파일 집합 `README.md` · `site/docs/index.md` · `site/docs/getting-started.md` · `site/docs/concepts.md` · 대조 항목 코드 블록(해시) · 백틱 토큰 다중집합 · 링크 대상 집합 · 숫자 다중집합 · 제목 줄 · 표 열 수 · 비교 기준 `HEAD` 대 작업 트리 · 루트 저장소. 네 파일 모두 여섯 항목이 `same`이다. 처분할 차이는 없다 |
| 2 | 부분 | 산문 계측(전 → 후): README 줄표 21 → 1 · 굵게 36 → 3 · 「」 0 → 0 / `index.md` 5 → 0 · 12 → 1 · 0 → 0 / `getting-started.md` 11 → 1 · 21 → 2 · 0 → 0 / `concepts.md` 9 → 0 · 21 → 2 · 0 → 0. 남은 줄표 둘은 **제목 줄** 「### 수동 복사 (비권장 — 가드 hook 미포함)」(README · `getting-started.md`)에 있다. 기준 1이 제목 텍스트를 고정하므로 지우지 않았고, 계측 스크립트가 제목 줄을 산문 쪽에 세기 때문에 0이 되지 않는다. 제목 줄을 빼면 네 파일 산문의 줄표 · 「」는 0이다. 남긴 굵게 여덟의 자리와 사유는 T02 · T03 항목에 있다 |
| 3 | 충족 | 기준표는 마일스톤 T01 · 이 보고서 T01이 가리키고, 변환 예시 한 쌍이 T01에 있다. 자료 누출 검사(스크래치패드 `m80-leak.ps1`) — 패턴 29개(메일 자료의 사람 이름 · 회사명 · 시스템명 · 고유 ID 꼴 · 지명 · 업무 용어) + IP 꼴 정규식 1, 대상 파일 집합 `git ls-files`와 `git ls-files --others --exclude-standard`의 합(327개), 대조 항목 「패턴이 파일 본문에 나타나는가」(ASCII 패턴은 앞에 영숫자가 없을 때만 — `BASENAMES` 같은 단어 속 일치를 거른다), 루트 저장소. 결과 0건. 같은 형태의 양성 통제(메일 자료 자체)에서 30/30이 잡힌다. 패턴 자체는 적지 않는다 |
| 4 | 충족 | 마지막 측정(이 보고서를 쓴 뒤): 아래 테스트 결과. sh 전수는 `measure-axis:`대로 CI가 판정한다 |
| 5 | 충족 | 다른 하니스 여섯이 pwsh 7과 5.1에서 FAIL 0이다(아래 테스트 결과) |
| 6 | 충족 | `mkdocs build -f site/mkdocs.yml --strict`(스크래치패드 venv · mkdocs 1.6.1) 정상 종료 · 산출물 55파일. 제외 용어(도출 1개) 스캔 0건 · 빌드 출력의 `index.html`을 복사해 용어를 심은 대조 사본에서 같은 스캔이 1건. 고친 문장(「빼 두었고」)이 빌드 출력에 있는 것도 확인했다 |
| 7 | 충족 | `git diff --name-only` → `CLAUDE.md` · `README.md` · `docs/epics/E2.md` · `docs/epics/E3.md` · `site/docs/concepts.md` · `site/docs/getting-started.md` · `site/docs/index.md`. `skills/` · `hooks/` · `docs/conventions*.md` · `docs/commands.md` · `docs/orchestration.md` · `CHANGELOG.md`는 0이다 |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M80-impl.md` |
| 수정 | `README.md` · `site/docs/index.md` · `site/docs/getting-started.md` · `site/docs/concepts.md` · `CLAUDE.md` · `docs/epics/E2.md` · `docs/epics/E3.md` |
| 삭제 | (없음) |

`docs/milestones/M80.md`와 `docs/epics/E3.md`(등재 한 줄)는 직전 `/tide:milestone`의 미커밋 산출물이다. `CLAUDE.md` · `docs/epics/E2.md`는 마일스톤 생성 뒤 사용자 요청으로 고친 미커밋 변경이다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (pwsh 7.6.7 · Windows PowerShell 5.1.26100 — 전수 / Git Bash `sh` · `/usr/bin/dash` — Part B · C · F · G 부분) | pwsh **608/0** · 5.1 **608/0** · sh B 14/0 · C 30/0 · F 30/0 · G 18/0 · dash 같은 값 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — 규약 `measure-axis:`의 배당) | 릴리즈 단계에서 확인 |

- **마지막 측정**(이 보고서를 쓴 뒤의 트리)
  - `pwsh -NoProfile -File tests/discover/run.ps1` → `# result: PASS=608 FAIL=0`
  - `powershell -NoProfile -File tests/discover/run.ps1` → `# result: PASS=608 FAIL=0`
  - `sh tests/discover/run.sh {B|C|F|G}` · `/usr/bin/dash tests/discover/run.sh {B|C|F|G}` → 위 표의 값
  - 나머지 하니스 여섯(`multi-repo` 37 · `fleet` 45 · `fleet-cycle` 24 · `fleet-verify` 30 · `site-includes` 51 · `mutation` 12)은 pwsh 7과 5.1에서 FAIL 0이다.
- **보고서 이전 기준선** — 보고서가 없던 트리에서 pwsh · 5.1 전수는 607/1이었다(`U6` — 완료 기준 대조가 M80을 건너뛴 수 1). 다른 붉음은 없었다.
- **캐시가 아닌 실행임을 확인한 방법**(`measure-not-cached`) — 하니스는 빌드 캐시가 없는 해석형 스크립트다. 보고서 이전과 이후의 전수 결과가 607/1 → 608/0으로 바뀌었고, 바뀐 것은 이 보고서를 읽는 `U6` 하나다.
- **생명주기 상태표** — 이 사이클은 기계 판정을 새로 세우거나 판정 조건을 바꾸지 않았다(러너 · 규약 변경 0). 그래서 `lifecycle-state-table`은 걸리지 않는다.

## 되돌림 실측

이 사이클은 새 케이스를 세우지 않았다. 대신 **고친 문장이 기존 판정에 여전히 물리는가**를 잰다 — 목록 줄의 넷은 고친 파일을 읽는 기존 본 검사이고, 행마다 다시 쓴 문장에서 정상 편집 하나로 그 자리를 깨면 그 케이스가 붉는지 본다.

**규약 정의와의 차이(리뷰 권장 3으로 더함)** — 규약 "되돌림 표의 선언 형식 (기계가 읽는다)" 절과 impl 템플릿은 목록 줄을 「그 사이클이 새로 세운 본 검사」의 자리로 정의한다. 이 사이클에는 그런 케이스가 없고, 목록을 비우면 같은 절의 침묵 판정(판정이 읽지 못하는 보고서)이 붉는다. 새 케이스 없는 사이클이 따를 형태를 규약이 정하지 않았으므로 기존 케이스로 채웠다 — 규약의 빈자리로 후속 5에 넘긴다.

<!-- reversal-table:start -->
<!-- reversal-table-main: B1 C3 C4 F2 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| b1-readme | README의 「현재 커맨드는 총 12종」을 「13종」으로 | adversarial | B1 | ps1 전수 606/2 · sh B 13/1 |
| c3-concepts | `concepts.md` 기록 명단 줄에서 `cycle` 토큰을 지움 | adversarial | C3 | ps1 전수 603/5 · sh C 26/4 |
| c4-readme | README stable 명단 줄 머리에 `/tide:debug`를 더함 | adversarial | C4 | ps1 전수 605/3 · sh C 28/2 |
| f2-readme | README의 `verification-only`를 전부 `verification only`로 | adversarial | F2 | ps1 전수 606/2 · sh F 29/1 |

<!-- reversal-table:end -->

- **기준선** — 보고서 이전 트리에서 ps1 전수 **607/1**(`U6` — 보고서 부재) · sh B 14/0 · C 30/0 · F 30/0. 그래서 표의 ps1 결과는 전부 `U6` 하나를 포함한 값이고, `붉은 케이스` 열에는 그 행이 더한 붉음만 적었다.
  - 드라이버는 스크래치패드의 `rev80.ps1`이다. 백업 키는 저장소 경로(`README.md` · `site__docs__concepts.md`)이고, 백업 `bak80`은 이 사이클의 기준선에서 새로 떴다.
  - 행마다 앵커가 맞는지 단언했다(`rep`은 정확히 한 번 · `repall`은 한 번 이상 — 어긋나면 `ANCHOR-MISS`, 0건). 매 행 앞뒤에서 두 파일을 백업으로 되돌리고 해시로 대조했다(`RESTORE-MISMATCH` 0건). 결과 줄 수가 요청 행 수(4)와 같다.
- **본 검사 단독 행** — 목록 줄의 넷은 각각 자기 하나만 붉는 행이 있다. 같은 ID를 여러 chk가 나눠 쓰므로(`B1`은 파일마다 · `C3`은 개수 · 집합 · 서로소) 한 행에서 같은 ID가 여럿 붉을 수 있고, `붉은 케이스` 열은 ID로 적었다.
- **`adversarial` 행만 있는 까닭** — 판정 코드를 바꾸지 않았으므로 `broken`(판정을 무력화하는 변이)을 잴 대상이 없다. 재는 것은 다시 쓴 문서가 그 판정의 입력으로 여전히 쓰이는가 하나다.

## 미해결·후속 메모

1. **제목 줄의 줄표 둘** — 「### 수동 복사 (비권장 — 가드 hook 미포함)」(README · `getting-started.md`). 제목을 바꾸면 사이트 앵커가 바뀌어 기준 1(제목 고정)에 걸리므로 남겼다. 바꾸려면 앵커를 가리키는 링크가 없는지 먼저 훑고 별도 편집으로 한다.
2. **표 셀의 줄표** — README 커맨드 표의 셀 몇 곳(retro · status · debug · fleet · fleet-verify 행)에 줄표가 남아 있다. 기준 2의 계측 범위(표 밖 산문) 밖이라 고치지 않았다.
3. **진입 문서 상한** — `CLAUDE.md` 상한이 줄 수만 센다는 실측과 처방 후보는 `docs/epics/E2.md` 「M80 계획 중 드러난 것」 소절에 넘겼다. 이 사이클의 `CLAUDE.md`에 남은 줄 합침 하나도 그 소절이 적는다.
4. **어투를 기계가 묻지 않는다** — 줄표 · 굵게 계측은 이번 보고서의 일회성 측정이다. 다음 소개 문서 편집이 옛 문체로 돌아가도 하니스는 초록이다. `CLAUDE.md`의 함정 항목이 그 경계를 알린다.
5. **새 케이스 없는 사이클의 되돌림 목록** — 규약은 목록 줄을 새 본 검사의 자리로만 정의하고, 비우면 침묵 판정이 붉다. 이 사이클은 고친 파일을 읽는 기존 본 검사로 채웠다. 규약이 이 경우의 형태(기존 케이스로 채움 · 면제 선언 등)를 정해야 한다 — `docs/epics/E2.md`의 「M80 계획 중 드러난 것」 소절에 넘겼다.
6. **`getting-started.md` 워크스루 5번의 「CHANGELOG/README 갱신」** — release는 README를 고치지 않는다(CHANGELOG가 단일 원본이고 README는 포인터). 이번 사이클 이전부터 있던 부정확함이고, 이 마일스톤은 문장 어투만 바꾸므로 사실은 고치지 않았다.
7. **병렬 디스패치** — T02 · T03을 서브에이전트 둘로 동시 실행했다(파일 비겹침). 두 서브에이전트는 하니스를 돌리지 않고 보존 스크립트로만 자기 검사를 했고, 하니스 · 사이트 빌드 · 누출 검사는 메인이 두 결과를 합친 트리에서 돌렸다.
