## Parent

#11

## What to build

在 `core/` 建立 Rust workspace（`hentai-core` + `hentai-flutter`），接入 `flutter_rust_bridge`。`app` 的 `main()` 可阻塞调用 `RustLib.init()` 与 `init_db`（可先打开内存库或空连接）。实现 `comic_id` 模块：路径规范化 + SHA1，与现有 Dart 逻辑 bit-exact 对齐；共享 golden `core/tests/fixtures/comic_id_vectors.json`。

## Acceptance criteria

- [ ] `cd core && cargo test --workspace` 通过，含 comicId golden
- [ ] `cd app && flutter run`（或集成测）可完成 FRB init，无运行时链接错误（桌面平台即可）
- [ ] Golden fixture 至少覆盖 Windows/POSIX 路径、尾斜杠、混合分隔符
- [ ] `init_db` 接受 `appDataDir` 与 `dbFileName` 参数（与 Drift `my_database` 对齐）

## Blocked by

- #12
