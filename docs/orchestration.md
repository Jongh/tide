# 오케스트레이션 사용 가이드 (orchestration)

상위 폴더 단일 세션에서 여러 tide 자식 레포(MSA)를 가로질러 운용하는 **실전 사용법**을
정리한 how-to 가이드다. 발견 → 의존·계약 선언 → 교차 사이클 자동화 → 통합 검증 →
순서대로 release 핸드오프까지의 흐름을 워크드 예제로 설명한다.

> 이 문서는 *사용법*이고, 규약(normative rules)의 단일 원본은
> [`docs/conventions.md`](conventions.md)의 "멀티 레포 오케스트레이션" 절이다. 여기서는
> 규약을 다시 규정하지 않고 인용한다 — 동작·메시지·불변의 정확한 정의는 conventions를 본다.

<!-- 아래 [start:body]~[end:body]는 사이트(site/docs/orchestration.md)가 pymdownx.snippets로
     본문만 인클루드하기 위한 마커다. 위 도입 문단은 일부러 마커 밖에 두어 사이트에서는
     사이트 전용 도입부로 대체된다. 렌더에는 영향 없음. -->
<!-- --8<-- [start:body] -->
## 전제

- tide 플러그인이 설치돼 11종 커맨드와 tide-guard hook이 활성화돼 있다.
- 여러 자식 레포가 **하나의 상위(부모) 폴더 직속 하위**에 나란히 있고, 각자 git 레포이며
  tide 산출물(`docs/milestones/` 또는 `.tide/` 또는 버전 파일)을 가진다.
- 부모 폴더에서 단일 Claude Code 세션을 띄운다. 각 멀티 레포 커맨드는 선택 인자로 다른
  부모 경로를 받을 수도 있다(생략 시 세션 cwd).

## 1단계 — 상위 폴더 구성 + `/tide:fleet`로 발견·교차 상태 보기

부모 폴더 아래에 자식 레포들을 나란히 둔다:

```
my-platform/                 ← 여기서 세션을 띄운다 (부모 cwd)
├── svc-auth/                ← 자식 tide 레포 (git + tide 산출물)
├── svc-orders/
├── svc-gateway/
├── svc-notify/
└── .tide-fleet/             ← (4단계에서 추가) 통합 훅. 숨김이라 발견에서 제외
```

부모 폴더에서 `/tide:fleet`을 실행하면 직속 1단계 하위에서 자식 tide 레포를 **발견**하고
(git + tide 산출물, `.`으로 시작하는 숨김 디렉터리는 무시), 각 레포의 사이클 위치를 교차
집계한다. 출력은 **레포별 표** + **5버킷 교차 요약**(`release 가능 N / review 대기 N /
impl 진행 N / milestone 필요 N / 보완 필요 N`) + **권장 처리 순서**다.

`/tide:fleet`은 **읽기 전용**이다 — 파일·`.tide/phase`·git을 전혀 건드리지 않고 권장
순서를 *제안*만 한다(advisory). 무엇을 언제 처리할지는 사용자가 판단한다.

## 2단계 — 자식 레포에 `.tide/deps`로 의존·계약 버전 선언

각 자식 레포 루트에 `.tide/deps`를 두어 **어느 형제 레포에 의존하는지**를 선언한다. 한
줄에 의존하는 형제 레포 디렉터리명 하나, 빈 줄과 `#` 주석은 무시, 선두 BOM은 제거된다.

```
# svc-orders/.tide/deps — orders는 auth에 의존 (auth가 먼저 처리돼야 함)
svc-auth >= v0.3.0
```

- **이름만 의존**: `svc-auth` 한 줄이면 "orders는 auth에 의존" — 순서상 auth가 먼저.
- **계약 버전 제약(옵트인)**: `<형제명>[ <op> <버전>]` 형식으로 버전 제약을 붙일 수 있다.
  전체 비교 연산자를 지원한다 — `>=`·`>`·`=`(또는 `==`)·`<=`·`<`. 예: `svc-auth >= v0.3.0`
  = "auth는 v0.3.0 이상이어야 한다". 만족이면 무표기, **불만족이면 `⚠ contract` 경고**가
  의존 레포 줄에 붙고 연산자·요구·현재가 함께 적힌다. `>=` 위반은 통상 **upstream behind**
  (의존 대상이 요구보다 낮음)다.
- 알 수 없는 연산자·비표준 버전은 **무시하고 경고**한다(차단·위반으로 단정하지 않음 — 안전 측).
- **순서는 버전 제약과 무관하게 불변**이다 — 경고는 줄 표기일 뿐, 위상정렬 순서를 바꾸지 않는다.

