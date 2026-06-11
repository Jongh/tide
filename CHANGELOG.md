# CHANGELOG (Older Releases)

최신 릴리즈는 [README.md](README.md#changelog) 를 참조하세요.

---

### [v0.3.0]
- **Claude Code 플러그인으로 전환** — `/plugin marketplace add Jongh/tide` → `/plugin install tide@tide` 한 번으로 커맨드 6종 + tide-guard hook이 함께 활성화 (`.claude-plugin/plugin.json`·`marketplace.json` 신설, 커맨드를 `commands/`로 이동)
- tide-guard hook을 플러그인이 직접 제공 — `hooks/hooks.json`이 `${CLAUDE_PLUGIN_ROOT}` 경로로 등록, 프로젝트별 hook 설치 절차 폐지. kickoff 내장 스크립트 제거로 가드 원본이 `hooks/` 한 곳으로 단일화
- 템플릿 파일화 — `templates/`(마일스톤·완료보고서·리뷰보고서)가 형식의 단일 원본. milestone/impl/review 커맨드가 템플릿을 직접 읽어 생성 (부재 시 폴백)
- 버전 파일 목록에 `.claude-plugin/plugin.json` 추가 (release/status/kickoff)
- README에 구버전(≤v0.2.0) 마이그레이션 노트 추가 — 수동 복사 사본의 플러그인 커맨드 섀도잉, 구 hook 설치물 중복 실행 주의

### [v0.2.0]
- `/tide-status` 신설 — 사이클 현재 상태(마일스톤/보고서/판정/버전/phase)와 다음 권장 커맨드 제시 (읽기 전용)
- tide-guard hook 도입 — `.tide/phase`가 `release`가 아닌 동안 git commit/tag/push를 기계적으로 차단 (`hooks/tide-guard.sh`·`.ps1`, `/tide-kickoff`가 대상 프로젝트 `.claude/hooks/`에 설치)
- 상태 파일(`.tide/phase`) 규약 도입 — 각 커맨드가 시작/종료 시 단계 기록, `.gitignore` 처리
- 전제조건 검사 — impl(마일스톤 문서 존재)·review(완료보고서 존재) 미충족 시 안내 후 중단
- release 프리플라이트 — 리뷰 판정 "가능" + 테스트 통과 + 워킹트리 확인 후에만 git 작업 진행
- `/tide-impl M{N}` 번호 지정 인자 — 특정 마일스톤 재실행·이어하기 지원
- 규약 문서에 상태 파일·tide-guard·단계별 강제 수단 명시

### [v0.1.0]
- tide 워크플로우 슬래시 커맨드 5종 신설: `tide-kickoff`·`tide-milestone`·`tide-impl`·`tide-review`·`tide-release`
- impl/review 단계 작업보고서(`docs/reports/M{N}-impl.md`·`M{N}-review.md`) 규약 포함
- 부수효과 분리 원칙(impl/review는 git 금지, release만 git 조작) 명문화
- `docs/conventions.md` 규약 문서 추가
