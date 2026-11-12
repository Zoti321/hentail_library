# Cross-feature 协作（Riverpod + ADR-0050 / ADR-0051）

先按 ADR-0045 / ADR-0049 判断可达性：跨模块仅 import owner `public/**`；禁止边、public 无环、shared/core 不反向依赖 feature、R12 现行 facade 规则见 ADR-0051。实现归 owner，`lib/composition/` 只接线。生产 UI 仍以 shared UI/theme 为准。

## 公开入口

`features/<owner>/public.dart` 只汇总以下能力入口；public 文件只导出符号，实现在 owner 对应层。

- `public/contracts.dart`：纯 Dart 类型、Repository/Gateway 接口、Command/Query 签名和纯规则；domain/application 通过它或更窄的类型入口协作。
- `public/providers.dart`：面向消费者的 Riverpod 状态、Command/Query token。持续数据用 watch；一次动作在调用时执行。
- `public/widgets.dart`：页面、组件、UI 展示与交互辅助。
- `public/infrastructure/`：仅跨基础设施的专用映射入口，不经普通 barrel 导出。

工厂、平台绑定和 override 分组归组合根，产品模块不 import composition。原窄 public 路径仍可使用，避免为一个类型引入全部 UI；不要新增 public 实现或导出工厂。

## 选择能力形态

- 执行动作：类型明确的 Command 函数；`ref.read(commandProvider)(...)` 才执行。Provider 构建/重建不写业务数据，闭包在调用时读取当前 Notifier，或绑定稳定的纯 Dart 用例。
- 一次性读取：Query 函数，按调用时取值；不改成 FutureProvider 永久缓存，不随 revision 重建覆盖编辑 seed 或 Reader 会话快照。
- 持续读取：公开 owner 的 StreamProvider / 状态 Provider。消费者 `watch/select`；保留 loading/error/data、首次查询、后续变化与释放。
- 已提交事实：DomainEvent，发布在 application/infrastructure，投影仍经 DomainEventRevisions。`listen` 用于已有状态反应，不建立通用通知网络。
- 真实系统/资源：保留 Repository、NativeReader、ComicPageSource、Clipboard、SyncLibrary、MetadataRefresh 等外部契约。需要拆文件 IO 时用最小 Gateway。

纯 Dart 共享协作签名在 `shared/application/contracts/`；含 BuildContext 的签名在 `shared/ui/contracts/`。owner 可达的契约在 owner domain，窄 public 面公开 token 与类型。shared token 只用于禁止边、public 环或 shared/core 消费者，不能绕过依赖规则。

## 当前入口

- 导航：`shared/presentation/providers/app_navigator_provider.dart` → AppNavigator；Reader 的 `openReader` 便利函数保留 Future 返回语义。作者按 id / 名字分别用 `openAuthorByIdCommandProvider` / `openAuthorByNameCommandProvider`；按名字仍先由 browse 解析 id。默认返回用 `goLibraryBrowseFallbackCommandProvider`，先清除详情返回上下文再回 Home。
- Comic trash：`shared/presentation/providers/trash_comics_command_provider.dart` → `trashComicsCommandProvider`；busy、关闭会话、提交后事件仍由 owner 承担。
- Series：`findSeriesItemMembershipQueryProvider`、`findSeriesReadingContextQueryProvider`、`persistSeriesItemSortCommandProvider` 在共享表现层的协作 token 文件；查询不缓存，排序仍由 series 用例处理锁与事实。
- Reader 元数据：`comicReadQueryProvider` → ComicReadQuery；保留快照、标题 fallback 和批量读取，不穿透 reader ↛ comic 禁止边。
- 进度：history public 的 `recordReadingProgressCommandProvider` / `readResumePageQueryProvider`；封面进度订阅 shared `readingHistoryProgressProvider`。首次读取后监听 history 变化重新查询；comic 的公开进度 token 复用同一 Provider。
- 统计：reading_stats public 的 `homePageCountsProvider(excludeR18)`（autoDispose family）、`readingActivityStatsProvider` 和 `recordReadSessionActivityCommandProvider`。Home 在共享状态之上保留 UI 降频，不重复订阅仓储流。
- Library：admin public 的 `submitLibraryFormCommandProvider`、`deleteLibraryCommandProvider`、`updateLibrarySidebarCommandProvider`；扫描用 start/cancel；元数据刷新用 refreshComic/Series/Library 与 cancel。观察 running、target、busy 等状态用对应 Provider，不通过命令对象 getter 读状态。批量编辑用 `bulkEditComicMetadataCommandProvider`，仍经过已有 busy/备份守卫。
- 重排和详情返回：共享消费者只拿 `exitLibraryReorderCommandProvider`、重排只读状态、`rememberComicReturnSeriesCommandProvider` / `clearComicReturnSeriesCommandProvider`，不持有私有 Notifier。
- 远程凭据：保留 library_admin public 的 RemoteLibraryCredentialsPort 与 token。设置偏好、字典与命名元数据仓储、封面 UI/codegen 仍经各 owner public 能力，不在 shared 增加转发。

## 用例与装配

application/domain 不 import Flutter、Riverpod、FRB、infrastructure 或 presentation。用例接收 Repository、明确函数、领域记录和真实 IO Gateway；UI 留校验展示、文本解析、草稿、mounted、确认弹窗、交互状态。Provider 的用例绑定只依赖抽象契约；外部默认实现由组合根注入。具体编排：Comic 保存先元数据后可选排序；Library 提交保留凭据/改根/设置顺序；加载保留旧载荷迁移与 best-effort 清理；Reader 准备系列顺序、批量标题/fallback 与恢复页；备份 prepare 生成同一载荷的 manifest/preview，确认后 commit。

自动备份执行、并发保护和成功记录归 RunMetadataAutoBackupUseCase；事件监听、debounce、post-frame 与生命周期取消留集成层，文件压缩/写入/保留策略归 Gateway。第二步失败不补偿、不自动重试第一步；不改变 Rust 事务和互斥。

## 验证

测试 seam 是公开 ProviderContainer 行为或纯 Dart UseCase 构造依赖。检查惰性命令、一次调用一次执行、顺序/部分提交、领域事实、流的初值/变化/错误/取消和 bootstrap 运行时装配。架构检查仍见 `app/test/architecture/`、`test/gate/`；快轨清单为 `test/gate/manifest.txt`。
