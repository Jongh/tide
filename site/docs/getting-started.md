# 시작하기

## 설치

tide는 플러그인으로 설치하는 것이 좋습니다. 수동 복사도 가능하지만 이 경우 가드 hook이 빠집니다.

### 플러그인 (권장)

```
/plugin marketplace add Jongh/tide
/plugin install tide@tide
```

플러그인으로 설치하면 커맨드 12종과 tide-guard hook이 함께 활성화됩니다. 가드는 플러그인이
`${CLAUDE_PLUGIN_ROOT}` 경로의 hook으로 직접 제공하므로, 프로젝트별 hook 설치 절차는 따로 없습니다.

!!! note "Windows 참고"
    hook은 `sh`로 실행되므로 Git for Windows가 필요합니다. 이는 Claude Code의 Bash 도구가
    요구하는 것과 동일한 전제입니다.

### 수동 복사 (비권장 — 가드 hook 미포함)

```bash
mkdir -p ~/.claude/skills
cp -r skills/* ~/.claude/skills/
```

이 경로는 권장하지 않습니다. tide-guard hook이 설치되지 않으므로 git 금지가 프롬프트 수준으로만 동작합니다.
또한 호출명이 네임스페이스 없는 `/kickoff`·`/milestone` 형태가 되어 다른 스킬과 충돌할 수 있습니다.

??? info "구버전에서 마이그레이션"
    - ≤v0.2.0 (수동 복사): 프로젝트나 전역 `.claude/commands/`에 복사해 둔 `tide-*.md` 사본은
      **플러그인 커맨드를 가리므로** 삭제하셔야 합니다. 추가로 v0.2.0 방식으로 설치한 `.claude/hooks/`와
      settings.json의 hook 등록도 제거해야 가드가 중복 실행되지 않습니다.
    - v0.3.0 → v0.4.0: 호출명이 `/tide:tide-status`에서 `/tide:status` 형태로 바뀌었습니다.
      `claude plugin marketplace update tide` 후 재설치하시면 새 호출명이 적용됩니다.

## 5분 워크스루

설치가 끝나면 프로젝트에서 아래 순서로 사이클을 한 바퀴 돌리시면 됩니다. 신규 프로젝트와 진행 중인
프로젝트를 모두 지원합니다.

1. `/tide:kickoff`: 워크플로우 골격을 세웁니다. 진행 중인 프로젝트라면 코드베이스를 조사해
   `docs/project-context.md`(스택·구조·진입점)까지 만듭니다.

2. `/tide:milestone`: 다음에 할 일을 `docs/milestones/M{N}.md` 한 장으로 계획합니다(목표·태스크·완료 기준).
   해당 단계에서는 코드를 아직 건드리지 않습니다.

3. `/tide:impl`: 마일스톤대로 구현하고 테스트를 돌린 뒤 완료보고서 `docs/reports/M{N}-impl.md`를 남깁니다.
   이 단계는 git 작업을 하지 않습니다.

4. `/tide:review`: 방금 구현한 내용을 비판적으로 리뷰합니다. 판정 직전에는 자기 결론을 반박하는
   반증 시도(refutation) 패스를 한 번 거칩니다. 그 뒤 릴리즈 판정(가능/불가)과 추천 버전을 담은
   `docs/reports/M{N}-review.md`를 남깁니다. 차단 등급 결함은 리뷰가 고치지 않고 판정 `불가`로 impl에
   되돌립니다(권장·사소만 리뷰 중 수정). 이 단계도 git 작업은 하지 않습니다.

5. `/tide:release vX.Y.Z [pr/release]`: 우선 프리플라이트(판정 "가능" + 테스트 통과 + 워킹트리 확인)를
   검사합니다. 통과하면 버전 범프 → CHANGELOG/README 갱신 → commit → tag → push까지 진행합니다.
   추가로 `gh`(GitHub CLI)가 있으면 GitHub 릴리즈 게시와 릴리즈 PR 생성 중 하나를 옵트인으로 고를 수
   있습니다. 해당 단계는 tide 사이클에서 **git을 만지는 유일한 단계**입니다.

### 단축 경로

위 단계 외에 함께 쓰는 커맨드는 아래와 같습니다.

- `/tide:status`: 언제든 현재 위치(마일스톤·보고서·판정·버전·phase)와 다음 권장 커맨드를 읽기 전용으로
  확인합니다.
- `/tide:cycle`: `milestone → impl → review`를 한 번의 호출로 이어서 실행하고 `release` 직전에 멈춰
  안내합니다. 단계를 일일이 호출하지 않고 사이클을 돌리실 때 사용하시면 됩니다.
- `/tide:retro`: 사이클이 여러 번 쌓인 뒤에 쓰는 커맨드입니다. 누적된 마일스톤·보고서를 가로질러 반복
  문제·수용된 트레이드오프·미반영 후속을 회고 문서로 집계합니다(읽기 전용).
- `/tide:debug`: 빌드 후 테스트에서 에러를 발견했을 때 쓰는 사이클 밖 진입점입니다. 마일스톤 없이
  `/tide:debug "증상"`으로 세션을 열어 발견과 수정을 누적합니다. `/tide:debug done`으로 닫으면
  `docs/reports/debug-{N}.md` 보고서 하나가 남습니다. 해당 판정이 리뷰 판정을 대신하므로 곧바로
  `/tide:release`로 이어집니다. 이 경우에도 git 작업은 하지 않습니다.

각 커맨드의 인자와 산출물은 [커맨드 레퍼런스](commands.md)를 참고하시면 됩니다.
