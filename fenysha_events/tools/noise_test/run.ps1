# ============================================================================
# SS13 Noise Tester
# Python 3.11 x86 launcher
# ============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ScriptDir = $PSScriptRoot
Set-Location $ScriptDir

$TargetScript = Join-Path $ScriptDir "noise_tester.py"
$PythonDir = Join-Path $ScriptDir "python_x86"
$PythonExe = Join-Path $PythonDir "python.exe"

$Installer = Join-Path $ScriptDir "python-3.11.9-x86.exe"
$InstallerUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9.exe"


Write-Host ""
Write-Host "=============================================="
Write-Host "       SS13 Noise Tester - Python x86"
Write-Host "=============================================="
Write-Host ""


# ============================================================================
# Check target script
# ============================================================================

if (-not (Test-Path $TargetScript)) {
    Write-Host "ERROR: noise_tester.py was not found:" -ForegroundColor Red
    Write-Host $TargetScript -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}


# ============================================================================
# Check existing local Python
# ============================================================================

$PythonExists = Test-Path $PythonExe

if ($PythonExists) {

    Write-Host "[+] Local Python found:" -ForegroundColor Green
    Write-Host $PythonExe

}
else {

    Write-Host "[!] Local Python x86 not found." -ForegroundColor Yellow
    Write-Host "[*] Downloading official Python 3.11.9..." -ForegroundColor Cyan
    Write-Host ""

    # ------------------------------------------------------------------------
    # Download installer
    # ------------------------------------------------------------------------

    try {

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        Invoke-WebRequest `
            -Uri $InstallerUrl `
            -OutFile $Installer `
            -UseBasicParsing

    }
    catch {

        Write-Host ""
        Write-Host "ERROR: Failed to download Python installer." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        Read-Host "Press Enter to exit"
        exit 1
    }


    # ------------------------------------------------------------------------
    # Check downloaded file
    # ------------------------------------------------------------------------

    if (-not (Test-Path $Installer)) {

        Write-Host ""
        Write-Host "ERROR: Installer was not downloaded." -ForegroundColor Red

        Read-Host "Press Enter to exit"
        exit 1
    }

    $InstallerSize = (Get-Item $Installer).Length

    Write-Host "[+] Installer downloaded." -ForegroundColor Green
    Write-Host ("    Size: {0:N0} bytes" -f $InstallerSize)


    if ($InstallerSize -lt 10000000) {

        Write-Host ""
        Write-Host "ERROR: Installer file is suspiciously small." -ForegroundColor Red

        Remove-Item $Installer -Force -ErrorAction SilentlyContinue

        Read-Host "Press Enter to exit"
        exit 1
    }


    # ------------------------------------------------------------------------
    # Create Python directory
    # ------------------------------------------------------------------------

    if (-not (Test-Path $PythonDir)) {

        New-Item `
            -ItemType Directory `
            -Path $PythonDir `
            -Force | Out-Null
    }


    # ------------------------------------------------------------------------
    # Install Python
    # ------------------------------------------------------------------------

    Write-Host ""
    Write-Host "[*] Installing Python 3.11.9 x86..." -ForegroundColor Cyan
    Write-Host "[*] Target: $PythonDir"
    Write-Host ""


    $Arguments = @(
        "/quiet"
        "InstallAllUsers=0"
        "PrependPath=0"
        "Include_launcher=0"
        "Include_pip=1"
        "Include_tcltk=1"
        "Include_test=0"
        "SimpleInstall=1"
        "TargetDir=$PythonDir"
    )


    try {

        $Process = Start-Process `
            -FilePath $Installer `
            -ArgumentList $Arguments `
            -Wait `
            -PassThru

    }
    catch {

        Write-Host ""
        Write-Host "ERROR: Failed to start Python installer." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        Remove-Item $Installer -Force -ErrorAction SilentlyContinue

        Read-Host "Press Enter to exit"
        exit 1
    }


    # ------------------------------------------------------------------------
    # Installer exit code
    # ------------------------------------------------------------------------

    if ($Process.ExitCode -ne 0) {

        Write-Host ""
        Write-Host "ERROR: Python installer returned code $($Process.ExitCode)." -ForegroundColor Red

        Remove-Item $Installer -Force -ErrorAction SilentlyContinue

        Read-Host "Press Enter to exit"
        exit 1
    }


    # ------------------------------------------------------------------------
    # Remove installer
    # ------------------------------------------------------------------------

    Remove-Item $Installer -Force -ErrorAction SilentlyContinue


    # ------------------------------------------------------------------------
    # Check python.exe
    # ------------------------------------------------------------------------

    if (-not (Test-Path $PythonExe)) {

        Write-Host ""
        Write-Host "ERROR: python.exe was not found after installation." -ForegroundColor Red
        Write-Host "Expected:" -ForegroundColor Red
        Write-Host $PythonExe -ForegroundColor Red

        Read-Host "Press Enter to exit"
        exit 1
    }


    Write-Host ""
    Write-Host "[+] Python installed successfully." -ForegroundColor Green
}


