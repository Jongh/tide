# M26 리뷰보고서 (review)

## 개요

M26(잔여 후속 결산 — BOM 헬퍼 단일 원본화 + 사이트 인클루드 자기완결 검증)을 리뷰했다. 신규 코드가
프롬프트 스킬이 아니라 **테스트 하니스·셸 참조 구현**이라(회고 교훈 #1: 가산·정리 사이클은 단일 비판
리뷰), 교훈 #2("테스트 통과 ≠ 정합 — 자동 테스트가 닿지 않는 산출물일수록 직접 검토")에 따라 **그린
숫자만 믿지 않고** 신규/수정 셸 소스·source 배선·인코딩·인클루드 검증 로직을 정적으로 직접 읽고,
의심 가는 회귀는 끝까지 추적했다. 차단 결함 0. 인코딩 일관성 결함 1건을 리뷰에서 직접 수정했고,
리뷰 중 발견한 **기존(M26 범위 밖) 테스트 하니스 취약성 1건**을 솔직히 기록한다.

**차단 결함 0. 최종 판정: 가능 — 추천 v2.4.1 (patch).**

## 비판점

### 차단 (0건)

없음.

### 권장 (1건 — 리뷰에서 수정 완료)

1. **신규 `tests/site-includes/run.ps1`가 선두 BOM을 가져 자매 테스트 `.ps1` 인코딩 규율에서 이탈** —
   repo의 모든 테스트 `.ps1`(`tests/lib/{encoding,discover,deps,toposort}.ps1`·`tests/*/run.ps1`)은
   **no-BOM·ASCII-only**다(`.ps1` BOM 규약은 한글 메시지를 담는 `hooks/tide-guard.ps1`에 한정 —
   `docs/conventions.md` 인코딩 절). T02가 신설한 `site-includes/run.ps1`만 BOM을 달고 있었다(내용은
   ASCII 전용이라 BOM이 불필요). 동작은 무해하나(PS 5.1은 BOM `.ps1`도 정상 읽음, 하니스 양 셸 green),
   repo가 반복 회고에서 강조해 온 **인코딩 규율의 일관성**을 깨고 향후 "왜 이 파일만 BOM?" 드리프트를
   부른다. **영향**: 기능 무영향·일관성 결함. **수정**: 선두 BOM 3바이트(`EF BB BF`)를 제거해 자매
   파일과 동일한 no-BOM ASCII-only로 맞췄다(아래 수정 내용). 수정 후 `tests/` 전 `.ps1`이 no-BOM으로
   일관.

### 사소 (2건)

- **[sn1] `site-includes`의 제외 용어 런타임 추출이 '오추출 → 공허한 green' 여지** — 하니스는 제외 용어를
  하드코딩하지 않으려고(그 자체가 누수·드리프트) 마스트헤드(`README.md:3`·`docs/conventions.md:3`,
  본문 마커 **밖**)의 "외부 귀속어 + 한국어 '…의 개발 방법론'" 패턴에서 런타임 추출한다(현재 정확히
  1개 추출). "추출 0개면 FAIL" 가드로 **빈 스캔**은 막았으나, 마스트헤드 표현이 바뀌어 **엉뚱한 토큰**을
  뽑으면 그 토큰은 당연히 본문에 없어 스캔이 **공허하게 통과**할 수 있다(틀린 이유의 green — 교훈 #2가
  경계하는 바로 그 모드). **수용 사유**: ① 테스트 전용 하니스(배포 런타임 아님), ② 현재 추출 정확
  (`porpoise`), ③ 제외 용어 누수 방어는 **3중**(release 프리플라이트 수기 스캔 · CI `--strict` · 이
  로컬 가드)이라 단일 실패점이 아님. **후속(비차단)**: positive-control 한 줄 — 추출한 토큰이 그
  마스트헤드 영역에 **실제로 존재**함을 재확인(스캐너가 진짜 문자열을 다루는지 보장)하거나, 용어를
  비-인클루드 데이터 파일에 두는 대안의 트레이드오프를 차기 정리 사이클에서 판단.
