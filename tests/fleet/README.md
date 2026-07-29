# fleet 라이브 실증 (tests/fleet)

`/tide:fleet`(멀티 레포 오케스트레이션 1층)의 **결정적 핵심**을 재현 가능하게 검증하는 하니스다.

## 무엇을 검증하나 (그리고 왜 참조 구현인가)

fleet은 **프롬프트 스킬**이라 실행 바이너리가 없다(tide-guard처럼 직접 호출할 `.sh`가 없다).
따라서 이 러너는 fleet이 따르는 **결정적 규약**(자식 tide 레포 **발견** 규약 + `/tide:status`
**분류** 규칙)을 **동일 로직의 참조 셸 절차**로 재현해 픽스처에 대해 검증한다. 단일 원본은
`docs/conventions.md`의 "멀티 레포 오케스트레이션" 절이며, 이 러너는 그 규약의 결정적 동작을
**회귀로 고정**한다(규약이 바뀌어 발견·분류가 깨지면 실패한다).

> 스킬 프롬프트의 LLM 서술(advisory 계획 문장 등)은 스크립트로 100% 강제되지 않는다 —
> **결정적 핵심**(발견·분류·강등)만 스크립트로 덮고, **advisory 서술 품질**은 아래 세션 레벨
> 수동 절차로 분리한다(M13 앵커링 수동 절차와 동일 분리).

### 시나리오 (sh·ps1 동일, 각 41건)

러너는 임시 상위 폴더 아래에 서로 다른 사이클 위치의 자식들을 만든다:

| 자식 | 구성 | 기대 position |
|---|---|---|
| `repo-a` | git + milestone + impl + review(판정 가능) + 버전 파일 | 발견됨 / **release 가능** (release-ready) |
| `repo-b` | git + milestone + impl (review 없음) | 발견됨 / **review 대기** (review-pending) |
| `repo-c` | git + milestone만 | 발견됨 / **impl 진행** (impl-inprogress) |
| `repo-d` | git + milestone + impl + review(판정 **불가**) | 발견됨 / **보완 필요** (needs-fix) |
| `repo-e` | git + `.tide` + 버전 파일 (마일스톤 없음) | 발견됨 / **milestone 필요** (milestone-needed) |
| `plain` | 비-git 일반 디렉터리 | **발견 제외** |
| `notide` | git이나 tide 산출물 없음 | **발견 제외** |
| `.hidden-svc` | git + tide 산출물이나 **숨김(dot) 디렉터리** | **발견 제외** |

검증: ① 발견 = tide 레포만(plain·notide·.hidden 제외, **직속 1단계 + 숨김 무시**), ② 5 position
분류 정확(release 가능/review 대기/impl 진행/보완 필요/milestone 필요), ③ **교차 요약 5버킷 1:1**
(`release=1 review=1 impl=1 milestone=1 fix=1`, 합산 금지), ④ tide 레포 0개 부모 → **graceful 강등**.

### 다중 자리 마일스톤(M10+) 픽스처 (M14 사소4 — `sort -V`/자연 정렬)

M2·M9·M10이 공존하는 `multidigit` 픽스처에서 **최신 마일스톤이 M10(다중 자리)으로 집히는지** 검증한다
(단순 사전순이면 `M10 < M9 < M2`로 잘못 정렬돼 M9가 최신으로 집힌다). sh는 `sort -V`, ps1은 마일스톤
번호의 정수 자연 정렬로 동일하게 M10을 집는다. 검증: ⑮ 최신 = M10(M9 아님), ⑯ 분류가 M10 기준
(M10-impl만 있고 M10-review 없음 → review 대기), ⑰ M9 완료 산출물이 있어도 분류는 M10 기준 불변.

### 의존성 인식 순서 (M16 — `.tide/deps` 위상정렬·폴백)

`.tide/deps` 파싱(한 줄에 형제 레포명 하나, `#` 주석·빈 줄 무시, 트림) + 발견 집합 위 방향 그래프
**위상정렬**(피의존 먼저) + **순환 감지 폴백**(센티넬 `CYCLE`)을 참조 구현으로 회귀 고정한다.
별도 픽스처 상위 폴더에서 검증한다:

