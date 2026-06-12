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

                          /tide:status      — 언제든 현재 위치 확인 (읽기 전용)
                          /tide:fleet       — 여러 자식 레포 교차 개요 (읽기 전용)
                          /tide:fleet-cycle — 그 순서대로 milestone→review 자동 실행 (멀티 레포, release 제외)
                          /tide:fleet-verify — 통합 훅으로 레포 간 통합 검증 (멀티 레포, verification-only)
```

`/tide:status`·`/tide:fleet`은 **사이클 단계가 아니다** — kickoff→…→release 흐름 밖에 있는
읽기 전용 보조 커맨드다(`status`는 현재 레포 위치, `fleet`은 여러 자식 레포 교차 개요).
`/tide:fleet-cycle`은 그와 짝을 이루는 **멀티 레포 자동화 보조** 커맨드다 — fleet이 읽기 전용
개요라면, fleet-cycle은 그 발견·순서대로 각 레포의 `milestone → review`를 자동 실행한다
(release는 제외 — 아래 "멀티 레포 오케스트레이션" 절).

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
- `.gitignore` 대상은 **`.tide/phase`만**이다 (로컬 상태일 뿐 커밋하지 않음). `.tide/` 전체가
  아니라 `.tide/phase`만 무시하므로, 같은 `.tide/` 아래의 **`.tide/deps`(의존성 선언)는 커밋된다**
  (위 "멀티 레포 오케스트레이션 → 의존성 선언" 절). `.tide/phase`의 의미(단계명 한 줄)와 tide-guard
  계약은 **불변**이다(1.0 안정성 정합) — 이 변경은 gitignore 범위만 좁힌다.

## tide-guard hook

- PreToolUse(Bash|PowerShell 매처) hook. **플러그인이 직접 제공한다** —
  `hooks/hooks.json`이 `${CLAUDE_PLUGIN_ROOT}/hooks/tide-guard.sh`를 등록하므로
  플러그인 설치만으로 활성화되고, 프로젝트별 설치 절차는 없다.
- 동작: `.tide/phase`가 `release`가 **아닌** 동안 `git commit` / `git tag` / `git push`
  패턴의 셸 명령을 차단한다(exit 2 + 한국어 안내 메시지: "'{phase}' 단계에서는 git
  commit/tag/push가 차단됩니다. git 작업은 /tide:release 단계에서만 허용됩니다.").
- **phase 읽기 위치**: 가드는 **명령이 실행되는 레포 루트의 `.tide/phase`를 읽는다**(단일
  레포에선 `CLAUDE_PROJECT_DIR`와 동일). 레포를 못 찾으면 `CLAUDE_PROJECT_DIR` 폴백,
  그래도 없으면 무차단. 이는 단일 레포 동작을 바꾸지 않는 **하위 호환 일반화**이며(아래
  "1.0 안정성"·"멀티 레포 / 대상 레포" 절 참조), 차단 규칙·메시지·exit 2는 불변이다.
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

## 멀티 레포 / 대상 레포

앵커링·cwd 규율의 **단일 원본**이다. 스킬·가드·실증이 모두 이 절을 따른다.

- **대상 레포(target repo) 해석**: 각 tide 커맨드는 시작 시 "대상 레포 루트"를 정한다.
  - 기본(단일 레포): 세션을 레포 루트에서 구동한 경우 대상 = 그 레포(`CLAUDE_PROJECT_DIR`).
    **현행과 동일** — 이 절은 그 동작을 바꾸지 않는다.
  - 멀티 레포: 상위 폴더에서 띄운 단일 세션이 특정 자식 레포를 작업하라고 지시받으면(인자
    또는 대화 맥락) 그 **자식 레포의 절대 루트**를 대상으로 삼는다. 인자 지원은 가산이며
    기존 `argument-hint`를 깨지 않는다(선택 인자 — 없으면 기본 동작).
- **산출물 앵커링**: `docs/milestones/`·`docs/reports/`·`.tide/phase`·버전 파일·`CHANGELOG.md`
  등 **모든 상대경로 산출물은 대상 레포 루트 기준**으로 읽고 쓴다. 상위 폴더에 흩뿌리지 않는다.
- **cwd 규율**: 모든 git·테스트·빌드 명령은 **대상 레포 루트를 작업 디렉터리로** 실행한다.
  서브에이전트 위임 시에도 대상 레포 루트를 전달해 동일 규율을 상속한다.
- **세 규약의 맞물림**: cwd를 대상 레포 루트로 두면 tide-guard의 레포 루트 해석이 같은
  루트를 가리키므로, 스킬이 쓰는 `.tide/phase`와 가드가 읽는 phase가 같은 레포로 일치한다 —
  이것이 멀티 레포 격리가 성립하는 핵심이다.
- **격리 보장**: 자식 A를 release(phase=release)해도 자식 B의 phase는 독립이며 B로의 git
  commit/tag/push는 계속 차단된다(가드가 각 레포 루트의 phase를 따로 읽으므로).

이 절의 추가는 전부 가산이다 — 단일 레포 동작은 불변이고, 대상 레포가 곧 세션 레포인
일반 경우엔 위 규율이 현행과 같은 결과를 낸다.

## 멀티 레포 오케스트레이션

상위 폴더 단일 세션에서 그 아래 여러 tide 자식 레포를 가로질러 보고 조정하는 규약의
**단일 원본**이다. fleet 커맨드·발견·계획이 모두 이 절을 따른다.

### 계층 로드맵

오케스트레이션은 한 번에 다 짓지 않고 아래 4층으로 쌓는다 — 안전·고가치인 아래층부터.

- **① 1층 — 가시성 (이번 마일스톤)**: 읽기 전용 fleet 개요 = 자식 레포 **발견** + **교차
  상태** 집계 + **advisory 계획**. git·파일 변경 없이 "어떤 레포가 어느 사이클 위치인지"와
  권장 순서만 제시한다.
- **② 2층 — 의존성/계약 선언 (활성 — 이번 마일스톤)**: 자식 레포 간 의존을 선언하는
  매니페스트(`.tide/deps`)를 도입해 **순서 인식**(어느 레포를 먼저 처리해야 하는지)을
  가능하게 한다. 아래 "의존성 선언 (`.tide/deps`)"·"의존성 인식 순서 규칙" 절이 그 단일
  원본이다.
- **③ 3층 — 교차 사이클 자동화 (활성 — 이번 마일스톤)**: 여러 레포의 `milestone → review`
  까지를 교차로 이어 실행한다(`/tide:fleet-cycle`). fleet의 발견·위상정렬·계약을 재사용해
  처리 순서(피의존 먼저)를 정하고 각 레포 루트에 앵커해 그 레포의 `/tide:cycle` 의미를 돌린다.
  **release는 제외** — 부수효과 분리상 레포별 수동으로 유지한다(아래 불변 참조). 아래
  "교차 사이클 자동화 (`/tide:fleet-cycle`)" 절이 그 단일 원본이다.
- **④ 4층 — 통합 검증 (활성 — 이번 마일스톤)**: 프로젝트 정의 통합 테스트 훅으로 자식
  레포들을 가로지르는 통합을 검증한다(`/tide:fleet-verify`). 각 레포가 각자 사이클을 통과한
  뒤 release 전에, 레포를 가로지르는 통합을 부모 레벨 훅(`.tide-fleet/integration`, 옵트인)으로
  한 번 검증한다 — **verification-only**(git·release 없음). 아래 "통합 검증 (`/tide:fleet-verify`)"
  절이 그 단일 원본이다.

이로써 오케스트레이션 로드맵 1~4층이 모두 완성된다 — 1·2·3층(가시성·의존성 선언·교차
사이클 자동화, 구현됨) 위에 이번 마일스톤이 **4층(통합 검증)**을 올린다.

### 부수효과 분리 불변

멀티 레포 토대에서도 부수효과 분리 원칙(위 "사이클" 절)은 그대로다. **2층(의존성 인식)에서도
동일하다** — 의존성 그래프로 권장 순서를 산출해도 fleet은 그 순서를 제안만 한다. **3층(교차
사이클 자동화)에서도 동일하다** — fleet-cycle은 milestone→review까지만 자동화하고 release·
cross-repo git은 자동화하지 않는다(아래 "교차 사이클 자동화" 절 참조). **4층(통합 검증)에서도
동일하다** — fleet-verify는 통합 훅(검증/테스트 명령)을 실행하되 git commit/tag/push·release·
cross-repo git을 하지 않고, **어떤 레포의 `.tide/phase`도 `release`로 쓰지 않는다**(아래 "통합
검증" 절 참조). verification-only다.

- 오케스트레이션은 **cross-repo `git commit/tag/push`를 자동화하지 않는다**. release는 항상
  **레포별 수동**(`/tide:release`)이며, tide-guard와 레포별 격리(위 "멀티 레포 / 대상 레포"
  절)가 그대로 적용된다.
- fleet은 **advisory만** 한다 — 위상정렬한 권장 처리 순서를 **제안**할 뿐 어떤 레포에도
  사이클·git을 **자동 실행하지 않는다**. 강제·자동 집행 없음. 실제 처리 순서·시점은 사용자가
  판단한다.
- fleet-cycle은 **milestone→review만 자동화**한다 — 각 레포에서 `release`·git commit/tag/push·
  cross-repo git을 자동 실행하지 않고, **어떤 레포의 `.tide/phase`도 `release`로 쓰지 않는다**.
  release 미발생의 실제 보장은 그 **규율**이며, tide-guard는 phase≠release인 레포의 git을 막는
  **백스톱**(release 차단기가 아님 — `/tide:release`가 phase=release를 먼저 써서 가드를 푼다)이다.
  fleet-cycle은 처리 전 **phase=release 잔재 레포를 제외**해 백스톱이 풀린 채 도는 것을 막는다
  (아래 "교차 사이클 자동화"의 사전 점검). 순서 release 핸드오프는 **제안**이며 release 시점·실행은
  사용자가 판단한다.

### 의존성 선언 (`.tide/deps`)

레포 간 의존을 선언하는 매니페스트의 **단일 원본**이다. fleet 스킬·실증이 이를 인용한다.

- **위치·포맷**: 각 자식 레포 루트의 `.tide/deps`. 한 줄에 **의존하는 형제 레포 디렉터리명**
  하나. 빈 줄과 `#`로 시작하는 주석 줄은 무시하고, 줄 앞뒤 공백은 트림한다.
