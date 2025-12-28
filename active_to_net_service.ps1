@('Dnscache', 'Dhcp', 'LanmanServer', 'Browser', 'Netlogon', 'SamSs', 'LanmanWorkstation', 'KeyIso', 'FDResPub', 'SSDPSRV', 'upnphost', 'RpcSs', 'RpcEptMapper', 'EventLog', 'lmhosts', 'NlaSvc') | ForEach-Object { 
    Start-Service -Name $_ 
}