- **[sn2] `tests/multi-repo/run.ps1`을 비-PowerShell 셸(Git Bash)에서 실행하면 ps1 테스트가 PASS=6
  FAIL=4로 실패 — 기존·M26 범위 밖** — 리뷰 중 전 하니스를 Bash 도구로 돌리다 발견. 원인을 끝까지
  추적한 결과: 그 테스트는 가드 입력 fixture JSON을 `Set-Content -Encoding utf8`로 쓰는데 **PS 5.1에선
  이게 BOM을 붙인다**(확인: 선두 3바이트 `239,187,191`). 그리고 **PS 5.1 `ConvertFrom-Json`은 선두
  BOM에서 throw**한다(확인). 비-PS 콘솔(MSYS)에서 실행하면 그 BOM이 `[Console]::In`을 거쳐
  `ConvertFrom-Json`까지 도달→파싱 throw(가드의 `try/catch`가 삼킴)→`cwd` 미추출→가드가
  `CLAUDE_PROJECT_DIR`로 폴백한다. 폴백 대상에 `.tide/phase`가 없는 4개 시나리오만 "허용(exit 0)"으로
  뒤집혀 실패하고, 폴백 대상에 phase가 있는 블록 시나리오(#6·#8)는 그대로 통과 — **관찰된 6/4 패턴과
  정확히 일치**. **M26 무관 확정**: `git diff --stat -- hooks/ tests/multi-repo/`가 **빈 출력**
  (`tide-guard.ps1`·`multi-repo/run.ps1` 둘 다 M25 baseline과 바이트 동일, M26은 손대지 않음).
  **가드 실동작 정상**: 실제 Claude Code 훅 입력은 BOM 없는 UTF-8이라 `cwd`가 정상 추출되고, **의도된
  실행(PowerShell)에서 multi-repo ps1은 10/10 통과**, sh 테스트도 10/10이다(가드 로직 자체는 정상).
  즉 **테스트 하니스의 fixture 인코딩 취약성**이지 제품 결함이 아니다. **수용·후속(비차단)**: fixture를
  no-BOM으로 쓰거나(`[IO.File]::WriteAllText` + UTF8 no-BOM / `-Encoding ascii`), 더 근본적으로 **가드가
  입력 선두 BOM에 내성**을 갖도록(BOM strip 후 `ConvertFrom-Json`) — 후자는 기존 수용 항목인
  tide-guard 입력 견고화(M13 사소3 raw-`$input` grep)와 같은 결의 가드-하드닝이라 별도 사이클에서
  함께 다룬다. M26 가산 범위에 넣지 않는다(가드·multi-repo 미변경 유지).

## 수정 내용

- **권장 1 (인코딩 일관성)**: `tests/site-includes/run.ps1`의 선두 UTF-8 BOM을 제거했다
  (`perl -0777 -i -pe 's/^\xEF\xBB\xBF//'`). 내용은 ASCII 전용이라 무변경, 첫 3바이트가
  `EF BB BF`→`23 20 74`(`# t`)로 바뀌고 비-ASCII 바이트 0. 수정 후 양 셸 재실행 **PASS=27 FAIL=0**
  유지(동작 보존). 이제 `tests/`의 모든 `.ps1`(7개)이 no-BOM으로 일관.

## 검증

**정적 직접 검토(셸·참조 구현 — 교훈 #2 직접 적용)**:
- **단일 정의 확인**: `grep -rn`으로 `strip_bom()`(sh)·`function StripBom`(ps1) 정의가 트리 전체에 **각
  1개**(`tests/lib/encoding.{sh,ps1}`)만 존재. `tests/fleet-verify`의 로컬 복제 소멸, 나머지는 호출(use).
  헬퍼 본문은 M25 원본과 **바이트 동일**(순수 이동·재배선).
- **source 배선 정합(양 셸 직접 확인)**: `encoding → discover → deps → toposort` 순서가 `fleet`·
  `fleet-cycle`(.sh:20-23 / .ps1:19-22)에서, `encoding → discover`가 `fleet-verify`(.sh:19-20 /
  .ps1:20-21, `read_hook`/`ReadHook`용)에서 확인. `deps`의 `read_deps`가 `strip_bom`을 쓰므로 encoding
  선행이 필수인데 네 하니스 모두 충족. `discover` 하니스는 `strip_bom` 불사용이라 encoding 미-source가
  옳음(과잉 source 없음). 거짓 의심(초기 grep이 `.ps1`의 backslash source 줄을 놓침)은 파일 직접 읽어
  encoding 선행을 확증.
- **`site-includes` 로직 정적 검토**: 마커 매칭을 bare `[start:body]`가 아니라 **`--8<-- ` 접두 포함**
  전체 마커로 앵커링 → CHANGELOG 본문/설명 산문의 동명 문자열 오탐 배제(올바른 설계). PASS=27 구조가
  비공허(1 용어-추출 + 4 셸 × {include-count, target-exists, start==1, end==1, balanced, body-term==0} +
  2 site-level = 27). 인클루드는 스캔 발견(하드코딩 아님)이라 새 셸도 포착. 스코프 경계(= `mkdocs
  --strict` 대체 아님·B2와 비중복)가 헤더 주석에 명시. 음성 케이스(타깃 end 마커 제거 시 FAIL=2)는
  impl 단계가 실증(파일 md5 복원 확인) + 본 리뷰가 balanced 판정 로직(ns/ne 카운트·ls<le)을 직접 읽어
  검증.
- **누수 정합**: 4개 사이트 본문(conventions·commands·orchestration·CHANGELOG)의 제외 용어 **0건**
  (하니스). 제외 용어는 마스트헤드 2곳(`README.md:3`·`docs/conventions.md:3`, 본문 마커 **밖**)에만
  존재 → 사이트 미유입(설계대로). 하니스 소스에 용어 **하드코딩 0**(런타임 추출). **T03이 편집한
  `docs/conventions.md` 본문(마커 안 435·597행 부근)이 마커/용어 회귀를 부르지 않음**을 수정 후 하니스
  재실행 green으로 확인 — 과거 v0.9.0의 "메타 문장 literal 누수"(M9) 같은 회귀가 이번 편집에서 재발하지
  않았다(오히려 이 신규 가드가 그 회귀 부류를 결정적으로 막는다).
- **인코딩 규율**: 수정 후 `tests/` 전 `.ps1` no-BOM 일관, 신규 `.sh`(encoding·site-includes) no-BOM,
  비-ASCII 소스 0(KO 구절은 코드포인트/UTF-8 바이트로 구성).
- **문서 결산 정합**: project-context "이월 처분 원장"에 sn3(strip_bom=fix)·mkdocs(부분-fix) 2행 +
  하니스 인벤토리에 `site-includes`·`tests/lib/encoding`·source 순서 반영. conventions "릴리즈 빌드
  출력 검증" 3분담(수기·CI·로컬 가드) + "규약↔실행 동기화" M26 예 추가. 스킬↔규약 분담 유지.

**라이브 회귀(양 셸, 네이티브 실행 컨텍스트 — M25 baseline 동일 + 신규)**:

| 하니스 | sh | ps1 |
|---|---|---|
| discover · fleet · fleet-cycle · fleet-verify · multi-repo | 19·41·23·29·10 / FAIL 0 | 19·41·23·29·10 / FAIL 0 |
| site-includes (신규) | 27 / FAIL 0 | 27 / FAIL 0 |

- 전 러너 exit 0, 기존 5개 baseline 동일(동작 보존). 드리프트 가드 discover B1(`11종`)·B2(사이트 셸)·
  B3(이름 완전성) 통과 — M26은 새 `/tide` 커맨드·토큰을 더하지 않음(`site-includes`는 테스트 하니스,
  커맨드 카탈로그 무관). BOM 수정 후 양 셸 재확인.

**잔여 리스크(솔직)**: 위 사소 2건 — (sn1) `site-includes` 용어 추출의 오추출-공허 green 여지(테스트
전용·3중 방어·현재 정확), (sn2) `multi-repo` ps1 fixture-BOM 취약성(M26 무관·기존·의도된 PS 실행에선
green). 둘 다 비차단·후속 후보. mkdocs **실제 렌더**(`--strict`)는 설계상 CI 잔존(로컬은 사각지대만 닫음).

**완료 기준 5개 충족**: ①`strip_bom`/`StripBom` 셸당 1정의·fleet-verify 복제 제거·5하니스 baseline 동일
②`site-includes` mkdocs 없이 4셸 타깃·마커·용어 검증·양 셸 exit 0·음성 검출 ③스코프 경계·B2 비중복
주석 명시 ④이월 원장 2행·인벤토리·conventions 3분담·동기화 예 ⑤2.0 stable 계약(11종·오케스트레이션·
`.tide/phase`/tide-guard·보고서/마일스톤 형식) 불변·새 커맨드/토큰 0·B1/B2/B3 불변·인코딩 규율
(수정 후 일관)·부수효과 분리(git 무변경 — status/diff 읽기 전용만).

## 릴리즈 판정

**가능** — 추천 **v2.4.1 (patch)**.

근거: 차단 0. 권장 1건(인코딩 일관성)은 **리뷰에서 직접 수정**, 사소 2건은 수용(둘 다 비차단·후속).
M26은 **사용자 대면 능력·새 `/tide` 커맨드·계약 변경이 전혀 없는 순수 내부 정리·검증 인프라 사이클**
이다 — 테스트 참조 구현의 마지막 BOM 복제면 제거 + mkdocs 빌드 출력 검증의 로컬 사각지대를 자기완결
하니스로 결정적 봉쇄 + 문서 결산. `gh`/`release`/push-only/tide-guard 경로는 **바이트 동일**(git diff로
무변경 확인). 영향도가 patch에 맞다(M23 테스트 참조 구현 단일 원본화 = patch 선례와 동형; M22처럼 새
사용자 대면 능력을 더하지 않으므로 minor 아님). 2.0 stable 계약·M22 드리프트 가드(B1/B2/B3)·tide-guard
비확장 전부 불변. M24 sn3·M25 sn3(strip_bom 단일 원본화)과 M22~M25 연속 환경-이월(mkdocs 로컬 검증)을
**종결**했다.

## 다음 단계

- `.tide/phase`를 `idle`로 되돌리고 **`/tide:release v2.4.1`**을 사용자에게 넘긴다(cycle은 release 제외).
- 릴리즈 후 권장 후속(모두 비차단·차기 정리 사이클 후보):
  1. **sn1**: `site-includes` 용어 스캔에 positive-control(추출 토큰의 마스트헤드 실재 재확인) 한 줄 추가 — 오추출-공허 green 차단.
  2. **sn2**: `tests/multi-repo/run.ps1` fixture를 no-BOM으로 쓰거나, **가드가 입력 선두 BOM에 내성**을 갖도록(BOM strip 후 `ConvertFrom-Json`). 후자는 기존 수용 항목 **tide-guard 입력 견고화**(M13 사소3 raw-`$input` grep 한정)와 같은 가드-하드닝이라 한 사이클로 묶는 것을 권장(BOM/인코딩 규율 테마).
  3. 잔존 의도적 수용: tide-guard raw-`$input` grep 거칠음(2와 통합 검토), 라이브 도그푸딩(gh 게시·`pr` finalize 실증 — 이 릴리즈를 `pr`/`release` 모드로 회수하면 동시 실증 가능).
- **도그푸딩 기회**: v2.4.1을 `gh` 게시 모드로 릴리즈하면 M25 finalize(머지 후 태그·릴리즈 자동 마무리) 라이브 미검증(M25 sn2)을 함께 회수할 수 있다.
