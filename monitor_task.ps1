# Бесконечный мониторинг процессов с окнами
while ($true) {
    Clear-Host
    Write-Host "Процессы с окнами (обновление каждые 5 сек):" -ForegroundColor Yellow
    Write-Host "=" * 50
    
    Get-Process | Where-Object { $_.MainWindowTitle } |
    Select-Object Name, @{Name="WindowTitle"; Expression={ 
        if ($_.MainWindowTitle.Length -gt 50) { 
            $_.MainWindowTitle.Substring(0,47) + "..." 
        } else { 
            $_.MainWindowTitle 
        }
    }}, Id, Responding |
    Format-Table -AutoSize
    
    Write-Host "Нажмите Ctrl+C для выхода" -ForegroundColor Gray
    Start-Sleep -Seconds 5
}
