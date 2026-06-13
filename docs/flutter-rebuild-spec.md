# Cliper Flutter 重构交付规格

这份文档是给执行 agent 的直接交付说明，不是讨论稿。

目标很明确：在 `D:\xiehan\flutter\cliper` 中，用 Flutter 重新实现 Cliper，并对 `D:\xiehan\github\cliper` 的现有产品形态做 1:1 复刻。目标平台只有 `Windows` 和 `macOS`。UI、交互、数据模型、系统级能力都必须对齐，不能做“差不多”的替代版。

这个产品的窗口模型不是常规桌面应用，而是“弹出式剪贴板面板”：

- 没有常规标题栏
- 没有最小化 / 最大化 / 关闭按钮
- 不以任务栏主窗口的心智出现
- 点击应用外区域后自动隐藏
- 只能通过托盘点击或全局快捷键再次呼出

执行时，必须把这条当成顶层产品约束，不能退化成普通 Flutter 桌面窗口。

## 1. 源项目与真值源

重构时，以 `D:\xiehan\github\cliper` 为产品真值源。

优先级如下：

1. 运行时行为与现有源码一致。
2. 源码未明确时，以现有 README / 架构文档为准。
3. 文案、布局、交互不允许擅自优化或改风格。

执行前必须完整阅读这些文件：

- `D:\xiehan\github\cliper\README.zh-CN.md`
- `D:\xiehan\github\cliper\doc\architecture.md`
- `D:\xiehan\github\cliper\Cliper项目完整文档.md`
- `D:\xiehan\github\cliper\src\App.jsx`
- `D:\xiehan\github\cliper\src\index.css`
- `D:\xiehan\github\cliper\src\locales.js`
- `D:\xiehan\github\cliper\src\main\store.js`
- `D:\xiehan\github\cliper\src\main\clipboard.js`
- `D:\xiehan\github\cliper\src\main\ipcHandlers.js`
- `D:\xiehan\github\cliper\src\main\windowManager.js`
- `D:\xiehan\github\cliper\src\main\shortcutManager.js`
- `D:\xiehan\github\cliper\src\main\trayManager.js`
- `D:\xiehan\github\cliper\src\main\autoLaunch.js`
- `D:\xiehan\github\cliper\src\main\platform\WindowsNativeAdapter.js`
- `D:\xiehan\github\cliper\src\main\platform\MacOSAdapter.js`

## 2. 交付目标

需要交付一个 Flutter 桌面应用，满足下面条件：

- `flutter run -d windows` 可运行。
- `flutter run -d macos` 可运行。
- Windows/macOS 的核心功能一致。
- UI 视觉与交互对齐现有 Electron 版。
- 系统级能力完整对齐现有 Electron 版。
- 代码结构可维护，系统能力与 UI 分层清晰。
- 至少有基础自动化测试，覆盖数据层与关键行为。

## 3. 非目标

这些不在本次范围内：

- Android 功能实现
- iOS 功能实现
- 云同步
- 搜索
- 内容编辑
- OCR
- 多窗口模式
- 任意新的产品功能
- 对现有交互做“顺手优化”

如果发现 Electron 版有明显缺陷，也不要擅自修产品逻辑。先按现有行为复刻。

## 4. 技术约束

### 4.1 平台与仓库

- 代码只在 `D:\xiehan\flutter\cliper` 修改。
- 目标平台只支持 `windows/` 与 `macos/`。
- `android/` 可以保留默认目录，但本次不投入实现。

### 4.2 Flutter 侧架构要求

不要把 Electron 的“主进程 + IPC”结构硬搬进 Flutter，但要保留职责分离。

必须拆分为以下层次：

- `presentation`：页面、组件、主题、文案
- `application`：状态编排、命令、交互用例
- `domain`：实体、枚举、接口
- `infrastructure`：本地存储、桌面插件、平台通道、窗口/托盘/快捷键/剪贴板实现

### 4.3 状态管理要求

允许使用轻量方案，但不要引入过重框架。

推荐：

- `ChangeNotifier` + `Provider`
- 或 `ValueNotifier` + 自定义控制器

不要求上 `Bloc` / `Riverpod`，除非仓库里已经用了。当前仓库是空壳，不需要为了“规范”加复杂框架。

### 4.4 推荐插件

