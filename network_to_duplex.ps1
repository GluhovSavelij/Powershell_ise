function Test-ScriptEncoding {
    param([string]$Path)
    
    try {
        $content = Get-Content -Path $Path -Raw -ErrorAction Stop
        
        # Проверка на проблемные паттерны
        $issues = @()
        
        if ($content -match '\?\?\?\?\?\?') {
            $issues += "Обнаружены знаки вопроса (?????)"
        }
        
        if ($content -match 'DisplayName "_{10,}"') {
            $issues += "DisplayName содержит подчеркивания"
        }
        
        if ($content -notmatch 'DisplayName "Speed & Duplex"') {
            $issues += "DisplayName не установлен в 'Speed & Duplex'"
        }
        
        # Проверка BOM
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $hasBOM = $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        
        return @{
            HasUTF8BOM = $hasBOM
            Issues = $issues
            IsFixed = ($issues.Count -eq 0)
        }
    }
    catch {
        Write-Error "Ошибка при чтении файла: $_"
        return @{
            HasUTF8BOM = $false
            Issues = @("Файл не найден или недоступен")
            IsFixed = $false
        }
    }
}

# Исправленный скрипт для сетевых адаптеров
function Set-NetworkAdapterSpeed {
    param(
        [string]$AdapterPattern = "*hernet*",
        [string]$TargetSpeed = "1.0 Гбит/с Full Duplex"
    )
    
    # Получаем все Ethernet адаптеры
    $adapters = Get-NetAdapter | Where-Object { $_.Name -like $AdapterPattern }
    
    if (-not $adapters) {
        Write-Warning "Адаптеры, соответствующие шаблону '$AdapterPattern', не найдены"
        return
    }
    
    foreach ($adapter in $adapters) {
        Write-Host "Обработка адаптера: $($adapter.Name) (Текущая скорость: $($adapter.LinkSpeed))" -ForegroundColor Cyan
        
        try {
            # Проверяем, есть ли свойство "Speed & Duplex"
            $properties = Get-NetAdapterAdvancedProperty -Name $adapter.Name
            
            if ($properties.DisplayName -contains "Speed & Duplex") {
                # Устанавливаем скорость
                Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Speed & Duplex" -DisplayValue $TargetSpeed
                Write-Host "  ✓ Скорость установлена на: $TargetSpeed" -ForegroundColor Green
                
                # Перезапускаем адаптер
                Write-Host "  ↻ Перезапуск адаптера..." -ForegroundColor Yellow
                Restart-NetAdapter -Name $adapter.Name -Confirm:$false
                
                # Проверяем результат
                Start-Sleep -Seconds 2
                $updatedAdapter = Get-NetAdapter -Name $adapter.Name -ErrorAction SilentlyContinue
                if ($updatedAdapter) {
                    Write-Host "  ✓ Адаптер перезапущен. Новая скорость: $($updatedAdapter.LinkSpeed)" -ForegroundColor Green
                }
            }
            else {
                Write-Warning "  Свойство 'Speed & Duplex' не найдено для адаптера $($adapter.Name)"
            }
        }
        catch {
            Write-Error "  Ошибка при обработке адаптера $($adapter.Name): $_"
        }
    }
}

# Пример использования:
if ($MyInvocation.ScriptName -like "*test*") {
    # Тестирование кодировки
    $result = Test-ScriptEncoding -Path "ваш_скрипт.ps1"
    if ($result.IsFixed) {
        Write-Host "✓ Скрипт исправлен" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Проблемы: $($result.Issues -join ', ')" -ForegroundColor Red
    }
    
    # Исправление скорости адаптера
    Set-NetworkAdapterSpeed
}
