# 프로젝트 컨텍스트 (project-context)

> `/tide:kickoff`가 진행 중 프로젝트를 감지해 생성하는 문서. 이후 `/tide:milestone`·
> `/tide:impl`이 기존 구조를 재조사 없이 참조한다. 구조가 바뀌면 갱신한다.

## 스택 · 의존성

- **형태**: Claude Code 플러그인 (코드 런타임 없음 — 마크다운 프롬프트 + 셸 hook으로 구성)
- **언어**: Markdown(스킬·문서), POSIX sh + PowerShell(가드 hook), JSON(매니페스트)
- **외부 의존성**: 런타임 의존성 없음. Windows에서 hook 실행에 Git for Windows의 `sh` 필요
- **버전 원본**: `.claude-plugin/plugin.json` (이 문서는 버전 숫자를 복제하지 않는다 — 드리프트 방지)

## 디렉터리 구조

| 경로 | 역할 |
|---|---|
| `.claude-plugin/` | `plugin.json`·`marketplace.json` — 플러그인/마켓플레이스 매니페스트 (버전 원본) |
| `skills/` | 스킬 11종 — `{kickoff,milestone,impl,review,release,status,cycle,retro,fleet,fleet-cycle,fleet-verify}/SKILL.md`. milestone·impl·review·retro는 `template.md` 동봉 (fleet은 읽기 전용 멀티 레포 개요, fleet-cycle은 교차 사이클 자동화, fleet-verify는 통합 검증) |
| `hooks/` | `hooks.json`(PreToolUse 등록) + `tide-guard.sh`(원본 로직)·`tide-guard.ps1`(보조 사본) |
| `docs/milestones/` | 마일스톤 문서 `M{N}.md` |
| `docs/reports/` | 완료보고서 `M{N}-impl.md`·리뷰보고서 `M{N}-review.md`·회고 `retro.md`(최근) + `retro-archive.md`(과거 회고 분리·보존) |
| `docs/conventions.md` | 단계별 규약 단일 원본 |
| `docs/commands.md` | 커맨드 카탈로그 단일 원본(11종 역할·인자·산출물·금지). 사이트 `commands.md`가 `pymdownx.snippets`로 본문(`[start:body]`) 인클루드 — `tests/discover` 가드가 카운트·셸·이름 완전성을 집행 |
| `tests/` | 라이브 실증 하니스 (`multi-repo/`·`site-includes/` 등 — `run.sh`·`run.ps1`, 자동 러너 없는 도그푸딩 검증 수단). 발견·위상정렬·deps 파싱·BOM 제거 참조 구현은 `tests/lib/{encoding,discover,deps,toposort}.{sh,ps1}` 공유 단일 원본을 하니스가 source(트리 내 자기완결; source 순서 encoding→discover→deps→toposort) |
| `site/` | MkDocs 사이트 (`mkdocs.yml`·`docs/` — 문서 사이트 빌드 입력). `conventions`·`orchestration`·`changelog`·`commands` 4종은 저장소 원본을 `pymdownx.snippets`로 인클루드하는 **스니펫 셸**(수기 복제 아님) |
| `.tide/` | `phase`(로컬 상태 — `.gitignore` 대상, 커밋 안 함) + `deps`(의존성 선언 — 커밋함) + `release-mode`(게시 모드 선호도 `pr`/`release` — `deps`와 동급으로 커밋함). gitignore 범위는 `.tide/`가 아니라 `.tide/phase`만 |
| `.tide-fleet/` | 부모 레벨 통합 훅(`integration`) — fleet-verify가 읽는 cross-repo 검증 명령(옵트인). 숨김 디렉터리라 fleet 발견에서 제외 |

## 진입점 · 빌드/테스트

