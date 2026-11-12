# 设计系统开发与边界验证

现行职责由 ADR-0053 定义。生产 UI 使用 `app/lib/design-system/design_system.dart`；根目录 `design-system/` 的占位和示例图不是实现规范。

## 组件落点

搜索、输入、TagInput/多选、设置项、分页、按钮、指针交互、确认框、纯展示卡片、布局与窗口外观归设计系统。组件接收普通数据与回调，不读取 Repository/业务 Provider、领域对象、应用 ARB 或路由。M3E 可直接使用，不要求每种控件都有本地包装。

`shared/ui` 保留产品导航、当前漫画库/flyout、选择与重排互斥、领域分页/元数据锁适配、图像加载/缓存和产品错误消息。修改留存项时以 ADR-0053 的逐类理由为准，不按“跨多个模块”或目录名判归属。Reader 专属 chrome 布局由 reader owner 维护。

## 公开接口

外部统一 import `package:hentai_library/design-system/design_system.dart`；按使用能力可在调用方加 `show`。入口对每个实现显式列出符号，不通过主题或组件的层叠 export 扩散公开面。内部用相对 import，不 import 入口；不增加旧路径兼容层。新增公开类型需要同步入口、调用方与门禁。

`design_system_boundary_test` 检查生产、测试、Widgetbook、integration_test 和 tool 的深引用，并从所有层内文件检查完整传递图（含条件导入、export、part/part-of 与第三方运行时声明/源码）。应用内出边为零；设计系统不依赖 core。第三方允许真实 UI 包及其运行时依赖，框架 SDK 是可信底座。不要通过 barrel、重命名 Provider 类型或应用“通用适配器”绕过。

## 本地化与宿主效果

`flutter gen-l10n` 读取 `app/l10n.yaml`，应用 ARB 产物在 `app/lib/l10n`。组件通用文案来自 `DesignSystemLocalizations`，保留 zh/en；候选列表的业务空态、错误与智能提示由宿主传参。日历继续使用 `materialLocalizationsOf` / `MaterialUiLocalizationsScope` 的 material_ui 约定。

根浮层在打开时同步 capture `OverlayRouteScopeSnapshot`，保留调用方主题、locale 与 delegate；不要让设计系统 import 应用 delegate。窗口外观通过 `DesktopWindowActions` 回调使用，`composition/window_composition` 把原生实现装配给生产和 Widgetbook。预览没有原生宿主时按钮可保持禁用。

## 行为验证

设计系统组件测试使用 `test/support/pump_design_system_app.dart`，无需应用 ARB、ProviderScope 或领域模型。产品适配测试继续用 `pumpLocalizedApp` / 现有 `pumpApp`。复杂多选需要覆盖打开浮层后候选更新、loading/error/retry、拼音、智能提示、清空、键盘/IME 与焦点；不把这些行为替换成仅扫描源码的断言。

Widgetbook：`cd app && flutter run -t widgetbook/main.dart`。打开 `MD3E (Lab) / widgets / FacetMultiSelectField / Authors · smart hint`，通过 Candidates knob 检查 Loaded、Loading、Error、Empty；验证拼音输入、上下键/Tab/Enter、智能提示及清空。标题栏、卡片、设置项和分页仍使用实际设计系统组件。Widgetbook 页面与应用 ARB 的装配由预览宿主负责。

相关快轨覆盖位于 `test/design-system`（整体）、`test/architecture`、`test/composition` 和 manifest 指定的 owner 适配测试。路由过渡页面测试归 bootstrap，字体偏好适配测试归 app_settings，均保留原快轨覆盖。新增测试按 `docs/engineering/gate.md` 连续三轮后纳入快轨。

运行受影响的 `flutter gen-l10n` 与 `dart run build_runner build`，检查生成文件无漂移；再运行完整 `flutter test`、`flutter analyze`、仓库 DCL、格式、Python 测试盘存工具及其单元测试、`git diff --check`。本次不改 Rust，无需无依据扩大验证到 Rust。

## 本轮验证记录（2026-11-12）

