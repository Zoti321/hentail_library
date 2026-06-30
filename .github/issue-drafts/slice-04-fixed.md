## Parent

#11

## What to build

将完整 Library sync 迁入 Rust：`create_sync_handle`、`sync_library`（`Stream<SyncProgress>`）、`cancel_sync`。实现增量扫描（stat 未变跳过 parse、zip 浅解析）、并行 walk/parse、diff、upsert/delete、缩略图生成（512/JPEG85）、`clear_reader_sessions`。Dart 删除 `SyncLibraryUseCase` 编排，扫描 UI 只调 FRB。取消语义：扫描/写库事务前取消不写 DB。

## Acceptance criteria

- [ ] 用户可从 UI 触发 Library sync，进度阶段与现网一致（scanning / writingDb / generatingThumbnails / done）
- [ ] 二次 sync 未变更 Resource 明显快于全量解析
- [ ] 取消扫描后 DB 与 sync 前一致（无部分写入）
- [ ] 新增/删除/保留 Comic 与 Saved path 镜像语义与现网一致
- [ ] 缩略图写入 `ComicThumbnails` 且失效规则使用 source stat

## Blocked by

- #14
