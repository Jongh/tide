# fleet-verify 라이브 실증 (tests/fleet-verify)

`/tide:fleet-verify`(멀티 레포 오케스트레이션 4층 — 통합 검증 훅)의 **결정적 핵심**을 재현
가능하게 검증하는 하니스다.

**현재 케이스 수 (cases: 30)** — `run.sh` @ **dash**(우분투 `/bin/sh`) · `run.sh` @ **bash**(Git
Bash) · `run.ps1` @ **Windows PowerShell 5.1** · `run.ps1` @ **pwsh 7** — **네 실행 환경 모두**
같은 수, FAIL 0.

> 이 한 줄이 **케이스 수의 유일한 선언처**다(규약: `docs/conventions.md`의 "문서 자기서술 정합").
> 러너가 종료 직전 `cases` 토큰으로 이 값을 **추출해 자기 실제 실행 수와 대조**하므로, 케이스를
> 더하거나 빼고 이 줄을 안 고치면 **양 셸이 FAIL한다**. 선언을 **못 읽는 경우**(파일 없음·토큰
> 없음)도 FAIL이다 — 못 읽어서 건너뛰고 통과하는 경로는 두지 않는다. 다른 문서·이 파일의 다른
> 줄은 이 수를 옮겨 적지 않는다.

## 무엇을 검증하나 (그리고 왜 참조 구현인가)

fleet-verify는 **프롬프트 스킬**이고 실제 통합 훅 실행(부모 cwd에서 `.tide-fleet/integration`
명령 실행)은 **LLM 행위**라 실행 바이너리가 없다. 따라서 이 러너는 그 스킬이 따르는 **결정적
규약**을 **동일 로직의 참조 셸 절차**로 재현해 픽스처에 대해 검증한다. 단일 원본은
`docs/conventions.md`의 "멀티 레포 오케스트레이션"(통합 검증 절)이며, 이 러너는 그 규약의 결정적
동작을 **회귀로 고정**한다.

> 실제 통합 훅 **실행 품질**(부모 cwd 앵커링·다중 레포를 띄운 contract/통합 테스트·실패 출력
> 요약 등)은 스크립트로 100% 강제되지 않는다 — **결정적 핵심**(훅 발견/파싱·옵트인 생략·pass/fail
> 분류·verification-only·`.tide-fleet/` 발견 무시)만 스크립트로 덮고, **실행 품질**은 아래 세션
> 레벨 수동 절차로 분리한다.

발견 규약은 `tests/fleet`/`tests/fleet-cycle`의 참조 구현을 재사용하며(직속·git·tide 산출물·숨김
무시), 이 러너는 그 위에 fleet-verify 고유의 결정적 핵심을 더한다.

### 시나리오 (sh·ps1 동일)

| # | 시나리오 | 픽스처 | 검증 |
|---|---|---|---|
| 1 | **훅 발견/파싱** | `parse/.tide-fleet/integration` = 선두 BOM + `#` 주석 + 빈 줄 + 명령 2줄 + 후행 주석 | 선두 BOM 제거·주석/빈 줄 무시 후 명령 줄 2개(`docker compose up -d`, `npm run integration-test`)만 추출, 분류 = **declared** |
| 2 | **옵트인 생략** | `nohook`(파일 없음) / `emptyhook`(주석·빈 줄뿐) | 둘 다 유효 줄 0 → **skip**(통합 훅 미선언), skip이면 실행 분류도 skip |
| 3 | **pass/fail 분류** | `passhook`(`exit 0`) / `failhook`(`exit 1`) / `multifail`(`exit 0`→`exit 1`) | exit 0 = **pass**, 비0 = **fail**, 다단계 중 하나라도 비0 → fail (git 동사 미사용) |
| 4 | **verification-only** | 자동 단계열 참조 = `discover hook report` + `skills/fleet-verify/SKILL.md` grep | 자동 계획에 **`release`·`git` 단계 없음**, report로 종료(릴리즈 아님); SKILL.md에 **금지 목록**(release / git commit / git tag / git push / cross-repo git)·**verification-only** 산문 존재 |
| 4c | **git-verb 가드라일** (M20 advisory) | `guardrail-git`(`git push`) / `guardrail-release`(`npm run release`) / `guardrail-clean`(`npm test`·`docker compose up -d`) / `guardrail-mixed`(`npm test`+`git commit`) | 훅 명령에 git commit/tag/push·release 토큰 있으면 **warn**(가드라일 플래그), 클린 훅은 **ok**, 미선언은 **skip**. 다단계 중 하나라도 git-verb면 전체 warn. 참조 함수 `has_git_verb`/`HasGitVerb`. **토큰은 FIXTURE 문자열일 뿐 실행 안 됨**(실행 전 점검·경고, 차단 아님) |
| 5 | **`.tide-fleet/` 발견 무시** | `discover/auth`·`orders`(자식 레포) + `.tide-fleet`(통합 훅 보관소, 가짜 tide 산출물 포함) | 발견은 자식 레포 `auth orders`만, **`.tide-fleet` 미포함**(숨김 dot 디렉터리), 2노드 |

