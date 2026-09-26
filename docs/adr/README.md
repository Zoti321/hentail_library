# Architecture Decision Records

本目录存放 **架构决策记录（ADR）**：记录「为什么」做出某个技术或结构选择，供后续开发与 Agent 技能参考。

## 何时写 ADR

满足以下三点时再新增 ADR：

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
| [0011](./0011-tag-dictionary-no-ehtag.md) | 移除 EhTagTranslation 接入，保留通用标签字典导入 | Accepted |
| [0012](./0012-comic-deletion-deletes-local-resource.md) | 用户 Comic deletion 删除 Local Resource；sync / 删库不删盘 | Accepted |
| [0013](./0013-path-migration.md) | Path migration：弱指纹 + Local 库根相对路径 remapping | Accepted |
| [0014](./0014-retire-saved-path-ui-and-api.md) | 退役 Saved path / Selected Paths UI 与 Path API | Accepted |
| [0015](./0015-ios-pdf-via-vendored-pdfium.md) | iOS PDF 经 vendored pdfium 一等支持（去除 stub） | Accepted |
| [0016](./0016-app-preferences-via-shared-preferences.md) | App preference 经 SharedPreferences 持久化（取代 settings.json） | Accepted |
| [0017](./0017-ui-mvvm-presentation-layer.md) | Flutter UI 层 MVVM（Riverpod）命名与 View/Repository 边界 | Accepted |
| [0018](./0018-test-seams-and-ci-tiers.md) | 测试三层缝（Rust 真值 / FRB 线缝 / Dart 薄边）与 CI tier 命名 | Accepted |
| [0019](./0019-application-data-wipe-and-uninstall-options.md) | 应用数据清除与卸载数据选项 | Accepted |
