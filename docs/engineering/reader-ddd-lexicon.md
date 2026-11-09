# Reader 模块 DDD 命名词典（ADR-0038）

Wayfinder module：`features/reader/`。领域会话概念仍称 **Read session**（ADR-0005）。

## 前缀

| 前缀 | 用于 | 禁止用于 |
|------|------|----------|
| `ReadSession*` | 会话实体、页码 VO、会话规则异常、Coordinator | 纯 UI、纯路由参数 |
| `Reader*` / `NativeReader*` | 页 payload、native 资源 port、UI | 冒充会话聚合 |
| `*Service` / `*Coordinator` | application 用例编排 | domain 规则类型 |

## 类型对照

| 角色 | 类型 | 层 / 文件 |
|------|------|-----------|
| Product module | `reader` | `features/reader/` |
| 会话实体 | `ReadSession` | `domain/read_session.dart` |
| 打开读模型 | `OpenedReadSession` | `domain/opened_read_session.dart` |
| 打开编排 | `OpenReadSessionService` | `application/open_read_session_service.dart` |
| 进度/活动协调 | `ReadSessionCoordinator` | `application/read_session_coordinator.dart` |
| Page image copy 用例 | `CopyPageImageService` | `application/copy_page_image_service.dart` |
| Rust reader 生命周期 port | `NativeReaderPort` | `domain/native_reader_port.dart` |
| 页来源 port | `ComicPageSourcePort` | `domain/comic_page_source_port.dart` |
| Spread 翻页策略 | `SpreadNavigation` | `domain/spread_navigation.dart` |
| Auto-play 边界策略 | `AutoPlayBoundaryPolicy` | `domain/auto_play_boundary_policy.dart` |
| 预取窗口策略 | `PagePrefetchWindow` | `domain/page_prefetch_window.dart` |
| 打开命令参数 | `OpenReaderArgs` | `application/open_reader_args.dart`（presentation 路由映射） |
| 跨 feature 启动 | `ReaderLaunchPort` / `openReader` | `shared/domain/ports` + `public/` |
| 点击区 | `ReaderTapZone` | `presentation/`（非 domain） |
| 会话规则异常 | `ReadSessionException` | `domain/`（`DomainException`） |
| 页加载失败（用户可见） | `ReadSessionPageLoadException` | application/data 映射（`AppException`） |

## 文件名

- `domain/read_session.dart` **只**放 `ReadSession` 实体。
- 策略 / Policy / Domain Service 文件名与类型一致（见 `ddd-domain-naming.md`）。
