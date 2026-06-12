# M20 리뷰보고서 (review)

## 개요

M20(연산자 확장 + 자산 정리·견고화 + 2.0 안정 계약 재기준)을 **적대적 검증 워크플로우**(4 차원 ×
독립 검증, 회의적 검증자가 기본 반박)로 리뷰했다. **확정 8건(major 2·minor 5·nit 1) + 반박 2건**.
확정 8건은 모두 **리뷰에서 직접 수정**하고 양 셸 라이브 실증으로 회귀 고정했다. M20은 그 논지 자체가
*계약 정합*(2.0 재기준)이라, 참조 구현이 계약과 모순(#1)하거나 공개 사이트가 stable 커맨드 수를
부정(#6)한 채로는 release할 수 없다는 판단에서 in-review 수정을 택했다.

**최종 판정: 가능 — 추천 v2.0.0 (major, 안정 계약 재기준).**

## 비판점 및 수정

### 차단 (수정 전 release 불가) — 모두 in-review 수정 완료

**#1 [major] 미지 연산자가 의존명을 오염해 토포 엣지를 무성 드롭** (compat) — 이름 추출 정규식이
`[<>=]` 첫 글자에서 잘라, `auth ~> v0.1.0`의 `>`까지 먹어 이름이 `auth ~`가 되고 발견 집합의 `auth`와
불일치해 의존 엣지가 사라졌다. 규약("미지 연산자 → 무시·**이름 의존 유지**")과 정면 모순. 기존 unkop
테스트는 *잘못된 이유*로 통과(파싱된 이름 불일치로 `none`)해 결함을 가렸다.
- **수정**: `tests/fleet/run.sh`·`run.ps1`의 이름 추출을 **첫 공백 토큰 기반**으로 교체(무공백 형은
  연산자에서 절단), 연산자 추출은 **둘째 토큰이 알려진 연산자일 때만** 인정(아니면 none). 어떤
  연산자(미지 포함)든 이름이 보존돼 토포 엣지가 유지된다. 회귀 테스트 추가(아래 #4와 공동).

**#6 [major] 공개 사이트가 "8종"이라 fleet 3종을 문서화하며 동시에 부정** (docs) —
`site/docs/commands.md`·`getting-started.md`가 v1.2.0(9종)·2.0(11종) 갱신을 놓쳐 "8종"으로 남았는데,
M20이 같은 nav에 fleet 3종을 상술하는 오케스트레이션 가이드를 실어 모순이 노출됐다. 배포 워크플로우엔
paths 필터가 없어 라이브로 렌더된다.
- **수정**: `site/docs/commands.md`(서문·한눈에 보기 표를 11종, fleet 3종 행 + 커맨드별 절 추가 +
  가이드 포인터)·`getting-started.md`(11종) 정합.

### 권장 (수정함) — minor

- **#3 [minor] `==`에 satisfied만 있고 violation 테스트 없음**(operator) → `eqeq_bad`(`auth == v0.3.0`)
  픽스처 + 위반 단언 양 셸 추가.
- **#4 [minor] 기호 없는 미지 연산자(`auth ~ v0.1.0`)도 엣지 유실**(operator, #1과 동일 근원) → #1 수정이
  공통 해결. `unksym` 픽스처 + (read_deps=`auth`·토포 엣지 보존) 단언 양 셸 추가.
- **#5 [minor] git-verb 가드라일이 정석 cross-repo 형태(`git -C <dir> push`)를 미탐**(guardrail) →
  `tests/fleet-verify/run.sh`·`run.ps1`의 매칭을 `git` 토큰과 변이 동사 사이 인자를 허용하도록 확장,
  `git -C <dir> push`·`git --git-dir=… commit` 경고 + 읽기 전용 `git status` 비경고(오탐 방지) 픽스처 추가.
- **#2 [minor] `⚠ contract` 위반 메시지 예시가 정본(conventions)과 불일치**(compat) — SKILL.md·M20.md
  예시가 `위반` 형으로 드리프트(정본은 `⚠ contract … < 요구 >= …`) → `skills/fleet/SKILL.md`·
  `docs/milestones/M20.md` 예시를 conventions 형식으로 통일 + "형식 단일 원본은 conventions" 포인터 명시.
- **#7 [minor] project-context의 "tests/fleet … M14에서 더해질 예정"(과거 미래형)이 같은 파일 원장과
  모순**(docs) → `docs/project-context.md`를 tests/fleet·fleet-cycle·fleet-verify 현존 + M20 M10+ 픽스처
  반영으로 수정.

### 사소 (수정함) — nit

- **#8 [nit] orchestration.md가 연산자 목록·경고 문자열을 conventions에서 축자 복제**(docs, 드리프트
  위험) → 가이드에 "정확한 형식의 단일 원본은 conventions" deferral 노트 추가(예시는 illustrative로 유지).

### 반박 (결함 아님)

- **"`⚠ upstream behind`→`⚠ contract` 라벨 변경으로 동작 불변 과장"** — fleet은 읽기 전용 advisory이고
  바뀐 건 사람 대상 경고 라벨(계약 surface·exit·순서·그래프 불변), major 범프에서 허용되며 impl 보고서에
  이미 명시. 결함 아님.
- **"sh vs ps1 가드라일 대문자 경계 분기"** — grep `-i`가 부정 브래킷(`[^a-z]`)도 폴딩해 양 셸이 모든
  토큰을 동일 분류. 검증자의 경험적 주장(`releaseR→sh=yes`)이 실제 툴체인에서 재현 안 됨. 반박.

## 검증

| 러너 | 결과 |
|---|---|
| `tests/fleet/run.sh` | exit 0 |
| `tests/fleet/run.ps1` | **PASS=41 FAIL=0** (이전 35 +6: `==` 위반·미지 연산자 2종 이름 보존·토포 엣지 보존) |
| `tests/fleet-verify/run.sh` | exit 0 |
| `tests/fleet-verify/run.ps1` | **PASS=29 FAIL=0** (이전 25 +4: cross-repo `git -C`·`--git-dir`·읽기전용 비경고) |

- `run.ps1` 두 파일 비ASCII 바이트 **0**, `run.sh` 무BOM 유지.
- 잔여 "8종"은 전부 맥락상 정확("앞의 8종은 단일 레포", "기존 8종 + …→11종 stable") — 언더카운트 0.
- 옛 메시지 형식(`위반 >=`) 잔재 0. 제외 용어: 변경/사이트 노출 파일(commands·getting-started·
  orchestration·M20) **0**.
- 테스트 README(`tests/fleet`·`tests/fleet-verify`) 시나리오 수·신규 케이스 설명 정합.

## 릴리즈 판정

**가능** — 추천 **v2.0.0 (major)**.

근거: 확정 8건이 전부 in-review 수정·회귀 고정됐고, 수정 후 차단 결함 0. 변경은 전부 하위 호환
가산·정리(단일 레포·미선언 deps·기존 11종 동작 불변)이며, 2.0은 **동작 파괴 없는 안정 계약 재기준**
(11종 커맨드 + 오케스트레이션 규약 stable 동결)으로 v1.0.0의 "안정 선언" major와 동형이다. 적대적
검증이 짚은 "참조 구현↔계약 모순"·"공개 사이트↔stable 선언 모순"이라는 2.0의 자기 논지를 깨는 두
major를 제거해, 재기준이 실제로 정합한다.

## 다음 단계

`.tide/phase`를 `idle`로 되돌리고 사용자에게 **`/tide:release v2.0.0`**을 넘긴다(release는 git을 만지는
유일한 단계 — 부수효과 분리·tide-guard). 후속(비차단): M21 후보 "오케스트레이션 발견성"(retro 기록됨,
2.0 후 첫 minor).
