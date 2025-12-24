# Определяем кодировки
$encoding1251 = [System.Text.Encoding]::GetEncoding(1251)
$encodingUTF8 = [System.Text.Encoding]::UTF8

# Исходные русские тексты
$originalText1 = "Скорость и дуплекс"
$originalText2 = "1 Гбит/с дуплекс"

# Преобразуем в байты (UTF-8 -> Windows-1251)
$bytes1251_1 = $encoding1251.GetBytes($originalText1)
$bytes1251_2 = $encoding1251.GetBytes($originalText2)

# Преобразуем обратно в строки (для проверки)
$displayName1251 = $encoding1251.GetString($bytes1251_1)
$displayValue1251 = $encoding1251.GetString($bytes1251_2)

Write-Host "DisplayName (1251): '$displayName1251'" -ForegroundColor Yellow
Write-Host "DisplayValue (1251): '$displayValue1251'" -ForegroundColor Yellow

# Альтернативный метод - правильные значения для Windows
# В большинстве случаев Windows использует UTF-8 или Unicode
# Правильные значения для сетевых адаптеров:
$correctDisplayName = "Speed & Duplex"
$correctDisplayValues = @(
    "10 Мбит/с Half Duplex",
    "10 Мбит/с Full Duplex", 
    "100 Мбит/с Half Duplex",
    "100 Мбит/с Full Duplex",
    "1.0 Гбит/с Full Duplex",  # ← правильный формат для 1 Гбит
    "2.5 Гбит/с Full Duplex",
    "5.0 Гбит/с Full Duplex",
    "10 Гбит/с Full Duplex"
)

Write-Host "`nРекомендуемые значения:" -ForegroundColor Cyan
Write-Host "DisplayName: '$correctDisplayName'"
Write-Host "DisplayValue для 1 Гбит: '$($correctDisplayValues[4])'"

# Основной скрипт
Get-NetAdapter | Where-Object { $_.LinkSpeed -eq '100 Mbps' } | ForEach-Object {
    if($_.Name -like '*hernet*') {
        Write-Host "`nОбработка адаптера: $($_.Name)" -ForegroundColor Green
        Write-Host "Текущая скорость: $($_.LinkSpeed)" -ForegroundColor Yellow
        
        # Вариант 1: Использовать перекодированные русские значения
        try {
            Write-Host "Попытка установить русские значения..." -ForegroundColor Cyan
            Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName $displayName1251 -DisplayValue $displayValue1251 -ErrorAction Stop
            Write-Host "✓ Значения установлены" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ Ошибка с русскими значениями: $_" -ForegroundColor Red
            
            # Вариант 2: Использовать стандартные английские значения
            Write-Host "Попытка установить стандартные значения..." -ForegroundColor Cyan
            try {
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName $correctDisplayName -DisplayValue $correctDisplayValues[4] -ErrorAction Stop
                Write-Host "✓ Стандартные значения установлены" -ForegroundColor Green
            }
            catch {
                Write-Host "✗ Ошибка: $_" -ForegroundColor Red
            }
        }
        
        # Перезапуск адаптера
        try {
            Write-Host "Перезапуск адаптера..." -ForegroundColor Magenta
            Restart-NetAdapter -Name $_.Name -Confirm:$false -ErrorAction Stop
            Write-Host "✓ Адаптер перезапущен" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ Ошибка при перезапуске: $_" -ForegroundColor Red
        }
    }
}

# Дополнительная функция для проверки доступных свойств
function Get-AdapterProperties {
    param([string]$AdapterName = "*hernet*")
    
    Get-NetAdapter | Where-Object { $_.Name -like $AdapterName } | ForEach-Object {
        Write-Host "`nСвойства адаптера: $($_.Name)" -ForegroundColor Cyan
        Write-Host "=" * 50
        
        $properties = Get-NetAdapterAdvancedProperty -Name $_.Name
        
        # Группируем по DisplayName для удобства
        $groupedProps = $properties | Group-Object DisplayName
        
        foreach ($group in $groupedProps) {
            Write-Host "`nDisplayName: '$($group.Name)'" -ForegroundColor Yellow
            $group.Group | ForEach-Object {
                Write-Host "  - DisplayValue: '$($_.DisplayValue)'"
                Write-Host "    RegistryKeyword: $($_.RegistryKeyword)"
                Write-Host "    Valid: $($_.ValidDisplayValues -join ', ')"
            }
        }
    }
}

# Проверить доступные свойства (раскомментировать при необходимости)
# Get-AdapterProperties

# Функция для поиска правильного имени свойства "Скорость и дуплекс"
function Find-SpeedDuplexProperty {
    param([string]$AdapterName = "*hernet*")
    
    $adapters = Get-NetAdapter | Where-Object { $_.Name -like $AdapterName }
    
    foreach ($adapter in $adapters) {
        Write-Host "`nПоиск для: $($adapter.Name)" -ForegroundColor Cyan
        
        $properties = Get-NetAdapterAdvancedProperty -Name $adapter.Name
        
        # Ищем свойство, связанное со скоростью
        $speedProps = $properties | Where-Object { 
            $_.DisplayName -match "(Speed|Duplex|Скорость|дуплекс)" -or
            $_.RegistryKeyword -match "(Speed|Duplex)"
        }
        
        if ($speedProps) {
            Write-Host "Найдены свойства скорости:" -ForegroundColor Green
            $speedProps | ForEach-Object {
                Write-Host "  DisplayName: '$($_.DisplayName)'"
                Write-Host "  Текущее значение: '$($_.DisplayValue)'"
                Write-Host "  Доступные значения: $($_.ValidDisplayValues -join ', ')"
                Write-Host "  ---"
            }
        } else {
            Write-Host "Свойства скорости не найдены" -ForegroundColor Yellow
        }
    }
}

# Поиск свойства скорости (раскомментировать при необходимости)
# Find-SpeedDuplexProperty
