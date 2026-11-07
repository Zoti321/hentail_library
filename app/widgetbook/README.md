# MD3E Widgetbook（dev-only）

入口：`flutter run -t widgetbook/main.dart`

## 目录

| 路径 | 用途 |
|------|------|
| `main.dart` | Widgetbook 入口 |
| `catalog/` | 组件树定义（`md3e_widgetbook_directories.dart` 及 `part`） |
| `shell/` | App 壳、Viewport/Theme addon、Scope、本地化 |
| `hosts/` | 各 Lab 页面的 Widgetbook host（`*_lab_host.dart`） |
| `preview/` | 预览用假数据（`*_preview_data.dart`） |
| `lab/` | 与生产共享的 Lab 专用 UI/导航（非 Widgetbook 专有） |
| `lab/theme/` | Lab 主题 |
| `lab/pages/` | Lab 整页（如库浏览） |
| `lab/navigation/` | Lab 内路由/转场 |
| `lab/data/` | Lab 导航用静态数据 |

改 `catalog/md3e_widgetbook_directories.dart` 时请同步 `docs/html/widgetbook.html`（见 ADR-0030）。