- **선두 BOM 무시**: 파일을 읽을 때 **선두 UTF-8 BOM(`EF BB BF`)을 제거**한 뒤 줄 단위로
  파싱한다 — BOM이 붙은 첫 줄(주석·의존)도 올바로 파싱된다(Windows 편집기·`Set-Content
  -Encoding utf8`로 만든 deps 파일 내성). 주석·빈 줄 무시·트림 규칙은 그대로다.
- **의미**: "이 레포는 나열된 형제 레포들에 **의존**한다"(의존 대상이 먼저 처리되어야 한다).
  예 — `svc-orders/.tide/deps`에 `svc-auth` 한 줄 → orders는 auth에 의존, 순서상 auth가 먼저.
- **옵트인·하위 호환**: 파일이 없거나 유효 줄이 0이면 **의존 0**(현행 동작 그대로). 선언은 순수
  가산이며 단일 레포·미선언 멀티 레포 동작을 바꾸지 않는다.
- **커밋 대상**: `.tide/deps`는 레포의 **선언**이므로 **커밋한다**. 반면 `.tide/phase`는 종전대로
  로컬 상태라 gitignore다 — gitignore 범위는 `.tide/`가 아니라 **`.tide/phase`만**이다(deps는
  커밋, phase는 무시). `.tide/phase`의 의미·tide-guard 계약은 **불변**이다(1.0 안정 계약 정합).
