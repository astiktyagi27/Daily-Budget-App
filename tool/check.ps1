# One-command check for the Daily Budget App (plan F-001, task T-006).
#
# Runs, from app/: flutter pub get -> dart format check -> flutter analyze ->
# dart analyze --fatal-infos -> test-name check -> flutter test -> engine
# coverage gate -> time-zone matrix. Prints PASS/FAIL per step, stops at the
# first failure and exits 1; exits 0 when every step passes.
# Phase 2 (F-007, T-206): a Drift codegen step runs right after pub get and
# fails if a committed generated file or schema snapshot is out of date; the
# coverage gate (tool/domain_coverage.ps1) and the TZ matrix
# (tool/tz_matrix.ps1) run after flutter test, only when lib/domain/ and
# test/domain/ exist (PM decision, T-206).
# dart analyze runs as well because analyzer plugins (riverpod_lint, D-027)
# report only there, not in flutter analyze (T-129).
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

    # Generated Drift code and schema snapshots are committed (F-007). The
    # step regenerates them and fails if any file changed, so a source edit
    # can never leave stale generated code behind. Skipped until the database
    # exists.
    $databaseSource = Join-Path $appDir 'lib/data/database/app_database.dart'
    if (Test-Path -LiteralPath $databaseSource) {
        $step = 'drift codegen is up to date'
        Write-Host ('--- ' + $step)
        $generatedRoots = @('lib', 'drift_schemas', 'test\drift') |
            ForEach-Object { Join-Path $appDir $_ } |
            Where-Object { Test-Path -LiteralPath $_ }
        $snapshot = {
            Get-ChildItem -LiteralPath $generatedRoots -Recurse -File |
                Where-Object { $_.Name -like '*.g.dart' -or $_.FullName -like '*drift_schemas*' -or $_.FullName -like '*test?drift*' } |
                Sort-Object FullName |
                ForEach-Object { $_.FullName.Substring($appDir.Length + 1) + ' ' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
        }
        $before = @(& $snapshot)
        & $dart run build_runner build
        if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
        $after = @(& $snapshot)
        $changed = @(Compare-Object $before $after)
        if ($changed.Count -gt 0) {
            Write-Host 'Generated files changed (commit them, they are part of the source):'
            $changed | ForEach-Object { Write-Host ('  ' + $_.InputObject) }
            Stop-WithFailure $step
        }
        # The committed snapshot of the current schema must equal a fresh dump
        # (TC-007-14): a schema edit without a version bump or snapshot fails.
        $dump = Join-Path ([IO.Path]::GetTempPath()) 'daily_budget_schema_dump.json'
        & $dart run drift_dev schema dump lib/data/database/app_database.dart $dump
        if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
        $versionLine = Select-String -LiteralPath $databaseSource -Pattern 'int get schemaVersion => (\d+);'
        $version = $versionLine.Matches[0].Groups[1].Value
        $snapshotFile = Join-Path $appDir ('drift_schemas/app_database/drift_schema_v' + $version + '.json')
        if (-not (Test-Path -LiteralPath $snapshotFile)) {
            Write-Host ('Missing schema snapshot: ' + $snapshotFile)
            Stop-WithFailure $step
        }
        if ((Get-FileHash -LiteralPath $dump).Hash -ne (Get-FileHash -LiteralPath $snapshotFile).Hash) {
            Write-Host ('The schema differs from the committed snapshot ' + $snapshotFile)
            Stop-WithFailure $step
        }
        Write-Host ('Checked ' + $after.Count + ' generated file(s).')
        Write-Result $step $true
    }

    $step = 'dart format (check only)'
    Write-Host ('--- ' + $step)
    # Only the source folders, never `.`: a path over 260 characters under
    # app/build (a profile build creates them) breaks `dart format` on
    # Windows, and build output needs no formatting (D-093).
    $formatFolders = @('lib', 'test', 'integration_test', 'test_driver') |
        Where-Object { Test-Path -LiteralPath (Join-Path $appDir $_) }
    & $dart format --output=none --set-exit-if-changed @formatFolders
    if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
    Write-Result $step $true

    $step = 'flutter analyze'
    Write-Host ('--- ' + $step)
    & $flutter analyze
    if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
    Write-Result $step $true

    # Analyzer plugins (riverpod_lint) report only here; infos fail too.
    $step = 'dart analyze --fatal-infos'
    Write-Host ('--- ' + $step)
    & $dart analyze --fatal-infos
    if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
    Write-Result $step $true

    # Every test()/testWidgets() name must start with a test case ID: TC-NNN-NN.
    # The name may be on the line after the opening parenthesis. A call
    # preceded by '.' or a word character (ProviderContainer.test(, mytest()
    # is not a test declaration (T-129).
    $step = 'test names start with TC-NNN-NN'
    Write-Host ('--- ' + $step)
    $callPattern = '(?<![.\w])(?:test|testWidgets)\(\s*'
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

    # Engine coverage and the three-zone date run (F-006 AC-23, AC-24). The
    # scripts run in this process; they call `exit`, which ends only the
    # script. The TZ matrix also runs the F-007 date test.
    if ((Test-Path -LiteralPath (Join-Path $appDir 'lib\domain')) -and
        (Test-Path -LiteralPath (Join-Path $appDir 'test\domain'))) {
        $step = 'domain coverage (lib/domain/budget)'
        Write-Host ('--- ' + $step)
        & (Join-Path $PSScriptRoot 'domain_coverage.ps1')
        if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
        Write-Result $step $true

        $step = 'time-zone matrix (UTC, PST8PDT, IST)'
        Write-Host ('--- ' + $step)
        $tzTests = @('test/domain/budget')
        $databaseTzTest = 'test/data/database/database_time_zone_test.dart'
        if (Test-Path -LiteralPath (Join-Path $appDir $databaseTzTest)) {
            $tzTests += $databaseTzTest
        }
        & (Join-Path $PSScriptRoot 'tz_matrix.ps1') -Tests $tzTests
        if ($LASTEXITCODE -ne 0) { Stop-WithFailure $step }
        Write-Result $step $true
    }

    Write-Host ''
    Write-Host 'ALL CHECKS PASSED' -ForegroundColor Green
    exit 0
} finally {
    Pop-Location
}
