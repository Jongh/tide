# M21 완료보고서 (impl)

## 개요

마일스톤 M21(오케스트레이션 발견성 — 멀티 레포 맥락 감지 힌트 + 커맨드 수 드리프트 가드)의 네 태스크를
**4-way 병렬**(파일 비중첩·무deps)로 구현했다. 결과: (1) `/tide:status`·`/tide:kickoff`가 세션 cwd 직속
자식 tide 레포 **2개 이상** 감지 시 `여러 자식 tide 레포 N개 감지 — 교차 개요는 /tide:fleet` 한 줄을
advisory로 덧붙이고 **2개 미만이면 무출력**(소음 0), (2) 발견성 규약을 `docs/conventions.md`에 단일
원본으로 규정(발견 규약 재사용), (3) **커맨드 수 드리프트 가드**(실제 스킬 수 == 문서·사이트 선언)를
신규 하니스로 추가해 M20 리뷰 #6(사이트 8종↔11종 표류) 회귀 고정. 전부 읽기 전용·하위 호환 가산.

## 태스크별 결과

### M21-T01 — status 감지 힌트
- **파일**: `skills/status/SKILL.md`
- status 본래 보고 **맨 끝에** 자식 tide 레포 ≥2 감지 시 advisory 한 줄, <2면 무출력. 발견 규약은
  conventions "멀티 레포 오케스트레이션"(발견) 인용(재정의 금지). **완전 읽기 전용 불변** + 힌트가
  fleet 자동 실행 안 함 명시. <2 세션 출력 바이트 동일.

### M21-T02 — kickoff 감지 힌트
- **파일**: `skills/kickoff/SKILL.md`
- 골격 생성(+진행 중 프로젝트 문서화) 완료 **맨 끝에** 동일 트리거·출력 조건. kickoff 기존 동작
  (골격·`.gitignore`·project-context) 불변, 힌트는 가산·advisory. conventions 인용.

### M21-T03 — 발견성 규약(단일 원본) + README
- **파일**: `docs/conventions.md`, `README.md`
- conventions "멀티 레포 오케스트레이션"에 **"발견성(discoverability) 힌트"** 절 추가 — 트리거(cwd 직속
  자식 tide 레포 ≥2)·출력 조건(맨 끝 한 줄·<2 무출력)·읽기 전용 advisory 불변·status/kickoff 공통.
  발견 규약은 기존 "자식 tide 레포 발견 규약" 절 재사용(재정의 금지). `[start:body]` 마커 안.
- README MSA 포인터에 사용자 대면 한 줄(멀티 레포 맥락이면 status·kickoff가 fleet 안내). 2.0 안정성·
  커맨드 표 불변.

### M21-T04 — 라이브 실증(감지 임계값 + 커맨드 수 가드)
- **파일**: `tests/discover/run.sh`·`run.ps1`·`README.md`(신규)
- **Part A 감지 임계값**: fleet 발견 참조 구현 재사용 → 2개 자식 tide 레포 **hint(N=2)**, 1개·0개·단일
  레포 루트(자식 비-tide) **none**, 숨김(`.hidden-svc`) 미카운트.
- **Part B 커맨드 수 가드**: `skills/*/SKILL.md` 실제 개수(11) == 캐노니컬 선언(`README`·`conventions`·
  `site/docs/commands.md`·`site/docs/getting-started.md`의 "N종") grep 결합. 드리프트 대조(12종 부재)로
  불일치 시 FAIL 보장. 실제 스킬 디렉터리를 세므로 커맨드 증감 시 갱신 강제.

## 테스트 결과

| 러너 | 결과 |
|---|---|
| `tests/discover/run.sh` | **PASS=16 FAIL=0** (exit 0) |
| `tests/discover/run.ps1` | **PASS=16 FAIL=0** (exit 0) |

- Part A(2→hint·1→none·0→none·단일레포→none·숨김 미카운트) + Part B(실제 11 == 캐노니컬 4곳 선언, 12종
  부재 대조) 모두 검증.
- `run.ps1` 비ASCII 바이트 **0**(`종`=`[char]0xC885` 코드포인트), `run.sh` 무BOM. 활성 가드 규율 준수.
- 회귀: 기존 tests/fleet·fleet-cycle·fleet-verify·multi-repo 불변(이 사이클은 신규 하니스만 추가).

## 부수효과 분리 확인

- impl 단계 전체 git commit/tag/push 미수행(서브에이전트 포함, phase=impl).
- 힌트·가드·규약은 전부 하위 호환 가산 — 자식 tide 레포 <2 세션의 status·kickoff 출력 불변, 단일 레포
  동작 불변. status 완전 읽기 전용·kickoff 골격 동작 불변 유지.
- 제외 용어: 변경/사이트 노출 파일(status·kickoff·conventions body·discover·M21) **0**.

## 변경 파일

- 추가: `tests/discover/run.sh`·`run.ps1`·`README.md`(T04); `docs/milestones/M21.md`(마일스톤);
  `docs/reports/M21-impl.md`(본 보고서)
- 수정: `skills/status/SKILL.md`(T01); `skills/kickoff/SKILL.md`(T02); `docs/conventions.md`·`README.md`(T03)

## 미해결·후속

- 없음(차단 이슈 0). 발견 임계값(≥2)·커맨드 수 가드 양 셸 그린.
- 주의(검증자 참고): ps1 Part B는 BOM 없는 UTF-8 마크다운을 `[System.IO.File]::ReadAllText(..., UTF8)`로
  읽어 한글 "종" 매칭(PS 5.1 `Get-Content -Raw` 오디코딩 회피) — 인코딩 규약 정합.
- 다음: review에서 발견성 힌트의 읽기 전용·소음 0 불변, 가드의 드리프트 적발력을 비판적으로 검증.
