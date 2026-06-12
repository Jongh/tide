---
description: "[tide] 상위 폴더의 여러 자식 tide 레포를 교차 집계 + 조정 계획 제시 (읽기 전용, 멀티 레포)"
argument-hint: "[부모 폴더 경로(선택, 생략 시 현재 세션 위치)]"
---
상위 폴더 아래 여러 자식 tide 레포의 사이클 상태를 한 번에 **읽기 전용**으로 집계하고,
조정된 다음 행동 계획을 advisory로 제시해줘. 대상 부모: "$ARGUMENTS" (생략 시 현재 세션 위치)

이 커맨드는 멀티 레포 오케스트레이션의 **1층(가시성)**이다 — 계층 로드맵·발견/계획 규약의
단일 원본은 `docs/conventions.md`의 "멀티 레포 오케스트레이션" 절이다. fleet은 그 규약을 따른다.

## 자식 tide 레포 발견

대상 부모의 **직속 하위 디렉터리**(기본 = 현재 세션 위치, 인자로 경로 지정 가능) 중 다음을
**모두** 만족하는 것을 자식 tide 레포로 본다:
- git 레포일 것 (`<dir>/.git` 존재 또는 `git -C <dir> rev-parse --show-toplevel` 성공), **그리고**
- tide 산출물을 가질 것 — `docs/milestones/` 또는 `.tide/` 또는 버전 파일(`package.json`/
  `Cargo.toml`/`pyproject.toml`/`.claude-plugin/plugin.json` 등) 중 하나 이상.

**깊은 재귀는 하지 않는다 — 직속 1단계만**. 손주 이하 디렉터리는 보지 않는다.

이름이 `.`으로 시작하는 **숨김 디렉터리는 무시**한다(`.git`·`.claude` 등).

발견이 **0개**면: "자식 tide 레포 0개 — 단일 레포 세션으로 보임"을 안내하고, 현재 레포에 대해
`/tide:status`를 권한 뒤 종료한다(graceful 강등 — 단일 레포에서 안전).

## 레포별 상태 조회 (각 레포 루트 기준, 읽기 전용)

발견된 각 자식 레포에서 `/tide:status`의 확인 항목을 **그 레포 루트 기준**으로 조회한다:
1. `docs/milestones/M*.md` 중 최대 번호 — 마일스톤 번호·제목
2. `docs/reports/M{N}-impl.md` 존재 여부
3. `docs/reports/M{N}-review.md` 존재 여부 — 있으면 릴리즈 판정(가능/불가)·추천 버전
4. 버전 파일의 현재 버전
5. `.tide/phase`의 현재 값 (파일 없으면 "없음")

어떤 레포에서도 **파일·`.tide/phase`·git을 일절 변경하지 않는다**(읽기 전용).

## 출력

1. **레포별 표** — 레포명 | 마일스톤(M{N} 제목) | phase | 판정/추천 버전 | 버전
2. **교차 요약** — position과 1:1로 집계한 고정 5버킷을 한 줄로 표기한다(임의 합산 금지,
   해당 0건 버킷도 0으로 명시): `release 가능 N / review 대기 N / impl 진행 N / milestone 필요 N / 보완 필요 N`
3. **advisory 다음 행동 계획** — 레포별로 `/tide:status`의 "다음 커맨드 판단 규칙"을 적용해
   각 레포의 position을 정확히 하나로 분류하고 `레포명 → 다음: /tide:...`를 한 줄씩 제시한다.
   position→커맨드 매핑은 **인자를 포함**해 다음과 같이 고정한다:
   - `milestone 필요` → `/tide:milestone`
   - `impl 진행` → `/tide:impl M{N}` (반드시 최신 마일스톤 번호 포함)
   - `review 대기` → `/tide:review`
   - `보완 필요`(판정 "불가") → 보완 후 `/tide:impl M{N}`
   - `release 가능`(판정 "가능") → `/tide:release v{추천}`
   - **의존성 기반 정렬은 미지원**임을 명시한다(2층 전까지). fleet은 레포 간 의존을 알지
     못하므로 순서는 **각 레포의 상태로만** 산출하며, 실제 처리 순서는 사용자가 판단하도록
     advisory로 둔다 — 단정하지 않는다.

## 부수효과 분리 (불변)

fleet은 **제안만** 한다 — 어떤 레포에도 사이클을 자동 실행하거나 cross-repo git을 하지 않는다.
release는 끝까지 레포별 수동(`/tide:release`)이며, tide-guard와 레포별 격리가 그대로 적용된다.

다음은 절대 수행하지 마: 파일 생성·수정 / 어느 레포의 `.tide/phase` 변경 / git 작업
(읽기 전용 커맨드 — `/tide:status`·`/tide:retro`와 동일 원칙)
