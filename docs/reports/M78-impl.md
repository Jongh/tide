# M78 완료보고서 (impl)

## 개요

M78의 태스크 넷(T01~T04)을 구현했다. 「자율 진행 (.tide/autonomy)」 절의 안전 바닥 목록은 지금까지 산문 열거(「열이다」 ⑴~⑽)였다. 이것을
이름 선언 `floor-items:`와 이름별 정의 항목으로 올렸다. 바닥과 표지의 분할(표지가 덮는다 · 표지가 없다 · 일부러 뺐다)은 선언 셋
(`floor-mark-map:` · `floor-unmarked:` · `floor-excluded:`)이 든다. 두 러너는 Part N에 열여섯 케이스(`N30`~`N45`)를 더해 선언 · 정의 · 칸 ·
표지 집합의 정합을 문다. 바닥 게이트의 동작과 `N12` · `N20`이 무는 것은 그대로다. `skills/` 변경은 0이다.

**라운드 1** — 리뷰 라운드 0(`docs/reports/M78-review.md`, 판정 `불가`)의 반환 아홉 항목을 처리했다.
- 차단 1: `N35`가 `floor-mark-map:`까지 네 줄을 문다. 규약 「기계가 묻는 것」의 추출 서술은 실제 케이스(직접 둘 · 간접 둘)에 맞췄다.
- 차단 2: 빠진 회귀 방향 여섯과 `floor-mark-map:` 구분자 행을 되돌림 표에 더했고, 표 전체를 이 트리에서 다시 쟀다. 재서술 검색은 영어 패턴을 더해 다시 훑었다.
- 권장 3 · 4와 사소 5~9도 함께 고쳤다.

재작업 라운드(rework): 1

## 태스크별 수행 내용

- **M78-T01**(읽기 전용 — 확정 결과)
  - **⑴ 이름** — `guard-gating` · `verdict-block` · `debug-session-block` · `preflight-stop` · `no-unmerged-tag` · `version-sanity` · `pr-ci-check` ·
    `residual-risk` · `redecompose` · `publish`. 순서는 옛 열거 ⑴~⑽와 같다. 스킬 병기어 `residual-risk-acceptance`와 철자를 일부러 다르게 뒀다.
    그 토큰은 `floor-marks:`의 표지이기도 해서, 같은 철자면 이름과 표지가 한 토큰으로 겹친다.
  - **⑵ 선언 형태** — M75 형태(이름 한 줄과 이름별 굵은 백틱 정의 항목)를 썼다. 선언과 정의는 「안전 바닥」 항목의 **하위 목록**에 둔다.
    절 머리의 선언 블록 바로 아래에는 `- **`autonomy-lines:`는 …**`처럼 정의 모양으로 시작하는 항목이 이미 있다. 정의 범위를
    「선언 줄부터 다음 제목까지」(M75의 `sp_defs`)로 잡으면 그 항목들이 고아 정의로 잡힌다. 그래서 범위를 「`floor-items:` 선언 줄부터,
    그 줄보다 얕게 들여쓴 비어 있지 않은 줄(또는 제목) 직전까지」로 잡았다. 지금 트리에서 그 범위는 `- **`/tide:fleet-cycle`은 대상이 아니다**`
    줄(들여쓰기 0)에서 끝난다. 이 범위는 선언 줄에 매달려 있다 — **선언 줄이 사라지면 정의 항목도 함께 보이지 않는다**. 그래서 선언 소실에서는
    `N37` · `N38`이 0으로 남고 `N30` · `N34` · `N42` · `N45`가 붉다(되돌림 `dir-decl-gone`).
  - **⑶ 표지 대응** — 후보 ⒝(별도 대응 선언)를 골랐다. 표지가 공백을 품으므로(`gh pr checks`) `floor-mark-map:`은 백틱 구획마다
    `이름=표지` 쌍 하나다. `publish`는 쌍이 셋이고, `gh release create`는 `no-unmerged-tag` · `publish` 두 이름에 대응한다. 옛 산문의 「⑸는 게시
    분기 창이 함께 덮는다」를 쌍 하나로 적은 것이다. 근거는 `skills/release/SKILL.md` 5번 항목이다 — 미머지 태그 금지 문장이 `gh release create`와 같은
    항목 창에 있다. 후보 ⒜(정의 항목마다 `mark:` 꼬리)는 뜻 문장과 기계 값이 한 줄에 섞이므로 버렸다.
  - **⑷ Part L과의 관계** — `l7-floor`는 러너 · 되돌림 표에 실재하지 않는다. `docs/reports/M52-impl.md` 464행의 되돌림 행 이름이었고(「열 → 아홉」으로
    고쳐 `L7`이 붉었다), README는 그 이름을 인용할 뿐이다. 열거를 선언으로 바꾸면 그 자리는 Part L의 대상에서 빠진다. 옛 방향(바닥 하나를 지움)은
    이제 지우는 자리에 따라 다른 케이스가 받는다(라운드 1에서 전부 실측 — 아래 되돌림 표).
    - 정의만 지움: `N37`(`n37-defdrop`)
    - 칸에서만 뺌: `N41`(`n41-classdrop`)
    - `floor-items:`에서만 지움: `N38`;`N42`(`dir-name-only` — 정의가 고아가 되고 칸의 이름이 선언 밖이 된다)
    - 선언 줄째 지움: `N30`;`N34`;`N42`;`N45`(`dir-decl-gone`)
    - 모든 바닥 선언 · 정의에서 함께 지움: 초록(규약의 ⒝)
    - 라운드 0은 「칸에 남긴 채 선언에서만 지우면 `N42`」의 근거로 `n42-stray`(칸에 새 이름을 더함)를 들었다. 그것은 다른 변이였다(리뷰 차단 2).
  - **⑸ 헬퍼 재사용** — Part W의 `sp_*`를 일반화하지 않고 Part N에 `fl_*`/`Fl*`를 따로 세웠다. 까닭은 셋이다.
    ⓐ 정의 범위의 끝 규칙이 다르다(위 ⑵).
    ⓑ `sp_def_bad` · `sp_def_orphan`은 규약 파일 인자를 받지 않는다.
    ⓒ M75 헬퍼는 선언 둘을 합쳐 읽는다.
    `fl_*`는 키와 규약 파일을 인자로 받으므로 `rf-79`의 다음 무리가 쓸 수 있다(후속 1).
  - **⑹ 분할 산문의 처분** — 「표지가 덮는 바닥 항목」 · 「표지가 없어 … 셋」은 선언 셋을 가리키는 한 항목으로 바꿨다. 「git 쓰기 게이팅 ⑴은 일부러 …」는
    이름(`guard-gating`)으로 가리키고 까닭 문장을 남겼다. 「집행이 미치는 자리는 셋이다」의 ⑴은 「이름 선언 · 정의 · 표지 대응의 정합」이 됐다.
    「기계가 막지 못하는 것」 ⒜는 `floor-unmarked:`를 가리킨다. 「기계가 묻는 것」 항목을 새로 두었다.
  - **⑺ 생명주기** — 기계 판정을 새로 세웠고 라운드 1에서 `N35`의 조건을 바꿨으므로 `lifecycle-state-table`이 요구된다. 판정 입력은 `docs/conventions.md`
    **하나**다. 아래 상태표는 라운드 1 트리에서 다시 쟀다.
  - **⑻ 회귀 방향** — 마일스톤 T01 ⑻의 목록 전부를 아래 되돌림 표와 표 밖 행이 덮는다. 대조는 아래 「완료 기준 대조」 기준 4 칸에 있다.
