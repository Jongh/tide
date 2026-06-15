# M22 완료보고서 (impl)

## 개요

M22(사이트 단일 원본화)를 구현했다. 공개 사이트의 커맨드 카탈로그를 새 캐노니컬 문서
`docs/commands.md` 한 곳으로 끌어오고 `site/docs/commands.md`를 `pymdownx.snippets` 스니펫
셸로 전환해(기존 conventions·orchestration·changelog와 동형), 회고가 M11~M20 내내 지목한
"수기 사이트 페이지 표류" 군집의 잔존 뿌리를 닫았다. 같은 사이클에 드리프트 가드
(`tests/discover`)를 *개수→이름 완전성 + 셸 검증*까지 확장해(2.0 메타 규칙 — 새 단일 원본은
강제 수단도 같은 사이클에) 단일 원본화를 기계적으로 동결했다. 4개 태스크 전부 완료, 양 셸
하니스 그린.

## 태스크별 수행 내용

- **M22-T01** — 캐노니컬 `docs/commands.md`를 신설하고(레퍼런스 H1·도입은 마커 밖, 카탈로그
  본문은 `<!-- --8<-- [start:body] -->`~`[end:body]` 마커 안), 현재 `site/docs/commands.md`의
  카탈로그 본문("한눈에 보기" 표 + 11개 `## /tide:…` 절 + 멀티 레포 도입 문단 + `11종`을 언급하는
  도입 단락)을 **바이트 보존**으로 옮겼다. `site/docs/commands.md`는 `site/docs/conventions.md`와
  동일 패턴의 셸로 축소 — 사이트 전용 제목 + 도입(카운트·카탈로그 미포함) + GitHub 원본 귀속
  블록쿼트 + `--8<-- "docs/commands.md:body"`. 렌더 출력은 카탈로그 위치만 이동했을 뿐 동일.
  서브에이전트가 `diff`로 카탈로그·도입 단락의 바이트 동일을 확인.
- **M22-T02** — 잔여 수기 사이트 페이지(`getting-started`·`concepts`·`index`)를 감사한 결과
  **세 파일 모두 이미 단일 원본 경계를 지키고 있어 변경 불필요**. getting-started의 5분 워크스루·
  단축 경로는 카탈로그가 아닌 순차 튜토리얼 산문이고 이미 말미에서 `commands.md`로 교차 링크함
  (line 70). concepts는 설계 "왜" 산문(전제조건 표는 프리플라이트 *개념* 예시이지 역할 카탈로그
  아님). index는 가치 블러브 + 단어형 플로우 다이어그램으로 역할 카탈로그 미보유, 이미 `commands.md`
  교차 링크 보유. 카탈로그 필드(역할/인자/산출물/금지)는 세 파일에서 교차 링크 문장에만 등장함을
  grep으로 확인.
- **M22-T03** — 드리프트 가드(`tests/discover/run.sh`·`run.ps1`)를 확장했다(deps T01). 카운트
  대상을 셸이 된 `site/docs/commands.md` → 캐노니컬 `docs/commands.md`로 교체하고, 검사 3종으로
  구조화: **B1** 카운트 선언 정합(`docs/commands.md`·README·conventions·getting-started가 `N종`
  선언, `N+1종` 부재), **B2** 사이트 카탈로그 페이지가 스니펫 셸인지(인클루드 `8<-- "docs/commands.md:body"`
  보유 AND `N종`·카탈로그 표 구분행 `|---|---|---|---|` 미재선언 — 재수기화 시 FAIL), **B3** 카탈로그
  완전성(각 `skills/*/SKILL.md` 이름이 카탈로그에 `/tide:<name>`으로 등장 + 가짜 `/tide:bogus` 부재로
  이름 검사 구별력 입증). ps1은 ASCII 소스 규율 유지 — 셸/표 패턴은 모두 ASCII이고 한글 카운트
  토큰은 기존대로 `$JONG=[char]0xC885`로만 구성(UTF-8 명시 읽기 헬퍼 `ReadUtf8`로 통일).
