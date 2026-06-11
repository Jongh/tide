---
description: "[tide] 최근 구현 비판적 리뷰 + 리뷰보고서 + 릴리즈 판정 (커밋·태그·푸시 없음)"
---
최근 구현된 작업 내용을 비판적으로 리뷰하고, 릴리즈 가능한 상태인지 보고해줘.

시작 전 검사: 대상 마일스톤(docs/milestones/M*.md 중 최대 번호 M{N})의 완료보고서
docs/reports/M{N}-impl.md가 존재하는지 확인해줘.
없으면 리뷰하지 말고, /tide-impl 을 먼저 실행하라고 안내한 뒤 중단해줘.

검사를 통과하면 .tide/phase 파일에 `review` 한 줄을 기록해줘 (.tide/ 디렉터리가 없으면 생성).

리뷰 항목:
- 요청/마일스톤 대비 구현 완성도
- 코드 구조 일관성 (기존 패턴 이탈 여부)
- 버그·엣지케이스 누락
- 테스트 통과 여부
- 추천 버전 (major / minor / patch)

차단 이슈는 수정까지 진행해도 됨. 단, 다음은 절대 수행하지 마:
git commit / git tag / git push

리뷰보고서 작성 — docs/reports/M{N}-review.md (대상 마일스톤 번호 M{N}에 맞춤):
- ${CLAUDE_PLUGIN_ROOT}/templates/review-report.md 템플릿을 읽어 그 구조 그대로 작성
  ({} 자리를 채우고 안내문은 제거)
- 템플릿을 읽을 수 없으면 폴백 — 비판점(차단/권장/사소) / 수정 내용 / 검증 /
  릴리즈 판정(+추천 버전 major/minor/patch) / 다음 단계 5개 섹션
- 릴리즈 가능이면 /tide-release vX.Y.Z 구체 버전을, 불가면 보완 태스크 또는
  /tide-milestone 후속 계획을 다음 단계에 제시

리뷰·수정·리뷰보고서까지 마치면 .tide/phase를 `idle`로 되돌린 뒤 최종 판정을 명확히 보고해줘.