- **M78-T02** — `docs/conventions.md` 「자율 진행 (.tide/autonomy)」 절.
  - ⑴ `floor-marks:` 항목의 하위 불릿 셋을 선언 포인터와 까닭 문장으로 바꿨다.
  - ⑵ 「안전 바닥」 항목의 ⑴~⑽ 열거를 선언 네 줄과 정의 항목 열 개로 바꿨다.
  - ⑶ 「집행이 미치는 자리」 · 「기계가 막지 못하는 것」을 고쳤고 「기계가 묻는 것」을 더했다.
  - **라운드 1**:
    - 「기계가 묻는 것」의 구분자 · 추출 서술을 실제 케이스에 맞췄다(차단 1). 구분자는 네 줄 각각이다. 추출은 `floor-items:` · `floor-mark-map:`이
      직접이고, `floor-unmarked:` · `floor-excluded:`는 칸 대조의 간접 집행이다.
    - 묻지 않는 것에 「이름이 든 칸이 옳은가」를 더했다(사소 6).
    - ⒝에 `floor-marks:`를 넣었다(권장 4).
  - **`N20`과의 관계**: `floor_hits`는 `skills/*/SKILL.md`만 훑는다(`run.sh`의 `floor_hits` 호출 인자가 `$ROOT/skills`). 그래서 규약의 정의 항목은 `N20`에
    걸리지 않는다. 그래도 정의 항목 안에 `autonomy` 토큰은 두지 않았다.
- **M78-T03** — `tests/discover/run.sh` · `run.ps1`. 파트 가드 밖에 헬퍼를 정의했다(`fl_names` · `fl_pairs` · `fl_defs` · `fl_name_dup` ·
  `fl_def_bad` · `fl_def_orphan` · `fl_def_order` · `fl_class` · `fl_class_bad` · `fl_stray` · `fl_mark_missing` · `fl_mark_extra` · 픽스처 둘 — ps1은
  같은 이름의 `Fl*`와 `OrdSet`). 비교는 전부 ordinal(`LC_ALL=C` · `StringComparison.Ordinal` · `StringComparer.Ordinal`)이다.
  - **라운드 1**:
    - `N35`가 `floor-mark-map:` 꼬리까지 본다(기대값 `0000`).
    - 케이스 블록을 기존 `N24`~`N29` 뒤로 옮겼다. 두 러너 출력이 `N1`~`N45` 번호 순이다(사소 7).
    - `fl_marks` · `FlMarks`를 지우고 기존 `floor_marks` · `FloorMarks`가 규약 파일 인자를 받게 했다(사소 8).
    - 두 러너의 「자율 배선 선언 정합」 머리 주석이 「Part L이 바닥 열거 자체를 문다」고 현재형으로 적던 것을 고쳤다(권장 3 — `run.sh` 2731행 · `run.ps1` 2956행).
  - 라운드 0 경위: 처음에는 `N24`~`N39`로 붙였다가 기존 번호와 겹쳐 `N30`~`N45`로 옮겼다.
