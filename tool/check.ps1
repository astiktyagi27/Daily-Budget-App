# One-command check for the Daily Budget App (plan F-001, task T-006).
#
# Runs, from app/: flutter pub get -> dart format check -> flutter analyze ->
# test-name check -> flutter test. Prints PASS/FAIL per step, stops at the
# first failure and exits 1; exits 0 when every step passes.
# The cheap test-name check runs before flutter test so a bad name fails fast.
#
# PowerShell:  .\tool\check.ps1
# Git Bash:    powershell -ExecutionPolicy Bypass -File tool/check.ps1
#
# Compatible with Windows PowerShell 5.1 (no &&, ||, ?? or ternaries).

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$appDir = Join-Path $projectRoot 'app'

function Find-FlutterTool([string]$name) {
    $onPath = Get-Command $name -ErrorAction SilentlyContinue
    if ($null -ne $onPath) {
        return $onPath.Source
    }
    $roots = @()
    if ($env:FLUTTER_ROOT) {
        $roots += $env:FLUTTER_ROOT
    }
    $roots += 'C:\src\flutter'
    foreach ($root in $roots) {
        $candidate = Join-Path (Join-Path $root 'bin') ($name + '.bat')
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    return $null
}

function Write-Result([string]$step, [bool]$passed) {
    if ($passed) {
        Write-Host ('PASS  ' + $step) -ForegroundColor Green
    } else {
        Write-Host ('FAIL  ' + $step) -ForegroundColor Red
    }
}

# The caller's location is restored by the finally block below, which also
# runs on `exit` and on thrown errors.
function Stop-WithFailure([string]$step) {
    Write-Result $step $false
    Write-Host ''
    Write-Host ('CHECK FAILED at step: ' + $step) -ForegroundColor Red
    exit 1
}

$flutter = Find-FlutterTool 'flutter'
$dart = Find-FlutterTool 'dart'
if ($null -eq $flutter -or $null -eq $dart) {
    Write-Host 'FAIL  locate Flutter: flutter/dart not on PATH, in FLUTTER_ROOT or C:\src\flutter\bin' -ForegroundColor Red
    exit 1
}
Write-Host ('Using Flutter: ' + $flutter)
Write-Host ('Using Dart:    ' + $dart)
Write-Host ('App folder:    ' + $appDir)
Write-Host ''

if (-not (Test-Path -LiteralPath $appDir)) {
    Write-Host ('FAIL  app folder not found: ' + $appDir) -ForegroundColor Red
    exit 1
}

Push-Location -LiteralPath $appDir
try {
    $step = 'flutter pub get'
    Write-Host ('--- ' + $step)
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
    Write-Result $step $true

    $step = 'dart format (check only)'
    Write-Host ('--- ' + $step)
    & $dart format --output=none --set-exit-if-changed .
    if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
    Write-Result $step $true

    $step = 'flutter analyze'
    Write-Host ('--- ' + $step)
    & $flutter analyze
    if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
    Write-Result $step $true

    # Every test()/testWidgets() name must start with a test case ID: TC-NNN-NN.
    # The name may be on the line after the opening parenthesis.
    $step = 'test names start with TC-NNN-NN'
    Write-Host ('--- ' + $step)
    $callPattern = '\b(?:test|testWidgets)\(\s*'
    $namePattern = '\G[''"]TC-\d{3}-\d{2} '
    $badNames = @()
    $testFiles = Get-ChildItem -LiteralPath (Join-Path $appDir 'test') -Recurse -Filter '*.dart' -File
    foreach ($file in $testFiles) {
        $source = [IO.File]::ReadAllText($file.FullName)
        foreach ($call in [regex]::Matches($source, $callPattern)) {
            $nameMatch = [regex]::new($namePattern).Match($source, $call.Index + $call.Length)
            if (-not $nameMatch.Success) {
                $line = ($source.Substring(0, $call.Index) -split "`n").Count
                $badNames += ($file.FullName.Substring($appDir.Length + 1) + ':' + $line)
            }
        }
    }
    if ($badNames.Count -gt 0) {
        Write-Host 'Test calls whose name does not start with TC-NNN-NN:'
        $badNames | ForEach-Object { Write-Host ('  ' + $_) }
        Stop-WithFailure $step
    }
    Write-Host ('Checked ' + $testFiles.Count + ' test file(s).')
    Write-Result $step $true

    $step = 'flutter test'
    Write-Host ('--- ' + $step)
    & $flutter test
    if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
    Write-Result $step $true

    Write-Host ''
    Write-Host 'ALL CHECKS PASSED' -ForegroundColor Green
    exit 0
} finally {
    Pop-Location
}
