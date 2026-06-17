# tide 인코딩 헬퍼 참조 구현 — 단일 원본 (POSIX / Git Bash)
#
# `strip_bom`(stdin의 선두 UTF-8 BOM 제거)은 fleet 계열 하니스(deps의 `read_deps`·fleet·
# fleet-cycle의 계약 비교·fleet-verify의 `read_hook`)가 공유하는 범용 인코딩 헬퍼의 단일
# 정의다. 규약의 단일 원본은 `docs/conventions.md` "선두 BOM 무시" 규칙(파일을 읽을 때
# 선두 UTF-8 BOM(`EF BB BF`)을 제거한 뒤 줄 단위로 파싱)이며, 이 파일은 그 규칙을 동일
# 로직의 참조 셸 절차로 고정한다.
#
# 부수효과 없음 — 함수 정의만 담는다. source 순서 맨 앞(encoding → discover → deps →
# toposort): deps의 `read_deps`가 `strip_bom`을 쓰므로 deps보다 먼저 source돼야 한다.
# 사용: . "$ROOT/tests/lib/encoding.sh"

# 선두 UTF-8 BOM(EF BB BF) 제거(M17). 이름 방출/훅 파싱 전 첫 줄에 적용한다.
strip_bom() { sed '1s/^\xEF\xBB\xBF//'; }
