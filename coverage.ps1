# coverage.ps1 - Test coverage report generator
#
# Usage: .\coverage.ps1
# Requires: choco install lcov strawberryperl

$perl        = "C:/Strawberry/perl/bin/perl.exe"
$lcovPath    = "C:/ProgramData/chocolatey/lib/lcov/tools/bin/lcov"
$genhtmlPath = "C:/ProgramData/chocolatey/lib/lcov/tools/bin/genhtml"

Write-Host "=== flutter test --coverage ===" -ForegroundColor Cyan
flutter test --coverage
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tests failed. Aborting." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Filtering lcov.info ===" -ForegroundColor Cyan
$excludePatterns = Get-Content lcov_exclude.txt |
    Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' }
& $perl $lcovPath --remove coverage/lcov.info @excludePatterns --output-file coverage/lcov_filtered.info

if ($LASTEXITCODE -ne 0) {
    Write-Host "lcov --remove failed." -ForegroundColor Red
    exit 1
}

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
