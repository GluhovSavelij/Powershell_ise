function Quick-IP-Find {
    param(
        [int]$InterfaceIndex = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | 
                               Where-Object {$_.NextHop -like "192*"} | 
                               Select-Object -First 1).InterfaceIndex,
        [string]$TestDomain = "ya.ru",
        [string[]]$DNSServers = @("77.88.8.8", "77.88.8.1")
    )
    
    # Получаем информацию о текущем адаптере
    $adapter = Get-NetAdapter -InterfaceIndex $InterfaceIndex -ErrorAction SilentlyContinue
    if (-not $adapter) {
        Write-Host "❌ Адаптер с индексом $InterfaceIndex не найден!" -ForegroundColor Red
        return $null
    }
    
    $interfaceAlias = $adapter.Name
    Write-Host "Работаю с адаптером: $interfaceAlias (Index: $InterfaceIndex)" -ForegroundColor Cyan
    
    # Получаем шлюз по умолчанию
    $defaultGateway = (Get-NetRoute -InterfaceIndex $InterfaceIndex -DestinationPrefix "0.0.0.0/0").NextHop
    if (-not $defaultGateway) {
        Write-Host "❌ Шлюз по умолчанию не найден!" -ForegroundColor Red
        return $null
    }
    
    # Получаем текущий IP
    $currentIPConfig = Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if (-not $currentIPConfig) {
        Write-Host "❌ Не удалось получить IP-конфигурацию!" -ForegroundColor Red
        return $null
    }
    
    $currentIP = $currentIPConfig.IPAddress
    $subnet = $currentIP -replace '\.\d+$', '.'
    
    Write-Host "Текущий IP: $currentIP" -ForegroundColor Yellow
    Write-Host "Шлюз: $defaultGateway" -ForegroundColor Yellow
    Write-Host "Диапазон поиска: ${subnet}10 - ${subnet}254" -ForegroundColor Yellow
    Write-Host "`nИщу первый рабочий IP для $TestDomain..." -ForegroundColor Cyan
    
    # Сохраняем оригинальную конфигурацию для восстановления
    $originalIP = $currentIP
    $originalPrefix = $currentIPConfig.PrefixLength
    
    # Тестируем IP-адреса
    foreach ($i in 10..254) {
        $testIP = "${subnet}$i"
        
        # Пропускаем текущий IP
        if ($testIP -eq $currentIP) { 
            Write-Host "Пропускаю текущий IP: $testIP" -ForegroundColor Gray
            continue 
        }
        
        Write-Host "Тестирую $testIP..." -NoNewline
        
        try {
            # Удаляем старый IP
            Remove-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $currentIP -Confirm:$false -ErrorAction Stop
            
            # Устанавливаем новый IP
            New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $testIP `
                            -PrefixLength 24 -DefaultGateway $defaultGateway -ErrorAction Stop
            
            # Настраиваем DNS (ИСПРАВЛЕНО: используем $interfaceAlias вместо $as)
            Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias `
                                      -ServerAddresses $DNSServers `
                                      -ErrorAction Stop
            
            Write-Host " [DNS настроены] " -NoNewline -ForegroundColor DarkGray
            
            # Даем время для применения настроек
            Start-Sleep -Milliseconds 300
            
            # Проверяем соединение
            if (Test-Connection $TestDomain -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                Write-Host " ✅ РАБОТАЕТ!" -ForegroundColor Green
                Write-Host "`n🎉 Найден рабочий IP: $testIP" -ForegroundColor Green
                Write-Host "   Адаптер: $interfaceAlias" -ForegroundColor Green
                Write-Host "   Шлюз: $defaultGateway" -ForegroundColor Green
                Write-Host "   DNS: $($DNSServers -join ', ')" -ForegroundColor Green
                return $testIP
            } else {
                Write-Host " ❌" -ForegroundColor Red
            }
            
            # Обновляем текущий IP для следующей итерации
            $currentIP = $testIP
            
        } catch {
            Write-Host " [ОШИБКА: $($_.Exception.Message)]" -ForegroundColor Red
            # Пытаемся восстановить оригинальный IP при ошибке
            try {
                New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $originalIP `
                                -PrefixLength $originalPrefix -DefaultGateway $defaultGateway -ErrorAction SilentlyContinue
            } catch {}
            continue
        }
    }
    
    # Восстанавливаем оригинальный IP, если не нашли рабочий
    Write-Host "`n⚠️ Рабочий IP не найден. Восстанавливаю оригинальную конфигурацию..." -ForegroundColor Yellow
    try {
        Remove-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $currentIP -Confirm:$false -ErrorAction SilentlyContinue
        New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $originalIP `
                        -PrefixLength $originalPrefix -DefaultGateway $defaultGateway -ErrorAction SilentlyContinue
        Write-Host "✅ Оригинальный IP восстановлен: $originalIP" -ForegroundColor Green
    } catch {
        Write-Host "❌ Не удалось восстановить оригинальный IP!" -ForegroundColor Red
    }
    
    return $null
}

# Автоматический запуск с определением интерфейса
Quick-IP-Find
