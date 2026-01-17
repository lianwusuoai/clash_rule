@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"
echo ========================================
echo    Clash Meta - 刷新规则
echo    (包含 jsDelivr CDN 缓存清除)
echo ========================================
echo.

set "API="
set "REPO=lianwusuoai/clash_rule"
set "BRANCH=main"

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $candidates=@('http://127.0.0.1:9090','http://127.0.0.1:7890','http://127.0.0.1:9097','http://127.0.0.1:9091'); foreach($c in $candidates){ try{ Invoke-RestMethod -Uri ($c + '/version') -Method GET -TimeoutSec 2 | Out-Null; Write-Output $c; exit 0 }catch{} } exit 1"`) do set "API=%%A"
if not defined API (
  echo [错误] 未找到可用的 Clash 外部控制器端口。
  echo        请确认 Clash 已启动，且 external-controller 可访问。
  echo.
  echo 按任意键退出...
  pause >nul
  exit /b 1
)

echo 控制器: %API%

echo [1/3] 正在清除 jsDelivr CDN 缓存...
echo   这将确保你获取到 GitHub 上的最新规则！
powershell -NoProfile -Command "$ErrorActionPreference='Continue'; $files=@('AI.yaml','AUTO.yaml','China.yaml','GitHub.yaml','Telegram.yaml','TikTok.yaml','YouTube.yaml'); foreach($file in $files){ $url='https://purge.jsdelivr.net/gh/%REPO%@%BRANCH%/' + $file; Write-Host '  清除缓存:' $file; $ok=$false; for($i=1;$i -le 3 -and -not $ok;$i++){ try{ Invoke-RestMethod -Uri $url -Method GET -TimeoutSec 10 | Out-Null; $ok=$true } catch { if($i -lt 3){ Start-Sleep -Milliseconds 300 } } } if(-not $ok){ Write-Host '    (失败 - 将继续后续刷新)' -ForegroundColor Yellow } }"

echo.
echo [2/3] 正在刷新 Clash 规则提供者...
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $providersResp=Invoke-RestMethod -Uri '%API%/providers/rules' -Method GET -TimeoutSec 10; $providers=$providersResp.providers; $ok=0; $fail=0; foreach($name in $providers.PSObject.Properties.Name){ Write-Host '  更新:' $name; try{ Invoke-RestMethod -Uri ('%API%/providers/rules/' + $name) -Method PUT -TimeoutSec 30 | Out-Null; $ok++ }catch{ Write-Host '    (失败)' -ForegroundColor Yellow; $fail++ } } Write-Host ('  完成: 成功 ' + $ok + ' / 失败 ' + $fail)"

echo.
echo [3/3] 正在重载配置并二次刷新规则...
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; Invoke-RestMethod -Uri '%API%/configs?force=true' -Method PATCH -ContentType 'application/json' -Body '{}' -TimeoutSec 30 | Out-Null; Start-Sleep -Milliseconds 800; $providersResp=Invoke-RestMethod -Uri '%API%/providers/rules' -Method GET -TimeoutSec 10; $providers=$providersResp.providers; foreach($name in $providers.PSObject.Properties.Name){ Write-Host '  二次更新:' $name; try{ Invoke-RestMethod -Uri ('%API%/providers/rules/' + $name) -Method PUT -TimeoutSec 30 | Out-Null }catch{ Write-Host '    (失败)' -ForegroundColor Yellow } } Write-Host '成功！所有规则已更新。' -ForegroundColor Green"

echo.
echo ========================================
echo   完成！你的规则现在是最新的了。
echo ========================================
echo.
echo 按任意键退出...
pause >nul
