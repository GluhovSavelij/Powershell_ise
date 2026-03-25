function Clear-TemporaryFiles {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    Write-Host "Начинаем очистку временных файлов..." -ForegroundColor Yellow
    
    $tempPaths = @(
        $env:TEMP,
        "C:\Windows\Temp",
        "$env:LOCALAPPDATA\Temp",
        [System.IO.Path]::GetTempPath()
    )
    
    $totalFreed = 0
    $deletedCount = 0
    
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            Write-Host "`nОчищаем: $path" -ForegroundColor Cyan
            
            try {
                # Только файлы старше 1 дня и определенных расширений
                $files = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | 
                         Where-Object { 
                             $_.LastWriteTime -lt (Get-Date).AddDays(-1) -and
                             $_.Extension -match '\.(tmp|log|old|bak|cache|temp)$' -and
                             $_.Name -notmatch '^(system|important)' 
                         }
                
                foreach ($file in $files) {
                    try {
                        if ($Force -or (Test-Path $file.FullName)) {
                            $size = $file.Length
                            Remove-Item $file.FullName -Force -ErrorAction Stop
                            $totalFreed += $size
                            $deletedCount++
                        }
                    }
                    catch {
                        Write-Host "  Не удалось удалить: $($file.Name)" -ForegroundColor DarkYellow
                    }
                }
                
                # Очистка пустых папок
                Get-ChildItem -Path $path -Directory -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue).Count -eq 0 } |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                
                Write-Host "  ✓ Успешно: $deletedCount файлов освобождено $([math]::Round($totalFreed/1MB, 2)) MB" -ForegroundColor Green
            }
            catch {
                Write-Host "  ✗ Ошибка при очистке: $path" -ForegroundColor Red
                Write-Host "    Детали: $($_.Exception.Message)" -ForegroundColor DarkRed
            }
        } else {
            Write-Host "  Путь не найден: $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nОчистка завершена!" -ForegroundColor Green
    Write-Host "Всего освобождено: $([math]::Round($totalFreed/1MB, 2)) MB" -ForegroundColor Green
}