- **M78-T04** — `tests/discover/README.md`: `cases:` 줄(Part N 29 → 45, 총계 575 → 591) · Part N 머리 · 「안전 바닥은 세 자리가 나눠 문다」 ⑴ ·
  「사람의 영역 둘」 · 새 검증 블록(바닥 이름 축) · 「왜 둘 다 필요한가」 · 「묻지 않는 것」(⑼를 더하고 수사를 「아홉이다」로 고쳤다 — Part L).
  - 라운드 1:
    - 검증 블록의 `N35` 서술을 「네 선언 꼬리」로 바꿨고 추출의 간접 집행을 적었다.
    - ⑻에 `floor-marks:`를 넣고, ⑼에 「칸이 옳은가」를 더했다.
  - `CLAUDE.md` 27행:
    - 옛 「바닥 열거는 Part L이 문다」를 고쳤다.
    - 라운드 1에서 케이스 번호 범위 대신 「Part N의 바닥 이름 축」을 가리키게 했다(사소 5).
    - 같은 문장을 가진 로컬 `AGENTS.md`(`.gitignore` 12행 대상)도 맞췄다. 저장소 변경에는 들지 않는다.

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | `docs/conventions.md` 237행에 `floor-items:` 선언, 242~252행에 정의 항목 열 개가 있고 정의 순서가 선언과 같다(`N37` · `N39` 초록). 번호 열거 검색 — 패턴 `⑴`~`⑽` 열 글자와 `열이다` · 대상 「자율 진행 (.tide/autonomy)」 절(`### 자율 진행` 줄부터 `## 상태 파일 (.tide/phase)` 줄까지, 177~290행) · 대조 항목 「히트가 바닥 열거인가」 · 루트 저장소. 동그라미 히트 다섯 줄은 전부 바닥 열거가 아니다 — 「집행이 미치는 자리는 셋이다」의 ⑴⑵⑶(세 줄)과 「두 라운드가 실측으로 연 자리다」 문단의 ⑵ · ⑶(두 줄, 집행 자리 번호를 가리킨다). `열이다`는 0건이다 |
| 2 | 충족 | 대응이 이름 열을 전부 정확히 한 칸에 둔다(`N41` 0) · 칸에 든 이름이 전부 선언에 있다(`N42` 0) · 대응 표지 집합 = `floor-marks:` 집합(`N43` · `N44` 0). 분할 산문은 바닥을 선언 이름 · 선언 키로 가리킨다(기준 1의 검색 — 같은 절에서 바닥 번호 히트 0) |
| 3 | 충족 | 이름 리터럴 검색 — 패턴 바닥 이름 열 개 각각(고정 문자열) · 대상 `tests/discover/run.sh` · `run.ps1` · 대조 항목 「히트 줄이 M78 코드인가」 · 루트 저장소. 여덟 이름은 두 파일 모두 0줄이다. `residual-risk`는 두 파일 각 1줄로 기존 토큰 `residual-risk-acceptance`(sh 609행 · ps1 762행)의 부분 문자열이다. `publish`는 sh 1 · ps1 16줄로 HEAD와 같은 수이고 전부 기존 산문 · 주석의 낱말이다. 배선 통제 `N45` 초록이고, 되돌림 `n45-ctl`(이름을 소스에 박음)에서 두 사본 모두 `N45`가 붉다 |
| 4 | 충족 | 마일스톤 T01 ⑻ 목록의 방향마다 행이 있다(라운드 1 트리에서 전부 다시 쟀다).<br>• 선언: 지움 `dir-name-only` · 더함 `dir-name-add` · 중복 `n36-namedup` · 금지 구분자 `n35-sep` · `n35-mapsep` · 소실 `dir-decl-gone`.<br>• 정의: 지움 `n37-defdrop` · 복제 `n37-defdup`(리뷰 라운드 1이 잼 — impl은 재지 않았다) · 고아 `n38-orphan` · 순서 `n39-swap`.<br>• 표지 대응: 대응에서만 쌍 삭제 `dir-map-drop` · `floor-marks:`에서만 표지 삭제 `dir-marks-drop` · 두 칸 `dir-two-slot` · 칸 없는 이름 `n41-classdrop`.<br>• 배선: `n45-ctl`.<br>• 기존 회귀: `N12` · `N20` 픽스처 통제가 전수 측정에서 초록(아래 기준 5).<br>• 오탐 방향: `fp-def-text` · `fp-reason-text` 초록.<br>더해 라운드 0의 더하기 방향(`n43-missing` · `n44-extra`)과 적대 행 둘이 있다. 열거한 행 전부 지목한 케이스가 두 사본에서 붉다 |
| 5 | 충족 | 기존 바닥 집행 — 본 검사 `N12` · `N20`, 픽스처 통제 `N13` · `N14` · `N21` · `N23`, 음성 통제 `N15` · `N22`가 마지막 전수 측정에서 두 사본 초록이다(통제가 기대값 `1`로 초록이라는 것은 픽스처가 붉었다는 뜻이다). `dir-marks-drop`에서 `N21` · `N23`이 함께 붉는 것은 픽스처가 그 표지(`gh pr checks`)를 쓰기 때문이다. 옛 `l7-floor` 방향(바닥 하나를 지움)은 위 T01 ⑷의 행들이 받는다 |
| 6 | 충족 | 규약 「안전 바닥」 항목의 「기계가 묻는 것」 하위 항목(묻지 않는 것 셋 — 정의 문장의 뜻 · 대응과 스킬 창 · 칸이 옳은가)과 「기계가 막지 못하는 것」 ⒜⒝, README Part N 「묻지 않는 것」 ⑺ · ⑻ · ⑼가 같은 경계를 적는다 |
| 7 | 충족 | `CLAUDE.md` 27행을 고쳤다.<br>• 재서술 검색(라운드 1에서 다시 돌림): 도구 pwsh `Select-String`(대소문자 무시).<br>• 한국어 패턴 `바닥 열거` · `표지가? 없는 바닥 셋` · `바닥 ⑴` · `게이팅 ⑴` · `열이다` · `사람의 영역으로 남는 것` · `바닥 셋` · `열거 자체` · `바닥.{0,20}Part L` · `Part L.{0,40}바닥`.<br>• 영어 패턴(`.ps1`은 ASCII 전용이라 따로 둔다) `floor.{0,40}enumeration` · `enumeration.{0,40}floor` · `Part L.{0,60}floor` · `floor.{0,60}Part L` · `safety.floor.{0,30}` 뒤에 `list` · `ten` · `10` 중 하나.<br>• 대상 `*.md` · `*.sh` · `*.ps1` · `*.json` · `*.yml` 80개 · 대조 항목 「옛 열거를 현재형으로 다시 적는가」 · 루트 저장소 · 뺀 것 `docs/milestones/` · `docs/reports/`(역사 기록) · `.git/`.<br>• 히트 열둘(한국어 여섯 · 영어 여섯), 고유 줄 열(README 1095행 · `run.sh` 2731행은 두 패턴 모두에 걸렸다) 처분: 규약 3131행 「`계열이다`」 · README 1203 · 1453행(「부분 문자열이다」) — 무관. README 1095행과 `run.sh` 3068행 · `run.ps1` 3381행 케이스 주석 — 옛 형태를 과거형으로 인용. `run.sh` 2731행 · `run.ps1` 2956~2957행 — 라운드 1에서 고친 머리 주석(과거형). `run.ps1` 3149행 — M78 헬퍼 주석.<br>• `docs/project-context.md`는 `autonomy` · `floor` · `자율` 0줄이다 |
| 8 | 충족 | 마지막 전수 측정에서 두 러너 총계가 같다(F1). `run.ps1` 비-ASCII 바이트 0(Git Bash `LC_ALL=C grep -c "$(printf '[\200-\377]')" tests/discover/run.ps1` → 0 · `F5` 초록 — 리뷰 라운드 1이 명령을 재현 가능한 형태로 고쳤다. 작은따옴표 안 8진은 펼쳐지지 않아 다른 값을 낸다). `cases: 591` = 실측(`F1` · `F1b` 초록) |
| 9 | 충족 | `git status --porcelain -- skills/` 출력 0줄 |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M78-impl.md` |
| 수정 | `docs/conventions.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` · `CLAUDE.md` |
| 삭제 | (없음) |

`docs/milestones/M78.md`와 `docs/epics/E2.md`(등재 한 줄)는 직전 `/tide:milestone`의 미커밋 산출물이고, `docs/reports/M78-review.md`는 리뷰 라운드 0의 미커밋 산출물이다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (pwsh 7.6.7 · Windows PowerShell 5.1 — 전수 / Git Bash `sh` · `dash` — Part N 부분) | pwsh **591/0** · 5.1 **591/0** · sh Part N **45/0** · dash Part N **45/0** |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 전수 — 규약 `measure-axis:`의 배당) | 릴리즈 단계에서 확인 |

- **마지막 측정**(이 보고서를 쓴 뒤의 트리)
  - `pwsh -NoProfile -File tests/discover/run.ps1` → `# result: PASS=591 FAIL=0`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tests/discover/run.ps1` → `PASS=591 FAIL=0`
  - `sh tests/discover/run.sh N` → `# 부분 결과(Part N): PASS=45 FAIL=0` · `dash tests/discover/run.sh N` → 같은 값
  - 나머지 하니스 여섯(`multi-repo` · `fleet` · `fleet-cycle` · `fleet-verify` · `site-includes` · `mutation`)은 pwsh에서 전부 FAIL 0이다.
