# ADR-0033: Flutter feature Application 层（Wayfinder）

## Status

Accepted

## Context

Wayfinder feature 模块已有 `domain` / `data` / `presentation`，但 `*Service`、`*Coordinator` 与交互草稿混在 `domain/`，ViewModel 又承担过多用例编排。ADR-0002 将业务真值放在 Rust；Dart 侧需要一层 **无 Flutter、无 FRB** 的用例编排，且与 glossary 中的 **Application data**（应用数据目录）术语区分。

`shared/domain/ports/` 与 `shared/domain/library/` 中的跨 feature **命令契约**（含部分含 `BuildContext` 的 UI 命令类型；#434 起不再使用 `shared/application/ports/`；2026-11-12 / #530 起 `LibraryManagementPort` 已归 `library_admin`，shared 只留 `LibraryBrowseFallbackPort` 窄口）；消费方 **import owner** `features/<id>/public.dart`（ADR-0034）。feature 内仍缺同级 **用例编排** 命名层。

## Decision

### 1. 物理目录

- **`features/<feature>/application/`**（**可选**）：用例编排（Service、Coordinator）；可 `async`；禁止 Flutter、Riverpod、FRB。
- **`features/<feature>/domain/`**：纯规则、值对象、本 feature 专用 Repository **契约**。
- **跨 feature 命令类型**：定义在 `shared/domain`（ports / library）；**发现面**在 owner `features/<id>/public/`（re-export）；与 feature `application` **并存**，职责不同。

术语 **Application 应用层** 指本节 Dart 用例层，**不是** ADR-0019 / glossary 的 Application data。

### 2. 依赖方向（Gate L1，零 tolerance）

- `application` → 本 feature 与 `shared` 的 **domain**（含 `shared/domain/ports`）：允许。
- `application` → `data` / `presentation` / `frb_generated` / `package:flutter*`：禁止。
- `domain` → `application`：禁止。
- `presentation/view_models` → `application`：允许（推荐）。
- 产品 feature 间 import：**仅** `features/<owner>/public/**`（ADR-0034）；deep import 仍禁止；跨模块契约仍经 shared + bootstrap，逐步迁入 owner public。

### 3. 与 MVVM、Rust

- MVVM 与 View 不直连 Repository 不变（ADR-0017）；Repository 调用经 ViewModel → application 或 ViewModel → Repository（薄用例可省略 application 类）。
- 不在 Dart application 复刻 Rust 不变式（批量 patch 语义、扫描等）。

### 4. 迁移

#419 / #420–#424 已落地：reader、comic_trash、library_admin application 迁移与 library_browse 草稿归位。新用例编排仍按本节落 `application/`。

> **实现修订（2026-11-02）**：Epic [#436](https://github.com/Zoti321/hentail_library/issues/436)（#437–#444）将 purge/阅读/库筛选·管理/Repository/周边 read model 等 **Dart 域真源**迁入各 owner `features/<id>/domain/`；`shared/domain/**` 对迁出符号仅保留 **export-only strangler**（`app/test/gate/strangler_shims.txt`）。Catalog 实体与分页/thumbnail 内核仍 @ shared（**ADR-0035**）。归属表与仍留 shared 的 UI 契约见 [`docs/engineering/shared-domain-ownership.md`](../engineering/shared-domain-ownership.md)。

> **实现修订（2026-11-11）**：漫画封面写入命令从 reader 的 VM 移入 `features/comic/application/comic_cover_service.dart`，经 `comicCoverSetCommandProvider`（`comic/public/di/`）供 reader 调用；封面缓存刷新留在装配层。系列封面仍归 series owner。

## Consequences

### Positive

- 落点可文档化、可门禁；application 单元测试无需 Widget/Riverpod。

### Negative

- 目录层数增加；薄 feature 可不建 `application/`，需 ADR 与 gate 说明可选性。

## References

- ADR-0002、ADR-0017、ADR-0027、ADR-0018、**ADR-0034**
- #419 — spec（已关闭）
