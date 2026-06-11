# M8 리뷰보고서 (review)

> `/tide:cycle`의 review 단계로 수행. 대상은 방금 impl을 마친 M8(최대 번호 마일스톤 +
> impl 보고서 존재 → 전제조건 충족).

## 비판점

### 차단 (0건)

없음. 완료 기준 6개 중 1·3·4·5·6은 실증으로 충족(가드 한국어 차단 + 인코딩 바이트
확인, `--strict` 통과, 인클루드 정상, 빌드 출력 porpoise 0건, conventions 반영), 2는
캐시 실측 + 매니페스트/`.gitattributes` 근거로 결정·문서화. ps1 런타임만 release 후
실증으로 남으며 이는 전 사이클 공통의 구조적 제약이다.

### 권장 (1건)

1. **snippets `base_path: ["."]`의 빌드 cwd 의존 — fail-fast로 완화됨, 확인 권장** —
   인클루드는 `mkdocs build`를 저장소 루트에서 실행한다는 전제에 의존한다. 검증 결과
   배포 워크플로우의 `- run: mkdocs build -f site/mkdocs.yml`은 `working-directory`
   override가 없어 기본값 `GITHUB_WORKSPACE`(=루트)에서 실행되고, 로컬 검증도 루트에서
   했으므로 **CI·로컬 모두 전제와 일치**한다. 게다가 `check_paths: true`를 켜 두어 경로를
   못 찾으면 빌드가 조용히 비는 대신 **즉시 실패**한다(fail-fast). 따라서 실질 위험은
   낮으나, 누군가 `site/`에서 빌드하면 `site/docs/conventions.md` 자기참조 등으로 깨질 수
   있으니 "루트에서 빌드" 전제를 워크플로우 주석이나 conventions에 한 줄 남기는 것이
   안전하다(후속 후보).

### 사소 (3건 — 수용)

2. **ps1 가드 한국어 출력 런타임 미검증** (impl 후속 #1) — sh 경로는 실증(한국어 +
   exit 2 + 깨짐 없음), ps1은 BOM 바이트만 확인. 활성 가드가 설치 캐시(구 영문)라 새
   메시지는 release+재설치 후에만 실호출에 뜬다 — M1~M7과 동일한 구조적 제약, release
   후 도그푸딩으로 수용.
3. **README↔CHANGELOG 노트 중복은 잔존** (impl 후속 #3) — 이번 단일화는 사이트↔
   `CHANGELOG.md` 축만 다뤘다. 규약상 양쪽에 동일 노트를 두는 기존 중복은 범위 밖으로
   수용, 차기 후보.
4. **원본 파일에 마커 주석 추가** — 단일 원본화를 위해 `docs/conventions.md`·
   `CHANGELOG.md`에 HTML 주석 섹션 마커를 넣었다. GitHub 렌더에서 숨겨지고 의미 내용
   무변경이라 무해, 단일화의 최소 침습 방식으로 수용.

## 수정 내용

- 없음 — 리뷰 중 추가 결함을 발견하지 못했다. impl 단계에서 가드 한국어 차단(파일
  입력으로 활성 캐시 가드 우회 실행), 인코딩 바이트(sh `23 21 2f`·ps1 `ef bb bf`),
  `--strict` 통과, 인클루드 반영·마커 누수 없음, 빌드 출력 porpoise 0건을 이미 실증했고,
  리뷰에서 워크플로우 빌드 cwd(루트)와 `check_paths: true` 안전망을 추가 확인했다.

## 검증

- **완료 기준 대조**:
  ① 가드가 `phase=impl`에서 git commit 류를 **한국어** + exit 2로 차단, 비-git exit 0,
     한글 무깨짐. sh=BOM 없는 UTF-8 / ps1=BOM 포함 UTF-8 바이트 확인(실증).
  ② 패키지 위생: 캐시에 `docs/` 포함 실측 + 공식 제외 수단 부재 근거로 수용 재확정,
     `project-context.md` "배포 위생" 절에 기록(실증·문서).
  ③ `site/docs/{conventions,changelog}.md`가 `docs/conventions.md:body`·`CHANGELOG.md:notes`
     를 인클루드 — 사본 본문 중복 제거(실증).
  ④ `mkdocs build --strict` exit 0, 경고·깨진 링크 없음(실증).
  ⑤ 빌드 출력 `site/_build`에 porpoise 0건 — 도입 문단을 마커 밖에 둔 설계로 귀속
     재유입 없음(실증).
  ⑥ `docs/conventions.md` tide-guard 절이 한국어 메시지·인코딩 규약 반영, 의미 내용은
     마커 주석·해당 갱신 외 무변경(실증).
- **부수효과 분리**: impl·review 통틀어 git 없음. tide-guard(review phase)와 충돌 없음.
  변경은 모두 M8 산출물 + 직전 retro.md(이전 커맨드분).
- **인클루드 견고성**: 워크플로우가 `working-directory` 없이 루트에서 빌드 → `base_path`
  `.`이 원본을 정확히 가리킴. `check_paths: true`가 경로 누락 시 빌드를 실패시켜 silent
  drop을 방지.
- **미검증 잔여 리스크**: ps1 런타임 출력(사소2)·실배포 사이트의 인클루드 렌더는 release
  후 재설치/배포 도그푸딩에서 확인. 위험 낮음(정적 빌드 통과 + sh 실증 + 표준 snippets).

## 릴리즈 판정

**가능** — 추천 버전: **v0.9.0 (minor)**

- 차단 0건. 완료 기준 1~6 충족(2는 결정 문서화, ps1 런타임만 사후 실증) — M5~M7과 동일
  기준 통과.
- 권장 1·사소 3은 모두 impl 후속이 추적, 수용 가능.
- minor 근거: 사용자 대면 차단 메시지 변경 + 사이트 빌드 구조(snippets 단일화) 변경,
  하위 호환·0.x 누적. patch도 방어 가능하나 history가 일관 minor이고 M8 목표 버전과 일치.

## 다음 단계

- **릴리즈**: `/tide:release v0.9.0`
- 릴리즈 후: 재설치 + 새 세션에서 ps1 환경 가드 한국어 출력 실증(사소2), Pages 재배포로
  conventions/changelog 인클루드 렌더 확인. M7의 Pages 소스 전환이 아직이면 함께 수행.
- 차기 마일스톤 후보(미반영, retro 추적): **진짜 병렬 실행 수단**(회고 최상위), README↔
  CHANGELOG 단일화, snippets "루트에서 빌드" 전제 명문화(권장1).