- **계약 버전 (옵트인 확장)**: 의존 줄에 선택적 최소 버전 제약을 붙일 수 있다 —
  `<형제 레포명>[ >= <버전>]`. 예: `svc-auth >= v0.3.0`. 연산자·버전이 없으면 **이름 의존만**
  (M16 동작 그대로). 토큰 사이 공백은 트림한다.
  - **연산자**: 이번 단계는 **`>=`(최소 버전)만** 지원한다("이 버전 이상 필요" — 의존 계약의
    지배적 의미). `>`·`=`·`<=`·`<` 등 그 외 연산자는 후속(범위 밖)이며, 오면 **무시하고 경고**
    한다(안전 측 — 미달로 단정하지 않는다).
  - **버전 파싱·비교**: 버전은 `vX.Y.Z`(선행 `v` 선택)로 보고 **major.minor.patch를 숫자로**
    비교한다. 버전 파싱 불가(비표준)면 **비교를 생략하고 경고**한다(차단·위반으로 단정하지 않는다).
  - **옵트인·하위 호환**: 버전 제약 없는 줄·deps 미선언은 현행 동작 불변.

### 계약 비교 규칙

- 의존 줄에 `>= 버전` 제약이 있으면, fleet은 **의존 대상 레포의 현재 버전**(아래 "발견 규약"의
  버전 파일, 상태 조회 4번 항목)을 읽어 요구 버전과 비교한다 — `현재 >= 요구`면 만족, 아니면
  **위반(upstream behind)**.
