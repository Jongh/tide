# M12 완료보고서 (impl)

## 개요

M12 "1.0 준비"의 4개 태스크를 구현했다. v1.0.0 안정 선언을 위한 잔여 정리·견고화를
완료 — 배포 트리거 견고화(T01), 1.0 안정 선언 + "규약↔실행 동기화" 메타 규칙 +
README↔CHANGELOG 단일화(T02), 사이트 cosmetic + 홈 안정성(T03)을 **3개 서브에이전트로
동시 디스패치**(M9 병렬 메커니즘 3사이클 연속 사용, 벽시계 ≈ 최댓값)했고, T04에서 통합·
strict 빌드·porpoise 0을 확인했다. 회고가 닫지 못하던 항목(배포 견고화·README 단일화·
규약↔실행 동기화)이 모두 처리돼 1.0 릴리즈 준비가 끝났다.

## 태스크별 수행 내용

- **M12-T01** (서브에이전트 #1, `.github/workflows/deploy-pages.yml`) — `push` 트리거의
  `paths` 필터를 **제거**하고 `main` 푸시마다 빌드·배포하도록 변경(M11 권장1: 허용목록이
  단일 원본 인클루드 확장에 취약 → 근본 해소). `workflow_dispatch`·`permissions`·
  `concurrency`·job 구조 보존, 이유 주석 추가. YAML 유효.
- **M12-T02** (서브에이전트 #2, `conventions.md`·`README.md`·`release/SKILL.md`·
  `project-context.md`) — 핵심 4파일:
  - (a) **1.0 안정 선언**: conventions(마커 안쪽)·README에 "1.0 안정성" 절 — 커맨드 8종
    호출명·역할, 단계별 규약, `.tide/phase`/tide-guard 계약, 보고서·마일스톤 형식이
    1.0부터 stable, 하위 호환 파괴는 다음 major에서만.
  - (b) **메타 규칙**: conventions(마커 안쪽)에 "규약↔실행/인프라 동기화" — 규약·단일
    원본을 더하면 강제·반영할 실행 수단(프리플라이트·hook·CI 트리거·빌드)도 같은 사이클에.
  - (c) **README↔CHANGELOG 단일화**: README CHANGELOG 중복 노트 제거 → `CHANGELOG.md`
    포인터, conventions 버전 규칙을 "CHANGELOG 단일 원본·README 포인터"로 수정,
    `release/SKILL.md` 절차에서 "README CHANGELOG 추가" 단계 제거·재정렬(+frontmatter 정합).
  - (d) project-context에 1.0 선언·메타 규칙 반영.
  - 제외 용어 literal 미사용(메타 용어 누수 방지 준수).
- **M12-T03** (서브에이전트 #3, `site/mkdocs.yml`·`site/docs/index.md`) — `site_url`을
  라이브 실호스트에 맞춰 **소문자**(`https://jongh.github.io/tide/`)로 정렬(M11-impl#4),
  홈에 1.0 안정성 한 줄 가산. `repo_url` 등 보존, conventions/README 미접촉(비중첩).
- **M12-T04** (메인, 배리어; deps T01·T02·T03) — 통합·검증: 매니페스트 구조 무수정,
  release 절차 정합(README 단계 제거·CHANGELOG 단일 원본 명시), conventions 마커 무결,
  strict 빌드 exit 0, 빌드 출력 porpoise 0, 1.0 안정성이 사이트 2개 페이지(홈·규약)에 반영
  확인. 불일치 없어 추가 수정 불필요.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | (없음) |
| 수정 | `.github/workflows/deploy-pages.yml`(T01), `docs/conventions.md`·`README.md`·`skills/release/SKILL.md`·`docs/project-context.md`(T02), `site/mkdocs.yml`·`site/docs/index.md`(T03) |
| 삭제 | (없음 — README 중복 노트·release README 단계는 제거하되 파일 유지) |

> `.claude-plugin/plugin.json`·`marketplace.json` 구조 무수정(버전 1.0.0 범프는 release
> 소관). 자동 발견 유지.

## 테스트 결과

자동 테스트 러너 없는 플러그인. 정적/빌드/병렬 검증:

- **병렬 디스패치(3사이클 연속)** — T01·T02·T03 비중첩 동시 디스패치, 폴백 없음, 벽시계
  ≈ 최댓값(~185s = T02, 합산 아님). M10·M11에 이은 안정적 재사용.
- **strict 빌드** — `mkdocs build -f site/mkdocs.yml --strict` exit 0. T03 site_url·홈
  변경, T02 conventions 1.0 선언이 사이트에 정상 반영(1.0 안정성 2개 페이지).
- **빌드 출력 porpoise 0건** — 1.0 선언·메타 규칙 문장이 제외 용어 literal을 안 써(메타
  용어 누수 방지 준수) 누수 없음.
- **release 절차 정합** — README CHANGELOG 단계 제거 후 1~6 재정렬, step 2가 "CHANGELOG
  단일 원본·README 미수정" 명시. conventions 버전 규칙·project-context와 일치.
- **conventions 마커 무결** — start(9)·end(179) 보존, 신규 절은 마커 안쪽 → 사이트 반영.
- **매니페스트 구조 무수정** — 자동 발견 유지.
- **하위 호환** — 이 라운드 변경은 전부 정리·가산(배포 트리거 견고화·문서 단일화·선언
  추가). 커맨드·계약 파괴 없음 → 1.0 안정 선언과 정합.

## 미해결·후속 메모

1. **1.0 릴리즈는 major 범프** — `/tide:release v1.0.0`에서 `plugin.json`을 1.0.0으로
   범프하고 CHANGELOG에 v1.0.0 노트(README는 이제 포인터라 미수정 — T02가 release 절차에서
   그 단계를 제거함). 이번 사이클이 그 절차 변경의 첫 적용이 된다.
2. **배포 트리거 변경 후 첫 푸시 확인** — 이제 main 푸시마다 배포되므로, v1.0.0 릴리즈
   푸시가 사이트를 재빌드해 라이브에 1.0 안정성·v1.0.0 변경 이력이 반영되는지 release 후
   확인(누락 위험은 구조적으로 제거됨).
3. **README masthead의 외부 귀속은 잔존(사이트 무영향)** — `README.md` line 3의 도입
   문장은 이번 범위 밖이며, 사이트 홈(`site/docs/index.md`)은 별도라 영향 없다. 원한다면
   1.0 차원에서 README masthead도 tide 자체 정의로 정리하는 것은 cosmetic 후속.
4. **브라우저 런타임·병렬 폴백 종단 실증은 여전히 후속** — M11에서 넘어온 저위험 항목,
   1.0 이후 자연 발생 시 확인.
