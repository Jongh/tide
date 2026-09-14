# M65 완료보고서 (impl)

## 개요

구조적 불가 주장(「이 형태로는 불가능하다」)의 근거 형태를 규약에 병기어로 선언하고(T01), 리뷰 스킬·impl
템플릿·리뷰 템플릿이 그것을 가리키게 했으며(T02), 선언과 재서술처의 정합을 `tests/discover` Part W가 물게
했고(T03), 그 부류의 첫 실례였던 나열 줄 거름을 `# mutates-to:`로 두 사본에 선언해 **측정으로** 방전했다(T04).
태스크가 T01→T04 한 줄의 사슬이고 T03·T04가 러너 파일을 공유해 병렬 디스패치 없이 메인이 순차로 구현했다.

재작업 라운드(rework): 0

## 태스크별 수행 내용

- **M65-T01** — `docs/conventions.md`의 "검사 범위 선언" 절 **바로 뒤**에 "구조적 불가 주장의 근거" 소절을
  두었다. 병기어 선언 줄 `infeasible-decl:` (값 `infeasible-evidenced`) 하나와 굵은 코드 스팬 정의 줄 하나.
  - **근거는 세 요소** — 어느 형태에서 · 왜 성립하는가 · 반례를 어떻게 찾으려 했는가. 이 셋을 임의로 고르지
    않고 **M63의 틀린 주장에서 빠져 있던 것의 목록**으로 적었다(형태를 한정하지 않았다 — 고정 대체에만
    성립 · 반례 시도가 없었다).
  - **못 채우면 「하지 않았다(사유)」로 적는다** — 앞 절의 *"덜 주장하는 것은 산출물이다"* 와
    `tests/mutation/README.md`가 남긴 *"비용을 사유로 적는 것이 정직한 이월이다"* 를 규칙으로 올렸다.
  - **발화 조건은 주장의 부류**(「단독 불가」·「무력화되지 않는다」·「공허해질 수 없다」 포함), 기계가 묻지
    않는 것 셋(사실성 · 반례의 독립성 · 빠짐없음)을 같은 소절에 적었다.
  - **재서술처를 `scope-declared`와 같은 셋으로 둔 설계 결정** — 두 규율이 대조되는 자리가 같다(리뷰가 목록으로
    대조 · impl 보고서가 근거 칸·되돌림 표에 적음 · 리뷰보고서가 `## 검증`에 적음). 같은 셋이라 T03이 **같은
    헬퍼**를 쓸 수 있고, 그 공유의 근거와 깨지는 조건을 규약·러너 주석·README에 적었다.
- **M65-T02** — 세 자리에 병기어를 **가리키는 문면**을 붙였다. `skills/review/SKILL.md`의 「검사 범위 대조」 절에
  「못 한다」 주장도 같은 목록 대조에 넣는다는 불릿, `skills/impl/template.md`의 완료 기준 대조 안내에 근거 칸의
  불가 주장 한 문단과 **되돌림 실측 안내에 「목록에서 뺀 케이스의 사유는 불가 주장이다」** 한 줄,
  `skills/review/template.md`의 `## 검증` 절에 「불가 주장 대조」 문단. 요소·발화 조건은 어디에도 다시 적지 않고
  규약 소절을 가리킨다.
- **M65-T03** — Part W에 `W49`~`W57`을 더했다. 선언 줄 유일성(`W49`) · 추출 positive-control(`W50`, 폴백
  `zzz-infeasible-decl-unset`) · 네 파일 결합(`W51`) · 규약 정의 줄(`W52`) · 재서술처 자리별 백틱 토큰(`W53`~`W55`) ·
  배선(`W56`) · 꼬리 구분자(`W57`). 헬퍼는 `scope-decl:`의 것(`scope_all`·`scope_defn`·`scope_tok`·`bad_seps`)을
  그대로 부른다. 하니스 README의 `cases:` 선언 · 파트 내역 · Part W 머리글·블록을 같은 편집에서 고쳤다.
