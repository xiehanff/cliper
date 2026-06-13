# Cliper Flutter 项目 Agent 指南

## 环境约定

- 必须使用 **FVM** 管理 Flutter/Dart 版本，固定版本为 `3.44.2`（见 `.fvmrc`）。
- 所有 Flutter 命令统一使用 `fvm flutter xxx`。
- 所有 Dart 命令统一使用 `fvm dart xxx`。
- 禁止直接使用系统全局 `flutter` 或 `dart`。

常用命令示例：

```bash
fvm flutter pub get
fvm flutter run -d windows
fvm flutter run -d macos
fvm flutter analyze
fvm flutter test
fvm flutter build windows
fvm flutter build macos
fvm dart format lib test
```

## 项目背景

本项目是 Cliper 剪贴板管理应用的 Flutter 重构版，目标 1:1 复刻 `D:\xiehan\github\cliper` 的 Electron 版。

- 目标平台：**Windows / macOS** 桌面端。
- 产品形态：弹出式剪贴板面板，无边框、无标题栏按钮、不驻留任务栏、失焦隐藏、仅通过托盘/全局快捷键呼出。
- 品牌名：**CLIPER**（不使用“霞霞剪切板”）。

## 架构分层

```text
lib/
  app/              # 启动与依赖装配
  core/             # 常量、工具、主题、国际化
  domain/           # 实体、枚举、接口、业务规则
  infrastructure/   # 插件封装、平台通道、持久化
  application/      # 状态控制器
  presentation/     # 页面、组件
```

依赖方向：

```text
presentation -> application -> domain
infrastructure -> domain
application -> infrastructure（仅通过接口注入后的实现装配）
```

## 编码规范

- 优先使用小而明确的类和函数，禁止胖控制器/万能 Manager。
- 业务逻辑不得写在 Widget 的 `build()` 或回调中。
- 平台插件调用不得散落在页面组件里。
- UI 层不直接读写 JSON、本地文件、平台通道、托盘、快捷键。
- 平台差异收敛在 `infrastructure/desktop/platform/` 内，不要散落在 UI 层。
- 不要为 text/image/file 三种条目复制三套几乎一样的流程代码。
- 主题和语言切换逻辑不要重复写在多个 Widget 中。
- 注释只解释难以一眼看懂的约束或平台差异，不写废话注释。
- 不得删除用户已注释的代码。

## 状态管理

- 使用 `ChangeNotifier` + `Provider`。
- 禁止引入 Bloc / Riverpod 等重型框架。

## 推荐插件

| 能力 | 插件 |
|---|---|
| 窗口管理 | window_manager |
| 托盘 | tray_manager |
| 全局快捷键 | hotkey_manager |
| 开机自启动 | launch_at_startup |
| 剪贴板读写 | super_clipboard |
| 剪贴板变更监听 | clipboard_watcher |
| 屏幕信息/定位辅助 | screen_retriever |
| 本地存储路径 | path_provider |
| 依赖注入/状态 | provider |

## 测试与质量

- 核心业务规则必须脱离 Widget 独立测试。
- 平台服务通过接口注入，便于 fake/mock。
- 每次改动 Dart 文件后，必须对相关文件执行 `fvm dart analyze <file>`。
- 提交前必须执行 `fvm flutter analyze` 并通过。
- Widget 测试中不应真的触发系统全局快捷键、创建托盘或读写真实配置目录。

## 文档

- 详细重构规格见 `docs/flutter-rebuild-spec.md`。
- 分阶段实施清单见 `docs/implementation-checklist.md`。
- 源项目真值源见 `D:\xiehan\github\cliper`。