- **M22-T04** — 단일 원본 도달 범위를 문서에 동기화(deps T01·T03). `docs/conventions.md`
  "규약 ↔ 실행/인프라 동기화" 절에 M22 적용 예(카탈로그 단일 원본화 + 같은 사이클 가드 확장 B1/B2/B3)를
  추가. `docs/project-context.md` 디렉터리 구조 표에 `docs/commands.md`(캐노니컬 카탈로그) 행 추가 +
  `site/` 행을 "conventions·orchestration·changelog·commands 4종은 스니펫 셸"로 갱신. 버전 숫자
  미복제 기조 유지.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `docs/commands.md` (캐노니컬 커맨드 카탈로그, `[start:body]`/`[end:body]` 마커) |
| 수정 | `site/docs/commands.md`(스니펫 셸 전환), `tests/discover/run.sh`·`tests/discover/run.ps1`(가드 B1/B2/B3 확장), `docs/conventions.md`(동기화 절 적용 예), `docs/project-context.md`(구조 표·site 행) |
| 삭제 | 없음 |
| 변경 없음(감사 후) | `site/docs/getting-started.md`·`concepts.md`·`index.md` (T02 — 이미 경계 준수) |

## 테스트 결과

이 프로젝트는 자동 러너가 없고 `tests/`의 자기완결형 라이브 하니스로 검증한다(양 셸 `run.sh`·`run.ps1`).

- **`tests/discover/run.sh`**: **PASS=19 FAIL=0** (exit 0).
- **`tests/discover/run.ps1`**: **PASS=19 FAIL=0** (exit 0). Part A(감지 임계값) 7 + Part B(B1 카운트
  5·B2 셸 1·B3 완전성+이름통제 2·B1 드리프트통제 4) = 12, 합 19.
- **회귀(불변 확인)**: `tests/fleet`·`tests/fleet-cycle`·`tests/fleet-verify`·`tests/multi-repo`의
  `run.sh` 모두 PASS(신규 하니스 영향 없음).
- **인코딩 규율**: `run.ps1` 비ASCII 바이트 **0**(코드포인트 한글만), `run.ps1`·`run.sh`·`docs/commands.md`·
  `site/docs/commands.md` 모두 **BOM 없음**(선두 바이트 `23`=`#`).
- **렌더 불변**: T01 서브에이전트가 카탈로그·도입 단락의 바이트 동일을 `diff`로 확인 — 렌더된 사이트
  커맨드 페이지 내용은 변경 전과 동일(카탈로그 위치만 이동).

## 미해결·후속 메모

1. **mkdocs 빌드/`check_paths` 미실행(환경)** — 로컬에 mkdocs 부재로 실제 스니펫 인클루드 렌더는
   빌드하지 못했다. 가드 B2가 인클루드 라인 존재를 정적 검증하고, 스니펫 경로·마커 패턴은 작동 중인
   `conventions`/`orchestration`/`changelog`와 동형이라 동작 동일을 기대한다. 배포 빌드(CI/라이브)에서
   확인(과거 마일스톤의 빌드 출력 검증 패턴과 동일).
2. **B2 셸 검증의 음성측 미픽스처화** — "셸이 카운트/표를 재선언하면 FAIL"의 양성 경로만 확인했고,
   재수기화 픽스처로 실제 FAIL을 재현하진 않았다(M21 가드 정밀 수준과 동일한 수용 한계). 리뷰가
   필요하다 보면 픽스처 추가 가능.
3. **범위 밖(이번 사이클 비포함, 후속 후보)**: ② 참조 구현 이중성 — `tests/{discover,fleet,fleet-cycle,
   fleet-verify}`의 `discover`/`is_tide_repo`/topo 로직 공유 라이브러리 추출(테스트 인프라 리팩터),
   ③ `retro.md` 자기 입력비용 — 구 섹션 아카이브(`/tide:retro` 입력 동작과 결합되어 별도 검토). 둘 다
   M22 범위에서 의도적으로 제외.