- **진입점**: 슬래시 커맨드 `/tide:{단계}` (플러그인 설치 시 노출). 가드는 PreToolUse hook으로 자동 활성
- **빌드**: 없음 (해석형 마크다운/셸)
- **테스트**: 자동화된 테스트 러너 없음. 검증 수단은 **플러그인 재설치 후 새 세션 드라이런/도그푸딩**
  (스킬 노출 확인, 가드 차단/통과 확인, 템플릿 경로 치환 확인)과 **`tests/`의 자기완결형 라이브
  하니스** — `tests/multi-repo`(repo-root 인식·앵커링·cwd 규율)와 오케스트레이션 참조 구현
  하니스 `tests/fleet`(발견·5분류·위상정렬·전체 연산자 계약 비교·다중 자리 마일스톤 M10+)·
  `tests/fleet-cycle`(release 제외·downstream-skip)·`tests/fleet-verify`(verification-only·git-verb
  가드라일)·`tests/site-includes`(사이트 스니펫 인클루드 타깃·섹션 마커·제외 용어 정적 검증 + 용어
  추출 positive-control — mkdocs 불요)가 모두 존재한다(양 셸 `run.sh`·`run.ps1`). `tests/multi-repo`는
  선두 BOM 입력 내성 회귀를 포함(양 셸 12/12). 가드 스크립트 수정 시 `.sh`·`.ps1` 두 사본을 함께 갱신
- **개발 사이클**: tide 자신을 도그푸딩 — `/tide:milestone → impl → review → release`

## 배포 위생 (패키지에 포함되는 파일)

- **현황(M8 재조사, 2026-06-11)**: 플러그인 설치는 저장소의 **추적 파일 트리를
  그대로 미러링**한다. 설치 캐시(`~/.claude/plugins/cache/tide/tide/{version}/`)에
  런타임 무관 파일인 `docs/`가 실제로 포함됨을 확인했다(`site/`·`.github/`도 추후
  버전부터 동일하게 포함될 것).
- **공식 제외 수단 부재**: `plugin.json`·`marketplace.json`에 배포 파일을 한정하는
  `files`/`include`/`ignore` 류 필드가 없고, `.gitattributes export-ignore`는
  `git archive`에만 적용돼 clone 기반 설치에는 효과가 없다. M3의 "수용 종결"을 이
  근거로 **재확정**한다.
- **영향·결정**: 런타임에는 `skills/`·`hooks/`·`.claude-plugin/`만 쓰이고 추가 파일
  (`docs/`·`site/` 등)은 용량 외 비용이 없어(보안·동작 무영향) **수용**. 공식 제외
  수단이 생기면 재검토(재검토 트리거: 플러그인 매니페스트 스키마에 파일 한정 필드 등장).

## 핵심 도메인 개념

- **사이클**: kickoff → milestone → impl → review → release. `status`는 읽기 전용 현재 위치 보고
- **부수효과 분리**: impl·review는 git 작업 금지(코드·보고서만), git commit/tag/push는 release에서만
- **tide-guard**: `.tide/phase`가 `release`가 아니면 git **쓰기**(commit·태그 생성/삭제·push)를 기계적으로
  차단(exit 2)하고 git **읽기**(커밋 읽기·태그 목록·메시지 검색·이력 파일 읽기)는 통과시킨다(M28). verb는
  git **서브커맨드 위치**에서만 판정한다 — 옵션 값(`--grep=commit`)·경로(`HEAD:src/tag.rs`)·복합 서브커맨드
  이름(`commit-graph`·`cat-file commit`)의 부분일치는 무시. `tag`는 읽기 옵션만/인자 없음이면 목록(읽기),
  쓰기 옵션이나 목록 옵션 없는 위치 인자면 생성/삭제(쓰기). 상태 파일이 없으면 차단하지 않음. 입력 선두
  BOM 내성(strip 후 파싱)·sed `cwd` 추출 키 앵커링으로 견고화. 단일 원본 = conventions "tide-guard hook",
  집행 = `tests/multi-repo`(읽기/쓰기 구분 23/23 양 셸)
- **상태 파일 `.tide/phase`**: 현재 단계명 한 줄(`milestone`/`impl`/`review`/`release`/`idle`).
  각 스킬이 시작 시 기록하고 종료 시 `idle`로 되돌림