优先使用成熟桌面插件，不要先写原生代码。只有插件无法满足时，才补平台通道或 FFI。

建议能力映射：

| 能力 | 首选 |
|---|---|
| 窗口管理 | `window_manager` |
| 托盘 | `tray_manager` |
| 全局快捷键 | `hotkey_manager` |
| 开机自启动 | `launch_at_startup` |
| 剪贴板读写 | `super_clipboard` |
| 剪贴板变更监听 | `clipboard_watcher` |
| 屏幕信息/定位辅助 | `screen_retriever` |

说明：

- 这些插件当前都存在公开包与桌面支持说明。
- 文件路径剪贴板在 Windows 下可能需要额外平台代码，不能假设插件天然等价于 Electron 的 `FileNameW` 读取逻辑。
- macOS 的后台工具行为也可能需要改原生层配置，不能只停留在 Dart 层。

### 4.5 代码风格与可维护性要求

这部分不是建议，是必须遵守的实现约束。

- 优先写小而明确的类和函数，不要堆大文件。
- 单个函数只做一件事，长度尽量控制在易读范围内。
- 单个类只承担一个稳定职责，不要混合 UI、状态、平台调用、存储。
- 不要为了“以后可能会扩展”提前做抽象。
- 发现重复逻辑时，先判断是否真的是同一语义，再抽取公共函数。
- 不要出现“万能 Manager”或“万能 Controller”持有所有依赖并直接处理所有逻辑。
- 业务逻辑不允许写在 Widget 的 `build()` 里。
- 平台插件调用不要散落在页面组件里。
- 不要在 UI 层直接读写 JSON、本地文件、平台通道、托盘、快捷键。
- 注释只解释难以一眼看懂的约束或平台差异，不写废话注释。

### 4.6 单一职责边界

分层之后，每层只做自己该做的事。

`presentation` 层：

- 只负责布局、展示、事件转发、轻量交互状态
- 不直接处理存储、剪贴板、快捷键、托盘、窗口焦点、平台判断

`application` 层：

- 负责编排用例和状态变化
- 组织“创建分组”“切换主题”“激活条目”“处理剪贴板新内容”这类动作
- 不直接依赖具体插件类型，应该依赖抽象接口

`domain` 层：

- 只放稳定的数据结构、值对象、规则、接口定义
- 不依赖 Flutter UI、插件、文件系统

`infrastructure` 层：

- 负责插件封装、平台通道、文件读写、系统集成
- 对外暴露稳定接口
- 不反向依赖页面组件

### 4.7 冗余控制要求

- 不要复制一套 `Windows` 和 `macOS` 页面代码。
- 平台差异只收敛在 `infrastructure/desktop/platform` 或对应 service 内。
- 不要为 `text/image/file` 三种条目分别复制三套几乎一样的流程代码。
- 条目去重、入库、上限裁剪、移动规则必须集中在统一的业务层实现。
- 主题和语言切换逻辑不能在多个 Widget 各写一遍。
- 如果一个值可以从状态推导出来，就不要重复存储第二份。

### 4.8 易测性要求

- 所有核心业务规则必须脱离 Widget 独立测试。
- 平台服务必须通过接口注入，便于 fake/mock。
- 不要在控制器构造函数里直接静态读取插件单例。
- 时钟、随机 ID、文件路径、系统能力读取最好都通过可替换依赖注入。
- Widget 测试中不应真的依赖托盘、快捷键、系统剪贴板。
- 平台插件异常要在基础设施层转成可断言的失败结果或日志，不要把异常直接炸到 UI。

## 5. 产品功能清单

以下能力必须全部交付。

### 5.1 剪贴板历史

- 自动监听剪贴板变化。
- 支持三种类型：
  - 文本
  - 图片
  - 文件路径列表
- 新内容进入“实时剪贴板”顶部。
- 实时历史最多保留 50 条。
- 相同内容不重复插入。

### 5.2 条目激活

- 双击条目后，将内容重新写回系统剪贴板。
- 双击后窗口隐藏。
- 如果该条目来自实时历史且不在顶部，需要移动到顶部并更新时间戳。

### 5.3 分组归档

- 可创建分组。
- 可删除分组。
- 可修改分组颜色。
- 可将条目从实时历史拖拽到分组。
- 可将条目从分组拖回实时历史。
- 可在分组之间移动条目。
- 从实时历史拖到其他分组时，目标分组插入一份副本，不删除实时历史原条目。
- 从普通分组移动到其他组时，源分组移除原条目。

