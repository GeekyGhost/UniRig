@echo off
setlocal EnableDelayedExpansion

echo ========================================
echo  UniRig Special Requirements Installer
echo ========================================
echo.
echo This script will install:
echo - PyTorch and TorchVision
echo - spconv (CUDA-specific)
echo - torch_scatter and torch_cluster
echo - numpy 1.26.4 (compatibility fix)
echo - Blender VRM addon
echo - Download model checkpoints
echo.

:: Set virtual environment name
set VENV_NAME=venv_unirig

:: Check if virtual environment exists
if not exist "%VENV_NAME%" (
    echo ERROR: Virtual environment not found.
    echo Please run launch.bat first to create the virtual environment.
    pause
    exit /b 1
)

:: Activate virtual environment
echo Activating virtual environment...
call "%VENV_NAME%\Scripts\activate.bat"
if errorlevel 1 (
    echo ERROR: Failed to activate virtual environment.
    pause
    exit /b 1
)
echo Virtual environment activated.
echo.

:: Detect CUDA version
echo Detecting CUDA version...
set CUDA_VERSION=
for /f "tokens=*" %%i in ('nvcc --version 2^>nul ^| findstr "release"') do (
    for /f "tokens=4 delims=, " %%j in ("%%i") do (
        set CUDA_VERSION=%%j
    )
)

if "%CUDA_VERSION%"=="" (
    echo WARNING: CUDA not detected or nvcc not found.
    echo Defaulting to CPU-only PyTorch installation.
    set CUDA_VERSION=cpu
    set TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu
    set SPCONV_PACKAGE=spconv-cu117
) else (
    echo CUDA version detected: %CUDA_VERSION%
    :: Convert CUDA version to appropriate format
    if "%CUDA_VERSION%"=="12.1" (
        set CUDA_SHORT=cu121
        set SPCONV_PACKAGE=spconv-cu121
    ) else if "%CUDA_VERSION%"=="12.0" (
        set CUDA_SHORT=cu118
        set SPCONV_PACKAGE=spconv-cu118
    ) else if "%CUDA_VERSION%"=="11.8" (
        set CUDA_SHORT=cu118
        set SPCONV_PACKAGE=spconv-cu118
    ) else if "%CUDA_VERSION%"=="11.7" (
        set CUDA_SHORT=cu117
        set SPCONV_PACKAGE=spconv-cu117
    ) else (
        echo Unsupported CUDA version. Defaulting to CUDA 11.7 packages.
        set CUDA_SHORT=cu117
        set SPCONV_PACKAGE=spconv-cu117
    )
    set TORCH_INDEX_URL=https://download.pytorch.org/whl/!CUDA_SHORT!
)
echo.

:: Get PyTorch version
echo Detecting PyTorch version...
set TORCH_VERSION=
for /f "tokens=*" %%i in ('python -c "import torch; print(torch.__version__)" 2^>nul') do (
    set TORCH_VERSION=%%i
)

if "%TORCH_VERSION%"=="" (
    echo PyTorch not found. Installing PyTorch and TorchVision...
    echo.
    if "%CUDA_VERSION%"=="cpu" (
        python -m pip install torch torchvision --index-url %TORCH_INDEX_URL%
    ) else (
        python -m pip install torch torchvision --index-url %TORCH_INDEX_URL%
    )
    if errorlevel 1 (
        echo ERROR: Failed to install PyTorch.
        pause
        exit /b 1
    )
    
    :: Get the installed PyTorch version
    for /f "tokens=*" %%i in ('python -c "import torch; print(torch.__version__)"') do (
        set TORCH_VERSION=%%i
    )
) else (
    echo PyTorch version found: %TORCH_VERSION%
)
echo.

:: Extract major.minor version from PyTorch version (e.g., 2.3.1 -> 2.3)
for /f "tokens=1,2 delims=." %%a in ("%TORCH_VERSION%") do (
    set TORCH_MAJOR_MINOR=%%a.%%b
)

