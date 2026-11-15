@echo off
chcp 936 >nul
title 视频号下载开关
set "TOOL_DIR=__TOOL_DIR__"
if not exist "%TOOL_DIR%\wx_video_download.exe" set "TOOL_DIR=%~dp0wxdl_full"
if not exist "%TOOL_DIR%\wx_video_download.exe" (
  echo.
  echo  [错误] 找不到 wx_video_download.exe
  echo  请先运行 install.ps1，或确认工具目录存在。
  echo  当前查找: %TOOL_DIR%
  pause
  exit /b 1
)

tasklist /fi "imagename eq wx_video_download.exe" 2>nul | find /i "wx_video_download.exe" >nul
if %errorlevel%==0 goto :STOP

echo.
echo  正在启动下载器，请稍候...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; ^
   $p=Join-Path $env:TEMP 'wxdl_proxy_backup.json'; ^
   $k='HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'; ^
   $i=Get-ItemProperty $k; ^
   $en=[int]$i.ProxyEnable; ^
   $srv=[string]$i.ProxyServer; ^
   $ours=($en -ne 0) -and ($srv -match '(^|[;=\s])127\.0\.0\.1:2023($|[;\s])'); ^
   if ($ours) { ^
     if (-not (Test-Path $p)) { @{en=0;srv=''}|ConvertTo-Json|Set-Content $p -Encoding utf8 } ^
   } else { ^
     @{en=$en;srv=$srv}|ConvertTo-Json|Set-Content $p -Encoding utf8 ^
   }" >nul 2>&1
cd /d "%TOOL_DIR%"
start "" /min wx_video_download.exe
ping -n 3 127.0.0.1 >nul
echo  [已就绪] 去微信视频号视频页面，点「更多下载」菜单即可下载。
echo  如果微信页面已经开着，刷新一下页面菜单就会出现。
echo  本窗口 5 秒后自动关闭...
ping -n 6 127.0.0.1 >nul
exit /b 0

:STOP
taskkill /f /im wx_video_download.exe >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; ^
   $f=Join-Path $env:TEMP 'wxdl_proxy_backup.json'; ^
   $k='HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'; ^
   if (Test-Path $f) { ^
     $o=Get-Content $f -Raw|ConvertFrom-Json; ^
     Set-ItemProperty $k -Name ProxyEnable -Value ([int]$o.en); ^
     if ($null -ne $o.srv) { Set-ItemProperty $k -Name ProxyServer -Value ([string]$o.srv) }; ^
     Remove-Item $f -Force -ErrorAction SilentlyContinue ^
   } else { ^
     Set-ItemProperty $k -Name ProxyEnable -Value 0 ^
   }" >nul 2>&1
echo.
echo  [已停止] 下载器关闭，系统代理已恢复原状。
echo  本窗口 3 秒后自动关闭...
ping -n 4 127.0.0.1 >nul
exit /b 0