### 5.4 快捷键

- 默认全局快捷键：`CommandOrControl+\`
- 支持用户重新录制快捷键。
- 新快捷键保存后立即生效。
- 快捷键作用：显示/隐藏主窗口。

### 5.5 窗口行为

- 主窗口默认隐藏启动。
- 点击托盘或触发快捷键时显示/隐藏。
- 窗口为无边框、置顶、跳过任务栏。
- 窗口不是常规桌面主窗口，而是弹出式工具面板。
- 不允许出现原生标题栏。
- 不允许出现最小化、最大化、关闭按钮。
- 窗口显示后，只有在本次展示期间曾获得焦点，失焦时才自动隐藏。
- 窗口标题与品牌保持一致，不能保留默认 Flutter 标题。
- 除托盘点击和全局快捷键外，不提供其他主入口来重新呼出窗口。

### 5.6 托盘

- 创建系统托盘图标。
- 点击托盘图标切换主窗口显示状态。
- 托盘菜单至少包含“退出应用”。

### 5.7 开机自启动

- 设置面板可开启/关闭开机自启动。
- Windows 和 macOS 都要支持。
- macOS 开机启动后应隐藏启动。
- 开发环境不要求真正写入系统启动项，但应用内状态不能乱。

### 5.8 国际化

- 仅支持 `zh` / `en`。
- 文案必须与现有项目一致，不要自行润色。

### 5.9 主题

- 支持 `dark` / `light`。
- 默认 `dark`。
- 主题切换后立即更新 UI。

### 5.10 持久化

- 本地保存实时历史、分组、设置。
- 应用重启后恢复。
- 存储结构要兼容当前 Electron 版数据模型。

## 6. 数据模型

数据结构必须与现有 Electron 版对齐。

```dart
class ClipboardStore {
  final List<ClipboardItem> realtime;
  final List<ClipboardGroup> groups;
  final AppSettings settings;
}

enum ClipboardItemType {
  text,
  image,
  file,
}

class ClipboardItem {
  final String id;
  final ClipboardItemType type;
  final String text;
  final String image;
  final List<String> files;
  final int timestamp;
}

class ClipboardGroup {
  final String id;
  final String name;
  final String color;
  final List<ClipboardItem> items;
}

class AppSettings {
  final String theme;
  final String language;
  final String shortcut;
  final bool autoLaunch;
}
```

默认值固定为：

```text
theme = dark
language = zh
shortcut = CommandOrControl+\
autoLaunch = false
```

额外约束：

- `id` 使用字符串随机 ID。
- `timestamp` 使用毫秒时间戳。
- `type=file` 时只使用 `files`。
- `type=image` 时只使用 `image`。
- `type=text` 时只使用 `text`。

## 7. 本地存储要求

### 7.1 文件位置

使用桌面应用用户数据目录，不要写死工作区路径。

文件名固定为：

```text
clipboard-store.json
```

### 7.2 兼容规则

需要兼容两种历史格式：

1. 旧版仅数组格式，代表 `realtime`
2. 新版完整对象格式，包含 `realtime / groups / settings`

### 7.3 容错规则

- 文件不存在时使用默认 store。
- JSON 解析失败时不崩溃，回退默认 store。
- 缺失字段时合并默认值。
- `shortcut` 为空字符串时回退默认快捷键。

## 8. UI 复刻规格

UI 必须按 Electron 版复刻，不允许自由发挥。

### 8.1 主窗口尺寸与基础形态

- 宽：`660`
- 高：`720`
- 无原生边框
- 非透明窗口
- 常驻顶层
- 跳过任务栏
- 初始隐藏
- 可调整大小
- 没有标题栏区域按钮
- 视觉形态更接近弹窗/面板，而不是普通应用窗口

### 8.2 页面总布局

- 左侧侧边栏固定宽度：`120`
- 右侧为主内容区
- 整体纵向充满窗口
- 顶部 header 可拖动窗口
- header 内交互按钮区域不可拖动

### 8.3 主题色与基础视觉

需要复刻现有变量语义，至少保持同级别观感。

亮色主题：

- 背景：`rgba(245, 245, 250, 0.98)`
- 侧边栏：`rgba(240, 240, 245, 0.95)`
- 主文字：`#1a1a1a`
- 次文字：`#6b6b7a`
- 主强调：`#007AFF`
- 紫色强调：`#8b5cf6`