- **템플릿 단일 원본**: 마일스톤·보고서 형식은 각 스킬의 `${CLAUDE_SKILL_DIR}/template.md`가 원본
- **태스크 표기**: `M{N}-T01` … , 선행 의존은 `(deps: M{N}-T01, …)`
- **병렬 디스패치**: impl 단계(`/tide:impl`·`/tide:cycle` 공통)는 deps 위상에서 같은
  레벨의 독립 태스크를 서브에이전트로 동시 실행한다. 메커니즘·충돌 안전장치·병합·폴백의
  단일 원본은 `skills/impl/SKILL.md`의 "병렬 디스패치" 절. 파일 겹침 감지는 마일스톤
  템플릿의 태스크별 **"변경 파일"** 권장 필드(`skills/milestone/template.md`)로 결정적이
  된다 — 같은 레벨 태스크의 변경 파일이 비중첩이면 폴백 없이 병렬 유지
- **릴리즈 위생**: release 운영 주의(phase↔git 분리·멀티라인 메시지·제외 용어 literal
  회피)는 `skills/release/SKILL.md`, 메타 용어 누수 방지·빌드 출력 검증 규약은
  `docs/conventions.md`(버전·CHANGELOG 절). 릴리즈 노트의 단일 원본은 `CHANGELOG.md`이며
  README의 CHANGELOG 섹션은 포인터만 둔다(이중 갱신 제거). **gh 게시 모드**(`gh` 옵트인 —
  GitHub 릴리즈/PR 택1·검증 게이트·`.tide/release-mode` 선호도·원격 불가 처리·tide-guard 비확장)의
  단일 원본은 `docs/conventions.md` "릴리즈 게시 (gh)" 절이고, 절차는 `skills/release/SKILL.md`다.
  `pr` 모드는 PR 머지 후 같은 명령 재실행으로 태그·릴리즈를 자동 마무리한다(상태 인지·멱등). 마무리
  (finalize)는 다 쓴 릴리즈 브랜치(`release/v{버전}` 로컬·원격) 정리까지 포함한다(멱등·비차단·현재
  브랜치 안전 — 단일 원본 = conventions "`pr` 모드" 절)
- **멀티 레포 / 대상 레포**(M13 토대): 각 커맨드는 시작 시 "대상 레포 루트"를 정해(기본=세션 레포,
  현행 동일) 산출물 앵커링·git/테스트 cwd를 그 루트 기준으로 두고, repo-root 인식 가드가
  같은 루트의 `.tide/phase`를 읽어 레포별 격리가 성립한다(가산). 단일 원본은
  `docs/conventions.md`의 "멀티 레포 / 대상 레포" 절
- **오케스트레이션 로드맵 1~4층**(상위 폴더 단일 세션·멀티 레포 MSA): 안전·고가치인 아래층부터
  4층으로 쌓는다 — ① **1층 가시성**(`/tide:fleet`, 읽기 전용 발견·교차 상태·advisory 계획),
  ② **2층 의존성/계약 선언**(`.tide/deps` — 형제 레포 의존 + 선택적 계약 버전 제약, 위상정렬
  순서 인식), ③ **3층 교차 사이클 자동화**(`/tide:fleet-cycle` — 의존성 순서로 각 레포
  `milestone→review` 자동 실행 + 순서 release 핸드오프, **release 제외**), ④ **4층 통합 검증**
  (`/tide:fleet-verify` — 부모 레벨 통합 훅 `.tide-fleet/integration`으로 cross-repo 통합을
  **verification-only** 검증). 부수효과 분리 불변은 모든 층에서 유지(fleet advisory·fleet-cycle
  release 제외·fleet-verify verification-only). 단일 원본은 `docs/conventions.md`의 "멀티 레포
  오케스트레이션" 절, **실전 사용법은 `docs/orchestration.md`**(발견→deps/계약→fleet-cycle→
  fleet-verify→순서 release 워크드 예제)
