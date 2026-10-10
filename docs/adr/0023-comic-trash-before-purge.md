# ADR-0023: 用户删除改为 Comic trash → Comic purge 两段式

## Status

Accepted（部分取代 ADR-0012）

## Context

ADR-0012 规定用户 Comic deletion 立即永久删除 Local Resource，且「不使用系统回收站，以确认对话框勾选闸门表达不可撤销」。实际使用中误删无法挽回，用户要求先进入可恢复状态，再由用户显式永久删除。

约束：

- ADR-0012 中「Library sync orphan 清理与删除 Library 不删盘」「路径安全校验」「Remote 仅清库」仍成立，不应被削弱。
- 系列重建会删除无成员的 Series 记录，若 trash 成员不计入成员则恢复后丢失 Series 用户数据（自定义名、连载状态、字段锁等）。
- 删除改写 Comic 与 Series，与 Library sync / Metadata refresh / Metadata bulk patch 并发会互相覆盖。

## Decision

### 两段式

- 用户主动删除 Comic 改为 **Comic trash**（见 `CONTEXT.md`）：仅标记删除时间，库记录、用户元数据、Metadata field lock、阅读历史、Resource 原样保留。Local 与 Remote library 一致。
- **Comic restore** 清除标记，恢复全部可见性。
- **Comic purge** 仅作用于已 trash 的 Comic，沿用 ADR-0012 的删盘语义（Local 路径校验后删 Resource；Remote 仅清库）。批量 purge **逐本**处理：成功者清库，删盘失败者保留在 trash，汇总结果返回。
- **不**做自动 purge（按天数等），只能用户手动触发。

### 存储与可见性

- `comics` 增加可空删除时间列；非空即处于 trash。不另建回收站表。
- 所有浏览面（Library catalog、Home、搜索、Series 成员与计数、阅读历史、标签/作者等聚合计数）只统计未 trash 的 Comic；Read session 拒绝打开 trash 中的 Comic。
- **系列重建仍把 trash 成员计入成员**，以保留 Series 记录；浏览面隐藏「无可见成员」的 Series，成员数只算可见成员。

### 与 sync / 迁移 / 删库 / 备份

- Library sync 扫描到 trash 中 Comic 的 Resource：视为已存在，照常更新物理字段，**保持 trash**，不复活、不重新导入。
- Resource 消失（或格式分组被取消）：按 orphan 清理移除库记录，不删盘。
- Path migration 保留 trash 状态。
- 删除 Library 连带清除其 trash 中 Comic 的库记录，不删盘。
- 元数据备份导出不包含 trash 中 Comic；导入命中 trash 中 Comic 时照常写回元数据，保持 trash。

### 并发

- Comic trash / restore / purge 均获取 `library_write_lock`，与 Library sync / Metadata refresh / Metadata bulk patch 全局单飞；占用则立即失败、不排队。

### UI（概要）

- 删除入口（库卡片、Comic 详情、Series 成员卡片）先弹**轻量确认**（无勾选闸门、普通样式），执行 Comic trash，成功提示「已移入『已删除』」；详情页删除后照旧返回。
- 侧栏系统区（设置上方）新增「已删除」页：跨全部 Library，按删除时间倒序；单条与多选的恢复 / 永久删除，以及「全部永久删除」。
- Comic purge 保留勾选闸门 + 危险样式按钮（第二遍确认）；文案区分 Local（删磁盘）与 Remote（仅移出库），混选时分别计数。
- Comic restore 不确认，成功 toast。

## Consequences

### Positive

- 误删可恢复；永久删盘仍需显式二次确认，安全性高于 ADR-0012。
- trash 期间用户元数据、阅读历史、Series 用户数据不丢。
- sync / 删库不删盘的既有安全边界保持不变。

### Negative

- 所有 Comic 查询都须过滤 trash，遗漏会导致「已删除的漫画在某处出现」；需集中谓词与 Rust 集成测覆盖。
- trash 中的 Local Resource 仍占磁盘空间，直到用户 purge。
- 系列重建与浏览面对「成员」的口径不同（记录层含 trash，展示层不含），实现需注意。

## References

- `CONTEXT.md` — Comic trash / Comic restore / Comic purge / Comic deletion
- ADR-0012 — 删盘语义与路径安全（被本 ADR 部分取代）
- ADR-0013 — Path migration
- ADR-0018 — 测试三层缝
- ADR-0022 — `library_write_lock` 单飞先例
- ADR-0026 — Library-level write seam（trash / restore 单事务，purge 逐本事务）
