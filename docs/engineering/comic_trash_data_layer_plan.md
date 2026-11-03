# comic_trash 数据层归属规划

**状态**：Phase R-FRB + Dart Phase A/B/C 已实施（2026-11-03）  
**背景**：回收站 FRB 已迁至 `api/comic_trash.rs`；`ComicTrashRepositoryImpl` 在 owner `data/`，browse 不再实现 trash。  
**参照**：`metadata_backup`（`data/repositories` + `data/adapters` + `data/mappers` + feature `di`）、ADR-0034、ADR-0023、ADR-0026、`docs/engineering/cross-feature-collaboration.md`。

---

## 1. 目标与 non-goals

### 目标

- **Owner 清晰**：`comic_trash` 拥有 `ComicTrashRepository` 的 FRB 调用与 DTO→域映射。
- **browse 减耦**：`library_browse` 不再 import `comic_trash/public` 做 trash 持久化；删书进回收站仍经 `ComicTrashCommandPort`（已有）。
- **Rust/FRB 边界与 Dart feature 对齐**：允许并**优先评估** Rust API 拆分，使生成代码与 `comic_trash` / `library_browse` 模块一一对应（见 §5）。

### Non-goals

- 新建回收站表或改动 ADR-0023 产品语义（`deleted_at` 列、visibility 谓词、purge 逐本事务等保持不变）。
- 把 `hentai_core::comic::trash` 业务逻辑迁出 `core` crate（**已**在 `core/crates/core/src/comic/trash.rs`，结构合理）。
- 解决「封面 cache / `ComicCoverContent`」对 `library_browse` 的 presentation 依赖（已 baseline；可选后续 shared 化）。

---

## 2. 现状切片

### 2.1 Dart

| 能力 | Dart 入口 | FRB 生成（今日） |
| --- | --- | --- |
| trash / restore / purge | `ComicRepositoryImpl` | `src/rust/api/comic.dart` → `trashComicsFrb` 等 |
| 已删除列表/计数/id | 同上 | 同上 |
| 域映射 | `comic_frb_mapper.dart`：`mapTrashedComic*` | `TrashedComicFrbDto` 内嵌 `ComicDto` |

**注入**：`data_overrides.dart` 中 `comicTrashRepositoryProvider` 与 `comicLookupRepositoryProvider` 均 `overrideWith` 为 **同一** `const ComicRepositoryImpl()`。

### 2.2 Rust（核心已分层，FRB 未分层）

| 层 | 位置 | 说明 |
| --- | --- | --- |
| 领域/持久化 | `core/crates/core/src/comic/trash.rs` | `trash_comics`、`purge_comics`、`fetch_trashed_comics_page` 等；`library_write` 单飞 |
| 可见性 | `comic/visibility.rs` | ADR-0023 集中谓词 |
| FRB 暴露 | `core/crates/flutter/src/api/comic.rs` | trash DTO + 7 个 `*_frb` 与 catalog API **同文件** |
| 集成测 | `core/crates/core/tests/comic_trash.rs` | 行为钉在 Rust，与 Dart owner 无关 |

**结论**：动 Rust **不必**重写 trash 业务；**值得动**的是 FRB 模块划分（以及可选 DTO 瘦身），以降低 Dart 跨 feature mapper 耦合。

---

## 3. 目标结构（Dart）

```text
features/comic_trash/
  data/
    adapters/          # guardFrb + 调用 rust/api/comic_trash.dart（§5）
    mappers/           # mapTrashedComic*；Comic 聚合映射见 §5.2
    repositories/
      comic_trash_repository_impl.dart
  di/
    comic_trash_repository_provider.dart
```

`library_browse`：仅 catalog/lookup/user-meta；**零** trash FRB import。

---

## 4. 实施路径对比

| 路径 | 做法 | 优点 | 缺点 |
| --- | --- | --- | --- |
| **A. 仅搬 Dart** | 仍 import `api/comic.dart` trash 符号 | PR 小、无 codegen | browse 与 trash 共享巨大 `comic.dart`；mapper 仍依赖 `mapRustComic`（browse/shared 扯皮） |
| **B. FRB 拆分（推荐）** | 新增 `api/comic_trash.rs` → `comic_trash.dart` | 与 `metadata_backup` 一致；gate 白名单按 feature 文件；browse **物理上**无法误绑 trash API | 需 FRB 再生成 + 删/迁 `comic.rs` 中 trash 符号（§5.3） |
| **B+ DTO 瘦身（可选）** | 列表项不用完整 `ComicDto` | trash mapper **不**依赖 catalog mapper；列表 FRB  payload 更小 | 需定义 `ComicListSummary` 或 trash 专用 summary DTO；Dart `TrashedComic` 仍持 `Comic`（由 summary 映射，字段子集须覆盖 UI + restore 流程） |