- **계약 비교 연산자**(`.tide/deps`): 의존 줄에 선택적 버전 제약 `<형제명>[ <op> <버전>]`을 둘 수
  있고, 전체 비교 연산자(`>=`·`>`·`=`(또는 `==`)·`<=`·`<`)를 지원한다. 만족이면 무표기, 불만족이면
  `⚠ contract` 경고(연산자·요구·현재 표기, `>=` 위반 = upstream behind). 알 수 없는 연산자·비표준
  버전은 무시하고 경고(안전 측). 위상정렬 순서는 버전 제약과 무관하게 불변 — 경고는 줄 표기일 뿐.
  단일 원본은 `docs/conventions.md`의 "계약 비교 규칙" 절
- **2.0 안정성·메타 규칙**(v2.0.0~ 재기준): **커맨드 11종**(기존 8종 + `/tide:fleet`·
  `/tide:fleet-cycle`·`/tide:fleet-verify`) 호출명·역할과 **오케스트레이션 규약**(부수효과 분리
  불변·`.tide/deps`·계약 비교·`.tide-fleet/integration`)이 2.0부터 안정(stable)으로 동결되고,
  `.tide/phase`/tide-guard 계약·보고서·마일스톤 형식은 1.0 그대로 유지(불변)된다. 2.0은 동작
  파괴 없는 **계약 재기준**(v1.0.0의 "안정 선언" major와 동형)이며, 하위 호환을 깨는 변경은 다음
  major(3.0)에서만 한다(v1.x 가산 이력은 보존 표기). 또한 규약·단일 원본을 새로 더하면 그것을
  강제·반영할 실행 수단(스킬 프리플라이트·hook·CI 트리거·빌드)도 같은 사이클에 함께 손본다 —
  단일 원본은 `docs/conventions.md`의 "2.0 안정성"·"규약↔실행/인프라 동기화" 절

## 이월 항목 처분 원장

M20(에픽 마감)에서 회고 백로그의 이월·견고화 항목을 **각각 fix·수용(사유)·환경-이월(사유)** 중
하나로 명시 종결해 백로그를 실제로 비웠다. 이 원장은 그 처분을 기록한다(상세 근거는 M20 마일스톤
"이월 항목 종결 원장" 표).