暗色主题：

- 背景：`rgba(18, 18, 20, 0.98)`
- 侧边栏：`rgba(24, 24, 28, 0.95)`
- 主文字：`#f5f5f7`
- 次文字：`#9a9aa5`
- 卡片背景：`#1f1f23`
- 卡片 hover：`#2a2a2e`

分组颜色固定为：

```text
#FF6B6B
#4ECDC4
#FFD93D
#6BCF7F
#A78BFA
#FB7185
```

### 8.4 侧边栏

必须包含：

- 一个固定 tab：`实时剪贴板 / Realtime History`
- 若干用户分组 tab
- 底部“新建分组”按钮

行为要求：

- 激活项使用紫色渐变背景。
- hover 时有轻微位移与背景变化。
- 分组 tab 左侧显示颜色点。
- hover 分组时才出现删除按钮。
- 点击颜色点展开颜色选择器。
- 点击其他区域收起颜色选择器。

### 8.5 主内容区

header 结构：

- 左侧标题：当前激活分组名称
- 右侧工具区：
  - 快捷键录制按钮
  - 快捷键文本胶囊
  - 主题切换按钮
  - 语言切换按钮
  - 设置按钮

列表区要求：

- 条目竖向排列
- 卡片圆角约 `10`
- 列表滚动条隐藏
- 滚动较深后出现右上角 `top` 按钮

### 8.6 条目渲染

文本条目：

- 单行省略
- 展示时间
- hover 显示删除按钮

图片条目：

- 使用缩略图展示
- 最大高度约 `120`
- 保持比例

文件条目：

- 多行展示文件路径
- 前缀有文件图标或等价表达

### 8.7 设置面板

设置面板是一个浮层，不是整页跳转。

必须包含：

- 标题：`设置`
- 开机自启动开关
- 当前状态说明文案
- 关闭按钮

行为要求：

- 点击设置按钮切换显示。
- 点击浮层外部区域关闭。
- 样式为小面板悬浮在右上角。

### 8.8 快捷键录制 UI

- 点击键盘图标后进入录制态。
- 录制态下，快捷键文本区显示“等待按键”或英文等价文案。
- 录制态视觉高亮。
- 捕获到组合键后立刻保存并退出录制态。

## 9. 文案规格

必须使用现有文案，不要改写。

```text
zh:
realtime = 实时剪贴板
collections = 收藏夹
newGroup = 新建分组
deleteGroupConfirm = 确定要删除这个分组吗？
groupNamePlaceholder = 分组名称...
doubleClickToCopy = 双击复制
empty = 空
delete = 删除
settings = 设置
language = 语言
switchTo = En
shortcut = 快捷键
theme = 主题
dark = 深色
light = 浅色
editShortcut = 点击修改
waitingForKey = 等待按键

en:
realtime = Realtime History
collections = Collections
newGroup = New Group
deleteGroupConfirm = Delete group?
groupNamePlaceholder = Name...
doubleClickToCopy = Double-click to copy
empty = Empty
delete = Delete
settings = Settings
language = Language
switchTo = 中
shortcut = Shortcut
theme = Theme
dark = Dark
light = Light
editShortcut = Click to edit
waitingForKey = Waiting for keys
```

## 10. 系统级行为规格

### 10.1 剪贴板监听

目标行为与 Electron 版一致：

- 优先识别文件路径列表
- 文件未命中时识别文本
- 文本未命中时识别图片

优先级固定：

1. file
2. text
3. image

去重规则：

- 文本按文本值去重
- 图片按 data URL 或等价内容标识去重
- 文件按路径数组拼接后的字符串去重

### 10.2 剪贴板写回

- 文本条目写回文本
- 图片条目写回图片
- 文件条目写回时，至少要恢复为换行拼接路径文本

说明：

- 如果 Flutter 桌面插件无法完整恢复系统“文件剪贴板对象”，Windows 下允许第一版回写为文本路径，但“读取文件路径并入库”必须实现。
- 如果能补齐原生实现，则应优先做到与 Electron 完全等价。

### 10.3 窗口显示与隐藏

必须实现下面的显示状态机：

