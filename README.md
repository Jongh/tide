# tide

porpoise의 개발 방법론(마일스톤 → 구현 → 리뷰 → 릴리즈)을 **프로젝트 독립적인 Claude Code
슬래시 커맨드**로 옮긴 워크플로우 모음입니다. 어떤 저장소에든 얹어 동일한 개발 리듬과
문서화 규율을 그대로 적용할 수 있습니다.

## 사이클

```
/tide:kickoff  →  /tide:milestone  →  /tide:impl  →  /tide:review  →  /tide:release vX.Y.Z
   (세팅)           (계획)             (구현·테스트)    (리뷰·판정)       (배포)

              └──────────── /tide:cycle ────────────┘  (release 직전 정지)

              /tide:status — 언제든 현재 위치와 다음 커맨드 확인 (읽기 전용)
              /tide:fleet        — 상위 폴더의 여러 자식 레포 교차 개요 (읽기 전용, 멀티 레포)
              /tide:fleet-cycle  — 그 순서대로 milestone→review 자동 실행 (멀티 레포, release 제외)
              /tide:fleet-verify — 통합 훅으로 레포 간 통합 검증 (멀티 레포, verification-only)
```

> **멀티 레포(MSA) 운용**: 상위 폴더 단일 세션에서 여러 자식 레포를 가로질러
> 운용하는 실전 사용법은 **[docs/orchestration.md](docs/orchestration.md)**
> (오케스트레이션 사용 가이드)를 참고하세요. 단일 세션이 멀티 레포 맥락(직속 자식 tide 레포
> 2개 이상)이면 `/tide:status`·`/tide:kickoff`가 `/tide:fleet`을 한 줄로 안내합니다(읽기 전용 advisory).

`/tide:cycle`은 `milestone → impl → review`를 한 번에 이어 실행하고(impl 단계에서
마일스톤 태스크의 `(deps:)`를 읽어 독립 태스크는 **서브에이전트로 동시 실행**·의존
태스크는 순차로 진행 — 변경 파일이 겹치면 그 부분만 순차 폴백), git 작업을 하는
`release`만은 자동 체이닝에서 빼고 직전에 멈춰 안내합니다.

각 단계는 **부수효과를 엄격히 분리**합니다 — `impl`·`review`는 절대 git 작업을 하지 않고
(코드·보고서만 남김), git commit/tag/push는 오직 `release`에서만 일어납니다.

이 원칙은 프롬프트 지시에 더해 **tide-guard hook**으로 기계적으로 강제됩니다:
플러그인이 직접 제공하는 PreToolUse hook이 `.tide/phase` 상태 파일을 보고,
`release` 단계가 아닌 동안 git commit/tag/push 명령을 차단합니다. 또한 각 단계는
시작 전 **전제조건 검사**(impl: 마일스톤 존재, review: 완료보고서 존재)를 하고,
`release`는 **프리플라이트**(리뷰 판정 "가능" + 테스트 통과 + 워킹트리 확인)를
통과해야 git 작업을 시작합니다.

## 커맨드

| 커맨드 | 역할 | 산출물 |
|---|---|---|
| `/tide:kickoff` | 워크플로우 골격 생성 (+ 진행 중 프로젝트면 구조 문서화) | `docs/milestones/`·`docs/reports/`·`CHANGELOG.md`·`docs/conventions.md`·`docs/project-context.md` |
| `/tide:milestone` | 다음 마일스톤 문서 생성 | `docs/milestones/M{N}.md` |
| `/tide:impl [M번호]` | 마일스톤대로 구현 + 테스트 (생략 시 최신, 번호 지정 시 재실행) | 코드 + `docs/reports/M{N}-impl.md` (완료보고서) |
| `/tide:review` | 비판적 리뷰 + 릴리즈 판정 | `docs/reports/M{N}-review.md` (리뷰보고서) |
| `/tide:cycle [주제/M번호]` | `milestone→impl→review` 자동 체이닝 (deps 기반 실제 병렬[서브에이전트]/순차, release 직전 정지) | 위 단계들의 산출물 + 릴리즈 안내 |
| `/tide:release` | 프리플라이트 → 버전 범프 → CHANGELOG → commit → tag → push | 릴리즈 커밋·태그 |
| `/tide:retro` | 누적 사이클 회고 — 반복 문제·수용 트레이드오프·미반영 후속 집계 (읽기 전용) | `docs/reports/retro.md` (회고 문서) |
| `/tide:status` | 사이클 현재 상태 + 다음 권장 커맨드 (읽기 전용) | (없음 — 보고만) |
| `/tide:fleet [부모 경로]` | 상위 폴더의 여러 자식 tide 레포 교차 개요 + 조정 계획 (읽기 전용, 멀티 레포) | (없음 — 보고만) |
| `/tide:fleet-cycle [부모 경로]` | 발견된 자식 레포의 `milestone→review`를 의존성 순서로 교차 자동 실행 + 순서 release 핸드오프 (멀티 레포, release 제외) | 각 레포 산출물 + 순서 핸드오프 |
| `/tide:fleet-verify [부모 경로]` | 부모 레벨 통합 훅(`.tide-fleet/integration`)으로 레포 간 통합 검증 + pass/fail 보고 (멀티 레포, verification-only) | (없음 — 보고만) |

## 설치

### 플러그인 (권장)

```
/plugin marketplace add Jongh/tide
/plugin install tide@tide
```

커맨드 11종과 tide-guard hook이 **함께** 활성화됩니다. 프로젝트별 hook 설치 절차는
없습니다 — 가드는 플러그인이 `${CLAUDE_PLUGIN_ROOT}` 경로의 hook으로 직접 제공합니다.