# ============================================================================
# Check Python architecture
# ============================================================================

Write-Host ""
Write-Host "[*] Checking Python architecture..." -ForegroundColor Cyan

$Bitness = & $PythonExe -c "import struct; print(struct.calcsize('P') * 8)"

if ($LASTEXITCODE -ne 0) {

    Write-Host "ERROR: Could not execute Python." -ForegroundColor Red

    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[+] Python architecture: $Bitness-bit" -ForegroundColor Green


if ($Bitness -ne "32") {

    Write-Host ""
    Write-Host "ERROR: Python is not 32-bit!" -ForegroundColor Red
    Write-Host "Detected: $Bitness-bit" -ForegroundColor Red

    Read-Host "Press Enter to exit"
    exit 1
}


# ============================================================================
# Check required modules
# ============================================================================

Write-Host ""
Write-Host "[*] Checking Python modules..." -ForegroundColor Cyan

& $PythonExe -c "import tkinter; import numpy; import matplotlib"

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "[!] Required modules are missing." -ForegroundColor Yellow
    Write-Host "[*] Installing NumPy and Matplotlib..." -ForegroundColor Cyan
    Write-Host ""


    & $PythonExe -m pip install `
        --only-binary=:all: `
        "numpy<2.0" `
        "matplotlib<3.9"


    if ($LASTEXITCODE -ne 0) {

        Write-Host ""
        Write-Host "ERROR: Failed to install Python modules." -ForegroundColor Red

        Read-Host "Press Enter to exit"
        exit 1
    }

}
else {

    Write-Host "[+] tkinter: OK" -ForegroundColor Green
    Write-Host "[+] numpy: OK" -ForegroundColor Green
    Write-Host "[+] matplotlib: OK" -ForegroundColor Green
}


# ============================================================================
# Final module verification
# ============================================================================

Write-Host ""
Write-Host "[*] Verifying environment..." -ForegroundColor Cyan

& $PythonExe -c "import tkinter; import numpy; import matplotlib; print('Python:', __import__('sys').version.split()[0]); print('NumPy:', numpy.__version__); print('Matplotlib:', matplotlib.__version__); print('Tkinter: OK')"

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "ERROR: Python environment verification failed." -ForegroundColor Red

    Read-Host "Press Enter to exit"
    exit 1
}


# ============================================================================
# Run noise_tester.py
# ============================================================================

Write-Host ""
Write-Host "=============================================="
Write-Host "[>] Starting noise_tester.py"
Write-Host "=============================================="
Write-Host ""

& $PythonExe $TargetScript

$ExitCode = $LASTEXITCODE


# ============================================================================
# Exit
# ============================================================================

Write-Host ""

if ($ExitCode -eq 0) {

    Write-Host "[+] noise_tester.py finished." -ForegroundColor Green

}
else {

    Write-Host "[!] noise_tester.py exited with code $ExitCode." -ForegroundColor Red
}


Write-Host ""
Read-Host "Press Enter to exit"
