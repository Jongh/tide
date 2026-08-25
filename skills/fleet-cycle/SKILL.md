---
description: "[tide] 발견된 자식 tide 레포의 milestone→review를 의존성 순서로 교차 자동 실행 + 순서 release 핸드오프 (release 제외, 멀티 레포)"
argument-hint: "[부모 폴더 경로(선택, 생략 시 현재 세션 위치)]"
---
상위 폴더 아래 발견된 자식 tide 레포들의 `milestone → impl → review`를 **의존성 순서**로
교차 자동 실행하고, 마지막에 **순서 있는 release 핸드오프**를 제시해줘. 대상 부모:
"$ARGUMENTS" (생략 시 현재 세션 위치)

이 커맨드는 멀티 레포 오케스트레이션의 **3층(교차 사이클 자동화)**이다 — 발견·위상정렬·
계약·실패 처리·출력 규약의 단일 원본은 `docs/conventions.md`의 "멀티 레포 오케스트레이션"
절이다. fleet-cycle은 그 규약을 따른다. `/tide:fleet`이 같은 발견·순서를 **읽기 전용**으로
보여주는 반면, fleet-cycle은 그 순서대로 milestone→review를 **자동 실행**하는 행위 커맨드다.

**release는 이 자동화에 포함하지 않는다** — git 작업을 하는 유일한 단계이므로(부수효과 분리·
tide-guard) cross-repo에서 더 강하게 제외한다. fleet-cycle은 milestone→review까지만 돌리고
release는 아래 release 핸드오프로 사용자에게 넘긴다(`docs/conventions.md`의 "교차 사이클 자동화" 절).

## 자식 tide 레포 발견·처리 순서

발견·위상정렬은 **fleet 규약을 그대로 재사용**한다(`skills/fleet/SKILL.md`·`docs/conventions.md`
단일 원본):
- **발견**: 대상 부모의 **직속 1단계** 하위 디렉터리 중 git 레포(`<dir>/.git` 또는
  `git -C <dir> rev-parse --show-toplevel` 성공)이고 tide 산출물(`docs/milestones/` 또는
  `.tide/` 또는 버전 파일)을 가진 것. **깊은 재귀 없음**. `.`으로 시작하는 **숨김 디렉터리는 무시**.
- **처리 순서(피의존 먼저)**: 각 레포 루트의 `.tide/deps`(선두 BOM 제거 후 줄 단위 파싱,
  `<형제명>[ >= <버전>]`, 빈 줄·`#` 주석 무시)를 읽어 의존 그래프를 만들고 **위상정렬**한다 —
  **의존 대상(먼저 필요한 레포)이 그에 의존하는 레포보다 앞**에 온다(예: orders가 auth에
  의존하면 auth 먼저 처리). (M16)
  - **순환 의존**(직간접 A→…→A): **감지해 보고**(고리 레포명 명시)하고 **상태 기반 순서로 폴백**.
  - **미선언 레포**(deps 없음/유효 줄 0): 의존 0인 **독립 노드** — 다른 노드와 위상 제약 없음.
  - **미존재명**(발견 집합에 없는 이름)을 가리키는 줄은 **무시하고 경고**(순서를 깨지 않게).

발견이 **0개**면: "자식 tide 레포 0개 — 단일 레포 세션으로 보임"을 안내하고, 현재 레포에 대해
`/tide:cycle`을 권한 뒤 종료한다(graceful 강등 — 단일 레포에서 안전).

## 레포별 실행 (앵커 — 처리 순서대로)

위상정렬 처리 순서대로 각 레포를 **그 레포 루트에 앵커**(M13 cwd 규율 — `docs/conventions.md`
"멀티 레포 / 대상 레포" 절)해 `/tide:cycle` 의미(`skills/cycle/SKILL.md`)를 실행한다. 한 레포의
산출물(`docs/milestones/`·`docs/reports/`)·`.tide/phase`·테스트·서브에이전트는 **그 레포 루트
기준/cwd**로만 수행한다(레포별 격리).

각 레포에서 시작점은 **그 레포의 보고서 상태**로 정하며, 분기를 여기서 다시 열거하지 않는다.
확인 항목과 읽는 법의 단일 원본은 `docs/conventions.md`의 "상태 확인 항목과 시작점 판단 (선언)" 절
(`status-items:` 선언)이고, 시작점 분기의 단일 원본은 `skills/cycle/SKILL.md`의 "시작점 판단" 절이다 —
**마일스톤 문서가 하나도 없는 경우를 포함해** 그쪽 분기를 그대로 적용한다. 대상 레포에 규약 파일이
없으면 플러그인 설치본을 읽는다(도달 규칙은 `docs/conventions.md`의 "멀티 레포 / 대상 레포" 절).
분기를 이 파일에 복제하면 한쪽이 늘 때 다른 쪽이 조용히 낡는다 — 실제로 「마일스톤 0개」 분기가
`/tide:cycle`에 생긴 뒤에도 이 파일의 사본에는 없었다(M52 리뷰 차단 3).

그 시작점에서 `milestone → impl → review`를 잇되, 각 단계 진입 직전 **그 레포의 `.tide/phase`**에
단계명을 기록하고(레포별 격리), 단계별 기존 규칙·전제조건·deps 기반 병렬/순차(impl)는
`/tide:cycle` 규칙을 그대로 따른다. 한 레포 사이클이 끝나면 그 레포 `.tide/phase`를 `idle`로
되돌린다. **release는 어떤 레포에서도 실행하지 않는다**(아래 불변).

