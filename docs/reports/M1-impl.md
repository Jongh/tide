# M1 완료보고서 (impl)

## 개요

M1 "부수효과 분리의 메커니즘화 + 사이클 상태 인식"의 8개 태스크(M1-T01~T08)를 모두
구현했다. git 금지 원칙을 강제하는 tide-guard hook(sh/ps1), 상태 파일(`.tide/phase`)
규약, `/tide-status` 커맨드, 단계별 전제조건·release 프리플라이트, `/tide-impl`
번호 지정 인자를 추가하고 규약 문서·README를 갱신했다.

## 태스크별 수행 내용

- **M1-T01** — `hooks/tide-guard.sh`·`hooks/tide-guard.ps1` 작성. stdin의 hook JSON에서
  명령을 추출해 `git[^&|;]*` + `commit|tag|push` 패턴을 검사. `.tide/phase`가 없으면
  무조건 통과, `release`면 통과, 그 외 단계면 exit 2 + 안내 메시지로 차단.
  sh는 jq 의존 없이 전체 입력을 보수적으로 스캔, ps1은 ConvertFrom-Json 우선·실패 시 폴백.
- **M1-T02** — `.tide/phase` 규약(`milestone`/`impl`/`review`/`release`/`idle`) 정의.
  milestone·impl·review·release 4개 커맨드에 "시작 시 단계명 기록 → 종료 직전 idle 복귀"
  지시 추가. 이 저장소 `.gitignore`에 `.tide/` 추가.
- **M1-T03** — `/tide-kickoff` 확장: `.claude/hooks/`에 스크립트 2종 생성(내용 내장,
  전역 설치 시에도 자급자족), `.claude/settings.json`에 PreToolUse(`Bash|PowerShell` 매처)
  병합, 플랫폼별 command 1개만 등록, `.gitignore`에 `.tide/` 보강. 기존 파일·설정 보존 원칙 유지.
- **M1-T04** — `.claude/commands/tide-status.md` 신설. 마일스톤/보고서/판정/버전/phase를
  읽고 다음 권장 커맨드를 구체 인자까지 제시. 읽기 전용(phase도 변경하지 않음).
- **M1-T05** — impl에 "마일스톤 문서 없으면 중단 + /tide-milestone 안내", review에
  "M{N}-impl.md 없으면 중단 + /tide-impl 안내" 전제조건 추가.
- **M1-T06** — release에 3단계 프리플라이트 추가: ① review 판정 "가능" 확인(불가/부재 시
  중단, 버전 인자 + 명시적 강행 시에만 경고 후 진행) ② 테스트 통과 ③ 워킹트리 확인.
  통과 후에만 phase=release 기록 → git 작업 진행.
- **M1-T07** — impl에 `argument-hint` 추가, `M{N}` 인자로 특정 마일스톤 재실행·이어하기
  지원(생략 시 최신). 재실행 시 기존 보고서 갱신 명시.
- **M1-T08** — conventions.md에 상태 파일·tide-guard·전제조건/프리플라이트 절 신설,
  금지 행위 표에 "강제 수단" 열 추가. README에 status 커맨드, 가드 설명, 설치 안내 갱신.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `hooks/tide-guard.sh`, `hooks/tide-guard.ps1` |
| 추가 | `.claude/commands/tide-status.md` |
| 추가 | `docs/milestones/M1.md` (milestone 단계 산출물) |
| 수정 | `.claude/commands/tide-kickoff.md`, `tide-milestone.md`, `tide-impl.md`, `tide-review.md`, `tide-release.md` |
| 수정 | `docs/conventions.md`, `README.md`, `.gitignore` |

## 테스트 결과

프로젝트에 테스트 러너가 없어(마크다운 저장소) M1 완료 기준의 hook 시나리오를
임시 디렉터리 + 샘플 hook JSON으로 직접 실행해 검증했다.

- `hooks/tide-guard.sh` (git bash): **8/8 통과** — impl에서 commit/push/tag 차단(exit 2),
  `git status`·`git log`·`npm test` 통과(exit 0), review에서 commit 차단, release에서
  commit 통과, 상태 파일 부재 시 통과, 차단 메시지 출력 확인
- `hooks/tide-guard.ps1` (Windows PowerShell 5.1): **8/8 통과** — 동일 시나리오 전부 기대대로
- kickoff 내장 스크립트 ↔ `hooks/` 원본: **diff 0** (byte 동일)

발견·수정한 이슈: PowerShell 5.1이 BOM 없는 UTF-8 ps1을 ANSI로 읽어 한국어 차단
메시지가 깨짐 → 차단 메시지를 인코딩 안전한 **영문으로 변경**(sh도 일관성 위해 동일
적용). 메시지는 Claude가 읽고 사용자에게 전달하는 용도라 동작에 영향 없음.

완료 기준 3~6(status 동작, 전제조건 중단, 프리플라이트 중단, 번호 지정 실행)은
프롬프트 수준 변경이라 커맨드 파일 내용 검토로 확인했고, 실제 동작은 다음 사이클
사용 중 자연 검증된다.

## 미해결·후속 메모

1. **이 저장소 자체에는 hook 미등록** — tide 저장소의 `.claude/settings.json`에
   tide-guard가 아직 없다. 이 저장소에서 `/tide-kickoff`를 한 번 실행하면 셀프
   도그푸딩이 완성된다 (release 전 권장).
2. **내장본 이중 관리** — kickoff 커맨드에 스크립트가 내장돼 있어 `hooks/` 원본과
   둘을 항상 함께 수정해야 한다. 플러그인 패키징(차기 마일스톤 후보)으로 해소 가능.
3. **차단 메시지 영문 고정** — 한국어 메시지를 원하면 ps1을 BOM 포함 UTF-8로
   저장하는 규약이 추가로 필요하다.
4. hook 패턴은 보수적이라 `echo "git push"` 같은 무해한 명령도 impl/review 중에는
   차단될 수 있다(의도된 트레이드오프 — 해당 단계에서 그런 명령이 필요할 일은 드묾).
