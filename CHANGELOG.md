# Changelog

## [Unreleased]

## [1.1.6] - 2026-09-04

### Fixed

- 修复部分网页“复制”按钮写入剪切板后可以正常粘贴，但 Cliper 未生成历史记录的问题：文本读取现在优先使用 plain text，缺失或为空时回退到 HTML clipboard，并安全转换为纯文本
- 剪切板变化后增加短延迟重试，降低系统剪切板格式尚未就绪时的漏记概率；同时加入 generation guard，避免 stop/restart 后旧重试继续写入历史
- 修复重复复制已有历史项时界面无变化的问题：重复内容保持单条记录，但会刷新时间并移动到列表顶部
- 修复持久化进行中后续保存请求被直接丢弃的问题，改为 dirty + drain queue，确保连续复制后的最新状态最终落盘
- 加固 HTML clipboard 文本转换：保留有效首尾空白与显式换行，正确处理 quoted attribute 中的 `>`、CF_HTML fragment、script/style 以及其中的 `<`

### Changed

- 新增 HTML-only clipboard、monitor retry、重复项刷新和 in-flight persistence 回归测试
- 发布版本号更新为 `1.1.6`

## [1.1.5] - 2026-08-30

### Changed

- 明亮模式条目卡片背景色再调暗一档（`#F2F2F5` → `#EDEDF1`），hover 色同步调整
- 发布流程改为 tag 触发：推送 `v*` tag 时才创建 GitHub Release（`--verify-tag` 校验 tag，Release Notes 从 `CHANGELOG.md` 提取对应版本段落，缺失时回退为简短说明）；master 推送只构建并上传 artifact，不再自动发版。同时对 `on: push` 增加分支过滤，避免无关分支消耗构建时长
- 发布版本号更新为 `1.1.5`

## [1.1.4] - 2026-08-30

### Added

- GitHub Actions 打包流水线（`.github/workflows/build-desktop-packages.yml`）：push 或手动触发时自动构建 Windows Inno Setup 安装包与 macOS DMG，产物上传为 artifact（保留 30 天）
- master 分支推送后自动创建/更新 GitHub Release `v<版本>`，安装包作为 Release 附件发布，用户可直接从 Releases 页面下载
- macOS DMG 打包脚本 `scripts/build_macos_dmg.sh`，支持 `--skip-build` 复用已有 Release 构建

### Changed

- 明亮模式条目卡片底色调暗（`#F9F9FB` → `#F2F2F5`），hover 色同步调整，并加强卡片阴影，提升与窗口背景的分离度
- 设置浮窗移除底部「关闭」按钮，保留点击浮窗外区域与再次点击头部设置按钮两种关闭方式
- 仓库不再跟踪历史安装包产物 `windows/installer/dist/CLIPER_Setup_1.0.0.exe`
- 更新 README 与 docs 文档，补充 CI 打包与分发说明
- 发布版本号更新为 `1.1.4`

## [1.1.3] - 2026-07-24

### Added

- macOS 应用名称统一为 `CLIPER`，修正图标显示尺寸

### Fixed

- 文件条目回写改为原生文件 URI 剪贴板对象，支持文件和文件夹按系统方式粘贴
- 修复连续启动时残留多个 `cliper.exe` 后台进程的问题：未取得单实例锁的进程现在会立即退出，不再停留在 Windows Runner 消息循环中

### Changed

- 发布版本号更新为 `1.1.3`

## [1.1.1] - 2026-06-15

### Added

- Windows 单实例锁，防止重复启动多个 Cliper 实例

### Fixed

- Windows 文件条目去重时统一归一化路径大小写，避免同一路径被当成多个条目

### Changed

- 更新 Windows 发布版本号与安装包输出名

## [1.1.0] - 2026-06-15

### Added

- macOS 开机自启动支持（SMAppService + 登录项）
- 平台特定窗口服务：`MacOSViewportService` / `WindowsViewportService`
- 接口 `ViewportController`（原 `WindowController`）
- macOS 红绿灯按钮隐藏（`windowButtonVisibility: false`）
- macOS 应用图标（asset catalog + .icns）
- 集成 851 GBai 马克笔体（GBaiMarkerPen）作为标题品牌字体
- README 宣传图（cliper.png）
- README 重写为面向用户的英文版 + 中文入口
- Makefile + make.cmd + make.ps1 统一构建入口
- ContentTypeDetector 工具类：根据数据格式检测内容类型（text/image/file）
- Windows 安装程序构建脚本（Inno Setup + PowerShell）
- Windows 快捷方式创建脚本（cmd + ps1）
- Windows 构建与分发文档
- 本地字体配置：苹方（PingFang SC）作为全局中文字体，Google Sans Mono 作为剪切板记录等宽字体
- 字体资产注册（`assets/fonts/`）
- CHANGELOG.md

### Changed

- 重命名 `WindowController` → `ViewportController`，目录 `window/` → `viewport/`
- 标题从动态文本（实时剪贴板/分组名）固定为 "Cliper"，移除侧边栏联动
- 标题使用绿色渐变（#77C599 → #5DA37A）+ GBaiMarkerPen 字体渲染
- 全局默认字体从 `Segoe UI` 改为 `PingFang SC`
- 明亮模式侧边栏颜色调深（`240,240,245` → `227,227,235`），与右侧记录区形成层次
- 默认窗口宽度从 660 增加到 780
- 侧边栏默认宽度从 160 增加到 180
- 记录列表底部增加 24px 容器内边距，滚动内容不再贴底

### Refactored

- 记录卡片布局重写为 `1-2-1-1` Row 结构：
  - 左侧类型图标占位符
  - 中间 Column（主标题 + 副标题，副标题最多 3 行，等宽字体）
  - 右侧时间文本（`MM/dd HH:mm:ss` 格式）
  - 三点菜单按钮（PopupMenuButton），替代原删除图标
- 图片类型记录增加固定 48×48 缩略图
- 时间格式化统一为月/日 时:分:秒，不再区分今天/历史
- 清理旧组件：`_ImageContent`、`_ImagePlaceholder`、`_DeleteButton`、`_buildBody`
- 卡片 hover 阴影移除紫色效果，仅加深黑色阴影

### Removed

- 记录卡片 hover 紫色阴影
