# Changelog

## [Unreleased]

### Added

- 本地字体配置：苹方（PingFang SC）作为全局中文字体，Google Sans Mono 作为剪切板记录等宽字体
- 字体资产注册（`assets/fonts/`）
- CHANGELOG.md

### Changed

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