## release 제외 (불변)

fleet-cycle은 **milestone→review까지만** 자동화한다. **어떤 레포에서도 `release`를 실행하지 않고,
어떤 레포의 `.tide/phase`도 `release`로 두지 않으며, git commit/tag/push·cross-repo git을 자동
실행하지 않는다.** release 미발생의 실제 보장은 이 **규율**(fleet-cycle이 release를 호출하지도,
phase=release를 쓰지도 않음)이다 — release는 아래 "release 핸드오프"로 사용자에게 넘긴다.

> **tide-guard의 역할(정확히)**: 가드는 명령 레포의 `.tide/phase`가 `release`가 **아닌 동안** git
> commit/tag/push를 막는 **phase 잠금**이지 release **차단기가 아니다**(`/tide:release`는 git 전에
> phase=release를 먼저 써서 가드를 **푼다**). 즉 가드는 fleet-cycle이 각 레포 phase를
> milestone/impl/review로 두는 한 그 레포의 git을 막는 **백스톱**이 되지만, 어떤 자식 레포가
> 이전에 **중단된 수동 release의 잔재로 phase=release로 남아 있으면** 가드가 그 레포의 git을
> 풀어줄 수 있다. 그래서 아래 **사전 점검**이 필수다.

**사전 점검 (필수)**: 처리 시작 전, 발견된 각 자식 레포의 `.tide/phase`를 읽는다. 어떤 레포가
`release`로 남아 있으면(이번 실행이 쓴 게 아니라 **이전 중단된 수동 release의 잔재**) 그 레포는
**처리에서 제외하고 경고**한다 — 예: `⚠ <repo>: phase=release 잔재 — fleet-cycle 제외(수동 정리:
그 레포 .tide/phase를 idle로)`. 가드가 풀린 레포에서는 사이클을 돌리지 않는다(안전 측).

## 계약 인식 (M17 — upstream-behind)

레포 X가 의존 Y에 `>= 버전` 계약을 두고 Y가 **upstream-behind**(Y의 현재 버전 < 요구 버전,
fleet의 계약 버전 비교 규칙 그대로)면: X의 사이클은 **돌리되**, release 핸드오프에서 X를
**`contract-blocked: Y를 먼저 release/upgrade 필요`**로 표기한다(X를 release-ready로 단정하지
않음). 위상정렬 순서·의존 그래프는 버전 제약과 **무관하게 불변**이다 — contract-blocked는 순서를
바꾸지 않고 핸드오프 표기일 뿐이다. 한쪽 버전이 파싱 불가면 비교를 생략하고 경고한다.

## 실패·중단 처리

한 레포의 사이클이 **중단**되면(전제조건 미충족·테스트 실패·review 판정 "불가"; 각 레포 사이클
자체의 중단 처리는 `/tide:cycle` "중단 처리" 규칙 그대로 — 그 레포 `.tide/phase`를 `idle`로
되돌림):
- 그 레포를 **"중단"으로 기록**한다.
- 위상정렬상 **그 레포에 의존하는 downstream 레포는 건너뛴다**(upstream 미완 → downstream
  처리 보류, **사유 기록**). downstream의 downstream도 연쇄로 skip.
- 그와 **무관한 독립 레포는 계속 진행**한다(전체 중단이 아니라 **부분 진행 + 명확한 보고**).

## 출력 (집계)

① **처리 순서 표** — 한 행에 한 레포:

| 레포 | 시작 단계 | 도달 단계 | review 판정 / 추천 버전 | 비고 |
|---|---|---|---|---|

`비고`에 **중단 / skip(사유) / contract-blocked(사유)**를 표기한다.

② **의존성 순서 release 핸드오프** — review 판정 **"가능"**인 레포를 **위상정렬 순서**로 나열한다:

```
1) /tide:release vX.Y.Z (repo-a)
2) /tide:release vX.Y.Z (repo-b)
```

contract-blocked·중단·downstream-skip 레포는 **사유와 함께 보류**로 표기한다(예:
`보류 — svc-orders: contract-blocked (svc-auth를 먼저 release/upgrade)`,
`보류 — svc-notify: skip (upstream svc-orders 중단)`). **release는 사용자 몫**임을 명시한다 —
순서·핸드오프는 **제안**이며 release 시점·실행은 사용자가 판단한다.

release 전 `/tide:fleet-verify`로 자식 레포 통합을 확인한다(통합 훅 선언 시). (fleet-cycle은
통합을 자동 실행하지 않는다 — 안내만; fleet-verify가 별도 명시 호출.)

## 부수효과 분리 (불변)

fleet-cycle은 milestone→review만 자동화하고, 순서·핸드오프는 **제안**이다. release 시점·실행은
사용자가 판단한다.

다음은 **절대 수행하지 마**: release / git commit / git tag / git push / cross-repo git /
어떤 레포의 `.tide/phase`를 `release`로 쓰기. milestone→review만 자동화한다 — release는 순서 있는
핸드오프로 사용자에게 넘긴다. (tide-guard는 phase≠release인 레포의 git을 막는 **백스톱**이며,
위 "사전 점검"이 phase=release 잔재 레포를 제외해 백스톱이 풀린 채 도는 것을 막는다.)
