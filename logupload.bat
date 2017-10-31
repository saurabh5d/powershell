Echo off

set scriptpath="%~dp0FTPupload.ps1"


If Exist "C:\Windows\SysWOW64" GOTO x64PlatForm
"C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe" set-executionpolicy unrestricted
"C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe" -file %scriptpath%
GOTO End

:x64PlatForm
"C:\Windows\SysWOW64\WindowsPowershell\v1.0\powershell.exe" set-executionpolicy unrestricted
"C:\Windows\SysWOW64\WindowsPowershell\v1.0\powershell.exe" -file %scriptpath%
GOTO End


:End

