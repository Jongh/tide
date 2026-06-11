# tide 규약 (conventions)

tide는 porpoise의 개발 방법론(마일스톤 → 구현 → 리뷰 → 릴리즈)을 프로젝트
독립적인 슬래시 커맨드로 옮긴 워크플로우다. 이 문서는 각 단계가 따르는 규약을 정의한다.

<!-- 아래 [start:body]~[end:body]는 사이트(site/docs/conventions.md)가 pymdownx.snippets로
     본문만 인클루드하기 위한 마커다. 위 도입 문단은 일부러 마커 밖에 두어 사이트에서는
     사이트 전용(외부 귀속 없는) 도입부로 대체된다. 렌더에는 영향 없음. -->
<!-- --8<-- [start:body] -->
## 사이클

```
/tide:kickoff  →  /tide:milestone  →  /tide:impl  →  /tide:review  →  /tide:release vX.Y.Z
   (세팅)           (계획)             (구현·테스트)    (리뷰·판정)       (배포)

                  └──────────── /tide:cycle ────────────┘  (release 직전 정지)

                          /tide:status — 언제든 현재 위치 확인 (읽기 전용)
```

**수동 단계별 호출 vs `/tide:cycle` 자동 체이닝**: 평소엔 각 단계를 직접 호출하지만,
`/tide:cycle`은 `milestone → impl → review`를 한 번에 이어 실행한다(필요 시 milestone부터,
`M{N}` 인자면 impl부터). `release`만은 자동 체이닝에서 **제외** — git 작업을 하는 유일한
단계이므로 review "가능" 판정 후 사이클을 끝내고 사용자에게 `/tide:release vX.Y.Z`를
넘긴다. cycle은 각 단계의 전제조건을 그대로 검사하고, 한 단계가 미충족·실패로 멈추면
사이클 전체를 중단하며 중단 지점·사유를 보고한다. impl 단계에서는 마일스톤 태스크의
`(deps:)` 표기를 읽어 **독립 태스크를 서브에이전트로 동시 디스패치(실제 병렬)**, 의존
태스크는 순차로 스케줄링한다. 병렬 메커니즘·파일 충돌 안전장치·결과 병합·폴백은
`skills/impl/SKILL.md`의 "병렬 디스패치" 절이 단일 원본이다(`/tide:impl`·`/tide:cycle`
공통).

**핵심 원칙 — 부수효과 분리**: `impl`·`review`는 **절대 git 작업을 하지 않는다**(문서·코드만
남김). git commit/tag/push는 오직 `release`에서만 일어난다. impl/review가 남긴 보고서는
다음 `release` 커밋에 함께 포함된다. 이 원칙은 프롬프트 지시에 더해 **tide-guard hook**으로
기계적으로 강제된다(아래 참조).

## 상태 파일 (.tide/phase)

- 위치: `.tide/phase` — 현재 단계명 한 줄 (`milestone` / `impl` / `review` / `release` / `idle`)
- 각 커맨드는 시작 시 자기 단계명을 기록하고, 최종 보고 직전 `idle`로 되돌린다
  (`/tide:status`는 읽기 전용이라 변경하지 않음)
- `.tide/`는 `.gitignore` 대상이다 (로컬 상태일 뿐 커밋하지 않음)

## tide-guard hook

- PreToolUse(Bash|PowerShell 매처) hook. **플러그인이 직접 제공한다** —
  `hooks/hooks.json`이 `${CLAUDE_PLUGIN_ROOT}/hooks/tide-guard.sh`를 등록하므로
  플러그인 설치만으로 활성화되고, 프로젝트별 설치 절차는 없다.
