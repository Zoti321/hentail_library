# Reader 模块 DDD 命名词典（ADR-0038）

Wayfinder module：`features/reader/`。领域会话概念仍称 **Read session**（ADR-0005）。

## 前缀

| 前缀 | 用于 | 禁止用于 |
|------|------|----------|
| `ReadSession*` | 会话实体、页码 VO、会话规则异常、Application Service | 纯 UI、纯路由参数 |
| `Reader*` / `NativeReader*` | 页 payload、native 资源 port、UI | 冒充会话聚合 |
| `*Service` / `*ApplicationService` | application 用例编排 | domain 规则类型；勿再新增 `*Coordinator` |
| `*ViewModel` / `*Notifier` | 表现层 UI 状态与命令 | 用 Facade/Controller 当页面主心智 |

## 类型对照

| 角色 | 类型 | 层 / 文件 |
|------|------|-----------|
| Product module | `reader` | `features/reader/` |
| 会话实体 | `ReadSession` | `domain/read_session.dart` |
| 打开读模型 | `OpenedReadSession` | `domain/opened_read_session.dart` |
| 打开/页 I/O 编排 | `OpenReadSessionService` | `application/open_read_session_service.dart` |
| 进度/活动用例编排 | `ReadSessionApplicationService` | `application/read_session_application_service.dart` |
| Page image copy 用例 | `CopyPageImageService` | `application/copy_page_image_service.dart` |
| Rust reader 生命周期 port | `NativeReaderPort` | `domain/native_reader_port.dart` |
| 页来源 port | `ComicPageSourcePort` | `domain/comic_page_source_port.dart` |
| Spread 翻页策略 | `SpreadNavigation` | `domain/spread_navigation.dart` |
| Auto-play 边界策略 | `AutoPlayBoundaryPolicy` | `domain/auto_play_boundary_policy.dart` |
| 预取窗口策略 | `PagePrefetchWindow` | `domain/page_prefetch_window.dart` |
| 打开命令参数 | `OpenReaderArgs` | `application/open_reader_args.dart` |
| 跨 feature 启动 | `ReaderLaunchPort` / `openReader` | `shared/domain/ports` + `public/` |
| 页面主 ViewModel | `ReaderViewModel` / `ReaderUiState` | `presentation/view_models/` |
| Chrome 正交状态 | `ReaderChromeNotifier` | `presentation/view_models/`（全屏等；非第二套页面 VM） |
| 预取基础设施 | `ReaderPrefetchNotifier` | `presentation/view_models/`（非页面命令门面） |
| 点击区 | `ReaderTapZone` | `presentation/`（非 domain） |
| 会话规则异常 | `ReadSessionException` | `domain/`（`DomainException`） |
| 页加载失败（用户可见） | `ReadSessionPageLoadException` | application/data 映射（`AppException`） |

## 表现层约定

- 页面根只经 **`ReaderViewModel`** 发命令；**禁止** View 直连 Application Service。
- **不**保留独立 `*Facade` 作为阅读页主聚合；外壳字段用 `readerViewModelProvider.select`。
- 禁止新增阅读页主链 `*Controller` / `*Facade` 命名。

## 文件名

- `domain/read_session.dart` **只**放 `ReadSession` 实体。
- 策略 / Policy / Domain Service / Application Service 文件名与类型一致（见 `ddd-domain-naming.md`）。
