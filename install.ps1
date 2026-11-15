<#
.SYNOPSIS
  视频号下载开关 - 一键安装脚本
.DESCRIPTION
  自动下载 wx_video_download v261106、写入配置、生成开关脚本，并创建快捷方式。
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install.ps1 -UpstreamProxy http://127.0.0.1:7890
#>
param(
    [string]$InstallRoot = "D:\软件\视频号\tools",
    [string]$DownloadDir = "E:\视频号下载",
    [string]$UpstreamProxy = "",
    [switch]$NoShortcut
)

$ErrorActionPreference = "Stop"
$Version = "v261106"
$ExeUrl = "https://github.com/ltaoo/wx_channels_download/releases/download/$Version/wx_video_download_${Version}_windows_x86_64.zip"
$MirrorUrl = "https://ghfast.top/" + $ExeUrl
$ToolDir = Join-Path $InstallRoot "wxdl_full"
$ExePath = Join-Path $ToolDir "wx_video_download.exe"
$ProxyPort = 2023

function Stop-DownloaderIfRunning {
    $procs = Get-Process -Name "wx_video_download" -ErrorAction SilentlyContinue
    if ($procs) {
        Write-Host "检测到下载器正在运行，先停止并恢复代理..." -ForegroundColor Yellow
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Restore-SystemProxy
    }
}

function Restore-SystemProxy {
    $backup = Join-Path $env:TEMP "wxdl_proxy_backup.json"
    $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    if (Test-Path $backup) {
        $o = Get-Content $backup -Raw -Encoding UTF8 | ConvertFrom-Json
        Set-ItemProperty $key -Name ProxyEnable -Value ([int]$o.en)
        if ($null -ne $o.srv) {
            Set-ItemProperty $key -Name ProxyServer -Value ([string]$o.srv)
        }
        Remove-Item $backup -Force -ErrorAction SilentlyContinue
    } else {
        $i = Get-ItemProperty $key
        $srv = [string]$i.ProxyServer
        if (([int]$i.ProxyEnable -ne 0) -and ($srv -match "(^|[;=\s])127\.0\.0\.1:$ProxyPort($|[;\s])")) {
            Set-ItemProperty $key -Name ProxyEnable -Value 0
        }
    }
}

function Set-YamlScalar([string]$Text, [string]$Key, [string]$Value) {
    $pattern = "(?m)^(\s*" + [regex]::Escape($Key) + ":\s*)""[^""]*"""
    if ($Text -notmatch $pattern) {
        throw "配置中找不到键: $Key"
    }
    return [regex]::Replace($Text, $pattern, ('${1}"' + $Value + '"'), 1)
}

function Resolve-DownloadedExe([string]$SearchRoot, [string]$TargetExe) {
    if (Test-Path $TargetExe) { return $TargetExe }
    $found = Get-ChildItem -Path $SearchRoot -Filter "wx_video_download.exe" -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $found) { return $null }
    $destDir = Split-Path $TargetExe -Parent
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    if ($found.FullName -ne $TargetExe) {
        Get-ChildItem -Path $found.DirectoryName -Force | ForEach-Object {
            $dest = Join-Path $destDir $_.Name
            if ($_.FullName -ne $dest) {
                Copy-Item $_.FullName -Destination $dest -Recurse -Force
            }
        }
    }
    if (Test-Path $TargetExe) { return $TargetExe }
    return $null
}

Write-Host ""
Write-Host "=== 视频号下载开关 安装程序 ===" -ForegroundColor Cyan
Write-Host "安装目录: $InstallRoot"
Write-Host "下载目录: $DownloadDir"
if ($UpstreamProxy) { Write-Host "上游代理: $UpstreamProxy" }
Write-Host ""

Stop-DownloaderIfRunning

