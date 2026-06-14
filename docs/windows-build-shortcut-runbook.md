# Windows 构建与桌面快捷方式流程记录

记录时间：`2026-06-14`  
项目路径：`D:\xiehan\flutter\cliper`

这次确认跑通的是最小流程：

```text
fvm flutter build windows --release
-> build/windows/x64/runner/Release/cliper.exe
-> scripts/create_windows_shortcut.ps1
-> 桌面生成 CLIPER.lnk
```

不包含安装器，不包含 MSIX，不包含 Inno Setup。

## 1. 构建命令

按项目约定，统一使用 FVM：

```powershell
fvm flutter build windows --release
```

本次实际结果：

```text
√ Built build\windows\x64\runner\Release\cliper.exe
```

构建产物路径：

```text
build/windows/x64/runner/Release/
```

关键文件：

- `cliper.exe`
- `flutter_windows.dll`
- `*.dll`
- `data/`

不能只拿 `cliper.exe` 单独运行或分发。

## 2. 快捷方式脚本

脚本文件：

- [scripts/create_windows_shortcut.ps1](/D:/xiehan/flutter/cliper/scripts/create_windows_shortcut.ps1:1)

默认行为：

- 目标程序：`build/windows/x64/runner/Release/cliper.exe`
- 桌面快捷方式名：`CLIPER.lnk`
- 图标来源：`cliper.exe,0`

执行命令：

```powershell
& .\scripts\create_windows_shortcut.ps1
```

如果以后要指向别的 exe，也可以显式传参：

```powershell
& .\scripts\create_windows_shortcut.ps1 -TargetExe 'D:\path\to\cliper.exe' -ShortcutName 'CLIPER'
```

## 3. 本次验证结果

### 3.1 快捷方式创建成功

桌面正式快捷方式：

```text
C:\Users\chink\Desktop\CLIPER.lnk
```

本次校验到的属性：

- `TargetPath`: `D:\xiehan\flutter\cliper\build\windows\x64\runner\Release\cliper.exe`
- `WorkingDirectory`: `D:\xiehan\flutter\cliper\build\windows\x64\runner\Release`
- `IconLocation`: `D:\xiehan\flutter\cliper\build\windows\x64\runner\Release\cliper.exe,0`

### 3.2 应用启动成功

直接启动 `build/windows/x64/runner/Release/cliper.exe` 后，进程已正常起来。

本次观察到：

- 进程名：`cliper`
- 窗口标题：`CLIPER`

### 3.3 图标验证边界

能确认的事实：

- 快捷方式图标来源已经明确指向当前 `cliper.exe,0`
- 快捷方式目标路径已经明确指向当前 Release 目录

这次没有拿到一个足够稳定的“桌面截图中肉眼可见图标已刷新”的结果。更像是 Windows 桌面刷新、图标排列或 Shell 缓存问题，不是快捷方式创建失败。

所以这次的结论要分开看：

- 快捷方式文件创建：已成功
- 快捷方式目标路径：已正确
- 快捷方式图标来源：已正确
- 应用启动：已成功
- 桌面图标即时可见刷新：未作为硬成功条件确认

## 4. 这次踩过的坑

### 4.1 不要先上安装器

这次已经验证，单纯为了“稳定创建桌面快捷方式”，先上安装器会把问题扩大。

先把下面这条最小链路跑通更合适：

```text
Release 构建
-> 快捷方式脚本
-> 路径/图标/启动验证
```

### 4.2 PowerShell 脚本的 `param()` 要放在最前面

`param(...)` 前面不能先放普通语句，否则会报解析错误。

这次修正后脚本结构是：

```powershell
param(...)
$ErrorActionPreference = 'Stop'
...
```

### 4.3 参数默认值不要写复杂表达式

`param()` 里的默认值如果写成复杂表达式，在当前环境下容易踩解析问题。  
更稳的做法是先给空字符串，再在参数块后补默认路径。

## 5. 后续建议

如果后面只是继续沿用这条流程，按下面顺序就够了：

1. `fvm flutter build windows --release`
2. `& .\scripts\create_windows_shortcut.ps1`
3. 检查 `CLIPER.lnk` 的 `TargetPath / WorkingDirectory / IconLocation`
4. 启动 `cliper.exe`，确认进程和窗口标题正常

如果以后要做正式分发，再单独讨论安装器，不要和“先把快捷方式做对”混在一起。
