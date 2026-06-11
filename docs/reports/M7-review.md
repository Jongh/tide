# M7 리뷰보고서 (review)

> 이 리뷰는 `/tide:cycle`을 실행하는 흐름의 review 단계로 수행됐다. 대상은 방금 impl을
> 마친 M7(최대 번호 마일스톤 + impl 보고서 존재 → 전제조건 충족).

## 비판점

### 차단 (0건)

없음. 완료 기준 6개 중 코드/빌드로 검증 가능한 1~5는 실증으로 충족했고(특히 1의
`mkdocs build --strict` exit 0), 6(Pages 소스 전환)은 코드로 불가능한 저장소 설정
단계로 impl 보고서·릴리즈 안내에 수동 절차로 명시돼 있다.

### 권장 (1건)

1. **워크플로우에 `actions/configure-pages` 부재 — 의도된 단순화이나 명시 가치** —
   `deploy-pages.yml`은 `upload-pages-artifact`→`deploy-pages` 표준 패턴을 쓰고
   `configure-pages` 단계를 생략했다. 이 조합은 Pages 소스가 "GitHub Actions"로
   설정돼 있으면 정상 동작하며 `site_url`을 `mkdocs.yml`에 하드코딩해 base URL 문제도
   없다. 다만 `site_url` 가정(`https://Jongh.github.io/tide/`)이 틀리면 canonical·검색
   링크가 어긋난다 — impl 후속 메모 #4가 이미 추적하므로 수용. 첫 배포 후 실URL로
   확인하면 충분하다.

### 사소 (3건 — 수용)

2. **사이트 `conventions.md`·`changelog.md`가 원본의 사본** — 내용 분기 시 이중 갱신
   부담. impl 후속 메모 #2가 단일화(빌드 시 인클루드 등)를 차기 후보로 추적 중. 지금은
   사본이 가장 단순하고 사이트가 원본과 독립적으로 톤(porpoise 제거)을 가질 수 있어
   수용.
3. **`mkdocs.yml`에 미사용 확장 포함** — `pymdownx.snippets`·`pymdownx.inlinehilite`는
   현재 페이지에서 쓰이지 않는다. 무해하고 향후 콘텐츠 확장 시 유용하므로 수용.
4. **런타임(배포 후) 동작 미검증** — Mermaid 렌더링·한국어 검색·다크모드·내부 링크는
   `--strict` 정적 빌드로 잡히지 않는 클라이언트 사이드 동작이다. impl 후속 메모 #3이
   배포 후 도그푸딩으로 추적. M5/M6의 "재설치/배포 후 확인" 리듬과 동일해 수용.

## 수정 내용

- 없음 — 리뷰 중 추가 결함을 발견하지 못했다. impl 단계에서 strict 빌드 통과, porpoise
  0건, 원본 무변경, 임시 산출물(`.venv-mkdocs`·`site/_build`) 정리를 이미 끝냈고, 워크플로우
  artifact 경로(`site/_build`)가 `mkdocs.yml`의 `site_dir`과 일치함을 확인했다.

## 검증

- **완료 기준 대조**:
  ① `mkdocs build --strict` → exit 0, 깨진 링크·nav 누락 경고 없음(실증).
  ② 6페이지가 `nav`에 모두 등록되고 상호 링크(홈→하위, concepts↔conventions)가 정합.
  ③ `grep -rin porpoise site/` 0건 + 홈·규약 도입부가 tide 자체 정의로 서술(실증).
  ④ `git diff -- README.md docs/conventions.md CHANGELOG.md` 무변경(실증).
  ⑤ `deploy-pages.yml`이 `push`(main, `site/**`)·`workflow_dispatch`에서 빌드→
     `deploy-pages` 구성, `.gitignore`에 `site/_build/` 포함(실증).
  ⑥ Pages 소스 전환은 impl 후속 메모 #1·릴리즈 안내에 수동 단계로 명시. **1~5 실증, 6은
     문서화로 충족.**
- **부수효과 분리**: 리뷰·구현 통틀어 git commit/tag/push 없음. tide-guard가 review
  phase에서 git을 차단하는 동작과 충돌 없음. `git status`는 의도한 변경만(M `.gitignore`,
  신규 `.github/`·`docs/milestones/M7.md`·`docs/reports/M7-*.md`·`site/`).
- **구조 일관성**: 사이트 소스를 `site/`로 격리해 tide 사이클 기록(`docs/`)과 분리, MkDocs
  기본 출력명 충돌을 `site_dir: _build` 명시로 제거 — 마일스톤이 짚은 핵심 제약을 정확히
  해소.
- **미검증 잔여 리스크**: 배포 후 실사이트 동작(권장 1·사소 4)과 `site_url` 실값. 첫
  배포 + Pages 소스 전환 후 확인하는 것이 불가피하며 위험은 낮다(정적 빌드 통과 +
  표준 Actions 패턴).

## 릴리즈 판정

**가능** — 추천 버전: **v0.8.0 (minor)**

- 차단 0건. 완료 기준 1~5 실증, 6은 코드 외 수동 단계로 문서화 — M5~M6과 동일 기준 통과.
- 권장 1·사소 3은 모두 impl 후속 메모가 추적 중이며 수용 가능.
- minor 근거: 신규 문서 사이트·CI 추가(순수 가산), 플러그인 동작·기존 산출물 무변경,
  0.x 단계. M7 메타 목표 버전과 일치.

## 다음 단계

- **릴리즈**: `/tide:release v0.8.0`
- 릴리즈 직후 **저장소 Settings → Pages → Source를 "GitHub Actions"로 1회 전환**
  (코드로 불가). 이후 `workflow_dispatch` 또는 `site/**` 푸시로 배포 확인.
- 배포 후 도그푸딩: Mermaid 렌더·한국어 검색·다크모드·내부 링크 실확인, `site_url`
  실값 대조 후 필요 시 `mkdocs.yml` 조정(후속 메모 #3·#4).
- 차기 마일스톤 후보(미반영, 후속 메모가 추적): 사이트 `conventions`/`changelog`의
  원본 단일화(빌드 시 인클루드).