`test/md3e/widgetbook_design_system_test.dart` 实际构建 Widgetbook 目录和预览宿主，通过真实 Candidates knob 分别验证 Loaded/Loading/Error/Empty，并在 Loaded 预览执行拼音、Tab 选择与清空。浏览器启动尝试受应用原有非 Web 图像适配阻挡（`AppComicImage` 的 `dart:io File` 与 extended_image Web 类型不同）；没有为此扩展应用 Web 支持。Widgetbook 的行为证据来自真实 Widgetbook 组件测试，不将静态检查称为视觉验收。

`flutter gen-l10n` 与不带冲突删除选项的 `dart run build_runner build` 已重跑，89 个生成文件 SHA-256 无漂移。最终 Flutter 测试 1221 项通过；`flutter analyze`、仓库 DCL 硬门禁、1603 个 Dart 文件格式检查（0 变化）、Python 盘存工具及其 4 项单元测试、`git diff --check` 全部通过。

隔离验证副本使用离线包解析，包图中不含应用、go_router、Riverpod 或 window_manager，原设计系统源码无需改写 import；14 项组件交互与 zh/en 语义测试全部通过。该副本位于忽略的 `.scratch`，不构成生产 package 拆分。

## 完成审计

1. 职责与实际迁移：`shared/ui` 从 129 个 Dart 文件收敛至 48 个；搜索、设置、按钮、分页、指针、菜单、对话框、卡片、展示 chip、编辑外壳和布局均在真实消费者处改用设计系统。没有整目录机械迁移、逐个包装 M3E 或创建生产 package。
2. 混合职责：候选 Provider/AsyncValue 适配留 comic；控件接收普通数据与状态。go_router page/state/extra 留 bootstrap；通用过渡留设计系统。Snackbar 错误映射留产品层。窗口配置/执行/关闭监听归 infrastructure，由 composition 绑定。saveAndPop 契约留产品层，保存/取消按钮与展示壳归设计系统；适配器无消费者的旧参数已清理。封面身份标签留产品层，通用 Hero 飞行归设计系统；Reader 专属度量回归 owner。
3. 独立边界：递归 AST 门禁覆盖全部 import/export/part/条件分支、第三方声明和源码、公开面的传递依赖；外部只消费显式 show 入口，内部不依赖该入口，不保留旧路径转发。边界回归用例与移除应用包的隔离运行共同证明没有经 barrel 或订阅接口泄漏产品依赖。
4. 本地化与生成：应用 ARB 生成至 `lib/l10n`，所有生产、测试、Widgetbook 与辅助生成脚本调用同步。组件保留 zh/en 原文、可访问语义及错误提示；通用组件无应用 ARB import，产品 overlay 的主题/locale/delegate 在发起时捕获。89 个生成文件重跑 SHA-256 无漂移。
5. 行为：最终完整 Flutter 1221 项通过；真实 Widgetbook 四态预览覆盖 loaded/loading/error/empty、拼音、Tab 和清空；独立控件覆盖候选更新、重试、智能提示、键盘/IME、焦点与语义；产品和平台通道测试覆盖错误文本、选择/导航、窗口关闭保护与回调绑定。独立副本另有 14 项通过。浏览器版预览的既有 Web 图像适配限制已如实记录，未将测试当成截图验收。
6. 既有架构与覆盖：core 纯 Dart、domain/application 递归纯度、composition 外部装配、跨 feature public-only、禁止边、无环及 required Provider 绑定门禁均随完整测试通过。baseline 与 DCL 配置/豁免内容未变。原 220 个快轨文件逐一映射到现存路径，无丢失或降级；现为 227，慢轨仍为 100。4 个测试文件按 owner 单文件移动，新增复杂交互测试已多轮稳定运行。
7. 文档与工作区：新 ADR-0053 明确修订旧决定，历史 ADR 正文未改写；AGENTS、Glossary、Contributor map、Gate 与本开发指南同步。全程保留 `integrate/read`，没有新分支或 worktree；无批量/递归删除。Rust 未改动，按任务范围未扩展 Rust 验证。