| 항목 | 출처 | 처분 |
|---|---|---|
| 다중 자리 마일스톤(M10+) 픽스처 | M14 사소4 | **fix** — `tests/fleet` 분류·정렬에 M10+ 픽스처 추가 |
| gitignore 마이그레이션 노트 | M16 사소2 | **fix** — README에 "기존 프로젝트는 deps 채택 시 `.tide/`→`.tide/phase`로 좁혀라" 한 줄 |
| 통합 훅 git-verb 가드라일 | M19 사소2 | **fix** — fleet-verify가 훅 실행 전 git/release 토큰 점검·경고(advisory) |
| 참조 버전 파일 범위·pre-release | M17 사소2 | **fix(문서)** — 참조 구현은 `package.json`만, pre-release는 skip 명시 |
| jq 추출 분기 실증 | M13-impl#1 | **환경-이월** — 로컬 jq 부재. 정적 검토 + "jq 환경 재실행" 노트(동작 동일 기대), 회고에서 닫음 |
| 워크트리 격리 병합 경로 | M9-impl#3 | **수용** — 기본은 공유 트리(비겹침), 워크트리는 impl 스킬의 선택적 고급 경로로 이미 문서화. 별도 구현 불요 |
| README masthead 외부 귀속 | M12 | **수용** — 사이트만 제외, 저장소 원본 보존(원 의도). 변경 없음 |
| 브라우저 런타임 렌더·병렬 폴백 종단·retro 자기입력 비용 | M11~M12·M6 | **환경-이월/수용** — 세션·배포 수동 검증 영역. 저위험으로 회고에서 닫음(필요 시 별도) |
| `strip_bom`/`StripBom` 단일 원본화 | M24 sn3 / M25 sn3 | **fix(M26)** — `tests/lib/encoding.{sh,ps1}` 단일 원본으로 추출, `tests/fleet-verify` 로컬 복제 제거(정의 셸당 1개). 참조 구현 이중성 군집의 마지막 코드성 복제면 종결 |
| mkdocs 빌드 출력 검증(로컬 사각지대) | M22 사소1~M25 다음단계 | **fix(부분, M26)** — `tests/site-includes` 자기완결 가드로 인클루드·마커·제외 용어를 mkdocs 없이 결정적 검증(로컬 사각지대 종결). 실제 `--strict` 렌더는 CI 잔존(렌더 잔여만 환경-이월로 남김) |
| `site-includes` 용어 추출 오추출-공허 green | M26 sn1 | **fix(M27)** — 추출한 제외 용어가 마스트헤드 추출 영역에 literal로 실재하는지 positive-control 단언 추가(양 셸 +1). "틀린 이유의 green" 차단 |
| `multi-repo` fixture-BOM 취약성 | M26 sn2 | **fix(M27)** — ps1 fixture를 no-BOM UTF-8(`WriteAllText`)로 쓰고, 가드가 입력 선두 BOM에 내성(strip)을 갖게 함. 선두 BOM 입력 회귀 단언 추가(양 셸 +2씩, 12/12) |
| tide-guard raw-`$input` grep 거칠음 | M13 사소3→M18 사소6 | **fix(M27)** — sed `cwd` 추출을 JSON 구조 경계(`{`·`,`·공백)로 앵커링해 부분일치 오인 감소. 차단/통과 판정·메시지·exit 2 계약은 불변 |
| tide-guard 읽기 오차단(태그 목록·`--grep`·이력 경로·`cat-file`) | 사용자 요구(2026-06-18) | **fix(M28)** — verb를 git 서브커맨드 위치에서만 판정 + `tag` 읽기/쓰기 구분. 비-release에서도 git 읽기(커밋 읽기·태그 목록·메시지 검색·이력 파일)는 통과, 쓰기(commit·태그 생성/삭제·push)만 차단. 차단되던 쓰기 집합 불변(보호 보존). `tests/multi-repo` 23/23 양 셸 집행 |

이로써 오케스트레이션 에픽의 잔여 후속은 fix/수용/환경-이월로 전부 종결됐고, **로드맵 항목 미반영은
0**이다 — 백로그가 닫혔다. M26은 그 뒤 남아 있던 **코드성 잔여 두 건**(`strip_bom` 단일 원본화·mkdocs
로컬 사각지대)을 fix로 마저 닫았다. **M27**은 M26 리뷰의 비차단 후속(sn1 `site-includes` positive-control·
sn2 `multi-repo` fixture-BOM 내성)과 오래 수용돼 온 `tide-guard` raw-`$input` grep 거칠음(M13 사소3→M18
사소6)을 **모두 fix로 닫고**, `pr` 모드 finalize에 릴리즈 브랜치 정리를 더했다 — 이로써 **코드로 손볼 잔여
후속은 0**이며, 남는 미반영은 **라이브 도그푸딩 영역(gh 게시·`pr` finalize 라이브 실증)뿐**이다. **M28**은
백로그가 아닌 **사용자 신호**(release 외 상황의 git 읽기 작업이 필요)로 tide-guard의 git 읽기 오차단(태그
목록·`--grep`·이력 경로·`cat-file`)을 닫았다 — verb를 서브커맨드 위치에서 판정하고 `tag` 읽기/쓰기를 구분해
비-release에서도 git 읽기가 통과한다(차단되던 쓰기는 불변, 보호 보존). 남는 미반영은 여전히 라이브 도그푸딩
영역뿐이다.

## 메타

- 생성: `/tide:kickoff` 브라운필드 감지 (M4 자기적용) — 2026-06-11 기준
- 감지 근거(최초 감지 시점 기준 — 역사값, 이후 갱신하지 않음): 커밋 4개 + 기존 스킬/hook 소스 +
  M1~M6 마일스톤 보유 → 진행 중 프로젝트