- **M65-T04** — 나열 줄 거름의 게이트 리터럴이 두 사본 모두 **파일 내 유일**함을 선언 직전에 다시 쟀다
  (`grep -cF` — `run.sh` 1 · `run.ps1` 1). 각 사본 끝에 `# mutates-to:` 선언을 하나씩 더했다 — sh는 `-eq 1`→`-eq 9`,
  ps1은 `$all`→`$false`(둘 다 거름이 꺼지는 대체), 기대값은 `W25`가 붉는 `caught`. `tests/mutation/README.md`의
  선언 수(4→5)·케이스 수(11→12)와 경계 표의 「나열 줄 거름」 행을 고쳤고, 두 러너의 선언 머리 주석에서
  *"이번에 선언하지 않은 것은 비용이다"* 를 *"M63은 비용으로 미뤘고 M65가 선언했다"* 로 바꿨다. 표 아래 *"비용을 사유로
  적는 것이 정직한 이월이다"* 문단은 이력으로 남겼다.

**「새 검사를 세울 때 함께 붙일 것」 대조** — 대상은 선언 키 `infeasible-decl:`와 케이스 `W49`~`W57`, 뮤테이션 선언 둘이다.

| 항목 | 대조 |
|---|---|
| 1. 추출 positive-control | `W50`(병기어). 뮤테이션 쪽은 기존 `X1`(선언 추출)이 새 선언도 센다 |
| 2. 선언 줄 유일성 | `W49`. 뮤테이션 선언 수는 기존 `X2`가 README 선언과 대조한다 |
| 3. 되돌림 실측 | 아래 표 14행. 새 케이스 9개 전부가 어느 행에서든 붉었다 |
| 4. 되돌림의 방향 둘 | `broken` 8행 · `adversarial` 6행. **초록으로 지나간 적대 변이 0** |
| 5. 무는 대상 집합의 명세 | 재서술처는 명시한 세 경로(`scope-declared`와 같은 셋)이고 발견 집합이 아니다. 형태(정의 줄 = 굵은 코드 스팬 · 재서술처 = 백틱 토큰)는 하니스 README Part W 절에 적었다 |
| 6. 통제는 판정의 반응을 묻는다 | `W56`은 인자로 준 토큰 하나만 읽어 **기준선이 구조로 상수**인 자리이고 그 사유를 러너의 같은 자리 주석에 적었다(규약이 허용하는 예외 형태 ⑴) — 그 상수성 자체가 아래 불가 주장 목록의 한 항목이다 |

## 완료 기준 대조

