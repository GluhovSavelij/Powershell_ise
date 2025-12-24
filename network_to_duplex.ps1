$bytes1251 = $encoding1251.GetBytes($originalText)
$originalText = @(
Get-NetAdapter | Where-Object { $_.LinkSpeed -eq '100 Mbps' } | ForEach-Object {
IF($_.Name -like '*hernet*'  )
{
    Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Скорость и дуплекс" -DisplayValue "1 Гбит/с дуплекс"  
    Restart-NetAdapter -Name $_.Name 
}
}
)

