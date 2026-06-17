# tide .tide/deps 파싱 참조 구현 — 단일 원본 (POSIX / Git Bash)
#
# `read_deps`(위상정렬용 이름 방출)와 그 직접 보조 `dep_name`는 fleet·fleet-cycle
# 하니스가 공유하는 deps 파싱 규약의 단일 정의다. 규약의 단일 원본은 `docs/conventions.md`
# "계약 비교 규칙"·"멀티 레포 오케스트레이션" 절(한 줄에 형제 레포명 하나·# 주석/빈 줄 무시·
# 트림·선두 UTF-8 BOM 제거·이름은 첫 공백 토큰에서 연산자 앞까지)이며, 이 파일은 그 규약을
# 동일 로직의 참조 셸 절차로 고정한다. 선두 BOM 제거 헬퍼 `strip_bom`은 범용 인코딩 헬퍼라
# `tests/lib/encoding.sh`로 승격됐다 — 이 파일은 앞서 source된 그 `strip_bom`을 쓴다(아래 의존성).
#
# 의존성: `read_deps`가 `strip_bom`을 호출하므로 하니스는 `tests/lib/encoding.sh`를 먼저
# source해야 한다. 또 `toposort`가 내부에서 `read_deps`를 호출하므로 이 파일을 source한 뒤
# `tests/lib/toposort.sh`를 source해야 한다(read_deps 정의 제공). source 순서: encoding →
# discover → deps → toposort. 부수효과 없음 — 함수 정의만 담는다(픽스처·실행 0).
# 사용: . "$ROOT/tests/lib/encoding.sh"; . "$ROOT/tests/lib/discover.sh"; . "$ROOT/tests/lib/deps.sh"; . "$ROOT/tests/lib/toposort.sh"
#
# 추출 범위: 위상정렬에 필요한 `read_deps`(+`dep_name`)만 단일화한다. 선두 BOM 제거(`strip_bom`)는
# `encoding.sh`가, 계약 비교 전용 함수(`dep_required_*`·`semver_*`·`eval_op`·`check_contract` 등)는
# 각 하니스 로컬이 가진다(추출 범위 밖). (M17 BOM 처리·M20 전체 연산자 이름 보존을 정본으로 채택)

# 선두 UTF-8 BOM 제거 헬퍼 `strip_bom`은 `tests/lib/encoding.sh`로 이동(범용 인코딩 헬퍼).
# 하니스가 encoding을 먼저 source하므로 read_deps가 그 정의를 그대로 쓴다.
# 이름 = 첫 공백 토큰(규약 포맷 `<name> <op> <ver>`), 무공백 형(`auth>=v`)은 연산자에서 절단.
# 어떤 연산자든(미지 `~>` 포함) 이름은 보존된다 → 토포 의존 엣지가 유지된다(규약 불변).
dep_name() { # <line> → 형제 레포명(연산자 앞)
    printf '%s' "$1" | awk '{print $1}' | sed -E 's/(>=|<=|==|=|>|<).*$//'
}
# .tide/deps에서 의존 형제명만 방출(위상정렬용). 버전 제약은 하니스 로컬 함수가 따로 조회한다.
read_deps() { # <repo-dir> → 의존 형제명 줄 출력 (없으면 빈 출력)
    f="$1/.tide/deps"
    [ -f "$f" ] || return 0
    strip_bom < "$f" | while IFS= read -r line || [ -n "$line" ]; do
        # 앞뒤 공백 트림
        line=$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        case "$line" in ''|'#'*) continue ;; esac           # 빈 줄·주석 무시
        dep_name "$line"
    done
}
