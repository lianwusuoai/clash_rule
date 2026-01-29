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
powershell -NoProfile -Command "$files = Get-ChildItem -Path . -Filter *.yaml | Select-Object -ExpandProperty Name; foreach($f in $files){ $url='https://purge.jsdelivr.net/gh/%REPO%@%BRANCH%/' + $f; Write-Host ('  清除: ' + $f); try { $r = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing -TimeoutSec 10; Write-Host ('    成功: ' + $r.StatusCode) -ForegroundColor Green } catch { Write-Host ('    跳过/失败') -ForegroundColor Gray } }"

echo.
echo [2/3] 刷新 Clash 规则提供者...
powershell -NoProfile -Command "try { $resp = Invoke-RestMethod -Uri '%API%/providers/rules' -Method GET; $ps = if ($resp.providers) { $resp.providers } else { $resp }; foreach($n in $ps.PSObject.Properties.Name){ Write-Host ('  更新: ' + $n); Invoke-RestMethod -Uri ('%API%/providers/rules/' + $n) -Method PUT | Out-Null } echo '  所有规则已刷新。' } catch { Write-Host '  刷新失败' -ForegroundColor Red }"

echo.
echo [3/3] 重载配置 (Force Reload)...
powershell -NoProfile -Command "try { Invoke-RestMethod -Uri '%API%/configs?force=true' -Method PATCH -ContentType 'application/json' -Body '{}' | Out-Null; echo '  配置已重载。' } catch { Write-Host '  重载失败' -ForegroundColor Red }"

echo.
echo ========================================
echo   更新完成！
echo ========================================
pause
