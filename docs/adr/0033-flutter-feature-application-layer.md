# ADR-0033: Flutter feature Application 层（Wayfinder）

## Status

Accepted

## Context

Wayfinder feature 模块已有 `domain` / `data` / `presentation`，但 `*Service`、`*Coordinator` 与交互草稿混在 `domain/`，ViewModel 又承担过多用例编排。ADR-0002 将业务真值放在 Rust；Dart 侧需要一层 **无 Flutter、无 FRB** 的用例编排，且与 glossary 中的 **Application data**（应用数据目录）术语区分。

`shared/application/ports/`（ADR-0027）已承载跨 feature 的 UI 编排契约；feature 内仍缺同级命名层。

## Decision

### 1. 物理目录

- **`features/<feature>/application/`**（**可选**）：用例编排（Service、Coordinator）；可 `async`；禁止 Flutter、Riverpod、FRB。
- **`features/<feature>/domain/`**：纯规则、值对象、本 feature 专用 Repository **契约**。
- **`shared/application/ports/`**：跨 feature UI 命令（可含 `BuildContext`）；与 feature `application` **并存**，职责不同。

术语 **Application 应用层** 指本节 Dart 用例层，**不是** ADR-0019 / glossary 的 Application data。

### 2. 依赖方向（Gate L1，零 tolerance）

- `application` → 本 feature 与 `shared` 的 **domain**（含 `shared/domain/ports`）：允许。
- `application` → `data` / `presentation` / `frb_generated` / `package:flutter*`：禁止。
- `domain` → `application`：禁止。
- `presentation/view_models` → `application`：允许（推荐）。
- 产品 feature 间 import：仍禁止（import boundary ratchet）；跨模块经 shared 契约 + bootstrap。

### 3. 与 MVVM、Rust

- MVVM 与 View 不直连 Repository 不变（ADR-0017）；Repository 调用经 ViewModel → application 或 ViewModel → Repository（薄用例可省略 application 类）。
- 不在 Dart application 复刻 Rust 不变式（批量 patch 语义、扫描等）。

### 4. 迁移

按 #419 子票渐进搬迁既有 Service/Coordinator；交互草稿归 `presentation/`。

## Consequences

### Positive

- 落点可文档化、可门禁；application 单元测试无需 Widget/Riverpod。

### Negative

- 目录层数增加；薄 feature 可不建 `application/`，需 ADR 与 gate 说明可选性。

## References

- ADR-0002、ADR-0017、ADR-0027、ADR-0018
- #419 — spec
