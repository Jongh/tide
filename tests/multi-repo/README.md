# 멀티 레포 라이브 실증 (tests/multi-repo)

repo-root 인식 tide-guard와 멀티 레포 격리(M13)를 재현 가능하게 검증하는 하니스다.
tide에는 자동 테스트 러너가 없으므로(도그푸딩 검증) **자기완결형 러너 스크립트**로 대신한다.

## 무엇을 검증하나

마일스톤 M13의 세 토대 중 **기계적으로 강제되는 핵심(가드의 repo-root 인식·격리·폴백)** 을
실제로 실행해 확인한다. 러너는 임시 상위 폴더 아래 자식 레포 2개(+하위 디렉터리·비-레포
디렉터리)를 만들고, 수정된 가드 스크립트를 **합성 훅 입력 JSON**으로 직접 호출해 exit 코드를
대조한 뒤 정리한다.

> 가드는 stdin으로 JSON을 받는다. `.sh`는 `sh guard < fixture.json`, `.ps1`은
> `Start-Process -RedirectStandardInput`으로 주입하고 실제 종료 코드를 확인한다.
> 자식 레포는 `git init`만 하면 되고 **commit은 불필요**하다(`rev-parse --show-toplevel`는
> 빈 레포에서도 동작).

### 시나리오 (sh·ps1 동일, 각 10건)

| # | 상황 | 기대 exit | 확인하는 것 |
|---|---|---|---|
| 1 | 자식 A `phase=impl` + commit/tag | 2 (차단) | 비-release 차단(기존 계약 유지) |
| 2 | 자식 A `phase=release` + commit | 0 (통과) | release에서만 허용 |
| 3 | A=release인 같은 시점에 B `phase=impl` + commit | 2 (차단) | **레포별 격리** — A의 release가 B를 풀어주지 않음 |
| 4 | cwd=A의 하위 디렉터리 `phase=impl` | 2 (차단) | 하위 dir에서도 **레포 루트** phase로 해석 |
| 5 | A `phase=impl` + `git status` | 0 (통과) | 차단 대상(commit/tag/push) 외 명령 무영향 |
| 6 | cwd 필드 없음 + `CLAUDE_PROJECT_DIR`=A(impl) | 2 (차단) | **폴백** — cwd 못 얻으면 기존 경로 사용 |
| 7 | non-repo cwd + phase 파일 없음 | 0 (통과) | 무차단(안전 측 — 누수 아님) |
| 8 | cwd=A 루트 (impl/release 각각) | 2 / 0 | **단일 레포 회귀** — 현행 동작과 동일 |

## 실행

```sh
# POSIX / Git Bash (Windows 기본 실행 경로 — 설치된 가드가 .sh로 동작)
sh tests/multi-repo/run.sh
```

```powershell
# Windows PowerShell (.ps1 보조 사본 검증)
& tests\multi-repo\run.ps1
```

각 러너는 모든 시나리오 통과 시 exit 0, 하나라도 실패 시 exit 1을 반환한다.

> **활성 가드 주의**: 차단 동사(commit/tag/push) 문자열은 러너 **내부 픽스처**에만 둔다.
> 러너를 호출하는 명령줄에는 차단 패턴이 없어야 활성 tide-guard가 그 호출을 막지 않는다
> (가드는 도구 호출의 command 문자열만 검사하고, 스크립트 내부 서브프로세스는 보지 않는다).

## 자동화로 못 덮는 부분 — 세션 레벨 수동 절차

산출물 앵커링·cwd 규율은 **에이전트 행위 규약**(스킬 프롬프트)이라 스크립트 단위 테스트로
강제되지 않는다. 상위 폴더 단일 세션에서 실제로 다음을 수동 확인한다:

1. 상위 폴더에서 세션을 띄우고 자식 레포 A에 대해 `/tide:milestone`→`/tide:impl`을 지시한다.
2. `docs/milestones/`·`docs/reports/`·`.tide/phase`가 **자식 레포 A 안**에만 생기고, 상위
   폴더에는 tide 산출물이 생기지 않음을 확인한다(앵커링).
3. 자식 A에 대해 `/tide:release vX.Y.Z`를 지시하면 그 레포의 실제 기본 브랜치·remote로
   commit/tag/push가 통과함을 확인한다(가드가 A의 `phase=release`를 읽으므로).
4. 같은 시점에 자식 B는 비-release 상태에서 git이 차단됨을 확인한다(격리).

상세 규약은 `docs/conventions.md`의 "멀티 레포 / 대상 레포" 절이 단일 원본이다.

## 비고

- 이 환경에는 `jq`가 없어 `.sh`는 **sed 폴백 경로**로 실증되었다. `jq`가 있으면 `jq -r '.cwd'`
  경로(자동 이스케이프)로 동작한다 — 동일 결과가 기대된다.
- Windows 경로의 백슬래시 JSON 이스케이프 해제는 `.sh`의 sed 폴백이 처리한다(`\\`→`\`,
  `\/`→`/`). 이 러너의 샌드박스 cwd는 실행 셸의 경로 형식을 그대로 쓴다.