- **순서 불변**: 위상정렬 순서·의존 그래프는 버전 제약과 무관하게 M16 그대로다(버전 제약은
  순서를 바꾸지 않는다).
- **위반 표기**: 미달이면 권장 처리 순서/advisory에 경고를 한 줄 덧붙인다 — 예:
  `svc-orders → ⚠ svc-auth 0.2.0 < 요구 >= 0.3.0 (upstream behind — svc-auth를 먼저 올릴 것)`.
- **advisory만**: 이 경고는 제안일 뿐이다 — fleet은 위반을 이유로 어떤 레포도 **차단·실행하지
  않는다**(위 "부수효과 분리 불변"). 버전 파싱 불가·미지원 연산자도 경고에 그치고 위반으로
  단정하지 않는다.

### 의존성 인식 순서 규칙

- 발견된(아래 "발견 규약": 직속·git·tide 산출물·숨김 제외) 자식 레포들의 `.tide/deps`를 모아
  **방향 그래프**(의존→피의존)를 만들고 **위상정렬**해 권장 처리 순서를 산출한다 — **피의존(먼저
  필요한 레포)이 의존하는 레포보다 앞**에 온다.
- **순환 의존**(직간접 A→B→…→A): **감지해 보고하고 상태 기반 순서로 폴백**한다(impl `(deps:)`
  순환 폴백과 동일 기조). 순환 고리에 든 레포를 명시한다.
- **미선언 레포**: 의존 0인 독립 노드로 두고 순서는 상태로 산출한다(다른 노드와 위상 관계 없음).
- **존재하지 않는 형제명**: `.tide/deps`가 발견 집합에 없는 이름을 가리키면 **무시하고 경고**한다
  (안전 측 — 잘못된 선언이 순서를 깨지 않게).
- fleet은 **advisory만** — 위상정렬 순서를 **제안**할 뿐 어떤 레포에도 사이클·git을 자동 실행하지
  않는다(위 "부수효과 분리 불변").

### 자식 tide 레포 발견 규약

