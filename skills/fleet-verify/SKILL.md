---
description: "[tide] 발견된 자식 tide 레포의 통합을 부모 레벨 통합 훅으로 검증 + pass/fail 보고 (verification-only, 멀티 레포)"
argument-hint: "[부모 폴더 경로(선택, 생략 시 현재 세션 위치)]"
---
상위 폴더 아래 발견된 자식 tide 레포들을 가로지르는 **통합**을, 대상 부모에 선언된
**통합 훅**으로 부모에서 한 번 실행해 **통합 pass/fail**을 보고해줘. 대상 부모:
"$ARGUMENTS" (생략 시 현재 세션 위치)

이 커맨드는 멀티 레포 오케스트레이션의 **4층(통합 검증)**이다 — 발견·통합 훅·실행/보고·
verification-only 불변·출력의 단일 원본은 `docs/conventions.md`의 "멀티 레포 오케스트레이션"
절이다. fleet-verify는 그 규약을 따른다. 3층(`/tide:fleet-cycle`)이 각 레포의
milestone→review를 의존성 순서로 자동 실행하는 반면, fleet-verify는 "각 레포가 각자 통과"
이후 "레포들이 **함께** 동작"하는지를 release 핸드오프 직전에 한 번 검증하는 보조 커맨드다.

**fleet-verify는 verification-only다** — 통합 훅(검증/테스트 명령)을 부모에서 돌려 결과만
보고하고, git·release·cross-repo git을 하지 않으며 어떤 레포의 `.tide/phase`도 `release`로
쓰지 않는다(아래 "verification-only 불변"). 통합 훅이 없으면 "통합 검증 생략"으로 graceful
강등한다(옵트인).

## 자식 tide 레포 발견 (통합 대상)

발견은 **fleet 규약을 그대로 재사용**한다(`skills/fleet/SKILL.md`·`docs/conventions.md`
단일 원본):
- **발견**: 대상 부모(기본 = 현재 세션 위치, 인자로 경로 지정 가능)의 **직속 1단계** 하위
  디렉터리 중 git 레포(`<dir>/.git` 존재 또는 `git -C <dir> rev-parse --show-toplevel` 성공)
  이고 tide 산출물(`docs/milestones/` 또는 `.tide/` 또는 버전 파일)을 가진 것. **깊은 재귀
  없음 — 직속 1단계만**. 이름이 `.`으로 시작하는 **숨김 디렉터리는 무시**한다(`.git`·`.claude`·
  `.tide-fleet` 등 — 따라서 통합 훅 디렉터리는 자식 레포로 잡히지 않는다).

이 목록이 **통합 대상 레포**(통합이 함께 동작해야 하는 자식들)다.

발견이 **0개**면: "자식 tide 레포 0개 — 단일 레포 세션으로 보임"을 안내하고, 현재 레포에 대해
`/tide:status`를 권한 뒤 종료한다(graceful 강등 — 단일 레포에서 안전).

## 통합 훅 읽기 (`.tide-fleet/integration`, 옵트인·parent-level)

통합은 어느 한 레포가 소유하지 않는 **cross-repo 개념**(fleet 전체의 통합)이라, 통합 훅은
레포별이 아니라 **대상 부모 레벨**에 둔다 — 대상 부모의 `.tide-fleet/integration` 파일.
규약 단일 원본은 `docs/conventions.md`의 "멀티 레포 오케스트레이션" 절이다.
- **선두 BOM 제거**: 파일을 읽을 때 **선두 UTF-8 BOM(`EF BB BF`)을 먼저 제거**한 뒤 줄 단위로
  파싱한다(Windows 편집기·`Set-Content -Encoding utf8`로 만든 BOM 붙은 첫 줄도 올바로 처리되게).
- **파싱**: **빈 줄과 `#`로 시작하는 주석 줄은 무시**하고, 남은 줄들이 통합 검증으로 실행할
  **셸 명령(들)**이다(한 줄 이상 — 예: `docker compose up -d && npm run integration-test`).
