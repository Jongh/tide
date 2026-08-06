# 멀티 레포 라이브 실증 (tests/multi-repo)

repo-root 인식 tide-guard와 멀티 레포 격리(M13)를 재현 가능하게 검증하는 하니스다.
tide에는 자동 테스트 러너가 없으므로(도그푸딩 검증) **자기완결형 러너 스크립트**로 대신한다.

**현재 케이스 수 (cases: 31)** — `run.sh` @ **dash**(우분투 `/bin/sh`) · `run.sh` @ **bash**(Git
Bash) · `run.ps1` @ **Windows PowerShell 5.1** · `run.ps1` @ **pwsh 7** — **네 실행 환경 모두**
같은 수, FAIL 0. `run.ps1`은 아래 "지원 기동 맥락"을 함께 읽는다.

> 이 한 줄이 **케이스 수의 유일한 선언처**다(규약: `docs/conventions.md`의 "문서 자기서술 정합").
> 러너가 종료 직전 `cases` 토큰으로 이 값을 **추출해 자기 실제 실행 수와 대조**하므로, 케이스를
> 더하거나 빼고 이 줄을 안 고치면 **양 셸이 FAIL한다**. 선언을 **못 읽는 경우**(파일 없음·토큰
> 없음)도 FAIL이다 — 못 읽어서 건너뛰고 통과하는 경로는 두지 않는다. 다른 문서·이 파일의 다른
> 줄은 이 수를 옮겨 적지 않는다.

## 무엇을 검증하나

마일스톤 M13의 세 토대 중 **기계적으로 강제되는 핵심(가드의 repo-root 인식·격리·폴백)** 을
실제로 실행해 확인한다. 러너는 임시 상위 폴더 아래 자식 레포 2개(+하위 디렉터리·비-레포
디렉터리)를 만들고, 수정된 가드 스크립트를 **합성 훅 입력 JSON**으로 직접 호출해 exit 코드를
대조한 뒤 정리한다.

> 가드는 stdin으로 JSON을 받는다. `.sh`는 `sh guard < fixture.json`, `.ps1`은
> `Start-Process -RedirectStandardInput`으로 주입하고 실제 종료 코드를 확인한다.
> 자식 레포는 `git init`만 하면 되고 **commit은 불필요**하다(`rev-parse --show-toplevel`는
> 빈 레포에서도 동작).

