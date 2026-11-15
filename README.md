# 视频号下载开关

一个「按需开关」的微信视频号视频下载工具：双击启动，微信视频号页面出现「更多下载」菜单；用完再双击停止，网络恢复原样。

## 安装

```
powershell -ExecutionPolicy Bypass -File install.ps1 -UpstreamProxy http://127.0.0.1:7897
```

## 使用

| 操作 | 效果 |
|---|---|
| 双击「视频号下载开关」 | 开启下载菜单 |
| 再双击一次 | 关闭并恢复代理 |

详见仓库内 `install.ps1`、`config.yaml`、`视频号下载开关.bat`。
