## Parent

#1

## What to build

阅读 I/O 迁入 Rust（现有格式）：`open_reader`、`load_page_list`、`load_page_bytes`、`close_reader`。支持 Resource 类型 dir、zip、cbz、epub；会话内保持 archive 句柄。Dart `ComicPageSource` Repository 改调 FRB；阅读器 UI 可加载页面并翻页。Standalone/Series 进度写入可本切片或下一切片完成。

## Acceptance criteria

- [ ] 四种现有格式均可打开阅读会话并加载至少首页字节
- [ ] 连续翻页无每页重开全文件（会话生效）
- [ ] 阅读器 UI 对加载失败展示可读错误（映射 `HentaiError`）
- [ ] `sync_library` 完成后 reader sessions 被清理

## Blocked by

- SeaORM 接管 SQLite 与 Comic 库浏览 API issue