#### 훅 발견/파싱 (시나리오 1)

대상 부모의 `.tide-fleet/integration`을 읽어 **선두 UTF-8 BOM을 제거**하고 `#` 주석·빈 줄을
무시한 뒤 남은 줄(들)이 통합 검증 명령이다. 부모 cwd에서 실행한다(예: `docker compose up -d &&
npm run integration-test`). BOM 내성은 `.tide/deps` 파싱(M16/M19)과 동일 규약이다.

#### 옵트인 생략 (시나리오 2)

`.tide-fleet/integration`이 없거나 유효 줄이 0이면 **통합 훅 미선언**으로 분류해 fleet-verify가
"통합 검증 생략(훅 없음)"을 안내하고 graceful 종료한다. 단일 레포·미선언 fleet 동작은 현행 불변
(가산·옵트인).

#### pass/fail 분류 (시나리오 3)

통합 훅을 부모 cwd에서 실행해 **exit 0 = 통합 pass**, 비0 = **통합 fail**(실패 출력 요약)로
매핑한다. 모의 훅은 이식 가능한 `exit 0`/`exit 1`을 쓰며 **git 동사를 쓰지 않는다**. 다단계
명령 중 하나라도 비0이면 전체 fail이다.

#### verification-only (시나리오 4 — 핵심 불변)

fleet-verify는 통합 훅(검증/테스트)만 실행하며 **git commit/tag/push·release·cross-repo git을
하지 않고** 어떤 레포의 `.tide/phase`도 `release`로 쓰지 않는다. 자동 계획 단계열을 산출하는
참조(`plan_stages`/`PlanStages`)는 결코 `release`·`git` 단계를 포함하지 않으며, 러너는 그 부재를
적극 검증한다. 나아가 이 불변을 실제로 강제하는 **스킬 산문**(`skills/fleet-verify/SKILL.md`의
금지 목록·verification-only 불변)이 회귀하면 fail하도록 SKILL.md를 grep해
**결합**한다(적대 리뷰 대응). `run.ps1`은 ASCII 소스라 ASCII 부분 문자열만 매칭한다(한국어는
스킬이 보유).

#### git-verb 가드라일 (시나리오 4c — M20 advisory)

fleet-verify는 verification-only라 통합 훅에 git commit/tag/push·release가 합법적으로 필요한 변형은
드물다(major-safe). 훅을 실행하기 **전에** 명령에 그런 토큰이 있는지 `has_git_verb`/`HasGitVerb`로
점검해, 있으면 **warn**(cross-repo git 누수 인지)·없으면 **ok**·미선언이면 **skip**으로 분류한다.
다단계 훅 중 한 줄이라도 git-verb면 전체 warn이다. **정석 cross-repo 형태**(`git -C <dir> push`·
`git --git-dir=… commit` 등 git과 동사 사이에 인자가 끼는 형태)도 잡는다(M20-review #5 — 매칭이
`git <동사>` 인접형만 보면 누수가 빠져나간다). 읽기 전용 git(`git status`)은 변이 동사가 없어 **warn하지
않는다**(오탐 방지). 가드라일은 훅 실행을 **강제 차단하지 않으며**(advisory), 토큰은 픽스처 파일 안의
**문자열일 뿐 실행되지 않는다**(러너 명령줄 밖). M19 적대 검증이 짚은 훅 공격 표면을 advisory 가드라일로
좁힌다.