### 시나리오 (sh·ps1 동일)

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
# Windows PowerShell (.ps1 보조 사본 검증) — 네이티브 PowerShell/pwsh 호스트에서 띄운다
powershell.exe -File tests\multi-repo\run.ps1   # Windows PowerShell 5.1
pwsh           -File tests\multi-repo\run.ps1   # PowerShell 7
```

각 러너는 모든 시나리오 통과 시 exit 0, 하나라도 실패 시 exit 1을 반환한다.

### 지원 기동 맥락 (`run.ps1`, M38-T05)

`run.ps1`은 **네이티브 PowerShell/pwsh 호스트**에서 띄운다. **Git Bash 호스트에서 띄우면 안 된다** —
그리고 이 규율은 문장으로만 있지 않고 러너가 **시작 시 스스로 확인**한다.

- **왜 갈리나(진단)**: 이 하니스는 가드에 훅 입력을 **stdin으로** 넣고, 가드는 `[Console]::In`으로
  읽는다. 그 디코딩은 `[Console]::InputEncoding` — 즉 **콘솔 입력 코드페이지**를 따르고, 자식
  프로세스는 그것을 **띄운 호스트에서 물려받는다**. 같은 기계에서 실측한 값:
  - **네이티브 PowerShell 호스트** → 자식 콘솔 입력 CP **65001**(UTF-8). 선두 BOM 3바이트가 UTF-8
    디코더에 흡수되고 가드는 깨끗한 `{`를 본다.
  - **Git Bash 호스트** → 자식 콘솔 입력 CP **949**(ANSI 페이지). `EF BB`가 **한 글자**(U+7664),
    `BF`가 U+003F로 디코드돼 선두가 `U+FEFF`도 `U+00EF U+00BB U+00BF`도 아니다 — 가드가 strip하는
    두 형태 중 어느 것도 아니라 `ConvertFrom-Json`이 throw하고, `cwd`가 비어 `CLAUDE_PROJECT_DIR`로
    폴백해 **통과**해 버린다. 그래서 시나리오 9만 뒤집혀 **29/1**이 됐다(네이티브 호스트는 30/0).
  - 원인은 **BOM 자체도 `$OutputEncoding`도 아니고 기동 맥락**(콘솔 입력 코드페이지)이다.
- **처분 (b) 명시 + 집행**: 러너가 첫 단언 전에 **같은 `Start-Process` stdin 경로로 자기 채널을
  탐침**한다(`EF BB BF` + `{}`를 보내 선두가 가드가 아는 형태로 도착하는지). 지원 밖이면 케이스를
  하나도 돌리지 않고 `# UNSUPPORTED LAUNCH CONTEXT …` + 코드페이지 진단을 찍고 **exit 1**한다 —
  조용히 다른 판정을 내지 않는다. 탐침은 **행위 기반**이지 코드페이지 화이트리스트가 아니다
  (`65001`을 하드코딩하면 오늘 정당하게 초록인 CI 레그를 붉게 만든다).
- **(a)를 택하지 않은 이유**: 어느 호스트에서든 같은 판정이 되게 하려면 ⑴ 가드의 BOM strip을
  넓히거나 ⑵ 러너가 **공유 콘솔의 코드페이지를 고쳐 쓰거나** 여야 한다. ⑴은 이 사이클의 불변
  (**훅 무접촉**)이고, ⑵는 사용자 터미널에 대한 부수효과이면서 가드의 실제 취약성을 **가린다**.
  남은 가드 측 견고성 구멍(비-UTF-8 콘솔 페이지가 뭉갠 BOM)은 **고치지 않고 이월로 기록**한다.
- **CI**: `.github/workflows/tests.yml`의 PowerShell 잡은 호스트 셸을 `pwsh`로 두고 **자식
  프로세스만** 매트릭스로 바꾼다 — 그 파일의 주석 4번이 같은 사실을 적고 있고, 이제 러너가
  그것을 기계로 문다.
- **탐침의 CI 거동은 아직 실증되지 않았다(고지)**: GitHub windows 러너의 자식 콘솔 입력 코드페이지가
  UTF-8 계열이 아니면 이 러너는 케이스 0건·exit 1을 내고 `powershell` 잡 **두 레그가 붉어진다** —
  M38 이전에는 초록이던 잡이다. 위험은 낮다고 본다: v2.11.0의 성공 실행에서 `powershell (powershell)`·
  `powershell (pwsh)`가 둘 다 초록이었고 그 안에 **시나리오 9(선두 BOM)** 가 들어 있다. 그 케이스가
  통과했다는 것은 BOM이 **가드가 strip하는 형태로 도착했다**는 뜻이고, 그것이 곧 탐침의 통과
  조건이다. 그래도 **첫 실증은 실제 푸시의 CI**다(`pr` 모드로 릴리즈하면 `release/vX.Y.Z` 브랜치의
  PR CI, 아니면 기본 브랜치 push 이후의 CI). **M40이 그 조회를 `pr` 모드 마무리에 배선했다** —
  태그 전에 PR 체크를 조회해 사용자 확인을 받는다(게이트가 아니다). push-only·`release` 모드는
  PR도 머지 전 CI도 없어 그 경로에서는 여전히 닫히지 않으며, 근거와 잔여의 단일 원본은
  `docs/conventions.md`의 "실행 환경 축" 절이다.

실행 환경 축의 단일 원본은 `docs/conventions.md`의 "실행 환경 축" 절이며 이 절은 그 표의
**기동 맥락** 행이 가리키는 집행처다.

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