# ---------- 1. 下载并解压工具 ----------
if (Test-Path $ExePath) {
    Write-Host "[1/4] 工具已存在，跳过下载" -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $ToolDir | Out-Null
    $zip = Join-Path $InstallRoot "wxdl_$Version.zip"
    $ok = $false
    foreach ($u in @($MirrorUrl, $ExeUrl)) {
        try {
            Write-Host "[1/4] 下载: $u"
            Invoke-WebRequest -Uri $u -OutFile $zip -UseBasicParsing -TimeoutSec 120
            if ((Test-Path $zip) -and (Get-Item $zip).Length -gt 1000000) { $ok = $true; break }
        } catch {
            Write-Host "      下载源失败，换源重试" -ForegroundColor Yellow
        }
    }
    if (-not $ok) { throw "下载失败：请检查网络，或手动下载后放到 $InstallRoot" }

    $extractTmp = Join-Path $InstallRoot "wxdl_extract_$Version"
    if (Test-Path $extractTmp) { Remove-Item $extractTmp -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $extractTmp | Out-Null
    Expand-Archive $zip -DestinationPath $extractTmp -Force

    $resolved = Resolve-DownloadedExe -SearchRoot $extractTmp -TargetExe $ExePath
    if (-not $resolved) {
        throw "解压后未找到 wx_video_download.exe，请检查压缩包内容"
    }
    Remove-Item $extractTmp -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Write-Host "      解压完成，已校验 exe" -ForegroundColor Green
}

if (-not (Test-Path $ExePath)) {
    throw "安装校验失败：缺少 $ExePath"
}

# ---------- 2. 写入配置 ----------
$cfgPath = Join-Path $ToolDir "config.yaml"
$cfgTemplate = Join-Path $PSScriptRoot "config.yaml"
if (-not (Test-Path $cfgPath)) {
    if (-not (Test-Path $cfgTemplate)) { throw "缺少 config.yaml 模板" }
    Copy-Item $cfgTemplate $cfgPath
}
$cfg = Get-Content $cfgPath -Raw -Encoding UTF8
$dirEscaped = $DownloadDir -replace '\\', '\\'
$cfg = Set-YamlScalar -Text $cfg -Key "dir" -Value $dirEscaped
if ($UpstreamProxy) {
    $cfg = Set-YamlScalar -Text $cfg -Key "upstreamProxy" -Value $UpstreamProxy
}
[System.IO.File]::WriteAllText($cfgPath, $cfg, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "[2/4] 配置已写入" -ForegroundColor Green

# ---------- 3. 生成开关脚本 ----------
$batTemplate = Join-Path $PSScriptRoot "视频号下载开关.bat"
if (-not (Test-Path $batTemplate)) { throw "缺少 视频号下载开关.bat 模板" }
# 仓库内模板按 UTF-8 保存；写出给 cmd 用的 bat 使用系统 ANSI/GBK
$utf8 = New-Object System.Text.UTF8Encoding($false)
$gbkEnc = [System.Text.Encoding]::GetEncoding(936)
$bat = [System.IO.File]::ReadAllText($batTemplate, $utf8)
if ($bat -notmatch "__TOOL_DIR__") {
    # 兼容旧模板：按整段路径替换
    $bat = $bat.Replace('D:\软件\视频号\tools\wxdl_full', $ToolDir)
} else {
    $bat = $bat.Replace("__TOOL_DIR__", $ToolDir)
}
$batPath = Join-Path $InstallRoot "视频号下载开关.bat"
[System.IO.File]::WriteAllText($batPath, $bat, $gbkEnc)
Write-Host "[3/4] 开关脚本已生成: $batPath" -ForegroundColor Green

# ---------- 4. 快捷方式 ----------
if (-not $NoShortcut) {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $ws = New-Object -ComObject WScript.Shell
    $lnkPath = Join-Path $desktop "视频号下载开关.lnk"
    $s = $ws.CreateShortcut($lnkPath)
    $s.TargetPath = $batPath
    $s.WorkingDirectory = $InstallRoot
    $s.IconLocation = "%SystemRoot%\System32\shell32.dll,174"
    $s.Description = "双击开/关：开=微信视频号出现下载菜单，关=恢复网络"
    $s.Save()
    Write-Host "[4/4] 快捷方式已创建: $lnkPath" -ForegroundColor Green
} else {
    Write-Host "[4/4] 已跳过快捷方式" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "安装完成！双击「视频号下载开关」即可使用。" -ForegroundColor Cyan
Write-Host "下载的视频保存到: $DownloadDir"
Write-Host ""
if ($UpstreamProxy) {
    Write-Host "已配置上游代理：开关开启期间 Clash 等代理照常工作。" -ForegroundColor Green
} else {
    Write-Host "提示：如需开关开启时也不影响 Clash，重跑本脚本并加 -UpstreamProxy http://127.0.0.1:7890" -ForegroundColor Yellow
}
Write-Host ""