| 픽스처 | `.tide/deps` 구성 | 검증 |
|---|---|---|
| `topo/auth` | (없음) | 무의존 — 순서 선두 그룹 |
| `topo/orders` | `auth` + 미존재명 `nowhere`(트림 포함) | auth가 orders보다 **앞**, 미존재명 **무시** |
| `topo/gateway` | `# dep` 주석 + `auth` | auth가 gateway보다 **앞**(주석 무시) |
| `topo/solo` | (없음) | **미선언 독립** — 순서에 그대로 존재 |
| `cycle/a` ↔ `cycle/b` | a→b, b→a | **순환 감지 → `CYCLE` 폴백 신호** |

검증: ⑤ 위상정렬 순서에서 `auth`가 `orders`·`gateway`보다 앞(인덱스 비교), ⑥ 미선언 `solo`가
순서에 존재(위상 제약 없음), ⑦ 미존재 형제명(`nowhere`)은 무시(크래시 없이 순서 4노드 유지),
⑧ 순환(a↔b)은 `CYCLE` 센티넬로 감지 — fleet 스킬은 이때 상태 기반 순서로 폴백한다(advisory).
fleet은 순서를 **제안만** 하며 cross-repo git을 자동 실행하지 않는다(부수효과 분리 불변).

### 계약 버전 비교 + BOM 내성 (M17→M20 — `.tide/deps` 전체 연산자 제약·semver·선두 BOM)

`.tide/deps` 의존 줄의 **선택적 버전 제약**(`<형제명> <op> <버전>`)을 의존 대상의 현재 버전
(`package.json` `version`)과 **semver(major.minor.patch, 선행 `v` 선택) 비교**해 만족 여부를
판정하고, 불만족이면 위반(예: `upstream behind`)을 플래그한다. **M20: 전체 연산자**
`>=`·`>`·`=`(`==`)·`<=`·`<`를 지원한다(참조 구현은 3원 비교 `semver_cmp`/`SemverCmp` + 연산자
평가 `eval_op`/`EvalOp`). **알 수 없는 연산자**(예: `~>`)는 제약을 무시한다(`none` — 위반 단정 안 함).
버전 파싱 불가면 비교를 생략한다(`skip`, 크래시·오탐 없음). 파서는 **선두 UTF-8 BOM(`EF BB BF`)을
제거**해 BOM 붙은 첫 줄(주석·의존명)도 올바로 파싱한다. 버전 제약은 위상정렬 순서를 바꾸지 않는다
(이름 의존만 토포 반영).

| 픽스처 | `.tide/deps` 구성 | auth 현재 | 검증 |
|---|---|---|---|
| `contract/ge_ok` | `auth >= v0.2.0` | 0.2.0 | **만족**(satisfied) |
| `contract/ge_bad` | `auth >= v0.3.0` | 0.2.0 | **위반**(violation — upstream behind) |
| `contract/gt_ok` | `auth > v0.1.0` | 0.2.0 | **만족**(satisfied) |
| `contract/gt_bad` | `auth > v0.2.0` | 0.2.0 | **위반**(violation) |
| `contract/eq_ok` · `eqeq_ok` | `auth = v0.2.0` / `auth == v0.2.0` | 0.2.0 | **만족**(satisfied — `=`/`==` 동의어) |
| `contract/eq_bad` · `eqeq_bad` | `auth = v0.3.0` / `auth == v0.3.0` | 0.2.0 | **위반**(violation — `=`·`==` 둘 다) |
| `contract/le_ok` | `auth <= v0.2.0` | 0.2.0 | **만족**(satisfied) |
| `contract/le_bad` | `auth <= v0.1.0` | 0.2.0 | **위반**(violation) |
| `contract/lt_ok` | `auth < v0.3.0` | 0.2.0 | **만족**(satisfied) |
| `contract/lt_bad` | `auth < v0.2.0` | 0.2.0 | **위반**(violation) |
| `contract/unkop` | `auth ~> v0.1.0` | 0.2.0 | **무시**(none — 미지 연산자) + **이름 의존 보존**(read_deps=`auth`, 토포 엣지 유지) |
| `contract/unksym` | `auth ~ v0.1.0` | 0.2.0 | **무시**(none — 기호 없는 미지 연산자) + **이름 의존 보존**(엣지 유지) |
| `contract/badver` | `auth >= banana` | 0.2.0 | **비교 생략**(skip — 비표준 버전, 크래시 없음) |
| `bom/svc` | **선두 BOM** + `# dep file` 주석 + `auth >= v0.2.0` | 0.2.0 | BOM+주석 첫 줄 무시·의존명 파싱·계약 **satisfied** |
| `bom2/svc` | **선두 BOM** + `auth`(주석 없음) | — | BOM+의존명 첫 줄 이름 매칭 정상 |