- **캐시가 아닌 실행임을 확인한 방법**(`measure-not-cached`) — 하니스는 빌드 캐시가 없는 해석형 스크립트다. 라운드 1 작업 중 Part N 출력의 케이스 순서가
  `N23 → N30`에서 `N29 → N30`으로 바뀐 것을 보았다. 실행이 바뀐 소스를 읽었다는 증거다. 전수 결과 줄의 총계도 실측 케이스 수와 같다(`F1`).
- **사본 무결성** — 리뷰 라운드 0이 impl의 상태표 사본에서 `tests/lib`가 측정 뒤 비어 있는 것을 보았다(저장소 밖 정리로 보인다). 라운드 1의 사본은 모두 새로
  떴고, 행마다 `tests/lib` 파일 수(9)를 찍었다.

**생명주기 상태표**(`lifecycle-state-table`) — 판정 입력은 `docs/conventions.md`의 선언 다섯 줄(`floor-items:` · `floor-mark-map:` · `floor-unmarked:` · `floor-excluded:` · `floor-marks:`)과
정의 범위뿐이다. 전이 표의 전이 중 이 파일을 바꾸는 것은 없다. 전이가 바꾸는 입력은 마일스톤 문서 · 보고서 · 버전 파일 · CHANGELOG · 회고 · 표지 · 에픽 · `.tide/`다. 그래서 판정별
격자는 ② 단계에서 전부 항등이 되어 목록 밖 상태를 내지 않는다. 그래도 목록의 상태를 작업 트리 밖 사본(`.git` 없는 복사 — 스크래치패드 `lc78r1-s{n}`, 라운드 1 트리)으로 만들어
Part N을 두 사본에서 돌렸다. 사본마다 `tests/lib` 9개를 확인했다. 상태 칸의 전이는 규약 상태 목록의 인용을 따른다.

