# M26 완료보고서 (impl)

## 개요

M26(잔여 후속 결산)의 세 태스크를 모두 구현했다. 코드성으로 열려 있던 마지막 두 건을 닫았다 —
참조 구현의 BOM 제거 헬퍼(`strip_bom`/`StripBom`)를 `tests/lib/encoding.{sh,ps1}` 단일 원본으로
추출해 정의를 셸당 1개로 수렴시켰고(M24 sn3·M25 sn3 종결), M22부터 연속 환경-이월돼 온 사이트
스니펫 인클루드 검증을 mkdocs 없이 도는 자기완결 하니스 `tests/site-includes/run.{sh,ps1}`로
결정적으로 메웠다. 마지막으로 두 결산을 `project-context.md`·`conventions.md`에 기록했다. 독립인
T01·T02는 변경 파일이 비중첩이라 서브에이전트로 **병렬 실행**했고, 문서 결산 T03만 그 뒤에 순차로
처리했다.

## 태스크별 수행 내용

- **M26-T01** — `strip_bom`/`StripBom` 단일 원본화. **경로 A**(권장)를 택해 BOM 제거 헬퍼만 담는
  단일 책임 `tests/lib/encoding.sh`·`encoding.ps1`을 신설하고, 체인 **맨 앞**에서 source하도록
  배선했다(`encoding → discover → deps → toposort` — `deps`의 `read_deps`가 `strip_bom`을 쓰므로
  encoding 선행). `tests/lib/deps.{sh,ps1}`의 로컬 정의와 `tests/fleet-verify/run.{sh,ps1}`의 로컬
  복제(이전엔 `deps` 공유본과 바이트 동일했음)를 제거했다. fleet-verify는 `deps`가 아닌
  `.tide-fleet/integration`을 파싱하느라 `discover`만 source했었는데, `read_hook`/`ReadHook`가 쓰는
  BOM 헬퍼를 위해 `encoding` source 한 줄을 더했다. 헬퍼 본문은 **바이트 동일**로 옮겨(동작 무변경)
  기존 source-ordering 관례(`toposort`가 `deps` 선행을 가정하듯 libs는 선행을 자체 source하지 않고
  하니스가 순서를 잡음)를 그대로 따랐다. `deps.{sh,ps1}`의 "단일 deps-parse 규칙" 주석은 새 홈
  (`encoding`)을 가리키도록 정합했고, `tests/fleet-verify/run.ps1`의 BOM **픽스처**(`[char]0xFEFF`)는
  헬퍼가 아니라 손대지 않았다. (서브에이전트 위임, 반환 계약 충족.)

- **M26-T02** — 자기완결 사이트 인클루드 검증 하니스 `tests/site-includes/run.{sh,ps1}` 신설.
  `tests/discover` 구조(스크립트 위치 기준 ROOT, `chk`/`Chk` 카운터, PASS/FAIL 집계, exit 0/1, BOM
  규율)를 미러링했다. mkdocs 없이: ① `site/docs/*.md`의 인클루드 지시 `--8<-- "<target>:<section>"`를
  스캔으로 열거(하드코딩 아님 — 새 셸도 잡힘), ② 각 `<target>` 존재 + 균형 잡힌 마커 쌍
  `<!-- --8<-- [start:<section>] -->`/`[end:<section>]`이 정확히 1쌍(start 선행)인지, ③ 캐노니컬
  타깃마다 중복·고아 마커 없는지, ④ 마커 구획 본문에서 제외 용어 0건인지 검증한다. **마커 매칭은
  bare `[start:notes]`가 아니라 `--8<-- ` 접두를 앵커링**해 CHANGELOG 본문/설명 주석의 동명 문자열
  오탐을 배제했다(설계 결정). 제외 용어는 하니스에 하드코딩하지 않고(그 자체가 누수·드리프트가 됨)
  마커 **바깥** 마스트헤드(`README.md`/`docs/conventions.md` 3행)에서 런타임 추출한다 — 추출 결과가
  비면 시끄럽게 실패시켜 스캔이 공허해지지 않게 했다. 헤더 주석에 스코프 경계(= `mkdocs build
  --strict` 대체 아님, 렌더·nav/link는 CI 몫; `tests/discover` B2의 "셸 여부"와 중복 아님 — 타깃·마커
  해석 + 용어 스캔까지 감)를 명시했다. (서브에이전트 위임, 반환 계약 충족.)

- **M26-T03** — 문서 결산(deps: T01, T02). `docs/project-context.md` "이월 항목 처분 원장"에 두 행
  추가(`strip_bom` 단일 원본화 = **fix(M26)**, mkdocs 로컬 사각지대 = **fix(부분, M26)** — 렌더 잔여만
  환경-이월로 명시), 닫힘 문단에 M26이 코드성 잔여 두 건을 닫고 남는 미반영은 의도적 수용
  (`tide-guard` raw-`$input` grep)·라이브 도그푸딩(gh/`pr` finalize)뿐임을 추가. "진입점·빌드/테스트"
  하니스 목록과 디렉터리 구조 표에 `tests/site-includes`·`tests/lib/encoding`을 반영하고 source 순서를
  `encoding→discover→deps→toposort`로 갱신. `docs/conventions.md`는 "릴리즈 빌드 출력 검증"에 **3분담**
  (수기 release 스캔 · CI `--strict` · 로컬 `tests/site-includes` 가드)을 기록하고, "규약↔실행 동기화"에
  M26 적용 예(BOM 단일 원본화 + 인클루드 가드 배선)를 추가. (메인 직접 — 레벨 단일 태스크.)

## 변경 파일 요약

