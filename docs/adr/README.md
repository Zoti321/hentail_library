# Architecture Decision Records

本目录存放 **架构决策记录（ADR）**：记录「为什么」做出某个技术或结构选择，供后续开发与 Agent 技能参考。

协作文档地图：`CONTRIBUTING.md`、`AGENTS.md`。操作步骤（Gate、`gh`）在 `docs/engineering/`；**能测的不写长文**。

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

## 维护约定

### Status

- **Accepted**：现行决策；正文与索引表 Status 列一致。
- **Superseded by ADR-000N**：整篇被后继 ADR 取代时，Status 写清取代关系；索引表同步；正文 Decision 可保留历史语境，但须在 Decision 前或 Status 下用一两句指向现行 ADR。
- **部分被 ADR-000N 取代**：Status 写明被取代的**范围**（例如「用户删除立即删盘」被 0023 取代，删盘安全与 sync 语义仍有效）；正文勿再写已与后继 ADR 矛盾的绝对句。
- **Deprecated**：不再推荐但未写清单一后继 ADR 时慎用；优先改为 Superseded 或 Accepted + 实现修订。

### 实现修订 vs 新开 ADR

- 实现细节、桥接方式、临时指标与代码对齐**不改变**当初 Decision 的「为什么」时，用正文中的 **实现修订** 引用块（`> **实现修订（YYYY-MM-DD）**：…`），风格对齐 ADR-0003、ADR-0015、ADR-0006。
- 需要记录新的长期架构选择、或备选方案曾认真权衡时，才递增编号写新 ADR；勿用实现修订块替代新决策。

### Superseded 与索引

- 索引表「状态」列与正文 `## Status` **同一句话义**；父子 ADR 在双方 References 或 Decision 导读中互链。
- 取代关系以 **编号更大的 ADR** 为现行语义来源；读旧 ADR 时先看 Status 与实现修订。

### 避免过期快照

- Consequences 与「已实现」列表写**稳定事实**（删了哪些模块、用户可见行为），勿写会随 FRB codegen 变化的 **sync/async 入口计数** 等瞬时数字。
- 物理路径、目录分层以 `app/test/gate/` 与 ADR-0027 为准；勿保留 Wayfinder 迁移前的 `ui/features` 用语。

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
| [0012](./0012-comic-deletion-deletes-local-resource.md) | 用户 Comic deletion 删除 Local Resource；sync / 删库不删盘 | Accepted（部分被 0023 取代） |
| [0013](./0013-path-migration.md) | Path migration：弱指纹 + Local 库根相对路径 remapping | Accepted |
| [0014](./0014-retire-saved-path-ui-and-api.md) | 退役 Saved path / Selected Paths UI 与 Path API | Accepted |
| [0015](./0015-ios-pdf-via-vendored-pdfium.md) | iOS PDF 经 vendored pdfium 一等支持（去除 stub） | Accepted |
| [0016](./0016-app-preferences-via-shared-preferences.md) | App preference 经 SharedPreferences 持久化（取代 settings.json） | Accepted |
| [0017](./0017-ui-mvvm-presentation-layer.md) | Flutter UI 层 MVVM（Riverpod）命名与 View/Repository 边界 | Accepted |
| [0018](./0018-test-seams-and-ci-tiers.md) | 测试三层缝（Rust 真值 / FRB 线缝 / Dart 薄边）与 CI tier 命名 | Accepted |
| [0019](./0019-application-data-wipe-and-uninstall-options.md) | 应用数据清除与卸载数据选项 | Accepted |
| [0020](./0020-home-page-multi-library-entry.md) | 首页 reposition 为多库阅读入口 | Accepted |
| [0021](./0021-library-resource-probe.md) | Library resource probe：轻量发现未入库 Resource | Accepted |
| [0022](./0022-comic-metadata-bulk-patch.md) | Comic metadata bulk patch（core 批量用户元数据写入） | Accepted |
| [0023](./0023-comic-trash-before-purge.md) | 用户删除改为 Comic trash → Comic purge 两段式 | Accepted |
| [0024](./0024-author-stable-identity.md) | Author 稳定身份与创作平台外链 | Accepted |
| [0025](./0025-author-platform-image-sources.md) | Author 平台形象解析采用本地可信来源适配器 | Accepted |
| [0026](./0026-library-write-seam.md) | Library-level write seam（库级写的锁与事务边界） | Accepted |
| [0027](./0027-flutter-ui-shell-layout-component-layers.md) | Flutter UI Shell / Layout / Component 四层与 shared 依赖边界 | Accepted |
| [0028](./0028-design-system-theme-extensions.md) | 设计系统主骨架（ThemeExtension + theme_tailor + Widgetbook dev） | Accepted |
| [0029](./0029-design-system-documentation-charter.md) | design-system 目录章程（规划文档、Agent 规范、ui-ux-pro-max 输出） | Accepted |
| [0030](./0030-md3e-lab-freeze-design-system-docs.md) | MD3E Lab 阶段冻结 design-system 文档；Lab 以 Widgetbook + md3e 为准 | Accepted |
