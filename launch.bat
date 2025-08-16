@echo off
setlocal EnableDelayedExpansion

echo ========================================
echo      UniRig Launcher Script v1.0
echo ========================================
echo.

:: Set virtual environment name
set VENV_NAME=venv_unirig

:: Check if virtual environment exists
if not exist "%VENV_NAME%" (
    echo Virtual environment not found. Creating new virtual environment...
    echo.
    python -m venv %VENV_NAME%
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment.
        echo Please ensure Python is installed and accessible from PATH.
        pause
        exit /b 1
    )
    echo Virtual environment created successfully.
    echo.
) else (
    echo Virtual environment found: %VENV_NAME%
    echo.
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

:: Check if requirements.txt exists
if not exist "requirements.txt" (
    echo WARNING: requirements.txt not found in current directory.
    echo Please ensure you're running this script from the UniRig root directory.
    pause
    exit /b 1
)

:: Install requirements
echo Installing requirements from requirements.txt...
echo.
python -m pip install --upgrade pip

:: Create temporary requirements file without problematic packages
echo Creating filtered requirements file...
type nul > requirements_filtered.txt
for /f "usebackq delims=" %%a in ("requirements.txt") do (
    echo %%a | findstr /i "bpy" >nul
    if errorlevel 1 (
        echo %%a >> requirements_filtered.txt
    ) else (
        echo Skipping bpy package - will be handled separately
    )
)

:: Install filtered requirements
python -m pip install -r requirements_filtered.txt
if errorlevel 1 (
    echo ERROR: Failed to install basic requirements.
    echo You may need to run install_special_requirements.bat first.
    del requirements_filtered.txt 2>nul
    pause
    exit /b 1
)

:: Clean up temporary file
del requirements_filtered.txt 2>nul

:: Try to install bpy separately with fallback
echo.
echo Installing Blender Python (bpy) package...
python -m pip install bpy==4.2 2>nul
if errorlevel 1 (
    echo WARNING: Could not install bpy==4.2 from pip.
    echo This is normal on Windows. Blender functionality may be limited.
    echo For full Blender support, install Blender separately and use its Python.
)
echo.
echo Requirements installed successfully.
echo.

:: Check for input arguments or provide interactive menu
if "%~1"=="" (
    echo ========================================
    echo         UniRig Interface Menu
    echo ========================================
    echo.
    echo Please choose an option:
    echo.
    echo 1. Generate skeleton for a single file
    echo 2. Generate skeleton for directory
    echo 3. Generate skinning weights for a single file
    echo 4. Generate skinning weights for directory
    echo 5. Extract mesh data
    echo 6. Exit
    echo.
    set /p choice="Enter your choice (1-6): "
    
    if "!choice!"=="1" (
        set /p input_file="Enter input file path: "
        set /p output_file="Enter output file path: "
        bash launch/inference/generate_skeleton.sh --input "!input_file!" --output "!output_file!"
    ) else if "!choice!"=="2" (
        set /p input_dir="Enter input directory: "
        set /p output_dir="Enter output directory: "
        bash launch/inference/generate_skeleton.sh --input_dir "!input_dir!" --output_dir "!output_dir!"
    ) else if "!choice!"=="3" (
        set /p input_file="Enter input file path (with skeleton): "
        set /p output_file="Enter output file path: "
        bash launch/inference/generate_skin.sh --input "!input_file!" --output "!output_file!"
    ) else if "!choice!"=="4" (
        set /p input_dir="Enter input directory: "
        set /p output_dir="Enter output directory: "
        bash launch/inference/generate_skin.sh --input_dir "!input_dir!" --output_dir "!output_dir!"
    ) else if "!choice!"=="5" (
        set /p input_file="Enter input file path: "
        bash launch/inference/extract.sh --input "!input_file!"
    ) else if "!choice!"=="6" (
        echo Exiting...
        goto :end
    ) else (
        echo Invalid choice. Please run the script again.
        pause
        exit /b 1
    )
) else (
    :: If arguments provided, run skeleton generation with provided arguments
    echo Running skeleton generation with provided arguments...
    bash launch/inference/generate_skeleton.sh %*
)

:end
echo.
echo ========================================
echo           Process Complete
echo ========================================
echo.
echo Press any key to exit...
pause > nul