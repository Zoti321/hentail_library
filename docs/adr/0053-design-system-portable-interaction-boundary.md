# ADR-0053: 本应用设计系统的完整交互职责与独立依赖边界

## Status

Accepted（2026-11-12）。修订 ADR-0027、0044、0047 的 UI 物理职责与公开接口，以及 ADR-0052 的应用 ARB 落点。历史 ADR 保留原始决策；本决策是这些条款的现行修订。跨 feature public-only、禁止边、无环、内层纯 Dart 与组合根绑定规则不变。

## Context

`lib/design-system` 已有主题和复杂控件，但仍直接使用 Riverpod 候选 Provider、go_router 页面和全应用生成 ARB。许多接收属性与回调的搜索框、设置项、卡片和分页又留在 `shared/ui`。原门禁只看直接 import/export，未覆盖条件分支、part 或第三方运行时依赖。声明唯一 barrel 但生产、测试与 Widgetbook 大量深引用，使抽包边界缺乏可执行定义。

## Decision

### 职责

设计系统是本应用完整的视觉和交互系统，不是样式集合，也不是无产品风格的万能 UI 库。承载 M3E 的使用约定、自研或参考 MD3 的实现、主题/token、布局、动效、键盘、焦点、无障碍、组件状态和复杂输入（TagInput、FacetMultiSelect）。允许 `ComicCard` 等有本应用风格的纯展示组件；命名中出现 Comic 不构成业务耦合证据。

组件输入图片/封面 Widget、标题、进度、普通候选列表、加载/错误状态和回调。它不查询漫画、不操作 Repository、不决定应用路由或执行产品流程。第三方 M3E 控件可直接使用，不逐个增加包装层。本轮保留 `lib/design-system`，不新建 package。

`shared/ui` 是产品 UI 协作与适配层，具体保留：

- `catalog/selection`：产品 host 与选择状态，并与退出漫画库重排互斥；不是通用选择控件。
- `catalog/pagination`、`page_size`、`metadata_edit`：领域分页、用户偏好、具体元数据字段锁与回调适配。
- `shell`、`patterns/home`：产品导航 id、选中漫画库、flyout 操作及应用展示读模型；不把漫画库模型泛化成万能导航实体。
- `navigation`、`contracts`、`slots`：AppNavigator、返回目标与跨产品模块界面协作。
- `models/comic_cover_*`、`widgets/element/image`、`image`：本应用图像来源、文件加载、解码和 Reader 缓存适配。卡片本身只接收 Widget；通用 letterbox 和封面像素尺寸解析归设计系统。
- `widgets/feedback/app_snackbar`：只将 AppException 转为用户消息；Snackbar 呈现归设计系统。
- `patterns/metadata_edit/metadata_edit_actions` 只保留 saveAndPop 产品契约；保存/取消按钮与编辑展示外壳归设计系统。`patterns/shared/detail_metadata_chip_rows` 和 `catalog/detail` 保留领域作者引用或导航决策适配。
- `CatalogCoverHero` 只保留漫画/系列身份标签；`CoverHero` 承载设计系统的飞行动画。Reader 专用 chrome 度量回归 reader owner。

### 混合职责拆分

- `FacetMultiSelectField` 是普通 StatefulWidget：接收 `List<T>`、`isLoading`、`hasLoadError`、名称/智能标记解析和重试回调。组件拥有搜索、拼音索引、浮层、选择、键盘、焦点和动画状态；候选加载与 AsyncValue 的 refresh/reload/error 语义在 comic 的 `NamedFacetMultiSelectField` 适配。更新候选只重建浮层，不重置输入或关闭会话。接口没有 Provider、AsyncValue 或伪装的订阅类型。
- `ShellContentLayout`、rail/bar、pane、标题栏和窗口按钮归设计系统；`ResponsiveAppShell` 的 Reader 路由判断、产品导航槽、漫画库选择仍留宿主。`DesktopWindowActions` 接收回调；`infrastructure/window` 执行原生配置、拖动、最小化、最大化、关闭与 OS close 监听，`composition/window_composition` 负责选择和生命周期绑定，生产和 Widgetbook 均由组合根装配。
- 通用 Shared Axis、fade-through 与封面详情淡入留在设计系统。go_router 页面、state/extra 和切卷协议移到 bootstrap 的 `route_transition_pages`。原六处 go_router 集成来源收敛到四处宿主文件。

