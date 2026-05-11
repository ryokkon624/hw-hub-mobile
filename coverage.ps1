# coverage.ps1 - Test coverage report generator
#
# Usage: .\coverage.ps1
# Requires: choco install lcov strawberryperl

$perl        = "C:/Strawberry/perl/bin/perl.exe"
$genhtmlPath = "C:/ProgramData/chocolatey/lib/lcov/tools/bin/genhtml"

Write-Host "=== flutter test --coverage ===" -ForegroundColor Cyan
flutter test --coverage
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tests failed. Aborting." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Filtering lcov.info ===" -ForegroundColor Cyan

# Read exclusion patterns (skip comments and blank lines, strip CR)
$excludePatterns = Get-Content lcov_exclude.txt -Encoding UTF8 |
    Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' } |
    ForEach-Object { $_ -replace '\r', '' }

# Filter lcov.info in PowerShell to avoid lcov --remove path issues on Windows.
# Paths in lcov.info use backslashes; patterns use forward slashes.
# We normalize SF: paths to forward slashes and match with PowerShell -like.
$lines   = Get-Content coverage/lcov.info
$output  = [System.Collections.Generic.List[string]]::new()
$block   = [System.Collections.Generic.List[string]]::new()
$inBlock = $false
$skip    = $false
$excluded = 0
$kept     = 0

foreach ($rawLine in $lines) {
    $line = $rawLine -replace '\r', ''
    if ($line -match '^[SK]F:(.+)') {
        $sfPath = ($Matches[1] -replace '\\', '/').TrimEnd()
        $skip = $false
        foreach ($pat in $excludePatterns) {
            if ($sfPath -like $pat) { $skip = $true; break }
        }
        $inBlock = $true
        $block.Clear()
        $block.Add($line) | Out-Null
    } elseif ($line -eq 'end_of_record') {
        if ($inBlock) {
            $block.Add($line) | Out-Null
            if ($skip) { $excluded++ } else { $output.AddRange($block); $kept++ }
            $block.Clear()
            $inBlock = $false
            $skip    = $false
        }
    } elseif ($inBlock) {
        $block.Add($line) | Out-Null
    } else {
        $output.Add($line) | Out-Null
    }
}

$filteredPath = [System.IO.Path]::Combine((Get-Location).Path, 'coverage', 'lcov_filtered.info')
$filteredContent = ($output.ToArray() -join "`n") + "`n"
[System.IO.File]::WriteAllText($filteredPath, $filteredContent, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Kept $kept, excluded $excluded file(s)"

Write-Host "`n=== Generating HTML ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path coverage/html | Out-Null
& $perl $genhtmlPath `
    coverage/lcov_filtered.info `
    --output-directory coverage/html `
    --title 'HwHub Mobile Coverage'

if ($LASTEXITCODE -ne 0) {
    Write-Host "genhtml failed." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Opening coverage/html/index.html ..."
Start-Process coverage/html/index.html
