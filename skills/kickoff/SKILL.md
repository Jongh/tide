---
description: "[tide] tide 워크플로우 골격 생성 + 진행 중 프로젝트면 구조 문서화 (마일스톤/리포트/CHANGELOG/규약)"
argument-hint: "[프로젝트 한 줄 설명(선택)]"
---
이 저장소에 tide 개발 사이클 골격을 세팅해줘. 한 줄 설명: "$ARGUMENTS"

**대상 레포**: 골격·`docs/project-context.md`·`.gitignore`·`CHANGELOG.md` 등 모든 산출물은 **대상
레포 루트**에 만든다 — 기본은 세션 레포(현행 단일 레포 동작 그대로), 상위 폴더 단일 세션에서 특정
자식 레포를 지시받으면 그 자식 레포 루트. 상세·격리 규약은 `docs/conventions.md`의 "멀티 레포 /
대상 레포" 절(이 절도 골격 생성 시 conventions에 포함될 수 있도록 안내한다).

먼저 대상 저장소가 **신규**인지 **진행 중**인지 판별해줘:
- 신호: git 커밋 이력 유무, docs/milestones/·docs/reports/의 기존 산출물 유무,
  소스 파일·버전 파일의 존재 규모
- 판별 결과를 한 줄로 보고해줘 (예: "진행 중 프로젝트로 감지 — 커밋 N개, 소스 M개")

생성/확인 (기존 파일은 덮어쓰지 말고 누락된 것만 보강):
1. docs/milestones/ 및 docs/reports/ 디렉터리
2. CHANGELOG.md (없으면 "# CHANGELOG" 헤더로 생성)
3. README.md에 "## CHANGELOG" 섹션이 없으면 추가
4. docs/conventions.md — 단계별 금지행위(impl/review는 git 금지), 상태 파일(.tide/phase)
   규약, 태스크 ID·(deps:) 표기, 버전 파일 위치를 기록하고, 마일스톤·보고서 형식은
   tide 플러그인 각 스킬에 동봉된 template.md가 단일 원본임을 명시
5. .gitignore에 `.tide/phase` 항목이 없으면 추가 (로컬 상태 파일은 커밋 대상 아님 — `.tide/`
   전체가 아니라 `.tide/phase`만 무시해 `.tide/deps`는 커밋 가능하게)
   - 참고: `.tide/deps`는 레포 간 의존을 한 줄에 형제 레포명 하나씩 선언하는 **선택·옵트인**
     매니페스트로, 선언 시 fleet이 위상정렬해 권장 처리 순서를 제시한다. 선언이므로 커밋 대상
     이며 없으면 의존 0(현행 동작). kickoff가 이 파일을 자동 생성하지는 않는다.
6. 버전 파일(Cargo.toml/package.json/pyproject.toml/.claude-plugin/plugin.json 등) 감지 후 현재 버전 보고
7. **진행 중 프로젝트로 판별된 경우** docs/project-context.md 생성 (이미 있으면 덮어쓰지
   말고 누락 항목만 보강). 코드베이스를 조사해 아래를 채워줘 — 이후 /tide:milestone·
   /tide:impl이 매번 재조사하지 않고 이 문서를 참조한다:
   - 스택·언어·주요 의존성 (버전 파일·매니페스트 기준)
   - 최상위 디렉터리 구조와 각 디렉터리의 역할 한 줄
   - 진입점·빌드/테스트 실행 방법 (감지 가능한 범위)
   - 핵심 도메인 개념·용어 (소스·README에서 확인 가능한 수준)
   조사가 불확실한 항목은 단정하지 말고 "확인 필요"로 표기해줘. 구조를 신뢰 있게
   파악하기 어려우면(비표준 레이아웃 등) 최소 골격(디렉터리 트리 + 확인 필요 표기)만
   남기고 그 사유를 보고해줘. **신규(빈) 프로젝트로 판별되면 이 단계는 생략**하고
   그 사유를 한 줄로 보고해줘.

참고: git 작업 차단 가드(tide-guard)는 tide 플러그인이 hook으로 직접 제공하므로
프로젝트별 설치가 필요 없다. 별도의 hook 설치 절차를 만들지 마.

git 작업은 하지 마. 완료 후 다음 단계(/tide:milestone)를 안내해줘.
