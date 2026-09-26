@echo off
setlocal

set SCRIPT_DIR=%~dp0
set SCRIPT_PATH=%SCRIPT_DIR%sort_horizon_dme.py
set ARGS=--all

where py >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    py "%SCRIPT_PATH%" %ARGS%
    exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    python "%SCRIPT_PATH%" %ARGS%
    exit /b %ERRORLEVEL%
)

echo Python not found. Install Python 3 or add it to PATH.
exit /b 1
