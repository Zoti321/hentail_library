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
| [0001](./0001-comic-identity-via-path.md) | Comic 身份锚定磁盘路径 | Accepted |
| [0002](./0002-rust-core-via-frb.md) | Rust 核心层经 FRB 接管数据与 I/O | Accepted |
| [0003](./0003-unified-dev-logging.md) | 统一开发期日志（Dart `logging` + Rust `tracing`） | Accepted |