| 기준 | 판정 | 근거 |
|---|---|---|
| 1 | 충족 | 선언 줄 유일성은 `W49`가 문다(되돌림 `dup-inf-decl` 단독 붉음). 복제 부재 — 검색 루트 레포 루트, 대상 파일 `skills/review/SKILL.md` · `skills/impl/template.md` · `skills/review/template.md`, 패턴은 규약 새 소절의 정의·요소·경계 문장에서 뽑은 고정 문자열 15개(`근거를 같은 자리에 적고` · `세 요소` · `어느 형태에서` · `반례를 어떻게` · `구조의 사실` · `빠져 있던 것의 목록` · `덜 주장` · `정직한 이월` · `동의어로 비껴가면` · `정말 다른 경로` · `빠짐없이 형태` · `같은 셋` · `누가 쟀는가` · `공허해질 수 없다` · `무력화되지 않는다`), 대조 항목은 「규약 문장을 옮긴 줄인가」. **히트 0**. 대상 밖으로 둔 낱말 하나 — `하지 않았다`는 재서술처가 **정의가 인용하는 목표 문구**로 쓰는 지시어라(규약 정의 줄도 같은 낱말을 겹낫표로 인용한다) 문장 복제 대조의 대상이 아니다 |
| 2 | 충족 | 교란 일곱 각각이 붉었다(양 축 — `pwsh` 전수 · `sh` Part W). 선언 줄 삭제 `del-inf-decl` → `W49;W50;W51;W52;W53;W54;W55` · 선언 줄 복제 `dup-inf-decl` → `W49` · 정의 줄 굵은 표기 제거 `strip-inf-defn-bold` → `W52` · 재서술처별 토큰 삭제 `del-rev-skill-token` → `W51;W53` · `del-impl-tpl-token` → `W51;W54` · `del-rev-tpl-token` → `W51;W55` · 꼬리 구분자 `tab-tail-inf` → `W57` |
| 3 | 충족 | 선언이 두 사본 각각에 있다(`^# mutates` 줄 수 sh 5 · ps1 5, 새 줄은 각 사본의 나열 줄 거름 리터럴을 겨냥). `tests/mutation`(`pwsh`)이 `X3[caught]: W25: adversarial control -- a bold listing`을 PASS로 판정했다. 교란 둘 — 대체값을 거름이 유지되는 값으로 `mut-noop-replacement` → `X3[caught]` 붉음 · 선언을 한 사본(ps1)에서 삭제 `mut-decl-removed-ps1` → `X2;X4` 붉음. **sh 사본의 선언 삭제는 로컬에서 재지 않았다**(사유: 측정 배당 — `tests/mutation`의 `sh` 축 판정은 `pr` 모드 릴리즈에서 CI가 진다) |
| 4 | 충족 | `tests/mutation/README.md`의 `cases:` 12 · `mutations:` 5가 실측과 일치한다(`X2`·`X4` PASS, 아래 마지막 측정). 경계 표 「나열 줄 거름」 행이 *"된다 — 선언했다(M65 …)"* 이고 *"이번에 선언하지 않았다"* 는 문구가 사라졌다 |
| 5 | 충족 | 규약 새 소절에 ⑴ 세 요소 · ⑵ *"못 채우면 … 「하지 않았다(사유: 비용·범위)」로 적는다"* · ⑶ 발화 조건이 있고, **같은 소절의** 「기계가 무는 것과 사람의 영역」 불릿에 묻지 않는 것 셋(ⓐ 사실성 · ⓑ 반례의 독립성 · ⓒ 빠짐없음)이 있다 |
| 6 | 충족 | 아래 「이 사이클이 적은 구조적 불가 주장」 표가 목록이다(주장 셋 + 「하지 않았다」 하나). 빠짐없음의 범위 — 검색 루트 레포 루트, 대상은 이 사이클이 고친 추적 파일 여덟(`docs/conventions.md` · 스킬 셋 · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` · `tests/mutation/README.md`)의 **추가된 줄**(`git diff -U0`의 `+` 줄)과 이 보고서, 패턴은 `불가|수 없|못 한다|무력화되지 않|상수|단독으로 붉` 그리고 `run.ps1`에 한해 `cannot|impossible|constant|never`, 대조 항목은 「이 사이클이 **스스로 한** 불가 주장인가」. 히트 전수 분류 — 규약 새 소절 · 스킬 셋 · 하니스 README · 러너 케이스 라벨의 히트는 규칙과 그 발화 조건을 **서술하거나 예시로 인용**하는 문장이라 대상 밖이다. 대상은 두 러너의 `W56` 주석(*"기준선이 구조로 상수다"* / *"CONSTANT BY CONSTRUCTION"*)과 이 보고서의 표·체크리스트 6행·되돌림 절 한 줄이며, 전부 표의 세 주장 중 하나로 귀속된다 |
| 7 | 충족 | `docs/epics/E2.md`의 마커 블록에 `- M65 — …` 한 줄이 있고 `docs/milestones/M65.md`의 메타데이터가 `epic: E2`다(양방향) |

## 이 사이클이 적은 구조적 불가 주장

완료 기준 6의 목록이다. 형태는 규약 "구조적 불가 주장의 근거" 절(`infeasible-evidenced`)의 세 요소를 따른다.

| 주장 | 어느 형태에서 | 왜 성립하는가 | 반례 탐색 | 판정 |
|---|---|---|---|---|
| **`W51`은 단독으로 붉을 수 없다**(되돌림 목록에서 뺀 사유) | 네 파일 결합(규약 + 재서술처 셋)의 부분 문자열 판정 | `W51`이 붉으려면 어느 파일에 병기어 **부분 문자열**이 없어야 하고, 그 파일의 자리별 단언은 그 문자열을 **포함하는** 형태(규약 = 굵은 코드 스팬 정의 줄 `W52` · 재서술처 = 백틱 토큰 `W53`~`W55`)를 요구하므로 반드시 함께 붉는다 | 토큰 삭제 세 행(`del-*-token`) · 선언 삭제 · 값 비움 — 전부 `W51`이 자리별 케이스와 **함께만** 붉었다. 반대로 부분 문자열만 남기는 형태(백틱만 벗김 세 행)는 `W51`이 초록이고 자리별만 붉었다 | 형태 충족 |
| **`W50`은 단독으로 붉을 수 없다**(통제 — 단독 행 요구 대상은 아니나 사유를 적는다) | 추출 positive-control | 추출이 폴백(`zzz-infeasible-decl-unset`)이 되면 결합·자리별 단언이 **폴백 토큰**을 찾는데 그 토큰은 네 파일 어디에도 없어 `W51`~`W55`가 함께 붉는다 | `empty-inf-value`(선언 줄은 두고 값만 비움) · `del-inf-decl` — 둘 다 `W50`이 `W51`~`W55`와 함께 붉었다 | 형태 충족 |
| **`W56`의 기준선은 구조로 상수다** | 배선 통제(인자로 준 토큰 하나만 읽음) | 읽는 토큰 `zzz-other-infeasible`이 네 파일 어디에도 없으므로 정상 트리에서 결합은 언제나 `no`다 | `wiring-inf-break`(인자를 실제 병기어로 바꿈) → `W56` 단독 붉음. 토큰 부재 — `grep -cF 'zzz-other-infeasible'`을 네 파일(`docs/conventions.md` · `skills/review/SKILL.md` · `skills/impl/template.md` · `skills/review/template.md`)에 돌려 전부 0 | 형태 충족 |
| **sh 사본의 선언 삭제 교란** | — | — | — | **불가 주장이 아니다 — 「하지 않았다」**(사유: 측정 배당. 기준 3 행) |

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/reports/M65-impl.md` |
| 수정 | `docs/conventions.md` · `skills/review/SKILL.md` · `skills/impl/template.md` · `skills/review/template.md` · `tests/discover/run.sh` · `tests/discover/run.ps1` · `tests/discover/README.md` · `tests/mutation/README.md` |
| 삭제 | (없음) |

기준선은 이 단계 시작 시점의 워킹트리다. `docs/milestones/M65.md`와 `docs/epics/E2.md`의 역방향 등재 한 줄은
**직전 milestone 단계의 미커밋 산출물**이라 git 기준으로는 각각 신규 파일 · 수정이다.

## 테스트 결과

| 축 | 값의 출처 | 값 |
|---|---|---|
| 로컬에서 잰 값 | `axis-valued-locally` (`pwsh` 7.6.6 Core) | `tests/discover` 전수 **408 / 0** · 19초 · `tests/mutation` **12 / 0**(선언 5) · 122초 |
| 판정을 CI에 넘긴 축 | `axis-judged-by-ci` (`sh` 축 — CI `posix` 잡) | 릴리즈 단계에서 확인(`pr` 마무리의 PR CI 확인) |

**마지막 측정** — 이 보고서를 쓴 뒤 같은 트리에서 돌렸다.

| 하니스 | 실행 환경 | 결과 |
|---|---|---|
| `tests/discover` | `pwsh` 7.6.6 | PASS=408 FAIL=0 · exit 0 · 19초 |
| `tests/discover` | Windows PowerShell 5.1 | PASS=408 FAIL=0 · exit 0 · 42초 |
| `tests/discover` Part W(부분 실행) | Git Bash `sh` · `dash` | 59/0 · 59/0 (`sh` 12초) |
| `tests/mutation` | `pwsh` 7.6.6 | PASS=12 FAIL=0 (선언 5) · 122초 |
| `tests/fleet` · `fleet-cycle` · `fleet-verify` · `multi-repo` · `site-includes` | `pwsh` 7.6.6 | 45/0 · 24/0 · 30/0 · 37/0 · 51/0 |

- **`sh` 축 전수는 로컬에서 돌리지 않았다** — 측정 배당에 따라 그 판정은 `pr` 모드 릴리즈의 PR CI가 진다. 로컬 `sh`·`dash`는
  이 사이클이 고친 파트(W)만 부분 실행으로 확인했고, 부분 실행의 결과 줄 접두가 달라 위 전수 값과 섞이지 않는다.
- **정적 확인** — `sh -n`·`dash -n` 통과. 줄 끝은 `run.sh` CR 0 · `run.ps1` CR 4973 = 줄 4973 · 편집한 CRLF 문서
  여섯(`docs/conventions.md` 2771 · `skills/review/SKILL.md` 119 · `skills/impl/template.md` 101 · `skills/review/template.md` 74 ·
  `tests/discover/README.md` 1882 · `tests/mutation/README.md` 133)이 전부 CR 수 = 줄 수. `run.ps1` 비-ASCII 0줄. 나열 줄 거름
  리터럴은 각 사본에 둘(코드 1 + 선언 줄 1), 선언 줄은 각 사본에 다섯.
- **캐시가 아님의 확인**(`measure-not-cached`) — 하니스는 캐시 없는 셸 스크립트이고, 이번 실행들은 `tests/discover`가
  399 → 408, `tests/mutation`이 선언 4 → 5 · 케이스 11 → 12로 **바뀐 값**을 냈다. `U6`이 이 보고서가 생긴 뒤 초록이 된 것도
  값이 이 트리를 보았다는 근거다.
- **작업 중 신호** — 구현 직후 `pwsh` 전수는 407/1이었고 유일한 FAIL이 `U6`(이 보고서 부재)이었다.

## 되돌림 실측

<!-- reversal-table:start -->
<!-- reversal-table-main: W49 W52 W53 W54 W55 W57 -->

| 행 이름 | 깬 것 | 축 | 붉은 케이스 | 결과 |
|---|---|---|---|---|
| del-inf-decl | 규약의 `infeasible-decl:` 선언 줄 삭제 | broken | W49;W50;W51;W52;W53;W54;W55 | ps1 400/8 · sh Part W 52/7 |
| dup-inf-decl | 같은 `infeasible-decl:` 선언 줄을 하나 더 둠 | adversarial | W49 | ps1 406/2 · sh Part W 58/1 |
| empty-inf-value | 선언 줄은 두고 값만 비움 | broken | W50;W51;W52;W53;W54;W55 | ps1 401/7 · sh Part W 53/6 |
| strip-inf-defn-bold | 규약 정의 줄의 굵은 표기만 벗김 | adversarial | W52 | ps1 406/2 · sh Part W 58/1 |
| del-rev-skill-token | review 스킬의 병기어 토큰 삭제 | broken | W51;W53 | ps1 405/3 · sh Part W 57/2 |
| strip-rev-skill-backtick | review 스킬의 토큰에서 백틱만 벗김 | adversarial | W53 | ps1 406/2 · sh Part W 58/1 |
| del-impl-tpl-token | impl 템플릿의 병기어 토큰 삭제(두 자리) | broken | W51;W54 | ps1 405/3 · sh Part W 57/2 |
| strip-impl-tpl-backtick | impl 템플릿의 토큰에서 백틱만 벗김(두 자리) | adversarial | W54 | ps1 406/2 · sh Part W 58/1 |
| del-rev-tpl-token | review 템플릿의 병기어 토큰 삭제 | broken | W51;W55 | ps1 405/3 · sh Part W 57/2 |
| strip-rev-tpl-backtick | review 템플릿의 토큰에서 백틱만 벗김 | adversarial | W55 | ps1 406/2 · sh Part W 58/1 |
| tab-tail-inf | `infeasible-decl:` 선언 줄 끝에 탭 한 글자 | adversarial | W57 | ps1 406/2 · sh Part W 58/1 |
| wiring-inf-break | 두 사본의 `W56`이 실제 병기어를 인자로 받게 | broken | W56 | ps1 406/2 · sh Part W 58/1 |
| mut-noop-replacement | ps1 사본 나열 줄 거름 선언의 대체값을 거름이 유지되는 값으로 | broken | X3 | mutation ps1 11/1 |
| mut-decl-removed-ps1 | ps1 사본의 나열 줄 거름 선언 줄 삭제 | broken | X2;X4 | mutation ps1 9/2 |

<!-- reversal-table:end -->

**기준선은 `tests/discover` ps1 전수 407/1 · `sh` Part W 59/0 · `tests/mutation` ps1 12/0이다.** ps1 전수의 유일한
FAIL은 `U6`(이 보고서가 없던 동안 완료 기준 대조가 M65를 건너뛴 진행 신호)이고, 결과 칸의 ps1 총계는 전 행에서 그
하나를 포함하며 붉은 케이스 칸에서는 뺐다. `sh` 축은 **부분 실행**(Part W)이라 파트 밖의 붉음을 보지 못한다. 두 축은
Part W 안에서 **모든 행에서 같은 케이스 집합**을 붉혔다. 뮤테이션 행은 측정 배당에 따라 `pwsh` 축만 쟀다.

- **방법** — 대상 파일 여덟(규약 · 스킬 셋 · 하니스 README 둘 · 러너 두 사본)의 사본을 스크래치패드에 **경로를 키로** 뜨고
  매 행 시작에서 복원했다. 변이는 바이트를 그대로 두는 리터럴 치환이고 **한 줄 앵커만** 쓴다. 치환이 실패하면 `MUTFAIL`
  줄을 찍게 했고 14행의 출력 어디에도 그 줄이 없었다. 마지막에 여덟 파일을 사본과 `cmp`로 대조해 **전부 같음**을 확인했다.
- **목록(`reversal-table-main`)에서 뺀 케이스** — `W51`은 구조적 불가 주장으로 뺐고 그 근거는 위 「이 사이클이 적은 구조적 불가
  주장」 표의 첫 행이다. `W50`·`W56`은 통제라 단독 행 요구의 대상이 아니며, 각각 전용 행(`empty-inf-value` · `wiring-inf-break`)에서
  반응을 확인했다.
- **`adversarial` 행이 전부 붉었다** — 초록으로 지나간 적대 변이는 없다.

## 미해결·후속 메모

1. **새 규칙은 「병기어의 공존」까지만 기계가 문다** — 산출물의 불가 주장이 실제로 세 요소를 갖췄는지, 적힌 근거가 사실인지는
   리뷰가 목록으로 대조한다(규약이 그렇게 적는다). 이 보고서의 표가 그 첫 적용이다.
2. **`tests/mutation`의 `sh` 축은 로컬에서 돌리지 않았다** — 측정 배당(`pr` 모드 릴리즈에서 CI가 판정)에 따른다. 새 선언의 `sh`
   사본(`-eq 1`→`-eq 9`)이 `caught`인지는 릴리즈 PR의 `posix` 잡이 처음 잰다.
3. **회고 후속 표의 1순위 두 행(부류 · 실행)이 이 사이클로 반영됐다** — 표의 상태 열을 옮기는 것은 회고의 자리라 이 단계는
   건드리지 않았다. M64로 전제가 사라진 두 행(「영향 집합으로 좁힐 수 있는가」 · 「선언을 늘릴 때 sh 비용을 함께 잰다」)도 같다.
4. **E4의 남은 항목**(기록 비용 · 하니스 고정비)은 이 마일스톤 뒤로 미뤄졌다(`docs/milestones/M65.md` 배경의 순서 결정).
5. **`.tide/NEXT-SESSION.md`가 M62 시점에 멈춰 있다** — git 추적 대상이라 다음 릴리즈 커밋에 낡은 인수인계가 실린다.