- **옵트인·하위 호환**: 파일이 없거나 유효 줄이 0이면 **통합 훅 미선언** — "통합 훅 미선언 —
  통합 검증 생략"을 안내하고 graceful 종료한다. 단일 레포·미선언 fleet 동작은 현행 그대로.

`.tide-fleet/integration`은 **읽기만** 한다 — 생성·수정하지 않는다.

## 실행·보고

통합 훅 명령(들)을 **대상 부모 cwd에서 실행**한다(개별 레포가 아니라 부모에서 — 통합은
fleet 전체 개념). 결과는 **exit 코드**로 판정한다:
- **exit 0 = 통합 pass**.
- **비0 = 통합 fail** — 실패한 명령의 출력을 요약하고, 관련된(통합 대상) 레포를 함께 적는다.

훅 명령이 여러 줄이면 순서대로 실행하고, 하나라도 비0이면 거기서 멈춰 fail로 본다(통합
미성립). 통합 훅은 **검증/테스트 명령**이어야 하며(아래 verification-only — 훅 작성자 책임),
fleet-verify는 훅을 실행만 할 뿐 그 안에 git/release가 들어 있어선 안 된다.

## verification-only (불변)

fleet-verify는 **통합 훅(검증/테스트)을 실행해 pass/fail을 보고**할 뿐, 부수효과를 내지
않는다. 통합 훅도 **검증/테스트 명령**이어야 한다 — 훅 작성자는 git/release를 훅에 넣지
말아야 한다(impl/review가 테스트는 돌리되 git은 안 하는 것과 동일 원칙).

> **tide-guard 백스톱(정확히 — M18과 동일)**: 가드는 명령 레포의 `.tide/phase`가 `release`가
> **아닌 동안** git을 막는 **phase 잠금**이지 release **차단기가 아니다**. fleet-verify는 어떤 레포
> phase도 `release`로 쓰지 않으므로 **fleet-verify 자체로는** 가드가 풀리지 않는다. 단, **통합 훅이
> 자식 레포에서 git을 시도하고 그 자식이 이전 중단된 수동 release의 잔재로 phase=release로 남아
> 있으면** 가드가 그 레포의 git을 풀어줄 수 있다(M18 stale-release 사각). 따라서 **통합 훅에는
> cross-repo git을 두지 말고**(검증/테스트 명령만), 의심되면 처리 전 자식 레포 `.tide/phase`에
> release 잔재가 없는지 점검해 정리한다(fleet-cycle "사전 점검"과 동일 취지).

다음은 **절대 수행하지 마**: release / git commit / git tag / git push / cross-repo git /
어떤 레포의 `.tide/phase`를 `release`로 쓰기. fleet-verify는 통합 검증(부모에서 훅 실행 +
pass/fail 보고)만 한다 — release는 fleet-cycle의 순서 있는 핸드오프로 사용자에게 넘긴다.

## 출력

① **통합 대상 레포 목록** — 발견된 자식 tide 레포(통합이 함께 동작해야 하는 대상).
② **통합 훅 명령(들)** — `.tide-fleet/integration`에서 읽은 실행 명령 요약.
③ **통합 결과** — **pass**(exit 0) / **fail**(비0 — 실패 출력 요약 + 관련 레포). 훅 미선언이면
   "통합 훅 미선언 — 통합 검증 생략" 표기.
④ **다음 안내**:
   - pass → "이제 release 핸드오프 순서대로 수동 `/tide:release`"(fleet-cycle이 제시한 의존성
     순서대로 사용자가 레포별 release).
   - fail → "통합 수정 후 재검증"(통합을 고친 뒤 다시 `/tide:fleet-verify`).

## 권장 흐름

권장 순서: **`/tide:fleet-cycle`**(각 레포 milestone→review 의존성 순서 자동) →
**`/tide:fleet-verify`**(통합 검증) → 통합 pass면 fleet-cycle의 release 핸드오프 순서대로
**수동 `/tide:release`**. fleet-verify는 통합을 자동 release로 잇지 않는다 — pass/fail 보고와
다음 안내까지만 하고 release 시점·실행은 사용자가 판단한다.
