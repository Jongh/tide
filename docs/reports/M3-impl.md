# M3 완료보고서 (impl)

## 개요

M3 "스킬 구조 전환(네이밍 정리 포함) + 문서-실동작 일치 + 패키지 위생"의 6개 태스크
(M3-T01~T06)를 모두 구현했다. 커맨드 6종을 `skills/{이름}/SKILL.md` 구조로 전환해
호출명이 `/tide:status` 형태가 됐고, 템플릿을 각 스킬에 동봉(`${CLAUDE_SKILL_DIR}`)
했으며, 저장소 전체의 호출 표기를 실동작과 일치시켰다. 패키지 위생은 공식 제외 수단이
없음을 확인하고 수용으로 결정했다. 새 구조는 로컬 재설치 + 새 세션 4종 검증으로 실증했다.

## 태스크별 수행 내용

- **M3-T01** — `commands/tide-{이름}.md` 6종을 `git mv`로 `skills/{이름}/SKILL.md`에
  이동(이력 보존). frontmatter(`description`·`argument-hint`)는 그대로 유지, `[tide]`
  표기도 6종 일관 유지. 빈 `commands/` 디렉터리 제거.
- **M3-T02** — 템플릿 3종을 대응 스킬에 동봉(`skills/{milestone,impl,review}/template.md`)
  하고 SKILL.md의 참조를 `${CLAUDE_PLUGIN_ROOT}/templates/…`에서
  `${CLAUDE_SKILL_DIR}/template.md`로 교체. 치환 실동작을 드라이런으로 확인해 폴백
  경로(중앙 templates/ 유지)는 불필요했다. 빈 `templates/` 디렉터리 제거.
- **M3-T03** — 스킬 본문의 상호 호출 표기 전부 `/tide:{이름}`으로 교체 (kickoff·status의
  다음 단계 안내, impl·review 전제조건 안내, review의 릴리즈/후속 제안, release 예시).
  가드 스크립트 차단 메시지(sh·ps1)도 `/tide:release`로 갱신. 저장소 전체 `/tide-`
  grep으로 누락 검출 — review 템플릿의 다음 단계 안내 2줄을 추가 발견·수정. 잔여
  검출은 이력 문서(docs/·CHANGELOG·README의 과거 릴리즈 노트)와 파일 경로
  (`hooks/tide-guard.sh`)뿐임을 확인.
- **M3-T04** — README: 사이클 다이어그램·커맨드 표·수동 복사 절(skills 경로 기준,
  네임스페이스 없는 충돌 위험 명시)·저장소 구조·명명 규약(접두사 설명 → 네임스페이스
  설명)을 새 호출명으로 통일, 마이그레이션 노트에 v0.3.0→v0.4.0 호출명 변경 추가.
  conventions: 다이어그램·전제조건 표·템플릿 절(스킬 동봉 기준)·상태 파일 절 갱신.
- **M3-T05** — 공식 문서 조사 결과 **파일 제외 수단 미지원 확정**: plugin.json에
  files/ignore 필드 없음(컴포넌트 경로 필드는 등록만 제한, 복사 범위는 전체),
  `.claudepluginignore` 없음. 유일한 우회는 git-subdir source로 플러그인을 하위
  디렉터리에 두는 저장소 재구성뿐 — 마일스톤의 결정 규칙대로 **수용**으로 확정
  (비용 대비 이득 작음, docs/는 어차피 공개 문서·`.tide/`는 gitignore로 제외됨).
- **M3-T06** — 로컬 마켓플레이스로 재설치 후 새 세션(headless) 4종 검증 통과
  (아래 테스트 결과). GitHub 마켓플레이스 복원은 릴리즈 후로 미룸 — 지금 복원하면
  설치본이 v0.3.0(구 호출명)으로 되돌아가 남은 사이클(review·release) 진행과 어긋난다.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 이동 | `commands/tide-*.md` 6종 → `skills/{kickoff,milestone,impl,review,release,status}/SKILL.md` |
| 이동 | `templates/*.md` 3종 → `skills/{milestone,impl,review}/template.md` |
| 수정 | SKILL.md 6종 (호출 표기, 템플릿 참조), `skills/review/template.md` (호출 표기) |
| 수정 | `hooks/tide-guard.sh`·`tide-guard.ps1` (차단 메시지) |
| 수정 | `README.md`, `docs/conventions.md` |
| 삭제 | `commands/`, `templates/` (이동 후 빈 디렉터리) |

## 테스트 결과

테스트 러너가 없는 저장소이므로 로컬 재설치 + 새 세션(headless) 실증으로 검증했다.

1. `/tide:status` → 사이클 상태 정확 보고 (M3 진행 중, phase=impl까지 인지) — 통과
2. `/tide:tide-status` → "Unknown command" (구 호출명 제거 확인) — 통과
3. `/tide:milestone` 드라이런 → `${CLAUDE_SKILL_DIR}`가 절대경로
   `…/skills/milestone/template.md`로 치환되고 첫 줄 읽기 성공 — 통과
4. phase=impl에서 `git commit --dry-run` 시도 → 플러그인 hook이 **새 메시지**
   ("allowed only in /tide:release")로 차단 — 통과

가드 스크립트 로직은 무변경(메시지 문자열만 수정)이라 기존 차단/통과 시나리오는 유효.

## 미해결·후속 메모

1. **GitHub 마켓플레이스 복원은 릴리즈 후 수행** — 현재 user 설정의 마켓플레이스가
   임시 워크트리 경로를 가리킨다. v0.4.0 push 후
   `claude plugin marketplace remove tide` → `add Jongh/tide` → `install tide@tide`로
   복원해야 한다 (마일스톤 T06의 "검증 후 복원"을 시점만 조정 — 사유는 T06 항목 참조).
2. **패키지 위생은 수용으로 종결** — 공식 제외 수단이 생기면 재검토. 추적 근거는
   이 보고서와 M3 리뷰보고서에 남긴다.
3. v0.3.0 설치 사용자는 업데이트 후 호출명이 바뀌므로 README 마이그레이션 노트로
   안내된다 — 릴리즈 노트에도 동일 항목 필요 (release 단계에서 작성).
