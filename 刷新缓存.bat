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

echo [0/3] 检查本地环境...
git status -s >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('git status -s') do (
        echo [警告] 本地有未提交的修改，CDN 刷新将不会包含这些内容。
        goto :env_check_done
    )
)
:env_check_done

for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $candidates=@('http://127.0.0.1:9090','http://127.0.0.1:7890','http://127.0.0.1:9097','http://127.0.0.1:9091','http://127.0.0.1:7897'); foreach($c in $candidates){ try{ Invoke-RestMethod -Uri ($c + '/version') -Method GET -TimeoutSec 2 | Out-Null; Write-Output $c; exit 0 }catch{} } exit 1"`) do set "API=%%A"
if not defined API (
  echo [错误] 未找到可用的 Clash 外部控制器端口。
  echo        1. 请确认 Clash 已启动并开启了外部控制 (External Controller)。
  echo        2. 如果你设置了 API 密钥 (Secret)，请手动修改本脚本添加 Headers。
  echo        3. 常见端口: 9090, 7890, 7897, 9097。
  echo.
  pause
  exit /b 1
)

echo 控制器: %API%

echo [1/3] 正在清除 jsDelivr CDN 缓存...
powershell -NoProfile -Command "$ErrorActionPreference='Continue'; $files = Get-ChildItem -Path . -Filter *.yaml | Select-Object -ExpandProperty Name; foreach($file in $files){ $url='https://purge.jsdelivr.net/gh/%REPO%@%BRANCH%/' + $file; Write-Host '  清除缓存:' $file; try{ Invoke-RestMethod -Uri $url -Method GET -TimeoutSec 10 | Out-Null } catch { Write-Host '    (失败)' -ForegroundColor Yellow } }"

echo.
echo [2/3] 正在刷新 Clash 规则提供者...
powershell -NoProfile -Command "$ErrorActionPreference='Continue'; try { $resp=Invoke-RestMethod -Uri '%API%/providers/rules' -Method GET -TimeoutSec 10; $ps = if ($resp.providers) { $resp.providers } else { $resp }; if ($ps) { $ok=0; $fail=0; foreach($n in $ps.PSObject.Properties.Name){ Write-Host '  更新:' $n; try{ Invoke-RestMethod -Uri ('%API%/providers/rules/' + $n) -Method PUT -TimeoutSec 30 | Out-Null; $ok++ }catch{ Write-Host '    (失败)' -ForegroundColor Yellow; $fail++ } } Write-Host ('  完成: 成功 ' + $ok + ' / 失败 ' + $fail) } else { Write-Host '  未找到规则提供者。' -ForegroundColor Gray } } catch { Write-Host '  无法获取规则列表。' -ForegroundColor Yellow }"

echo.
echo [3/3] 正在重载配置并二次刷新规则...
powershell -NoProfile -Command "$ErrorActionPreference='Continue'; try { Invoke-RestMethod -Uri '%API%/configs?force=true' -Method PATCH -ContentType 'application/json' -Body '{}' -TimeoutSec 30 | Out-Null; Start-Sleep -Milliseconds 800; $resp=Invoke-RestMethod -Uri '%API%/providers/rules' -Method GET -TimeoutSec 10; $ps = if ($resp.providers) { $resp.providers } else { $resp }; if ($ps) { foreach($n in $ps.PSObject.Properties.Name){ try{ Invoke-RestMethod -Uri ('%API%/providers/rules/' + $n) -Method PUT -TimeoutSec 30 | Out-Null }catch{} } Write-Host '成功！所有规则已刷新。' -ForegroundColor Green } } catch { Write-Host '  重载失败。' -ForegroundColor Yellow }"

echo.
echo ========================================
echo   完成！你的规则现在是最新的了。
echo ========================================
echo.
echo 按任意键退出...
pause >nul