| 상태 | 사본에서 만든 방법 | 기대 | 실제 |
|---|---|---|---|
| ⑴ 사이클 중 — `tr-draft` `tr-impl` | 사본 기준선(M78 문서 · impl · 리뷰 라운드 0 보고서가 있는 트리) | 초록 | pwsh-N 45/0 · sh-N 45/0 |
| ⑵ 리뷰 뒤 릴리즈 전 — ⑴ + `tr-review` | ⑴ + 판정 `가능`인 `docs/reports/M78-review.md` | 초록 | 45/0 · 45/0 |
| ⑶ 릴리즈 커밋 — ⑵ + `tr-release-commit` | ⑵ + `plugin.json` 2.44.0 · M78에 `- released: v2.44.0` | 초록 | 45/0 · 45/0 |
| ⑷ 태그 뒤 후처리 전 — ⑶ + `tr-tag` | ⑶과 같은 트리(하니스는 git을 읽지 않는다 — 파생 규칙 4ⓑ) | 초록 | ⑶과 같음 |
| ⑸ 태그 뒤 후처리 후 — ⑷ + `tr-retro` | ⑶ + `retro.md` 최상단에 v2.44.0 섹션 | 초록 | 45/0 · 45/0 |
| ⑹ ⑵에서 다음 마일스톤 초안 — ⑵ + `tr-draft` | ⑵ + `docs/milestones/M79.md` 초안 | 초록 | 45/0 · 45/0 |
| ⑺ ⑶에서 다음 마일스톤 초안 — ⑶ + `tr-draft` | ⑶ + M79 초안 | 초록 | 45/0 · 45/0 |
| ⑻ ⑷에서 다음 마일스톤 초안 — ⑷ + `tr-retro-skip` + `tr-draft` | ⑺과 같은 트리(회고를 건너뛴 ⑷ = ⑶ 트리 + 초안) | 초록 | ⑺과 같음 |
| ⑼ debug 릴리즈 커밋 — ⑸ + `tr-debug-open` + `tr-debug-done` + `tr-debug-release` | ⑸ + `docs/reports/debug-3.md` | 초록 | 45/0 · 45/0 |
| ⑽ 후처리를 건너뛴 뒤 debug 릴리즈 커밋 | 해당 없음(사유: 판정 입력이 ⑼과 같다 — 차이는 회고 섹션뿐이고 이 판정은 회고를 읽지 않는다) | — | — |
| ⑾ 강행 릴리즈 커밋 — ⑴ + `tr-forced` | ⑴ + 버전 · 표지 | 초록 | 45/0 · 45/0 |
| ⑿ 파트 선택 실행 — `tr-part-select` | `run.sh N` · `run.ps1 N` 부분 실행(헬퍼가 파트 가드 밖) | 초록 | 위 모든 행이 부분 실행 값이다 · 전수도 초록 |
| ⒀ ⑴·⑵에서 debug 릴리즈 태그 뒤 후처리 후 | 해당 없음(사유: ⑼ · ⑸의 입력 조합 — 이 판정이 읽는 규약 파일은 같다) | — | — |
| ⒁ ⑹에서 debug 릴리즈 태그 뒤 후처리 후 | 해당 없음(사유: ⒀과 같다 — 초안 유무는 이 판정의 입력이 아니다) | — | — |
| ⒂ ⑹에서 직전 마일스톤만 강행 릴리즈 | 해당 없음(사유: ⑾ + 초안 — 둘 다 측정했고 규약 파일은 같다) | — | — |
| ⒃ ⑹에서 다음 사이클까지 마친 뒤 함께 릴리즈 | 해당 없음(사유: ⑺과 같은 입력 — 이 판정은 마일스톤 · 보고서 수를 읽지 않는다) | — | — |
| ⒄ 다음 마일스톤 impl만 마친 채 강행 | 해당 없음(사유: ⑾과 같은 입력) | — | — |
| ⒅ 대상 레포(다운스트림)에서 처음 도는 릴리즈 — ⑵ + `tr-downstream` + `tr-release-commit` | 문면으로 적는다: 하니스는 참조 구현 저장소 안에서만 돈다. 바닥 목록은 스킬이 규약 절을 가리켜 읽는 **규칙**이고 대상 레포별 값이 없다. 이 저장소 사실을 담은 값(번호 · 경로)도 선언에 없다 | 값 없음 | 해당 없음(규칙만 전파) |
| ⒆ 진행 중 사이클에 debug 세션이 열린 채 — ⑴·⑵ + `tr-debug-open` | ⑴ + `.tide/debug-session` · 판정 없는 `debug-3.md` | 초록 | 45/0 · 45/0 |
| ⒇ 리뷰 판정 `불가`인 채 재작업 전 — ⑴ + `tr-review`(`불가`) | ⑴ + 판정 `불가`인 M78 리뷰 보고서 | 초록 | 45/0 · 45/0 |
| `st-fail-then-draft` — ⒇ + `tr-draft` | ⒇ + M79 초안 | 초록 | 45/0 · 45/0 |

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: N36 N37 N38 N39 N41 N42 N43 N44 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| n30-dup | `floor-items:` 선언 줄을 한 줄 더 | broken | N30 | ps1 전수 590/1 · sh-N 44/1 |
| n31-dup | `floor-mark-map:` 선언 줄을 한 줄 더 | broken | N31 | ps1 전수 590/1 · sh-N 44/1 |
| n32-dup | `floor-unmarked:` 선언 줄을 한 줄 더 | broken | N32 | ps1 전수 590/1 · sh-N 44/1 |
| n33-dup | `floor-excluded:` 선언 줄을 한 줄 더 | broken | N33 | ps1 전수 590/1 · sh-N 44/1 |
| n34-empty | `floor-items:` 꼬리를 비움 | broken | N34;N38;N42;N45 | ps1 전수 587/4 · sh-N 41/4 |
| n35-sep | `floor-unmarked:` 줄 끝에 탭 | broken | N35;N41;N42 | ps1 전수 588/3 · sh-N 42/3 |
| n34-mapempty | `floor-mark-map:` 꼬리를 비움(리뷰 라운드 1이 잼) | broken | N34;N41;N43 | ps1 전수 588/3 · sh-N 42/3 |
| n35-mapsep | `floor-mark-map:`의 구획 사이 공백을 탭으로(라운드 1 — 리뷰 차단 1의 재현) | broken | N35 | ps1 전수 590/1 · sh-N 44/1 |
| n36-namedup | `floor-items:` 끝에 `publish`를 한 번 더 | broken | N36 | ps1 전수 590/1 · sh-N 44/1 |
| n37-defdrop | 정의 항목 `redecompose` 줄을 지움 | broken | N37 | ps1 전수 590/1 · sh-N 44/1 |
| n37-defdup | 정의 항목 `redecompose` 줄을 한 번 더 씀(리뷰 라운드 1이 잼) | broken | N37 | ps1 전수 590/1 · sh-N 44/1 |
| n38-orphan | 선언에 없는 정의 항목 `zz-orphan`을 더함 | broken | N38 | ps1 전수 590/1 · sh-N 44/1 |
| n39-swap | 정의 항목 `verdict-block` · `debug-session-block` 두 줄만 맞바꿈 | broken | N39 | ps1 전수 590/1 · sh-N 44/1 |
| n40-ctl | 두 러너의 순서 판정이 선언 이름을 읽지 않게 함(sh `_flol=''` · ps1 이름 루프를 빈 배열로) | broken | N40 | ps1 전수 590/1 · sh-N 44/1 |
| n41-classdrop | `floor-unmarked:`에서 `redecompose`를 뺌 | broken | N41 | ps1 전수 590/1 · sh-N 44/1 |
| n42-stray | `floor-unmarked:`에 선언에 없는 `zz-stray`를 더함 | broken | N42 | ps1 전수 590/1 · sh-N 44/1 |
| n43-missing | `floor-marks:`에 대응 없는 표지 `zzz-mark`를 더함 | broken | N43 | ps1 전수 590/1 · sh-N 44/1 |
| n44-extra | `floor-mark-map:`에 `floor-marks:`에 없는 쌍 `publish=zzz-mark`를 더함 | broken | N44 | ps1 전수 590/1 · sh-N 44/1 |
| n45-ctl | 두 러너의 칸 판정이 이름 열 개를 소스에 박은 목록으로 돎(선언을 읽지 않음) | broken | N45 | ps1 전수 590/1 · sh-N 44/1 |
| dir-name-only | `floor-items:`에서만 `redecompose`를 지움(정의 · 칸은 그대로 — 라운드 1) | adversarial | N38;N42 | ps1 전수 589/2 · sh-N 43/2 |
| dir-name-add | `floor-items:`에 정의 · 칸 없는 이름 `zz-new`를 더함(라운드 1) | adversarial | N37;N41 | ps1 전수 589/2 · sh-N 43/2 |
| dir-decl-gone | `floor-items:` 선언 줄을 지움(라운드 1 — 정의 범위도 함께 사라진다) | adversarial | N30;N34;N42;N45 | ps1 전수 587/4 · sh-N 41/4 |
| dir-two-slot | `floor-excluded:`에 `verdict-block`을 더함(두 칸 — 라운드 1) | adversarial | N41 | ps1 전수 590/1 · sh-N 44/1 |
| dir-map-drop | 대응에서만 쌍 `pr-ci-check=gh pr checks`를 지움(`floor-marks:`에는 남음 — 라운드 1) | adversarial | N41;N43 | ps1 전수 589/2 · sh-N 43/2 |
| dir-marks-drop | `floor-marks:`에서만 표지 `gh pr checks`를 지움(대응에는 남음 — 라운드 1) | adversarial | N21;N23;N44 | ps1 전수 588/3 · sh-N 42/3 |
| adv-def-outside | 정의 항목 `redecompose`를 범위 밖(`/tide:fleet-cycle` 항목 뒤)으로 옮김 | adversarial | N37 | ps1 전수 590/1 · sh-N 44/1 |
| adv-map-move | 대응 쌍 `pr-ci-check=gh pr checks`를 `residual-risk=gh pr checks`로(바닥 하나가 칸을 잃음) | adversarial | N41 | ps1 전수 590/1 · sh-N 44/1 |
<!-- reversal-table:end -->

