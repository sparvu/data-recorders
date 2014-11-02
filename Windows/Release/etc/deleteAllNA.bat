@echo off

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