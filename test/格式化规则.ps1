# 测试内容：自动为 Clash 规则集添加 "- " 前缀
# 功能：读取 AUTO.yaml，为没有前缀的规则行自动添加 "- " 前缀

$filePath = "AUTO.yaml"

# 读取文件所有行
$lines = Get-Content $filePath -Encoding UTF8

# 处理后的行
$newLines = @()

foreach ($line in $lines) {
    # 如果是 payload: 行，直接保留
    if ($line -match "^payload:") {
        $newLines += $line
    }
    # 如果是规则行但没有前缀，添加 "- "
    elseif ($line -match "^\s*(DOMAIN|IP-CIDR|PROCESS-NAME)" -and $line -notmatch "^\s*-") {
        # 移除行首空格，添加 "- " 前缀
        $trimmedLine = $line.Trim()
        $newLines += "- $trimmedLine"
    }
    # 其他情况保持原样
    else {
        $newLines += $line
    }
}

# 写回文件
$newLines | Set-Content $filePath -Encoding UTF8

Write-Host "格式化完成！已为所有规则添加 '- ' 前缀" -ForegroundColor Green