1. 应用启动时创建窗口但不显示。
2. 用户通过托盘或快捷键触发时显示窗口。
3. 窗口显示后先将“本次展示已获得焦点”状态置为 `false`。
4. 真正获得焦点后置为 `true`。
5. 只有该状态为 `true` 时，失焦才隐藏窗口。

不要做成“只要 blur 就立刻隐藏”，那和现有行为不一致。

补充硬约束：

- 点击应用窗口外部区域，窗口必须隐藏。
- 点击桌面、其他应用、其他系统窗口，效果都一样，统一视为外部点击。
- 隐藏后，窗口不能靠任务栏按钮恢复，因为它本来就不应出现在任务栏。
- 隐藏后，只能通过托盘点击或全局快捷键再次呼出。
- 不要提供右上角关闭按钮或最小化按钮作为替代入口。

### 10.3.1 窗口定位策略

窗口不是随意居中弹出，必须有稳定、可预期的出现位置策略。

默认定位规则：

1. 优先以当前活跃屏幕为目标屏幕。
2. 如果无法可靠判断活跃屏幕，则回退到主屏幕。
3. 窗口默认在目标屏幕的可用工作区内居中显示。

补充约束：

- 不能让窗口出现在屏幕外。
- 不能让窗口被任务栏或 macOS 菜单栏完全遮挡。
- 多显示器场景下，不要固定永远出现在主显示器，优先出现在用户当前交互屏幕。
- 如果托盘点击事件能提供更可靠的屏幕上下文，可优先使用托盘所在屏幕。

本次不要求实现“贴着托盘图标边缘弹出”的像素级定位，但必须满足：

- 位置稳定
- 多次呼出时不随机跳动
- 在多屏场景下符合用户当前操作预期

### 10.3.2 呼出来源策略

窗口只能通过两种来源呼出：

1. 托盘点击
2. 全局快捷键

不同来源的行为要统一，但要保留上下文差异：

- 托盘点击时，如果窗口当前隐藏，则显示并聚焦。
- 托盘点击时，如果窗口当前显示，则直接隐藏。
- 全局快捷键触发时，如果窗口当前隐藏，则显示并聚焦。
- 全局快捷键触发时，如果窗口当前显示，则直接隐藏。

禁止行为：

- 不要因为重复点击托盘而创建新窗口。
- 不要因为连续按快捷键而堆叠多个窗口实例。
- 不要出现“窗口已显示但未在最前面”的半激活状态。

### 10.3.3 首次焦点与呼出后焦点细节

呼出后焦点逻辑必须固定，不允许模糊实现。

显示窗口时：

1. 先显示窗口。
2. 立即尝试将窗口置顶。
3. 立即请求焦点。
4. 然后再把“本次展示已获得焦点”状态交给真实焦点事件确认。

理由：

- 这样可以避免视觉上窗口已经出现，但键盘输入没有落到应用上的情况。
- 这样也能避免因为 show/focus 顺序不稳定导致的误隐藏。

首次显示后的规则：

- 第一次呼出时，窗口必须进入可输入状态。
- 如果用户立即开始滚轮、点击、键盘操作，应用要能接住。
- 不允许出现首次呼出需要再点一下窗口内部才能操作的情况。

焦点状态建议维护为两个值：

- `isWindowVisible`
- `hadFocusSinceLastShow`

不要把“当前是否 visible”和“本次 show 后是否真正拿到过焦点”混成一个布尔值。

### 10.3.4 托盘点击后的显示策略

托盘点击不是普通按钮点击，要明确窗口切换行为。

当用户点击托盘时：

- 如果窗口隐藏：显示窗口、定位到目标屏幕、尝试聚焦。
- 如果窗口已显示：隐藏窗口。

如果点击托盘时窗口已显示但失去焦点：

- 仍按“当前显示”处理，直接隐藏。
- 不要改成“重新显示并抢焦点”，否则用户会感觉托盘点击行为不稳定。

如果托盘点击和失焦事件非常接近：

- 需要保证最终状态一致。
- 推荐把“显隐切换”集中收敛到一个窗口服务方法中，避免托盘事件和 blur 事件各自改状态导致抖动。

### 10.3.5 快捷键呼出后的显示策略

快捷键呼出与托盘呼出在显隐上保持一致，但要注意键盘场景的连贯性。

