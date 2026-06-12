# M20 완료보고서 (impl)

## 개요

마일스톤 M20(에픽 마감 — 계약 연산자 확장 + 자산 정리·견고화 + 2.0 안정 계약 재기준)의 네 태스크를
**4-way 병렬**(파일 비중첩)로 구현했다. 결과: (1) `.tide/deps` 계약 비교가 `>=`만 → **`>=`·`>`·`=`/`==`·
`<=`·`<` 전체 연산자**(가산), (2) `/tide:fleet-verify`에 **통합 훅 git-verb 가드라일(advisory)**, (3) "1.0
안정성" → **"2.0 안정성" 재기준**(11종 커맨드 + 오케스트레이션 규약 stable 동결, 동작 무파괴), (4) 백로그
이월 8항목 **명시 종결** + **오케스트레이션 사용 가이드(`docs/orchestration.md`)** 신설·사이트 노출. 양 셸
라이브 실증 전 항목 통과.

## 태스크별 결과

### M20-T01 — 규약(연산자·가드라일·2.0 재선언)
- **파일**: `docs/conventions.md`
- 계약 비교 규칙을 전체 연산자(`>=`·`>`·`=`/`==`·`<=`·`<`)로 확장 — `vX.Y.Z` 숫자 비교, 불만족 시 의존 레포
  줄에 `⚠ contract`(op·요구·현재 명시), **알 수 없는 연산자/비표준 버전 → 무시·경고**(위반 단정 안 함),
  **위상정렬 순서·그래프 불변**(M16·M17).
- `/tide:fleet-verify` 통합 검증에 **git-verb 가드라일(advisory)** 추가 — 훅 실행 전 git/release 토큰 점검·
  경고, **강제 차단 아님**(검증 훅에 git 필요한 변형 여지 — major-safe).
- "1.0 안정성" → **"2.0 안정성"** 재선언 — 커맨드 11종 + 오케스트레이션 규약 stable 동결, `.tide/phase`/
  guard·보고서·마일스톤 형식은 1.0 계약 유지(불변), v1.x 가산 이력 보존, 깨는 변경은 3.0에서만. 본문 마커
  `[start:body]`~`[end:body]` 안쪽, intro(line 3) 불변.

### M20-T02 — 스킬(연산자 비교·가드라일)
- **파일**: `skills/fleet/SKILL.md`, `skills/fleet-verify/SKILL.md`
- `fleet`: 계약 버전 비교를 전체 연산자로 확장(연산자별 만족/위반 표기, 알 수 없는 연산자/비표준 버전
  경고, 순서 불변). stale 참조(`⚠ upstream behind` → `⚠ contract`) 정합.
- `fleet-verify`: 통합 훅 실행 전 git-verb 점검·경고(advisory) 추가.
- 읽기 전용·부수효과 분리·verification-only 불변 서술 유지.

### M20-T03 — 라이브 실증(연산자·다중자리·가드라일)
- **파일**: `tests/fleet/run.sh`·`run.ps1`·`README.md`, `tests/fleet-verify/run.sh`·`run.ps1`·`README.md`
- `tests/fleet`: semver 비교기를 3원 비교(`semver_cmp`/`SemverCmp`) + 연산자 평가(`eval_op`/`EvalOp`)로
  일반화 — 각 연산자 satisfied/violation 짝, 알 수 없는 연산자→none, 비표준 버전→skip. **다중 자리
  마일스톤(M2/M9/M10) 픽스처** 추가(최신=M10 자연 정렬; ps1 `Classify`의 사전순 버그도 정수 정렬로 수정).
  기존 시나리오 유지 → **35건**.
- `tests/fleet-verify`: `has_git_verb`/`HasGitVerb` + 가드라일 분류(훅에 git/release 토큰→warn, clean→ok,
  미선언→skip). 기존 시나리오 유지 → **25건**. (git 토큰은 픽스처 문자열, 미실행.)

### M20-T04 — 문서 정합·이월 종결·오케스트레이션 가이드
- **파일**: `README.md`, `docs/project-context.md`, `docs/orchestration.md`(신규), `site/docs/orchestration.md`
  (신규), `site/mkdocs.yml`
- `README`: "2.0 안정성"(11종 stable·오케스트레이션 규약·v1.x 이력 보존), 커맨드 표 11종 정합, gitignore
  마이그레이션 노트, 가이드 포인터. masthead 외부 귀속 보존.