`.tide/deps`는 레포의 **선언**이므로 **커밋한다**. 반면 `.tide/phase`는 로컬 상태라
gitignore다 — gitignore 범위는 `.tide/`가 아니라 **`.tide/phase`만**으로 좁혀 둔다.

선언이 모이면 `/tide:fleet`의 권장 처리 순서가 위상정렬(피의존 먼저)로 산출된다. 순환
의존이면 감지·보고 후 상태 기반 순서로 폴백하고, 미선언 레포는 독립 노드로 둔다.

## 3단계 — `/tide:fleet-cycle`로 의존성 순서 교차 자동 실행

부모 폴더에서 `/tide:fleet-cycle`을 실행하면 발견한 자식 레포들을 **의존성 순서(피의존
먼저)로** 돌며, 각 레포를 그 레포 루트에 앵커해 `/tide:cycle` 의미(`milestone → impl →
review`)를 실행한다. 각 레포는 자기 보고서 상태로 시작점을 정한다(impl 보고서 없음→impl
부터, 있고 review 없음→review부터, 둘 다 있음→새 milestone).

- **release는 제외(불변)**: fleet-cycle은 **milestone→review까지만** 자동화한다. 어떤
  레포에서도 `release`를 실행하지 않고, 어떤 레포의 `.tide/phase`도 `release`로 쓰지
  않으며, cross-repo git을 자동 실행하지 않는다.
- **사전 점검**: 처리 전 각 레포의 `.tide/phase`를 읽어, `release`로 남아 있는 레포(중단된
  수동 release 잔재)는 처리에서 제외하고 경고한다(그 레포는 가드가 풀린 상태). 정리하려면
  그 레포 phase를 idle로 되돌린다.
- **계약 인식**: 레포 X가 의존 Y에 `>= 버전` 계약을 두고 Y가 upstream-behind면, X의 사이클은
  돌리되 release 핸드오프에서 X를 **"contract-blocked: Y를 먼저 release/upgrade 필요"**로
  표기한다.
- **실패·중단**: 한 레포의 사이클이 중단되면(전제조건 미충족·테스트 실패·review "불가")
  그 레포를 "중단"으로 기록하고, **그 레포에 의존하는 downstream 레포는 건너뛴다**. 무관한
  독립 레포는 계속 진행한다(부분 진행 + 명확한 보고).

출력은 **처리 순서 표**(레포 | 시작 단계 | 도달 단계 | review 판정/추천 버전 | 비고) +
**의존성 순서 release 핸드오프**(review "가능"인 레포를 위상정렬 순서로 `1) /tide:release
vX.Y.Z (repo)` 나열, contract-blocked·중단·skip은 사유와 함께 보류 표기)다. release는
사용자 몫임을 명시한다.

## 4단계 — `.tide-fleet/integration` + `/tide:fleet-verify`로 통합 검증

각 레포가 각자 사이클을 통과해도 "각자 통과"와 "함께 동작"은 다르다. release 전에 레포를
가로지르는 통합을 한 번 검증한다.

부모 폴더에 `.tide-fleet/integration`을 두고 통합 검증 명령(셸 명령 한 줄 이상, 빈 줄·`#`
주석 무시)을 적는다 — **부모 cwd에서 실행**된다:

```
# my-platform/.tide-fleet/integration
docker compose up -d
npm run integration-test
```

부모 폴더에서 `/tide:fleet-verify`를 실행하면 통합 대상 레포 목록을 보고하고, 통합 훅을
부모 cwd에서 실행해 결과를 보고한다 — **exit 0 = 통합 pass**, 비0 = 통합 fail(실패 출력
요약). 훅 미선언이면 "검증 생략"을 안내하고 graceful 종료한다.

- **git-verb 가드라일(advisory)**: 훅 실행 전 훅 명령에 git commit/tag/push·release로 보이는
  토큰이 있으면 **경고**한다(예: `⚠ 통합 훅에 git/release로 보이는 토큰 — fleet-verify는
  verification-only`). 강제 차단은 하지 않는다 — 사용자가 cross-repo git 누수를 인지하도록 알릴 뿐.
- **verification-only(불변)**: fleet-verify는 git commit/tag/push·release·cross-repo git을
  하지 않고, 어떤 레포의 `.tide/phase`도 `release`로 쓰지 않는다. 통합 훅도 검증/테스트
  명령이어야 한다(git·release를 두지 않는 것은 훅 작성자 책임).

## 5단계 — 핸드오프 순서대로 레포별 수동 `/tide:release`