**推荐顺序**：**B（必做）→ Dart Phase A/B（§6）→ B+ 仅当 summary 映射仍嫌重时做**。

---

## 5. Rust / FRB  redesign（推荐细节）

### 5.1 新增 FRB 模块 `api/comic_trash.rs`

对齐 `api/metadata_backup.rs`：

- 在 `core/crates/flutter/src/api/mod.rs` 增加 `pub mod comic_trash;` 与 `pub use comic_trash::*;`（或仅 re-export 需要的符号，避免根 namespace 膨胀）。
- 从 `api/comic.rs` **迁出**：
  - DTO：`TrashedComicFrbDto`、`PagedTrashedComicResultFrbDto`、`TrashedComicCountsFrbDto`、`ComicPurgeResultFrbDto`
  - 函数：`trash_comics_frb`、`restore_comics_frb`、`purge_comics_frb`、`fetch_trashed_comics_page_frb`、`count_trashed_comics_frb`、`list_trashed_comic_ids_frb`
- 实现仍 **一行委托** `hentai_core::trash_comics` 等（`comic/trash.rs` 不变）。

**Dart 生成物**：`app/lib/src/rust/api/comic_trash.dart`（FRB 默认按模块分文件时）。

**Feature import 规则**：

- `comic_trash/data/**` → 仅 `comic_trash.dart`
- `library_browse/data/**` → 仅 `comic.dart`（无 trash 符号）

### 5.2 DTO 形状（两档，择一）

**档 1 — 保持 `TrashedComicFrbDto { comic: ComicDto, ... }`（拆分 FRB 即可）**

- Dart：`comic_trash/data/mappers` 仍调用 **`mapRustComic`**。
- 将 **`mapRustComic` + 时间戳 helper** 抽到 `shared/data/frb/comic_entity_mapper.dart`（或 `library_browse/data/comic/` 仅 re-export 给 shared），使 trash **不 import browse feature**（符合 ADR-0035 Catalog 真源在 shared 的方向）。
- Rust 无行为变更。

**档 2 — 列表用 Summary DTO（更优，可选）**

在 `comic_trash.rs` 定义例如：

```rust
pub struct TrashedComicRowFrbDto {
    pub comic_id: String,
    pub title: String,
    pub path: String,
    pub resource_type: String,
    pub page_count: i32,
    pub created_at: i64,
    pub last_updated_at: i64,
    // 列表/封面/ badge 足够；facet 列表省略
    pub deleted_at: i64,
    pub library_name: String,
    pub library_kind: String,
}
```

- `fetch_trashed_comics_page_frb` 返回 `Vec<TrashedComicRowFrbDto>`（或在 Rust core `TrashedComicDto` 增加 `from_comic_summary` 构造）。
- Dart mapper 在 **comic_trash** 内组装 `Comic(...)` 最小字段 + `TrashedComic` record，**零** browse 依赖。
- **注意**：若 UI 后续要在回收站展示作者/标签，要么扩展 summary 字段，要么改回嵌 `ComicDto`；应用 YAGNI，当前 MD3E 列表仅标题+封面+库名。

**命令 API**（trash/restore/purge）保持 id 列表即可，无需改签名。

### 5.3 迁移与兼容

| 步骤 | 动作 |
| --- | --- |
| 1 | 添加 `comic_trash.rs` + FRB codegen；Dart 侧新增 `comic_trash.dart` |
| 2 | `ComicTrashRepositoryImpl` 切到新 import；browse 删除 trash 方法与 mapper |
| 3 | 从 `comic.rs` **删除**已迁出的 trash FRB（避免双入口）；全仓 grep `trashComicsFrb` / `TrashedComicFrbDto` |
| 4 | `core` 集成测 **不变**（仍测 `hentai_core::trash_comics`） |
| 5 | 更新 `import_boundary` / FRB data 层白名单：`features/comic_trash/data/**` |

