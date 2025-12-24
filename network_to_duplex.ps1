$bytes1251_1 = $encoding1251.GetBytes($originalText1)
$bytes1251_2 = $encoding1251.GetBytes($originalText2)
$original = "Скорость и дуплекс"
$original = "1 Гбит/с дуплекс" 
Get-NetAdapter | Where-Object { $_.LinkSpeed -eq '100 Mbps' } | ForEach-Object {
IF($_.Name -like '*hernet*'  )
{
    Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName $original1 -DisplayValue $original2
    Restart-NetAdapter -Name $_.Name 
}
}


