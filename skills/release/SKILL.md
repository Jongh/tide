---
description: "[tide] 프리플라이트 → 버전 범프 → CHANGELOG → commit → tag → push"
argument-hint: "v0.1.0 (생략 시 리뷰보고서의 추천 버전 기준)"
---
릴리즈를 진행해줘. 버전은 "$ARGUMENTS"로 지정할 수 있어 (예: /tide:release v0.1.0).
생략하면 리뷰보고서의 추천 버전으로, 그것도 없으면 버전 파일의 현재 버전을 기준으로 판단해줘.

**대상 레포**: 시작 시 대상 레포 루트를 정한다 — 기본은 세션 레포(현행 단일 레포 동작 그대로),
상위 폴더 단일 세션에서 특정 자식 레포를 지시받으면 그 자식 레포 루트. 버전 파일·`CHANGELOG.md`·
`.tide/phase`·테스트·`git add/commit/tag/push`는 모두 **대상 레포 루트 기준/cwd**로 수행한다.
`git push`의 대상 브랜치·remote는 가정(`origin main`)을 고정하지 말고 **대상 레포의 실제 기본
브랜치·remote**에 맞춘다(레포마다 다를 수 있음). 상세·격리 규약은 `docs/conventions.md`의
"멀티 레포 / 대상 레포" 절.

프리플라이트 (하나라도 실패하면 git 작업 없이 중단하고 사유를 보고):
1. 대상 마일스톤(M{N})의 docs/reports/M{N}-review.md 릴리즈 판정이 "가능"인지 확인
   — 판정이 "불가"이거나 보고서가 없으면 중단. 단, 사용자가 버전 인자를 주며 강행
   의사를 명시한 경우에만 경고를 남기고 진행
2. 프로젝트 테스트 명령(cargo test / npm test / pytest 등) 실행 — 실패 시 중단
3. git status로 워킹트리 확인 — 이번 사이클과 무관해 보이는 변경이 있으면
   목록을 보여주고 사용자 확인을 받은 뒤 진행
4. **사이트 빌드 출력 제외 용어 0건 확인** (사이트가 있는 프로젝트에 한함) —
   `site/mkdocs.yml` 등 사이트 설정이 있으면, 사이트를 빌드(예: `mkdocs build`)한
   **산출물(소스가 아니라 빌드 출력)** 을 스캔해 제외 용어(외부 저장소명 등)가 0건인지
   확인한다. 검출되면 release를 중단하고 누수 위치를 보고한다. 사이트가 없는 프로젝트
   (일반 tide 사용)에는 이 단계가 적용되지 않는다 — 건너뛰고 진행. 제외 용어 처리·검증의
   상세는 `docs/conventions.md`의 "릴리즈 빌드 출력 검증" 규약을 따른다.

프리플라이트 통과 후 .tide/phase 파일에 `release` 한 줄을 기록하고
(.tide/ 디렉터리가 없으면 생성) 다음을 수행:
1. 버전 파일 업데이트 (Cargo.toml / package.json / pyproject.toml /
   .claude-plugin/plugin.json 등 프로젝트에 맞게)
2. CHANGELOG.md 최상단에 해당 버전 릴리즈 노트 추가
   (CHANGELOG.md가 릴리즈 노트의 단일 원본 — README.md의 CHANGELOG 섹션은 포인터만
   두므로 건드리지 않는다. `docs/conventions.md`의 "버전·CHANGELOG" 규약 참조)
3. git add → git commit ("Release {버전}: {핵심 변경사항 한 줄 요약}")
4. git tag {버전}
5. git push {remote} {기본 브랜치}  — 대상 레포의 실제 remote·기본 브랜치 (기본 추정: origin/main, 다르면 그에 맞춤)
6. git push {remote} {버전}

완료 후 .tide/phase를 `idle`로 되돌리고 결과를 보고해줘.

## 운영 주의

최근 release에서 반복된 함정이다. 위 절차 자체는 그대로 두고, 실행 시 아래를 지킨다:

1. **`.tide/phase`=`release` 기록은 git 명령과 별도 단계로 먼저** 실행한다. tide-guard는
   명령 실행 *전*에 phase를 읽으므로, `phase 기록 && git ...`처럼 한 명령에 합치면 직전
   phase(예: `idle`/`review`)가 읽혀 git 작업이 차단된다. 반드시 phase를 먼저 한 단계로
   기록하고, 그다음 별도 명령으로 git을 실행한다.
2. **커밋 메시지가 여러 줄이면 실행 환경의 멀티라인 문법에 맞춘다.** `-m`을 반복하거나
   환경에 맞는 here-doc/here-string을 쓴다. 셸이 불일치하면(예: POSIX sh ↔ PowerShell)
   메시지에 따옴표·토큰이 그대로 섞여 오염될 수 있다.
3. **CHANGELOG/README 릴리즈 노트에 사이트에서 제외하기로 한 용어(외부 저장소명 등)를
   literal로 쓰지 않는다.** 이 문서들은 단일 원본화(snippets)로 사이트 콘텐츠에 그대로
   유입될 수 있다. 제외 용어 처리는 `docs/conventions.md`의 규약을 따른다.
