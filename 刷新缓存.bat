@echo off
chcp 65001 >nul
echo ========================================
echo    Clash Meta - Refresh Rules
echo ========================================
echo.

set API=http://127.0.0.1:7891

echo [1/2] Refreshing rule providers...
powershell -Command "$providers = (Invoke-RestMethod -Uri '%API%/providers/rules' -Method GET).providers; foreach ($name in $providers.PSObject.Properties.Name) { Write-Host '  Updating:' $name; Invoke-RestMethod -Uri ('%API%/providers/rules/' + $name) -Method PUT | Out-Null }"

echo [2/2] Reloading configuration...
powershell -Command "Invoke-RestMethod -Uri '%API%/configs?force=true' -Method PATCH -ContentType 'application/json' -Body '{}' | Out-Null; Write-Host 'SUCCESS! All rules updated.' -ForegroundColor Green"

echo.
echo Press any key to exit...
pause >nul