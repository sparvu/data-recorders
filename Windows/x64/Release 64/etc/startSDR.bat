

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


goto serviceInstall

:rebuild perf Counters
cd\windows\system32
lodctr /R
CD /D "%~dp0"

:serviceInstall
sc create "SDR_Sysrec" binPath= "%CD%\..\bin\SDR_sysrec.exe"  start= auto displayname= "System data recorder for system data."
sc description "SDR_Sysrec" "System data recorder for system data."
sc start "SDR_Sysrec"


sc create "SDR_Cpurec" binPath= "%CD%\..\bin\SDR_cpurec.exe"  start= auto displayname= "System data recorder for cpu data."
sc description "SDR_Cpurec" "System data recorder for cpu data."
sc start "SDR_Cpurec"


sc create "SDR_Diskrec" binPath= "%CD%\..\bin\SDR_diskrec.exe"  start= auto displayname= "System data recorder for disk data."
sc description "SDR_Diskrec" "System data recorder for disk data."
sc start "SDR_Diskrec"


sc create "SDR_Hdwrec" binPath= "%CD%\..\bin\SDR_hdwrec.exe"  start= auto displayname= "System data recorder for hardware data."
sc description "SDR_Hdwrec" "System data recorder for hardware data."
sc start "SDR_Hdwrec"


sc create "SDR_Nicrec" binPath= "%CD%\..\bin\SDR_nicrec.exe"  start= auto displayname= "System data recorder for network interface data."
sc description "SDR_Nicrec" "System data recorder for network interface data."
sc start "SDR_Nicrec"


 timeout /T 5