### 文案与作用域

全应用 ARB 继续来自 `app/l10n/*.arb`，由 `app/l10n.yaml` 生成到 `lib/l10n`。设计系统不能到达这份生成库。`DesignSystemLocalizations` 依据当前 locale 提供原有 zh/en 通用组件文案，业务空态、错误和智能匹配提示由参数提供；不以英文替换中文，不把整个应用文案复制成另一份生成库。

设计系统仍统一 material_ui MaterialLocalizations 的使用约定，日历保留既有固定 en 子树行为。`OverlayRouteScopeSnapshot` 同步捕获宿主本地化 delegate、locale 与主题；在根 overlay 中恢复时无需认识应用 delegate 的类型。这样既支持独立组件，也保留嵌入产品表单的应用文案与语言。

### 可执行公开接口和依赖门禁

`design_system.dart` 是唯一外部入口，每条导出用显式 `show` 选定实际消费符号；生产、测试、Widgetbook 和 integration/tool 均受门禁。不保留旧路径转发。实现使用层内相对依赖，不能反向 import 公共 barrel；实现文件不再层叠 export 其他设计系统文件。material_ui 的 MaterialLocalizations 类型仍是日历内部的窄导出。

设计系统的应用内依赖必须全部留在层内，连 core 也不能成为隐藏的抽包依赖。`design_system_boundary_test` 复用 AST 依赖扫描器，覆盖 import/export/part/part-of、条件分支、相对路径、公开接口的传递依赖与第三方完整运行时声明和库源码。允许真实 UI 包及其运行时依赖闭包，框架 SDK 是可信底座；Riverpod、go_router、window_manager、FRB、应用路由/领域/ARB/组合根等均不能进入。缺失文件与未解析包失败，不使用应用边 baseline 或豁免。

`dart_dependency_graph` 对第三方相对 URI 在 package URI 空间解析，匹配 Dart 对 `..` 在包 lib 根的语义；应用文件仍按真实文件路径检查逃逸。绕过测试同时覆盖条件边、part、隐藏声明、第三方回引应用、缺失文件及平台 SDK。现有 core/domain/application 递归纯度、模块图和 required Provider 装配门禁保持覆盖。

## Alternatives

整目录迁移会把产品协作一起带入；只换路径或隐藏 Provider 类型不能独立使用。立即新建 package 会同时引入构建和资源发布变更，本轮先用严格代码边界实现可提取状态。为所有 M3E 控件增加代理或为封面卡片设计万能实体接口会增加调用复杂度，因此保留实际需要的组件与直接回调。

## Verification

独立组件测试宿主 `test/support/pump_design_system_app` 只使用 Flutter、设计系统和框架本地化，无应用 ARB、ProviderScope 或领域模型。组件交互测试覆盖候选加载/错误/重试、打开浮层时的数据更新、拼音、键盘/IME、清空、智能匹配、焦点及双语语义；宿主测试覆盖产品 Provider 适配、错误消息、导航和窗口回调。Widgetbook 候选预览使用普通本地候选，提供 Loaded/Loading/Error/Empty 状态。

完整验证包括设计系统/架构/组合根/适配测试、完整 Flutter 测试、flutter analyze、DCL、格式、Python 测试盘存工具及单元测试、git diff --check、gen-l10n 和受影响 build_runner。迁出测试按 owner 保留并显式列入 manifest，新增组件测试整体仍走设计系统快轨。不扩大 baseline、DCL 豁免或削减覆盖；具体命令与验证结果记录于工程验证文档。

## References

- ADR-0027、0028、0044、0047、0051、0052。
- `app/test/design-system/design_system_boundary_test.dart`
- `app/test/design-system/design_system_dependency_policy_test.dart`
- `docs/engineering/design-system.md`