:: Install spconv
echo Installing spconv (%SPCONV_PACKAGE%)...
python -m pip install %SPCONV_PACKAGE%
if errorlevel 1 (
    echo WARNING: Failed to install spconv. This might affect some functionality.
    echo You may need to install it manually from: https://github.com/traveller59/spconv
)
echo.

:: Install torch_scatter and torch_cluster
echo Installing torch_scatter and torch_cluster...
if "%CUDA_VERSION%"=="cpu" (
    set TORCH_GEOM_URL=https://data.pyg.org/whl/torch-%TORCH_MAJOR_MINOR%+cpu.html
) else (
    set TORCH_GEOM_URL=https://data.pyg.org/whl/torch-%TORCH_MAJOR_MINOR%+!CUDA_SHORT!.html
)

python -m pip install torch_scatter torch_cluster -f %TORCH_GEOM_URL% --no-cache-dir
if errorlevel 1 (
    echo WARNING: Failed to install torch_scatter and torch_cluster.
    echo You may need to install them manually from: https://pytorch-geometric.com/
)
echo.

:: Install specific numpy version for compatibility
echo Installing numpy 1.26.4 for compatibility...
python -m pip install numpy==1.26.4
if errorlevel 1 (
    echo WARNING: Failed to install numpy 1.26.4. This might cause compatibility issues.
)
echo.

:: Install Blender addon (optional)
echo Installing Blender VRM addon...
if exist "blender\add-on-vrm-v2.20.77_modified.zip" (
    python -c "import bpy, os; bpy.ops.preferences.addon_install(filepath=os.path.abspath('blender/add-on-vrm-v2.20.77_modified.zip'))" 2>nul
    if errorlevel 1 (
        echo WARNING: Failed to install Blender addon. This is optional for VRM support.
        echo You can install it manually later if needed.
    ) else (
        echo Blender VRM addon installed successfully.
    )
) else (
    echo WARNING: Blender addon file not found. Skipping VRM addon installation.
)
echo.

:: Create models directory if it doesn't exist
echo Setting up model directories...
if not exist "models" mkdir models
if not exist "checkpoints" mkdir checkpoints
echo Model directories created.
echo.

:: Download model checkpoints (they will be auto-downloaded on first use)
echo Model checkpoints will be automatically downloaded when you first run the application.
echo The models are hosted on Hugging Face and will be cached locally.
echo.

:: Verify installation
echo ========================================
echo        Verifying Installation
echo ========================================
echo.

echo Testing PyTorch installation...
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')"
if errorlevel 1 (
    echo ERROR: PyTorch verification failed.
) else (
    echo PyTorch verification successful.
)
echo.

echo Testing transformers...
python -c "import transformers; print(f'Transformers version: {transformers.__version__}')" 2>nul
if errorlevel 1 (
    echo WARNING: Transformers not available. Make sure to run launch.bat to install basic requirements.
) else (
    echo Transformers verification successful.
)
echo.

echo Testing spconv...
python -c "import spconv; print('spconv available')" 2>nul
if errorlevel 1 (
    echo WARNING: spconv not available. Some features may not work.
) else (
    echo spconv verification successful.
)
echo.

echo Testing torch_scatter...
python -c "import torch_scatter; print('torch_scatter available')" 2>nul
if errorlevel 1 (
    echo WARNING: torch_scatter not available. Some features may not work.
) else (
    echo torch_scatter verification successful.
)
echo.

echo ========================================
echo     Special Installation Complete
echo ========================================
echo.
echo Additional setup notes:
echo.
echo 1. If you encounter CUDA-related errors, ensure your GPU drivers are up to date
echo 2. For VRM file support, the Blender addon may need manual installation
echo 3. Model checkpoints will download automatically (requires internet connection)
echo 4. Run launch.bat to start using UniRig
echo.
echo Press any key to exit...
pause > nul