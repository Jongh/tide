# tide 위상정렬 참조 구현 — 단일 원본 (POSIX / Git Bash)
#
# `toposort`(Kahn 변형, 피의존 우선, 순환 시 `CYCLE` 반환)는 fleet·fleet-cycle 하니스가
# 공유하는 의존성 인식 순서의 단일 정의다. 단일 원본은 `docs/conventions.md` "멀티 레포
# 오케스트레이션" 절의 의존성 순서 규약이며, 이 파일은 그 규약을 참조 셸 절차로 고정한다.
#
# 의존성: `toposort`는 내부에서 `discover`·`read_deps`를 호출한다. 따라서 하니스는 이 파일을
# source하기 전에 `tests/lib/discover.sh`(discover 제공)와 `tests/lib/deps.sh`(read_deps 제공)를
# 먼저 source해야 한다 — source 순서: discover → deps → toposort. 부수효과 없음 — 함수 정의만 담는다.
# 사용: . "$ROOT/tests/lib/discover.sh"; . "$ROOT/tests/lib/deps.sh"; . "$ROOT/tests/lib/toposort.sh"

# --- 의존성 인식 순서(참조 구현): 위상정렬(피의존 우선) + 순환 감지 폴백 ---
# 발견 집합에 없는 이름은 무시(안전 측). 모든 노드를 소비 못하면 순환 → 센티넬 CYCLE.
toposort() { # <parent> → "depA depB ..."(공백 구분, 피의존 먼저) | "CYCLE"
    parent="$1"
    nodes=$(discover "$parent")                              # 발견된 레포(정렬됨)
    [ -n "$nodes" ] || { echo ""; return 0; }

    # edges_<repo> = 발견 집합에 든 의존 대상만(미존재명 무시)
    set -- $nodes
    for r in $nodes; do
        kept=""
        for dep in $(read_deps "$parent/$r"); do
            for n in $nodes; do                              # 발견 집합 멤버십 검사
                if [ "$dep" = "$n" ]; then kept="$kept $dep"; break; fi
            done
        done
        eval "edges_$r=\"$kept\""
    done

    remaining="$nodes"
    order=""
    # Kahn 변형: 미해결 의존이 0인 노드를 발견 순서대로 방출, 진전 없으면 순환.
    while [ -n "$(printf '%s' "$remaining" | tr -d '[:space:]')" ]; do
        progressed=0
        next_remaining=""
        for r in $remaining; do
            eval "deps=\$edges_$r"
            ready=1
            for dep in $deps; do
                # dep이 아직 remaining에 있으면(아직 미방출) 이 노드는 대기
                for rem in $remaining; do
                    if [ "$dep" = "$rem" ]; then ready=0; break; fi
                done
                [ "$ready" -eq 1 ] || break
            done
            if [ "$ready" -eq 1 ]; then
                order="$order $r"; progressed=1
            else
                next_remaining="$next_remaining $r"
            fi
        done
        if [ "$progressed" -eq 0 ]; then echo "CYCLE"; return 0; fi
        remaining="$next_remaining"
    done
    # 선두 공백 제거
    printf '%s\n' "$order" | sed 's/^[[:space:]]*//'
}