- `project-context`: 오케스트레이션 1~4층·11종·2.0 반영 + **이월 항목 처분 원장**(fix/수용/환경-이월).
- **`docs/orchestration.md`(신규·단일 원본)**: 멀티 레포 실전 사용 가이드 — 발견→deps/계약 선언→
  fleet-cycle→fleet-verify→순서 release 5단계 + `svc-auth/orders/gateway/notify` 워크드 예제(의존 그래프·
  upstream-behind·통합 훅) + 안전 불변 요지. 규약은 conventions 참조(중복 규정 회피).
- **사이트**: `site/docs/orchestration.md`가 snippets로 본문 인클루드 + `site/mkdocs.yml` nav 항목 추가.

## 이월 항목 종결 원장 (M20 정규 spec)

| 항목 | 처분 | 결과 |
|---|---|---|
| 다중 자리 마일스톤(M10+) 픽스처 | **fix** | tests/fleet에 M2/M9/M10 픽스처 추가, ps1 정렬 버그 동시 수정 |
| gitignore 마이그레이션 노트 | **fix** | README에 한 항목 추가 |
| 통합 훅 git-verb 가드라일 | **fix** | conventions·fleet-verify·tests(advisory) 구현 |
| 참조 버전 파일 범위·pre-release | **fix(문서)** | project-context 원장에 명시 |
| jq 추출 분기 실증 | **환경-이월** | 로컬 jq 부재 — 정적 검토 + 재실행 노트, 원장에 종결 |
| 워크트리 격리 병합 경로 | **수용** | impl 선택적 고급 경로로 문서화, 별도 구현 불요 |
| README masthead 외부 귀속 | **수용** | 사이트만 제외·저장소 원본 보존(원 의도) |
| 브라우저 런타임·병렬 폴백·retro 자기입력 | **환경-이월/수용** | 세션·배포 수동 검증 영역, 원장에 종결 |

→ 로드맵 미반영 0, 백로그 명시 종결.

## 테스트 결과

| 러너 | 결과 |
|---|---|
| `tests/fleet/run.sh` | exit 0 |
| `tests/fleet/run.ps1` | **PASS=35 FAIL=0** (exit 0) |
| `tests/fleet-verify/run.sh` | exit 0 |
| `tests/fleet-verify/run.ps1` | **PASS=25 FAIL=0** (exit 0) |

- 전체 연산자 각 satisfied/violation, 알 수 없는 연산자→none, 비표준 버전→skip, 다중 자리 M10 픽스처,
  git-verb 가드라일(warn/ok/skip) 모두 검증. 기존 시나리오(발견·5분류·요약·BOM·토포·순환·verification-only·
  skill-coupling·.tide-fleet 무시) 유지.
- `run.ps1` 두 파일 비ASCII 바이트 **0**, `run.sh` 무BOM. 활성 가드 규율 준수(러너에 git 차단 동사 없음).

## 부수효과 분리 확인

- impl 단계 전체에서 git commit/tag/push 미수행(서브에이전트 포함, phase=impl).
- 가드라일·연산자·정리 변경은 전부 하위 호환 가산 — 단일 레포·미선언 deps·기존 11종 동작 불변.
- 신규 가이드 본문 단일 원본 → 사이트 빌드 출력 제외 용어 검증이 커버. M20 신규 파일 제외 용어 **0**.

## 제외 용어 스캔

`docs/orchestration.md`·`site/docs/orchestration.md`·`docs/milestones/M20.md` 등 **신규/사이트 노출 텍스트에
제외 용어 0**. 잔존 occurrence는 과거 마일스톤·보고서(사이트 미노출)와 README/conventions intro(마커 밖,
사이트 전용 도입부로 대체 — 원 의도)뿐.

## 변경 파일

- 수정: `docs/conventions.md`(T01); `skills/fleet/SKILL.md`·`skills/fleet-verify/SKILL.md`(T02);
  `tests/fleet/run.sh`·`run.ps1`·`README.md`·`tests/fleet-verify/run.sh`·`run.ps1`·`README.md`(T03);
  `README.md`·`docs/project-context.md`·`site/mkdocs.yml`(T04)
- 추가: `docs/orchestration.md`·`site/docs/orchestration.md`(T04, 오케스트레이션 사용 가이드);
  `docs/milestones/M20.md`(마일스톤); `docs/reports/M20-impl.md`(본 보고서)

## 미해결·후속

- 없음(차단 이슈 0). jq 분기는 환경-이월로 원장 종결, 워크트리/masthead는 수용으로 종결.
- 다음: review에서 2.0 재기준의 호환 무파괴·연산자 가산·가이드 정합을 비판적으로 검증.
