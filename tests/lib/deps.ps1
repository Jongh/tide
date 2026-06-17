# tide .tide/deps parse reference implementation -- single source (Windows PowerShell 5.1)
#
# ReadDeps (emits dependency names for topo sort) and its direct helper DepName are the single
# definition of the deps-parse rule shared by the fleet / fleet-cycle harnesses. The rule's
# single source is the "contract comparison" / "multi-repo orchestration" sections of
# docs/conventions.md (one sibling repo name per line / skip #-comments and blanks / trim / strip a
# leading UTF-8 BOM / name = first whitespace token up to the operator); this file fixes that rule
# as an equivalent reference procedure. The leading-BOM helper StripBom was promoted to the general
# encoding helper in tests\lib\encoding.ps1 -- this file uses that earlier-sourced StripBom (see below).
#
# Dependency: ReadDeps calls StripBom, so the harness must dot-source tests\lib\encoding.ps1 FIRST.
# TopoSort also calls ReadDeps internally, so it must dot-source this file BEFORE tests\lib\toposort.ps1
# (provides ReadDeps). Source order: encoding -> discover -> deps -> toposort.
# ASCII-only source (zero non-ASCII bytes, no BOM). No side effects -- function definitions only.
# Usage: . (Join-Path $ROOT 'tests\lib\encoding.ps1'); . (Join-Path $ROOT 'tests\lib\discover.ps1'); . (Join-Path $ROOT 'tests\lib\deps.ps1'); . (Join-Path $ROOT 'tests\lib\toposort.ps1')
#
# Extraction scope: only ReadDeps (+ DepName) needed for topo sort is unified here. The leading-BOM
# strip (StripBom) lives in encoding.ps1; contract-comparison-only functions (DepRequired* / Semver* /
# EvalOp / CheckContract) are OUT OF scope and stay local to each harness. (M17 BOM strip + M20
# full-operator name preservation are the adopted canonical: DepName takes the first whitespace token,
# then cuts at the operator.)

# StripBom (leading UTF-8 BOM strip) moved to tests\lib\encoding.ps1 (general encoding helper).
# The harness dot-sources encoding first, so DepLines uses that StripBom as-is.
# read raw lines with explicit BOM strip on the first line (independent of Get-Content's handling)
function DepLines($f) {
    $lines = @(Get-Content $f)
    if ($lines.Count -gt 0) { $lines[0] = StripBom $lines[0] }
    return $lines
}
# bare repo name = first whitespace-delimited token (spec format `<name> <op> <ver>`);
# a no-space form (`auth>=v`) is cut at the operator. ANY operator (incl. unknown `~>`) keeps the
# name intact -> the topo dependency edge survives (spec invariant).
function DepName($line) {
    $first = ($line.Trim() -split '\s+')[0]
    return ($first -replace '(>=|<=|==|=|>|<).*$', '')
}
# emit dependency sibling names from .tide/deps (for topo sort); version constraints are queried
# separately by harness-local functions.
function ReadDeps($repoDir) {
    $f = Join-Path $repoDir '.tide\deps'
    if (-not (Test-Path $f)) { return @() }
    $out = @()
    foreach ($line in (DepLines $f)) {
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }   # blank / comment
        $out += (DepName $t)
    }
    return $out
}