"대상 부모"의 **직속 하위 디렉터리**(기본 = 세션 cwd, 선택 인자로 경로 지정 가능) 중 다음을
**모두** 만족하는 것을 자식 tide 레포로 본다.

- git 레포일 것, **그리고**
- tide 산출물을 가질 것 — `docs/milestones/` **또는** `.tide/` **또는** 버전 파일 중 하나 이상.

**이름이 `.`으로 시작하는 숨김(dot) 디렉터리는 무시한다**(`.git`·`.claude` 등) — 직속 1단계
스캔에서 제외 대상이다.

**깊은 재귀는 하지 않는다 — 직속 1단계만**(단순·예측 가능). 손주 이하 디렉터리는 보지 않는다.

### advisory 계획 규칙

각 자식 레포의 **사이클 위치(position)**를 `/tide:status`의 다음 커맨드 판단 규칙을 그대로
**재사용**해 정확히 하나로 분류한다. 이 절이 분류 taxonomy·교차 요약·advisory 인자의 **단일
원본**이며, fleet 스킬은 이를 인용한다(임의로 합산·분리하지 않는다).

- **정규 position 5종과 advisory 다음 커맨드**(각 위치는 인자까지 포함한 정확한 커맨드로 매핑):
  - `milestone 필요`(`docs/milestones/M*.md` 없음) → `/tide:milestone`
  - `impl 진행`(M{N} 있고 `M{N}-impl.md` 없음) → `/tide:impl M{N}`(반드시 마일스톤 번호 포함)
  - `review 대기`(`M{N}-impl.md` 있고 `M{N}-review.md` 없음) → `/tide:review`
  - `보완 필요`(`M{N}-review.md` 판정 "불가") → 보완 후 `/tide:impl M{N}`
  - `release 가능`(`M{N}-review.md` 판정 "가능") → `/tide:release v{추천}`
- **교차 요약은 이 5 position을 1:1로 집계한다**(합산·분리 금지). 고정 형식:
  `release 가능 N / review 대기 N / impl 진행 N / milestone 필요 N / 보완 필요 N`
  (해당 0건 버킷도 0으로 명시한다).
- **권장 처리 순서**: 위 "의존성 인식 순서 규칙"의 위상정렬 결과를 번호/화살표 목록으로 제시하고,
  각 레포의 의존 대상을 표기한다(예: `1) svc-auth  2) svc-orders(→auth)  3) svc-gateway(→auth)`).
  순환·미선언으로 폴백하면 그 사유를 한 줄로 덧붙인다. 레포별 표 + 교차 요약(5버킷)은 그대로
  유지하고 이 순서를 새 항목으로 더한다.
- **의존성 인식**(`.tide/deps` 선언 시 위상정렬, 순환·미선언은 폴백) — `.tide/deps`를 선언한
  레포들의 의존 그래프로 순서를 산출하고, 순환·미선언·미존재명은 위 규칙대로 폴백·무시한다.
  선언이 전혀 없으면 종전처럼 각 레포의 상태로만 순서를 산출한다(옵트인·하위 호환).

### 교차 사이클 자동화 (`/tide:fleet-cycle`)

3층(교차 사이클 자동화)의 **단일 원본**이다. `/tide:fleet-cycle` 스킬·실증이 이를 인용한다.
fleet이 **읽기 전용 개요**(발견·순서·계약을 보기만)라면, fleet-cycle은 **그 순서대로
milestone→review를 자동 실행**하는 행위 커맨드다 — release는 제외(아래 불변).

- **대상·발견·순서**: 대상 부모(기본 = 세션 cwd, 선택 인자로 경로)의 자식 tide 레포를
  위 "발견 규약"으로 발견(직속 1단계·git·tide 산출물·숨김 무시)하고, `.tide/deps` 위상정렬
  (위 "의존성 인식 순서 규칙")로 **처리 순서**(피의존 먼저)를 정한다. 순환이면 보고 + 상태
  기반 순서로 폴백, 미선언 레포는 독립 노드.