- 用户按下快捷键时，如果窗口隐藏，窗口应快速显示并聚焦。
- 用户再次按下同一快捷键时，如果窗口显示，窗口应隐藏。
- 快捷键呼出后，用户应能立刻继续键盘操作，不需要额外鼠标点击。

不要出现这些问题：

- 快捷键显示了窗口，但焦点仍停留在原应用。
- 快捷键连续触发后窗口闪烁。
- 快捷键触发时窗口位置在不同屏幕随机变化。

### 10.3.6 动画策略

动画是允许的，但只能作为轻量增强，不能改变交互结果。

允许：

- 120ms 到 180ms 的淡入
- 轻微位移过渡
- 阴影或透明度渐变

不允许：

- 明显拖慢呼出速度
- 动画期间无法交互
- 动画结束前拿不到焦点
- 每个平台使用完全不同的弹出节奏

强约束：

- 如果动画会影响焦点稳定性，宁可去掉动画。
- “能稳定呼出并立刻可操作”优先级高于“看起来更丝滑”。

### 10.3.7 隐藏时机细节

窗口隐藏的触发条件需要统一定义。

应隐藏的场景：

- 用户点击窗口外区域
- 用户切换到其他应用
- 用户点击桌面
- 用户通过托盘再次点击
- 用户通过全局快捷键再次触发
- 用户双击某条记录完成写回

不应隐藏的场景：

- 用户点击窗口内部按钮
- 用户滚动列表
- 用户切换主题/语言
- 用户打开设置面板
- 用户在设置面板内点击开关
- 用户选择分组颜色
- 用户录制快捷键过程中按下组合键

要求：

- 所有内部浮层都视为应用内部区域。
- 不能因为点击颜色选择器或设置面板而触发外部点击隐藏。
- 内部子元素焦点切换不能被误判为外部失焦。

### 10.4 快捷键捕获规则

录制快捷键时：

- 忽略只有修饰键的输入
- 支持 `Ctrl` / `Meta` / `Alt` / `Shift`
- 组合后序列化为统一格式并持久化

运行时快捷键注册：

- 修改快捷键前先注销旧快捷键
- 注册失败时不能崩溃
- 注册失败至少要打印日志

### 10.5 macOS 行为

必须对齐现有设计：

- 应用作为后台工具运行
- Dock 图标隐藏
- 关闭窗口后应用不退出
- 开机启动时隐藏启动

### 10.6 Windows 行为

必须对齐现有设计：

- 支持读取文件路径剪贴板
- 窗口关闭后应用可退出或由托盘控制退出，具体实现要与最终 Flutter 行为一致，但不能破坏常驻工具定位

## 11. Flutter 目录建议

目标不是强制文件名一致，而是要有清晰职责边界。建议采用下面结构：

```text
lib/
  app/
    app.dart
    bootstrap.dart
  core/
    constants/
    utils/
    theme/
    l10n/
  domain/
    entities/
    enums/
    repositories/
    services/
  infrastructure/
    persistence/
      clipboard_store_local_data_source.dart
    desktop/
      tray/
      window/
      hotkey/
      clipboard/
      launch/
      platform/
    models/
  application/
    controllers/
      app_controller.dart
      settings_controller.dart
      clipboard_history_controller.dart
  presentation/
    pages/
      home_page.dart
    widgets/
      sidebar/
      header/
      item_list/
      settings_panel/
```

依赖方向必须固定：

```text
presentation -> application -> domain
infrastructure -> domain
application -> infrastructure（仅通过接口注入后的实现装配，不要在领域规则中反向依赖）
```

更具体地说：

- `presentation` 可以依赖 `application`，不能依赖具体平台实现文件。
- `application` 可以依赖 `domain` 接口，不能直接 import `windows/runner` 或 `macos/Runner` 相关代码。
- `infrastructure` 可以实现 `domain` 或 `application` 需要的接口，但不能把 Flutter 页面组件引进来。
- `domain` 必须处在最稳定的位置，不能反向依赖其他层。

建议增加一层装配入口：

```text
lib/app/bootstrap.dart
```

它负责：

- 创建 repository / service 实例
- 绑定平台实现
- 注入 controller
- 启动监听器

不要把依赖装配写进页面组件里。

## 12. 需要实现的核心类

至少要有这些职责对象：

