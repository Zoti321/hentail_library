# comic_trash 数据层归属规划

**状态**：规划（未实施）  
**背景**：回收站读写与 FRB 映射仍落在 `library_browse/data/comic/comic_repository_impl.dart` + `comic_frb_mapper.dart`；`ComicRepositoryImpl` 同时实现 `ComicTrashRepository` 与 catalog/lookup 等接口。  
**参照**：`metadata_backup`（`data/repositories` + `data/adapters` + `data/mappers` + feature `di`）、ADR-0034、`docs/engineering/cross-feature-collaboration.md`。

---

## 1. 目标与 non-goals

### 目标

- **Owner 清晰**：`comic_trash` 拥有 `ComicTrashRepository` 的 FRB 调用与 DTO→域映射。
- **browse 减耦**：`library_browse` 不再 import `comic_trash/public` 做 trash 持久化；删书进回收站仍经 `ComicTrashCommandPort`（已有）。
- **Rust 零行为变更（首期）**：仅搬 Dart 层；不拆/不改 `src/rust/api/comic.rs` 中 trash/purge API 签名，除非发现必须共用的 mapper 无法复用。

### Non-goals（本阶段不做）

- 把 trash 表或 SeaORM 模型迁到新 Rust crate（无必要）。
- 合并或拆分 FRB 生成的 `comic.dart` API 文件。
- 解决「封面 cache / `ComicCoverContent`」对 `library_browse` 的 presentation 依赖（已单独 baseline；可选后续 shared 化）。

---

## 2. 现状切片

| 能力 | Dart 入口 | Rust FRB（`src/rust/api/comic.dart` 等） |
| --- | --- | --- |
| trash / restore / purge | `ComicRepositoryImpl` | `trashComicsFrb`, `restoreComicsFrb`, `purgeComicsFrb` |
| 已删除列表/计数/id | 同上 | `fetchTrashedComicsPageFrb`, `countTrashedComicsFrb`, `listTrashedComicIdsFrb` |
| 域映射 | `comic_frb_mapper.dart`：`mapTrashedComic*`、`mapComicPurgeResult` | `TrashedComicFrbDto` 等 |

**注入**：`data_overrides.dart` 中 `comicTrashRepositoryProvider` 与 `comicLookupRepositoryProvider` 均 `overrideWith` 为 **同一** `const ComicRepositoryImpl()`。

**消费者**：

- `ComicTrashService` → `comicTrashRepositoryProvider`（shared token）
- 浏览/删除流 → `ComicTrashCommandPort` / catalog repos（仍可能间接 touch 同一 Rust 事务）

---

## 3. 目标结构（Dart）

```text
features/comic_trash/
  data/
    adapters/          # 可选薄层：guardFrb + rust 调用（对齐 metadata_backup_frb_adapter）
    mappers/           # mapTrashedComic*, mapComicPurgeResult（从 browse 迁入）
    repositories/
      comic_trash_repository_impl.dart   # implements ComicTrashRepository
  di/
    comic_trash_repository_provider.dart # feature 内 Provider（metadata_backup 模式）
```

`library_browse/data/comic/comic_repository_impl.dart`：

- 移除 `ComicTrashRepository` 实现与 trash/purge 方法。
- 移除对 `comic_trash/public.dart` 的 import。
- **`trashByIds` 在 browse 侧**：删除 UI 应只调 `ComicTrashCommandPort`；确认无 browse 代码直接 cast `ComicRepositoryImpl` 调 trash。

`comic_frb_mapper.dart`：

- 保留 catalog/comic DTO 映射；trash 段迁至 `comic_trash/data/mappers/`。
- **`mapRustComic`** 仍被 trash 列表使用（`TrashedComic` 内嵌 `Comic`）→ trash mapper **依赖** browse 的 `mapRustComic` 或 shared catalog mapper（见风险）。

---

## 4. 推荐分阶段（降风险）

### Phase A — 提取实现，单 Rust 入口（推荐先做）

