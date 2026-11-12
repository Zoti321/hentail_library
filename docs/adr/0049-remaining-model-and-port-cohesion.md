# ADR-0049: 剩余 models / ports 按 owner 与可达性内聚

## Status

Accepted（2026-11-12）；离线实施规格见 `.scratch/shared-domain-cohesion/issues/01-shared-domain-cohesion.md`。局部修订 ADR-0035、ADR-0045、ADR-0048。

## ADR-0050 修订（2026-11-12）

本 ADR 的模型归属与禁止边判据保持。下文“其余 11 个 ports 不迁移”指 owner 判定，不再要求保留接口/Adapter 形式或旧目录名：单动作已拆 Command/Query，进度公开共享 StreamProvider，ReaderLaunch 使用 AppNavigator；共享契约见 `shared/domain/contracts/`，UI 签名见 `shared/ui/contracts/`。不新增 public 环、shared/core 反向边或架构豁免。

## Context

Comic、Series 与 Comic metadata 实体归位后，共享模型仍混合模块专用词汇、真正的跨模块协议与旧持久化兼容代码。双模块消费不等于没有 owner；同样，不能仅因为实现归某模块就迁移契约，必须先核查禁止边、public 环与 shared/core 消费者。

## Decision

- `SerializationStatus` 归 `series/domain/value_objects/`；只通过 series 的窄 public 面供外部使用，wire 名称及未知值回退不变。
- `ContentRating`、Comic Language 辅助、`LibraryAuthorPick`、`LibraryTagPick` 归 `comic/domain/value_objects/`，由 `comic/public/comic_metadata_types.dart` 暴露。pick 是 Comic 查询契约的输入，由 comic 解释，browse 只是组装方。已有 `browse → comic` 方向可达，因此取代 ADR-0048 仅因双消费留 shared 的结论。
- `contentRatingLabel` 从 core 本地化辅助归 comic 的 public 本地化扩展，消除 core 的业务枚举依赖，不增加 core → feature 边。
- `ResourceFormatCategory` 与解析、默认、去重、编码及全关确认规则归 `library_admin/domain/`。app_settings 的旧载荷读取仅传输 `({Object? enabledFormatGroups})?`：外层 `null` 表示没有可读取载荷，record 内 `null` 表示旧载荷未配置该键。空列表与未知/非法值原样传输，由 admin 按原规则解释；保留已有暂存键的兼容性，不建立 `app_settings → library_admin`。
- `RemoteLibraryCredentialsPort`、token 及现有实现归 `library_admin`，调用方经 owner public 契约与 token 使用，bootstrap 负责注入。当前唯一实现持有 library_admin 仓库；旧“无单一生产者”理由已不成立。comic / reader 到 admin 的边可达且无环，shared 不再转发 token 或契约。
- `ResourceType` 的 wire 映射归 `shared/data/frb/`，领域词汇本身仍在 shared；reader 无需依赖 comic，映射仍只有一份。

以下模型继续共享：分页协议、`ResourceType`、`ThumbnailPriority`、`LibraryDisplayTarget`、`AuthorRef`、`SeriesItemMembership`。其中缩略图优先级和作者引用仍被 shared UI / slot 消费；浏览目标同时被设置、Comic 查询与 shared 分页消费；系列成员投影服务于被禁止直接互引的 comic / series。

其余 11 个 ports 不迁移：`AppNavigator` 为宿主协议；`LibraryBrowseFallbackPort` / `LibraryReorderModePort` 有 shared 消费者；`AuthorDetailPort`、`ComicReadLookupPort`、`ReaderLaunchPort`、三个 Series Port 受禁止边约束；`ComicTrashCommandPort`、`ReadingHistoryProgressPort` 迁 owner 会形成环。阅读进度实际由 comic 的进度投影消费，而 reading_history 已依赖 comic，取代旧 ADR 的 browse/reader 消费描述。

## Consequences

跨模块仍只经 owner public；不可达协作契约仍留 shared，由 owner 实现与 bootstrap 接线。命令/查询不改成事件总线请求，既有领域事实仍由事件传播。没有新增模块、Port、DTO 副本、baseline 或 allowlist。

结构与运行时验证复用现有架构/DI 门禁及领域、mapper、public、阅读用例测试。资源格式测试从旧 JSON 与暂存载荷出发，经真实设置仓库和库状态加载，验证最终每库配置及一次性迁移；语言与 wire 测试随真源职责归位，保持快轨覆盖。
