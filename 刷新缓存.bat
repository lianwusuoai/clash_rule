@echo off
chcp 65001 >nul
echo ========================================
echo    Clash Meta - 刷新规则
echo    (包含 jsDelivr CDN 缓存清除)
echo ========================================
echo.

set API=http://127.0.0.1:7891
set REPO=lianwusuoai/clash_rule
set BRANCH=main

echo [1/3] 正在清除 jsDelivr CDN 缓存...
echo   这将确保你获取到 GitHub 上的最新规则！
powershell -Command "$files = @('AI.yaml', 'AUTO.yaml', 'China.yaml', 'GitHub.yaml', 'Telegram.yaml', 'TikTok.yaml', 'YouTube.yaml'); foreach ($file in $files) { $url = 'https://purge.jsdelivr.net/gh/%REPO%@%BRANCH%/' + $file; Write-Host '  清除缓存:' $file; try { Invoke-RestMethod -Uri $url -Method GET -TimeoutSec 10 | Out-Null } catch { Write-Host '    (跳过 - 可能已是最新)' -ForegroundColor Yellow } }"

echo.
echo [2/3] 正在刷新 Clash 规则提供者...
powershell -Command "$providers = (Invoke-RestMethod -Uri '%API%/providers/rules' -Method GET).providers; foreach ($name in $providers.PSObject.Properties.Name) { Write-Host '  更新:' $name; Invoke-RestMethod -Uri ('%API%/providers/rules/' + $name) -Method PUT | Out-Null }"

echo.
echo [3/3] 正在重载配置...
powershell -Command "Invoke-RestMethod -Uri '%API%/configs?force=true' -Method PATCH -ContentType 'application/json' -Body '{}' | Out-Null; Write-Host '成功！所有规则已更新。' -ForegroundColor Green"

echo.
echo ========================================
echo   完成！你的规则现在是最新的了。
echo ========================================
echo.
echo 按任意键退出...
pause >nul