- **레포별 실행(앵커)**: 처리 순서대로 각 레포를 **그 레포 루트에 앵커**(위 "멀티 레포 /
  대상 레포"의 cwd 규율)해 `/tide:cycle` 의미를 실행한다 — 즉 그 레포의 보고서 상태로
  시작점을 정해(impl 보고서 없음→impl부터, 있고 review 없음→review부터, 둘 다 있음→새
  milestone) `milestone → impl → review`를 잇는다. 산출물·`.tide/phase`·테스트·서브에이전트는
  그 레포 루트 기준(레포별 격리). **release는 실행하지 않는다**(아래 불변).
- **release 제외(불변)**: fleet-cycle은 **milestone→review까지만** 자동화한다. 어떤 레포에서도
  `release`를 실행하지 않고, **어떤 레포의 `.tide/phase`도 `release`로 쓰지 않으며**, git
  commit/tag/push·cross-repo git을 자동 실행하지 않는다. release 미발생의 실제 보장은 이
  **규율**(release를 호출하지도 phase=release를 쓰지도 않음)이다. tide-guard는 phase≠release인
  레포의 git을 막는 **백스톱**이지 release 차단기가 아니다(`/tide:release`는 git 전에
  phase=release를 먼저 써서 가드를 푼다). release는 아래 "핸드오프"로 사용자에게 넘긴다.
- **사전 점검(필수)**: 처리 시작 전 각 자식 레포의 `.tide/phase`를 읽어, **`release`로 남아 있는
  레포(이전 중단된 수동 release의 잔재)는 처리에서 제외하고 경고**한다 — 그 레포는 가드가 풀린
  상태라 사이클을 돌리지 않는다(수동 정리: 그 레포 phase를 idle로). 이로써 백스톱이 풀린 채
  도는 경로를 막는다.
- **계약 인식(M17)**: 레포 X가 의존 Y에 `>= 버전` 계약을 두고 Y가 **upstream-behind**(위
  "계약 비교 규칙")면, X의 사이클은 돌리되 release 핸드오프에서 X를 **"contract-blocked:
  Y를 먼저 release/upgrade 필요"**로 표기한다(X를 release-ready로 단정하지 않는다).
- **실패·중단 처리**: 한 레포의 사이클이 중단되면(전제조건 미충족·테스트 실패·review 판정
  "불가") 그 레포를 **"중단"으로 기록**하고, 위상정렬상 **그 레포에 의존하는 downstream
  레포는 건너뛴다**(upstream 미완 → downstream 처리 보류, 사유 기록). 그와 무관한 독립 레포는
  계속 진행한다(전체 중단이 아니라 부분 진행 + 명확한 보고). 각 레포 사이클 자체의 중단
  처리는 `/tide:cycle` 규칙을 그대로 따른다.
- **출력(집계)**: ① **처리 순서 표** — 레포명 | 시작 단계 | 도달 단계 | review 판정/추천
  버전 | 비고(중단·skip·contract-blocked). ② **의존성 순서 release 핸드오프** — review "가능"인
  레포를 위상정렬 순서로 `1) /tide:release vX.Y.Z (repo)` 나열하되, contract-blocked·중단·
  downstream-skip은 사유와 함께 보류로 표기한다. release는 사용자 몫임을 명시한다.
- **부수효과 분리 불변 재확인**: fleet-cycle은 milestone→review만 자동화하고, release·cross-repo
  git은 자동화하지 않는다(위 "부수효과 분리 불변" 절). 순서·핸드오프는 **제안**이며 release
  시점·실행은 사용자가 판단한다.
- **발견 0 강등**: 자식 tide 레포를 못 찾으면 단일 레포로 graceful 강등한다(현재 레포
  `/tide:cycle` 권유) — 단일 레포·미선언 동작 불변(옵트인 가산).

### 통합 검증 (`/tide:fleet-verify`)

4층(통합 검증)의 **단일 원본**이다. `/tide:fleet-verify` 스킬·실증이 이를 인용한다. 자식 레포가
각자 사이클을 통과해도 "각 서비스가 각자 통과"와 "서비스들이 **함께** 동작"은 다르다 —
fleet-verify는 release 전에 레포를 가로지르는 통합을 프로젝트 정의 훅으로 한 번 검증한다.
**verification-only**(git·release 없음, 아래 불변).

**통합 훅 (`.tide-fleet/integration`, 옵트인·parent-level)** — 레포 간 통합 검증 명령의 단일
원본이다.

- **위치·형식**: 대상 부모(기본 = 세션 cwd, 선택 인자로 경로)의 `.tide-fleet/integration` 파일.
  내용은 통합 검증으로 실행할 **명령(들)**(셸 명령 한 줄 이상, 빈 줄·`#`로 시작하는 주석 무시,
  선두 UTF-8 BOM 제거). **부모 cwd에서 실행**한다(예: `docker compose up -d && npm run
  integration-test`).
- **parent-level(설계 결정)**: 의존 선언(`.tide/deps`)은 레포별(탈중앙, 각 레포가 자기 의존을
  선언)이지만, **통합은 단일 레포가 소유하지 않는 cross-repo 개념**(어느 한 레포의 통합이 아니라
  fleet 전체의 통합)이므로 훅은 **대상 부모 레벨**에 둔다.
- **옵트인·하위 호환**: 파일이 없거나 유효 줄이 0이면 **통합 훅 미선언** — fleet-verify는
  "통합 훅 미선언, 검증 생략"을 안내하고 graceful 종료한다. 단일 레포·미선언 동작은 현행 그대로.
- **발견 무시**: `.tide-fleet/`는 **숨김(dot) 디렉터리**라 fleet 발견(직속·git·tide 산출물·숨김
  무시, 위 "발견 규약")에서 자식 레포로 잡히지 않는다 — 1~3층과 충돌하지 않는다.

**`/tide:fleet-verify` — 통합 검증 실행**

- **발견·대상**: fleet 규약으로 자식 tide 레포를 발견(직속 1단계·git·tide 산출물·숨김 무시)해
  통합 대상 레포 목록을 보고한다. 발견 0이면 단일 레포로 graceful 강등(현재 레포 `/tide:status`
  권유).
- **실행·보고**: 통합 훅을 **부모 cwd에서 실행**하고 결과를 보고한다 — **exit 0 = 통합 pass**,
  비0 = **통합 fail**(실패 출력 요약 + 관련 레포). 훅 미선언이면 검증 생략 안내.
- **verification-only(불변)**: fleet-verify는 git commit/tag/push·release·cross-repo git을 하지
  않고, **어떤 레포의 `.tide/phase`도 `release`로 쓰지 않는다**. 통합 훅도 검증/테스트 명령이어야
  하며(git·release 금지 — 훅 작성자 책임), tide-guard는 phase≠release인 레포의 git을 막는
  **백스톱**(release 차단기가 아닌 phase 잠금 — 위 fleet-cycle 백스톱 설명과 동일)이다. 단, **통합
  훅이 자식 레포에서 git을 시도하고 그 자식이 stale phase=release**(중단된 수동 release 잔재)면 가드가
  풀릴 수 있으므로(M18 stale-release 사각), 훅에 **cross-repo git을 두지 않으며** 의심 시 처리 전
  자식 phase의 release 잔재를 점검·정리한다(fleet-cycle "사전 점검"과 동일 취지).
- **출력**: ① 통합 대상 레포 목록(발견), ② 통합 훅 명령(요약), ③ **통합 결과**(pass/fail + 실패
  시 요약), ④ 다음 안내(pass면 "이제 release 핸드오프 순서대로 수동 `/tide:release`", fail이면
  "통합 수정 후 재검증").

**fleet-cycle ↔ fleet-verify 흐름**

- 권장 순서: **`/tide:fleet-cycle`**(각 레포 milestone→review 의존성 순서 자동) →
  **`/tide:fleet-verify`**(통합 검증) → 통합 pass면 fleet-cycle의 release 핸드오프 순서대로
  **수동 `/tide:release`**.
- fleet-cycle은 통합을 자동 실행하지 않는다 — release 핸드오프 출력에 "release 전
  `/tide:fleet-verify`로 통합 확인(통합 훅 선언 시)" 안내만 두고, fleet-verify가 별도 명시 호출이다.

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
| fleet | 파일 생성·수정 / `.tide/phase` 변경 / git 작업 | 프롬프트 |
| fleet-cycle | git commit/tag/push (release·cross-repo git 비자동화) | 프롬프트 + hook(git) |
| fleet-verify | git commit/tag/push / release / 어떤 레포 phase=release 쓰기 (verification-only) | 프롬프트 + hook(git) |
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
  phase는 **명령의 레포 루트 기준**으로 읽으며(단일 레포에선 `CLAUDE_PROJECT_DIR`와 동일),
  레포를 못 찾으면 `CLAUDE_PROJECT_DIR` 폴백 — 이는 하위 호환 일반화로 단일 레포 동작을
  바꾸지 않는다(상세는 "멀티 레포 / 대상 레포" 절).
- **보고서·마일스톤 형식**: 마일스톤 문서·완료보고서·리뷰보고서·회고 문서의 섹션 구조(위 해당 절).

호환을 깨지 않는 추가(새 커맨드·새 선택 필드·새 검증 단계 등)와 정리·견고화는 minor·patch로
계속한다 — 안정 선언은 "이제부터 위 계약을 함부로 깨지 않는다"는 약속이지 기능 동결이 아니다.

- **가산 커맨드 — `/tide:fleet` (v1.2.0부터)**: 위 8종 커맨드의 호출명·역할은 그대로 안정이며,
  여기에 읽기 전용 멀티 레포 개요 커맨드 `/tide:fleet`이 **v1.2.0부터 가산**으로 더해진다.
  새 커맨드 추가는 1.0 안정성 절이 명시적으로 허용하는 하위 호환 minor 가산이다 — 기존 8종의
  안정 계약을 약화하지 않는다(상세 규약은 위 "멀티 레포 오케스트레이션" 절).
- **가산 커맨드 — `/tide:fleet-cycle` (v1.5.0부터)**: 읽기 전용 fleet과 별개로, 여러 자식 레포의
  `milestone → review`를 의존성 순서로 자동 실행하는 **행위** 커맨드 `/tide:fleet-cycle`이
  **v1.5.0부터 가산**으로 더해진다 — **release는 제외**(milestone→review만, git 금지). 위 8종
  안정 계약·읽기 전용 fleet 서술은 그대로이며, 새 행위 커맨드도 부수효과 분리 불변(release·
  cross-repo git 비자동화)을 지킨다(상세 규약은 위 "교차 사이클 자동화" 절).
- **가산 커맨드 — `/tide:fleet-verify` (v1.6.0부터)**: fleet·fleet-cycle과 별개로, 자식 레포를
  가로지르는 통합을 부모 레벨 훅(`.tide-fleet/integration`, 옵트인)으로 검증하는 커맨드
  `/tide:fleet-verify`가 **v1.6.0부터 가산**으로 더해진다 — **verification-only**(통합 훅은 검증/
  테스트 명령이며 git commit/tag/push·release·cross-repo git 없음, 어떤 레포 phase=release 미기록).
  위 8종 안정 계약·읽기 전용 fleet·fleet-cycle 서술은 그대로이며, 이 커맨드도 부수효과 분리
  불변을 지킨다(상세 규약은 위 "통합 검증" 절).
<!-- --8<-- [end:body] -->
