@('Dnscache', 'Dhcp', 'LanmanServer', 'Browser', 'Netlogon', 'SamSs', 'LanmanWorkstation', 'KeyIso', 'FDResPub', 'SSDPSRV', 'upnphost', 'RpcSs', 'RpcEptMapper', 'EventLog', 'lmhosts', 'NlaSvc') | ForEach-Object { 
    Start-Service -Name $_ 
}
# Покажем все службы связанные с сетью
Get-Service | Where-Object {
    $_.DisplayName -like "*сеть*" -or 
    $_.DisplayName -like "*сервер*" -or
    $_.DisplayName -like "*клиент*" -or
    $_.DisplayName -like "*обозреватель*" -or
    $_.DisplayName -like "*обнаруж*" -or
    $_.DisplayName -like "*SMB*" -or
    $_.DisplayName -like "*NetBIOS*"
} | Select-Object Name, DisplayName, Status | Format-Table -AutoSize
