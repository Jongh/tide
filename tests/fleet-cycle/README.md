# fleet-cycle 라이브 실증 (tests/fleet-cycle)

`/tide:fleet-cycle`(멀티 레포 오케스트레이션 3층 — 교차 사이클 자동화)의 **결정적 핵심**을
재현 가능하게 검증하는 하니스다.

**현재 케이스 수 (cases: 24)** — `run.sh` @ **dash**(우분투 `/bin/sh`) · `run.sh` @ **bash**(Git
Bash) · `run.ps1` @ **Windows PowerShell 5.1** · `run.ps1` @ **pwsh 7** — **네 실행 환경 모두**
같은 수, FAIL 0.

> 이 한 줄이 **케이스 수의 유일한 선언처**다(규약: `docs/conventions.md`의 "문서 자기서술 정합").
> 러너가 종료 직전 `cases` 토큰으로 이 값을 **추출해 자기 실제 실행 수와 대조**하므로, 케이스를
> 더하거나 빼고 이 줄을 안 고치면 **양 셸이 FAIL한다**. 선언을 **못 읽는 경우**(파일 없음·토큰
> 없음)도 FAIL이다 — 못 읽어서 건너뛰고 통과하는 경로는 두지 않는다. 다른 문서·이 파일의 다른
> 줄은 이 수를 옮겨 적지 않는다.

## 무엇을 검증하나 (그리고 왜 참조 구현인가)

fleet-cycle은 **프롬프트 스킬**이고 실제 사이클 실행(각 레포 `milestone → impl → review`)은
**LLM 행위**라 실행 바이너리가 없다. 따라서 이 러너는 그 스킬이 따르는 **결정적 규약**을 **동일
로직의 참조 셸 절차**로 재현해 픽스처에 대해 검증한다. 단일 원본은 `docs/conventions.md`의
"멀티 레포 오케스트레이션" 절이며, 이 러너는 그 규약의 결정적 동작을 **회귀로 고정**한다.

> 실제 교차 사이클 실행의 **품질**(레포별 앵커링·보고서 상태 기반 시작점·격리된 산출물 등)은
> 스크립트로 100% 강제되지 않는다 — **결정적 핵심**(처리 순서·release 제외·contract-blocked·
> downstream skip)만 스크립트로 덮고, **실행 품질**은 아래 세션 레벨 수동 절차로 분리한다.

발견·`.tide/deps` 파싱·위상정렬·semver/계약 검사는 `tests/fleet`의 참조 구현을 재사용하며,
이 러너는 그 위에 fleet-cycle 고유의 결정적 핵심 4종을 더한다.

### 시나리오 (sh·ps1 동일)

| # | 시나리오 | 픽스처 | 검증 |
|---|---|---|---|
| 1 | **처리 순서 = 위상정렬** | `topo/auth`(무의존) ← `orders`(→auth) ← `gateway`(→auth) ← `notify`(→orders) | auth가 orders·gateway보다 **앞**, orders가 notify보다 앞(전이), auth가 notify보다 앞(전이), 4노드 전부 존재, 순환 아님 |
| 2 | **release 제외(불변)** | 자동 단계열 참조 = `milestone impl review` | 자동 계획에 **`release` 단계 없음**, milestone으로 시작·review로 종료(릴리즈 아님) |
| 3 | **contract-blocked** | `contract/auth`(0.2.0) ← `orders`(`auth >= v0.3.0`) / `gateway`(`auth >= v0.2.0`) | upstream-behind인 orders는 핸드오프에서 **contract-blocked**(보류), 만족하는 gateway는 **release-ready** |
| 4 | **downstream skip** | `fail/auth` ← `orders`(→auth) ← `gateway`(→auth) ← `notify`(→orders), `solo`(독립) | auth 중단 시 의존자(전이 포함) orders·gateway·notify=**skip**, 독립 `solo`=**ok**, auth 자신=failed; orders만 중단 시 notify만 skip(부분 진행) |

#### 처리 순서 (시나리오 1)

자식 레포 의존 그래프의 **위상정렬**(피의존 먼저)이 fleet-cycle의 처리 순서다(M16 toposort
재사용). 피의존 레포(auth)를 먼저 처리해야 그 위에 의존하는 레포(orders/gateway, 전이로 notify)가
최신 전제 위에서 사이클을 돈다. 순환이면 `CYCLE` 센티넬 → 상태 기반 순서로 폴백한다(advisory).

#### release 제외 (시나리오 2 — 핵심 불변)

