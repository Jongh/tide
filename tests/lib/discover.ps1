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
# (M42-T03) Both comparisons here are pinned to ORDINAL.
#   - Sort-Object is CULTURE collation, not byte order (M41 measured it: culture puts 'docs' before
#     'README.md', byte order puts 'README.md' first). This output is compared AS A STRING by the
#     fleet harnesses -- `(Discover $P) -join ','` against a literal 'repo-a,repo-b,repo-c,...' -- so
#     the sort ORDER is part of the verdict, not presentation.
#   - `-notlike '.*'` is culture-aware AND case-insensitive; the hidden-dir test is pinned with the
#     same ordinal StartsWith M38 applied throughout tests/discover/run.ps1.
# NOTE for the .sh twin: tests/lib/discover.sh ends this function with a BARE `sort`. Every other
# sort in the .sh harnesses carries `LC_ALL=C` (M40 added the last missing one after a BSD leg
# diverged); this one does not, so under a non-C locale the two copies can order differently. Not
# changed here -- reporting only, per this task's scope.
function Discover($parent) {
    $names = New-Object 'System.Collections.Generic.List[string]'
    foreach ($e in (Get-ChildItem -Directory $parent -ErrorAction SilentlyContinue)) {
        if ($e.Name.StartsWith('.', [System.StringComparison]::Ordinal)) { continue }
        if (IsTideRepo $e.FullName) { [void]$names.Add([string]$e.Name) }
    }
    $names.Sort([System.StringComparer]::Ordinal)
    return @($names.ToArray())
}