1. 新建 `ComicTrashRepositoryImpl` + `comic_trash_frb_mapper.dart`（复制现有 FRB 调用与映射，不删 browse 旧代码）。
2. Feature `di` 提供 `comicTrashRepositoryProvider`（仅 feature 内）；bootstrap 将 `comicTrashRepositoryProvider`（shared token）改为 `ComicTrashRepositoryImpl()`。
3. `ComicRepositoryImpl` 仍实现 `ComicTrashRepository`，但 **delegate** 到内部 `ComicTrashRepositoryImpl`（或标记 deprecated），保证双路径行为一致。
4. 测试：`comic_trash_service_test`、现有 `comic_frb_mapper_test` trash 段复制/迁至 trash feature；加 **parity 测试**（同一 fake FRB 或 golden DTO 两边结果一致）— 若无法 mock FRB，至少保留 mapper 单测。
5. Gate：`import_boundary` 预期 browse **不再** import `comic_trash/public`（M1 再减）。

**验收**：`flutter test test/features/comic_trash/` + `test/features/library_browse/data/comic/` + `import_boundary_test`。

### Phase B — 从 ComicRepositoryImpl 剥离接口

1. `ComicRepositoryImpl` 去掉 `implements ComicTrashRepository` 与 trash 方法。
2. 确认 `comicTrashRepositoryProvider` 唯一绑定 `ComicTrashRepositoryImpl`。
3. 删除 browse mapper 中 trash 函数；browse 测试只保留 catalog 映射。

### Phase C — 可选 adapter 层

- 若 trash FRB 调用增多，引入 `ComicTrashFrbAdapter`（与 `MetadataBackupFrbAdapter` 同形），repository 只调 adapter + mapper。

### Phase D — 长期（仅当 mapper 依赖恶化）

- 将 `mapRustComic` 抽到 `shared/data/mappers/` 或 `library_browse/public` 只读 re-export（ADR-0035：不在 public 复制 Catalog 实体，只 re-export mapper 函数需谨慎）。
- 或 Rust 侧 `TrashedComicFrbDto` 改为扁平字段，减少 trash→catalog mapper 耦合（**高成本**，最后考虑）。

---

## 5. 风险与缓解

| 风险 | 说明 | 缓解 |
| --- | --- | --- |
| 双实例 / 状态不一致 | 若 lookup 与 trash 误用两个 impl | Phase A 末仍可从 browse impl delegate；Phase B 前全量搜 `ComicTrashRepository` 实现者 |
| `mapRustComic` 跨 feature | trash mapper 需要 Comic 聚合 | Phase A 允许 trash/data **import browse data mapper**（临时 M1）或 duplicate 最小字段（忌） |
| 删除流回归 | trash+close session+revision | 保留 `comic_delete_flow_test`；手动：删→回收站→恢复→永久删除 |
| FRB gate | trash data 层 import `src/rust/api` | 确认 `isFrbImportAllowedSource('features/comic_trash/data/...')`；必要时更新 gate 白名单（#280 模式） |
| Public 环 | browse↔trash | 剥离后 browse 不应再 import trash public；trash data 不应 import browse **public** |

---

## 6. 测试清单（实施时）

- [ ] `comic_trash/data/mappers/*_test.dart`（自 browse 迁出 trash mapper 用例）
- [ ] `ComicTrashRepositoryImpl` 集成测（mock adapter 或 guardFrb 注入点—若无 hook，保持 mapper + service 层覆盖）
- [ ] `test/features/library_browse/data/comic/comic_frb_mapper_test.dart` 删除 trash 组后仍绿
- [ ] `test/gate/import_boundary_test.dart` + baseline ratchet
- [ ] `./scripts/run-gate.sh`

---

## 7. 文档 / ADR

- 行为不变：**不必**改 GLOSSARY。
- 若 Phase B 完成后 browse 不再 re-export trash 类型：**更新**本文件状态为「已实施」，可选短 ADR 附录引用 ADR-0034 owner 边界。

---

## 8. 工作量粗估

| 阶段 | 规模 |
| --- | --- |
| Phase A | 中（~1 PR，主要是搬文件 + bootstrap + 测试） |
| Phase B | 小（删 delegate + 清 import） |
| Phase C/D | 视耦合而定，可选 |

**建议 issue 标题**：`refactor(comic_trash): 下沉 ComicTrashRepository FRB 实现（Phase A）`
