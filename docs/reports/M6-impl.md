# M6 완료보고서 (impl)

## 개요

M6 "`/tide:retro` 회고"의 5개 태스크(M6-T01~T05)를 구현했다. 누적된 마일스톤·보고서를
가로질러 반복 문제·수용 트레이드오프·미반영 후속을 집계하는 읽기 전용 스킬
`skills/retro/SKILL.md`(+ `template.md`)를 신설하고, 산출물을 갱신형 단일 문서
`docs/reports/retro.md`로 정의했다. conventions·README·project-context에 retro를 반영했고,
드라이런으로 M1~M5 보고서를 집계한 실제 `retro.md`를 생성해 집계 규칙을 검증했다.
이 구현은 `/tide:cycle`을 수동 실행(도그푸딩)하는 흐름의 impl 단계로 수행됐다.

## 태스크별 수행 내용

- **M6-T01** — `skills/retro/SKILL.md` 신설. frontmatter는 기존 스킬과 동일 형식. `/tide:status`와
  같은 **읽기 전용 원칙**을 명시 — 회고 문서 하나(`docs/reports/retro.md`)만 생성/갱신하고
  그 외 파일·`.tide/phase`·git에 손대지 않음. 신규 스킬 등록 필요 여부는 M5-T01에서 확인한
  자동 발견(매니페스트에 `skills` 배열 없이도 노출)을 재사용 → 매니페스트 무수정.
- **M6-T02** — 집계 규칙 4종을 본문에 정의: ① 리뷰 차단/권장 이슈의 주제 군집(2사이클 이상
  반복), ② 사소·수용 항목의 트레이드오프와 사유, ③ "미해결·후속" 메모가 이후 마일스톤에서
  반영/미반영됐는지 추적, ④ 릴리즈 판정·버전 추이. 입력은 `docs/milestones/M*.md` +
  `M*-impl.md`·`M*-review.md`, 자기 자신(`retro.md`)은 제외. 입력이 1사이클뿐이면 이득이
  작음을 명시하는 폴백 포함.
- **M6-T03** — 산출물을 `docs/reports/retro.md` **갱신형 단일 문서**로 정함(보고서 디렉터리
  일관성 + 이력 보존). 회고 시점마다 최상단에 새 섹션 누적. 형식은 milestone/impl/review
  패턴을 재사용해 `skills/retro/template.md`로 **동봉**(반복 사용 가치 있음) — 본문은
  `${CLAUDE_SKILL_DIR}/template.md` 참조 + 폴백 6개 섹션.
- **M6-T04** — `docs/conventions.md`: 보고서 절에 회고 문서 추가, 단계별 금지 행위 표에
  `retro` 행(회고 문서 외 수정·phase 변경·git 금지) 추가. `README.md`: 커맨드 표에 `/tide:retro`
  추가, 스킬 수 7→8종(설치·구조·자동완성 3곳). `docs/project-context.md` 디렉터리 표도 8종(+retro,
  template 동봉 목록에 retro 추가)으로 갱신.
- **M6-T05** — 드라이런: 자동 러너가 없으므로 retro 규칙을 **실제 M1~M5 보고서에 적용**해
  `docs/reports/retro.md`를 생성. 반복 군집 4개(설치 캐시 괴리·문서 동기화·마켓플레이스 경로·
  Windows hook), 수용 트레이드오프 6건, 후속 추적 표(반영 7 / 미반영 3), 버전 추이(v0.2.0~
  v0.6.0 전부 minor·연속 "가능")가 실제 보고서 내용과 맞게 집계됨을 확인. 실노출(재설치 후
  새 세션 호출)은 release 후 도그푸딩 필요(아래 메모).

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `skills/retro/SKILL.md`, `skills/retro/template.md` |
| 추가 | `docs/reports/retro.md` (드라이런 산출물 — 회고 문서) |
| 수정 | `docs/conventions.md` (보고서 절 + 금지 행위 표) |
| 수정 | `README.md` (커맨드 표 + 스킬 7→8종 3곳) |
| 수정 | `docs/project-context.md` (디렉터리 표 스킬 8종) |
| 삭제 | (없음) |

> M6 문서의 "(등록 필요 시) plugin.json/marketplace.json 수정"은 자동 발견 확인으로 불발생.

## 테스트 결과

자동 테스트 러너 없는 플러그인 프로젝트(검증 = 재설치 드라이런). 가능한 정적/행위 검증 수행, 통과:

- **frontmatter 동형성** — `skills/retro/SKILL.md`가 기존 스킬과 동일한 `description` +
  `argument-hint` 형식. 통과.
- **읽기 전용 원칙 명시** — 본문 마지막에 "회고 문서 외 파일·`.tide/phase`·git 금지"를 명시,
  status와 동일 원칙. 통과.
- **집계 규칙 행위 검증** — retro 규칙을 M1~M5 실제 보고서에 적용해 `retro.md` 생성.
  후속 추적의 반영/미반영 분류가 실제 이후 마일스톤과 합치(예: M1 hook 셀프설치→M2 반영,
  M1 차단 메시지 한국어화→미반영). 통과.
- **문서 일관성** — conventions·README·project-context의 retro 반영 및 8종 카운트 확인. 통과.

실노출(재설치 후 새 세션 `/tide:retro` 호출)은 플러그인 캐시가 release+재설치 전까지 구
스킬을 쓰므로 이 단계에서 불가 — M1~M5와 동일한 구조적 제약, release 후 도그푸딩에서 실증.

## 미해결·후속 메모

1. **실노출 드라이런 미수행** — `/tide:retro`가 재설치 후 새 세션에서 노출·호출되고, retro
   외 파일·git에 손대지 않는지(완료 기준 1·4)는 release 후 도그푸딩으로 실증해야 한다.
2. **회고 입력에 retro.md 자기 포함 방지** — 규칙에 "자기 자신 제외"를 명시했으나, 회고가
   누적되며 retro.md가 커지면 다음 회고 시 입력 비용이 늘 수 있다. 필요 시 "직전 회고 메모만
   참조" 같은 최적화를 차기 후보로.
3. **이번 도그푸딩 자체가 M5 완료 기준 1·2의 부분 충족** — 수동 실행이지만 `/tide:cycle`의
   impl→review 체이닝·phase 기록·release 직전 정지 흐름을 실제로 밟았다(설치 노출만 미검증).
