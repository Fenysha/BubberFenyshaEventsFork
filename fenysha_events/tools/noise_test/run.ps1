# ============================================================================
# SS13 Noise Tester Launcher (v4 - TargetDir fix)
# ============================================================================

$Host.UI.RawUI.WindowTitle = "SS13 Noise Tester Launcher"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Pause-Exit {
    param([string]$Message = "Press Enter to exit...")
    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host }
    exit
}

trap {
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Red
    Write-Host "  CRITICAL ERROR" -ForegroundColor Red
    Write-Host "==============================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host $_ -ForegroundColor DarkRed
    Pause-Exit
}

try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
} catch {}

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = (Get-Location).Path }
Set-Location $ScriptDir

$TargetScript = Join-Path $ScriptDir "noise_tester.py"
$PythonDir    = Join-Path $ScriptDir "python_x86"
$PythonExe    = Join-Path $PythonDir "python.exe"

$InstallerName = "python-3.11.9.exe"
$Installer     = Join-Path $ScriptDir $InstallerName
$InstallerUrl  = "https://www.python.org/ftp/python/3.11.9/python-3.11.9.exe"

Clear-Host
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "       SS13 Noise Tester - Python x86" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Working directory: $ScriptDir" -ForegroundColor DarkGray
Write-Host ""

# 1. Проверка скрипта
if (-not (Test-Path $TargetScript)) {
    Write-Host "ERROR: noise_tester.py not found!" -ForegroundColor Red
    Pause-Exit
}
Write-Host "[+] Found noise_tester.py" -ForegroundColor Green

# 2. Если python уже есть — отлично
if (Test-Path $PythonExe) {
    Write-Host "[+] Local Python already exists" -ForegroundColor Green
}
else {
    Write-Host "[!] Local Python not found" -ForegroundColor Yellow
    Write-Host ""

    # === Скачивание ===
    if (-not (Test-Path $Installer)) {
        Write-Host "[*] Downloading Python 3.11.9 (32-bit)..." -ForegroundColor Cyan
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $InstallerUrl -OutFile $Installer -UseBasicParsing
        }
        catch {
            Write-Host "ERROR: Download failed" -ForegroundColor Red
            Write-Host $_.Exception.Message
            Pause-Exit
        }

        Start-Sleep -Milliseconds 1000
        if (-not (Test-Path $Installer)) {
            Write-Host "ERROR: File was deleted by antivirus right after download!" -ForegroundColor Red
            Write-Host "Add this folder to Windows Defender exclusions and try again." -ForegroundColor Yellow
            Pause-Exit
        }
        Write-Host "[+] Download complete" -ForegroundColor Green
    }
    else {
        Write-Host "[+] Installer already exists" -ForegroundColor Green
    }

    # Создаём папку
    if (-not (Test-Path $PythonDir)) {
        New-Item -ItemType Directory -Path $PythonDir -Force | Out-Null
    }

    Write-Host ""
    Write-Host "[*] Installing Python into:" -ForegroundColor Cyan
    Write-Host "    $PythonDir" -ForegroundColor White
    Write-Host ""

    # Более надёжные аргументы
    $Arguments = @(
        "/quiet"
        "InstallAllUsers=0"
        "PrependPath=0"
        "Include_launcher=0"
        "Include_pip=1"
        "Include_tcltk=1"
        "Include_test=0"
        "AssociateFiles=0"
        "Shortcuts=0"
        "SimpleInstall=1"
        "TargetDir=$PythonDir"
    )

    Write-Host "Running installer..." -ForegroundColor DarkGray
    $proc = Start-Process -FilePath $Installer -ArgumentList $Arguments -Wait -PassThru -NoNewWindow

    Write-Host "Installer exit code: $($proc.ExitCode)" -ForegroundColor $(if ($proc.ExitCode -eq 0) {"Green"} else {"Red"})

    Start-Sleep -Seconds 3

    # === Ищем python.exe в нескольких местах ===
    $possiblePaths = @(
        $PythonExe
        (Join-Path $PythonDir "python.exe")
        (Join-Path $env:LOCALAPPDATA "Programs\Python\Python311-32\python.exe")
        (Join-Path $env:LOCALAPPDATA "Programs\Python\Python311\python.exe")
        (Join-Path $env:APPDATA "Local\Programs\Python\Python311-32\python.exe")
        "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python311-32\python.exe"
    )

    $foundPython = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $foundPython = $path
            break
        }
    }

    if ($foundPython) {
        Write-Host "[+] Found python.exe at:" -ForegroundColor Green
        Write-Host "    $foundPython" -ForegroundColor White

        # Если он не в нашей папке — копируем
        if ($foundPython -ne $PythonExe) {
            Write-Host "[*] Copying Python files to local folder..." -ForegroundColor Cyan

            $sourceDir = Split-Path $foundPython -Parent
            # Копируем всю папку
            robocopy $sourceDir $PythonDir /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null

            if (Test-Path $PythonExe) {
                Write-Host "[+] Successfully copied to $PythonDir" -ForegroundColor Green
            }
            else {
                Write-Host "WARNING: Copy failed, will use original location" -ForegroundColor Yellow
                $PythonExe = $foundPython
            }
        }
    }
    else {
        Write-Host ""
        Write-Host "ERROR: python.exe not found anywhere after installation!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Checked locations:" -ForegroundColor Yellow
        $possiblePaths | ForEach-Object { Write-Host "  $_" }
        Write-Host ""
        Write-Host "Try running the installer manually (double-click python-3.11.9.exe)" -ForegroundColor Cyan
        Write-Host "and choose 'Install for current user' + custom path:" -ForegroundColor Cyan
        Write-Host $PythonDir -ForegroundColor White
        Pause-Exit
    }

    # Удаляем инсталлятор только если всё хорошо
    if (Test-Path $PythonExe) {
        Remove-Item $Installer -Force -ErrorAction SilentlyContinue
    }
}

# 3. Финальная проверка
Write-Host ""
Write-Host "[*] Final checks..." -ForegroundColor Cyan

if (-not (Test-Path $PythonExe)) {
    Write-Host "ERROR: Still no python.exe!" -ForegroundColor Red
    Pause-Exit
}

$arch = & $PythonExe -c "import struct; print(struct.calcsize('P') * 8)"
Write-Host "[+] Python $arch-bit found" -ForegroundColor Green

if ($arch -ne "32") {
    Write-Host "ERROR: Need 32-bit Python!" -ForegroundColor Red
    Pause-Exit
}

# Модули
$needInstall = $false
try {
    & $PythonExe -c "import tkinter, numpy, matplotlib" 2>$null
    if ($LASTEXITCODE -ne 0) { $needInstall = $true }
} catch { $needInstall = $true }

if ($needInstall) {
    Write-Host "[*] Installing required modules..." -ForegroundColor Yellow
    & $PythonExe -m pip install --upgrade pip --quiet
    & $PythonExe -m pip install "numpy<2.0" "matplotlib<3.9"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to install modules" -ForegroundColor Red
        Pause-Exit
    }
}

Write-Host "[+] Everything ready!" -ForegroundColor Green
Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  Starting noise_tester.py" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""

& $PythonExe $TargetScript

Pause-Exit "Press any key to close..."
