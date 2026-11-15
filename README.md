# 视频号下载开关

一个「按需开关」的微信视频号视频下载工具：双击启动，微信视频号页面出现「更多下载」菜单；用完再双击停止，网络恢复原样。

## 安装（新电脑 / 重装系统后）

1. 解压本包到任意位置
2. 右键 `install.ps1` → **使用 PowerShell 运行**
   - 如果被系统拦截，打开 PowerShell 窗口执行：
     ```
     powershell -ExecutionPolicy Bypass -File install.ps1
     ```
3. 等待下载（约 15MB），完成后桌面出现「视频号下载开关」
4. 删除本包即可，无需保留

### 可选参数

```
# 让开关开启期间 Clash 照常工作（推荐）
powershell -ExecutionPolicy Bypass -File install.ps1 -UpstreamProxy http://127.0.0.1:7890

# 自定义下载保存目录
powershell -ExecutionPolicy Bypass -File install.ps1 -DownloadDir "D:\视频"

# 不创建桌面快捷方式
powershell -ExecutionPolicy Bypass -File install.ps1 -NoShortcut
```

## 使用

| 操作 | 效果 |
|---|---|
| 双击「视频号下载开关」 | 启动下载器 → 微信视频号页面出现下载菜单 |
| 再双击一次 | 停止下载器 → 系统代理恢复为你的原设置（如 Clash 7890） |

- 下载的视频保存到 `E:\视频号下载`（安装时可用 `-DownloadDir` 修改）
- 如果微信视频号页面已经开着，启动开关后**刷新一下页面**，菜单才会出现
- 开关会先备份你当前的系统代理设置，停止时原样恢复，不会破坏 Clash 等代理软件
- 若下载器异常退出导致代理卡住，再双击一次「关闭」即可恢复；重装时安装脚本也会自动清理

## 原理与注意

- 通过本地代理（127.0.0.1:2022 / 2023）捕获微信客户端的视频号流量，并在页面注入下载按钮
- 开关开启期间，系统代理被临时改为 127.0.0.1:2023；如未配置 `-UpstreamProxy`，依赖代理软件的国外网站会暂时不可用，关闭即恢复
- 工具本体 [wx_channels_download](https://github.com/ltaoo/wx_channels_download) v261106，下载失败时会自动走镜像
- 安装时会校验解压后的 `wx_video_download.exe`；配置写入只改目标字段，避免误伤其他项

## 卸载

1. 双击开关确认处于停止状态
2. 删除安装目录（默认 `D:\软件\视频号\tools`）和桌面快捷方式
3. 如果系统代理异常，打开「设置 → 网络和 Internet → 代理」关闭手动代理即可

## 文件说明

| 文件 | 说明 |
|---|---|
| `install.ps1` | 安装脚本（下载工具、写配置、生成开关、建快捷方式） |
| `config.yaml` | 配置模板（安装时自动写入下载目录等） |
| `视频号下载开关.bat` | 开关脚本模板（安装时写入实际工具路径；也可相对 `wxdl_full` 回退查找） |
