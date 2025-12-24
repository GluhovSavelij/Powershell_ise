[System.Text.Encoding]::GetEncoding(1251)
function Test-ScriptEncoding {
    param([string]$Path)
    
    $content = Get-Content -Path $Path -Raw
    
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

# Использование
$result = Test-ScriptEncoding -Path "ваш_скрипт.ps1"
if ($result.IsFixed) {
    Write-Host "✓ Скрипт исправлен" -ForegroundColor Green
} else {
    Write-Host "✗ Проблемы: $($result.Issues -join ', ')" -ForegroundColor Red
}
 $sc = 
Get-NetAdapter | Where-Object { $_.LinkSpeed -eq '100 Mbps' } | ForEach-Object {
IF($_.Name -like '*hernet*'  )
{
    Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Скорость и дуплекс" -DisplayValue "1 Гбит/с дуплекс"  
    Restart-NetAdapter -Name $_.Name 
}
}
