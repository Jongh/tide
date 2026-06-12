# M17 완료보고서 (impl)

## 개요

M17의 세 태스크를 모두 구현했다 — `/tide:fleet`이 `.tide/deps`의 `>= 버전` 계약을 의존 대상 레포의
현재 버전과 비교해 미달이면 **`⚠ upstream behind` 경고**를 advisory로 띄우고, deps 파서가 **선두 UTF-8
BOM을 무시**하게 했다. (T01) 규약을 단일 원본화하고, (T02) fleet 스킬에 계약 파싱·버전 비교·BOM strip을
반영하고, (T03) 라이브 하니스에 semver 비교·BOM 내성 참조 구현과 시나리오를 더해 sh·ps1 양쪽 **각
23/23 통과**시켰다. 버전 제약 없는 줄·BOM 없는 파일은 현행 동작 그대로(옵트인 가산)이며, fleet은 여전히
읽기 전용·advisory만(경고도 차단·실행 아님). T01·T02·T03은 정규 spec 공통 인용으로 **3-way 병렬** 수행.

## 태스크별 수행 내용

- **M17-T01** — `docs/conventions.md`("멀티 레포 오케스트레이션" 절, snippet body 안쪽): `.tide/deps`
  형식에 **계약 버전 옵트인 확장**(`<레포명>[ >= <버전>]`, `>=`만 지원·그 외 무시+경고, `vX.Y.Z`
  major.minor.patch 숫자 비교, 파싱 불가 시 비교 생략+경고) 보강, 신규 `계약 비교 규칙`(의존 대상 현재
  버전 < 요구 → `upstream behind` 경고를 권장 순서/advisory에 표기, **순서·그래프는 불변**, advisory만)
  추가, 파싱 서술에 **선두 BOM 무시** 한 줄 추가. 1.0 안정성·커맨드 수·부수효과 분리 서술 불변, 제외 용어 0.
- **M17-T02** — `skills/fleet/SKILL.md`: "`.tide/deps` 읽기" 절에 `>= 버전` 제약 파싱(연산자 외 무시+경고)·
  **선두 BOM 제거** 추가. "권장 처리 순서"에 **계약 버전 비교** 추가 — 의존 대상 현재 버전(상태 4번)과
  요구 버전 비교, 미달이면 의존 줄에 `⚠ upstream behind` 표기(만족 시 무표기, 파싱 불가 시 생략+경고),
  위상정렬 순서·그래프 불변, 경고는 advisory만. 읽기 전용·부수효과 분리·5버킷·M16 위상정렬/순환/미선언 유지.
- **M17-T03** — `tests/fleet/run.sh`·`run.ps1`·`README.md`: 참조 구현에 **선두 BOM strip**(sh `sed 1s/^\xEF\xBB\xBF//`,
  ps1 `StripBom`/`0xFEFF`)·`>= 버전` 추출(연산자 외 무매치)·`package.json` 버전 읽기·**semver 비교**
  (major.minor.patch, 선행 v 선택 → satisfied/violation/skip)·`check_contract`를 추가하고 시나리오 8종 보강.
  ReadDeps는 이름만 방출(버전 절 제거)해 위상정렬에 버전 제약이 영향 없게 유지. run.ps1 ASCII 소스(0
  non-ASCII)·run.sh BOM 없음·활성 가드 규율 유지. README 시나리오 표(15→23건)에 계약·BOM 케이스 추가.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | (없음 — 픽스처 `.tide/deps`·BOM 파일은 테스트 임시 생성) |
| 수정 | `docs/conventions.md` (T01); `skills/fleet/SKILL.md` (T02); `tests/fleet/run.sh`·`run.ps1`·`README.md` (T03) |
| 삭제 | (없음) |

## 테스트 결과

자동 러너 없는 프로젝트라(도그푸딩) 라이브 하니스로 검증했다.

- **`sh tests/fleet/run.sh`** → **PASS=23 / FAIL=0 (exit 0)**.
- **`& tests\fleet\run.ps1`** → **PASS=23 / FAIL=0 (exit 0)** (non-ASCII 0 확인).
- **회귀**: `sh tests/multi-repo/run.sh` → exit 0.

신규 시나리오(양 셸 공통): 계약 **만족**(auth≥0.2.0·현재 0.2.0→satisfied), **위반**(auth≥0.3.0·현재
0.2.0→violation/upstream behind), **연산자 외 무시**(auth>v0.1.0→none), **버전 파싱 불가**(auth≥banana→
skip), **버전 제약 줄도 토포 이름 의존 유지**(auth 먼저), **BOM 내성**(BOM+주석 첫 줄 무시·의존명 정상
파싱·BOM'd 줄 계약 비교 정상·BOM+의존명 첫 줄 매칭). 기존 15건(발견·5분류·요약·숨김·강등·위상정렬·
순환·미선언·미존재명) 유지.

**구현 메모**
- 정규 spec(계약 버전·BOM)을 conventions 단일 원본으로 두고 스킬·테스트가 인용해 3-way 병렬에도 정합.
  메인이 양 셸 23/23 재확인.
- semver 비교는 **major.minor.patch 숫자**만(선행 v 선택). 비표준 버전은 skip(오탐·크래시 없음).
- `>=`만 지원(의존 계약의 지배적 의미). 다른 연산자는 무시+경고(미달로 단정 안 함 — 안전 측).

## 미해결·후속 메모

1. **연산자 확장**: 이번은 `>=`만. `>` `=` `<=` `<`(범위·정확 일치)는 후속(범위 밖). 필요 시 다음 사이클.
2. **세션 레벨 upstream-behind 실증**: 샌드박스 `svc-auth`가 0.2.0이라 `svc-orders/.tide/deps`에
   `svc-auth >= v0.3.0`을 넣고 `/tide:fleet`을 돌리면 실제 `⚠ upstream behind`가 뜨는지 세션 레벨 1회
   확인 권장(리뷰/릴리즈 후 — README 수동 절차). 단, 샌드박스 deps는 BOM 붙은 상태라 이번 BOM 내성으로
   파싱도 함께 검증됨.
3. **참조 구현 이중성(이월)**: 계약 비교·semver를 스킬 산문 + 하니스가 각자 표현. conventions 단일
   원본으로 완화하나 규약 변경 시 동기화 부담 잔존. 저위험.
4. **3층/4층 후속**: 교차 사이클 자동화(review까지·cross-repo git 비자동화 불변)·통합 검증 훅은 별도
   마일스톤. 유지된 샌드박스가 테스트 베드.