- **기준선** — 라운드 1 트리(이 보고서의 라운드 0 판본 · 리뷰 보고서가 있는 트리)에서 ps1 전수 **591/0** · sh Part N **45/0**이다. 표의 모든 행을 이 트리에서 다시 쟀다.
  드라이버는 스크래치패드의 `rev78.ps1`이다.
  - 백업 키는 저장소 경로(`docs__conventions.md` 등 세 파일)이고, 라운드 1용 백업 `bak78r1`을 새로 떴다.
  - 행마다 치환 건수가 정확히 1인지 단언했다(어긋나면 `ANCHOR-MISS`로 멈춘다 — 0건).
  - 매 행 앞에서 세 파일을 백업으로 되돌렸고, 끝에 해시로 대조했다(`RESTORE-MISMATCH` 0건).
  - 결과 줄 수 = 요청 행 수(10 · 10 · 9 · 1)를 확인했다.
- **본 검사 단독 행** — 목록 줄의 여덟 케이스는 각각 자기 하나만 붉는 행이 있다(`n36` · `n37` · `n38` · `n39` · `n41` · `n42` · `n43` · `n44`). 선언 · 추출 통제
  (`N30`~`N35`)와 순서 · 배선 통제(`N40` · `N45`)도 각자 붉는 행이 있다. 여럿을 함께 붉히는 행은 입력을 비우거나 오염시키는 변이 · 두 판정에 동시에 걸치는 방향이다
  — 통제는 단독 요구의 대상이 아니다.
