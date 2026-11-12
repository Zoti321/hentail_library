# ADR-0051: 整洁架构的组合根、基础设施与内层依赖

## Status

Accepted（2026-11-12）。修订 ADR-0017、0027、0033、0034、0039、0050 的物理目录约定；跨模块禁止边、public only、无环和 Rust 事务真值不变。feature 的混合 DI 目录与 public 中的实现代码已按本决策拆分。

## Context

`shared` 同时承载领域内核、协作签名、FRB、Riverpod 状态与 UI；feature `di` 混合工厂、用例绑定与界面状态。bootstrap 的装配又是一个 feature，导致框架和外部实现容易通过 public barrel 进入内层。只重命名目录不能建立依赖方向。

## Decision

- `lib/composition/` 是应用组合根，入口 `app_composition.dart` 的 `appProviderOverrides()` 由 `main.dart` 调用。负责外部实现选择、跨模块状态桥接和路由槽位接线；产品模块和共享代码不依赖组合根。测试可直接装配局部 override。
- `features/<owner>/infrastructure/` 承载原 `data/` 的 Repository 实现、FRB 映射、平台适配、文件和网络服务；横切 FRB 防护与事件总线实现位于 `lib/infrastructure/`。不建立全 app 的业务仓储桶，owner 仍在 feature。
- `shared/domain/` 只承载有多个真实消费者且不能归于单个 owner 的纯 Dart 领域词汇、规则、值对象和事件。Command/Query/Navigator 等协作签名归 `shared/application/contracts/`，不再归 domain。界面选择、分页和字体映射归 UI / presentation。
- `shared/presentation/providers/` 承载现有共享协作 token 与事件状态投影，是 Riverpod 适配层；不作为新增业务归属。共享 token 仍须证明 owner 不可达、形成 public 环，或有 shared/core 消费者（ADR-0045）。
- domain/application 必须通过完整 import/export 链保持纯 Dart；不能经 public barrel 间接到达 Flutter、Riverpod、路由、FRB、基础设施、表现层或组合根。domain 也不依赖 application。
- feature 不设 `di` 业务层。界面状态和纯用例 Provider 在 `presentation/providers/`；具体外部实现绑定、工厂和跨 feature override 在 `composition/modules/<owner>/`、`platform_overrides.dart` 等组合根分组。必需依赖默认明确报缺失，由组合根绑定；测试可以只注入正在验证的契约。
- 每个模块 `public.dart` 只汇总 `public/contracts.dart`、`public/providers.dart`、`public/widgets.dart`（无该职责则省略）。contracts 必须递归保持纯 Dart；providers 提供状态和命令/查询 token；widgets 提供页面、组件和展示辅助。保留既有窄路径供准确选择能力，但所有 public 文件只声明导出，不承载实现。
- 普通公开面不导出工厂、override 或基础设施实现。跨模块 FRB mapper 使用 `public/infrastructure/` 的专用入口，只有基础设施调用方可消费，不进入普通 barrel。元数据候选查询也通过 owner 的 `namedFacetFormListingProvider` 注入真实仓储，不在 public 函数里创建默认实现。
- R12 的既有 UI 白名单继续只减不增；规范 providers/widgets 入口和显式 `show` 的纯导出 facade 由新结构规则约束。任意 public→presentation 的隐式深引用仍不允许。canonical 入口直接导出 presentation 时必须选定符号，providers 只允许 Provider token。

选择保留按 feature 组织的纵向模块，而非拆成全 app 的 domain/data/presentation 大目录，保留 owner 内聚。基础设施是原外部适配职责的明确归属，不为每个薄查询新增用例、接口或 Repository。DI 是最外层装配职责，不是与 domain/application 并列的业务层。

## Consequences

门禁同时验证内层递归依赖、组合根不可被产品代码引用、现有模块禁止边、public 无环与 Provider override 覆盖。原测试随实现迁移，manifest 不降低覆盖。门禁还要求 public 只有导出、旧 di/data 文件桶不可回流、所有 requiredProvider 均被组合根绑定；内层外部包仅信任现有数据注解库。迁移使用单文件移动，保留实现及行为；空旧目录不作为兼容入口，门禁与 Git 以文件为准。

备份 gzip 编解码归基础设施；格式识别留 domain。Comic/Series 字段锁保持不可变数据，不再为注解依赖 Flutter。Reader 的跨模块用例只消费进度/活动签名，不导入含界面与工厂的大 barrel。下载取消采用纯 Dart CancellationToken，Dio 映射由基础设施承担；GitHub 更新与字典下载通过真实 Gateway 注入。封面资源类型在仓储契约中保持领域枚举，到 FRB 适配处才编码。文件访问、目录查询和剪贴板/PNG 实现也由组合根选择。

## References

- [The Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)：依赖规则和框架独立性。
- `app/test/architecture/clean_architecture_dependency_test.dart`
- ADR-0033、0034、0035、0039、0045、0050。