통합이 pass면, 3단계 fleet-cycle이 내준 **의존성 순서 release 핸드오프**를 따라 레포별로
**수동** `/tide:release vX.Y.Z`를 실행한다. release는 부수효과 분리상 자동화하지 않는
유일한 git 단계이므로 항상 사용자가 레포별로 호출한다(contract-blocked·중단 레포는 사유를
해소한 뒤). 각 레포 release는 그 레포 루트에 앵커돼 tide-guard·레포별 격리가 그대로 적용된다.

권장 전체 흐름: **`/tide:fleet`(개요) → `.tide/deps` 선언 → `/tide:fleet-cycle`(교차 사이클)
→ `/tide:fleet-verify`(통합 검증) → 통합 pass면 핸드오프 순서대로 수동 `/tide:release`**.

## 워크드 예제 — svc-auth / svc-orders / svc-gateway / svc-notify

부모 폴더 `my-platform/`에 네 서비스가 있다. 의존 그래프:

```
svc-auth        (의존 없음 — 가장 먼저)
svc-orders   → svc-auth >= v0.3.0
svc-gateway  → svc-auth, svc-orders
svc-notify      (의존 없음 — 독립)
```

각 레포의 `.tide/deps`:

```
# svc-orders/.tide/deps
svc-auth >= v0.3.0
```
```
# svc-gateway/.tide/deps
svc-auth
svc-orders
```
(svc-auth·svc-notify는 `.tide/deps` 없음 = 의존 0.)

**위상정렬 권장 순서**: `1) svc-auth  2) svc-notify  3) svc-orders(→auth)  4) svc-gateway(→auth, orders)`
(auth·notify는 독립이라 앞쪽, orders는 auth 뒤, gateway는 둘 뒤).

**upstream-behind 계약 예시**: svc-auth의 현재 버전이 `v0.2.0`인데 svc-orders가 `>= v0.3.0`을
요구하면, fleet/fleet-cycle 출력에 다음 경고가 붙는다:

```
svc-orders → ⚠ contract svc-auth 0.2.0 < 요구 >= 0.3.0 (upstream behind — svc-auth를 먼저 올릴 것)
```

> 위 경고 문자열·연산자 비교 규칙의 **정확한 형식은 `docs/conventions.md`의 "계약 비교 규칙"이
> 단일 원본**이다(이 가이드의 예시는 그 형식을 보여줄 뿐). 형식이 갱신되면 conventions를 따른다.

이때 fleet-cycle은 svc-orders의 사이클은 돌리되 release 핸드오프에서 svc-orders를
**contract-blocked**(svc-auth를 먼저 release/upgrade)로 보류 표기한다 — 순서는 바뀌지 않는다.

**통합 훅 예시**: `my-platform/.tide-fleet/integration`에 네 서비스를 띄워 엔드투엔드를 도는
명령을 둔다:

```
# my-platform/.tide-fleet/integration
docker compose up -d
npm --prefix ./e2e run test:integration
```

`/tide:fleet-verify`가 이 훅을 부모 cwd에서 실행해 네 서비스가 **함께** 동작하는지 한 번에
검증한다(exit 0 = pass). pass면 핸드오프 순서(auth → notify → orders → gateway)대로 레포별
수동 `/tide:release`로 마무리한다.

## 안전 불변 요지

- **부수효과 분리**: 오케스트레이션 어느 층도 cross-repo `git commit/tag/push`를 자동화하지
  않는다. release는 항상 레포별 수동(`/tide:release`)이다.
- **fleet = advisory만**: 발견·순서·계약을 보기만 하고 어떤 레포도 자동 실행·차단하지 않는다.
- **fleet-cycle = release 제외**: milestone→review만 자동화하고, 어떤 레포 phase도 release로
  쓰지 않는다. 처리 전 **사전 점검**으로 stale phase=release 레포를 제외한다.
- **fleet-verify = verification-only**: 통합 훅(검증/테스트 명령)을 실행하되 git·release를
  하지 않는다. git-verb 가드라일이 훅의 git/release 토큰을 사전 경고한다.
- tide-guard는 phase≠release인 레포의 git을 막는 **백스톱**(release 차단기가 아니라 phase
  잠금)이고, 레포별 격리는 각 레포 루트의 `.tide/phase`를 따로 읽어 성립한다.

정확한 동작·메시지·계약은 [`docs/conventions.md`](conventions.md)의 "멀티 레포 오케스트레이션"
절이 단일 원본이다 — 이 가이드와 충돌하면 conventions를 따른다.
<!-- --8<-- [end:body] -->
