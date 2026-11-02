# Feature `data/` 目录与 FRB 薄层命名

**相关**：ADR-0002（Rust 真值）、ADR-0017（Repository 在 `data/repositories/`）、[`library-browse-zones.md`](library-browse-zones.md)（browse 分区）。

## 子目录职责

| 子目录 | 用途 | 文件后缀 |
| --- | --- | --- |
| `data/repositories/` | Domain 仓储契约的 FRB/平台实现 | `*_repository_impl.dart` |
| `data/mappers/` | Rust DTO ↔ Dart 模型（无 I/O） | `*_frb_mapper.dart` |
| `data/adapters/` | 调用 FRB API、Stream、或实现 domain **Port** | `*_frb_adapter.dart`、非 FRB 的 `*_adapter.dart` |
| `data/services/` | 下载、更新等 Dart 侧服务（可选） | `*_service.dart` |

**禁止**在 `data/` 根目录新增 FRB mapper/adapter（`metadata_backup` 等历史路径逐步对齐）。纯路径/常量 helper 可暂留 `data/` 根（如 `metadata_backup_paths.dart`）。

## `library_browse` 例外（方案 A）

在 `data/comic/`、`data/series/` **分区内** 仍允许 `{comic,series}_repository_impl.dart` 与 `{comic,series}_frb_mapper.dart` 同目录；语义等同 `repositories/` + `mappers/`，不再加深一层。

## `shared/data/`（横切 FRB）

| 子目录 | 内容 |
| --- | --- |
| `shared/data/frb/` | `frb_call_guard`、`frb_error_mapper`、`frb_zone_guard`（全 app） |
| `shared/data/mappers/` | 多 feature 共用的 DTO 映射（迁出前的 `series_*`、`reader_*`、`thumbnail_*`） |
| `shared/data/adapters/` | 跨 feature 进程级 FRB 辅助（如 `remote_credentials_frb_adapter`） |
| `shared/data/repositories/` | Catalog 内核仓储（如缩略图） |

新 FRB 映射 **默认进 owner `features/<id>/data/mappers/`**；仅当 ≥2 个 feature 依赖且短期无法抽 port 时，才放 `shared/data/mappers/`。

## 迁移 backlog（FRB 深模块）

- **第二批**：`series_frb_mapper` → `library_browse/data/series/`；`reader_frb_mapper` → `read_session/data/mappers/` + 拆分 `mapResourceType`。
- **第三批**：`remote_credentials_frb_adapter` → `library_admin` + public port；`thumbnail_frb_mapper` 随缩略图归属定稿。
