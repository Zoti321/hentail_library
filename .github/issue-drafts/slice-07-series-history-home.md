## Parent

#1

## What to build

经 FRB 暴露：`infer_series()`（原子：读未归属 Comic → 推断 → 写 Series）、阅读历史 CRUD/watch、`get_home_page_counts`。系列推断逻辑与黄金 `series_inference.json` 对齐。Dart 删除对应 UseCase，Repository 薄包装。

## Acceptance criteria

- [ ] UI 可触发 Series inference 并看到系列创建/归入结果
- [ ] Standalone read / Series read 进度写入后可在历史页看到
- [ ] 首页统计与现网语义一致（含 Healthy mode 相关计数逻辑在 Rust 或 filter 参数中一致）
- [ ] Rust `infer_groups` golden 与 fixture 全部通过

## Blocked by

- SeaORM 接管 SQLite 与 Comic 库浏览 API issue
