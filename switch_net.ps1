$exactNames = @('Ethernet', 'Ethernet 2', 'LAN', 'Local Area Connection')

# Изменение 1: Получаем строку вместо объекта Select-String
$current_network = Get-NetRoute | Where-Object {
    $_.NextHop -like '192.168.1.*' -or 
    $_.NextHop -like '192.168.0.*'
} | ForEach-Object { $_.NextHop } | Select-String -SimpleMatch 192 | Select-Object -First 1 | ForEach-Object { $_.Line }

# Изменение 2: Берем только первый IP и добавляем .32
$ip = Get-NetRoute | Where-Object {
    $_.NextHop -like '192.168.1.*' -or 
    $_.NextHop -like '192.168.0.*'
} | Select-Object -First 1 | ForEach-Object { $_.NextHop -replace '\.\d+$', '.32' }

$ip_r = $ip   
$as = Get-NetIPAddress | Where-Object {
    $_.InterfaceAlias -in $exactNames
} | Select-Object -First 1 -ExpandProperty InterfaceAlias

if ($as) {
    Write-Host "Найден интерфейс: $as" -ForegroundColor Green
    
    
    Write-Host "Удаляю старые IP-адреса..." -ForegroundColor Yellow
    Get-NetIPAddress -InterfaceAlias $as -ErrorAction SilentlyContinue | 
        Remove-NetIPAddress -Confirm:$false
    
    
    Write-Host "Добавляю IP: $ip_r" -ForegroundColor Yellow  # Изменение 3: Показываем реальный IP
    try {
        New-NetIPAddress -IPAddress $ip_r `
                         -DefaultGateway $current_network `
                         -PrefixLength 24 `
                         -InterfaceAlias $as `
                         -ErrorAction Stop
        
        Write-Host "IP успешно добавлен!" -ForegroundColor Green
        
        
        Write-Host "Настраиваю DNS..." -ForegroundColor Yellow
        Set-DnsClientServerAddress -InterfaceAlias $as `
                                  -ServerAddresses ("77.88.8.8", "77.88.8.1") `
                                  -ErrorAction Stop
        
        Write-Host "DNS успешно настроены: 77.88.8.8, 77.88.8.1" -ForegroundColor Green
        
        
        Write-Host "`n=== ТЕКУЩИЕ НАСТРОЙКИ ===" -ForegroundColor Cyan
        
        Write-Host "IP-адреса:" -ForegroundColor Yellow
        Get-NetIPAddress -InterfaceAlias $as -ErrorAction SilentlyContinue | 
            Select-Object IPAddress, PrefixLength, AddressFamily | Format-Table
        
        Write-Host "`nDNS серверы:" -ForegroundColor Yellow
        Get-DnsClientServerAddress -InterfaceAlias $as -ErrorAction SilentlyContinue | 
            Select-Object -ExpandProperty ServerAddresses
        
    } catch {
        Write-Host "Ошибка: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Ethernet интерфейсы не найдены!" -ForegroundColor Red
}
