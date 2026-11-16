# ADR-0043: 导航与路由解耦（抽象导航契约 + 集中式路由表）

## Status

Accepted（2026-11-11）。

## Context

go_router 是实现细节，但迁 Wayfinder 后大量 feature 仍直接：

- `import 'package:go_router/go_router.dart'`，在 presentation 调 `context.go/push/pushReplacement/pop`；
- 内联 `'/comic/...'`、`'/series/...'`、`'/metadata?tab=...'` 等 location；
- 经 `shared/di/app_router_provider.dart` 拿 `GoRouter` 具体类型。

结果形成「导航与路由耦合依赖边」：

- feature 同时依赖路由**框架**与**具体路径表**，换路由库或改路径会波及所有调用点；
- 路径字面量散落，`LibrariesRoutes` / `AppNavigation` / `pageTitleForPath` 各自维护一套字符串；
- `shared/di` 暴露 `Provider<GoRouter>`，把宿主实现泄漏为跨模块契约；
- `shared/ui` 的返回/壳层组件也直接依赖 GoRouter / `GoRouterState`。

## Decision

### 1. 集中式路由表：`core/constants/app_routes.dart`

`AppRoutes` 是 location、`GoRoute.name`、path 谓词与 path builder 的**唯一来源**，只含纯 Dart 常量/字符串，不依赖 Flutter / go_router。

- 路径统一经 `AppRoutes.comic(id)` / `series(id)` / `library(id)` / `metadataTab(tab)` / `readerLocation(query)` 构造；
- `LibrariesRoutes` 保留 library 语义入口，内部委托 `AppRoutes`（旧 API 不破坏）；
- 面包屑文案直接取 `AppRoutes.comicDetailName` / `seriesDetailName`；`pageTitleForPath`、`AppNavigation.activeNavIdForPath` 与路由表同源（`ContentBreadcrumbLabels` 已于 #495 删除）。

### 2. 导航契约：`shared/domain/ports/app_navigator.dart`

`AppNavigator` 只暴露**导航事实**与**导航意图**，纯 Dart：

- 事实：`currentLocation()` / `currentPath()` / `queryParameter()` / `canPop()`；
- 意图：`goHome()` / `goLibrary()` / `goMetadata(tab)` / `pushComicDetail()` / `replaceComicDetail()` / `openReader()` 等；
- 栈：`pop()`；owner 解析出的返回落地页经 `goLocation()`，shared UI 不解析语义。

`shared/di/app_navigator_provider.dart` 仅声明 token；feature 与 shared UI 通过 `ref.read(appNavigatorProvider)` 或 `appNavigatorOf(context)` 下达意图。

### 3. 宿主执行：bootstrap

`GoRouterAppNavigator`（`features/bootstrap/presentation/views/routing/`）是唯一把意图翻译为 go_router 调用的适配器，由 `bootstrapCompositionOverrides()` 注入。`appRouterProvider` 删除。

路由注册仍集中在 `app_router.dart` + `shared_content_routes.dart`；页面转场 `shared/ui/motion/**` 保留 `GoRouterState`，视为**路由集成层**，不承载业务导航意图。

### 4. 门禁：`test/architecture/navigation_routing_coupling_test.dart`

- `go_router` import 只允许出现在路由集成白名单（shrink-only）；
- `features/**` 不得出现 `context.go/push/...`、`GoRouter.of`；
- 导航调用不得内联 `"/xxx"` 字面量；
- `shared/di` 不得再暴露 `GoRouter` 具体类型。

## Consequences

### Positive

- feature 只依赖自身 ID 与 `AppNavigator` 意图，换路由库只改 bootstrap 适配器；
- 路径/路由名一处维护，深链与返回栈语义可单测；
- `shared/ui` 的返回、壳层判断不再依赖 go_router，可在 Widgetbook / 测试注入轻量导航器。

### Negative

- 每个新导航语义需在契约 + 适配器各加一处；
- 读当前 location 的事实查询是命令式接口，需要调用点自行保证重建时机；
- 路由集成白名单需随转场层演进评审。

## References

- ADR-0017、ADR-0027、ADR-0033、ADR-0034、ADR-0039、ADR-0042
- `app/lib/core/constants/app_routes.dart`、`app/lib/shared/domain/ports/app_navigator.dart`
- `app/test/architecture/navigation_routing_coupling_test.dart`、`docs/engineering/gate.md`
