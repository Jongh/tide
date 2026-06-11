# M8 완료보고서 (impl)

## 개요

M8의 5개 태스크(T01~T05)를 deps 위상 순서({T01·T02·T03} → T04 → T05)로 구현했다. 회고가
장기 미반영으로 추적해 온 저비용 후속 셋을 해소했다: tide-guard 차단 메시지를 한국어로
바꾸고 sh/ps1의 인코딩 규약을 확정했으며(T01), 패키지 위생을 캐시 실증과 함께 재조사해
수용을 재확정해 문서화했고(T02), 사이트의 `conventions`·`changelog`를 `pymdownx.snippets`
인클루드로 저장소 원본 단일화했다(T03·T04). `mkdocs build --strict`가 통과하고 빌드
출력의 외부 귀속(porpoise)은 0건을 유지함을 실증했다(T05).

## 태스크별 수행 내용

- **M8-T01** — `hooks/tide-guard.sh`·`tide-guard.ps1`의 차단 메시지를 한국어로 교체(두
  사본 문구 동일): `"'{phase}' 단계에서는 git commit/tag/push가 차단됩니다. git 작업은
  /tide:release 단계에서만 허용됩니다."`. 로직(정규식·exit 2·phase 판정)은 무변경.
  **인코딩 규약**을 확정·적용: `sh`는 BOM 없는 UTF-8(Git Bash shebang 보호), `ps1`은
  BOM 포함 UTF-8(PowerShell 5.1 한글 보존). Python으로 바이트 단위 저장 후 BOM 유무를
  검증(sh 첫 3바이트 `23 21 2f`, ps1 `ef bb bf`).
- **M8-T02** — 설치 캐시(`~/.claude/plugins/cache/tide/tide/0.7.0/`)를 실측해 런타임
  무관 파일 `docs/`가 실제 배포에 포함됨을 확인. `plugin.json`·`marketplace.json`에 파일
  한정 필드가 없고 `.gitattributes`는 LF 정규화(`*.sh`)뿐이며 export-ignore는 clone 기반
  설치에 무효임을 근거로, M3의 "수용 종결"을 재확정. 결정을 `docs/project-context.md`에
  "배포 위생" 절로 기록(현황·수단 부재·영향·재검토 트리거).
- **M8-T03** — `site/mkdocs.yml`에 `pymdownx.snippets`(`base_path: ["."]`,
  `check_paths: true`) 추가. `docs/conventions.md`의 본문(도입 문단 제외)을 HTML 주석
  섹션 마커 `[start:body]`~`[end:body]`로 감싸 porpoise 도입 문단을 마커 밖에 유지.
  `site/docs/conventions.md`를 사이트 전용·외부 귀속 없는 도입부 + `--8<-- "docs/conventions.md:body"`
  인클루드로 전환. base_path `.`는 빌드 cwd(저장소 루트, CI·로컬 동일)를 기준으로 원본
  `docs/`를 가리킨다.
- **M8-T04** — `CHANGELOG.md`의 릴리즈 노트(v0.8.0~v0.1.0)를 `[start:notes]`~`[end:notes]`
  마커로 감싸 제목·README 안내 줄을 제외. `site/docs/changelog.md`를 도입부 +
  `--8<-- "CHANGELOG.md:notes"` 인클루드로 전환(T03이 도입한 snippets 설정 재사용).
- **M8-T05** — `docs/conventions.md`의 tide-guard 절에 한국어 차단 메시지·인코딩 규약을
  반영. 격리 venv에서 `mkdocs build -f site/mkdocs.yml --strict` 통과 확인. 빌드 출력
  `site/_build`에서 인클루드 정상(conventions 본문·changelog 릴리즈노트 반영, 마커 누수
  없음)과 **porpoise 0건**을 실증. 임시 venv·`_build` 정리.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | (없음 — 신규 파일 없음) |
| 수정 | `hooks/tide-guard.sh`(한국어 문구·no-BOM), `hooks/tide-guard.ps1`(한국어 문구·BOM), `site/mkdocs.yml`(snippets), `site/docs/conventions.md`(인클루드), `site/docs/changelog.md`(인클루드), `docs/conventions.md`(섹션 마커 + 가드 절 한국어·인코딩 규약), `CHANGELOG.md`(섹션 마커), `docs/project-context.md`(배포 위생 절) |
| 삭제 | (없음 — T02는 코드 변경 없이 결정 기록) |

> `docs/reports/retro.md`의 미수정 표기는 직전 `/tide:retro` 산출물이며 M8 구현과 무관.

## 테스트 결과

자동 테스트 러너 없는 프로젝트. M8 완료 기준에 맞춰 행위/빌드 검증 수행, 통과:

- **가드 한국어 차단(T01)** — 편집본 `tide-guard.sh`를 파일 입력으로 직접 실행
  (활성 캐시 가드의 자기 차단을 피하려 트리거 토큰을 분리해 구성): `phase=impl`에서
  git commit 류 입력 → 한국어 메시지 + exit 2, 비-git 입력 → exit 0. 한글 깨짐 없음.
  인코딩은 sh=no-BOM·ps1=BOM을 바이트로 확인.
- **`--strict` 빌드(T03·T04·T05)** — venv(mkdocs 1.6.1)에서 exit 0, 경고·깨진 링크 없음.
- **인클루드 정상** — `site/_build/conventions/index.html`에 원본 본문(단계별 금지 표·
  인코딩 규약) 반영, `changelog/index.html`에 v0.8.0~v0.1.0 반영, 양쪽 모두 snippet
  마커(`--8<--`·`start:*`) 누수 없음.
- **porpoise 재검증** — `grep -rli porpoise site/_build` → 0건. 단일 원본화가 외부 귀속을
  재유입하지 않음을 실증(도입 문단을 마커 밖에 둔 설계가 동작).

## 미해결·후속 메모

1. **ps1 가드 런타임 실검증 미수행** — sh 경로는 실증했으나 `tide-guard.ps1`의 한국어
   출력(PowerShell 5.1, BOM)은 sh 없는 Windows 환경에서의 도그푸딩으로 실증 필요. 활성
   가드가 설치 캐시(구 영문)라 release+재설치 전에는 새 메시지가 실호출에 안 뜸 —
   구조적 제약(M1~M7과 동일), release 후 도그푸딩 항목.
2. **base_path `.`는 빌드 cwd 의존** — 인클루드는 `mkdocs build`를 **저장소 루트에서**
   실행한다는 전제에 의존한다(CI 워크플로우·로컬 검증 모두 루트 실행이라 일치). 다른
   디렉터리에서 빌드하면 원본을 못 찾을 수 있음 — 워크플로우가 이미 루트 실행이라 위험
   낮으나, 리뷰에서 짚을 여지.
3. **README↔CHANGELOG 중복은 여전** — 규약상 동일 노트를 두 곳에 두는 기존 중복은 이번
   범위 밖(사이트↔CHANGELOG 축만 단일화). 차기 후보로 남김.
4. **회고 미반영 최상위 후속(진짜 병렬 실행 수단)은 범위 외** — M8은 사용자 지정 3종만
   처리. 다음 마일스톤 후보로 잔존.
