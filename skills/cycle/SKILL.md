---
description: "[tide] milestone→impl→review 자동 체이닝 (deps 기반 병렬/순차, release 직전 정지)"
argument-hint: "[마일스톤 주제 또는 M번호 (선택)]"
---
한 번의 호출로 `milestone → impl → review`를 순서대로 이어 실행해줘. "$ARGUMENTS"가
있으면 시작점 결정에 쓴다 (주제 문자열이면 새 마일스톤 주제로, `M{N}` 번호면 그
마일스톤을 대상으로 한 impl→review 재실행으로).

`release`는 이 사이클에 **포함하지 않는다** — git 작업을 하는 유일한 단계이므로
부수효과 분리 원칙·tide-guard와 맞게 사용자에게 넘긴다 (docs/conventions.md).

**대상 레포**: 시작 시 대상 레포 루트를 정한다 — 기본은 세션 레포(현행 단일 레포 동작 그대로),
상위 폴더 단일 세션에서 특정 자식 레포를 지시받으면 그 자식 레포 루트. **체이닝하는 모든 단계가
같은 대상 레포 루트**를 일관되게 쓴다 — 산출물(`docs/`·`.tide/phase`)·테스트·서브에이전트는 그
레포 루트 기준/cwd로 수행한다. 상세·격리 규약은 `docs/conventions.md`의 "멀티 레포 / 대상 레포" 절.

docs/project-context.md가 있으면 먼저 읽어 기존 구조·스택을 파악한 뒤 진행해줘
(없으면 평소대로).

## 시작점 판단

`M{N}`은 `docs/milestones/M*.md` 중 가장 큰 번호의 마일스톤을 가리킨다.

- 인자가 `M{N}` 번호 → 그 마일스톤 문서를 대상으로 **impl 단계부터** 시작 (재실행/이어하기)
- 인자가 주제 문자열 → 그 주제로 **milestone 단계부터** 시작 (새 마일스톤 생성)
- 인자 없음 → 가장 큰 번호 마일스톤의 **보고서 상태**로 시작점을 정한다:
  - impl 보고서 없음 → 그 마일스톤으로 **impl 단계부터**
  - impl 보고서는 있고 review 보고서 없음 → 그 마일스톤으로 **review 단계부터** (사이클 이어하기)
  - impl·review 보고서 모두 있음(직전 사이클 완료) → **milestone 단계부터** (새 마일스톤)

## 단계 체이닝

각 단계는 진입 직전 `.tide/phase`에 단계명을 기록하고(.tide/ 없으면 생성), 해당 단계의
기존 규칙·전제조건을 사이클 안에서도 **그대로** 따른다. 한 단계가 끝나면 다음 단계로
넘어간다. 사이클 전체가 끝나면 `.tide/phase`를 `idle`로 되돌린다.

1. **milestone** (시작점이 milestone일 때만): `.tide/phase`=`milestone`. 현재 맥락·인자
   주제로 `docs/milestones/M{N}.md`를 생성 (규칙은 /tide:milestone과 동일 —
   `skills/milestone/template.md` 구조, 태스크 ID·`(deps:)` 표기).
2. **impl**: `.tide/phase`=`impl`. 전제조건 — 대상 마일스톤 문서 존재(없으면 중단,
   아래 "중단 처리"). 마일스톤 태스크를 **deps 규칙**(다음 절)대로 구현하고 테스트를
   실행한 뒤 `docs/reports/M{N}-impl.md`를 작성 (`skills/impl/template.md` 구조).
3. **review**: `.tide/phase`=`review`. 전제조건 — `docs/reports/M{N}-impl.md` 존재.
   비판적 리뷰 후 `docs/reports/M{N}-review.md`를 작성하고 릴리즈 판정·추천 버전을 낸다
   (`skills/review/template.md` 구조).

> 이 구간에는 git 작업이 없어야 한다 (commit/tag/push는 review까지 어느 단계도 하지
> 않음). tide-guard가 `release`가 아닌 phase에서 git을 차단하는 동작과 충돌하지 않는다.

## deps 기반 병렬/순차 (impl 단계)

마일스톤 문서의 태스크 목록에서 각 태스크의 `(deps: M{N}-T01, …)` 표기를 파싱해
의존 그래프를 만들고 다음 규칙으로 스케줄링한다:

- **의존 없는 태스크** = 서로 독립 → 병렬 착수 가능 (한 묶음으로 함께 진행)
- **의존 있는 태스크** → 선행 태스크가 모두 끝난 뒤 착수 (위상 정렬 순서)
- 같은 단계(선행이 모두 완료된) 태스크들끼리는 다시 병렬 묶음으로 처리

이상 표기 폴백 — 다음을 감지하면 **보고하고 전체를 순차(파일에 적힌 순서)로** 진행한다:

- **순환 의존**: A가 B에, B가 A에 (직간접) 의존
- **미존재 의존 ID**: `(deps:)`가 가리키는 태스크 ID가 목록에 없음
- 표기가 모호하거나 파싱 불가

**실제 병렬 실행**: impl 단계는 `/tide:impl`과 동일하게 같은 레벨의 독립 태스크를
서브에이전트로 **동시 디스패치**한다(같은 메시지에 복수 Agent 호출 = 동시 실행, 레벨
간 배리어). 메커니즘·파일 충돌 안전장치(예상 변경 파일 겹침 → 겹치는 것만 순차)·결과
병합·폴백은 `skills/impl/SKILL.md`의 "병렬 디스패치" 절이 단일 원본이다. 사이클 안에서도
같은 폴백(Agent 부재·레벨 단일 태스크·deps 이상 → 순차)과 tide-guard 정합(서브에이전트도
phase=impl이라 git 차단)이 적용된다.

## 중단 처리

한 단계의 전제조건이 미충족이거나 그 단계가 실패하면 **사이클 전체를 중단**한다.
중단 시: `.tide/phase`를 `idle`로 되돌리고, **어느 단계에서 왜 멈췄는지**와 사용자가
취할 다음 행동을 보고한다.

- milestone 시작점인데 맥락이 부족해 마일스톤을 못 만들면 → 중단, 주제 보강 요청
- impl 전제조건(마일스톤 문서) 미충족 → 중단, `/tide:milestone` 안내
- review 전제조건(impl 보고서) 미충족 → 중단, `/tide:impl` 안내
- 테스트 실패 등 차단 이슈로 진행 불가 → 중단, 사유와 함께 보고

## 종료

- review 판정이 **"가능"** → 사이클을 정상 종료하고, `.tide/phase`를 `idle`로 되돌린 뒤
  추천 버전으로 **`/tide:release vX.Y.Z`를 다음 단계로 안내** (release는 직접 실행하지 않음).
- review 판정이 **"불가"** → `idle`로 되돌리고 보완 태스크 또는 `/tide:milestone` 후속
  계획을 안내.

마지막에 각 단계의 산출물(생성/갱신된 마일스톤·보고서)과 최종 판정을 요약해 보고해줘.

다음은 절대 수행하지 마: git commit / git tag / git push (release는 사용자 몫)