| 类/对象 | 职责 |
|---|---|
| `AppController` | 整体状态源，协调启动、监听、存储、广播刷新 |
| `ClipboardMonitorManager` | 监听系统剪贴板变化，做类型识别与去重 |
| `ClipboardWriteManager` | 将条目写回系统剪贴板 |
| `WindowManagerService` | 窗口创建、显示、隐藏、焦点状态管理 |
| `TrayManagerService` | 托盘创建、点击行为、退出菜单 |
| `HotkeyManagerService` | 全局快捷键注册、更新、释放 |
| `LaunchAtStartupService` | 自启动状态读写 |
| `StoreRepository` | store 读写与兼容处理 |
| `LocalizationManager` | 语言切换与文案查询 |
| `ThemeManager` | 主题切换 |

这些对象的边界要明确：

- `AppController` 只负责总装配后的状态协调，不负责所有业务细节。
- `ClipboardMonitorManager` 只负责监听和解析新内容，不负责 UI 刷新。
- `ClipboardWriteManager` 只负责写回，不负责条目排序。
- `StoreRepository` 负责持久化，不负责拖拽移动规则。
- 拖拽移动、激活条目提升、50 条上限裁剪、去重规则，应该放在独立的业务服务或控制器内部方法中，不要散落在多个 Widget 回调里。
- `WindowManagerService` 负责弹出式窗口生命周期，不负责主题和文案。
- `TrayManagerService` 只处理托盘，不顺手管理快捷键。
- `HotkeyManagerService` 只处理全局快捷键注册与释放，不顺手修改 UI 状态。

建议补这些辅助对象，避免主控制器膨胀：

| 类/对象 | 职责 |
|---|---|
| `ClipboardHistoryService` | 条目去重、插入、裁剪、提升到顶部 |
| `GroupService` | 创建分组、删除分组、改色、移动条目 |
| `StoreSerializer` | JSON 编解码与兼容格式转换 |
| `ShortcutFormatter` | 快捷键录制后的归一化格式转换 |
| `AppLogger` | 统一日志入口，避免散落 `print` |

禁止出现这些情况：

- 一个 `HomePageController` 同时负责剪贴板监听、文件存储、托盘和快捷键。
- 一个 `ClipboardManager` 同时处理“监听、写回、持久化、UI 刷新、快捷键注册”。
- 页面组件直接 new service。
- 页面回调里写大段业务分支。

## 13. 平台通道要求

如果插件无法满足，允许补平台通道。

优先补的点：

- Windows 文件剪贴板读取
- macOS Dock 隐藏与后台工具配置
- 某些窗口焦点事件不稳定时的平台兜底

要求：

- 平台相关代码集中放到 `windows/runner` 与 `macos/Runner` 的独立文件。
- 不要把平台判断散落到 UI 层。
- Dart 层通过统一接口调用。

## 14. 执行步骤

按下面顺序做，不要乱序。

### 第一步：清理空壳并搭基础骨架

验证：

- 移除默认 counter demo
- 应用能正常启动空主界面
- 目录结构建立完成

### 第二步：实现数据模型与本地存储

验证：

- 可以读写 `clipboard-store.json`
- 默认值正确
- 旧格式兼容正确

### 第三步：实现主题、国际化、主布局

验证：

- 明暗主题可切换
- 中英文可切换
- UI 结构与 Electron 版对齐

### 第四步：实现实时列表、分组与设置面板

验证：

- 创建/删除分组可用
- 切换分组可用
- 条目列表渲染正确
- 设置浮层行为正确

### 第五步：实现剪贴板监听与写回

验证：

- 文本复制后入库
- 图片复制后入库
- Windows 文件路径复制后入库
- 双击条目后剪贴板被回写

### 第六步：实现托盘、快捷键、窗口隐藏逻辑

验证：

- 托盘显示正常
- 点击托盘可显隐窗口
- 全局快捷键可显隐窗口
- 失焦隐藏逻辑符合规格

### 第七步：实现开机自启动与平台差异

验证：

- Windows 自启动开关可用
- macOS 自启动开关可用
- macOS 后台工具行为正确

### 第八步：补测试与打包验证

验证：

- `flutter analyze` 通过
- 关键测试通过
- Windows 构建通过
- macOS 构建通过

## 15. 测试要求

至少补这些测试：

### 15.0 质量门槛

