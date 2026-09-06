# CLIPER Linux Wayland 适配记录

> 分支：`linux/wayland`
> 环境：`Ubuntu 26.04 + GNOME + Wayland`
> Flutter：`3.44.2 (FVM)`

## 1. 背景

当前仓库主规格原本面向 `Windows / macOS`，窗口模型是“托盘 + 全局快捷键呼出”的弹出式面板。

在 Linux Wayland 下，这套策略存在两个直接问题：

1. 初始隐藏且跳过任务栏时，应用容易表现为“进程已启动但没有可见入口”。
2. 托盘与全局快捷键在 GNOME / Wayland 上兼容性不稳定，影响可用性。

因此本分支改为维护一套 Linux 专用策略，不影响 Windows/macOS 现有逻辑与 UI。

## 2. Linux 平台策略

### 2.1 窗口行为

Linux 使用 `LinuxViewportService`，与 Windows/macOS 分离。

行为调整如下：

1. 启动后直接显示窗口，不再初始隐藏。
2. 不再使用弹出式面板策略。
3. 失去焦点后不自动隐藏。
4. 不跳过任务栏 / Dock。
5. 不强制置顶。
6. 双击条目回写后不自动隐藏窗口。
7. 使用普通标题栏按钮，便于 Linux 桌面环境接管窗口。

### 2.2 托盘与快捷键

Linux 下：

1. 不初始化 `TrayManagerService`。
2. 不注册全局快捷键。
3. 不显示快捷键录制 UI。

保留 Windows/macOS 原行为：

1. 托盘入口仍正常工作。
2. 全局快捷键仍正常工作。
3. 弹出式面板交互不变。

## 3. Linux 图标与启动器

为兼容 GNOME Dock / Wayland，对 Linux 原生 runner 做了额外处理：

1. `APPLICATION_ID` 固定为 `com.cliper.app`。
2. 安装版 `.deb` 内只保留一个系统启动器：`com.cliper.app.desktop`。
3. 系统图标名统一为 `com.cliper.app`。
4. `StartupWMClass` / `X-GNOME-WMClass` 统一为 `com.cliper.app`。
5. 开发态运行时会在用户目录写入本地 desktop/icon 条目，帮助 Dock 识别。
6. 安装态（`/opt/cliper/`）不再重复写用户目录条目，避免重复 CLIPER 启动器。

## 4. 依赖调整

`tray_manager` 在 Linux 下会强制编译 `ayatana-appindicator` 相关原生依赖，即使 Dart 层不调用也会导致构建失败。

当前处理方式：

1. 将 `tray_manager` vendored 到 `third_party/tray_manager`。
2. 根 `pubspec.yaml` 改为 path 依赖。
3. 删除该插件的 Linux 平台声明。

结果：

1. Linux 不再编译 `tray_manager`。
2. Windows/macOS 仍保留原托盘插件实现。

## 5. Linux 打包

新增脚本：`scripts/build_linux_deb.sh`

功能：

1. 执行 `fvm flutter build linux --release`
2. 生成 Debian 包目录结构
3. 将应用安装到 `/opt/cliper`
4. 生成 `/usr/bin/cliper` 命令入口
5. 安装 `com.cliper.app.desktop`
6. 安装 `com.cliper.app.png`
7. 调用 `dpkg-deb` 生成 `.deb`

当前产物命名：

`cliper_<version>-<build>_amd64.deb`

例如：

`cliper_1.1.1-3_amd64.deb`

## 6. 已验证项

在当前 Linux 环境已完成：

1. `fvm flutter analyze`
2. `fvm flutter build linux --debug`
3. `fvm flutter build linux --release`
4. `.deb` 打包成功
5. `.deb` 安装后应用菜单图标正常
6. `.deb` 安装后 Dock 图标正常

## 7. 注意事项

1. 不要把本分支的 Linux 行为回灌到 Windows/macOS 主线分支。
2. Linux 下当前不支持通过全局快捷键呼出窗口，这是刻意策略变更，不是 bug。
3. 若后续需要恢复 Linux 全局快捷键，应单独评估 GNOME / Wayland 可用性，而不是直接复用 Windows/macOS 策略。

## 8. 分支独立 CI 与发版规则

本分支拥有独立于 master 的 CI：`.github/workflows/build-linux-packages.yml`。

### 8.1 与 master workflow 的隔离机制

1. master 的 `build-desktop-packages.yml` 负责 Windows/macOS，触发 tag 前缀为 `v*`。
2. 本分支的 `build-linux-packages.yml` 负责 Linux（deb + rpm），触发 tag 前缀为 `linux-v*`（如 `linux-v1.1.6`）。
3. GitHub Actions 以 tag 所指向提交内的 workflow 文件为准：
   - `v*` tag 打在 master 提交上 → 只有 master 的 workflow 存在，不会构建 Linux 包。
   - `linux-v*` tag 打在本分支提交上 → 只有本分支的 workflow 匹配前缀，master 的 `v*` 规则不会命中。
4. 因此**严禁在本分支上打 `v*` 前缀的 tag**：本分支提交里同时存在 master 继承的 workflow 文件，会意外触发 Windows/macOS 构建与发版。

### 8.2 workflow_dispatch 不可用（GitHub 硬限制）

分支独有的 workflow（未出现在仓库默认分支 master 上）无法通过 `workflow_dispatch` 触发：

- `gh workflow run build-linux-packages.yml --ref linux/wayland` 会返回 404；
- 直接调用 dispatch API 同样 404；
- 这是 GitHub 的平台限制，不是配置问题。

结论：本分支的 CI 只能通过 tag 推送触发，UI/CLI 手动触发入口对本分支无效。

### 8.3 发版流程

```bash
git tag linux-v<版本号>          # 版本号取 pubspec.yaml 的 version 主版本，如 linux-v1.1.6
git push origin linux-v<版本号>
```

CI 自动完成：

1. ubuntu-latest 构建 `flutter build linux --release`；
2. `scripts/build_linux_deb.sh --skip-build` 与 `scripts/build_linux_rpm.sh --skip-build` 打包；
3. 产物上传 artifact（`cliper-linux-<run_number>`）；
4. 创建 GitHub Release（标题 `CLIPER Linux <版本号>`），从 `CHANGELOG.md` 的 `## [<版本号>]` 小节提取说明，资产为 `.deb` 与 `.rpm`。

### 8.4 已验证项

1. `linux-v0.0.0-ci` 测试 tag 全链路通过（构建 3m25s + 发版 8s）。
2. Release 资产：`cliper-1.1.6-1.x86_64.rpm` 与 `cliper_1.1.6+1_amd64.deb`。
3. deb 打包脚本在 Ubuntu 环境验证通过（本机 Fedora 仅能验证 rpm）。
4. 测试 tag 与 Release 已删除，不影响正式发版。
