# M27 완료보고서 (impl)

## 개요

M27의 5개 태스크를 모두 구현했다 — 주 기능인 **`pr` 모드 finalize 릴리즈 브랜치 정리**(규약+스킬
단일 원본)와 M26 리뷰의 비차단 후속 두 건(sn1 `site-includes` positive-control, sn2 `multi-repo`
fixture-BOM), 그리고 한 결인 **tide-guard 입력 견고화**(선두 BOM 내성 + sed `cwd` 키 앵커링). 부수효과
분리를 지켜 코드·테스트·문서만 남겼다(git 작업 없음). 라이브 하니스는 양 셸(sh·PowerShell)에서 전부
green이며 baseline 대비 회귀 0이다.

## 태스크별 수행 내용

- **M27-T01** — `pr` 모드 finalize에 **⑤ 릴리즈 브랜치 정리**를 더했다. 단일 원본인 `docs/conventions.md`
  "`pr` 모드" 절의 merged→finalize 항목에 ⑤를 추가하고, "멱등·안전" 목록에 정리 불변 한 항목을 신설했다
  — 선행 조건(②~④ 성공 후, 태그/릴리즈 생성과 **독립 멱등**), **현재 브랜치 안전**(기본 브랜치 체크아웃
  선행), **로컬**(`git branch -d` 우선·머지 확인된 경우만 `-D`·미머지 강제삭제 금지·없으면 건너뜀),
  **원격**(`git push --delete`·이미 없으면 건너뜀), **실패 비차단**(정리 실패가 릴리즈를 무르지 않음·경고
  보고). `skills/release/SKILL.md`의 finalize 줄에는 규약을 재서술하지 않고 **포인터**만 배선했다.
  `release`/push-only/생성·대기·중단 분기와 tide-guard 계약은 불변. (서브에이전트 병렬 구현, 메인 검증.)