- `flutter analyze` 必须通过。
- 新增代码不能留下未使用导入、未使用字段、未使用私有方法。
- 关键业务层不允许零测试直接交付。
- 如果新增平台通道，Dart 侧必须有对应接口测试，平台侧至少要有最小手工验证说明。

### 15.1 单元测试

- store 默认值
- store 旧格式兼容
- 条目去重
- 实时历史上限 50 条
- 从实时历史拖入分组时复制逻辑
- 从分组移动到其他组时迁移逻辑
- 激活实时条目后提升到顶部逻辑
- 快捷键格式归一化
- 设置默认值合并
- JSON 损坏后的兜底恢复
- 外部依赖抛错时控制器的降级行为

### 15.2 Widget 测试

- 主题切换
- 语言切换
- 新建分组
- 空状态
- 设置面板打开/关闭
- 快捷键录制态文案变化
- 分组颜色选择器展开/收起
- 条目列表在不同类型下的渲染

### 15.2.1 测试替身要求

- Widget 测试和单元测试优先使用 fake/stub，不要默认上重量级 mock。
- 对剪贴板、托盘、快捷键、自启动、窗口服务都要有可替换实现。
- 测试里不要真的触发系统全局快捷键注册。
- 测试里不要真的创建托盘。
- 测试里不要真的读写用户真实配置目录。

### 15.3 手工测试

Windows：

- 文本复制
- 图片复制
- 文件复制
- 双击回填
- 快捷键显隐
- 托盘显隐
- 自启动开关

macOS：

- 文本复制
- 图片复制
- 快捷键显隐
- 托盘显隐
- 自启动开关
- Dock 隐藏
- 关闭窗口后应用不退出

## 16. 验收清单

以下全部满足才算交付完成：

- `lib/main.dart` 不再是默认 Flutter demo
- UI 与 Electron 版主界面结构一致
- 窗口是弹出式工具面板，不是普通桌面窗口
- 没有原生标题栏和最小化/最大化/关闭按钮
- 默认主题为深色
- 默认语言为中文
- 默认快捷键为 `CommandOrControl+\`
- 实时历史可记录文本、图片、文件
- 双击条目可写回剪贴板并隐藏窗口
- 分组创建、删除、改色、拖拽归档全部可用
- 设置面板可切换开机自启动
- 托盘可用
- 全局快捷键可用
- 点击应用外区域后窗口会隐藏
- 隐藏后只能通过托盘或快捷键重新呼出
- 呼出后窗口位置稳定，不会随机跳到错误屏幕或屏幕外
- 首次呼出后窗口立即可交互，不需要额外点一下获取焦点
- 托盘点击与快捷键触发的显隐行为一致，没有抖动和重复实例
- Windows 可运行
- macOS 可运行
- `flutter analyze` 通过
- 自动化测试通过
- 核心业务逻辑与平台服务解耦，可通过 fake 进行单元测试
- 控制器和 service 职责边界清晰，没有明显的“大而全”类

## 17. 明确禁止项

- 不要把这个项目做成普通单页 Flutter 应用然后忽略桌面系统能力。
- 不要为了规避平台实现难点而删功能。
- 不要将“文件剪贴板”偷换成“只支持文本路径输入”。
- 不要改文案。
- 不要改交互顺序。
- 不要引入与需求无关的状态管理框架、路由框架、网络层、后端 SDK。
- 不要保留默认 Flutter Counter 相关代码。
- 不要为了省事把业务逻辑塞进 Widget。
- 不要让控制器直接依赖多个具体插件实现并同时承担业务规则。
- 不要复制粘贴相似逻辑形成多份分叉实现。
- 不要把 Windows/macOS 差异判断散落在页面和组件中。
- 不要把“方便测试”理解成只写几个 Widget smoke test。

## 18. 交付说明

最终提交时，至少要附上这些结果：

- 功能说明
- 使用到的插件清单
- 是否补了原生平台代码
- Windows 验证结果
- macOS 验证结果
- 未解决问题列表

如果某个系统能力因为插件限制暂时无法 100% 等价，必须在提交中明确写出：

- 哪个平台
- 缺了什么
- 为什么缺
- 目前行为是什么
- 下一步怎么补

但注意，这只能用于说明，不代表可以默认跳过。当前目标仍然是 1:1 交付。
