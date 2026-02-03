@echo off
REM Virtual environment setup script for Windows
REM Run this once before using the asset sync system

set SCRIPT_DIR=%~dp0
set VENV_DIR=%SCRIPT_DIR%venv

echo Setting up virtual environment...

if not exist "%VENV_DIR%" (
    python -m venv "%VENV_DIR%"
    echo Virtual environment created.
) else (
    echo Virtual environment already exists.
)

echo Activating virtual environment...
call "%VENV_DIR%\Scripts\activate.bat"

echo Installing dependencies...
pip install --upgrade pip
pip install -r "%SCRIPT_DIR%requirements.txt"

echo.
echo Setup complete.
echo.
echo To activate the virtual environment manually:
echo   %VENV_DIR%\Scripts\activate.bat
echo.
echo To run setup (TU only):
echo   %VENV_DIR%\Scripts\activate.bat ^&^& python setup.py
echo.
echo To run file watcher (NTU Desktop):
echo   %VENV_DIR%\Scripts\activate.bat ^&^& python run_watcher.py
echo.
echo To run upload server (NTU iPadOS):
echo   %VENV_DIR%\Scripts\activate.bat ^&^& python run_server.py

pause
