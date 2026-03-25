Get-ChildItem -Path "C:\" -Directory | ForEach-Object {
    $folder = $_.FullName
    try {
        $size = (Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            'Папка' = $_.Name
            'Размер (GB)' = [math]::Round($size / 1GB, 2)
            'Полный путь' = $folder
        }
    }
    catch {
        [PSCustomObject]@{
            'Папка' = $_.Name
            'Размер (GB)' = "Ошибка доступа"
            'Полный путь' = $folder
        }
    }
} | Sort-Object 'Размер (GB)' -Descending | Format-Table -AutoSize
