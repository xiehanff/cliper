# Cliper Flutter 重构项目状态文档

> 文档生成时间：2026-07-24
> 项目路径：`D:\xiehan\flutter\cliper`  
> 源项目真值源：`D:\xiehan\github\cliper`  
> Flutter 版本：`3.44.2`（FVM 管理）

---

## 1. 已完成的工作

### 1.1 工程骨架与基础（A2-A4）

- [x] 删除默认 Counter demo，重写 `lib/main.dart` 为最小启动入口。R
- [x] 建立 `app / core / domain / infrastructure / application / presentation` 分层目录。
- [x] 创建 `lib/app/bootstrap.dart` 依赖装配入口。
- [x] `pubspec.yaml` 已声明全部桌面依赖与 `assets/icon.png`。
- [x] 已执行 `fvm flutter pub get`。
- [x] 已创建项目级 `AGENTS.md`，明确 FVM 使用规范。

### 1.2 数据层与业务规则（B1-B6）

- [x] 领域实体：`ClipboardItem`、`ClipboardGroup`、`AppSettings`、`ClipboardStore`、`ClipboardItemType`。
- [x] `StoreSerializer`：支持旧版数组格式、新版完整对象格式、JSON 损坏兜底、默认值合并。
- [x] `StoreRepository`：基于 `path_provider` 的 `clipboard-store.json` 读写。
- [x] `ClipboardHistoryService`：去重、顶部插入、50 条上限、激活置顶。
- [x] `GroupService`：创建/删除/改色/重命名、拖拽复制与迁移规则。
- [x] `AppController`：`ChangeNotifier` 状态控制器，对外提供 UI 状态与动作，不直接依赖平台插件。

### 1.3 UI 复刻（C1-C7）

- [x] 主题系统：dark/light token，默认 dark。
- [x] 国际化系统：zh/en，文案与源项目 `locales.js` 一致。
- [x] 主页面布局：左侧 120px 侧边栏 + 右侧主内容区 + 可拖动 header。
- [x] 侧边栏：实时 tab、分组 tab、新建分组、颜色选择器、hover 删除按钮、拖拽接收。
- [x] 列表组件：文本/图片/文件三种条目渲染、hover 删除按钮、scroll-to-top。
- [x] 设置浮层：开机自启动开关、状态说明、关闭按钮、外部点击关闭。
- [x] 快捷键录制 UI：键盘图标、录制态高亮、「等待按键」文案、捕获后保存。

### 1.4 桌面系统能力（D1-D10）

