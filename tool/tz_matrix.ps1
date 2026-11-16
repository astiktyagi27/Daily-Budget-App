# Time-zone matrix (plan F-006, task T-205; F-006 AC-23, TC-006-27; reused by
# F-007 AC-3).
#
# Runs the given test files or folders (default test/domain/budget) in three
# separate test processes, one per POSIX TZ value: TZ=UTC, TZ=PST8PDT and the
# machine default (IST). IANA names such as Asia/Kolkata are silently ignored
# on Windows (docs/reviews/phase-2-lookahead.md #8), so only POSIX names are
# used. Each run gets --dart-define=EXPECT_TZ_OFFSET_MIN=<minutes> and
# --dart-define=TZ_NAME=<name>, so a sentinel test can prove the zone really
# changed and write build/tz/<name>.txt. When all three dump files exist they
# must be byte-identical. Exits 1 on any failure, 0 otherwise. The caller's TZ
# value is restored at the end.
#
# PowerShell:  .\tool\tz_matrix.ps1 [-Tests test/a_test.dart,test/b]
# Git Bash:    powershell -ExecutionPolicy Bypass -File tool/tz_matrix.ps1
#
# Compatible with Windows PowerShell 5.1 (no &&, ||, ?? or ternaries).

param(
    [string[]]$Tests = @('test/domain/budget'),
    # The default zone's offset on 9 Nov 2026, in minutes (IST = +5:30).
    [int]$DefaultOffsetMinutes = 330
)

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

$flutter = Find-FlutterTool 'flutter'
if ($null -eq $flutter) {
    Write-Host 'FAIL  locate Flutter: not on PATH, in FLUTTER_ROOT or C:\src\flutter\bin' -ForegroundColor Red
    exit 1
}

# November is outside US daylight saving, so PST8PDT is -8 h on 9 Nov 2026.
$runs = @(
    @{ Tz = 'UTC'; Name = 'UTC'; Offset = 0 },
    @{ Tz = 'PST8PDT'; Name = 'PST8PDT'; Offset = -480 },
    @{ Tz = $null; Name = 'IST'; Offset = $DefaultOffsetMinutes }
)

$savedTz = $env:TZ
$dumpDir = Join-Path $appDir 'build\tz'
Push-Location -LiteralPath $appDir
try {
    if (Test-Path -LiteralPath $dumpDir) {
        Remove-Item -LiteralPath $dumpDir -Recurse -Force
    }
    $failed = @()
    foreach ($run in $runs) {
        if ($null -eq $run.Tz) {
            Remove-Item Env:TZ -ErrorAction SilentlyContinue
        } else {
            $env:TZ = $run.Tz
        }
        Write-Host ('--- TZ=' + $run.Name + ': flutter test ' + ($Tests -join ' '))
        & $flutter test @Tests ('--dart-define=EXPECT_TZ_OFFSET_MIN=' + $run.Offset) ('--dart-define=TZ_NAME=' + $run.Name)
        if ($LASTEXITCODE -eq 0) {
            Write-Host ('PASS  TZ=' + $run.Name) -ForegroundColor Green
        } else {
            Write-Host ('FAIL  TZ=' + $run.Name) -ForegroundColor Red
            $failed += $run.Name
        }
    }

    $dumps = @()
    if (Test-Path -LiteralPath $dumpDir) {
        $dumps = @(Get-ChildItem -LiteralPath $dumpDir -Filter '*.txt' -File)
    }
    if ($dumps.Count -eq $runs.Count) {
        $hashes = @($dumps | Get-FileHash -Algorithm SHA256)
        $hashes | ForEach-Object { Write-Host ('      ' + $_.Hash + '  ' + (Split-Path -Leaf $_.Path)) }
        $distinct = @($hashes | Select-Object -ExpandProperty Hash -Unique)
        if ($distinct.Count -eq 1) {
            Write-Host 'PASS  the three engine dumps are identical' -ForegroundColor Green
        } else {
            Write-Host 'FAIL  the engine dumps differ between time zones' -ForegroundColor Red
            $failed += 'dump comparison'
        }
    } else {
        Write-Host ('NOTE  ' + $dumps.Count + ' dump file(s) in build\tz; no dump comparison for these tests')
    }

    Write-Host ''
    if ($failed.Count -gt 0) {
        Write-Host ('TZ MATRIX FAILED: ' + ($failed -join ', ')) -ForegroundColor Red
        exit 1
    }
    Write-Host 'TZ MATRIX PASSED (UTC, PST8PDT, IST)' -ForegroundColor Green
    exit 0
} finally {
    if ($null -eq $savedTz) {
        Remove-Item Env:TZ -ErrorAction SilentlyContinue
    } else {
        $env:TZ = $savedTz
    }
    Pop-Location
}