#### `.tide-fleet/` 발견 무시 (시나리오 5)

`.tide-fleet/`는 숨김(dot) 디렉터리라 fleet 발견(직속·숨김 무시)에서 자식 레포로 잡히지 않는다
(통합 훅 보관소이지 자식 레포 아님). 안에 가짜 tide 산출물(`docs/milestones`, `.git`)을 둬도
숨김 무시 규약이 이를 발견에서 배제하므로 1~3층과 충돌하지 않는다.

## 실행

```sh
sh tests/fleet-verify/run.sh          # POSIX / Git Bash
```
```powershell
& tests\fleet-verify\run.ps1          # Windows PowerShell (.ps1 사본)
```

각 러너는 전부 통과 시 exit 0, 하나라도 실패 시 exit 1. 자식 레포는 `git init`만 하면 되고
**commit은 불필요**하다(발견은 디렉터리·산출물 존재만 본다).

> **활성 가드 주의**: git 차단 동사(commit/tag/push)는 이 러너에 등장하지 않는다(setup은 init만
> 사용, 모의 훅은 `exit 0`/`exit 1`). 러너를 호출하는 명령줄에도 차단 패턴이 없어야 활성
> tide-guard가 막지 않는다. `run.ps1`은 **ASCII 소스**(127 초과 바이트 0)로 작성한다(인코딩
> 규약). **release·git·cross-repo git은 fleet-verify의 동작이 아니며**(verification-only), 이
> 러너는 release/git이 자동 계획에 없음을 적극 검증한다.

## 자동화로 못 덮는 부분 — 세션 레벨 수동 절차

실제 통합 훅 **실행**(부모 cwd 앵커링·다중 레포를 띄운 통합/contract 테스트·실패 출력 요약·다음
안내)은 스킬 프롬프트의 LLM 행위라 스크립트로 강제되지 않는다. 상위 폴더 단일 세션에서 다음을
수동 확인한다:

1. 자식 tide 레포 2~3개를 둔 상위 폴더에 `.tide-fleet/integration`을 선언한다(예:
   `docker compose up -d && npm run integration-test` — **검증/테스트 명령만**, release/git 금지).
2. 그 상위 폴더에서 세션을 띄우고 `/tide:fleet-verify`를 호출한다(또는 인자로 부모 경로 지정).
3. fleet 발견이 자식 tide 레포 목록을 보고하고 **`.tide-fleet/`는 자식으로 잡히지 않음**을
   확인한다(숨김 디렉터리·발견 무시).
4. 통합 훅이 **부모 cwd에서 실행**되고 결과가 **exit 0 = 통합 pass / 비0 = 통합 fail**(실패 시
   출력 요약 + 관련 레포)로 보고되는지 확인한다.
5. **어떤 레포에서도 `release`·git commit/tag/push·cross-repo git이 일어나지 않음**을 확인한다
   (verification-only 불변). 어떤 레포의 `.tide/phase`도 `release`로 쓰이지 않으며, tide-guard가
   phase≠release 레포의 git을 막는 백스톱은 그대로다.
6. 출력에 **① 통합 대상 레포 목록·② 통합 훅 명령 요약·③ 통합 결과(pass/fail + 실패 요약)·④ 다음
   안내**(pass면 "release 핸드오프 순서대로 수동 `/tide:release`", fail이면 "통합 수정 후
   재검증")가 나오는지 확인한다.
7. `.tide-fleet/integration`이 **없는** 상위 폴더에서 호출하면 "통합 검증 생략(훅 없음)"으로
   graceful 강등하고, 자식 tide 레포가 없으면 단일 레포로 강등(현재 레포 `/tide:status` 권유)함을
   확인한다.

상세 규약은 `docs/conventions.md`의 "멀티 레포 오케스트레이션"(통합 검증) 절이 단일 원본이다.
