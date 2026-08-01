# ADR-0005: 统一 Read session（仅 comicId；废弃系列阅读进度）

## Status

Accepted

## Context

领域上曾区分 **Standalone read** 与 **Series read**：入口可带 `seriesId`，进度分别写入 Reading history 与 Series reading history。Series 已由 Library sync 按 Folder series（直接父目录）生成，一本 Comic 至多属于一个 Series。

双模式带来：路由/会话分叉、两套进度语义、系列详情「继续阅读」与 Comic 历史可能不一致。目标是：**阅读不再区分模式**；系列能力改为打开 Comic 后按 comicId 派生上下文。

## Decision

### 会话与入口

- 唯一会话概念为 **Read session**，由 **comicId** 打开（可加无痕等开关）。
- 路由与启动器 **不再接受 `seriesId`**，删除 `ReadSessionMode` / Standalone vs Series 分叉。
- 退出阅读器 **一律** 回到该 Comic 的详情页（`/comic/:id`），不因系列归属改落点。
- 系列详情只列成员 Comic，**不提供**「继续阅读」。

### 进度

- **只保留** Comic 级 **Reading history**。
- **DROP** `series_reading_histories`，并删除对应 core API、FRB、Dart repository/实体；不做系列进度摊回。
- 无痕 Read session：**不读写** Reading history。

### Series reading context

- core 提供按 **comicId** 查询的 API；无归属返回空。
- 最小载荷：`{ seriesId, seriesName, orderedComicIds, currentIndex }`。
- 阅读器在存在 context 时：展示位置、上一卷/下一卷、卷列表跳转。
- 卷列表标题由 Flutter 沿用现有格式（`{序号}-{comic.title}` 等），不在 context API 内携带展示标题。
- 无痕时 **仍加载** context（可导航），仍不写进度。

### 换卷页码

- 切到同系列另一卷（邻卷或卷列表）前：非无痕则 **先落盘** 当前 Comic 的 Reading history。
- 目标卷 **总是从第 1 页** 打开；只有从库/详情/历史等重新打开某 Comic 时才恢复其 Reading history。

## Consequences

### Positive

- 入口与进度模型单一，与「Series 是 Comic 的派生组织」一致。
- 连读导航仍可用，但不引入第二种会话或第二种进度表。
- 持久化面缩小，避免双轨继续阅读。

### Negative

- 既有 Series reading history 数据丢弃；无法再直接「继续该系列上次读到的卷+页」（系列详情本也不再提供该入口）。
- 换卷不恢复目标卷历史页码，可能不符合「接着读下一本上次读到的页」预期（有意简化）。
- 卷列表标题需客户端再解析 Comic；大系列可能多次查标题（可后续优化，不阻塞本决策）。
