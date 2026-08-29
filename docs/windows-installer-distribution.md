# Windows 安装包生成与分发

项目路径：`D:\xiehan\flutter\cliper`

这份文档只记录两件事：

- 如何重新生成 Windows 安装包
- 如何把安装包分发给用户

## 1. 前置条件

- 使用项目固定 Flutter 版本：`fvm`
- 本机已安装 Inno Setup 6

## 2. 重新生成安装包

推荐直接走聚合命令：

```powershell
.\make.cmd package-windows
```

这条命令会先构建最新的 Release，再继续生成 setup 安装包。

如果你只想手动拆开执行，顺序如下。

如果刚改过代码，先重新生成 Release：

```powershell
fvm flutter build windows --release
```

如果 `build/windows/x64/runner/Release/` 已经是最新的，可以直接跳过上面这步。

然后执行安装包脚本：

```powershell
& .\windows\installer\build_installer.ps1 -SkipBuild
```

如果希望脚本自动先构建再打包，也可以直接执行：

```powershell
& .\windows\installer\build_installer.ps1
```

或者走 PowerShell 入口：

```powershell
powershell -File .\make.ps1 package-windows
```

如果你的环境装了 GNU make，也可以直接执行：

```powershell
make package-windows
```

## 2.1 用 GitHub Actions 自动打包

仓库已接入打包流水线 `.github/workflows/build-desktop-packages.yml`：

- 每次 push 或手动触发（workflow_dispatch）时自动执行
- Windows job：`flutter build windows --release` 后调用 `windows/installer/build_installer.ps1 -SkipBuild` 生成安装包
- 产物上传为 artifact（名称 `cliper-windows-<run_number>`，保留 30 天），在仓库 Actions 页面下载
- macOS job 同理生成 `cliper-<版本>.dmg`（artifact 名称 `cliper-macos-<run_number>`）
- **master 分支推送**：构建完成后自动创建/更新 GitHub Release `v<版本>`（版本号取自 `pubspec.yaml`），安装包作为 Release 附件发布，用户直接从 Releases 页面下载；其他分支只上传 artifact，不产生 Release

本地已构建 Release 且只想重新打包时，CI 与本地使用的是同一套脚本，产物一致。

## 3. 安装包输出位置

生成后的安装包在：

```text
windows/installer/dist/CLIPER_Setup_1.1.4.exe
```

如果后面版本号变化，文件名会跟随 `pubspec.yaml` 的版本号更新。

## 4. 安装包会帮用户做什么

用户双击安装包后，安装器会自动：

- 安装程序到 `C:\Program Files\CLIPER`
- 创建桌面快捷方式 `CLIPER`
- 创建开始菜单入口 `CLIPER`

用户不需要自己运行 PowerShell 脚本。

## 5. 分发给用户时怎么说

直接把这个文件发给用户：

```text
CLIPER_Setup_1.1.4.exe
```

附一句最小说明就够了：

```text
双击安装包完成安装。安装后桌面会出现 CLIPER 快捷方式，开始菜单里也可以找到 CLIPER。
```

## 6. 打包后建议自查

每次发版前至少检查这几项：

- 安装包能正常生成
- 安装后 `C:\Program Files\CLIPER\cliper.exe` 存在
- 桌面快捷方式存在
- 快捷方式能启动应用
- 开始菜单能搜到 `CLIPER`
