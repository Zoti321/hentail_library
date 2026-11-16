# ADR-0050: Riverpod 模块通信与具体应用用例内聚

## Status

Accepted（2026-11-12），已实施，验证记录见 `.scratch/module-communication/verification.md`。八项方向、完整实施计划与测试 seam 均已获用户最终确认；实施规格见 `.scratch/module-communication/plan.md`。局部修订 ADR-0033、0039、0045、0049 的跨模块 Port 表达，代码门禁随实施同步调整。

> **ADR-0051 修订（2026-11-12）**：组合根迁到 `lib/composition/`；owner `data/` 迁为 `infrastructure/`；共享协作签名在 `shared/application/contracts/`，Riverpod 适配在 `shared/presentation/providers/`。内层以递归 import/export 门禁为准；下文旧目录是历史语境。

## Context

模块通信本已通过 Riverpod 注入，但许多 Port 与单实现 Adapter 只把参数转给 Notifier；同时具体业务用例仍散在 UI 会话、Provider、值对象与数据服务中。仅改名不能解决内聚问题，直接把 Ref 传入 application 又会破坏纯 Dart 用例层。

## Decision

1. 处理全 app 模块协作，保留真实 Repository、原生 Reader、页面资源和剪贴板等外部适配职责。
2. domain/application 继续无 Flutter、Riverpod、FRB、data 实现依赖。
3. 按职责使用 Command、Query、Controller、Gateway、Navigator，Riverpod 公开能力以操作或数据命名。
4. 已完成领域事实继续经纯 Dart DomainEvent 发布，由 Riverpod 投影可观察状态。
5. 禁止边、public only、public 无环与 shared/core 不反向依赖 feature 不变。
6. 单动作可用类型明确的函数 Provider；状态订阅采用 Provider/StreamProvider/Notifier；一次性查询不隐式引入缓存。
7. 业务协调归具体 UseCase，优先收敛已存在于其他层的多步编排；不按代码行数加厚，不建立每模块巨型 ApplicationService。
8. 不改变原事务范围、写入顺序、取消、备份与事件语义，不新增跨模块补偿或自动重试。

## Consequences

DI 只装配用例依赖和对外能力；presentation 负责交互、草稿展示、路由、mounted 和 Riverpod UI 状态。应用层协调领域能力、执行顺序与结果，data 处理真实系统访问，Rust 保持事务与业务不变式真值。

Comic 元数据与系列排序、Library 表单持久化与旧配置初始化、Reader 上下文准备、备份 prepare/commit 与自动备份执行，是已由代码核实的优先收敛项。剩余薄层按实际职责保留，不新增空用例。

验收通过模块公开 Provider 的容器行为及纯 Dart UseCase 的注入依赖/结果进行；对写入部分成功、事件发布时机、缓存/释放和应用启动装配进行行为验证，不再为冗余 Adapter 保留镜像测试。
