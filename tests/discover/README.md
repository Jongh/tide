# discover 라이브 실증 (tests/discover)

M21 **오케스트레이션 발견성**의 **결정적 핵심** 두 가지를 재현 가능하게 검증하는 하니스다 —
① status·kickoff의 **멀티 레포 맥락 감지 힌트**(임계값 ≥2 → hint|none), ② **커맨드 수 드리프트
가드**(`skills/*/SKILL.md` 실제 개수 == 캐노니컬 문서·사이트의 "N종" 선언).

## 무엇을 검증하나 (그리고 왜 참조 구현인가)

감지 힌트는 status·kickoff **프롬프트 스킬**의 행위라 실행 바이너리가 없다(직접 호출할 `.sh`가
없다). 따라서 이 러너는 그 스킬이 인용하는 **결정적 규약**(fleet **발견** 규약 재사용 + 감지
**임계값** ≥2 판정)을 **동일 로직의 참조 셸 절차**로 재현해 픽스처에 대해 검증한다. 단일 원본은
`docs/conventions.md`의 "멀티 레포 오케스트레이션"(발견) 절 + 발견성 힌트 항목이며, 이 러너는
그 결정적 동작을 **회귀로 고정**한다.

> 스킬 프롬프트의 LLM 서술(advisory 한 줄 문구 등)은 스크립트로 100% 강제되지 않는다 —
> **결정적 핵심**(발견·임계값)만 스크립트로 덮고, **advisory 서술 품질**은 아래 세션 레벨 수동
> 절차로 분리한다(tests/fleet와 동일 분리).

### Part A — 감지 임계값 (sh·ps1 동일)

fleet 발견 참조 구현(직속 1단계·git 레포 AND tide 산출물·숨김 `.`-디렉터리 제외)을 재사용한
`detect_hint`/`DetectHint`가 자식 tide 레포 수를 세어 **≥2면 `hint N=<count>`**, **<2면 `none`**을
낸다. 픽스처별 기대:

| 부모 픽스처 | 구성 | 기대 감지 |
|---|---|---|
| `parent2` | 자식 tide 레포 **2개**(`svc-auth`·`svc-orders`) | **hint** (N=2) |
| `parent1` | 자식 tide 레포 **1개**(`only-svc`) | **none** |
| `parent0` | 자식 tide 레포 **0개**(비-tide 폴더만) | **none** |
| `single-repo` | **단일 레포 루트** — 직속 자식이 `src/`·`docs/` 등 비-tide | **none** (일반 단일 레포 세션) |
| `parenthidden` | 자식 tide 레포 **2개**(`svc-a`·`svc-b`) + **숨김** tide 자식 `.hidden-svc` | **hint** (N=2 — 숨김 미카운트) |

검증: ① 2개→hint N=2, ② 1개→none, ③ 0개→none, ④ 단일 레포 루트→none(소음 0), ⑤ 숨김
자식이 있어도 카운트에서 제외돼 hint N=2(숨김 미발견·발견 집합은 `svc-a,svc-b`).

### Part B — 커맨드 수 드리프트 가드 (sh·ps1 동일)

실제 커맨드 스킬 개수 `N = skills/*/SKILL.md 파일 수`(현재 11)를 세고, 캐노니컬 선언 위치가 같은
수 **"N종"**(예: `11종`)을 선언하는지 grep 결합 검증한다(불일치면 FAIL — M18~M20 SKILL-artifact
결합 패턴). 레포 루트는 스크립트 위치(`$(dirname "$0")/../..`)에서 해석한다.

| 캐노니컬 선언 위치 | 검증 |
|---|---|
| `README.md` | `${N}종` 선언 존재 |
| `docs/conventions.md` | `${N}종` 선언 존재 |
| `site/docs/commands.md` | `${N}종` 선언 존재 |
| `site/docs/getting-started.md` | `${N}종` 선언 존재 |

검증: ⑥ 실제 스킬 수 측정(>0), ⑦~⑩ 네 캐노니컬 파일이 전부 `${N}종`을 선언, ⑪~⑭ **드리프트
음성 통제** — 실제와 다른 수(`${N+1}종`)는 어느 캐노니컬 파일에도 없음(선언 수를 실제와 어긋나게
바꾸면 가드가 FAIL함을 입증). 이 가드는 M20 리뷰 #6(사이트 8종↔11종 표류)의 회귀 고정이다 —
커맨드를 더/빼면서 선언 수를 안 고치면 양 셸 모두 실패한다.

## 실행

```sh
sh tests/discover/run.sh       # POSIX / Git Bash
```
```powershell
& tests\discover\run.ps1       # Windows PowerShell (.ps1 사본)
```

각 러너는 전부 통과 시 exit 0, 하나라도 실패 시 exit 1. 픽스처 자식 레포는 `git init`만 하면 되고
**commit은 불필요**하다(발견은 디렉터리·산출물 존재만 본다).

> **활성 가드 주의**: git 차단 동사(commit/tag/push)는 이 러너에 등장하지 않는다(셋업은 init만
> 사용). 러너를 호출하는 명령줄에도 차단 패턴이 없어야 활성 tide-guard가 막지 않는다.
> `run.ps1`은 ASCII 소스 + 한글 카운터 토큰(`종`, U+C885)을 코드포인트로 구성해 BOM 의존을
> 없앤다(인코딩 규약). `run.sh`는 무BOM이다.

## 자동화로 못 덮는 부분 — 세션 레벨 수동 절차

감지 힌트의 **서술**(advisory 한 줄 `여러 자식 tide 레포 N개 감지 — 교차 개요는 /tide:fleet`을
status·kickoff 출력 맨 끝에 붙이는 LLM 행위)은 스크립트로 강제되지 않는다. 상위 폴더 단일
세션에서 다음을 수동 확인한다:

1. 자식 tide 레포 2개 이상을 둔 상위 폴더에서 세션을 띄우고 `/tide:status`(또는 `/tide:kickoff`)를
   호출한다.
2. 본래 보고 끝에 `여러 자식 tide 레포 N개 감지 — 교차 개요는 /tide:fleet` 한 줄이 advisory로
   붙고, status는 **완전 읽기 전용**(파일·git·phase 무변경), kickoff는 골격 생성 외 동작 불변임을
   확인한다.
3. 자식 tide 레포가 2개 미만(단일 레포 세션 포함)인 폴더에서 호출하면 **그 줄이 붙지 않음**(소음 0,
   기존 출력 바이트 동일)을 확인한다.

상세 규약은 `docs/conventions.md`의 "멀티 레포 오케스트레이션"(발견) 절 + 발견성 힌트 항목이
단일 원본이다.
