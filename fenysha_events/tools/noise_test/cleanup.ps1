# ============================================================================
# SS13 Noise Tester
# Python 3.11 x86 cleanup
# ============================================================================
#
# Удаляет локальную установку Python, созданную launcher.ps1:
#
#     .\python_x86\
#
# Также удаляет оставшийся installer, если он существует.
#
# Системный Python, PATH и другие установки Python НЕ затрагиваются.
# ============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ScriptDir = $PSScriptRoot
Set-Location $ScriptDir

$PythonDir = Join-Path $ScriptDir "python_x86"
$PythonExe = Join-Path $PythonDir "python.exe"
$Installer = Join-Path $ScriptDir "python-3.11.9-x86.exe"


Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "       SS13 Noise Tester - Python cleanup" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""


# ============================================================================
# Check local Python
# ============================================================================

if (Test-Path $PythonExe) {

    Write-Host "[+] Local Python found:" -ForegroundColor Green
    Write-Host "    $PythonExe"
    Write-Host ""

    # ------------------------------------------------------------------------
    # Check architecture before deletion
    # ------------------------------------------------------------------------

    Write-Host "[*] Checking Python architecture..." -ForegroundColor Cyan

    try {

        $Bitness = & $PythonExe -c "import struct; print(struct.calcsize('P') * 8)"

        if ($LASTEXITCODE -eq 0) {

            Write-Host "[+] Python architecture: $Bitness-bit" `
                -ForegroundColor Green

        }
        else {

            Write-Host "[!] Could not determine Python architecture." `
                -ForegroundColor Yellow

        }

    }
    catch {

        Write-Host "[!] Could not execute local Python." `
            -ForegroundColor Yellow
    }

}
else {

    Write-Host "[!] Local Python was not found." `
        -ForegroundColor Yellow

    Write-Host "    Expected:"
    Write-Host "    $PythonDir"
    Write-Host ""
}


# ============================================================================
# Check what is going to be deleted
# ============================================================================

$PythonExists = Test-Path $PythonDir
$InstallerExists = Test-Path $Installer

if (-not $PythonExists -and -not $InstallerExists) {

    Write-Host "[+] Nothing to remove." -ForegroundColor Green
    Write-Host ""

    Read-Host "Press Enter to exit"

    exit 0
}


Write-Host ""
Write-Host "The following files will be removed:" `
    -ForegroundColor Yellow
Write-Host ""


if ($PythonExists) {

    Write-Host "  [DIR] $PythonDir" `
        -ForegroundColor Yellow
}


if ($InstallerExists) {

    Write-Host "  [FILE] $Installer" `
        -ForegroundColor Yellow
}


Write-Host ""


# ============================================================================
# Confirmation
# ============================================================================

$Answer = Read-Host "Remove local Python environment? [Y/N]"

if (
    $Answer -ne "Y" -and
    $Answer -ne "y"
) {

    Write-Host ""
    Write-Host "Cancelled." -ForegroundColor Yellow
    Write-Host ""

    Read-Host "Press Enter to exit"

    exit 0
}


# ============================================================================
# Remove Python directory
# ============================================================================

if ($PythonExists) {

    Write-Host ""
    Write-Host "[*] Removing local Python..." `
        -ForegroundColor Cyan

    try {

        # --------------------------------------------------------------------
        # Удаляем директорию целиком.
        #
        # Это удалит:
        #
        #   python.exe
        #   python311.dll
        #   Lib\
        #   DLLs\
        #   Scripts\
        #   site-packages\
        #   numpy
        #   matplotlib
        #   tkinter
        #   и т.д.
        # --------------------------------------------------------------------

        Remove-Item `
            -LiteralPath $PythonDir `
            -Recurse `
            -Force `
            -ErrorAction Stop

        Write-Host "[+] Python directory removed." `
            -ForegroundColor Green

    }
    catch {

        Write-Host ""
        Write-Host "[!] Failed to completely remove Python directory." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Red

        Write-Host ""
        Write-Host "Possible reason: python.exe is still running." `
            -ForegroundColor Yellow

        Write-Host ""
    }
}


# ============================================================================
# Remove installer
# ============================================================================

if (Test-Path $Installer) {

    Write-Host ""
    Write-Host "[*] Removing installer..." `
        -ForegroundColor Cyan

    try {

        Remove-Item `
            -LiteralPath $Installer `
            -Force `
            -ErrorAction Stop

        Write-Host "[+] Installer removed." `
            -ForegroundColor Green

    }
    catch {

        Write-Host "[!] Failed to remove installer." `
            -ForegroundColor Yellow

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}


# ============================================================================
# Final verification
# ============================================================================

Write-Host ""
Write-Host "[*] Verifying cleanup..." `
    -ForegroundColor Cyan

Write-Host ""


if (Test-Path $PythonDir) {

    Write-Host "[!] python_x86 directory still exists:" `
        -ForegroundColor Yellow

    Write-Host "    $PythonDir"

}
else {

    Write-Host "[+] python_x86 directory removed." `
        -ForegroundColor Green
}


if (Test-Path $Installer) {

    Write-Host "[!] Installer still exists:" `
        -ForegroundColor Yellow

    Write-Host "    $Installer"

}
else {

    Write-Host "[+] Installer removed." `
        -ForegroundColor Green
}


# ============================================================================
# Important note
# ============================================================================

Write-Host ""
Write-Host "System Python installations were NOT modified." `
    -ForegroundColor Cyan

Write-Host "PATH was NOT modified." `
    -ForegroundColor Cyan

Write-Host "Registry was NOT modified." `
    -ForegroundColor Cyan


# ============================================================================
# Finish
# ============================================================================

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Cleanup finished" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
