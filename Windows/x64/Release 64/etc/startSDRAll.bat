

@echo off

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

sc create "SDR_Sender" binPath= "%CD%\..\bin\SDR_sender.exe"  start= auto displayname= "System data recorder sender."
sc description "SDR_Sender" "System data recorder sender."
sc start "SDR_Sender"

 timeout /T 3