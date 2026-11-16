# ADR-0038: Product module `read_session` 更名为 `reader`

## Status

Accepted

## Context

Wayfinder 模块目录曾命名为 `features/reader/`，与 glossary **Read session**（由 comicId 打开的一次阅读会话）同名。该模块实际拥有完整阅读器：页图 I/O、视口、chrome、设置、系列切卷导航，以及会话生命周期编排。名实不符导致跨 feature 文档与 import 把「会话概念」和「阅读器模块」混为一谈；domain 文件也曾用 `read_session.dart` 存放路由参数而非会话实体。

ADR-0005 已统一 **Read session** 语义（仅 comicId；进度只写 Reading history）。本次不改变该会话模型，只纠正 **product module** 命名与 DDD 名实对齐。

## Decision

1. Flutter Wayfinder product module 路径与门禁模块 id：**`read_session` → `reader`**（`app/lib/features/reader/`）。
2. Glossary：**Reader** = 阅读器 product module；**Read session** = 领域会话概念，owner 落在 `features/reader/domain/`。
3. 跨 feature 启动动词对齐模块：`openReader` / `ReaderLaunchPort`；打开的仍是一次 Read session（ADR-0005）。
4. 命名词典与分层卫生（实体 `ReadSession`、application `OpenReadSessionService` / `CopyPageImageService`、port `NativeReaderPort` 等）随本 ADR 落地；细则见 `docs/engineering/reader-ddd-lexicon.md`。
5. Rust `core/src/reader` **不改名**（已是 reader）。

## Consequences

### Positive

- 模块名与 `ReaderPage` / 阅读器职责一致；会话概念可单独用 `ReadSession*` 表达。
- 减少「路由参数文件叫 read_session」一类名实冲突。

### Negative

- 全库路径与 gate allowlist 一次性迁移成本高；旧 issue / ADR 正文中的 `read_session` 路径需交叉引用本 ADR。

## References

- ADR-0005（Read session 语义不变）
- ADR-0033 / ADR-0034（application 与 public 边界）
- `docs/engineering/reader-ddd-lexicon.md`
