# tide discovery rule reference implementation -- single source (Windows PowerShell 5.1)
#
# IsTideRepo + Discover are the single definition of the discovery rule shared by the fleet-family
# harnesses (discover / fleet / fleet-cycle / fleet-verify). The convention's single source is the
# "multi-repo orchestration" section of docs/conventions.md (immediate children / skip hidden (dot)
# dirs / git repo AND tide artifacts); this file fixes that rule as an equivalent reference procedure.
#
# ASCII-only source (zero non-ASCII bytes, no BOM). No side effects -- function definitions only.
# A harness dot-sources it: . (Join-Path $PSScriptRoot '..\lib\discover.ps1')

# --- discovery reference: immediate children, skip hidden (dot) dirs, git repo AND tide artifacts ---
# A `.tide-fleet/` directory is a hidden (dot) dir, so it is never picked up as a child repo
# (it is the integration-hook store, not a child).
function IsTideRepo($d) {
    $isGit = Test-Path (Join-Path $d '.git')
    if (-not $isGit) { & git -C $d rev-parse --show-toplevel 2>$null | Out-Null; $isGit = ($LASTEXITCODE -eq 0) }
    if (-not $isGit) { return $false }
    foreach ($m in @('docs\milestones', '.tide', 'package.json', 'Cargo.toml', 'pyproject.toml', '.claude-plugin\plugin.json')) {
        if (Test-Path (Join-Path $d $m)) { return $true }
    }
    return $false
}
function Discover($parent) {
    Get-ChildItem -Directory $parent -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '.*' -and (IsTideRepo $_.FullName) } | ForEach-Object { $_.Name } | Sort-Object
}