| 구분 | 파일 |
|---|---|
| 추가 | `tests/lib/encoding.sh`, `tests/lib/encoding.ps1`, `tests/site-includes/run.sh`, `tests/site-includes/run.ps1` |
| 수정 | `tests/lib/deps.sh`, `tests/lib/deps.ps1`(로컬 BOM 정의 제거·주석 정합), `tests/fleet-verify/run.sh`, `tests/fleet-verify/run.ps1`(로컬 복제 삭제·`encoding` source 추가), `tests/fleet/run.sh`, `tests/fleet/run.ps1`, `tests/fleet-cycle/run.sh`, `tests/fleet-cycle/run.ps1`(source 체인에 `encoding` 추가·주석), `docs/project-context.md`, `docs/conventions.md` |
| 삭제 | (정의 이동) `tests/fleet-verify/run.{sh,ps1}`·`tests/lib/deps.{sh,ps1}`의 로컬 `strip_bom`/`StripBom` 정의 |

## 테스트 결과

자동 테스트 러너는 없고 `tests/`의 자기완결 라이브 하니스를 **양 셸**로 실행해 검증했다(메인이 T01·T02
통합 후 재실행한 결과 — 베이스라인은 M25 리뷰의 `19·41·23·29·10 / FAIL 0`).

| 하니스 | M25 baseline | sh | ps1 |
|---|---|---|---|
| discover | PASS 19 | PASS 19 / FAIL 0, exit 0 | PASS 19 / FAIL 0, exit 0 |
| fleet | PASS 41 | PASS 41 / FAIL 0, exit 0 | PASS 41 / FAIL 0, exit 0 |
| fleet-cycle | PASS 23 | PASS 23 / FAIL 0, exit 0 | PASS 23 / FAIL 0, exit 0 |
| fleet-verify | PASS 29 | PASS 29 / FAIL 0, exit 0 | PASS 29 / FAIL 0, exit 0 |
| multi-repo | PASS 10 | PASS 10 / FAIL 0, exit 0 | PASS 10 / FAIL 0, exit 0 |
| **site-includes** (신규) | — | PASS 27 / FAIL 0, exit 0 | PASS 27 / FAIL 0, exit 0 |

- **동작 보존**: 기존 5개 하니스 모두 양 셸에서 M25 baseline과 PASS 수 **동일**, exit 0. BOM 헬퍼 이동은
  순수 재배선(본문 바이트 동일)임을 수치로 확인.
- **단일 정의 확인**: `grep -rn` 결과 `strip_bom()`(sh) 정의 **정확히 1개**(`tests/lib/encoding.sh:14`),
  `function StripBom`(ps1) 정의 **정확히 1개**(`tests/lib/encoding.ps1:15`). fleet-verify 로컬 복제 소멸,
  나머지는 모두 호출(use)일 뿐.
- **신규 하니스 음성 케이스**(T02 서브에이전트 검증): `docs/orchestration.md`의 `[end:body]` 마커를
  일시 제거하면 양 셸이 동일하게 FAIL=2(exit 1)로 검출하고 위치를 지목 → 파일 원복(md5 동일) 후 다시
  green. 검증이 실제로 무는지 확인됨.
- **인코딩 규율**: 신규 `.sh`(encoding/site-includes) BOM 없음, 신규 `.ps1`은 규약대로(`encoding.ps1`은
  자매 `tests/lib/*.ps1`와 동일하게 no-BOM·ASCII-only, `site-includes/run.ps1`은 BOM·ASCII-only). 비ASCII
  소스 0.

## 미해결·후속 메모

1. **T02 제외 용어 런타임 추출의 견고성(리뷰 확인 권장)**: 하니스는 제외 용어를 하드코딩하지 않으려고
   마스트헤드(`README.md`/`docs/conventions.md` 3행)의 "외부 저장소명 + `의 개발 방법론`" 패턴에서
   런타임 추출한다(현재 1개 추출 — 출력엔 `terms=[…]`로만 표기, literal 누수 없음). 의도는 좋으나
   마스트헤드 표현이 바뀌면 추출이 비어 **공허한 스캔**이 될 수 있다 — 이를 막으려 "추출 0개면 FAIL"
   가드를 넣었으니 침묵 실패는 아니나, 리뷰가 이 추출 휴리스틱 대 "용어를 별도 비-인클루드 데이터
   파일에 두고 읽기" 같은 대안의 트레이드오프를 한 번 판단해두면 좋다. (저위험·기능 정상.)
2. **`mkdocs --strict` 실제 렌더는 여전히 CI 잔여(환경-이월)**: `tests/site-includes`는 인클루드 타깃·
   마커·용어의 로컬 사각지대를 닫았을 뿐 실제 렌더·nav/link·mkdocs 설정 회귀는 검사하지 않는다(설계
   경계). 그 부분은 `deploy-pages.yml`의 `mkdocs build --strict`에 남으며, mkdocs 가용 환경/배포에서만
   회수된다. 본 마일스톤 범위 밖.
3. **범위 밖 의도적 수용 항목(불변)**: `tide-guard.sh`의 raw-`$input` grep 거칠음(M13 사소3→M18 사소6)은
   POSIX 명령 파싱 취약성 회피를 위한 의도적 트레이드오프로 M26에서 손대지 않았다. gh 게시·`pr` finalize
   라이브 실증은 코드 부채가 아니라 다음 `pr` 도그푸딩 회수 대상으로 유지.
4. **드리프트 가드 B2와의 관계**: `tests/site-includes`(타깃·마커·용어)와 `tests/discover` B2(사이트
   페이지가 스니펫 셸인지)는 상보적이며 중복 검사가 아니다(주석에 경계 명시). 향후 사이트 셸이 늘면
   site-includes는 스캔 기반이라 자동 포착되나, B1(`11종` 카운트)·B3(이름 완전성)와의 경계는 그대로다.
