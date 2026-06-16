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
    "scikit-learn>=1.4.2" `
    "numpy>=2.0.0" `
    --platform "manylinux2014_x86_64" `
    --only-binary=:all: `
    --target $ingestBuildDir `
    --upgrade

# 3. Install dependencies for PredictDisease (numpy, scikit-learn)
Write-Host "[3/5] Downloading Linux wheels for PredictDisease (scikit-learn, numpy)..." -ForegroundColor Yellow
& $pipPath install `
    "scikit-learn>=1.4.2" `
    "numpy>=2.0.0" `
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

# 6. Keep numpy (needed since we removed the layer) but prune bloat
# (tests, __pycache__, type stubs, documentation) to fit under the 250MB limit.
Write-Host "[6/6] Pruning unnecessary files (tests, cache, docs, stubs) to minimize bundle size..." -ForegroundColor Yellow

function Clean-PackageBloat($dir) {
    Write-Host "  Cleaning $dir..."
    
    # 1. Delete all folders named '__pycache__'
    Get-ChildItem -Path $dir -Recurse -Directory | Where-Object { 
        $_.Name -eq "__pycache__" 
    } | ForEach-Object {
        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }

    # 3. Delete all files with extension .pyi (type stubs)
    Get-ChildItem -Path $dir -Recurse -File -Filter "*.pyi" | ForEach-Object {
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }

    # 4. Delete documentation files (.txt, .md, .rst, .html)
    Get-ChildItem -Path $dir -Recurse -File | Where-Object {
        $_.Extension -eq ".txt" -or $_.Extension -eq ".md" -or $_.Extension -eq ".rst" -or $_.Extension -eq ".html"
    } | ForEach-Object {
        # Do not delete the script files or requirements.txt
        if ($_.Name -ne "requirements.txt" -and $_.Name -ne "PredictDisease.py" -and $_.Name -ne "IngestIoTData.py") {
            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }

    # 5. Delete .dist-info directories
    Get-ChildItem -Path $dir -Recurse -Directory | Where-Object {
        $_.Name -like "*.dist-info"
    } | ForEach-Object {
        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }

    # 6. Delete pandas if present (neither function uses pandas)
    $pandasDir = Join-Path $dir "pandas"
    if (Test-Path $pandasDir) {
        Remove-Item -Path $pandasDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    $pandasInfo = Join-Path $dir "pandas-*"
    if (Test-Path $pandasInfo) {
        Remove-Item -Path $pandasInfo -Recurse -Force -ErrorAction SilentlyContinue
    }
    $pandasLibs = Join-Path $dir "pandas.libs"
    if (Test-Path $pandasLibs) {
        Remove-Item -Path $pandasLibs -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Clean-PackageBloat $ingestBuildDir
Clean-PackageBloat $predictBuildDir

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "[SUCCESS] Lambda packages built and ready in 'aws_backend/build/'" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
