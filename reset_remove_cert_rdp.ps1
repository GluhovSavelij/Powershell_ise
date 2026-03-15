Get-ChildItem Cert:\LocalMachine\Remote Desktop | Remove-Item
Restart-Service TermService -Force
net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver

# Удалить кэш обновлений
Remove-Item -Path C:\Windows\SoftwareDistribution -Recurse -Force
Remove-Item -Path C:\Windows\System32\catroot2 -Recurse -Force

net start wuauserv
net start cryptSvc
net start bits
net start msiserver
