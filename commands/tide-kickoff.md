---
description: "[tide] 새 프로젝트에 tide 워크플로우 골격 생성 (마일스톤/리포트/CHANGELOG/규약)"
argument-hint: "[프로젝트 한 줄 설명(선택)]"
---
이 저장소에 tide 개발 사이클 골격을 세팅해줘. 한 줄 설명: "$ARGUMENTS"

생성/확인 (기존 파일은 덮어쓰지 말고 누락된 것만 보강):
1. docs/milestones/ 및 docs/reports/ 디렉터리
2. CHANGELOG.md (없으면 "# CHANGELOG" 헤더로 생성)
3. README.md에 "## CHANGELOG" 섹션이 없으면 추가
4. docs/conventions.md — 단계별 금지행위(impl/review는 git 금지), 상태 파일(.tide/phase)
   규약, 태스크 ID·(deps:) 표기, 버전 파일 위치를 기록하고, 마일스톤·보고서 형식은
   tide 플러그인의 templates/ 가 단일 원본임을 명시
5. .gitignore에 `.tide/` 항목이 없으면 추가 (상태 파일은 커밋 대상 아님)
6. 버전 파일(Cargo.toml/package.json/pyproject.toml/.claude-plugin/plugin.json 등) 감지 후 현재 버전 보고

참고: git 작업 차단 가드(tide-guard)는 tide 플러그인이 hook으로 직접 제공하므로
프로젝트별 설치가 필요 없다. 별도의 hook 설치 절차를 만들지 마.

git 작업은 하지 마. 완료 후 다음 단계(/tide-milestone)를 안내해줘.
