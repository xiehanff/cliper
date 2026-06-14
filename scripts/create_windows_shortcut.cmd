@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%create_windows_shortcut.ps1"

if not exist "%PS_SCRIPT%" (
  echo 找不到脚本: %PS_SCRIPT%
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
if errorlevel 1 (
  echo 创建桌面快捷方式失败
  pause
  exit /b 1
)

echo 已创建桌面快捷方式: CLIPER
pause