- **M27-T02** — sn1: `tests/site-includes`의 양 셸 하니스에 **positive-control 단언**을 추가했다 —
  마스트헤드에서 런타임 추출한 제외 용어가 그 추출 영역(README.md/conventions.md 3행)에 **literal로
  실재**하는지 재확인하고, 부재 시 FAIL. 마스트헤드 표현 변경 → 오추출 → 본문에 없어 공허 통과("틀린
  이유의 green") 모드를 차단한다. 다중 토큰 추출도 각각 검사(현재는 1개 `porpoise`). `run.ps1`의 stale
  주석("BOM present")을 no-BOM으로 정정. 양 셸 PASS 27→**28**(동수). ASCII-only·no-BOM 유지.
  (서브에이전트 병렬 구현, 메인 검증.)

- **M27-T03** — tide-guard 입력 견고화. 두 사본 모두 입력 파싱 **전에 선두 UTF-8 BOM을 제거**한다 —
  `tide-guard.sh`는 `bom=$(printf '\357\273\277'); input=${input#"$bom"}`(POSIX 파라미터 확장, GNU 의존
  없음), `tide-guard.ps1`은 `-replace '^(﻿|ï»¿)'`(UTF-8 디코드 BOM과 오디코드 3바이트
  둘 다 방어, .NET regex 이스케이프로 소스는 ASCII). sed `cwd` 추출은 키를 **JSON 구조 경계(`{`·`,`·공백)로
  앵커링**해 `"..._cwd"` 부분일치 오인을 줄였다. `tide-guard.ps1`의 **파일 BOM은 보존**(규약대로 — 한글
  메시지). `docs/conventions.md` "tide-guard hook"에 입력 견고화 규약 한 항목, "규약↔실행 동기화"에 M27
  예를 추가. **차단/통과 판정·메시지·exit 2 계약은 불변**(아래 검증).

- **M27-T04** — sn2: `tests/multi-repo/run.ps1`의 hook-input fixture(`in.json`)를 PS 5.1 `Set-Content
  -Encoding utf8`(BOM 부착) 대신 **no-BOM UTF-8**(`[IO.File]::WriteAllText` + `UTF8Encoding($false)`)로
  쓰게 바꿨다 — 가드가 fixture를 `[Console]::In`으로 **raw** 읽으므로 BOM이 들어가면 비-PS 콘솔에서
  파싱이 throw해 시나리오가 뒤집혔던 sn2의 근원을 닫는다. 더해 **선두 BOM 입력 회귀**(시나리오 9)를 양
  셸에 추가 — 판별 셋업(cwd=A(phase 설정)/CPD=$sbx(phase 없음))으로, BOM이 cwd 추출을 깨면 폴백으로 판정이
  뒤집히는지 검사한다. 양 셸 10→**12**(동수). `.tide/phase` 쓰기는 `Set-Content -Encoding utf8` 유지(무해 —
  가드는 phase를 `Get-Content`로 읽어 BOM이 자동 strip됨; 헤더 주석에 명시). `run.sh` fixture는 `printf`라
  애초에 no-BOM이므로 회귀 단언만 추가.

- **M27-T05** — 문서 결산(`docs/project-context.md`). 이월 원장에 3행 추가(sn1·sn2·raw-`$input` grep 모두
  **fix(M27)**), "남는 미반영"을 **코드 잔여 0 / 라이브 도그푸딩만**으로 갱신. 도메인 개념의 tide-guard에
  입력 BOM 내성·키 앵커링(판정 불변), 릴리즈 위생에 finalize 브랜치 정리를 반영. 진입점 절 하니스 인벤토리에
  site-includes positive-control·multi-repo BOM 회귀(12/12)를 반영. 버전 숫자는 복제하지 않음.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | (없음) |
| 수정 | `docs/conventions.md`(T01 `pr` finalize ⑤ + T03 가드 입력 견고화 규약·동기화 예), `skills/release/SKILL.md`(T01), `tests/site-includes/run.sh`·`run.ps1`(T02), `hooks/tide-guard.sh`·`hooks/tide-guard.ps1`(T03), `tests/multi-repo/run.sh`·`run.ps1`(T04 — 회귀 단언; ps1은 fixture no-BOM도), `docs/project-context.md`(T05) |
| 삭제 | (없음) |

> T04의 마일스톤 "변경 파일"은 `run.ps1`만 명시했으나, "양 셸 카운트 정합" 완료 기준을 위해 `run.sh`에도
> 동등 회귀 단언을 추가했다(셸당 +2, 둘 다 12). 임시 검증용 probe 스크립트(`tests/_t03*.ps1`)는 사용 후 삭제.

## 테스트 결과

자동 러너가 없는 프로젝트라 **자기완결 라이브 하니스**(양 셸 `run.sh`·`run.ps1`)로 검증했다. 전 하니스
양 셸 동수·exit 0:

| 하니스 | sh | ps1 | 비고 |
|---|---|---|---|
| discover | 19 / FAIL 0 | 19 / FAIL 0 | baseline 동일(미변경) |
| fleet | 41 / FAIL 0 | 41 / FAIL 0 | baseline 동일 |
| fleet-cycle | 23 / FAIL 0 | 23 / FAIL 0 | baseline 동일 |
| fleet-verify | 29 / FAIL 0 | 29 / FAIL 0 | baseline 동일 |
| multi-repo | **12** / FAIL 0 | **12** / FAIL 0 | 10→12 (BOM 회귀 +2) |
| site-includes | **28** / FAIL 0 | **28** / FAIL 0 | 27→28 (positive-control +1) |

추가 검증:
- **BOM strip 직접 실증**(임시 probe): 선두 BOM이 붙은 hook 입력에 대해 가드가 BOM 없는 입력과 **동일 판정**
  (cwd 기반 차단/통과)을 냄을 확인. `-replace '^(﻿|ï»¿)'`가 U+FEFF·오디코드 3바이트
  둘 다 strip함을 단위 확인.
- **인코딩 규율**: `tide-guard.sh` no-BOM·`tide-guard.ps1` BOM 보존, 테스트 `.ps1` 2종 no-BOM·**ASCII-only
  (비-ASCII 0)**, `.sh` no-BOM. `git diff --stat`로 줄바꿈 플립 없음 확인(ps1 +6, sh +8/-1 등 의도 변경만).
- **판정 계약 불변 실증**: multi-repo 기존 10 시나리오(차단/통과/폴백/격리/단일레포 회귀)가 전부 동일 exit로
  통과 — T03 견고화가 차단/통과 판정을 바꾸지 않음.

## 미해결·후속 메모

1. **sn2 회귀의 환경 의존성(정직한 기록)**: BOM이 `ConvertFrom-Json` throw로 이어지는 것은 **비-PS
   콘솔(Git Bash/MSYS)**에서 `run.ps1`을 돌릴 때이고, **순수 PowerShell 콘솔에서는 `[Console]::In`이 BOM을
   흡수해 strip 없이도 올바른 판정**(실험으로 no-strip 사본도 exit 2 확인)이 나온다. 즉 ① sn2의 실질 근원은
   **하니스 fixture의 BOM**이었고(이번에 no-BOM으로 닫음), ② 가드의 BOM strip은 **jq 경로(jq는 BOM에서
   throw)·MSYS 실행**을 위한 **방어적 견고화**다. 실제 Claude Code hook 입력은 BOM 없는 UTF-8이라 production
   동작은 애초에 불변. 시나리오 9는 **MSYS 실행에서 판별적**(no-strip이면 폴백으로 뒤집힘)이고 순수 PS에선
   동일-판정 계약을 고정한다 — 리뷰가 이 환경 의존성을 확인할 수 있게 명시한다.
2. **finalize 브랜치 정리는 규약·스킬 배선만** 추가됐고 라이브 실증(실제 PR 머지→finalize→브랜치 삭제)은
   미수행(release 단계는 사이클 제외·사용자 몫). 다음 `pr` 모드 릴리즈가 도그푸딩 기회 — `git branch -d`
   거부 시 `-D` 폴백·원격 `--delete`·보호 브랜치 실패 비차단 경로를 라이브로 회수할 수 있다.
3. **잔여 미반영**: 코드로 손볼 후속은 0. 남는 것은 라이브 도그푸딩 영역(gh 게시·`pr` finalize 실증)뿐이며,
   2번이 그 회수 경로다.
