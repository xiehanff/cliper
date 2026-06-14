# CLIPER

Flutter 重构版桌面剪贴板管理应用。

## 开发环境

- Flutter / Dart 必须通过 FVM 使用固定版本
- Flutter 命令统一使用 `fvm flutter xxx`
- Dart 命令统一使用 `fvm dart xxx`

## 常用命令

```powershell
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm flutter run -d windows
fvm flutter build windows --release
```

## Windows 构建

- Release 构建：`fvm flutter build windows --release`
- 安装包构建：`.\make.cmd package-windows`

相关文档：

- [Windows 构建与快捷方式记录](/D:/xiehan/flutter/cliper/docs/windows-build-shortcut-runbook.md)
- [Windows 安装包生成与分发](/D:/xiehan/flutter/cliper/docs/windows-installer-distribution.md)
