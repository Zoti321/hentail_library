# ADR-0039: 跨 feature 协作 — 命令走 Port，事实走领域事件

## Status

Accepted

## Context

ADR-0034（public only）解决了「谁能 import 谁」，但**同一次写入后的通知**在 Dart 侧仍有多套并行表达：

| # | 机制 | 典型位置 |
|---|------|----------|
| 1 | DI 注入回调闭包 | `library_admin/di/{library_sync,metadata_refresh,comic_metadata_bulk_patch}.dart` 的 `onCatalogRevision` / `onSucceeded` / `onDictionariesChanged` |
| 2 | 命令端口 | `LibraryRevisionSignalPort.notifyExternalChange()` |
| 3 | 伪事件总线（Riverpod notifier 累加版本号） | `shared/di/library_change_bus.dart` 的 `LibraryChangeBus.publish(LibraryChange)` |
| 4 | 数据层 revision 流 | `LibraryRevisionPort.watchRevision()`（SQLite `data_version`） |
| 5 | 领域事件类（已定义、无订阅者） | `features/*/domain/*_events.dart`（`LibraryAdminEvent`、`ComicTrashEvent`、`ReadingHistoryEvent`、`AppSettingEvent`） |

1/2/3/5 都在表达「某件事发生了」，边界模糊：presentation 可直接发布状态变更、订阅方各自 `ref.listen`、新增一条通知要同时改 coordinator 回调与 provider。5 证明事件语义已被认可，但缺一条统一通道落地。

## Decision

### 1. 唯一判定表

| 需求 | 机制 |
|------|------|
| 要它做事，需要返回值 / 可能失败 | `shared/domain/ports/**` 命令 / 查询 Port + `shared/di` token |
| 发生了某事，订阅方未知且可能 ≥0 个 | `DomainEvent`（本 ADR） |
| UI 需按「当前值」重建 | Riverpod 状态（由事件 reducer 投影） |
| 需要 `BuildContext`（导航 / 弹窗） | `features/<owner>/public/ui/**` 命令 |

**事件不替代 Port**：打开 reader、删除进回收站等指令仍是 Port；事件只承载「已提交成功」的事实。

### 2. 物理布局与依赖方向

| 角色 | 位置 | 约束 |
|------|------|------|
| 事件词汇表（sealed `DomainEvent` + 全部子类） | `shared/domain/events/**` | E1：子类只能声明在此（`sealed` 保证 reducer 可穷尽） |
| 发布接口 | `shared/domain/events/domain_event_publisher.dart` | 无 Flutter、无 Riverpod；application 层构造注入 |
| 订阅接口 | `shared/domain/events/domain_event_bus.dart` | `Stream<T> on<T extends DomainEvent>()` |
| 实现 | `shared/data/events/event_bus_adapter.dart` | `event_bus` 包（`sync: true`）；E4：实现只允许在此 |
| Token | `shared/di/event_bus_providers.dart` → `appEventBusProvider` | 只声明，bootstrap override |
| 状态投影 | `shared/di/domain_event_revisions.dart` | 唯一 reducer；消费者 `select` 版本号 |

事件全部经 `shared/domain`，**不产生 public cross-feature 边**，因此不扩大 ADR-0034 的 public 有向图（也不会引入环）。`shared` 仍不得 import `features/*/public/**`（R11 不变）。

### 3. 发布与订阅规则

- **发布点**：`features/*/application/**`（首选）或 `features/*/data/**`，且必须在写入**提交成功之后**；禁止在 FRB 调用 / 事务内部发布。
- **禁止 presentation 发布**（E2）：ViewModel 只调 Port / application 用例。
- **订阅点**：只有 `DomainEventRevisions` 直接 `on<DomainEvent>()`；其他消费者 `ref.watch(domainEventRevisionsProvider.select(...))`，不得各自 `ref.listen` 事件。
- **启动即订阅**：`_AppRoot.build` 首行 `ref.watch(domainEventRevisionsProvider)`，避免发布时 reducer 尚未 build 而丢事件（广播流不重放）。
- 事件只带 id / 标量，不带实体快照；需要当前实体请查 Repository。

### 4. Gate（`app/test/gate/domain_event_rules_test.dart`）

| 规则 | 内容 |
|------|------|
| **E1** | `class … extends/implements DomainEvent` 只允许 `shared/domain/events/**` |
| **E2** | `.publish(` 只允许 `application/`、`data/`、`shared/domain/events/` |
| **E4** | `implements DomainEventPublisher` 仅 `domain_event_bus.dart`；`implements DomainEventBus` 仅 `shared/data/events/` |

### 5. 首批迁移（本 ADR 落地范围）

`LibraryChangeBus` / `LibraryChange` / `LibraryAdminEvent` 删除，替换为：

- 事件：`ComicMetadataPersisted(tagsWritten, authorsWritten, parodiesWritten, charactersWritten)`；
- 发布：`comic/application/comic_metadata_service.dart`、`library_admin/application/comic_metadata_bulk_patch_coordinator.dart`；
- 投影：`DomainEventRevisions{dictionaryRevision, metadataSaveRevision}`；
- 订阅：home counts、字典型 providers、`library_distinct_metadata_providers`、metadata auto backup 改 `select` 版本号。

`LibraryRevisionPort`（SQLite `data_version`）与 `LibraryRevisionSignalPort` **保持原样**：前者是数据层外部事实流，后者是 catalog revision 触发，不属于「写入后通知」这一组。后续批次可把 `LibraryRevisionSignalPort` 也改为事件（`publish(LibraryExternalChangeDetected())`）。

## Consequences

### Positive

- 一次写入只发布一个事件，多个订阅方零耦合；新增订阅方不改发布侧。
- `sealed` + 穷尽 switch：新增事件类型时 reducer 编译失败，强制归位。
- presentation 不再持有通知职责，`LibraryChange` 这类「发布用 DTO」消亡。
- 事件声明在 shared，public 依赖图不增长。

### Negative

- 控制流变间接，`grep` 断链；靠 E1/E2/E4 与 reducer 单点收敛缓解。
- 事件流不重放，订阅方必须在发布前建立（由 `_AppRoot` 预热保证）。
- 事件数量需克制（建议 ≤15 个）；超出说明在模拟消息驱动架构。

## References

- ADR-0017、ADR-0027、ADR-0033、ADR-0034、ADR-0035
- `app/lib/shared/domain/events/`、`app/lib/shared/di/domain_event_revisions.dart`
- `app/test/gate/domain_event_rules_test.dart`、`app/test/shared/di/domain_event_revisions_test.dart`
- `docs/engineering/cross-feature-collaboration.md`
