# M7 완료보고서 (impl)

## 개요

M7의 8개 태스크(T01~T08)를 모두 구현했다. MkDocs Material 기반 문서 사이트의 골격과
GitHub Actions 배포 워크플로우를 만들고(T01), 홈·시작하기·개념·커맨드 레퍼런스·규약·
변경 이력 6개 한국어 페이지를 기존 저장소 문서에서 정제해 작성한 뒤(T02~T07),
내비게이션을 통합하고 `mkdocs build --strict`로 검증했다(T08). 사이트 소스는 tide
사이클 기록(`docs/`)과 격리된 `site/` 폴더에 두어 충돌을 피했고, porpoise 귀속 표현은
사이트 콘텐츠에서 완전히 배제하면서 원본 `README.md`·`docs/conventions.md`는 손대지
않았다.

## 태스크별 수행 내용

- **M7-T01** — `site/mkdocs.yml`(Material 테마, `language: ko`, 라이트/다크 토글, 검색,
  Mermaid superfence, admonition/details 확장), `site/requirements.txt`
  (`mkdocs-material>=9,<10`), `.github/workflows/deploy-pages.yml`을 작성. `docs/` 충돌을
  피하려 `docs_dir: docs`(→ `site/docs/`)·`site_dir: _build`를 **명시**해 MkDocs 기본
  출력 폴더명(`site`)이 프로젝트 폴더명 `site`와 겹치는 혼동을 제거했다. 워크플로우는
  `push`(`main`, `paths: site/**`)·`workflow_dispatch` 트리거에 `pages: write`·
  `id-token: write` 권한, `upload-pages-artifact`→`deploy-pages` 표준 패턴, `concurrency`
  그룹으로 동시 배포 방지. `.gitignore`에 `site/_build/` 추가.
- **M7-T02** — `site/docs/index.md`. tide를 "마일스톤 → 구현 → 리뷰 → 릴리즈 사이클을
  프로젝트 독립적인 Claude Code 슬래시 커맨드로 구현한 워크플로우"로 **porpoise 귀속
  없이** 정의. README의 ASCII 사이클도를 Mermaid flowchart(cycle subgraph 포함)로
  재구성하고 핵심 가치 4개·하위 페이지 링크를 배치.
- **M7-T03** — `site/docs/getting-started.md`. 플러그인/수동 설치(Windows `sh` 주의),
  마이그레이션 노트는 접이식 `???` admonition으로, 5분 워크스루(kickoff→…→release)와
  단축 경로(status/cycle/retro)를 정리.
- **M7-T04** — `site/docs/concepts.md`. 부수효과 분리·`.tide/phase`·tide-guard(상태
  파일 없으면 무간섭·idle에서도 차단)·전제조건/프리플라이트 표·프로젝트 컨텍스트를
  "왜"에 초점 맞춰 산문화.
- **M7-T05** — `site/docs/commands.md`. 8종 한눈에 보기 표(역할·산출물·git 여부) +
  커맨드별 소절(역할·인자·전제조건·산출물·금지). 출처는 README 커맨드 표와 각
  `skills/*/SKILL.md`.
- **M7-T06** — `site/docs/conventions.md`. `docs/conventions.md`의 사이트용 사본. 도입
  문장을 tide 자체 정의로 **리워딩(porpoise 제거)**, 개념 세부는 concepts로 링크해 중복
  축소.
- **M7-T07** — `site/docs/changelog.md`. v0.1.0~v0.7.0 릴리즈 노트를 `CHANGELOG.md`에서
  옮기고 원본 링크 명시.
- **M7-T08** — `mkdocs.yml`의 `nav`를 6페이지로 확정(자리표시자 없음). 가상환경에서
  `mkdocs build --strict`가 깨진 링크/nav 누락 경고 없이 통과함을 확인. `site/` 전체
  porpoise 0건, 원본 무변경 확인.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `site/mkdocs.yml`, `site/requirements.txt`, `site/docs/index.md`, `site/docs/getting-started.md`, `site/docs/concepts.md`, `site/docs/commands.md`, `site/docs/conventions.md`, `site/docs/changelog.md`, `.github/workflows/deploy-pages.yml` |
| 수정 | `.gitignore` (`site/_build/` 추가) |
| 삭제 | (없음) |

원본 `README.md`·`docs/conventions.md`·`CHANGELOG.md`·`skills/**`는 콘텐츠 출처로만
읽고 **수정하지 않았다**.

## 테스트 결과

이 저장소는 자동화 테스트 러너가 없고(해석형 마크다운/셸), M7은 완료 기준 1에서
명시적으로 `mkdocs build --strict`를 검증 수단으로 정했다.

- **빌드 검증**: 전역 Python 설치는 `watchmedo.exe` 파일 잠금(WinError 2)으로 설치
  실패 → 격리된 가상환경(`.venv-mkdocs`)에 `mkdocs-material 9.x`(mkdocs 1.6.1) 설치 후
  `python -m mkdocs build -f site/mkdocs.yml --strict` 실행 → **exit 0, 경고 없이
  통과**(빌드 1.58초). 출력 상단의 배너는 Material 팀의 "MkDocs 2.0" 안내 메시지로
  빌드 경고가 아니다.
- **porpoise 잔재**: `grep -rin porpoise site/ --exclude-dir=_build` → **0건**.
- **원본 무변경**: `git diff --stat -- README.md docs/conventions.md CHANGELOG.md` →
  변경 없음.
- **정리**: 검증용 `.venv-mkdocs/`와 `site/_build/`는 삭제. `git status`는 의도한 변경만
  남김(M `.gitignore`, ?? `.github/`·`docs/milestones/M7.md`·`site/`).

완료 기준 6개 중 1~5는 위로 충족. 6(Settings → Pages 소스 전환)은 코드로 불가한
수동 단계로 아래 후속 메모·릴리즈 안내에 명시한다.

## 미해결·후속 메모

1. **GitHub Pages 소스 전환은 1회 수동 단계** — 첫 배포 전 저장소 **Settings → Pages →
   Build and deployment → Source를 "GitHub Actions"** 로 바꿔야 워크플로우가 실제로
   게시된다. 코드/CI로는 설정 불가. 릴리즈 후 사용자가 수행.
2. **`site/docs/conventions.md`·`changelog.md`가 원본의 사본** — 내용이 분기하면 두
   곳을 갱신해야 한다. 후속 후보: (a) CHANGELOG를 빌드 시 인클루드(`pymdownx.snippets`
   또는 심볼릭/스니펫)해 단일화, (b) 규약 페이지를 원본에서 생성하는 방식. 이번
   범위에서는 단순 사본으로 수용.
3. **배포 후 실제 사이트 동작 미검증** — 로컬 `--strict` 빌드까지만 확인했다. Pages
   게시 후 Mermaid 렌더링·검색·다크모드·내부 링크를 새 환경에서 실확인 필요(M5/M6과
   동일한 "재설치/배포 후 도그푸딩" 리듬).
4. **`site_url`은 `https://Jongh.github.io/tide/`로 가정** — 사용자/조직 페이지 설정에
   따라 실제 URL이 다르면 `mkdocs.yml`의 `site_url`을 조정.
