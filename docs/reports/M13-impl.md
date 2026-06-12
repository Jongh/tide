# M13 완료보고서 (impl)

## 개요

M13의 네 태스크를 모두 구현했다 — (T01) tide-guard를 repo-root 인식으로 변경하고, (T02)
"멀티 레포 / 대상 레포" 규약을 conventions의 단일 원본으로 신설했으며, (T03) 스킬 8종에
대상 레포 앵커링·cwd 규율을 반영하고, (T04) 라이브 실증 하니스를 만들어 sh·ps1 양 가드에서
각 10개 시나리오를 **모두 통과**시켰다. 결과적으로 상위 폴더 단일 세션에서 자식 레포별로
tide 사이클이 격리되어 동작하는 토대가 갖춰졌고, 단일 레포 동작은 불변(하위 호환 가산)이다.
T01·T02는 병렬 서브에이전트로, T03·T04는 메인이 순차로 수행했다.

## 태스크별 수행 내용

- **M13-T01** — `hooks/tide-guard.sh`·`hooks/tide-guard.ps1`을 repo-root 인식으로 변경. 훅
  입력 JSON의 `cwd`를 읽어(`.sh`: jq 있으면 `jq -r '.cwd'`, 없으면 sed 폴백 + JSON 이스케이프
  해제 `\\`→`\`·`\/`→`/`; `.ps1`: `ConvertFrom-Json`의 `$parsed.cwd`) `git -C "$cwd" rev-parse
  --show-toplevel`로 레포 루트를 구하고 `<root>/.tide/phase`를 읽는다. cwd를 못 얻거나 git
  레포가 아니면 기존 `${CLAUDE_PROJECT_DIR:-.}` 경로로 폴백, 그래도 phase 없으면 무차단.
  차단 정규식·한국어 메시지·exit 2·release exit 0은 불변. **인코딩 규약 유지**(.sh BOM 없음,
  .ps1 BOM 포함 — `head -c 3`로 확인). 설계 원칙: 단일 레포(세션을 레포 루트에서 구동)에선
  cwd 레포 루트 == CLAUDE_PROJECT_DIR이라 동작 100% 동일이며, 폴백은 "안전 측 실패"(해석
  실패 시에도 차단이 느슨해지지 않음).
- **M13-T02** — `docs/conventions.md`에 `## 멀티 레포 / 대상 레포` 절을 snippet body 영역
  안쪽에 신설(대상 레포 해석·산출물 앵커링·cwd 규율·세 규약의 맞물림·격리 보장, "전부 가산"
  명시). tide-guard hook 절의 phase 읽기 위치 서술을 "명령이 실행되는 레포 루트의 `.tide/phase`를
  읽는다(단일 레포에선 CLAUDE_PROJECT_DIR와 동일), 못 찾으면 폴백, 없으면 무차단"으로 갱신하고
  하위 호환 일반화임을 명기. "1.0 안정성" 절의 phase/guard 계약 줄도 정합되게 보강.
  `docs/project-context.md` 핵심 도메인 개념에 한 줄 반영. 제외 용어(외부 저장소명) 누수 0건.
- **M13-T03** — 스킬 8종(`kickoff`·`milestone`·`impl`·`review`·`release`·`status`·`cycle`·
  `retro`)에 "**대상 레포**" 노트를 추가해 산출물·`.tide/phase`·git·테스트를 대상 레포 루트
  기준/cwd로 수행하도록 하고, 상세는 conventions 단일 원본을 참조하게 했다(산문 중복 회피).
  스킬별 구체 지점: `impl`은 서브에이전트 위임 목록에 "대상 레포 루트"를 추가(병렬에서도 상속),
  `release`는 버전/CHANGELOG/git을 대상 레포 루트에서 수행하고 push 대상을 `origin main` 가정
  대신 레포 실제 remote·기본 브랜치에 맞추도록 절차(5·6번)와 노트를 수정, `status`·`retro`는
  읽기 전용 유지(경로만 대상 레포 기준), `cycle`은 체이닝 전 단계가 같은 대상 레포 루트를
  쓰도록, `kickoff`은 골격을 대상 레포 루트에 생성하도록 명시.
- **M13-T04** — `tests/multi-repo/`에 자기완결형 라이브 실증 러너를 작성하고 **실제 실행**했다.
  `run.sh`(POSIX/Git Bash)·`run.ps1`(Windows PowerShell)·`README.md`(시나리오 표·실행법·세션
  레벨 수동 절차). 러너는 임시 상위 폴더 아래 자식 레포 2개(+하위 디렉터리·비-레포 디렉터리)를
  만들고 수정된 가드를 합성 훅 입력 JSON으로 직접 호출해 exit 코드를 대조한 뒤 정리한다. 활성
  가드 간섭을 피하려고 차단 동사 문자열을 러너 내부 픽스처에만 두었다(호출 명령줄엔 차단 패턴
  없음). **마일스톤의 잠정 파일명(setup.sh/setup.ps1)을 `run.sh`/`run.ps1`로 변경** — 스크립트가
  setup+실증+teardown을 한 번에 하는 러너라 의미를 맞췄다(디렉터리 `tests/multi-repo/`는 동일).

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `tests/multi-repo/run.sh`, `tests/multi-repo/run.ps1`, `tests/multi-repo/README.md` |
| 수정 | `hooks/tide-guard.sh`, `hooks/tide-guard.ps1` (T01); `docs/conventions.md`, `docs/project-context.md` (T02); `skills/{kickoff,milestone,impl,review,release,status,cycle,retro}/SKILL.md` (T03) |
| 삭제 | (없음) |

## 테스트 결과

자동 테스트 러너가 없는 프로젝트라 **라이브 실증 하니스**로 검증했다.

- **`sh tests/multi-repo/run.sh`** → **PASS=10 / FAIL=0 (exit 0)**. jq 미설치 환경이라 sed
  폴백 경로로 실증됨.
- **`& tests\multi-repo\run.ps1`** → **PASS=10 / FAIL=0 (exit 0)**.

검증된 시나리오(양 셸 공통): 비-release 차단(commit·tag), release 통과, **레포별 격리**
(A=release인 같은 시점에 B(impl) 차단), 하위 디렉터리 cwd→레포 루트 해석, 안전 명령 통과,
cwd 부재 시 CLAUDE_PROJECT_DIR 폴백 차단, non-repo+phase 부재 시 무차단, 단일 레포 회귀
(impl 차단/release 통과).

**구현 중 발견·처리한 이슈**
- (해소) **훅 입력의 `cwd` 필드 실존**: M13가 명시한 핵심 불확실성. 라이브 실증에서 cwd가
  실제로 전달·해석됨을 확인(시나리오 1~5·8이 cwd 경로로 통과). 부재 시 폴백(시나리오 6·7)도
  동작. → 불확실성 해소.
- (수정) **run.ps1 인코딩**: 최초 작성 시 BOM 없는 UTF-8이라 PowerShell 5.1이 한글 주석/문자열을
  깨뜨려 파서 오류 발생. 테스트 하니스를 **ASCII/영문 출력으로 재작성**해 BOM 의존을 제거(가드
  본체 .ps1만 BOM+한국어 메시지 유지). 인코딩 규약의 근거를 실증적으로 재확인한 셈.

## 미해결·후속 메모

1. **jq 경로 미실증**: 이 환경에 jq가 없어 `.sh`의 jq 추출 분기는 정적 검토만 했다(sed 폴백은
   실증). jq 설치 환경에서 한 번 더 돌려보면 좋다(동작 동일 기대).
2. **세션 레벨 앵커링은 수동 확인 영역**: 산출물 앵커링·cwd 규율은 스킬 프롬프트 규약이라
   스크립트로 강제되지 않는다. `tests/multi-repo/README.md`의 "세션 레벨 수동 절차"로 상위 폴더
   단일 세션에서 실제 `/tide:milestone→impl→release`를 자식 레포 대상으로 한번 돌려 앵커링·격리를
   눈으로 확인할 것(리뷰/다음 사이클 권장).
3. **파일명 변경 기록**: 마일스톤의 잠정 `setup.sh/setup.ps1`을 `run.sh/run.ps1`로 변경(이유는
   위). 리뷰에서 명칭 적절성 판단 바람.
4. **상위 오케스트레이션은 별도 마일스톤**: 이번은 "토대"만. 여러 레포를 자동 조정하는 에픽
   계층(contract-first·통합 검증·릴리즈 순서)은 M13 메타데이터에 적어둔 후속 과제.
5. **`tests/` 디렉터리 신설**: 플러그인 패키지가 추적 트리를 미러링하므로 `tests/`도 설치 캐시에
   포함된다(런타임 무관·비용 없음, project-context의 "배포 위생" 수용 기조와 일치). 리뷰에서
   수용/제외 판단 바람.
