# Architecture Decision Records

本目录存放 **架构决策记录（ADR）**：记录「为什么」做出某个技术或结构选择，供后续开发与 Agent 技能参考。

## 何时写 ADR

满足以下三点时再新增 ADR（参见 `docs/agents/domain.md`）：

1. 做出了有长期影响的架构或技术决策
2. 备选方案曾认真权衡过
3. 未来维护者可能质疑「为什么当初这样选」

日常功能改动、小重构、命名调整不需要 ADR。

## 文件命名

```
0001-<short-kebab-title>.md
0002-<short-kebab-title>.md
```

编号递增；标题用英文 kebab-case，便于引用（如「见 ADR-0001」）。

## 模板

```markdown
# ADR-0001: 标题

## Status

Accepted | Superseded by ADR-000N | Deprecated

## Context

当时面临的问题与约束。

## Decision

我们决定……

## Consequences

### Positive

- …

### Negative

- …
```

## 索引

| ADR | 标题 | 状态 |
| --- | ---- | ---- |
| [0001](./0001-comic-identity-via-path.md) | Comic 身份锚定资源位置键 | Accepted（修订：含 WebDAV URL） |
| [0002](./0002-rust-core-via-frb.md) | Rust 核心层经 FRB 接管数据与 I/O | Accepted |
| [0003](./0003-unified-dev-logging.md) | 统一开发期日志（Dart `logging` + Rust `tracing`） | Accepted |
| [0004](./0004-production-diagnostics.md) | 生产诊断与用户支持（日志导出） | Accepted |
| [0005](./0005-unified-read-session.md) | 统一 Read session（仅 comicId；废弃系列阅读进度） | Accepted |
| [0006](./0006-series-item-sort-order-lock.md) | Series item sort order lock（Komga 式手动排序） | Accepted |
| [0007](./0007-metadata-field-locks.md) | Comic / Series metadata field locks（Komga 式） | Accepted |
| [0008](./0008-multi-library-and-webdav.md) | 多 Library 与 WebDAV Remote library | Accepted |
| [0009](./0009-library-sidebar-pin-and-order.md) | Library pin 与 sidebar order 落在 libraries 表 | Accepted |
| [0010](./0010-windows-app-data-profile-isolation.md) | Windows 上按构建变体隔离 App data profile | Accepted |
