function Quick-IP-Find {
#здесь можно и обойтись без префикса  и сразу обратиться к шлюзу
    #$interface МОЖНО И АВТОМАТИЗИРОАВТЬ НО ИЗ ЗА РИСКА ОБНУЛЕНРИЯ ВО ВРЕМЯ ТЕСТА ИЗ ЗА ВНИМАТЕЛЬНОСТИ ВЫРЕЗАЛ
    $defaultGateway = (Get-NetRoute -InterfaceIndex 10 -DestinationPrefix "0.0.0.0/0").NextHop | Select-String 192 
    $interface = 10
    $currentIP = (Get-NetIPAddress -InterfaceIndex $interface -AddressFamily IPv4).IPAddress
    $subnet = $currentIP -replace '\.\d+$', '.'
    
    Write-Host "Ищу первый рабочий IP для ya.ru..." -ForegroundColor Cyan
    
    foreach ($i in 10..254) {
        $testIP = "${subnet}$i"
        if ($testIP -eq $currentIP) { continue }
        
        Write-Host "Тест $testIP..." -NoNewline
        
        # Меняем IP
        Get-NetIPAddress -InterfaceIndex $interface -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false
        New-NetIPAddress -InterfaceIndex $interface -IPAddress $testIP -PrefixLength 24 -DefaultGateway $defaultGateway

        Set-DnsClientServerAddress -InterfaceAlias $as `
                                  -ServerAddresses ("77.88.8.8", "77.88.8.1") `
                                  -ErrorAction Stop
        
        Write-Host "DNS успешно настроены: 77.88.8.8, 77.88.8.1" -ForegroundColor Green
        
        Start-Sleep -Milliseconds 200
        
        # Проверяем ya.ru
        if (Test-Connection "ya.ru" -Count 1 -Quiet) {
            Write-Host " ✅ РАБОТАЕТ!" -ForegroundColor Green
            Write-Host "Используйте IP: $testIP" -ForegroundColor Green
            return $testIP  # ⬅️ Выход при первом успехе
        } else {
            Write-Host " ❌" -ForegroundColor Red
        }
    }
    
    Write-Host "Рабочий IP не найден" -ForegroundColor Red
    return $null
}

Quick-IP-Find
