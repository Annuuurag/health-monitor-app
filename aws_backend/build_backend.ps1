# PowerShell script to build Python Lambda functions with Linux dependencies

$ErrorActionPreference = "Stop"

# Get current script path and set directories
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir

$buildDir = Join-Path $scriptDir "build"
$ingestBuildDir = Join-Path $buildDir "IngestIoTData"
$predictBuildDir = Join-Path $buildDir "PredictDisease"

# Locate the Python virtual environment's pip
$pipPath = Join-Path $projectDir ".venv\Scripts\pip.exe"
if (-not (Test-Path $pipPath)) {
    Write-Host "[ERROR] Virtual environment pip not found at $pipPath. Please run setup first." -ForegroundColor Red
    exit 1
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "BUILDING AWS BACKEND ML LAMBDA PACKAGES" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Clean and recreate build directories
Write-Host "[1/5] Recreating build directories..." -ForegroundColor Yellow
if (Test-Path $buildDir) {
    Remove-Item $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $ingestBuildDir -Force | Out-Null
New-Item -ItemType Directory -Path $predictBuildDir -Force | Out-Null

# 2. Install dependencies for IngestIoTData (numpy, scikit-learn)
Write-Host "[2/5] Downloading Linux wheels for IngestIoTData (scikit-learn, numpy)..." -ForegroundColor Yellow
& $pipPath install `
    "scikit-learn==1.4.2" `
    "numpy==1.26.4" `
    --platform "manylinux2014_x86_64" `
    --only-binary=:all: `
    --target $ingestBuildDir `
    --upgrade

# 3. Install dependencies for PredictDisease (numpy, scikit-learn)
Write-Host "[3/5] Downloading Linux wheels for PredictDisease (scikit-learn, numpy)..." -ForegroundColor Yellow
& $pipPath install `
    "scikit-learn==1.4.2" `
    "numpy==1.26.4" `
    --platform "manylinux2014_x86_64" `
    --only-binary=:all: `
    --target $predictBuildDir `
    --upgrade

# 4. Copy python source files
Write-Host "[4/5] Copying Lambda source handlers..." -ForegroundColor Yellow
Copy-Item (Join-Path $scriptDir "IngestIoTData\IngestIoTData.py") $ingestBuildDir
Copy-Item (Join-Path $scriptDir "PredictDisease\PredictDisease.py") $predictBuildDir

# 5. Copy ML model artifacts
Write-Host "[5/5] Copying ML model artifacts..." -ForegroundColor Yellow
Copy-Item (Join-Path $projectDir "ML_models\Anomaly_Detection\anomaly_model.pkl") $ingestBuildDir
Copy-Item (Join-Path $projectDir "ML_models\Anomaly_Detection\anomaly_scaler.pkl") $ingestBuildDir
Copy-Item (Join-Path $projectDir "ML_models\Disease_Prediction\prediction_model.pkl") $predictBuildDir
Copy-Item (Join-Path $projectDir "ML_models\Disease_Prediction\heart_scaler.pkl") $predictBuildDir

# 6. Remove numpy and pandas to stay under the 262MB unzipped size limit
Write-Host "[6/6] Removing numpy and pandas (will be loaded from AWS Lambda Layer)..." -ForegroundColor Yellow
Remove-Item (Join-Path $ingestBuildDir "numpy") -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ingestBuildDir "numpy-*.dist-info") -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $predictBuildDir "numpy") -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $predictBuildDir "numpy-*.dist-info") -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $predictBuildDir "pandas") -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $predictBuildDir "pandas-*.dist-info") -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "[SUCCESS] Lambda packages built and ready in 'aws_backend/build/'" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