- **표 밖 행**(두 사본 초록)
  - 오탐 방향 `fp-def-text`: 정의 항목 `redecompose`의 문구만 고침 — ps1 전수 591/0 · sh-N 45/0.
  - 오탐 방향 `fp-reason-text`: 「`guard-gating`을 일부러 표지에서 빼는 까닭」 문장의 문구만 고침 — 591/0 · 45/0.
  - 정의 복제(같은 이름 정의 두 줄)는 impl이 재지 않았고, 리뷰 라운드 1이 재어 표에 `n37-defdup`으로 더했다(`N37`만 붉다). 같은 리뷰가 `N34`의 대응 쪽 절반
    (`n34-mapempty`)도 재어 더했다.
  - **묻지 않는 방향** `open-map-to-unmarked`(리뷰 라운드 1이 잼): 대응 쌍 `no-unmerged-tag=gh release create`를 지우고 그 이름을 `floor-unmarked:`로 옮김 — 591/0 · 45/0.
    `gh release create`는 `publish`가 여전히 대응한다. 규약 「기계가 묻는 것」의 「다른 이름이 같은 표지를 대응해 두는 한 … 옮겨도 초록이다」가 이 실측이다.
  - **묻지 않는 방향** `open-slot-move`(라운드 1): `redecompose`를 `floor-unmarked:`에서 `floor-excluded:`로 옮김 — 591/0 · 45/0. 규약 「기계가 묻는 것」과 README ⑼가 「칸이 옳은가」를
    묻지 않는다고 적는다.
  - **묻지 않는 방향** `adv-remove-all`: `redecompose`를 `floor-items:` · `floor-unmarked:` · 정의 항목에서 함께 지움 — 591/0 · 45/0. 규약 「기계가 막지 못하는 것」 ⒝와 README
    「묻지 않는 것」 ⑻이 이 경계를 적는다. **닫을 수 없다고 본 근거**(`infeasible-evidenced`):
    - ⓐ **어느 형태에서**: 바닥 목록을 든 선언 · 정의 · 칸(그리고 그 바닥에만 대응하던 `floor-marks:` 표지) 전부를 같은 편집이 함께 고치는 형태.
    - ⓑ **왜 성립하는가**: 대조의 모든 입력이 같은 파일의 선언이다. 그래서 한 이름을 모든 쪽에서 지운 트리는 처음부터 그 이름이 없던 트리와 바이트 수준에서
      구별되지 않는다. 바닥 게이트가 스킬 문면에 남아 있는지를 대신 물으려면 `floor-unmarked:` 바닥(⒜)의 스킬 문면에 ASCII 토큰이 있어야 한다. 그 토큰을 심는
      것은 스킬 변경이라 이번 범위 밖이다(마일스톤 「닫지 않는 것」 둘째).
    - ⓒ **반례를 어떻게 찾았는가**: 같은 피해(바닥 하나가 조용히 사라짐)에 이르는 편집 여섯을 돌렸다 — 정의만(`n37`) · 칸만(`n41`) · 선언만(`dir-name-only`) ·
      선언 줄째(`dir-decl-gone`) · 범위 밖 이동(`adv-def-outside`) · 대응에서만(`dir-map-drop`). 여섯 다 붉었고, 모두 함께 고친 편집만 초록이다. 이 탐색은
      `docs/conventions.md` 한 파일의 선언 · 정의 편집에 한정된다.

