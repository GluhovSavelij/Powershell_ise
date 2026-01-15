function Quick-IP-Find {
    param(
        [int]$InterfaceIndex = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | 
                               Where-Object {$_.NextHop -like "192*"} | 
                               Select-Object -First 1 -ErrorAction SilentlyContinue).InterfaceIndex,
        [string]$TestDomain = "ya.ru",
        [string[]]$DNSServers = @("77.88.8.8", "77.88.8.2"),
        [switch]$SkipDNS
    )
    
    # Проверка наличия необходимых модулей
    if (-not (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Модуль NetAdapter не доступен. Запустите от имени администратора!" -ForegroundColor Red
        return $null
    }
    
    # Получаем информацию о текущем адаптере
    $adapter = Get-NetAdapter -InterfaceIndex $InterfaceIndex -ErrorAction SilentlyContinue
    if (-not $adapter) {
        Write-Host "❌ Адаптер с индексом $InterfaceIndex не найден!" -ForegroundColor Red
        Write-Host "Доступные адаптеры:" -ForegroundColor Yellow
        Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Format-Table Name, InterfaceIndex, Status, MacAddress
        return $null
    }
    
    $interfaceAlias = $adapter.Name
    Write-Host "=== Настройка сети ===" -ForegroundColor Cyan
    Write-Host "Адаптер: $interfaceAlias (Index: $InterfaceIndex)" -ForegroundColor Cyan
    Write-Host "Тестовый домен: $TestDomain" -ForegroundColor Cyan
    
    # Получаем шлюз по умолчанию
    $defaultGateway = (Get-NetRoute -InterfaceIndex $InterfaceIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue).NextHop
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
    $prefixLength = $currentIPConfig.PrefixLength
    
    Write-Host "Текущий IP: $currentIP/$prefixLength" -ForegroundColor Yellow
    Write-Host "Шлюз: $defaultGateway" -ForegroundColor Yellow
    Write-Host "Диапазон поиска: ${subnet}10 - ${subnet}254" -ForegroundColor Yellow
    Write-Host "`nПоиск рабочего IP для $TestDomain..." -ForegroundColor Cyan
    
    # Сохраняем оригинальную конфигурацию для восстановления
    $originalConfig = @{
        IPAddress = $currentIP
        PrefixLength = $prefixLength
        Gateway = $defaultGateway
        DNS = (Get-DnsClientServerAddress -InterfaceAlias $interfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
    }
    
    # Тестируем IP-адреса
    $foundIP = $null
    foreach ($i in 10..254) {
        $testIP = "${subnet}$i"
        
        # Пропускаем текущий IP и шлюз
        if ($testIP -eq $currentIP -or $testIP -eq $defaultGateway) { 
            Write-Host "[Пропуск] $testIP (текущий IP или шлюз)" -ForegroundColor Gray
            continue 
        }
        
        Write-Host "Тест $testIP..." -NoNewline
        
        try {
            # Удаляем старый IP (если не первый тест)
            if ($currentIP -ne $testIP) {
                Remove-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $currentIP -Confirm:$false -ErrorAction Stop
            }
            
            # Устанавливаем новый IP
            New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $testIP `
                            -PrefixLength $prefixLength -DefaultGateway $defaultGateway -ErrorAction Stop
            
            # Настраиваем DNS если не пропущен
            if (-not $SkipDNS) {
                Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias `
                                          -ServerAddresses $DNSServers `
                                          -ErrorAction Stop
            }
            
            Write-Host " [сетевые настройки применены] " -NoNewline -ForegroundColor DarkGray
            
            # Даем время для применения настроек
            Start-Sleep -Milliseconds 500
            
            # Проверяем соединение разными способами
            $connectionTest = $false
            
            # Способ 1: Ping
            if (Test-Connection $TestDomain -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                $connectionTest = $true
            }
            
            # Способ 2: DNS разрешение (если не пропускаем DNS)
            if (-not $connectionTest -and -not $SkipDNS) {
                try {
                    $dnsTest = Resolve-DnsName $TestDomain -Server $DNSServers[0] -ErrorAction Stop -QuickTimeout
                    if ($dnsTest) { $connectionTest = $true }
                } catch {}
            }
            
            # Способ 3: HTTP запрос (если есть интернет)
            if (-not $connectionTest) {
                try {
                    $webTest = Invoke-WebRequest "http://$TestDomain" -TimeoutSec 2 -ErrorAction SilentlyContinue
                    if ($webTest.StatusCode -eq 200) { $connectionTest = $true }
                } catch {}
            }
            
            if ($connectionTest) {
                Write-Host " ✅ РАБОТАЕТ!" -ForegroundColor Green
                Write-Host "`n🎉 Найден рабочий IP: $testIP" -ForegroundColor Green
                Write-Host "   Адаптер: $interfaceAlias" -ForegroundColor Green
                Write-Host "   Шлюз: $defaultGateway" -ForegroundColor Green
                Write-Host "   Маска: /$prefixLength" -ForegroundColor Green
                if (-not $SkipDNS) {
                    Write-Host "   DNS: $($DNSServers -join ', ')" -ForegroundColor Green
                }
                
                $foundIP = $testIP
                break
            } else {
                Write-Host " ❌ Нет соединения" -ForegroundColor Red
            }
            
            # Обновляем текущий IP для следующей итерации
            $currentIP = $testIP
            
        } catch {
            Write-Host " [ОШИБКА: $($_.Exception.Message)]" -ForegroundColor Red
            # Пытаемся восстановить конфигурацию при ошибке
            try {
                Remove-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $testIP -Confirm:$false -ErrorAction SilentlyContinue
                New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $originalConfig.IPAddress `
                                -PrefixLength $originalConfig.PrefixLength -DefaultGateway $originalConfig.Gateway -ErrorAction SilentlyContinue
                if ($originalConfig.DNS) {
                    Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias `
                                              -ServerAddresses $originalConfig.DNS `
                                              -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Host "Внимание: не удалось восстановить конфигурацию!" -ForegroundColor Yellow
            }
            continue
        }
    }
    
    # Восстанавливаем оригинальную конфигурацию, если не нашли рабочий IP
    if (-not $foundIP) {
        Write-Host "`n⚠️ Рабочий IP не найден. Восстанавливаю оригинальную конфигурацию..." -ForegroundColor Yellow
        try {
            # Удаляем тестовый IP если он остался
            if ($currentIP -ne $originalConfig.IPAddress) {
                Remove-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $currentIP -Confirm:$false -ErrorAction SilentlyContinue
            }
            
            # Восстанавливаем оригинальный IP
            $existingIP = Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if (-not $existingIP -or $existingIP.IPAddress -ne $originalConfig.IPAddress) {
                New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $originalConfig.IPAddress `
                                -PrefixLength $originalConfig.PrefixLength -DefaultGateway $originalConfig.Gateway -ErrorAction SilentlyContinue
            }
            
            # Восстанавливаем DNS
            if ($originalConfig.DNS) {
                Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias `
                                          -ServerAddresses $originalConfig.DNS `
                                          -ErrorAction SilentlyContinue
            }
            
            Write-Host "✅ Оригинальный IP восстановлен: $($originalConfig.IPAddress)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Не удалось восстановить оригинальный IP!" -ForegroundColor Red
            Write-Host "Текущий IP: $currentIP" -ForegroundColor Yellow
        }
    }
    
    # Проверяем финальное соединение
    if ($foundIP) {
        Write-Host "`n🔍 Проверка финального соединения..." -ForegroundColor Cyan
        try {
            if (Test-Connection $TestDomain -Count 2 -Quiet -ErrorAction SilentlyContinue) {
                Write-Host "✅ Соединение стабильно" -ForegroundColor Green
            } else {
                Write-Host "⚠️ Соединение может быть нестабильным" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "⚠️ Не удалось проверить стабильность соединения" -ForegroundColor Yellow
        }
    }
    
    return $foundIP
}

# Функция для удобного запуска
function Switch-Network {
    param(
        [string]$TestDomain = "ya.ru",
        [int]$StartRange = 10,
        [int]$EndRange = 254
    )
    
    # Проверка прав администратора
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "❌ Требуются права администратора!" -ForegroundColor Red
        Write-Host "Запустите PowerShell от имени администратора" -ForegroundColor Yellow
        return
    }
    
    Write-Host "=== Network Switcher ===" -ForegroundColor Cyan
    Write-Host "Поиск рабочего IP-адреса в сети" -ForegroundColor Cyan
    Write-Host "`nДоступные сетевые адаптеры:" -ForegroundColor Yellow
    
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object Name, InterfaceIndex, Status, MacAddress
    $adapters | Format-Table -AutoSize
    
    # Выбор адаптера
    if ($adapters.Count -gt 1) {
        $selectedIndex = Read-Host "`nВведите индекс адаптера (или Enter для автоматического выбора)"
        if ($selectedIndex -match '^\d+$') {
            $result = Quick-IP-Find -InterfaceIndex $selectedIndex -TestDomain $TestDomain
        } else {
            $result = Quick-IP-Find -TestDomain $TestDomain
        }
    } else {
        $result = Quick-IP-Find -TestDomain $TestDomain
    }
    
    if ($result) {
        Write-Host "`n✅ Сеть успешно переключена на IP: $result" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Не удалось найти рабочий IP-адрес" -ForegroundColor Red
    }
}

# Автоматический запуск
if ($MyInvocation.InvocationName -ne '.') {
    Switch-Network
}
