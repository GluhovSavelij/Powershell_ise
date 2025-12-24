# 修复后的网络适配器双工模式设置脚本
# 使用标准英文参数值以确保兼容性

# 定义正确的参数值（Windows系统通常识别这些英文值）
$correctDisplayName = "Speed & Duplex"
$targetSpeedValue = "1.0 Gbps Full Duplex"

# 获取速度为100 Mbps的以太网适配器
$adaptersToFix = Get-NetAdapter | Where-Object { 
    $_.LinkSpeed -eq '100 Mbps' -and $_.Name -like '*hernet*' 
}

# 检查是否有适配器需要处理
if (-not $adaptersToFix) {
    Write-Host "未找到速度为100 Mbps的以太网适配器，无需更改。" -ForegroundColor Yellow
    exit
}

Write-Host "找到 $($adaptersToFix.Count) 个需要处理的适配器。" -ForegroundColor Cyan

# 循环处理每个适配器
foreach ($adapter in $adaptersToFix) {
    Write-Host "`n正在处理适配器: $($adapter.Name) (接口描述: $($adapter.InterfaceDescription))" -ForegroundColor White
    
    try {
        # 尝试设置速度和双工模式
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $correctDisplayName -DisplayValue $targetSpeedValue -ErrorAction Stop
        Write-Host "  ✓ 已将 '$correctDisplayName' 设置为 '$targetSpeedValue'" -ForegroundColor Green
        
        # 重启适配器以应用更改
        Write-Host "  ↻ 正在重启适配器..." -ForegroundColor Yellow
        Restart-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
        
        Write-Host "  ✓ 适配器已重启。建议等待几秒钟让网络重新连接。" -ForegroundColor Green
        
    } catch {
        Write-Host "  ✗ 处理适配器时出错: $_" -ForegroundColor Red
        # 可以选择记录错误或继续处理下一个适配器
    }
}

Write-Host "`n脚本执行完毕。" -ForegroundColor Cyan
