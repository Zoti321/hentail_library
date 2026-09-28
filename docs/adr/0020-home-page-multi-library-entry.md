# 首页 reposition 为多库阅读入口

多 Library（ADR-0008）落地后，首页仍保留单库时代的 Current library 仪表盘语义：顶栏扫描、按 Current library 计 comic/series、空库 Hero 以扫描为主 CTA。Library sync 触发与库健康已收敛到侧栏 Libraries 分区（溢出菜单扫描/深度扫描）与 shell 级自动调度；首页不应再充当「当前库控制台」。

## Status

Accepted

## Context

- 产品定位：Home dashboard 是启动后第一屏，但 **Reading history 跨 Library 全局**；浏览与搜索默认作用于 **Current library**（`CONTEXT.md`）。
- ADR-0014 将空库 onboarding 放在 Home hero，主行动含扫描；多库后 onboarding 应引导 **建库**，扫描下沉到 Library 上下文。
- 用户期望首页承担：**继续阅读**、**全库态势摘要**（含「某库可能有新 Resource，建议 Library sync」），而非 Current library 语境与常驻扫描。

## Decision

- **Home page** 定位为：**全局阅读入口 + 多库态势摘要**；不展示 Current library 指示，不提供常驻 Library sync 入口。
- **废除**首页顶栏/空库 Hero 的扫描 CTA；Library sync 仍经侧栏 Library 溢出菜单、`Scan on startup` / `Scan interval` 自动调度，以及首页 **情境化 Home library alert** 内的 per-library 扫描（非全局扫描按钮）。
- **Home page counts** 改为 **全库聚合**（comic/series 跨全部 Library；tag/author 仍为全局字典计数）。
- **Home library alert** 展示全库 sync/健康摘要（远程不可达、上次 sync 失败、距上次成功 sync 过久等）；v1 文案可用 sync 时间启发式提示「可能有新 Resource」。真实枚举 diff 见 **ADR-0021 Library resource probe**（依赖本 ADR 的 alert 栈）。
- **Recently added on Home**：跨全部 Library，按 Comic 入库时间取 Top N，卡片标注来源 Library 显示名。
- **空库 onboarding** 触发条件：**无任何 Library**，或 **全库 Comic 总数为 0**；主行动为添加 Local/Remote library，文案说明扫描在侧栏对该 Library 执行。

## Consequences

### Positive

- 首页与多库信息架构一致；Current library 语义只在库页/侧栏出现。
- 扫描职责单一：Library 上下文 + 自动调度 + 情境化 alert，减少首页误触「只扫 Current library」的心智。

### Negative

- 需扩展 `libraries` 表或等价持久化 **上次 sync 结果**，供 Home library alert 读取。
- 现有首页 widget/统计测试与 l10n（`homeScanLibrary` 等）需迁移或退役顶栏用法。
- ADR-0014 中「空库 Hero 主行动扫描」被本决策 supersede（建库为主，扫描不再在 Hero 常驻）。
