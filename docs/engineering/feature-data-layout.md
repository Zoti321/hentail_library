# Feature `infrastructure/` 目录与 FRB 薄层命名

**现行目录**：ADR-0051；原 `data/` 已迁为 `infrastructure/`，测试同步迁移。横切实现位于 `lib/infrastructure/`，业务适配仍归 owner。

**相关**：ADR-0002（Rust 真值）、ADR-0017（Repository 在 `infrastructure/repositories/`）、[`library-browse-zones.md`](library-browse-zones.md)（browse 分区）。

## 子目录职责

| 子目录 | 用途 | 文件后缀 |
| --- | --- | --- |
| `infrastructure/repositories/` | Domain 仓储契约的 FRB/平台实现 | `*_repository_impl.dart` |
| `infrastructure/mappers/` | Rust DTO ↔ Dart 模型（无 I/O） | `*_frb_mapper.dart` |
| `infrastructure/adapters/` | 调用 FRB API、Stream、或实现 domain **Port** | `*_frb_adapter.dart`、非 FRB 的 `*_adapter.dart` |
| `infrastructure/services/` | 下载、更新等 Dart 侧服务（可选） | `*_service.dart` |

**禁止**在 `infrastructure/` 根目录新增 FRB mapper/adapter（`metadata_backup` 等历史路径逐步对齐）。纯路径/常量 helper 可暂留 `infrastructure/` 根（如 `metadata_backup_paths.dart`）；Dart 侧 I/O 服务放 `infrastructure/services/`（如 `metadata_auto_backup_service.dart`）。

## `library_browse` 例外（方案 A）

在 `infrastructure/comic/`、`infrastructure/series/` **分区内** 仍允许 `{comic,series}_repository_impl.dart` 与 `{comic,series}_frb_mapper.dart` 同目录；语义等同 `repositories/` + `mappers/`，不再加深一层。

## `infrastructure/`（横切 FRB）

| 子目录 | 内容 |
| --- | --- |
| `infrastructure/frb/` | `frb_call_guard`、`frb_error_mapper`、`frb_zone_guard`（全 app） |
| `infrastructure/events/` | `StreamDomainEventBus`；纯 Dart 事件契约仍在 shared/domain |

新 FRB 映射 **默认进 owner `features/<id>/infrastructure/mappers/`**；跨 feature 协作经 owner **`public/` + port**（如 [RemoteLibraryCredentialsPort]），勿再在 `infrastructure/` 新增 mapper/adapter 目录。

## 迁移 backlog（FRB 深模块）

**已完成**：第一～三批（单域 mapper/adapter、`series`/`reader` 迁出 shared、`remote_credentials` @ library_admin + [RemoteLibraryCredentialsPort]、缩略图 FRB @ `library_browse/infrastructure/comic/`）。**comic_metadata（2026-11-03）**：`public/` + 仓储工厂、`*_frb_adapter`、form listing 自 `infrastructure/repositories/` 回迁；Rust FRB `named_facet` 拆 `management`/`form`/`types`，`parody`/`character` 并入 `named_facet_dictionary`（无单独 `comic_metadata_data_layer_plan.md`，约定见 [`cross-feature-collaboration.md`](cross-feature-collaboration.md)）。
