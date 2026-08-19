# tide — 이 저장소의 함정 목록

규칙의 **단일 원본이 아니다**. 여기 있는 것은 *"모르면 조용히 깨지는 자리"* 뿐이고, 상세는 전부
포인터가 가리키는 곳에 있다. 일반적인 좋은 습관은 적지 않는다 — 그것이 이 파일이 낡는 이유다.

## 손대면 조용히 깨지는 자리

- **`tests/**/*.ps1`에 비-ASCII를 넣지 않는다.** 주석도 안 된다 — 한글이 필요하면 문서에 적고
  스크립트는 코드포인트(`Uni 0xC808`)로 지칭한다. 집행: `tests/discover` F5.
- **정렬·비교는 로케일/ordinal로 고정한다.** `.sh`는 같은 줄에 `LC_ALL=C`. 인자 없는 `Sort-Object`는
  **고정 형태가 없다** — ordinal 헬퍼로 바꾸거나 같은 줄에 `locale-exempt: <사유>`를 **선언**한다.
  집행: F9~F13.
- **인용은 한 줄 안에 쓴다.** `` `docs/conventions.md`의 "{앵커}" 절 `` 골격이며 파일명과 따옴표
  구획이 줄바꿈으로 갈리면 **가드가 보지 못한다**. 절보다 좁은 자리는 **번호가 아니라 이름**으로
  가리킨다(번호는 G8이 금지한다). 집행: Part G.
- **케이스 수를 여러 곳에 적지 않는다.** 단일 선언처는 각 `tests/{name}/README.md`의 `cases:` 한
  줄이고, 러너가 실측과 대조한다. 사이클 중 변하는 수는 문서에 박지 말고 **선언처를 가리킨다**.
- **git 쓰기는 `/tide:release` 단계에서만** 통과한다(`.tide/phase` + `hooks/tide-guard.*`).
  다른 단계에서 commit·tag·push를 시도하면 훅이 exit 2로 막는다. 읽기는 항상 통과한다.
- **규약은 한 파일이 아니라 문서 집합이다** — `docs/conventions*.md`(본체 + 주제 조각). 목록을
  스크립트·문서에 하드코딩하지 말고 글롭으로 발견한다.
- **하니스는 네 실행 환경에서 같은 수를 내야 한다** — `dash` · `bash` · Windows PowerShell 5.1 ·
  `pwsh` 7. `run.sh`와 `run.ps1`의 **총계가 일치**해야 하며(F1), 한쪽만 있는 케이스는 넣을 수 없다.
- **규칙을 고치면 그 규칙을 재서술한 자리를 같은 편집에서 고친다** — 스킬 절차·템플릿 안내문·
  `docs/project-context.md`의 개념 블록이 그 자리다. ASCII 병기어가 있는 규칙은 Part E가 문다.

## 어디를 읽어야 하는가

| 알고 싶은 것 | 단일 원본 |
|---|---|
| 규약 전체(단계·판정·집행) | `docs/conventions.md`(+ `docs/conventions-release.md`) |
| 커맨드 12종의 역할·산출물 | `docs/commands.md` |
| 프로젝트 맥락·이월 원장 | `docs/project-context.md` |
| 하니스가 무엇을 무는가 | `tests/{name}/README.md` |
| 사이클 이력 | `docs/milestones/M*.md` · `docs/reports/M*-{impl,review}.md` · `retro.md` |
