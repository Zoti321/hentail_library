# ADR-0009: Library pin 与 sidebar order 落在 libraries 表

侧栏需要 Pinned / Unpinned 与组内顺序，且 `list_libraries` 为全局列表源（设置、切库与侧栏共用）。Komga 把这套存在多用户 client settings；本应用是单用户，持久化已在 Rust SQLite（ADR-0002）。决定在 `libraries` 表加 `pinned`（默认 true）与 `sidebar_order`（组内整数），新建库 append 到已固定组末尾；拖放即写，不另做 client settings / `app_prefs` / `settings.json`。本切片只影响侧栏展示与列表顺序，不用 pin 过滤 All libraries browse。

### Considered Options

- **`app_prefs` JSON 有序 id 列表**：Library 实体更干净，但每次 list 都要 merge，删库/建库容易漏同步。
- **Flutter `settings.json`**：与 ADR-0002「库数据在 core」不一致，且其它列表拿不到同一顺序。
- **表列（采纳）**：`list_libraries` 直接按「Pinned 再 Unpinned、组内 `sidebar_order`」返回；迁移把现有行标为 Pinned，顺序沿用当时的 `root_path` 序。
