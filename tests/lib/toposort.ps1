# tide topological sort reference implementation -- single source (Windows PowerShell 5.1)
#
# TopoSort (Kahn variant, depended-upon first, returns 'CYCLE' on a cycle) is the single definition
# of dependency-aware order shared by the fleet / fleet-cycle harnesses. The single source is the
# dependency-order convention in the "multi-repo orchestration" section of docs/conventions.md;
# this file fixes that rule as an equivalent reference procedure.
#
# Dependency: TopoSort calls Discover and ReadDeps internally. The harness must therefore dot-source
# tests\lib\discover.ps1 (provides Discover) and tests\lib\deps.ps1 (provides ReadDeps) BEFORE this
# file -- source order: discover -> deps -> toposort. ASCII-only source (zero non-ASCII bytes, no
# BOM). No side effects -- definitions only.
# Usage: . (Join-Path $PSScriptRoot '..\lib\discover.ps1'); . (Join-Path $PSScriptRoot '..\lib\deps.ps1'); . (Join-Path $PSScriptRoot '..\lib\toposort.ps1')

# --- dependency-aware order reference: topological sort (depended-upon first) + cycle detection ---
# Names not in the discovered set are ignored (safe side). Unconsumed nodes -> cycle -> sentinel CYCLE.
function TopoSort($parent) {
    $nodes = @(Discover $parent)                              # discovered repos (sorted)
    if ($nodes.Count -eq 0) { return '' }

    # edges: keep only deps that are in the discovered set (ignore unknown names)
    # (M42-T03) Three ordinal pins here. A bare `@{}` hashtable looks its keys up CASE-INSENSITIVELY
    # (measured: $h['Foo']=1 then $h['FOO'] returns 1), and `-contains` is culture-aware AND
    # case-insensitive. Repo names are filesystem names, which are byte-distinct on POSIX, and the
    # order string this function returns is compared AS A STRING by the fleet / fleet-cycle harnesses
    # -- so 'auth' and 'AUTH' silently collapsing into one edge set would change the verdict while the
    # .sh twin (`case`/`=` on raw names) kept them apart.
    $nodeSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($n in $nodes) { [void]$nodeSet.Add([string]$n) }
    $edges = New-Object 'System.Collections.Hashtable' ([System.StringComparer]::Ordinal)
    foreach ($r in $nodes) {
        $kept = @()
        foreach ($dep in (ReadDeps (Join-Path $parent $r))) {
            if ($nodeSet.Contains([string]$dep)) { $kept += $dep }
        }
        $edges[$r] = $kept
    }

    $remaining = New-Object System.Collections.ArrayList
    [void]$remaining.AddRange($nodes)
    $order = @()
    # Kahn variant: emit nodes whose deps are all already emitted; no progress -> cycle.
    while ($remaining.Count -gt 0) {
        $progressed = $false
        $next = New-Object System.Collections.ArrayList
        # ordinal membership for the same reason as above (`-contains` is culture + case-insensitive)
        $remSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($n in $remaining) { [void]$remSet.Add([string]$n) }
        foreach ($r in $remaining) {
            $ready = $true
            foreach ($dep in $edges[$r]) {
                if ($remSet.Contains([string]$dep)) { $ready = $false; break }  # dep not yet emitted
            }
            if ($ready) { $order += $r; $progressed = $true } else { [void]$next.Add($r) }
        }
        if (-not $progressed) { return 'CYCLE' }
        $remaining = $next
    }
    return ($order -join ' ')
}
