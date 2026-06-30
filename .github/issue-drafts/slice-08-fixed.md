## Parent

#11

## What to build

移除 Drift 与全部 Dart 数据服务；移除 `auto_detect_content_rating` 及首页入口。`pubspec` 去掉 drift。确认仅 Rust 打开 `my_database.sqlite`。更新协作文档；大爆炸发版检查清单。

## Acceptance criteria

- [ ] 仓库无 `drift` / `drift_flutter` 依赖
- [ ] `app` 无 `AppDatabase`、DAO、旧 scan/read service 引用
- [ ] 无 `AutoDetectComicContentRating` 服务与首页按钮
- [ ] `cd app && flutter test` 与 `cd core && cargo test --workspace` 全绿
- [ ] `docs/agents/rust-migration.md` 与 PRD 描述一致

## Blocked by

- #15
- #16
- #17
- #18