## 미해결·후속 메모

1. **헬퍼 일반화 — `rf-79`의 다음 무리 입력.** `fl_*`/`Fl*`는 키와 규약 파일을 인자로 받는다.
   - 다음 무리(release 게이트 ①②③ · 회고 순서 갈래 · 도입 번호 파생 · 문서 커밋 전제)가 같은 형태(이름 선언 + 하위 목록 정의)로 서면 이 헬퍼를 키 매개변수로 일반화한다.
   - 그때 Part W의 `sp_*`(정의 범위가 「제목까지」인 판본)도 흡수할 수 있다 — 범위 규칙 둘을 매개변수로 둔다.
2. **`floor-unmarked:` 바닥의 스킬 토큰** — 규약 ⒜(표지 없는 바닥에 조건을 다는 편집)는 여전히 기계 밖이다.
   - 닫으려면 판정 `불가` 중단 · 프리플라이트 중단 조건 · 재분해 권고 게이트의 스킬 문면에 ASCII 표지를 심고 `floor-marks:`로 옮겨야 한다.
   - 스킬 변경이라 회고 메모의 범위 규율(스킬과 하니스를 한 사이클에 묶지 않는다)과 충돌한다. 따로 한 사이클로 다룬다.
3. **대응 · 칸과 스킬 창의 대조** — `N43` · `N44`는 표지 **집합**만, `N41`은 칸이 **하나인가**만 묻는다.
   - 대응 쌍이 스킬의 실제 항목 창과 맞는지, 칸이 옳은지는 묻지 않는다(README ⑼).
   - 바닥 문면이 한국어 산문이라 지목할 ASCII 토큰이 없다. 후속 2가 먼저다.
4. **로컬 `AGENTS.md`**(`.gitignore` 대상)는 `CLAUDE.md`와 18~19행이 이미 다르다. 이번에는 27행만 맞췄고, 저장소 산출물이 아니라 기계가 대조하지 않는다.
5. **병렬 디스패치를 쓰지 않았다** — T02(규약)와 T03(러너)는 같은 레벨이지만 메인이 순차로 했다.
   - T03의 파서는 T02가 쓰는 선언 형태를 그대로 읽는다. 그 의존이 마일스톤의 deps에 표기되지 않았다.
   - 다음 마일스톤에서 같은 형태(규약 선언 + 러너 파서)를 나눌 때는 deps에 적는다.