**不建议**：长期保留 `comic.dart` 里 deprecated wrapper 调用 `comic_trash.dart`（FRB 双注册增加 wire 面）；单 PR 原子切换即可。

### 5.4 Rust core 可选微调（非必须）

- 在 `lib.rs` 增加 `pub use comic::trash::*` 的别名模块文档，或 `hentai_core::comic_trash`  re-export —— **纯命名**，对 Dart 无必要。
- **`is_comic_trashed`** 已存在；若未来 read_session 要在 Rust 侧早失败，已满足 ADR-0023。

---

## 6. Dart 分阶段（在 §5B 之后）

### Phase A — Repository 归属

1. `ComicTrashRepositoryImpl` + mappers + adapter（调用 **`comic_trash.dart`**）。
2. bootstrap：`comicTrashRepositoryProvider` → `ComicTrashRepositoryImpl()`；lookup/catalog 仍 `ComicRepositoryImpl()`。
3. 短期 browse impl 可 delegate trash 接口到同一 impl，便于对比测试；**Phase B 前去掉**。

### Phase B — browse 剥离

1. `ComicRepositoryImpl` 去掉 `ComicTrashRepository`。
2. 删除 browse mapper trash 段与 `comic_trash/public` import。
3. Gate：browse→trash public 边应消失。

### Phase C — adapter 规范化

- [x] `ComicTrashFrbAdapter` + 可注入 `ComicTrashRepositoryImpl`（对齐 metadata_backup）。
- [x] `createComicTrashRepository()` 经 `public/di` 导出；bootstrap 经 `comic_trash/public.dart` 接线。

**未做（可选）**：档 2 Summary DTO（列表 FRB 瘦身）。

---

## 7. 风险与缓解

| 风险 | 说明 | 缓解 |
| --- | --- | --- |
| FRB 再生成冲突 | 大 PR  touch `frb_generated` | 单独 commit「Rust FRB 拆分」；跑 `scripts/setup-dev` / gate Rust 段 |
| `mapRustComic` 归属 | 档 1 需 shared mapper | 与 ADR-0035 一致；档 2 可推迟 shared 抽取 |
| 双 Repository 实例 | lookup vs trash 不同 impl | Phase B 后仅 trash 绑 `ComicTrashRepositoryImpl`；集成测 + 手动删→恢复→purge |
| 删除流回归 | session close + revision | `comic_delete_flow_test`、`comic_trash_service_test`、`core/tests/comic_trash.rs` |
| Public 环 | browse↔trash | browse 不再 import trash；trash data 不 import browse public |

---

## 8. 测试清单

**Rust**

- [ ] `core/crates/core/tests/comic_trash.rs`（回归，无改或仅 DTO 构造辅助）
- [ ] 若档 2：为 summary 列表 SQL 增加断言（页内字段、remote/local 计数）

**Dart**

- [ ] `comic_trash/data/mappers/*_test.dart`（自 browse 迁入）
- [ ] `comic_trash_service_test`、回收站 widget 测
- [ ] `library_browse` mapper 测删除 trash 组
- [ ] `import_boundary_test` + baseline
- [ ] `./scripts/run-gate.sh`

---

## 9. 文档 / ADR

- 产品行为不变：**不必**改 GLOSSARY。
- FRB 模块拆分若合并进主 PR：在 **本文件** 记「已实施」；跨 feature 边界若需正式记录，可增 **ADR 附录**（引用 ADR-0034 owner + ADR-0023 不变）。

---

## 10. 工作量粗估

| 工作包 | 规模 |
| --- | --- |
| **R-FRB**：`comic_trash.rs` 拆分 + codegen + 删旧符号 | 中 |
| **R-DTO 档 2**（可选 summary） | 中（core 列表映射 + Dart mapper） |
| **Dart Phase A+B** | 中 |
| **shared `mapRustComic`（档 1）** | 小～中 |

**建议 issue 序列**

1. `refactor(rust): FRB 拆分 comic_trash API（自 comic.rs 迁出）`
2. `refactor(comic_trash): ComicTrashRepositoryImpl + 切 comic_trash.dart`
3. （可选）`refactor(rust): TrashedComic 列表 Summary DTO`

---

## 11. 决策记录（2026-11-03）

- **允许改 Rust API**：是；优先 **FRB 模块拆分**，core `comic/trash.rs` 保持。
- **默认 DTO**：档 1（嵌 `ComicDto`）+ shared mapper；列表性能/耦合吃紧再做档 2。