- [x] `WindowManagerService`：无边框、置顶、跳过任务栏、初始隐藏、尺寸 660x720、可调整大小。
- [x] 窗口定位：优先当前活跃屏幕，回退主屏幕，工作区居中，边缘防溢出。
- [x] 焦点状态机：`hadFocusSinceLastShow`，只有真正获得焦点后才因 blur 隐藏。
- [x] `TrayManagerService`：托盘图标、点击显隐、退出菜单。
- [x] `HotkeyManagerService`：注册/注销、格式归一化、默认 `CommandOrControl+\`。
- [x] `ClipboardMonitorManager`：`file → text → image` 优先级监听。
- [x] `ClipboardWriterImpl`：文本/图片写回，文件条目回写为原生文件 URI 剪贴板对象。
- [x] Windows 文件剪贴板增强：新增 C++ MethodChannel 读取 `CF_HDROP` / `FileNameW`。
- [x] `LaunchAtStartupServiceImpl`：Windows/macOS 自启动读写，开发环境降级。
- [x] macOS 后台模式：`LSUIElement` 隐藏 Dock、关闭窗口不退出。

### 1.5 测试与质量（F1-F4）

- [x] 单元/Widget 测试：50 passed，2 skipped（Windows 条件测试）。
- [x] `fvm flutter analyze` 通过：无错误/警告/信息。
- [x] `fvm dart format lib test` 已执行。
- [x] Windows debug/release 构建均通过。
- [x] macOS Release 构建通过，已生成 `build/macos/CLIPER_1.1.3.dmg`。
- [x] Windows 应用可启动并保持运行。

---

## 2. 未完成 / 待验证的工作

### 2.1 macOS 实际运行未验证

| 项目 | 状态 | 说明 |
|---|---|---|
| macOS 编译 | 已验证 | `fvm flutter build macos --release` 成功，已生成 `build/macos/CLIPER_1.1.3.dmg` |
| macOS 托盘 | 待验证 | 配置已就绪，未真实运行 |
| macOS 快捷键 | 待验证 | 配置已就绪，未真实运行 |
| macOS Dock 隐藏 | 待验证 | `Info.plist` 已加 `LSUIElement`，未真实运行 |
| macOS 关闭窗口不退出 | 待验证 | `AppDelegate.swift` 已修改，未真实运行 |
| macOS 失焦隐藏 | 待验证 | 代码已实现，未真实运行 |

建议在 macOS 设备上执行：

```bash
cd D:\xiehan\flutter\cliper
fvm flutter build macos
fvm flutter run -d macos
```

### 2.2 Windows 手工 GUI 交互未完整走查

代码层已按规格实现，但因运行环境限制，以下操作未进行完整屏幕点击/按键手工验证：

- 托盘图标点击显隐窗口
- 全局快捷键显隐窗口
- 复制文件后通过平台通道正确入库
- 双击条目写回后窗口隐藏
- 拖拽条目到分组/分组之间/拖回实时历史
- 多显示器下窗口位置稳定性

### 2.3 文件条目系统对象回写

- 当前已实现文件条目原生回写，采用文件 URI 剪贴板对象写回系统。
- 仍需在 macOS 设备上手工验证 Finder 的真实粘贴行为。

---

## 3. 已知问题

### 3.1 托盘图标为占位图

- 当前使用 `assets/icon.png` 占位图。
- 功能正常，但视觉不是最终品牌图标。
- 替换方式：直接覆盖 `assets/icon.png` 后重新构建。

### 3.2 依赖版本较旧

- `fvm flutter pub get` 提示 28 个包有新版本可用。
- 当前版本已能稳定编译运行，升级可能引入桌面插件 API 变化，需重新验证。

### 3.3 持久化保存为异步 fire-and-forget

- `AppController` 中每次状态变更后调用 `_persist()` 异步保存，不阻塞 UI。
- 极端情况下（如应用崩溃瞬间），可能丢失最近一条写入。
- 当前符合规格，对剪贴板工具场景可接受。

### 3.4 图片条目使用 PNG base64

- 剪贴板图片统一转码为 `data:image/png;base64,...` 存储。
- 与 Electron 版行为一致，但大图片会占用较多 JSON 存储空间。

### 3.5 快捷键录制平台差异

- Windows 下录制使用 `Ctrl/Alt/Shift/Win + Key`。
- macOS 下应使用 `Cmd/Option/Shift/Control + Key`。
- 代码中已通过 `ShortcutFormatter` 做部分归一化，但真实 macOS 键盘事件映射未实测。

### 3.6 窗口拖动区域可能受 header 控件影响

- Header 区域整体支持拖动，但按钮区域已设置 `WindowCaption` / `no-drag` 等价处理。
- 真实交互中需确认右侧工具区是否仍能正确响应点击而不触发拖动。

---

## 4. 建议的下一步工作

### 4.1 立即执行（高优先级）

1. 在 macOS 设备上编译并运行，验证以下主流程：
   - 文本/图片复制入库
   - 快捷键 `Cmd+\` 呼出/隐藏
   - 托盘点击显隐
   - 点击外部区域隐藏
   - Dock 隐藏
   - 关闭窗口后应用不退出
   - 开机自启动开关

2. 在 Windows 设备上进行完整 GUI 走查：
   - 文本/图片/文件复制入库
   - 双击条目回填并隐藏
   - 托盘/快捷键显隐
   - 失焦隐藏
   - 分组拖拽归档
   - 多显示器位置稳定性

3. 替换 `assets/icon.png` 为最终品牌图标。

### 4.2 可选优化（中低优先级）

1. 升级桌面插件到最新版本，重新验证兼容性。
2. 增加崩溃恢复/关键操作同步保存机制。
3. 补充更多边界测试（如多显示器定位、快捷键冲突、大图片序列化）。

---

## 5. 验证记录汇总

| 检查项 | 命令/操作 | 结果 |
|---|---|---|
| 依赖安装 | `fvm flutter pub get` | ✅ 通过 |
| 静态分析 | `fvm flutter analyze` | ✅ `No issues found!` |
| 代码格式化 | `fvm dart format lib test` | ✅ 已格式化 |
| 单元测试 | `fvm flutter test` | ✅ 50 passed，2 skipped |
| Windows Debug 构建 | `fvm flutter build windows --debug` | ✅ 成功 |
| Windows Release 构建 | `fvm flutter build windows --release` | ✅ 成功 |
| Windows 启动验证 | 运行 `build\windows\x64\runner\Debug\cliper.exe` | ✅ 5 秒内未异常退出 |
| macOS Release 构建 | `fvm flutter build macos --release` | ✅ 成功 |
| macOS DMG 打包 | `hdiutil create -volname CLIPER -srcfolder ...` | ✅ 成功 |
| macOS 运行验证 | `fvm flutter run -d macos` | ❌ 未执行（环境限制） |

---

## 6. 文件变更摘要

### 新增核心目录

- `lib/app/`
- `lib/core/`
- `lib/domain/`
- `lib/infrastructure/`
- `lib/application/`
- `lib/presentation/`
- `test/application/`
- `test/domain/`
- `test/infrastructure/`
- `test/presentation/`
- `assets/`

### 新增/修改的关键文件

- `lib/main.dart`：最小启动入口。
- `lib/app/bootstrap.dart`：依赖装配。
- `lib/app/app.dart`：根应用。
- `lib/application/controllers/app_controller.dart`：总状态控制器。
- `lib/infrastructure/desktop/window/window_manager_service.dart`：窗口管理。
- `lib/infrastructure/desktop/tray/tray_manager_service.dart`：托盘。
- `lib/infrastructure/desktop/hotkey/hotkey_manager_service.dart`：全局快捷键。
- `lib/infrastructure/desktop/clipboard/clipboard_monitor_manager.dart`：剪贴板监听。
- `lib/infrastructure/desktop/clipboard/clipboard_writer_impl.dart`：剪贴板写回，文件条目原生写回。
- `lib/infrastructure/desktop/launch/launch_at_startup_service_impl.dart`：自启动。
- `windows/runner/clipboard_channel.cpp/.h`：Windows 文件剪贴板平台通道。
- `macos/Runner/Info.plist`：macOS 后台模式配置。
- `macos/Runner/AppDelegate.swift`：macOS 关闭窗口不退出。
- `AGENTS.md`：项目 Agent 指南与 FVM 约定。
- `pubspec.yaml`：依赖与资源声明。

### 删除的文件

- `test/widget_test.dart`：默认 Counter demo 测试。

---

## 7. 结论

本项目已完成规格中所有 P0 主链路的代码实现，Windows 侧通过构建、分析和自动化测试验证，应用可正常启动。macOS 侧代码与配置已就绪，Release 构建与 dmg 打包已完成，但真实运行与 GUI 交互仍需在 macOS 设备上继续验证。UI 交互与系统级行为的主要未决项均为「未在真实 GUI 环境下完整手工测试」，而非已知代码缺陷。
