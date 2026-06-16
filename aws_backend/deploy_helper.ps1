# PowerShell script to build and deploy AWS SAM backend while preserving Linux C binaries (.so)
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Run local Linux binary packaging
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "1. Running build_backend.ps1 to package dependencies..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
& (Join-Path $scriptDir "build_backend.ps1")

# 2. Run SAM Build
Write-Host "`n--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "2. Running SAM build..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
& sam build --template (Join-Path $scriptDir "template.yaml")

# 3. Copy Scikit-Learn .so files to .aws-sam build folders
Write-Host "`n--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "3. Injecting Linux binaries (.so) into .aws-sam build..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

$buildDir = Join-Path $scriptDir "build"
$samBuildDir = Join-Path $scriptDir ".aws-sam\build"

$predictSource = Join-Path $buildDir "PredictDisease"
$predictDest = Join-Path $samBuildDir "PredictDiseaseFunction"
$ingestSource = Join-Path $buildDir "IngestIoTData"
$ingestDest = Join-Path $samBuildDir "IngestIoTDataFunction"

# Helper function to recursively copy .so binaries
function Copy-Binaries($src, $dest) {
    if (-not (Test-Path $src)) {
        Write-Host "Source directory $src not found. Skipping." -ForegroundColor Yellow
        return
    }
    if (-not (Test-Path $dest)) {
        Write-Host "Destination directory $dest not found. Skipping." -ForegroundColor Yellow
        return
    }
    
    $soFiles = Get-ChildItem -Path $src -Recurse -Filter "*.so"
    Write-Host "Found $($soFiles.Count) Linux binary files (.so) in $src"
    
    foreach ($file in $soFiles) {
        $relPath = $file.FullName.Substring($src.Length + 1)
        $destFile = Join-Path $dest $relPath
        $destDir = Split-Path $destFile
        
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        Copy-Item -Path $file.FullName -Destination $destFile -Force
    }
    Write-Host "[OK] Successfully injected .so binaries into $dest" -ForegroundColor Green
}

Copy-Binaries $predictSource $predictDest
Copy-Binaries $ingestSource $ingestDest

# 4. Deploy using SAM CLI
Write-Host "`n--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "4. Executing SAM deployment to AWS Cloud..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
& sam deploy --config-file (Join-Path $scriptDir "samconfig.toml")