fleet-cycle은 각 레포에서 **milestone→impl→review까지만** 자동 체이닝한다. 자동 계획의 단계열을
산출하는 참조(`plan_stages`/`PlanStages`)는 결코 `release` 단계를 포함하지 않으며, 러너는 그
부재를 적극 검증한다. release는 **별도 핸드오프 목록**으로만 산출되고, 실행은 사용자 몫이다.
각 레포 impl/review는 phase≠release라 tide-guard가 git을 차단하므로, 자동화 중 어떤 레포에서도
commit/tag/push가 일어날 수 없다(기계적 보장).

#### contract-blocked (시나리오 3)

레포 X가 의존 Y에 `>= 버전` 계약을 두고 Y가 **upstream-behind**(현재 버전이 요구 미만)면, X의
사이클은 돌리되 release 핸드오프에서 X를 **contract-blocked**(Y를 먼저 release/upgrade 필요)로
표기한다. release-ready로 단정하지 않는다. semver/계약 검사는 `tests/fleet`(M17) 재사용.

#### downstream skip (시나리오 4)

한 레포의 사이클이 "중단"되면 위상정렬상 그 레포에 (직접·전이적으로) 의존하는 downstream 레포를
**skip**으로 분류한다(역방향 도달성 BFS 참조 구현). 그와 무관한 독립 레포는 **ok**로 계속 진행한다
(전체 중단이 아니라 부분 진행 + 명확한 보고).

## 실행

```sh
sh tests/fleet-cycle/run.sh          # POSIX / Git Bash
```
```powershell
& tests\fleet-cycle\run.ps1          # Windows PowerShell (.ps1 사본)
```

각 러너는 전부 통과 시 exit 0, 하나라도 실패 시 exit 1. 자식 레포는 `git init`만 하면 되고
**commit은 불필요**하다(발견은 디렉터리·산출물 존재만 본다).

> **활성 가드 주의**: git 차단 동사(commit/tag/push)는 이 러너에 등장하지 않는다(setup은 init만
> 사용). 러너를 호출하는 명령줄에도 차단 패턴이 없어야 활성 tide-guard가 막지 않는다.
> `run.ps1`은 **ASCII 소스**(127 초과 바이트 0)로 작성한다(인코딩 규약). **release·cross-repo
> git은 자동화 대상이 아니며**, 이 러너는 release가 자동 계획에 없음을 적극 검증한다.

## 자동화로 못 덮는 부분 — 세션 레벨 수동 절차

실제 교차 사이클 **실행**(레포별 앵커링·보고서 상태 기반 시작점·격리된 산출물·실시간 중단 처리)은
스킬 프롬프트의 LLM 행위라 스크립트로 강제되지 않는다. 상위 폴더 단일 세션에서 다음을 수동 확인한다:

1. 자식 tide 레포 2~3개(예: 의존 그래프 auth ← orders ← notify, gateway ← auth)를 둔 상위
   폴더에서 세션을 띄우고 `/tide:fleet-cycle`을 호출한다(또는 인자로 부모 경로 지정).
2. **처리 순서대로** 각 레포가 그 레포 루트에 **앵커**되어(M13 cwd 규율) `/tide:cycle` 의미
   (보고서 상태로 시작점 결정 → `milestone → impl → review`)로 실행되는지 확인한다 — 피의존
   레포(auth)가 먼저, 의존 레포(orders/gateway, 전이로 notify)가 뒤.
3. **어떤 레포에서도 `release`·git commit/tag/push·cross-repo git이 일어나지 않음**을 확인한다
   (부수효과 분리 불변). 각 레포 산출물·`.tide/phase`는 그 레포 루트 기준으로 격리되고, 자동화는
   review까지만 진행한다(릴리즈 단계 진입 없음).
4. 마지막 출력에 **① 처리 순서 표**(레포명·시작/도달 단계·review 판정·비고)와 **② 의존성 순서
   release 핸드오프**(review 가능 레포를 위상정렬 순서로 `1) /tide:release vX.Y.Z (repo)` 나열)가
   나오는지 확인한다. upstream-behind 의존이 있는 레포는 **contract-blocked**(선결 필요)로,
   중단·downstream-skip 레포는 사유와 함께 **보류**로 표기되며, release는 **사용자 몫**임이 명시됨.
5. 한 레포의 사이클이 중단되면 그 레포에 의존하는 downstream이 **skip**(사유 기록)되고, 무관한
   독립 레포는 계속 진행됨(부분 진행 + 명확한 보고)을 확인한다.
6. 자식 tide 레포가 없는 폴더에서 호출하면 단일 레포로 graceful 강등(현재 레포 `/tide:cycle`
   권유)함을 확인한다.

상세 규약은 `docs/conventions.md`의 "멀티 레포 오케스트레이션" 절이 단일 원본이다.
