---
description: "[tide] 새 프로젝트에 tide 워크플로우 골격 생성 (마일스톤/리포트/CHANGELOG/규약)"
argument-hint: "[프로젝트 한 줄 설명(선택)]"
---
이 저장소에 tide 개발 사이클 골격을 세팅해줘. 한 줄 설명: "$ARGUMENTS"

생성/확인 (기존 파일은 덮어쓰지 말고 누락된 것만 보강):
1. docs/milestones/ 및 docs/reports/ 디렉터리
2. CHANGELOG.md (없으면 "# CHANGELOG" 헤더로 생성)
3. README.md에 "## CHANGELOG" 섹션이 없으면 추가
4. docs/conventions.md — 마일스톤 7개 섹션 형식, 태스크 ID·(deps:) 표기,
   단계별 금지행위(impl/review는 git 금지), 보고서 형식, 버전 파일 위치 규약 명시
5. 버전 파일(Cargo.toml/package.json/pyproject.toml 등) 감지 후 현재 버전 보고

git 작업은 하지 마. 완료 후 다음 단계(/tide-milestone)를 안내해줘.
