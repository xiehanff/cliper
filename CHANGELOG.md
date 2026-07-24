# Changelog

## [Unreleased]

## [1.1.3] - 2026-07-24

### Added

- macOS 应用名称统一为 `CLIPER`，修正图标显示尺寸

### Fixed

- 文件条目回写改为原生文件 URI 剪贴板对象，支持文件和文件夹按系统方式粘贴

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
