# core/

Rust workspace：`hentai-core`（业务逻辑）+ `hentai_flutter`（FRB cdylib）。

- `hentai-core`：SeaORM 接管 SQLite、`comic_id`、Comic 读 API、Library sync（扫描/写库/缩略图/取消）
- 集成测试 fixture：`tests/fixtures/drift_v2.sql`

## 开发

**推荐**：在仓库根目录运行 [`../scripts/setup-dev.ps1`](../scripts/setup-dev.ps1)（Windows）或 [`../scripts/setup-dev.sh`](../scripts/setup-dev.sh)（Unix），一次性完成 `rust_builder` 链接与 pdfium 下载。

仅 Rust 侧开发时，可单独获取原生依赖（详见 [`vendor/README.md`](vendor/README.md)）：

```bash
# Linux / macOS / Git Bash
./vendor/fetch-native-deps.sh

# Windows PowerShell
./vendor/fetch-native-deps.ps1
```

```bash
cd core && cargo test --workspace
```

Golden fixture：`tests/fixtures/comic_id_vectors.json`（可用 `cd app && dart run tool/generate_comic_id_vectors.dart` 从 Dart 重新生成）。

FRB 代码生成（在 `app/` 下）：

```bash
cd app && flutter_rust_bridge_codegen generate
```
