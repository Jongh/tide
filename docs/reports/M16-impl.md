# M16 완료보고서 (impl)

## 개요

M16의 세 태스크를 모두 구현했다 — `/tide:fleet`이 레포별 `.tide/deps` 선언을 읽어 **의존성 인식
권장 처리 순서**(위상정렬·피의존 우선)를 advisory로 내놓는 오케스트레이션 2층을 세웠다. (T01) 규약을
단일 원본화하고 gitignore를 `.tide/phase`로 좁혀 `.tide/deps`를 커밋 가능하게 했으며, (T02) fleet 스킬에
`.tide/deps` 읽기·위상정렬·순환/미선언/미존재 폴백을 반영하고, (T03) 라이브 하니스에 위상정렬·순환
감지 참조 구현과 시나리오를 더해 sh·ps1 양쪽 **각 15/15 통과**시켰다. 미선언 시 현행 동작 그대로인
옵트인 가산이며, fleet은 여전히 읽기 전용·advisory만(cross-repo git 비자동화). T01·T02·T03은 마일스톤
정규 spec을 공통 인용해 **3-way 병렬 디스패치**로 수행했다(파일 비중첩).

## 태스크별 수행 내용

- **M16-T01** — `docs/conventions.md`("멀티 레포 오케스트레이션" 절, snippet body 안쪽): 로드맵 **2층을
  활성(이번 마일스톤)**으로 갱신, 신규 절 `의존성 선언 (.tide/deps)`·`의존성 인식 순서 규칙`을 단일
  원본으로 추가(레포별·옵트인·커밋 포맷, 위상정렬·순환 폴백·미선언 독립·미존재 무시, 출력에 **권장 처리
  순서** 추가). "상태 파일" 절의 gitignore 서술을 **`.tide/phase`만 무시·`.tide/deps`는 커밋**으로 정합하고
  `.tide/phase` 의미·tide-guard 계약 불변을 명시. `skills/kickoff/SKILL.md`의 `.gitignore` 생성을 `.tide/`→
  `.tide/phase`로 좁히고 `.tide/deps`(옵트인 의존 선언) 한 줄 추가. 이 저장소 `.gitignore`도 `.tide/phase`로
  좁혀 자기 규약 도그푸딩. 1.0 안정성 절·커맨드 수 무변경, 제외 용어 0.
- **M16-T02** — `skills/fleet/SKILL.md`: 신규 절 `.tide/deps 읽기(의존성 선언, 옵트인)`(한 줄당 형제명·
  `#` 주석/빈 줄 무시·트림·미존재명 무시 경고·읽기만)과 출력 항목 **권장 처리 순서**(의존 그래프
  위상정렬, 피의존 우선, 번호/화살표 목록+의존 표기, 순환→레포명 보고+상태 폴백, 미선언→독립) 추가.
  advisory 문구를 "의존성 기반 정렬 미지원(2층 전)"에서 **"의존성 인식 — `.tide/deps` 선언 시 위상정렬,
  순환·미선언 폴백"**으로 갱신. 읽기 전용·부수효과 분리·정규 5버킷 요약은 불변.
- **M16-T03** — `tests/fleet/run.sh`·`run.ps1`·`README.md`: `.tide/deps` 파서(`read_deps`/`ReadDeps`)·
  위상정렬+순환 감지(`toposort`/`TopoSort`, Kahn 변형, 진전 없으면 센티넬 `CYCLE`)·인덱스 헬퍼를 추가하고
  시나리오 4종 보강 — 위상정렬 순서(auth가 orders·gateway보다 앞), 순환 폴백(a↔b→`CYCLE`), 미선언 독립
  (solo 존재), 미존재명 무시(`nowhere` 무시·크래시 없음, 4노드 유지). 기존 발견·5분류·1:1 요약·숨김·강등
  시나리오 유지. run.ps1 ASCII 소스 유지(코드포인트 한글 토큰, 주석 ASCII화), run.sh BOM 없음.

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | (없음 — 픽스처 `.tide/deps`는 테스트 임시 생성) |
| 수정 | `docs/conventions.md`·`skills/kickoff/SKILL.md`·`.gitignore` (T01); `skills/fleet/SKILL.md` (T02); `tests/fleet/run.sh`·`run.ps1`·`README.md` (T03) |
| 삭제 | (없음) |

## 테스트 결과

자동 러너 없는 프로젝트라(도그푸딩) 라이브 하니스로 검증했다.

- **`sh tests/fleet/run.sh`** → **PASS=15 / FAIL=0 (exit 0)**.
- **`& tests\fleet\run.ps1`** → **PASS=15 / FAIL=0 (exit 0)** (non-ASCII 바이트 0 확인).
- **회귀**: `sh tests/multi-repo/run.sh` → exit 0(M13 가드 하니스 무영향).

검증 시나리오(양 셸 공통): 기존 9건(발견·5분류·1:1 요약·숨김·강등) + 신규 6건 — 순환 아님 확인,
위상정렬에서 auth가 orders·gateway보다 앞, 미선언 solo 순서 존재, 미존재명 무시(4노드), 순환 a↔b
`CYCLE` 폴백 감지.

**구현 중 처리한 사항**
- (정합) T01·T02·T03이 마일스톤 정규 spec(`.tide/deps` 포맷·위상정렬·폴백)을 공통 인용해 병렬에도
  서로 일치(conventions=단일 원본, 스킬·테스트가 인용). 메인이 양 셸 재실행으로 정합 확인.
- (인코딩) run.ps1의 기존 한글 주석 2줄을 ASCII 음역+코드포인트 라벨로 정리(한글 토큰 자체는 코드포인트
  유지). 바이트 스캔으로 ASCII-only(0) 재확인.
- (gitignore) `.tide/phase`로 좁힌 뒤 tide 자신은 `.tide/deps`가 없어 동작 무영향, `.tide/phase`는 여전히
  무시(추적 안 됨) 확인.

## 미해결·후속 메모

1. **계약/버전 비교는 범위 밖**: 이번은 이름 기반 의존만. `svc-auth >= v0.3.0` 같은 계약 버전 인식(상류가
   뒤처지면 "blocked: upstream behind" 경고)은 2층 sub-step 또는 별도 후속(리뷰에서 우선순위 판단 바람).
2. **fleet 세션 레벨 순서 출력 재확인**: 위상정렬 순서·순환 폴백 서술은 스크립트로 결정적 핵심만 덮었다.
   실제 `/tide:fleet`이 샌드박스(`.tide/deps` 선언)에서 권장 순서를 기대대로 출력하는지는 세션 레벨 수동
   확인 영역(README). 멀티 레포 실투입 전 1회 권장 — 샌드박스에 deps 선언 후 호출.
3. **참조 구현 이중성(이월)**: 위상정렬을 스킬 산문 + 하니스 양쪽이 표현. conventions 단일 원본으로
   완화했으나 규약 변경 시 동기화 부담 잔존. 저위험·구조적.
4. **3층/4층 후속**: 교차 사이클 자동화(review까지·cross-repo git 비자동화 불변)·통합 검증 훅은 별도
   마일스톤. 유지된 샌드박스 의존 그래프가 테스트 베드로 재사용.
