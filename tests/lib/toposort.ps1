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
    $edges = @{}
    foreach ($r in $nodes) {
        $kept = @()
        foreach ($dep in (ReadDeps (Join-Path $parent $r))) {
            if ($nodes -contains $dep) { $kept += $dep }
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
        foreach ($r in $remaining) {
            $ready = $true
            foreach ($dep in $edges[$r]) {
                if ($remaining -contains $dep) { $ready = $false; break }  # dep not yet emitted
            }
            if ($ready) { $order += $r; $progressed = $true } else { [void]$next.Add($r) }
        }
        if (-not $progressed) { return 'CYCLE' }
        $remaining = $next
    }
    return ($order -join ' ')
}
