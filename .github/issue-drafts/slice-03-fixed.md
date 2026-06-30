## Parent

#11

## What to build

SeaORM 原地接管现有 SQLite：Entity 对齐 Drift schema v2（snake_case 列名）；种子 migration v2 + 执行 v3（`source_modified_ms`、`source_size`）。经 FRB 暴露 Comic 读 API：`watch_comic_changes`、`fetch_comics_page`（接收 `ComicFilterDto`）、`find_comic_by_id`、`search_by_keyword` 等。`app` 的 `ComicRepository` 改为薄 FRB 包装；库列表 UI 从 Rust 读数据。本切片可不包含 Library sync 与阅读。

## Acceptance criteria

- [ ] 集成测试：用真实 Drift v2 fixture DB 打开后 Comic 行与 comicId 不变
- [ ] `fetch_comics_page` 筛选语义对齐原 SQL（含 showR18、tag、系列排除、关键词）
- [ ] UI 库列表页可展示 Comic 并响应 `watch_comic_changes`
- [ ] Drift 仍可在开发分支并行存在，但本切片验收以 Rust 读路径为准

## Blocked by

- #13
