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

### 시나리오 (sh·ps1 동일, 각 5건)

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

> 분류·요약·advisory 인자의 정규 taxonomy 단일 원본은 `docs/conventions.md` "멀티 레포
> 오케스트레이션" 절이며, 이 러너는 그 결정적 동작을 회귀 고정한다(advisory→`/tide:impl M{N}`·
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
