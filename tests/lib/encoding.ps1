# tide encoding helper reference implementation -- single source (Windows PowerShell 5.1)
#
# StripBom (remove a leading UTF-8 BOM from a string) is the single definition of the general
# encoding helper shared by the fleet-family harnesses (deps' ReadDeps / fleet / fleet-cycle
# contract comparison / fleet-verify's ReadHook). The rule's single source is the "strip leading
# BOM" rule in docs/conventions.md (remove a leading UTF-8 BOM (EF BB BF) before line parsing);
# this file fixes that rule as an equivalent reference procedure.
#
# ASCII-only source (zero non-ASCII bytes, no BOM). No side effects -- function definition only.
# Source order FIRST (encoding -> discover -> deps -> toposort): deps' ReadDeps uses StripBom, so
# this must be dot-sourced BEFORE deps.
# Usage: . (Join-Path $ROOT 'tests\lib\encoding.ps1')

# M17: strip a leading UTF-8 BOM (U+FEFF) from the first line before parsing.
function StripBom($s) {
    if ($null -ne $s -and $s.Length -gt 0 -and [int]$s[0] -eq 0xFEFF) { return $s.Substring(1) }
    return $s
}
