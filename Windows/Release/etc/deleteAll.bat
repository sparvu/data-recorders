@echo off
setlocal
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" == "5.2" goto NOUAC
if "%version%" == "5.1" goto NOUAC
endlocal

:UAC
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
: End check for permissions

:NOUAC

sc stop "SDR_Sysrec"
sc delete "SDR_Sysrec"


sc stop "SDR_Cpurec"
sc delete "SDR_Cpurec"


sc stop "SDR_Diskrec"
sc delete "SDR_Diskrec"


sc stop "SDR_Hdwrec"
sc delete "SDR_Hdwrec"


sc stop "SDR_Nicrec"
sc delete "SDR_Nicrec"


sc stop "SDR_Sender"
sc delete "SDR_Sender"



timeout /T 3