# M1 리뷰보고서 (review)

## 비판점

### 차단 (1건 — 리뷰 중 수정 완료)

1. **Windows에서 가드가 조용히 무력화될 수 있는 hook 등록 방식** —
   kickoff가 등록하는 Windows hook command가 `-File "$CLAUDE_PROJECT_DIR/...ps1"`
   형태였다. Windows에서 hook이 cmd 계열로 실행되면 `$VAR` 문법이 확장되지 않아
   powershell이 스크립트 파일을 찾지 못하고 비정상 종료하는데, PreToolUse hook은
   **exit 2만 차단**으로 취급하고 그 외 오류는 통과시키므로 가드가 작동하지 않는다는
   사실조차 드러나지 않는다. M1의 핵심 가치(기계적 강제)가 주 사용 플랫폼(Windows)에서
   무효가 될 수 있는 결함.

### 권장 (2건 — 1건 수정, 1건 후속)

2. **`idle` 상태에서도 차단된다는 동작이 문서에 불명확** — 가드는 phase가 `release`가
   아니면 전부 차단하므로, tide 도입 후에는 사이클 밖 일상 커밋 요청("이것만 커밋해줘")도
   막힌다. 의도된 철학이지만 사용자가 당황할 수 있는 동작인데 해제 방법이 문서화돼
   있지 않았다.
3. **이 저장소 자체에 hook 미설치** — tide 저장소의 `.claude/settings.json`에
   tide-guard가 등록돼 있지 않아 셀프 도그푸딩이 안 된 상태다. (후속 — release 후
   이 저장소에서 `/tide-kickoff` 1회 실행 권장)

### 사소 (2건 — 수용, 기록만)

4. **보수적 차단의 false positive** — 패턴이 명령 문자열 전체(설명 필드 포함 JSON)를
   스캔하므로 `echo "git push"` 같은 무해한 명령이나 설명에 "git commit"이 든 호출도
   impl/review 중 차단될 수 있다. 의도된 트레이드오프(해당 단계에서 그런 명령은 드묾).
5. **ps1 한국어 주석의 인코딩** — PS 5.1이 BOM 없는 UTF-8을 ANSI로 읽어 주석이
   깨질 수 있으나, 주석 줄 안에서만 깨지고 파싱·동작에는 영향 없음을 실행으로 확인했다.

## 수정 내용

- **이슈 1**: kickoff의 Windows hook command를 상대 경로
  (`-File .claude/hooks/tide-guard.ps1`)로 변경. hook은 프로젝트 루트를 cwd로
  실행되므로 셸 종류(cmd/sh)와 무관하게 동작한다. 변경 사유를 kickoff 본문에 주석으로 명시.
- **이슈 2**: conventions.md tide-guard 절에 "idle에서도 차단됨 + 해제하려면
  `.tide/phase` 삭제" 명시.

## 검증

- 상대 경로 + `CLAUDE_PROJECT_DIR` 환경변수 **부재** 조건에서 ps1 가드 재테스트:
  impl에서 commit 차단(exit 2), release에서 통과(exit 0) — 폴백 경로(`.`)까지 정상
- kickoff 내장 스크립트 ↔ `hooks/` 원본 diff 재확인: byte 동일
- 기존 16개 시나리오(sh 8 + ps1 8)는 스크립트 무변경이므로 impl 단계 결과 유효

잔여 리스크: Claude Code가 Windows에서 hook을 실제로 어떤 셸로 호출하는지는 이
환경에서 직접 재현할 수 없어, 상대 경로 방식이 "양쪽 모두에서 동작"하는 보수적
선택임을 확인하는 선에서 검증했다. 실프로젝트 첫 kickoff 후 의도적으로 impl 중
커밋을 시도해 차단을 확인하는 절차를 권장한다.

## 릴리즈 판정

**가능** — 추천 버전: **v0.2.0 (minor)**

- 마일스톤 완료 기준 7개 중 hook 관련(1·2)은 실행 검증, 커맨드 동작(3~6)은 프롬프트
  검토로 충족, 문서(7)는 갱신 완료
- 차단 이슈 1건은 리뷰 중 수정·재검증 완료
- 신규 커맨드(/tide-status)와 기능 확장(가드/전제조건/프리플라이트/인자) — minor 적합

## 다음 단계

- `/tide-release v0.2.0`
- 릴리즈 후 권장: 이 저장소에서 `/tide-kickoff`를 실행해 tide-guard 셀프 설치(이슈 3),
  실프로젝트에서 차단 동작 1회 실증
