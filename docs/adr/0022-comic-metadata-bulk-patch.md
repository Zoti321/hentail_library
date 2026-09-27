# ADR-0022: Comic metadata bulk patch

## Status

Accepted

## Context

用户常需对多本 Comic 统一补 Tag、Author 等元数据。单本 `EditMetadataDialog` + `update_comic_user_meta` 循环调用可行，但：

- 多值字段的 **添加 / 移除 / 替换** merge 语义应在 core 一处实现，避免 Flutter 逐本读—改—写 duplicated 逻辑与竞态。
- 批量写库应与 **Library sync / Metadata refresh** 互斥（库级写锁），否则批中 sync 可能 merge 扫描结果。
- 大批量需 **可取消**、**逐本 continue**、**unchanged 计数**，行为对齐 Metadata refresh 批处理 UX。

**Metadata field lock**（ADR-0007）防的是扫描/sync/refresh 覆盖，**不**阻挡用户主动写入；批量编辑须能修改已锁字段，保存后改动字段仍 auto-lock。

## Decision

### 领域对象

- 新增 **Comic metadata bulk patch**（见 `CONTEXT.md`）：对同一 Library 内 Comic 集合的稀疏用户元数据变更；仅启用字段参与；未启用字段不写值、不改锁。

### Core API

- 新增 **`apply_comic_metadata_bulk_patch(comic_ids, patch, handle)`**（async，FRB 暴露）。
- 入口 **acquire `library_write_lock`**，与 sync / Metadata refresh 全局单飞；占用则立即失败。
- **逐 Comic 独立事务**：单本失败 continue；`handle.is_cancelled()` 时停止后续，已提交保留。
- **校验**：`comic_ids` 若跨多个 Library → 整批拒绝；不存在 id → 计 `failed`。
- **上限**：Core 硬 cap **2000** ids；超出拒绝。
- **结果 DTO**：`succeeded`、`failed`、`unchanged`（merge 后无实际写库）、`cancelled`、`error_samples`（约 5 条）。

### Patch 与 merge 语义

Patch 仅含用户启用的字段（`Option` / 等价稀疏结构）。MVP 字段：`tags`、`authors`。M2 扩展：`languages`、`parodies`、`characters`、`content_rating`、`description`、`published_at`。

**多值字段**（tags / authors / languages / parodies / characters）每项带操作：

| 操作 | 语义 |
|------|------|
| Add | 追加到列表末尾，dedupe，保序 |
| Remove | 删除 patch 中列出的项；本不存在 → no-op，该本计 `unchanged` 或 `succeeded`（无写库） |
| Replace | 整字段 replace（同 `update_comic_user_meta` 列表语义） |

**标量字段**（M2）：`description`、`published_at` 使用显式 **Replace** / **Clear**，避免空值歧义。`content_rating` 批量仅 **safe / r18**（与单本编辑 UI 对齐，不含 unknown 入口）。

写入路径复用现有 user-meta 写与 **auto-lock** 规则（ADR-0007）：本次实际写入的字段自动 `*_locked = true`。

### 与 Metadata refresh / sync 的边界

| 操作 | 方向 | 数据源 |
|------|------|--------|
| Metadata bulk patch | 用户 → 库 | 用户编辑 |
| Metadata refresh | Resource → 库 | 重解析 + 字段锁 merge |
| Library sync | Resource → 库 | 扫描 + 字段锁 merge + orphan |

Bulk patch **不**重解析 Resource、**不** orphan 删除、**不**改 Series 成员排序、**不**改缩略图。

### Flutter UI（概要）

- **Catalog selection mode**：Library 漫画网格与搜索页；跨页 `Set<comicId>`；换库/筛选/排序/离路由清空。
- **BulkEditMetadataDialog**：稀疏 patch 表单（启用 × 操作 × 值）；N=1 开单本 `EditMetadataDialog`。
- **Series 详情**（M1）：overflow「编辑成员元数据…」直接预填成员 ids，跳过选择模式。
- **Series reorder mode**（ADR-0006 / #121）与 catalog selection mode **互斥**。
- 执行：静态确认摘要 → busy 顶栏 + 取消 → 汇总 toast；批末一次 catalog revision 与 auto-backup debounce。

MVP 无 core plan/dry-run API；确认 dialog 仅静态「N 本 · M 字段」。

## Consequences

### Positive

- Merge、持锁、cancel、跨库拒绝集中在 core，Flutter 只做选择与 patch 编排。
- 与 Metadata refresh 互斥与批结果形态一致，降低用户与实现认知负担。
- 字段锁语义与用户主动编辑一致，不因「已锁」误跳过。

### Negative

- 新 FRB async 面 + Rust 模块；需 Rust 集成测覆盖 merge / lock / cancel / 跨库。
- 逐本事务下 cancel 后批次部分成功，用户须读汇总 toast。
- M2 前标量与 Content rating 批量能力不可用。

## References

- `CONTEXT.md` — Comic metadata bulk patch / Comic metadata form / Metadata field lock
- ADR-0007 — Metadata field locks
- ADR-0006 — Series item sort order lock（reorder mode 互斥）
- ADR-0018 — 测试三层缝（Rust 真值缝优先）
- Metadata refresh 实现：`core/crates/core/src/sync/refresh.rs`、`SyncHandle`
