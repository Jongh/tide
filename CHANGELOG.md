# CHANGELOG (Older Releases)

최신 릴리즈는 [README.md](README.md#changelog) 를 참조하세요.

---

<!-- 아래 [start:notes]~[end:notes]는 사이트(site/docs/changelog.md)가 pymdownx.snippets로
     릴리즈 노트만 인클루드하기 위한 마커다. 위 제목·안내 줄은 사이트에 부적절해 제외된다.
     렌더에는 영향 없음. -->
<!-- --8<-- [start:notes] -->
### [v2.2.0]
- **사이트 단일 원본화 — 커맨드 카탈로그를 캐노니컬 `docs/commands.md`로 동결(정리)**: 그동안 `site/docs/commands.md`에 수기로 복제돼 있던 커맨드 카탈로그(한눈에 보기 표 + 11종 절)를 새 캐노니컬 문서 `docs/commands.md` 단일 원본으로 끌어오고, 사이트 페이지는 `pymdownx.snippets`로 본문을 인클루드하는 **스니펫 셸**로 전환했다(기존 `conventions`·`orchestration`·`changelog`와 동형). 카탈로그 본문은 **바이트 보존 이동**이라 렌더 출력 불변. 회고가 M11~M20 내내 지목한 "수기 사이트 페이지 표류" 군집의 잔존 뿌리를 단일 원본화로 닫았다.
- **드리프트 가드 확장 — 개수→이름 완전성 + 셸 검증**: `tests/discover` 가드를 (B1) `N종` 카운트 선언 정합(캐노니컬 = `docs/commands.md`), (B2) 사이트 카탈로그 페이지가 스니펫 셸인지(인클루드 보유·카운트/표 미재선언, 재수기화 시 FAIL), (B3) 카탈로그 완전성(각 커맨드 이름이 `/tide:<name>` **경계 일치**로 등장 — `fleet`이 `fleet-cycle`에 substring으로 걸려 거짓 통과하지 않도록)까지 확장했다. 새 단일 원본을 더하면 강제 수단도 같은 사이클에(2.0 메타 규칙).
- **라이브 실증**: `tests/discover` 하니스가 감지 임계값 + 단일 원본 동결(B1/B2/B3)을 sh·ps1 양쪽 각 19/19 통과. `tests/fleet`·`fleet-cycle`·`fleet-verify`·`multi-repo` 회귀 불변. 전부 하위 호환 정리 가산 — 커맨드 11종 이름·역할(2.0 stable 계약)·`.tide/phase`/tide-guard·보고서·마일스톤 형식 불변, 사이트 렌더 출력 불변.

### [v2.1.0]
- **오케스트레이션 발견성 — 멀티 레포 맥락 감지 힌트(가산)**: `/tide:status`·`/tide:kickoff`가 본래 작업을 마친 뒤, 현재 세션 위치의 직속 자식 tide 레포(발견 규약 재사용 — git 레포 AND tide 산출물, 숨김 디렉터리 제외)가 **2개 이상**이면 출력 맨 끝에 `여러 자식 tide 레포 N개 감지 — 교차 개요는 /tide:fleet` 한 줄을 advisory로 덧붙인다. **2개 미만(단일 레포 세션 포함)이면 아무 것도 덧붙이지 않는다**(소음 0). 읽기 전용·advisory — status는 종전대로 완전 읽기 전용, kickoff는 골격 생성 외 동작 불변이고 힌트는 fleet을 자동 실행하지 않는다. 발견성 규약은 `docs/conventions.md` "멀티 레포 오케스트레이션"이 단일 원본.
- **커맨드 수 드리프트 가드**: `skills/*/SKILL.md`로 존재하는 실제 커맨드 스킬 개수와 캐노니컬 문서·사이트(`README`·`conventions`·`site/docs/commands`·`site/docs/getting-started`)가 선언하는 "N종" 수가 어긋나면 FAIL하는 가드를 `tests/discover`에 추가했다 — 커맨드 증감 시 선언 갱신을 강제한다(수기 사이트 페이지의 커맨드 수 표류 회귀 고정).
- **라이브 실증**: `tests/discover` 하니스가 감지 임계값(≥2→hint·<2→none·단일 레포→none·숨김 미카운트)과 커맨드 수 가드를 sh·ps1 양쪽 각 16/16 통과. 전부 하위 호환 가산 — 자식 tide 레포 2개 미만 세션의 status·kickoff 출력 불변, 단일 레포 동작·2.0 안정 계약(11종 커맨드·오케스트레이션 규약) 불변.

### [v2.0.0]
- **2.0 안정 계약 재기준(동작 무파괴)**: 오케스트레이션 에픽(로드맵 1~4층) 완성 surface를 **stable로 동결 선언**한다 — v1.0.0이 "안정 선언" major였던 것과 동형의 **계약 재기준**이며 호환을 깨지 않는다. **커맨드 11종**(기존 8종 + `/tide:fleet`·`/tide:fleet-cycle`·`/tide:fleet-verify`)의 호출명·역할과 **오케스트레이션 규약**(부수효과 분리 불변·`.tide/deps` 의존/계약 비교·`.tide-fleet/integration` 통합 훅·tide-guard 백스톱)을 안정 계약으로 동결한다. `.tide/phase`·tide-guard·보고서·마일스톤 형식은 1.0 계약 그대로 유지. 하위 호환을 깨는 변경은 다음 major(v3.0.0)에서만 한다.
- **계약 비교 연산자 확장(가산)**: `.tide/deps`의 버전 제약이 `>=`만이 아니라 **`>=`·`>`·`=`(또는 `==`)·`<=`·`<` 전체 연산자**를 지원한다 — 의존 대상의 현재 버전과 요구 버전을 `vX.Y.Z` major.minor.patch로 비교해 불만족이면 의존 레포 줄에 `⚠ contract` 경고(연산자·요구·현재 명시)를 advisory로 표기한다. 알 수 없는 연산자·비표준 버전은 무시·경고하되 위반으로 단정하지 않으며, 이름 의존은 보존돼 위상정렬 순서·그래프는 불변이다. 기존 `>=`·미선언 deps 동작 불변(순수 가산).
- **통합 훅 git-verb 가드라일(advisory) + 자산 정리·견고화**: `/tide:fleet-verify`가 통합 훅 실행 전 git commit/tag/push·release 토큰(정석 cross-repo 형태 `git -C <dir> …` 포함)을 점검해 경고한다(강제 차단 아님 — verification-only 불변 유지). 백로그 이월 항목을 각각 fix(다중 자리 마일스톤 M10+ 픽스처·gitignore 마이그레이션 노트·가드라일)·수용·환경-이월로 명시 종결. **오케스트레이션 사용 가이드**(`docs/orchestration.md`, 사이트 노출)를 신설해 발견→deps/계약 선언→fleet-cycle→fleet-verify→순서 release를 워크드 예제로 설명한다.
- **라이브 실증**: `tests/fleet`(전체 연산자 satisfied/violation·미지 연산자 이름 의존 보존·다중 자리 M10+·BOM)·`tests/fleet-verify`(git-verb 가드라일 cross-repo 포함·verification-only)를 sh·ps1 양쪽 각 41/41·29/29 통과. 적대적 검증으로 참조 구현↔계약·사이트↔stable 선언 정합을 확인.

### [v1.6.0]
- **오케스트레이션 4층 — 통합 검증(`/tide:fleet-verify`, 11번째 커맨드)**: 자식 tide 레포들이 각자 사이클을 통과한 뒤, 레포를 가로지르는 통합을 대상 부모의 통합 훅(`.tide-fleet/integration`, 옵트인·parent-level)으로 검증한다. fleet-verify가 자식 레포를 발견해 통합 대상으로 보고하고, 부모 cwd에서 훅을 실행해 **exit 0 = 통합 pass / 비0 = fail**(실패 요약)을 보고한 뒤 "통합 pass면 release 핸드오프 순서대로 수동 release"를 안내한다. 훅 미선언이면 통합 검증 생략(옵트인·graceful).
- **verification-only(불변)**: fleet-verify는 git commit/tag/push·release·cross-repo git을 하지 않고, 어떤 레포의 `.tide/phase`도 `release`로 쓰지 않는다. 통합 훅은 검증/테스트 명령이어야 한다 — tide-guard는 phase≠release인 레포의 git을 막는 백스톱(release 차단기가 아닌 phase 잠금)이며, 통합 훅에 cross-repo git을 두지 않도록 안내한다.
- **오케스트레이션 로드맵 1~4층 완성**: 가시성(fleet) → 의존성 선언·계약 비교(`.tide/deps`) → 교차 사이클 자동화(fleet-cycle) → 통합 검증(fleet-verify). 전 계층에서 부수효과 분리 불변(release·cross-repo git 비자동화) 보존. `tests/fleet-verify/` 하니스가 훅 발견/파싱·옵트인 생략·pass/fail·verification-only(스킬 산문 결합)·`.tide-fleet` 발견 무시를 sh·ps1 양쪽 각 18/18 통과. 옵트인 가산 — 단일 레포·훅 미선언 동작 불변, 커맨드 10종·1.0 계약 불변.

### [v1.5.0]
- **오케스트레이션 3층 — 교차 사이클 자동화(`/tide:fleet-cycle`, 10번째 커맨드)**: 상위 폴더 단일 세션에서 발견된 자식 tide 레포들의 `milestone → impl → review`를 `.tide/deps` 의존성 순서(위상정렬·피의존 먼저)로 교차 자동 실행하고, 의존성 순서 release 핸드오프를 제시한다. upstream-behind 계약(M17)이 있는 레포는 핸드오프에서 `contract-blocked`로, 사이클이 중단된 레포의 downstream은 `skip`으로 보류 표기된다. 발견 0이면 단일 레포로 graceful 강등.
- **release·cross-repo git 자동화 제외(불변)**: fleet-cycle은 milestone→review까지만 자동화한다 — 어떤 레포에서도 release를 실행하지 않고, 어떤 레포의 `.tide/phase`도 `release`로 쓰지 않으며, git commit/tag/push·cross-repo git을 자동 실행하지 않는다. release는 순서 있는 핸드오프로 사용자에게 넘긴다. tide-guard는 phase≠release인 레포의 git을 막는 백스톱이고, **사전 점검**이 처리 전 phase=release 잔재(이전 중단된 수동 release) 레포를 제외해 백스톱이 풀린 채 도는 경로를 막는다.
- **라이브 실증**: `tests/fleet-cycle/` 하니스가 처리 순서(위상정렬)·release 제외·contract-blocked·downstream-skip + 불변을 강제하는 스킬 산문(금지 목록·백스톱/사전점검) 결합 검증을 sh·ps1 양쪽 각 23/23 통과. 옵트인 가산 — 단일 레포·미선언 동작 불변, 커맨드 9종·읽기 전용 fleet·부수효과 분리·`.tide/phase` 계약 불변.

### [v1.4.0]
- **오케스트레이션 2층 sub-step — `.tide/deps` `>=` 계약 버전 비교(옵트인)**: 의존 줄에 최소 버전을 선언하면(`<형제 레포명> >= <버전>`, 예 `svc-auth >= v0.3.0`), `/tide:fleet`이 의존 대상 레포의 현재 버전과 semver(major.minor.patch) 비교해 미달이면 권장 순서/advisory에 **`⚠ upstream behind`** 경고(그 레포를 먼저 올려야 함)를 표기한다. `>=`만 지원하고 그 외 연산자·비표준 버전은 경고에 그쳐 위반으로 단정하지 않는다. 위상정렬 순서·그래프는 버전 제약과 무관하게 불변. 버전 제약 없는 줄은 현행 동작 그대로(하위 호환 옵트인).
- **`.tide/deps` BOM 내성**: 파서가 선두 UTF-8 BOM(`EF BB BF`)을 제거해, Windows 편집기·`Set-Content -Encoding utf8`로 만든 BOM 붙은 deps 파일의 첫 줄(주석·의존명)도 올바로 파싱한다.
- 모두 옵트인·advisory만 — fleet은 여전히 읽기 전용이며 경고를 이유로 차단·실행하지 않는다(부수효과 분리 불변). `tests/fleet/` 하니스에 계약 만족/위반/연산자 외 무시/버전 파싱 불가/BOM 시나리오를 더해 sh·ps1 양쪽 각 23/23 통과.

### [v1.3.0]
- **멀티 레포 오케스트레이션 2층 — `.tide/deps` 의존성 인식 권장 순서(옵트인)**: 각 자식 레포가 루트 `.tide/deps`에 의존하는 형제 레포를 선언하면(한 줄에 하나, `#` 주석·빈 줄 무시), `/tide:fleet`이 의존 그래프를 위상정렬해 **권장 처리 순서**(피의존 먼저 — 예: orders가 auth에 의존하면 auth 먼저)를 advisory로 제시한다. 순환 의존은 감지·보고 후 상태 기반 순서로 폴백하고, 미선언 레포는 현행 동작 그대로(하위 호환 옵트인). fleet은 여전히 **읽기 전용·advisory만** — 순서를 제안할 뿐 cross-repo git을 자동 실행하지 않는다(부수효과 분리 불변).
- **`.tide/deps`는 커밋·`.tide/phase`는 로컬**: gitignore 범위를 `.tide/`에서 `.tide/phase`로 좁혀 의존 선언(`.tide/deps`)은 커밋되고 단계 상태(`.tide/phase`)는 종전대로 로컬에 머문다. `.tide/phase`의 의미와 tide-guard 차단 계약은 불변. kickoff의 `.gitignore` 생성도 이에 맞춘다.
- **라이브 실증**: `tests/fleet/` 하니스에 `.tide/deps` 파싱·위상정렬·순환 감지 폴백 참조 구현과 시나리오(위상정렬 순서·순환 폴백·미선언 독립·미존재명 무시)를 추가해 sh·ps1 양쪽 각 15/15 통과. 발견·5분류·1:1 요약·숨김 무시·강등 기존 시나리오 유지.

### [v1.2.1]
- **`/tide:fleet` 출력 정합·결정성(patch)**: 교차 요약을 레포 사이클 위치와 1:1로 대응하는 정규 5버킷(`release 가능 / review 대기 / impl 진행 / milestone 필요 / 보완 필요`)으로 통일하고(임의 합산 제거), advisory 다음 커맨드를 인자 포함으로 고정했다(`/tide:impl M{N}` · `/tide:release v{추천}`). 발견 규약은 숨김(dot) 디렉터리(`.git`·`.claude` 등)를 무시함을 명문화. 분류 taxonomy의 단일 원본은 `docs/conventions.md` "멀티 레포 오케스트레이션" 절이며, fleet 스킬과 `tests/fleet` 하니스가 이를 인용한다(sh·ps1 각 9/9, 숨김·`보완 필요` 시나리오 포함). fleet 호출명·역할·읽기 전용·부수효과 분리는 불변.

### [v1.2.0]
- **멀티 레포 오케스트레이션 1층(읽기 전용 가시성)**: 새 커맨드 `/tide:fleet`이 상위 폴더 아래 자식 tide 레포들을 발견해 각자의 사이클 상태(마일스톤·보고서·판정·버전·phase)를 교차 표로 보고하고 레포별 다음 행동을 advisory로 제시한다. 읽기 전용 — 파일·`.tide/phase`·git을 변경하지 않으며, cross-repo git은 자동화하지 않는다(release는 레포별 수동).
- **오케스트레이션 규약·로드맵 단일 원본**: `docs/conventions.md`에 "멀티 레포 오케스트레이션" 절 신설 — 4계층 로드맵(1층 가시성=이번, 2층 의존성/계약 선언·3층 교차 사이클 자동화·4층 통합 검증은 후속 마일스톤), 부수효과 분리 불변, 자식 레포 발견 규약(직속 1단계), advisory 계획 규칙.
- **커맨드 9종 — `/tide:fleet` 가산**: 기존 커맨드 8종의 호출명·역할은 v1.0 안정 계약 그대로이며, 읽기 전용 멀티 레포 개요 커맨드 `/tide:fleet`이 v1.2.0부터 하위 호환 가산으로 더해진다. README·conventions·project-context 정합.
- **문서↔릴리즈 버전 드리프트 차단**: `docs/project-context.md`가 버전 숫자를 복제하지 않고 `.claude-plugin/plugin.json`을 단일 원본으로 가리킨다 — release가 버전 파일만 범프해도 문서가 stale이 되지 않는다(드리프트를 갱신 단계가 아니라 복제 제거로 구조적 해소).
- **라이브 실증**: `tests/fleet/` 하니스로 자식 레포 발견·사이클 위치 분류·graceful 강등을 sh·ps1 양쪽 각 5/5 통과 확인.

### [v1.1.0]
- **멀티 레포 토대(가산)**: 상위 폴더 한 곳에서 띄운 단일 세션이 그 아래 여러 자식 레포를 오가며 각 위치별로 tide 사이클을 격리해 돌릴 수 있다. 단일 레포 사용(레포 루트에서 세션 구동) 동작은 **불변** — 이 변경은 전부 하위 호환 가산이다.
- **tide-guard repo-root 인식**: 가드(`hooks/tide-guard.sh`·`tide-guard.ps1`)가 명령이 실제로 실행되는 레포 루트의 `.tide/phase`를 읽어 차단/통과를 판정한다(단일 레포에선 `CLAUDE_PROJECT_DIR`와 동일). 레포를 못 찾으면 `CLAUDE_PROJECT_DIR` 폴백, 그래도 없으면 무차단. 차단 규칙·안내 메시지·exit 2·인코딩 규약은 불변.
- **대상 레포 규약 단일 원본**: `docs/conventions.md`에 "멀티 레포 / 대상 레포" 절을 신설해 대상 레포 해석·산출물 앵커링·cwd 규율·레포별 격리를 단일 원본으로 정의. 스킬 8종이 이를 참조해 산출물·`.tide/phase`·git·테스트를 대상 레포 루트 기준/cwd로 수행하고, `release`는 push 대상을 레포 실제 remote·기본 브랜치에 맞춘다.
- **라이브 실증**: `tests/multi-repo/` 하니스로 repo-root 인식·레포별 격리·폴백을 sh·ps1 양 가드에서 각 10/10 통과 확인. 상위 폴더 단일 세션 + 자식 레포 대상 사이클(앵커링·격리)도 세션 레벨에서 실증.

### [v1.0.0]
- **안정(stable) 선언**: 커맨드 8종의 호출명·역할, 단계별 규약, `.tide/phase`·tide-guard 계약, 보고서·마일스톤 형식을 v1.0.0부터 안정 계약으로 선언 — 하위 호환을 깨는 변경(호출명 제거·역할/계약 의미 변경)은 다음 major에서만, minor·patch는 가산·정리·견고화만. 11사이클 연속 "가능"·전부 minor로 굳은 세트를 1.0으로 고정
- **"규약↔실행/인프라 동기화" 메타 규칙 신설**: 규약·단일 원본을 새로 더하면 그것을 강제·반영할 실행 수단(스킬 프리플라이트·hook·CI 트리거·빌드)도 같은 사이클에 함께 손본다 (`docs/conventions.md`)
- **README↔CHANGELOG 단일화**: `CHANGELOG.md`가 릴리즈 노트의 단일 원본이고 README는 포인터만 둔다 — release 절차에서 README CHANGELOG 갱신 단계 제거(이중 갱신·불일치 종결)
- **배포 트리거 견고화**: `deploy-pages.yml`이 `main` 푸시마다 빌드·배포(`paths` 필터 제거) — 사이트가 단일 원본 인클루드하는 루트 파일이 늘어도 누락으로 낡지 않음. `site_url` 소문자 정렬, 홈에 1.0 안정성 반영
- 매니페스트 구조 무수정·자동 발견. 이 라운드 변경은 전부 정리·가산(하위 호환 파괴 없음)

### [v0.12.0]
- **도그푸딩 라운드 — 누적 실증 부채 상환**: 회고가 추적해 온 배포·환경 의존 실증을 한 묶음으로 처리. GitHub Pages 게시 확인(라이브 HTTP 200·홈/규약 정상), `tide-guard.ps1` 한국어 차단 메시지를 PowerShell 5.1에서 런타임 실증(무깨짐·exit 2·BOM), 병렬 디스패치 폴백 경로(겹침→순차·부분 실패→재시도/중단) 워크스루 확인
- **배포 결함 수정**: `deploy-pages.yml` 트리거 `paths`가 `site/**`만 감시해, 사이트가 단일 원본 인클루드하는 루트 파일(`CHANGELOG.md`·`docs/conventions.md`)만 바뀐 릴리즈에서 사이트가 낡던 문제를 수정(두 파일을 paths에 추가) — 변경 이력 페이지 고착(2릴리즈) 적발·해소
- **release 프리플라이트에 빌드 출력 검증 배선**(M10 권장1): 사이트가 있는 프로젝트에 한해 빌드 산출물 기준 제외 용어 0건 확인 단계 추가 — 규약↔실행 일치
- 병렬 디스패치 폴백 규약 보강(`skills/impl/SKILL.md`): 겹침=정규화 경로 교집합·빈/조건부 집합은 잠재 겹침으로 순차, 실패 정의+재시도 1회. 매니페스트 무수정·자동 발견

### [v0.11.0]
- **안정화 라운드 + 병렬 디스패치 런타임 실증**: M9의 "독립 태스크 서브에이전트 동시 디스패치"를 **실제로 사용해 이 사이클을 구현** — 비중첩 태스크 3개를 한 메시지에서 병렬 디스패치(폴백 없음, 벽시계 = 합산 아닌 최댓값)해 M9 병렬 기능의 **첫 런타임 실증**
- `skills/release/SKILL.md`에 "운영 주의" 절: phase↔git 분리(가드가 명령 전 phase를 읽음)·멀티라인 커밋 메시지는 환경 문법에 맞춤·릴리즈 노트의 제외 용어 literal 회피
- `skills/milestone/template.md`에 태스크별 "변경 파일" 권장 필드 — 병렬 겹침 감지를 휴리스틱에서 결정적으로(하위 호환, 필수 아님)
- `docs/conventions.md`에 메타 용어 누수 방지 + 릴리즈 빌드 출력 검증 규약 추가(snippets로 사이트 반영), `docs/project-context.md` 반영. 매니페스트 무수정·자동 발견

### [v0.10.0]
- **진짜 병렬 실행 신설**: `/tide:impl`·`/tide:cycle`의 impl 단계가 deps 위상에서 독립(무의존) 태스크를 서브에이전트로 **동시 디스패치**(같은 메시지에 복수 Agent 호출 = 동시 실행, 레벨 간 배리어) — "병렬은 스케줄링 해석일 뿐"이던 것을 실제 동시 실행으로 전환. 메커니즘·전달 컨텍스트·반환 계약은 `skills/impl/SKILL.md`의 "병렬 디스패치" 절이 단일 원본
- 파일 충돌 안전장치(예상 변경 파일 겹침 → 겹치는 태스크만 순차 폴백, 워크트리 격리는 선택·기본 비활성), 결과 병합(단일 impl 보고서)·부분 실패 처리, tide-guard 정합(서브에이전트도 phase=impl이라 git 차단). Agent 부재·레벨 단일 태스크·deps 이상은 순차 폴백(하위 호환)
- `skills/cycle/SKILL.md`의 "실제 병렬 실행 수단은 구현 판단에 맡긴다" 문장을 impl 단일 원본 참조로 교체, `docs/conventions.md`·`README.md`·`docs/project-context.md` 반영(매니페스트 무수정·자동 발견)
- 회귀 수정: v0.9.0 changelog 노트의 검증 문장에 들어간 외부 저장소명 literal이 단일 원본화(snippets)로 사이트에 유입된 것을 리워딩으로 제거 — 사이트 외부 귀속 표기 0건 회복

### [v0.9.0]
- **tide-guard 차단 메시지 한국어화**: git commit/tag/push 차단 안내를 한국어로("'{phase}' 단계에서는 git commit/tag/push가 차단됩니다. git 작업은 /tide:release 단계에서만 허용됩니다") — `tide-guard.sh`·`.ps1` 동일 문구. **인코딩 규약 확정**: sh=BOM 없는 UTF-8(Git Bash shebang 보호), ps1=BOM 포함 UTF-8(Windows PowerShell 5.1 한글 보존)
- **사이트 문서 단일 원본화**: `pymdownx.snippets`로 사이트 `conventions`·`changelog`가 저장소 원본 `docs/conventions.md`·`CHANGELOG.md`를 인클루드 — 사본 이중 갱신 부채 제거. 원본 도입부의 외부 귀속은 섹션 마커(`[start:body]`/`[start:notes]`)로 사이트에서 제외(빌드 출력 0건 유지)
- **패키지 위생 재확정**: 설치가 추적 파일 트리를 미러링함을 캐시로 실측, 공식 제외 수단 부재로 수용 재확정(`docs/project-context.md` "배포 위생" 절). 런타임 무관 파일은 용량 외 비용 없음
- 검증: `mkdocs build --strict` 통과 + 인클루드 정상(마커 누수 없음) + 빌드 출력 외부 귀속 표기 0건 실증, 편집본 가드 sh 한국어 차단(exit 2) 실증

### [v0.8.0]
- **tide 소개 GitHub Pages 사이트 신설**: MkDocs Material 기반 한국어 문서 사이트(홈·시작하기·개념·커맨드 레퍼런스·규약·변경 이력 6페이지)를 `site/`에 구성하고, GitHub Actions(`.github/workflows/deploy-pages.yml`)로 `main` 푸시 시 자동 빌드·배포 — 사이트 소스를 tide 사이클 기록(`docs/`)과 격리(`site/`, `site_dir: _build` 명시)해 충돌 회피
- 콘텐츠는 `README.md`·`docs/conventions.md`·`CHANGELOG.md`·`skills/*/SKILL.md`에서 정제, tide를 독립 워크플로우로 서술(외부 저장소 귀속 표현 제외). 사이클 다이어그램은 Mermaid로 재구성. **원본 문서는 무수정**
- `mkdocs build --strict` 통과 검증(격리 venv), `site/` 전체 외부 귀속 0건, `.gitignore`에 빌드 출력 `site/_build/` 추가
- 배포에는 저장소 Settings → Pages → Source를 "GitHub Actions"로 1회 전환 필요(코드 외 수동 단계)

### [v0.7.0]
- **`/tide:retro` 회고 신설**: 누적된 마일스톤·보고서를 가로질러 반복 문제·이슈 군집, 수용된 트레이드오프, "후속"의 반영/미반영 추적, 릴리즈 판정·버전 추이를 집계하는 읽기 전용 회고 스킬 — 산출물은 갱신형 단일 문서 `docs/reports/retro.md`(회고 시점마다 최상단 누적), 형식은 `skills/retro/template.md` 동봉
- `/tide:status`와 동일한 읽기 전용 원칙 — 회고 문서 하나만 생성/갱신하고 `.tide/phase`·git에는 손대지 않음
- `docs/conventions.md`(보고서 절·금지 행위 표)·`README.md`(커맨드 표)·`docs/project-context.md`에 retro 반영, 스킬 8종으로 갱신
- 첫 회고 산출 — M1~M5 사이클을 집계한 `docs/reports/retro.md` 생성(반복 군집 4·수용 트레이드오프 6·후속 반영 7/미반영 3·버전 추이 v0.2.0~v0.6.0 전부 minor)

### [v0.6.0]
- **`/tide:cycle` 오케스트레이션 신설**: `milestone → impl → review`를 한 번의 호출로 자동 체이닝 — 각 단계 진입 시 `.tide/phase` 기록, 사이클 종료 시 `idle` 복원, 한 단계라도 전제조건 미충족·실패 시 사이클 전체를 중단하고 중단 지점·사유 보고. git 작업을 하는 `release`만은 체이닝에서 제외하고 review "가능" 판정 후 `/tide:release vX.Y.Z`를 안내 (부수효과 분리·tide-guard와 정합)
- impl 단계에서 마일스톤 태스크의 `(deps:)` 표기를 파싱해 독립=병렬·의존=순차로 스케줄링하는 규칙 명시 (순환 의존·미존재 의존 ID는 감지·보고 후 순차 폴백)
- 무인자 호출 시 최대 번호 마일스톤의 보고서 상태로 시작점 3분기 (impl 없음→impl / impl만 있음→review 이어하기 / 둘 다 완료→새 milestone)
- 신규 스킬이 매니페스트 수정 없이 `skills/*/SKILL.md` 자동 발견됨을 확인 — `plugin.json`·`marketplace.json` 무변경
- `docs/conventions.md`·`README.md`·`docs/project-context.md`에 cycle 반영 (사이클 다이어그램·금지 행위 표·커맨드 표·스킬 7종)

### [v0.5.0]
- **브라운필드 킥오프**: `/tide:kickoff`가 대상 저장소를 신규/진행-중으로 판별(커밋 이력·기존 산출물·소스 규모 기준)하고, 진행-중이면 코드베이스를 조사해 `docs/project-context.md`(스택·디렉터리 구조·진입점·도메인 개념)를 생성 — 이후 단계가 매번 재조사하지 않도록
- `/tide:milestone`·`/tide:impl`이 `docs/project-context.md`가 있으면 먼저 읽어 기존 구조를 파악(조건부 — 없으면 평소대로, 하위 호환)
- `docs/conventions.md`에 "프로젝트 컨텍스트" 절 신설, README 커맨드 표·저장소 구조·설치 절을 브라운필드 동작에 맞게 갱신
- 로드맵 마일스톤 추가 — M5(`/tide:cycle` 오케스트레이션)·M6(`/tide:retro` 회고) 문서를 독립 진행 가능하도록 작성

### [v0.4.0]
- **호출명 개편**: `/tide:tide-status` → `/tide:status` — 커맨드 6종을 공식 권장 `skills/{이름}/SKILL.md` 구조로 전환하며 `tide-` 접두사 중복 제거 (기능·frontmatter 동등, 이력 보존 이동)
- 템플릿을 각 스킬에 동봉 — `skills/{milestone,impl,review}/template.md`, 참조는 `${CLAUDE_SKILL_DIR}/template.md`로 전환 (중앙 `templates/` 폐지)
- 저장소 전체 호출 표기를 실동작과 일치 — 스킬 상호 안내, 가드 차단 메시지(sh·ps1), README·conventions
- 패키지 위생 조사 종결 — 플러그인 파일 제외 수단은 공식 미지원으로 확인, 수용 결정 (근거: M3 보고서)
- README 마이그레이션 노트에 v0.3.0 → v0.4.0 호출명 변경 안내 추가

### [v0.3.0]
- **Claude Code 플러그인으로 전환** — `/plugin marketplace add Jongh/tide` → `/plugin install tide@tide` 한 번으로 커맨드 6종 + tide-guard hook이 함께 활성화 (`.claude-plugin/plugin.json`·`marketplace.json` 신설, 커맨드를 `commands/`로 이동)
- tide-guard hook을 플러그인이 직접 제공 — `hooks/hooks.json`이 `${CLAUDE_PLUGIN_ROOT}` 경로로 등록, 프로젝트별 hook 설치 절차 폐지. kickoff 내장 스크립트 제거로 가드 원본이 `hooks/` 한 곳으로 단일화
- 템플릿 파일화 — `templates/`(마일스톤·완료보고서·리뷰보고서)가 형식의 단일 원본. milestone/impl/review 커맨드가 템플릿을 직접 읽어 생성 (부재 시 폴백)
- 버전 파일 목록에 `.claude-plugin/plugin.json` 추가 (release/status/kickoff)
- README에 구버전(≤v0.2.0) 마이그레이션 노트 추가 — 수동 복사 사본의 플러그인 커맨드 섀도잉, 구 hook 설치물 중복 실행 주의

### [v0.2.0]
- `/tide-status` 신설 — 사이클 현재 상태(마일스톤/보고서/판정/버전/phase)와 다음 권장 커맨드 제시 (읽기 전용)
- tide-guard hook 도입 — `.tide/phase`가 `release`가 아닌 동안 git commit/tag/push를 기계적으로 차단 (`hooks/tide-guard.sh`·`.ps1`, `/tide-kickoff`가 대상 프로젝트 `.claude/hooks/`에 설치)
- 상태 파일(`.tide/phase`) 규약 도입 — 각 커맨드가 시작/종료 시 단계 기록, `.gitignore` 처리
- 전제조건 검사 — impl(마일스톤 문서 존재)·review(완료보고서 존재) 미충족 시 안내 후 중단
- release 프리플라이트 — 리뷰 판정 "가능" + 테스트 통과 + 워킹트리 확인 후에만 git 작업 진행
- `/tide-impl M{N}` 번호 지정 인자 — 특정 마일스톤 재실행·이어하기 지원
- 규약 문서에 상태 파일·tide-guard·단계별 강제 수단 명시

### [v0.1.0]
- tide 워크플로우 슬래시 커맨드 5종 신설: `tide-kickoff`·`tide-milestone`·`tide-impl`·`tide-review`·`tide-release`
- impl/review 단계 작업보고서(`docs/reports/M{N}-impl.md`·`M{N}-review.md`) 규약 포함
- 부수효과 분리 원칙(impl/review는 git 금지, release만 git 조작) 명문화
- `docs/conventions.md` 규약 문서 추가
<!-- --8<-- [end:notes] -->
