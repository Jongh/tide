# M23 완료보고서 (impl)

## 개요

M23(정리 사이클)을 구현했다. 두 정리 후속을 묶어 — ② `tests/{discover,fleet,fleet-cycle,fleet-verify}`에
4중(× 2셸)으로 복제돼 있던 발견·위상정렬 참조 구현(`is_tide_repo`·`discover`·`toposort`)을
`tests/lib/{discover,toposort}.{sh,ps1}` 공유 라이브러리 단일 원본으로 추출하고 하니스가 source하도록
전환했고, ③ 1060행으로 비대해진 `docs/reports/retro.md`를 v2.x만 남기고 v1.4.0 이하를
`docs/reports/retro-archive.md`로 분리했다. 5개 태스크 전부 완료, 전 하니스가 **양 셸에서 전환 전과
동일한 PASS 수**로 통과(동작 보존). 새 커맨드·능력·계약 변화 0.

## 태스크별 수행 내용

- **M23-T01** — `tests/lib/`에 공유 참조 라이브러리 4개 신설. `discover.sh`/`discover.ps1`(`is_tide_repo`·
  `discover`/`IsTideRepo`·`Discover`), `toposort.sh`/`toposort.ps1`(`toposort`/`TopoSort`). 정본은 fleet
  하니스 버전을 **바이트 보존** 채택하고, fleet-verify가 갖던 더 자세한 주석(`.tide-fleet 포함`)을 정본
  `discover` 주석에 흡수(로직 동일이라 주석만 통합). 라이브러리는 함수 정의만(부수효과 없음). **설계
  메모**: `toposort`는 `read_deps`를 호출하는데 이는 라이브러리에 두지 않았다 — `read_deps`는 하니스별
  로컬 정의로 남긴다(함수는 호출 시점 해석이라 source 순서 무관). `.ps1`은 ASCII 소스(비ASCII 0)·무BOM.
- **M23-T02** — `discover`·`fleet` 하니스(sh+ps1)를 라이브러리 source로 전환(deps T01). ROOT 해석 직후
  `. "$ROOT/tests/lib/discover.sh"`(fleet은 `toposort.sh`도) / ps1 dot-source 삽입, 로컬 `is_tide_repo`·
  `discover`(fleet은 `toposort`도) 정의 제거(브레드크럼 주석 유지). fleet의 `read_deps`/`ReadDeps`·픽스처·
  단언 유지. (fleet 하니스엔 ROOT 변수가 없어 discover와 동일 관용구로 신설.)
- **M23-T03** — `fleet-cycle`·`fleet-verify` 하니스(sh+ps1)를 source로 전환(deps T01). fleet-cycle은
  discover+toposort 둘 다 source(로컬 `is_tide_repo`·`discover`·`toposort` 제거, `read_deps` 유지),
  fleet-verify는 discover만. **로직 동등성 실증**: fleet-cycle이 자기 압축형 `toposort` 대신 정본(fleet판)
  으로 PASS=23 통과 → 두 구현이 로직 동등이었음이 입증됨(T01의 미검증 가정 해소).
- **M23-T04** — 회고 아카이브 분리. `docs/reports/retro-archive.md` 신설(헤더 + v1.4.0 이하 섹션 **바이트
  보존** 이동), `retro.md`는 v2.x(v2.2.0·v2.1.0·v2.0.0·v1.6.0 블록쿼트 연속 포함)만 남기고 아카이브
  포인터 한 줄 추가(1060→320행). `skills/retro/SKILL.md`에 아카이브 관례 노트(동작 불변 — retro.md 입력
  제외·최상단 누적). 분할점은 `## ...(v1.4.0 시점)...` 헤더. `/tide:retro`가 retro.md를 입력 제외하므로
  behavior-neutral.
- **M23-T05** — 단일 원본 도달 범위 문서 동기화(deps T01~T04). `docs/conventions.md` "규약↔실행/인프라
  동기화" 절에 M23 적용 예(테스트 참조 구현 단일 원본화 + read_deps 로컬 유지 메모) + 회고 아카이브 관례
  추가. `docs/project-context.md` `tests/` 행(발견·위상정렬 참조 구현 = `tests/lib` 공유, 트리 내 자기완결)·
  `docs/reports/` 행(`retro-archive.md`) 갱신.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `tests/lib/discover.sh`·`discover.ps1`·`toposort.sh`·`toposort.ps1`, `docs/reports/retro-archive.md` |
| 수정 | `tests/{discover,fleet,fleet-cycle,fleet-verify}/run.sh`·`run.ps1`(8개, source 전환), `docs/reports/retro.md`(v2.x만+포인터), `skills/retro/SKILL.md`(아카이브 노트), `docs/conventions.md`·`docs/project-context.md`(동기화) |
| 삭제 | 없음 (로컬 함수 정의는 하니스 내 제거, 파일 삭제 아님) |

## 테스트 결과

자동 러너 없음 — `tests/`의 자기완결형 라이브 하니스로 검증(양 셸). **전 하니스가 전환 전 baseline과
동일 PASS 수로 통과(동작 보존)**:

| 하니스 | sh | ps1 | baseline |
|---|---|---|---|
| `discover` | 19/0 ✅ | 19/0 ✅ | 19 |
| `fleet` | 41/0 ✅ | 41/0 ✅ | 41 |
| `fleet-cycle` | 23/0 ✅ | 23/0 ✅ | 23 |
| `fleet-verify` | 29/0 ✅ | 29/0 ✅ | 29 |
| `multi-repo` | 10/0 ✅ | 10/0 ✅ | 10 (불변) |

- 모든 러너 exit 0. **fleet-cycle이 정본 toposort로 통과**해 두 toposort 구현의 로직 동등성 실증.
- **인코딩 규율**: `tests/lib/*.ps1` 비ASCII 바이트 **0**, 신규 라이브러리 4개 + 수정 하니스 8개 모두
  **BOM 없음**(선두 `23`=`#`). M22 가드(discover B1/B2/B3) 단언 불변.
- retro 아카이브: 이동 구간 바이트 보존(diff 클린, T04 확인), `/tide:retro` 입력 제외라 집계 무영향.

## 미해결·후속 메모

1. **하니스 자기완결성 약화(수용·설계 결정)** — 하니스가 이제 `tests/lib/`를 source한다. 같은 `tests/`
   트리 내 상대경로라 `sh tests/X/run.sh`·`& tests\X\run.ps1`로는 그대로 실행되며, 단일 원본 이득(규약
   변경 시 1곳 수정)이 파일별 자기완결성보다 크다고 판단. 리뷰가 이 트레이드오프 적정성을 확인.
2. **`read_deps`는 라이브러리 미추출(범위 밖)** — `toposort`가 호출하는 `read_deps`/`ReadDeps`는 하니스별
   로컬로 남겼다(이번 범위는 discover/toposort). fleet·fleet-cycle 두 곳에 잔존 — 추가 단일 원본화는
   향후 정리 후보(저위험).
3. **mkdocs 빌드 출력 검증(환경-이월 지속)** — M22에서 이월된 항목으로, 이번 정리 사이클과 무관하나
   다음 release 프리플라이트에서 동일하게 환경 이슈. CI/라이브 회수.
