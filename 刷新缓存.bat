@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo    Clash Meta - 自动刷新工具
echo ========================================
echo.

set "API=http://127.0.0.1:7890"
set "REPO=lianwusuoai/clash_rule"
set "BRANCH=main"

echo [1/3] 清除 CDN 缓存 (jsDelivr)...
:: 自动扫描目录下所有 yaml 文件并清除缓存
powershell -NoProfile -Command "$files = Get-ChildItem -Path . -Filter *.yaml | Select-Object -ExpandProperty Name; foreach($f in $files){ Write-Host ('  清除: ' + $f); try { Invoke-RestMethod -Uri ('https://purge.jsdelivr.net/gh/%REPO%@%BRANCH%/' + $f) -Method GET -TimeoutSec 5 | Out-Null } catch {} }"

echo.
echo [2/3] 刷新 Clash 规则提供者...
:: 自动获取所有规则提供者并逐一刷新
powershell -NoProfile -Command "try { $resp = Invoke-RestMethod -Uri '%API%/providers/rules' -Method GET; $ps = if ($resp.providers) { $resp.providers } else { $resp }; foreach($n in $ps.PSObject.Properties.Name){ Write-Host ('  更新: ' + $n); Invoke-RestMethod -Uri ('%API%/providers/rules/' + $n) -Method PUT | Out-Null } echo '  所有规则已刷新。' } catch { Write-Host '  刷新失败' -ForegroundColor Red }"

echo.
echo [3/3] 重载配置 (Force Reload)...
:: 强制触发配置重载
powershell -NoProfile -Command "try { Invoke-RestMethod -Uri '%API%/configs?force=true' -Method PATCH -ContentType 'application/json' -Body '{}' | Out-Null; echo '  配置已重载。' } catch { Write-Host '  重载失败' -ForegroundColor Red }"

echo.
echo ========================================
echo   更新完成！
echo ========================================
pause
