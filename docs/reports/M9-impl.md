# M9 완료보고서 (impl)

## 개요

M9 "진짜 병렬 실행"의 6개 태스크(T01~T06)를 구현했다. `/tide:impl`과 `/tide:cycle`의
impl 단계가 deps 위상에서 독립 태스크를 **서브에이전트로 동시 디스패치**하도록 규약을
명문화했다 — 병렬 메커니즘·파일 충돌 안전장치·결과 병합·폴백을 `skills/impl/SKILL.md`에
단일 원본으로 정의(T01~T03)하고, `skills/cycle/SKILL.md`의 "구현 판단에 맡긴다" 문장을
그 참조로 교체(T04)했으며, conventions·README·project-context에 반영(T05)했다. 검증 중
**v0.9.0에서 새어든 잠재 회귀 1건**(changelog 노트의 literal "porpoise" 단어가 단일
원본화로 사이트에 유입)을 발견·수정했다(T06).

## 태스크별 수행 내용

- **M9-T01** — `skills/impl/SKILL.md`에 "병렬 디스패치" 절 신설(병렬 단일 원본). 같은
  위상 레벨의 무의존 태스크 ≥2개를 **한 메시지에서 동시 Agent 호출**로 위임, 레벨 간
  배리어. 서브에이전트 전달 컨텍스트(마일스톤 경로·project-context·태스크 ID/상세/완료
  기준·부수효과 분리 상속)와 반환 계약(수행 내용·실제 변경 파일·테스트·이슈)을 명시.
  "진행" 항목도 "독립 태스크는 병렬 디스패치"로 갱신.
- **M9-T02** — 같은 절에 파일 충돌 안전장치 추가: 디스패치 전 마일스톤 "파일 변경
  요약"으로 예상 변경 집합 추정 → 겹치는 태스크만 순차 폴백, 비겹침은 병렬 유지.
  conventions의 "파일 비중첩" 권장과 연결. 워크트리 격리는 선택·기본 비활성으로 명시
  (병합 복잡도 때문).
- **M9-T03** — 결과 병합(서브에이전트 반환을 단일 `M{N}-impl.md`로, 형식 불변)·부분
  실패(다른 결과 보존 + 메인 재시도 → 실패 시 중단 보고)·폴백 조건(Agent 부재·레벨
  단일·deps 이상)·tide-guard 정합(서브에이전트 phase=impl → git 차단)을 정의.
- **M9-T04** — `skills/cycle/SKILL.md`의 deps 절 말미 *"실제 병렬 실행 수단은 구현 판단에
  맡긴다 …"* 를 삭제하고 **"impl 단계는 `/tide:impl`과 동일하게 서브에이전트 동시
  디스패치, 메커니즘은 impl 스킬 단일 원본 참조"** 로 교체. 사이클 내 폴백·가드 정합 명시.
- **M9-T05** — `docs/conventions.md`(사이클 절: "독립 태스크를 서브에이전트로 동시
  디스패치"로 갱신 + 마일스톤 절: 파일 비중첩이 병렬 안전과 직결됨 추가),
  `README.md`(cycle 설명·커맨드 표), `docs/project-context.md`(도메인 개념에 "병렬
  디스패치" 항목) 반영. conventions 변경은 snippets로 사이트에 자동 반영됨.
- **M9-T06** — 자동 발견(매니페스트 무수정)·정적 일관성(impl 단일 원본, 나머지 참조)·
  strict 빌드를 확인. **검증 중 회귀 발견**(아래 테스트 결과) 후 수정·재검증. release-후
  병렬 도그푸딩 시나리오를 정의(아래 후속 메모).

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | (없음) |
| 수정 | `skills/impl/SKILL.md`(병렬 디스패치 단일 원본), `skills/cycle/SKILL.md`(deps 절 교체·참조화), `docs/conventions.md`(사이클·마일스톤 절), `README.md`(cycle 설명·커맨드 표 + 회귀 수정), `CHANGELOG.md`(회귀 수정), `docs/project-context.md`(병렬 디스패치 개념) |
| 삭제 | (없음 — cycle "구현 판단에 맡긴다" 문장은 교체) |

> `.claude-plugin/plugin.json`·`marketplace.json` 무수정 — 신규 파일 없이 기존 스킬만
> 수정(자동 발견, M5~M8과 동일).

## 테스트 결과

자동 테스트 러너 없는 프롬프트·규약 플러그인. 정적/빌드 검증 수행:

- **매니페스트 무수정** — `git status`에 `plugin.json`·`marketplace.json` 없음. 통과.
- **정적 일관성** — impl 스킬이 병렬 단일 원본이고 cycle·conventions·project-context가
  이를 참조함을 확인. 서술 모순 없음. 통과.
- **strict 빌드** — venv(mkdocs 1.6.1)에서 `mkdocs build -f site/mkdocs.yml --strict`
  exit 0, conventions의 "동시 디스패치" 서술이 snippets로 사이트 `conventions`에 반영됨
  확인. 통과.
- **회귀 발견·수정(중요)** — 빌드 출력에서 `porpoise`가 `changelog/index.html`·검색
  인덱스에 **1건 검출**. 원인: **v0.9.0 CHANGELOG 노트의 검증 문장 "빌드 출력 porpoise
  0건 실증"에 literal 단어 "porpoise"가 포함**돼, M8이 도입한 changelog 단일 원본화
  (`CHANGELOG.md:notes` 인클루드)를 통해 사이트로 유입된 것. 이 노트는 M8 **release
  단계**에서 추가돼 M8 impl 검증(0건) 이후라 사후 미검증으로 빠져나갔다(회고가 지목한
  "release-후 미검증" 패턴의 실례). 수정: `CHANGELOG.md`·`README.md`의 해당 문장을
  "빌드 출력 **외부 귀속 표기** 0건 실증"으로 리워딩. **재빌드 후 사이트 porpoise 0건
  회복** 확인(README line 3 masthead는 사이트 비대상이라 무관).

## 미해결·후속 메모

1. **병렬 동작 실호출 미실증(구조적)** — M9는 대부분 단일 SKILL 편집이라 자기적용으로
   병렬 이득을 못 보인다(T02·T03이 같은 `impl/SKILL.md`를 고쳐 M9 자체도 순차 구현됨).
   **release-후 도그푸딩 시나리오**: M9 이후 *독립 태스크 2개 이상(파일 비중첩)*을 가진
   첫 마일스톤을 `/tide:cycle`로 돌려, 같은 레벨이 동시 서브에이전트로 디스패치되고 결과가
   단일 보고서로 병합되는지 확인한다. 활성 스킬 캐시가 release+재설치 전엔 구 버전이라
   실호출은 그 이후(M1~M8과 동일 제약).
2. **단일 원본화의 부작용 일반화** — 이번 회귀는 "검증을 서술하는 단어가 곧 콘텐츠가
   된다"는 단일 원본화의 함정이다. CHANGELOG/conventions 노트에서 제외 대상 용어(예:
   외부 저장소명)를 **메타 서술로도 쓰지 않는** 규칙을 conventions에 한 줄 둘 가치가
   있다(차기 후보). 당장은 리워딩으로 해소.
3. **워크트리 격리 경로는 미설계** — 파일 경쟁이 불가피한 병렬에 대한 worktree+병합
   경로는 "선택·기본 비활성"으로만 남겼다. 실제 병합 절차를 프롬프트로 안전히 기술하는
   건 별도 마일스톤 후보.
4. **README↔CHANGELOG 노트 중복은 여전** — 이번 회귀 수정도 두 파일에 각각 적용했다.
   M8부터 추적된 이 축의 단일화는 차기 후보로 잔존.
