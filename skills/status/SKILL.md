---
description: "[tide] 사이클 현재 상태 보고 + 다음 권장 커맨드 제시 (읽기 전용)"
---
tide 사이클의 현재 상태를 읽기 전용으로 보고해줘.

**대상 레포**: 시작 시 대상 레포 루트를 정한다 — 기본은 세션 레포(현행 단일 레포 동작 그대로),
상위 폴더 단일 세션에서 특정 자식 레포를 지시받으면 그 자식 레포 루트. 아래 확인 항목의 모든
경로(마일스톤·보고서·버전 파일·`.tide/phase`)는 **대상 레포 루트 기준**으로 조회한다(읽기 전용 —
파일·phase 변경 없음). 상세는 `docs/conventions.md`의 "멀티 레포 / 대상 레포" 절.

확인 항목:
1. docs/milestones/M*.md 중 최대 번호 — 마일스톤 번호와 제목
2. docs/reports/M{N}-impl.md 존재 여부
3. docs/reports/M{N}-review.md 존재 여부 — 있으면 릴리즈 판정(가능/불가)과 추천 버전
4. 버전 파일(Cargo.toml / package.json / pyproject.toml / .claude-plugin/plugin.json 등)의 현재 버전
5. .tide/phase의 현재 값 (파일 없으면 "없음")

보고 형식: 위 항목을 간단한 표나 목록으로 보여주고, 마지막 줄에 다음 권장 커맨드를
구체 인자까지 포함해 한 줄로 제시해줘 (예: `다음: /tide:release v0.2.0`).

다음 커맨드 판단 규칙:
- 마일스톤 문서 없음 → /tide:kickoff(골격 미비 시) 또는 /tide:milestone
- impl 보고서 없음 → /tide:impl
- review 보고서 없음 → /tide:review
- 판정 "가능" → /tide:release v{추천 버전}
- 판정 "불가" → 보완 후 /tide:impl M{N} 재실행 또는 /tide:milestone 으로 후속 계획

다음은 절대 수행하지 마: 파일 생성·수정 / git 작업 (.tide/phase도 변경하지 않는 읽기 전용 커맨드)