검증: ⑱ 각 연산자(`>=`·`>`·`=`/`==`·`<=`·`<`)의 **만족(satisfied)·위반(violation)** 짝(`==` 위반 포함)·
⑲ 알 수 없는 연산자(`~>`·`~`) 무시(`none`)이되 **이름 의존은 보존**돼 토포 엣지가 유지됨(미지 연산자가
의존 엣지를 떨어뜨리지 않음 — 이름 추출이 첫 공백 토큰 기반)·⑳ 버전 파싱 불가 시 비교 생략(`skip`)·
㉑ 버전 제약/미지 연산자 줄도 토포 이름 의존 유지(`auth`가 의존측보다 먼저)·㉒ BOM 붙은 deps의 첫 줄
(주석/의존명) 정상 파싱 + BOM'd 줄의 계약 비교 정상. 경고는 **advisory만** — fleet은 순서를 바꾸거나
차단·실행하지 않는다(읽기 전용·부수효과 분리 불변).

> 분류·요약·advisory 인자의 정규 taxonomy 단일 원본은
> `docs/conventions.md`의 "멀티 레포 오케스트레이션" 절이며,
> 이 러너는 그 결정적 동작을 회귀 고정한다(advisory→`/tide:impl M{N}`·
> `/tide:release v{추천}` 등 인자 포함).

## 실행

```sh
sh tests/fleet/run.sh          # POSIX / Git Bash
```
```powershell
& tests\fleet\run.ps1          # Windows PowerShell (.ps1 사본)
```

각 러너는 전부 통과 시 exit 0, 하나라도 실패 시 exit 1. 자식 레포는 `git init`만 하면 되고
**commit은 불필요**하다(발견은 디렉터리·산출물 존재만 본다).

> **활성 가드 주의**: git 차단 동사(commit/tag/push)는 이 러너에 등장하지 않는다(발견은 init만
> 사용). 러너를 호출하는 명령줄에도 차단 패턴이 없어야 활성 tide-guard가 막지 않는다.
> `run.ps1`은 ASCII 소스 + 한글 판정 토큰을 코드포인트로 구성해 BOM 의존을 없앤다(인코딩 규약).

## 자동화로 못 덮는 부분 — 세션 레벨 수동 절차

advisory 계획 **서술**(레포별 다음 커맨드 제시·순서 advisory·의존성 미지원 명시)은 스킬 프롬프트의
LLM 행위라 스크립트로 강제되지 않는다. 상위 폴더 단일 세션에서 실제로 다음을 수동 확인한다:

1. 자식 레포 2~3개를 둔 상위 폴더에서 세션을 띄우고 `/tide:fleet`을 호출한다(또는 인자로 부모
   경로 지정).
2. 출력에 **레포별 표 + 교차 요약 + 레포별 다음 커맨드**가 나오고, 어떤 레포에도 파일·`.tide/phase`·
   git 변경이 **일어나지 않음**(읽기 전용)을 확인한다.
3. release 가능 레포에 `/tide:release v{추천}`이 advisory로 제시되되, fleet이 그것을 **자동 실행하지
   않음**(부수효과 분리 불변)을 확인한다.
4. 자식 tide 레포가 없는 폴더에서 호출하면 "단일 레포로 보임" 안내 + `/tide:status` 권유로
   graceful 강등함을 확인한다.

상세 규약은 `docs/conventions.md`의 "멀티 레포 오케스트레이션" 절이 단일 원본이다.
