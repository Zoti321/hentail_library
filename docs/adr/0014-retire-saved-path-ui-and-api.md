# 退役 Saved path / Selected Paths UI 与 Path API

多 Library（ADR-0008）落地后，运行时 Path 已是 `libraries` 表上的薄封装，但 Flutter 仍保留 `/paths`（Selected Paths）与侧栏 Library form 双入口，且 `PathRepository.add` 可绕过 Library form 裸建 Local library。产品叙事与 `CONTEXT` 已只认 Library；继续保留路径页会分裂心智并扩大测试面。

## Status

Accepted

## Decision

- 用户侧创建与管理 Library **仅**经 Library form 与侧栏 Libraries；Selected Paths /「路径页」不作产品概念。
- 删除 `/paths`；旧深链 redirect 至 Home。空库 CTA 与 Home hero：主行动 createLocal，次要 createRemote（均弹 Library form）。
- 同一波删除 Dart `PathRepository` / Selected Paths UI，以及 Rust `path` 模块与 FRB path API；不占用 `/libraries`（无尾段），以免与 `/libraries/all`（All libraries browse）混淆。
- **不在本决策内**：ADR-0013 Path migration；`/libraries/all` 聚合浏览实现；`saved_paths` 表/entity 删除；Library FRB sync→async（CRUD 写路径）。

## Consequences

- 无「管库」专页；管理面收敛到侧栏 + Library form。
- 去掉 sync Path FRB 消费面；实现排在明确 P0 之后，可按 ADR → UX/redirect → 删 Dart Path 面 → 删 Rust/FRB path 拆 PR。
- **已实现（2026-09-16）**：`/paths` 改为 `redirect → /home`；空库 CTA 与 Home hero 改为 createLocal + createRemote（经 `LibraryManagementActions`）；删除 `SelectedPathsPage` 及其 widgets、`SelectedPathsPageNotifier`、`PathRepository(+Impl)` 与 `pathRepoProvider`、Rust `core/src/path/`、`flutter/src/api/path.rs`（FRB 绑定已重生成）。user-facing 的最后两处 Path 文案改为 Library 措辞（`libraryLocalAddedToast` / `libraryRemovedToast`）。FRB 入口随之降到 60 sync / 43 async。
- **仍按原决策保留**：`saved_paths` 表与相关 migration / 迁移测试；`RemoveSavedPathConfirmDialog` 的类名（文案已是 Library 措辞，改名可另排）。
- **后续补充**：Library **热读**（`list` / `get_current` / `set_current`）已由 P0-B2 / P1-A3 第一刀改为真 async；Library CRUD 写路径仍不在本决策内，可另排。
