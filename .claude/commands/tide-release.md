---
description: "[tide] 버전 범프 → CHANGELOG/README → commit → tag → push"
argument-hint: "v0.1.0 (생략 시 현재 버전 기준)"
---
릴리즈를 진행해줘. 버전은 "$ARGUMENTS"로 지정할 수 있어 (예: /tide-release v0.1.0).
생략하면 버전 파일의 현재 버전을 기준으로 판단해줘.

수행 순서:
1. 버전 파일 업데이트 (Cargo.toml / package.json / pyproject.toml 등 프로젝트에 맞게)
2. CHANGELOG.md 최상단에 해당 버전 릴리즈 노트 추가
3. README.md의 CHANGELOG 섹션 최상단에 동일 내용 추가
4. git add → git commit ("Release {버전}: {핵심 변경사항 한 줄 요약}")
5. git tag {버전}
6. git push origin main
7. git push origin {버전}
