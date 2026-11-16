# Budget engine coverage gate (plan F-006, task T-205; F-006 AC-24, D-048).
#
# Runs, from app/: flutter test --branch-coverage <tests> (default
# test/domain/budget), then reads coverage/lcov.info and checks every file in
# lib/domain/budget/: lines hit = lines found (LH = LF) and branches hit =
# branches found (BRH = BRF). Flutter 3.47 writes the BRDA lines but no BRF/BRH
# totals, so both are counted here from the DA and BRDA lines. A file that no
# test loads is a failure too, unless it holds only comments and directives. Prints one line per file and every missed line
# or branch; exits 1 on any gap, 0 when everything is covered.
#
# PowerShell:  .\tool\domain_coverage.ps1
# Git Bash:    powershell -ExecutionPolicy Bypass -File tool/domain_coverage.ps1
#
# Compatible with Windows PowerShell 5.1 (no &&, ||, ?? or ternaries).

param(
    [string[]]$Tests = @('test/domain/budget')
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

Push-Location -LiteralPath $appDir
try {
    Write-Host ('--- flutter test --branch-coverage ' + ($Tests -join ' '))
    & $flutter test --branch-coverage @Tests
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'FAIL  tests failed, coverage not checked' -ForegroundColor Red
        exit 1
    }

    $lcov = Join-Path $appDir 'coverage\lcov.info'
    if (-not (Test-Path -LiteralPath $lcov)) {
        Write-Host ('FAIL  no coverage file: ' + $lcov) -ForegroundColor Red
        exit 1
    }

    # Per file: lines found/hit, branches found/hit, missed entries.
    $files = @{}
    $current = $null
    foreach ($line in Get-Content -LiteralPath $lcov) {
        if ($line -like 'SF:*') {
            $path = $line.Substring(3).Replace('\', '/')
            if ($path -match '(^|/)lib/domain/budget/[^/]+\.dart$') {
                $current = @{ LF = 0; LH = 0; BRF = 0; BRH = 0; Missed = @() }
                $files[$Matches[0].TrimStart('/')] = $current
            } else {
                $current = $null
            }
        } elseif ($null -eq $current) {
            continue
        } elseif ($line -match '^DA:(\d+),(\d+)') {
            $current.LF++
            if ([int64]$Matches[2] -gt 0) {
                $current.LH++
            } else {
                $current.Missed += ('line ' + $Matches[1])
            }
        } elseif ($line -match '^BRDA:(\d+),(\d+),(\d+),(-|\d+)$') {
            $current.BRF++
            if ($Matches[4] -ne '-' -and [int64]$Matches[4] -gt 0) {
                $current.BRH++
            } else {
                $current.Missed += ('branch at line ' + $Matches[1])
            }
        }
    }

    $failed = $false
    $sources = Get-ChildItem -LiteralPath (Join-Path $appDir 'lib\domain\budget') -Filter '*.dart' -File
    foreach ($source in $sources) {
        $key = 'lib/domain/budget/' + $source.Name
        if (-not $files.ContainsKey($key)) {
            # A file of only comments and directives (the library file that
            # lists the parts) has no code, so it never appears in lcov.info.
            $code = @(Get-Content -LiteralPath $source.FullName | Where-Object {
                $_.Trim() -ne '' -and $_ -notmatch '^\s*(//|library\b|part\b|import\b|export\b)'
            })
            if ($code.Count -eq 0) {
                Write-Host ('PASS  ' + $key + '  (directives only, no code)') -ForegroundColor Green
            } else {
                Write-Host ('FAIL  ' + $key + ': not loaded by any test') -ForegroundColor Red
                $failed = $true
            }
            continue
        }
        $f = $files[$key]
        $text = '{0}  L {1}/{2}  B {3}/{4}' -f $key, $f.LH, $f.LF, $f.BRH, $f.BRF
        if ($f.LH -eq $f.LF -and $f.BRH -eq $f.BRF) {
            Write-Host ('PASS  ' + $text) -ForegroundColor Green
        } else {
            Write-Host ('FAIL  ' + $text) -ForegroundColor Red
            $f.Missed | ForEach-Object { Write-Host ('        missed ' + $_) }
            $failed = $true
        }
    }

    Write-Host ''
    if ($failed) {
        Write-Host 'DOMAIN COVERAGE FAILED: every line and branch of lib/domain/budget/ must be hit' -ForegroundColor Red
        exit 1
    }
    Write-Host 'DOMAIN COVERAGE 100% (lines and branches)' -ForegroundColor Green
    exit 0
} finally {
    Pop-Location
}
