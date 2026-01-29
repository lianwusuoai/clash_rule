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

echo [1/2] 刷新 Clash 规则提供者...
powershell -NoProfile -Command "try { $resp = Invoke-RestMethod -Uri '%API%/providers/rules' -Method GET; $ps = if ($resp.providers) { $resp.providers } else { $resp }; foreach($n in $ps.PSObject.Properties.Name){ Write-Host ('  正在更新: ' + $n) -NoNewline; try { Invoke-RestMethod -Uri ('%API%/providers/rules/' + $n) -Method PUT | Out-Null; Write-Host ' [成功]' -ForegroundColor Green } catch { Write-Host ' [失败]' -ForegroundColor Red; Write-Host ('    错误原因: ' + $_.Exception.Message) -ForegroundColor Gray } } } catch { Write-Host '无法获取规则列表' -ForegroundColor Red }"

echo.
echo [2/2] 重载配置 (Force Reload)...
powershell -NoProfile -Command "try { Invoke-RestMethod -Uri '%API%/configs?force=true' -Method PATCH -ContentType 'application/json' -Body '{}' | Out-Null; echo '  配置已重载。' } catch { Write-Host '  重载失败' -ForegroundColor Red }"

echo.
echo ========================================
echo   更新完成！
echo ========================================
pause