> Windows 참고: hook은 `sh`로 실행되므로 Git for Windows가 필요합니다
> (Claude Code의 Bash 도구가 요구하는 것과 동일한 전제).

### 수동 복사 (비권장 — 가드 hook 미포함)

```bash
mkdir -p ~/.claude/skills
cp -r skills/* ~/.claude/skills/
```

이 경로는 tide-guard hook이 설치되지 않아 git 금지가 프롬프트 수준으로만 동작하며,
호출명도 네임스페이스 없는 `/kickoff`·`/milestone` 형태가 되어 다른 스킬과 충돌할 수
있습니다.

> **구버전에서 마이그레이션**:
> - **≤v0.2.0 (수동 복사)**: 프로젝트나 전역 `.claude/commands/`에 복사해 둔
>   `tide-*.md` 사본은 **플러그인 커맨드를 가리므로** 삭제하세요. v0.2.0 방식으로
>   설치한 `.claude/hooks/`와 settings.json의 hook 등록도 제거해야 가드가 중복
>   실행되지 않습니다.
> - **v0.3.0 → v0.4.0**: 호출명이 `/tide:tide-status`에서 `/tide:status` 형태로
>   바뀌었습니다. `claude plugin marketplace update tide` 후 재설치하면 새 호출명이
>   적용됩니다.

설치 후 프로젝트에서 `/tide:kickoff`로 시작하세요 (신규·진행 중 프로젝트 모두 지원).

## 저장소 구조

```
.claude-plugin/   plugin.json·marketplace.json (플러그인/마켓플레이스 매니페스트)
skills/           스킬 11종 — {단계}/SKILL.md (+ milestone·impl·review·retro는 template.md 동봉)
hooks/            hooks.json + tide-guard.sh·.ps1 (git 작업 가드)
docs/             규약·마일스톤·보고서·프로젝트 컨텍스트 (이 저장소 자체의 tide 사이클 기록)
```

## 명명 규약

- 호출: `/tide:{단계}` — 플러그인 네임스페이스가 내장 스킬·다른 플러그인과의 충돌을 방지
- `/tide:` 까지 입력하면 탭 자동완성으로 커맨드 11종이 함께 표시됩니다

## 규약

마일스톤 문서 형식, 보고서 형식, 단계별 금지 행위, 버전·CHANGELOG 규칙은
[docs/conventions.md](docs/conventions.md)를 참고하세요.

## 2.0 안정성

tide는 **v2.0.0부터 다음을 안정(stable) 계약으로 재기준(re-baseline)**합니다. v2.0은
동작을 깨는 major가 아니라 — 오케스트레이션 에픽(로드맵 1~4층) 완성 surface를 **stable로
동결 선언**하는 **계약 재기준**입니다(v1.0.0이 "안정 선언" major였던 것과 동형). 단일 레포·
미선언·기존 동작은 전부 불변입니다.

- **커맨드 11종의 호출명·역할**: `/tide:kickoff`·`/tide:milestone`·`/tide:impl`·`/tide:review`·`/tide:cycle`·`/tide:release`·`/tide:retro`·`/tide:status`·`/tide:fleet`·`/tide:fleet-cycle`·`/tide:fleet-verify` (위 커맨드 표 참조).
- **오케스트레이션 규약**: 부수효과 분리 불변(fleet은 advisory·fleet-cycle은 release 제외·fleet-verify는 verification-only), 의존성 선언·계약 비교(`.tide/deps`)·통합 훅(`.tide-fleet/integration`) 포맷 — `docs/conventions.md`가 단일 원본.
- **단계별 규약**: 사이클 순서, 부수효과 분리(impl·review는 git 작업 금지·release만 git 조작), 전제조건·프리플라이트 — `docs/conventions.md`가 단일 원본.
- **`.tide/phase`·tide-guard 계약**: 상태 파일 `.tide/phase`의 의미(단계명 한 줄)와 tide-guard hook의 차단 규칙(release 단계가 아니면 git commit/tag/push 차단, 상태 파일 부재 시 무차단) — 1.0 그대로 유지(불변).
- **보고서·마일스톤 형식**: 마일스톤 문서·완료보고서·리뷰보고서·회고 문서의 섹션 구조 — 1.0 그대로 유지(불변).

이 계약들은 하위 호환을 지킵니다 — **하위 호환을 깨는 변경(호출명 제거·역할 변경·계약 의미 변경 등)은 다음 major(v3.0.0)에서만** 합니다. minor·patch는 가산·정리·견고화만 합니다.

> **v1.x 가산 이력(보존)** — 위 11종 중 멀티 레포 커맨드는 v1.x에서 하위 호환 가산으로
> 더해진 뒤 2.0에서 stable로 동결됐습니다: 읽기 전용 개요 `/tide:fleet`은 **v1.2.0부터**,
> 교차 사이클 자동화 `/tide:fleet-cycle`은 **v1.5.0부터**, 통합 검증 `/tide:fleet-verify`는
> **v1.6.0부터** 가산됐습니다. 상세는 [docs/conventions.md](docs/conventions.md)의
> "멀티 레포 오케스트레이션" 절, 실전 사용법은 [docs/orchestration.md](docs/orchestration.md).

> **gitignore 마이그레이션(기존 프로젝트)**: `.tide/deps`(의존성 선언)를 채택하는 기존
> 프로젝트는 `.gitignore`를 `.tide/`에서 **`.tide/phase`로 좁히세요** — phase는 로컬 상태라
> 무시하되 deps는 커밋해야 하기 때문입니다(신규 `/tide:kickoff` 프로젝트는 이미 적용됨).

## CHANGELOG

릴리즈 노트의 단일 원본은 [CHANGELOG.md](CHANGELOG.md)입니다 — 버전별 변경 이력은 그쪽을 참조하세요.
