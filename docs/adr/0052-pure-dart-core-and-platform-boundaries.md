# ADR-0052: 保留纯 Dart core，按 owner 分离共享协作与外部实现

## Status

Accepted（2026-11-12）。补充 ADR-0051，修订 ADR-0003、0004 的 Dart 日志落点与 ADR-0044 的 UI 文案归属说明；不修改既有跨 feature 禁止边、public-only、无环或 Provider 覆盖规则。

## Context

`app/lib/core` 原来同时包含通用算法、产品路由、异常、Flutter 配置与系统操作。日志初始化甚至反向引用基础设施，界面又直接创建文件导出实现。目录名与依赖方向不一致，单看直接 import 或信任第三方包名也无法证明内层独立。

## Decision

- 保留 `app/lib/core`，只接收与本产品无关且有实际消费者的纯 Dart 基础能力。本轮保留集合编辑、字节格式、节流、防抖与版本比较；两个下载 owner 共用的取消令牌从 `shared/application` 迁入 `core/async`。无生产调用的 Dart 自然排序副本及其独立测试退役；没有为保留它而改变产品排序，资源排序仍由 Rust 负责。
- core 不依赖 Flutter、Riverpod、`dart:io`、FRB、插件，以及应用内其他目录。第三方依赖必须检查所有 import/export/part（含条件分支）、完整运行时依赖声明及这些包的库源码。当前 core 只有 Dart SDK 依赖。`pinyin_pro_flutter` 虽然导出纯计算 API，但运行时声明依赖 Flutter，因此 UI 名称筛选迁入 `design-system/filtering`，不进入 core。
- `shared/domain` 继续承载现有共享内核、值对象与事实；`shared/application` 承载产品协作签名、应用错误包络和产品日志入口；`shared/presentation` 负责 Riverpod 适配；`shared/ui` 承载产品 UI 协作、路由展示辅助、窗口标题和图像缓存/解码配置。业务有明确 owner 时不因调用者多而进入 shared。
- `AppRoutes` 是宿主与多个 feature 共用的纯 Dart location 协作词汇，放 `shared/application/navigation`；`LibrariesRoutes` 等高亮和删除后导航辅助放 `shared/ui/navigation`。go_router 实现继续归宿主。更新常量、更新包/Release 打开、日志导出及脱敏规则归 `app_settings`。阅读器专用图像预算回归 reader。
- 生成的全应用 UI 文案放 `design-system/l10n`，由 `app/l10n.yaml` 与 `app/l10n/*.arb` 生成。design-system 本身属于共享 UI 层（ADR-0044），输入、日历和页头直接消费这份文案，保持原语言和可访问性语义。BuildContext 的共享适配在 `shared/ui/l10n`；问候语、阅读历史时间、Series 卷数展示扩展分别归 home、reading_history、series（browse 使用 series 的既有窄 public 入口）；无消费者的路由标题辅助退役。不让 design-system 反向依赖 shared/ui，不新增允许边。
- `AppException` / `ValidationException` 是面向应用调用方的错误包络，在 `shared/application/errors`；`DomainException` 继续独立表示领域不变式，不与应用错误统一继承。FRB 操作错误为基础设施内的 `FrbOperationException`，Library sync 进度失败为 owner 的 `LibrarySyncException`；两者仍继承 AppException，保留 message/cause/stackTrace。无调用的 NotFound/Conflict 异常声明退役。
- `shared/application/logging/AppLog` 保留原 logger 名称和 error/stack 参数。文件写入、轮换、Flutter 控制台与 Rust 诊断设置归顶层 `infrastructure/logging`；日志纯脱敏规则归 `app_settings/application/diagnostics`，文件枚举、平台信息和 zip 导出归该 owner 的 infrastructure。初始化与监听装配归 `composition/logging_composition`。导出先 flush，再读日志，保留白名单、manifest、脱敏选项和 isolate 压缩。
- 顶层 `infrastructure` 只包含跨 feature 的技术实现，不认识 feature。系统文件浏览实现归 `infrastructure/platform`；UI 消费纯命令与 required Provider。更新打开、诊断开关和导出也以函数契约注入，不为薄函数新增服务桶或 Repository。所有生产绑定在组合根；presentation 不直接依赖基础设施，domain/application 不能经转发间接到达外层。
- 不保留旧路径导出兼容层；移动原测试并同步 manifest，保留原断言。新增日志轮换/flush、取消语义、组合根依赖和门禁绕过用例。自然排序的四个测试随无消费者代码移除，与放宽门禁无关；其余既有测试不降级。

## Gates

`test/architecture/clean_architecture_dependency_test.dart` 用 analyzer AST 遍历 directives，检查 core 完整依赖图、domain/application/contracts 的递归纯 Dart 性，以及各层与组合根方向。`dart_dependency_graph_test.dart` 验证相对 barrel、条件分支、声明中的传递 Flutter 依赖、未从入口导出的包源码及循环依赖。扫描找不到文件或包时失败；不以忽略缺失路径获得通过。现有模块/public/Provider 门禁和 baseline 保持不变。

## 保留的共享中转与后续建议

本轮核对的 shared/application/contracts 与 shared/presentation/providers 仍有实际消费者：`reader` 需要 `comic_read_query_provider`，但 reader → comic 是已有禁止边；`comic`/`series` 详情消费 `series_reading_context_providers`、`series_item_membership_providers` 等协作面，而 comic → series 禁止。组合根的 `composition/modules/comic/comic_read_query.dart` 和 `feature_state_overrides.dart` 负责把 owner 能力接入这些共享契约。shared UI 的目录浏览、详情槽位也实际消费对应 token，不能单按生产者归属移动。

这些落点带有既有模块依赖约束的成本。后续若调整禁止边，应逐项核对 shared UI 消费、public 图的环和 Provider 覆盖，再考虑将纯 owner token 收回；本轮不以搬迁 core 为由开放边，也不增加业务中转。
