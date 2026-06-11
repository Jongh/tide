---
description: "[tide] 마일스톤대로 구현 + 테스트 + 완료보고서 (커밋·리뷰 없음)"
argument-hint: "[M번호 (선택, 예: M3 — 생략 시 최신 마일스톤)]"
---
마일스톤 문서대로 구현을 진행해줘. 대상 지정: "$ARGUMENTS"
- 인자로 마일스톤 번호(예: M3)가 오면 docs/milestones/M3.md를 대상으로 (재실행·이어하기 용도)
- 생략하면 docs/milestones/M*.md 중 번호가 가장 큰 문서를 대상으로

시작 전 검사: 대상 마일스톤 문서가 존재하는지 확인해줘.
없으면 아무것도 구현하지 말고, /tide:milestone 을 먼저 실행하라고 안내한 뒤 중단해줘.

검사를 통과하면 .tide/phase 파일에 `impl` 한 줄을 기록해줘 (.tide/ 디렉터리가 없으면 생성).

docs/project-context.md가 있으면 먼저 읽어 기존 구조를 파악한 뒤 구현해줘
(없으면 평소대로 진행).

진행:
- 태스크를 의존성(deps) 순서를 고려해 구현
- 구현 후 프로젝트의 테스트 명령(cargo test / npm test / pytest 등)을 실행해 결과 확인

완료보고서 작성 — docs/reports/M{N}-impl.md (재실행이면 기존 보고서를 갱신):
- ${CLAUDE_SKILL_DIR}/template.md 템플릿을 읽어 그 구조 그대로 작성
  ({} 자리를 채우고 안내문은 제거)
- 템플릿을 읽을 수 없으면 폴백 — 개요 / 태스크별 수행 내용 / 변경 파일 요약 /
  테스트 결과 / 미해결·후속 메모 5개 섹션

구현·테스트·완료보고서까지 마치면 .tide/phase를 `idle`로 되돌린 뒤 결과를 보고해줘.
다음은 절대 수행하지 마: 코드 리뷰 / git commit / git tag / git push
