# core/

Rust workspace：`hentai-core`（业务逻辑）+ `hentai_flutter`（FRB cdylib）。

- `hentai-core`：SeaORM 接管 SQLite、`comic_id`、Comic 读 API
- 集成测试 fixture：`tests/fixtures/drift_v2.sql`

## 开发

```bash
cd core && cargo test --workspace
```

Golden fixture：`tests/fixtures/comic_id_vectors.json`（可用 `cd app && dart run tool/generate_comic_id_vectors.dart` 从 Dart 重新生成）。

FRB 代码生成（在 `app/` 下）：

```bash
cd app && flutter_rust_bridge_codegen generate
```
