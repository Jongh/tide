---
description: "[tide] 프리플라이트 → 버전 범프 → CHANGELOG/README → commit → tag → push"
argument-hint: "v0.1.0 (생략 시 리뷰보고서의 추천 버전 기준)"
---
릴리즈를 진행해줘. 버전은 "$ARGUMENTS"로 지정할 수 있어 (예: /tide:release v0.1.0).
생략하면 리뷰보고서의 추천 버전으로, 그것도 없으면 버전 파일의 현재 버전을 기준으로 판단해줘.

프리플라이트 (하나라도 실패하면 git 작업 없이 중단하고 사유를 보고):
1. 대상 마일스톤(M{N})의 docs/reports/M{N}-review.md 릴리즈 판정이 "가능"인지 확인
   — 판정이 "불가"이거나 보고서가 없으면 중단. 단, 사용자가 버전 인자를 주며 강행
   의사를 명시한 경우에만 경고를 남기고 진행
2. 프로젝트 테스트 명령(cargo test / npm test / pytest 등) 실행 — 실패 시 중단
3. git status로 워킹트리 확인 — 이번 사이클과 무관해 보이는 변경이 있으면
   목록을 보여주고 사용자 확인을 받은 뒤 진행

프리플라이트 통과 후 .tide/phase 파일에 `release` 한 줄을 기록하고
(.tide/ 디렉터리가 없으면 생성) 다음을 수행:
1. 버전 파일 업데이트 (Cargo.toml / package.json / pyproject.toml /
   .claude-plugin/plugin.json 등 프로젝트에 맞게)
2. CHANGELOG.md 최상단에 해당 버전 릴리즈 노트 추가
3. README.md의 CHANGELOG 섹션 최상단에 동일 내용 추가
4. git add → git commit ("Release {버전}: {핵심 변경사항 한 줄 요약}")
5. git tag {버전}
6. git push origin main
7. git push origin {버전}

완료 후 .tide/phase를 `idle`로 되돌리고 결과를 보고해줘.