- 동작: `.tide/phase`가 `release`가 **아닌** 동안 `git commit` / `git tag` / `git push`
  패턴의 셸 명령을 차단한다(exit 2 + 한국어 안내 메시지: "'{phase}' 단계에서는 git
  commit/tag/push가 차단됩니다. git 작업은 /tide:release 단계에서만 허용됩니다.").
- 상태 파일이 없으면 아무것도 차단하지 않는다 — tide를 쓰지 않는 프로젝트나
  사용자의 수동 git 작업(idle 상태가 아니라 파일 자체가 없는 경우)에 영향을 주지 않는다.
- **`idle`에서도 차단된다** — tide 도입 후에는 Claude를 통한 git commit/tag/push가 항상
  `/tide:release`로만 일어나는 것이 의도된 동작이다. tide 사이클 밖에서 Claude에게
  git 작업을 시키려면 `.tide/phase` 파일을 삭제해 가드를 해제한다.
- 스크립트 원본은 `hooks/tide-guard.sh` **한 곳**이다 (`tide-guard.ps1`은 sh를 쓸 수
  없는 환경을 위한 보조 사본 — 로직·메시지 수정 시 함께 갱신). Windows에서는 Git for
  Windows의 sh로 실행된다.
- **인코딩 규약**: 두 사본의 인코딩이 다르다 — `tide-guard.sh`는 **BOM 없는 UTF-8**
  (Git Bash가 shebang을 정상 처리하도록), `tide-guard.ps1`은 **BOM 포함 UTF-8**
  (Windows PowerShell 5.1이 한글 메시지를 ANSI로 오인해 깨뜨리지 않도록). 메시지를
  수정할 때 각 파일의 인코딩을 유지한다.

## 템플릿

- 각 스킬 디렉터리에 동봉된 `template.md`가 마일스톤·보고서 **형식의 단일 원본**이다:
  `skills/milestone/template.md` / `skills/impl/template.md` / `skills/review/template.md`
- milestone/impl/review 스킬은 `${CLAUDE_SKILL_DIR}/template.md`를 읽어 그 구조 그대로
  문서를 생성한다. 템플릿을 읽을 수 없으면 스킬에 내장된 한 줄 폴백(섹션 목록)으로
  동작한다.
- 형식을 바꾸려면 템플릿 파일을 수정한다 — 스킬·규약 문서의 산문을 고치는 것이 아니라.

## 전제조건 · 프리플라이트

| 커맨드 | 시작 전 검사 | 실패 시 |
|---|---|---|
| `/tide:impl` | 대상 마일스톤 문서 존재 | 구현 없이 `/tide:milestone` 안내 후 중단 |
| `/tide:review` | `docs/reports/M{N}-impl.md` 존재 | 리뷰 없이 `/tide:impl` 안내 후 중단 |
| `/tide:release` | ① review 판정 "가능" ② 테스트 통과 ③ 워킹트리 확인 | git 작업 없이 사유 보고 후 중단 |

release 1번 검사는 사용자가 버전 인자와 함께 강행 의사를 명시한 경우에만 경고 후 통과할 수 있다.

## 마일스톤 문서

- 위치: `docs/milestones/M{N}.md` (가장 큰 번호 + 1, 없으면 M1)
- 필수 섹션 7개: **목표 / 배경 / 태스크 목록 / 태스크 상세 / 파일 변경 요약 / 완료 기준 / 메타데이터**
- 태스크 ID: `M{N}-T01`, `M{N}-T02` …
- 태스크는 한 번에 끝낼 수 있는 크기로 분해하고, 가능한 한 서로 독립적으로 설계
  (특히 **변경 파일이 겹치지 않게** — 독립 태스크는 병렬 디스패치되므로 파일 비중첩이
  병렬 안전과 직결된다. 겹치면 그 부분만 순차 폴백)
- 선행 의존이 있으면 태스크 끝에 `(deps: M{N}-T01, …)` 로 표기
- `/tide:impl M{N}` 처럼 번호를 지정해 특정 마일스톤을 재실행·이어하기 할 수 있다

## 보고서

- 완료 보고서: `docs/reports/M{N}-impl.md`
  - 개요 / 태스크별 수행 내용 / 변경 파일 요약 / 테스트 결과 / 미해결·후속 메모
- 리뷰 보고서: `docs/reports/M{N}-review.md`
  - 비판점(심각도: 차단/권장/사소) / 수정 내용 / 검증 / 릴리즈 판정(+추천 버전) / 다음 단계
- 회고 문서: `docs/reports/retro.md` (`/tide:retro` 산출물 — 갱신형 단일)
  - 집계 범위 / 반복된 문제·이슈 군집 / 수용된 트레이드오프 / 후속 항목 추적 /
    릴리즈 판정·버전 추이 / 회고 메모. 마일스톤별이 아니라 **누적 사이클을 가로질러** 본다.
  - 회고 시점마다 문서 최상단에 새 섹션을 누적한다(이력 보존, 읽기 전용 — 회고 문서만 생성).
- 동일 마일스톤 재실행 시 기존 보고서를 갱신한다.

## 프로젝트 컨텍스트 (docs/project-context.md)

- `/tide:kickoff`는 대상 저장소가 신규인지 진행 중인지 판별한다(git 커밋 이력·기존
  산출물·소스 규모 기준).
- **진행 중 프로젝트**로 판별되면 코드베이스를 조사해 `docs/project-context.md`를
  생성한다 — 스택·언어·의존성, 최상위 디렉터리 구조와 역할, 진입점·빌드/테스트 방법,
  핵심 도메인 개념. 불확실한 항목은 "확인 필요"로 표기하고, 구조 파악이 어려우면 최소
  골격만 남긴다.
- **신규(빈) 프로젝트**로 판별되면 이 문서는 생성하지 않고 골격만 세운다.
- `/tide:milestone`·`/tide:impl`은 이 문서가 있으면 먼저 읽어 기존 구조를 파악한 뒤
  작업한다(없으면 평소대로 진행 — 필수 전제조건은 아니다).

## 버전 · CHANGELOG

- 버전 파일은 프로젝트 스택에 맞춤: `Cargo.toml` / `package.json` / `pyproject.toml` 등
- 버전은 SemVer. 리뷰 단계에서 major/minor/patch를 추천한다.
- **`CHANGELOG.md`가 릴리즈 노트의 단일 원본**이다. 릴리즈 노트는 `CHANGELOG.md` 최상단에만
  추가하고, `README.md`의 `## CHANGELOG` 섹션은 `CHANGELOG.md`로 가는 **포인터만** 둔다(노트
  본문을 중복 보관하지 않는다 — 이중 갱신·불일치 방지). 사이트 변경 이력은 이미 `CHANGELOG.md`를
  단일 원본으로 인클루드한다.
- 커밋 메시지: `Release {버전}: {핵심 변경사항 한 줄 요약}`
- **메타 용어 누수 방지**: 사이트에서 제외하기로 한 용어(외부 저장소명 등)는 본문 콘텐츠뿐
  아니라 CHANGELOG·conventions의 **검증을 서술하는 메타 문장**(예: "제외 용어가 누수되지
  않는지 확인한다" 류)에서도 literal로 쓰지 않는다 — 본문이 단일 원본(snippets)으로 사이트
  콘텐츠가 되므로, 메타 문장에 박힌 제외 용어 역시 그대로 사이트에 유입된다. 검증을 서술할
  때는 실제 단어 대신 "제외 용어"·"외부 저장소명" 같은 일반 표현을 쓴다.
- **릴리즈 빌드 출력 검증**: release 프리플라이트에서 사이트를 빌드한 **산출물 기준**으로
  제외 용어 0건을 확인하는 절차를 한 줄 수행한다(소스가 아니라 빌드 출력을 스캔) — 누수
  회귀를 다음 사이클이 아니라 **release 시점에** 잡는다.

## 단계별 금지 행위 요약

| 단계 | 금지 | 강제 수단 |
|---|---|---|
| kickoff | git 작업 | 프롬프트 |
| milestone | 작업지시서 생성 / 코드 구현 / 테스트 실행 / git 작업 | 프롬프트 + hook(git) |
| impl | 코드 리뷰 / git commit / git tag / git push | 프롬프트 + hook(git) |
| review | git commit / git tag / git push | 프롬프트 + hook(git) |
| status | 파일 생성·수정 / git 작업 | 프롬프트 |
| retro | 회고 문서(`docs/reports/retro.md`) 외 파일 생성·수정 / `.tide/phase` 변경 / git 작업 | 프롬프트 |
| cycle | git commit / git tag / git push (release 단계는 체이닝에서 제외) | 프롬프트 + hook(git) |
| release | (없음 — 유일하게 git 조작 허용) | 프리플라이트 통과 필요 |

## 규약 ↔ 실행/인프라 동기화

규약이나 단일 원본(단일 원본화한 문서·인클루드 대상 등)을 **새로 더하거나 바꾸면**, 그것을
강제·반영할 **실행 수단도 같은 사이클에 함께 손본다** — 스킬 프리플라이트, hook, CI 트리거,
빌드 설정 중 해당하는 것. 규약만 적어두고 그것을 집행할 배선을 다음 사이클로 미루지 않는다.

- 근거: 빌드 출력 검증 규약을 정해두고 release 배선이 따라오지 않아 한동안 규약↔실행 간극이
  남았고, 문서를 단일 원본으로 인클루드하기 시작했으나 배포 트리거가 그 루트 파일을 감시하지
  않아 사이트가 낡는 간극이 반복됐다. 둘 다 "규약·원본"과 "그것을 집행하는 실행/인프라"를
  같은 사이클에 묶었다면 생기지 않았을 군집이다.
- 적용 예: 사이트가 인클루드하는 루트 파일을 새로 추가하면 → 그 변경을 빌드·배포로 반영할
  CI 트리거가 그 파일을 누락하지 않는지 같은 사이클에 확인한다. 프리플라이트에 새 검증 규약을
  적으면 → release 스킬 절차에 그 검증 단계를 같은 사이클에 배선한다.

## 1.0 안정성

tide는 **v1.0.0부터 아래를 안정(stable) 계약으로 선언**한다. 안정 계약은 하위 호환을 지키며,
**하위 호환을 깨는 변경은 다음 major에서만** 한다(minor·patch는 가산·정리·견고화에 한한다).

- **커맨드 8종의 호출명·역할**: `/tide:kickoff`·`/tide:milestone`·`/tide:impl`·`/tide:review`·
  `/tide:cycle`·`/tide:release`·`/tide:retro`·`/tide:status`. 호출명과 각 단계의 역할은 안정이다.
- **단계별 규약**: 위 "사이클"·"부수효과 분리"·"전제조건·프리플라이트"·"단계별 금지 행위 요약"이
  정의하는 단계 순서·금지·강제 수단.
- **`.tide/phase`·tide-guard 계약**: 상태 파일 `.tide/phase`의 의미(단계명 한 줄)와 tide-guard
  hook의 차단 규칙(release 단계가 아니면 git commit/tag/push 차단, 상태 파일 부재 시 무차단).
- **보고서·마일스톤 형식**: 마일스톤 문서·완료보고서·리뷰보고서·회고 문서의 섹션 구조(위 해당 절).

호환을 깨지 않는 추가(새 커맨드·새 선택 필드·새 검증 단계 등)와 정리·견고화는 minor·patch로
계속한다 — 안정 선언은 "이제부터 위 계약을 함부로 깨지 않는다"는 약속이지 기능 동결이 아니다.
<!-- --8<-- [end:body] -->
