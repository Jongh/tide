# tide 규약 (conventions)

tide는 porpoise의 개발 방법론(마일스톤 → 구현 → 리뷰 → 릴리즈)을 프로젝트
독립적인 슬래시 커맨드로 옮긴 워크플로우다. 이 문서는 각 단계가 따르는 규약을 정의한다.

## 사이클

```
/tide-kickoff  →  /tide-milestone  →  /tide-impl  →  /tide-review  →  /tide-release vX.Y.Z
   (세팅)           (계획)             (구현·테스트)    (리뷰·판정)       (배포)
```

**핵심 원칙 — 부수효과 분리**: `impl`·`review`는 **절대 git 작업을 하지 않는다**(문서·코드만
남김). git commit/tag/push는 오직 `release`에서만 일어난다. impl/review가 남긴 보고서는
다음 `release` 커밋에 함께 포함된다.

## 마일스톤 문서

- 위치: `docs/milestones/M{N}.md` (가장 큰 번호 + 1, 없으면 M1)
- 필수 섹션 7개: **목표 / 배경 / 태스크 목록 / 태스크 상세 / 파일 변경 요약 / 완료 기준 / 메타데이터**
- 태스크 ID: `M{N}-T01`, `M{N}-T02` …
- 태스크는 한 번에 끝낼 수 있는 크기로 분해하고, 가능한 한 서로 독립적으로 설계
- 선행 의존이 있으면 태스크 끝에 `(deps: M{N}-T01, …)` 로 표기

## 보고서

- 완료 보고서: `docs/reports/M{N}-impl.md`
  - 개요 / 태스크별 수행 내용 / 변경 파일 요약 / 테스트 결과 / 미해결·후속 메모
- 리뷰 보고서: `docs/reports/M{N}-review.md`
  - 비판점(심각도: 차단/권장/사소) / 수정 내용 / 검증 / 릴리즈 판정(+추천 버전) / 다음 단계
- 동일 마일스톤 재실행 시 기존 보고서를 갱신한다.

## 버전 · CHANGELOG

- 버전 파일은 프로젝트 스택에 맞춤: `Cargo.toml` / `package.json` / `pyproject.toml` 등
- 버전은 SemVer. 리뷰 단계에서 major/minor/patch를 추천한다.
- `CHANGELOG.md` 최상단과 `README.md`의 `## CHANGELOG` 섹션 최상단에 **동일한** 릴리즈 노트를 둔다.
- 커밋 메시지: `Release {버전}: {핵심 변경사항 한 줄 요약}`

## 단계별 금지 행위 요약

| 단계 | 금지 |
|---|---|
| kickoff | git 작업 |
| milestone | 작업지시서 생성 / 코드 구현 / 테스트 실행 / git 작업 |
| impl | 코드 리뷰 / git commit / git tag / git push |
| review | git commit / git tag / git push |
| release | (없음 — 유일하게 git 조작 허용) |
