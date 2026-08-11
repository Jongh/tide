# tide 발견 규약 참조 구현 — 단일 원본 (POSIX / Git Bash)
#
# `is_tide_repo` + `discover`는 fleet 계열 하니스(discover·fleet·fleet-cycle·fleet-verify)가
# 공유하는 발견 규약의 단일 정의다. 규약의 단일 원본은 `docs/conventions.md` "멀티 레포
# 오케스트레이션" 절의 발견 규약(직속 1단계·숨김(dot) 제외·git 레포 AND tide 산출물)이며,
# 이 파일은 그 규약을 동일 로직의 참조 셸 절차로 고정한다.
#
# 부수효과 없음 — 함수 정의만 담는다. 하니스가 ROOT 해석 직후 source 후 호출한다.
# 사용: . "$ROOT/tests/lib/discover.sh"

# --- 발견 규약(참조 구현): 직속 1단계, 숨김(.) 무시, git 레포 AND tide 산출물 ---
is_tide_repo() { # <dir>
    d="$1"
    { git -C "$d" rev-parse --show-toplevel >/dev/null 2>&1 || [ -d "$d/.git" ]; } || return 1
    [ -d "$d/docs/milestones" ] || [ -d "$d/.tide" ] || [ -f "$d/package.json" ] || \
        [ -f "$d/Cargo.toml" ] || [ -f "$d/pyproject.toml" ] || [ -f "$d/.claude-plugin/plugin.json" ]
}
discover() { # <parent> → 직속 자식 tide 레포 basename 정렬 출력
    for d in "$1"/*/ ; do
        [ -d "$d" ] || continue
        base=$(basename "${d%/}")
        case "$base" in .*) continue ;; esac          # 숨김(dot) 디렉터리 무시(.tide-fleet 포함)
        if is_tide_repo "${d%/}"; then echo "$base"; fi
    done | LC_ALL=C sort
}
# (M42) `LC_ALL=C`는 장식이 아니다 — 이 출력은 fleet 하니스가 **문자열로 통째 비교**하는 판정값이라
# (`$(discover …) | tr '\n' ','` ↔ 리터럴) 정렬 **순서 자체가 판정에 든다**. ps1 사본은 M42-T03에서
# `StringComparer::Ordinal`로 고정됐고, 로케일이 걸린 `sort`는 collation 비교라 두 사본의 의미가
# 갈린다(M40이 `tests/discover/run.sh`에서 같은 누락을 BSD 레그로 발견한 것과 같은 부류 — 그때는
# 러너 안이었고 이번은 **공유 단일 원본**이다).
