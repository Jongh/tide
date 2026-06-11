# M2 완료보고서 (impl)

## 개요

M2 "플러그인 패키징 + 템플릿 파일화"의 8개 태스크(M2-T01~T08)를 모두 구현했다.
tide를 Claude Code 플러그인 구조로 재편해 커맨드 6종과 tide-guard hook이 설치
한 번으로 함께 활성화되게 했고, kickoff 내장 스크립트를 제거해 가드 원본을
`hooks/` 한 곳으로 통합했으며, 마일스톤·보고서 형식을 `templates/` 실물 파일로
옮겼다. 이 저장소 자체도 플러그인 설치 방식으로 도그푸딩 전환을 완료했다.

## 태스크별 수행 내용

- **M2-T01** — `.claude-plugin/plugin.json` 생성(name/version 0.2.0/repository 등),
  `.claude/commands/tide-*.md` 6종을 `git mv`로 `commands/`에 이동(이력 보존).
  구현 전 공식 문서를 조사해 스키마·디렉터리 규칙을 확정하고 진행.
- **M2-T02** — `hooks/hooks.json` 작성. 조사 결과 OS별 hook 분기는 공식 지원이 없고,
  Windows는 Git for Windows가 있으면 bash로 hook을 실행하므로(Claude Code의 Bash
  도구와 동일 전제) **단일 `sh "${CLAUDE_PLUGIN_ROOT}/hooks/tide-guard.sh"` 엔트리**로
  결정. M2가 대안으로 둔 "상호 OS 가드"는 불필요해져 미적용. ps1은 sh를 쓸 수 없는
  환경용 보조 사본으로 유지.
- **M2-T03** — kickoff에서 내장 스크립트 2종·`.claude/hooks/` 생성·settings.json 병합
  절차를 전부 제거. "플러그인이 hook을 제공하므로 별도 설치 절차를 만들지 마"를
  명시해 모델이 옛 동작을 재현하는 것도 차단.
- **M2-T04** — `templates/milestone.md`·`impl-report.md`·`review-report.md` 작성.
  M1 실문서 구조를 추출하고 {} 빈 칸 + 작성 안내문 형식으로 구성.
- **M2-T05** — milestone/impl/review 커맨드의 형식 산문을 "${CLAUDE_PLUGIN_ROOT}/templates/
  템플릿을 읽어 그 구조 그대로 작성"으로 교체. 조사로 커맨드 본문에서도
  `${CLAUDE_PLUGIN_ROOT}`가 치환됨을 확인(별도 복사 방식 불필요). 템플릿 부재 시
  섹션 목록 한 줄 폴백 유지. release 커맨드의 버전 파일 목록에 plugin.json 추가
  (플러그인화로 이 저장소에 버전 파일이 생겼으므로).
- **M2-T06** — `.claude-plugin/marketplace.json` 작성(plugins[0].source = "./").
  `claude plugin validate .` 통과.
- **M2-T07** — `claude plugin marketplace add ./` + `claude plugin install tide@tide
  --scope project`로 로컬 설치. 구 설치물(`.claude/hooks/`, settings.json의 hook 등록)을
  제거해 플러그인 hook만 남도록 격리한 뒤 **헤드리스 새 세션 3건으로 실증**(아래
  테스트 결과). settings.json에는 `enabledPlugins`만 남음.
- **M2-T08** — README 설치 절을 플러그인 우선으로 개편(수동 복사는 "가드 미포함
  비권장"으로 격하), 저장소 구조 절 신설, Windows의 Git for Windows 전제 명시.
  conventions의 hook 절을 "플러그인 제공"으로 갱신하고 템플릿 절(단일 원본 원칙) 신설.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `hooks/hooks.json` |
| 추가 | `templates/milestone.md`, `templates/impl-report.md`, `templates/review-report.md` |
| 이동 | `.claude/commands/tide-*.md` 6종 → `commands/` (git mv) |
| 수정 | `commands/tide-kickoff.md` (hook 설치 절차 제거), `tide-milestone.md`·`tide-impl.md`·`tide-review.md` (템플릿 참조), `tide-release.md` (버전 파일에 plugin.json) |
| 수정 | `README.md`, `docs/conventions.md` |
| 수정 | `.claude/settings.json` (hook 등록 제거 → enabledPlugins만), `.claude/hooks/` 삭제 |

## 테스트 결과

- JSON 3종(`plugin.json`/`marketplace.json`/`hooks.json`) 파싱 검증: 통과
- `claude plugin validate .`: 통과
- 플러그인 설치: `marketplace add ./` → `install tide@tide --scope project` 성공
  (`claude plugin list`에서 enabled 확인)
- **헤드리스 새 세션 실증 3건** (구 설치물 제거 후 = 플러그인 hook만 활성):
  1. phase=impl에서 `git commit --dry-run` 시도 → 플러그인 hook
     (`sh "${CLAUDE_PLUGIN_ROOT}/hooks/tide-guard.sh"`)이 차단, 명령 미실행 확인
  2. `git status --short` → 차단 없이 정상 실행 (false positive 없음)
  3. 슬래시 커맨드 노출 → `/tide-*` 6종 전부 플러그인 경유로 확인
- 가드 스크립트 자체는 M1에서 16개 시나리오 검증 후 무변경

발견 사항: `claude plugin marketplace add .`은 거부됨(`./` 형식 필요) — README의
사용자 안내는 GitHub 형식(`Jongh/tide`)이라 영향 없음.

## 미해결·후속 메모

1. **마켓플레이스 경로가 워크트리를 가리킴** — 도그푸딩 설치 시 user 설정에 등록된
   마켓플레이스 source가 이 임시 워크트리 절대경로다. 릴리즈·머지 후
   `claude plugin marketplace remove tide` → `claude plugin marketplace add Jongh/tide`
   (또는 본 저장소 로컬 경로)로 재등록 필요.
2. **sh 없는 Windows 환경** — Git for Windows가 없는 환경에서는 플러그인 hook이
   조용히 실패한다(보조 ps1은 등록 경로가 없음). Claude Code 자체가 같은 전제를
   가지므로 실질 위험은 낮지만, README에 전제로 명시해 둠.
3. **구 수동 설치 사용자** — v0.2.0 방식(.claude/hooks + settings.json)으로 설치한
   프로젝트는 플러그인 전환 시 hook이 중복 실행된다(동작은 차단으로 동일, 메시지 2회).
   구 설치물 제거 안내가 필요하면 차기에 마이그레이션 노트 추가.
