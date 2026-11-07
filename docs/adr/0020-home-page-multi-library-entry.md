# 首页 reposition 为多库阅读入口

多 Library（ADR-0008）落地后，首页仍保留单库时代的 Current library 仪表盘语义：顶栏扫描、按 Current library 计 comic/series、空库 Hero 以扫描为主 CTA。Library sync 触发与库健康曾计划收敛到应用侧栏 Libraries 分区；**生产 MD3E shell 已改为 Home「我的漫画库」+ Navigation rail 库 flyout**（见文末实现修订）。

## Status

Accepted

## Context

- 产品定位：Home dashboard 是启动后第一屏，但 **Reading history 跨 Library 全局**；浏览与搜索默认作用于 **Current library**（`GLOSSARY.md`）。
- ADR-0014 将空库 onboarding 放在 Home hero，主行动含扫描；多库后 onboarding 应引导 **建库**，扫描下沉到 **按 Library 的上下文**（现：Home 库列表行操作）。
- 用户期望首页承担：**全库态势摘要**（含「某库可能有新 Resource，建议 Library sync」），而非 Current library 语境与常驻全局扫描。

## Decision

- **Home page** 定位为：**全局阅读入口 + 多库态势摘要 + 库管理主界面**（「我的漫画库」：建库、排序、扫描/深度扫描、元数据刷新、编辑/删除）；不展示 Current library 指示为「控制台」，不提供**首页顶栏**常驻 Library sync 按钮。
- **废除**首页顶栏/空库 Hero 的扫描 CTA；Library sync 经 **Home 库列表行内操作**、`Scan on startup` / `Scan interval` 自动调度，以及 **Home library alert** 内的 per-library 扫描（非全局扫描按钮）。
- **Navigation rail** 的 Library 项 + **库 flyout / compact sheet**：**切库并打开 browse**（`LibraryManagementPort.openLibrary`）；建库与 scan/refresh **不在 flyout 重复为唯一入口**（flyout 可含快捷建库，与 Home 区块一致）。
- **Home page counts** 为 **全库聚合**（comic/series 跨全部 Library；tag/author 仍为全局字典计数）。
- **Home library alert** 展示全库 sync/健康摘要（远程不可达、上次 sync 失败、距上次成功 sync 过久等）；v1 文案可用 sync 时间启发式提示「可能有新 Resource」。真实枚举 diff 见 **ADR-0021 Library resource probe**。
- **Recently added on Home**（原决策）：跨全部 Library Top N — **已退役**（见实现修订）。
- **空库 onboarding** 触发条件：**无任何 Library**，或 **全库 Comic 总数为 0**；主行动为添加 Local/Remote library（Library form）；扫描说明为在 **Home 库列表**对该 Library 执行。

## Consequences

### Positive

- 首页与多库信息架构一致；Current library 语义在库 browse 与 shell 选库态出现，而非旧式「首页控制台」。
- 扫描职责清晰：按 Library 的行内操作 + 自动调度 + 情境化 alert。

### Negative

- 需扩展 `libraries` 表或等价持久化 **上次 sync 结果**，供 Home library alert 读取。
- 现有首页 widget/统计测试与 l10n（`homeScanLibrary` 等）需迁移或退役顶栏用法。
- ADR-0014 中「空库 Hero 主行动扫描」被本决策 supersede（建库为主，扫描不再在 Hero 常驻）。

> **实现修订（2026-11-02）**：生产 MD3E 首页（`Md3eHomePage`）已移除 **继续阅读 Top N** 与 **Recently added** 区块；继续阅读走 **`/history`**（`reading_history` feature）。Dart 侧已删除对应 Riverpod / `HomePageRepository` 方法与 read model；Rust `watch_continue_reading_top5` / `watch_recently_added_on_home` FRB 暂保留供 core 测试与后续收口。

> **实现修订（2026-11-03）**：库管理 UI 主入口为 **`/home`** 内 `HomeLibraryManagementPanel`（`Md3eHomeLibraryManagementSection`）。Legacy **`LibrariesSidebarSection` / `LibrariesAppSidebar`**（desktop sidebar Libraries 分区 + 行内溢出菜单）已从生产路径移除并删除源码。Shell 使用 **MD3E Navigation rail**（`ApplicationShell` + `md3e_production_shell_adapters.dart`）；库 flyout 数据与 Home 行共用 `list_libraries` 顺序与 dashboard stats。
