# 工程指南

按任务阅读。结构规则以 `app/test/architecture/`、`app/test/gate/` 与配置为准；本目录只保留消歧义、写语义与操作流程。决策背景见 [ADR 索引](../adr/README.md)。历史计划与验证流水账保存在 Git 历史及 issue / PR。

- [模块协作](cross-feature-collaboration.md)：目录/适配器落点、public 能力、browse 壳、product seams。
- [领域所有权](shared-domain-ownership.md)：owner 与 Shared Kernel 判定。
- [领域命名](domain-naming.md)：domain 命名模板与 Reader 消歧。
- [Rust 写语义](rust-write-semantics.md)：sync / reader writeback / metadata 等事务边界。
- [设计系统](design-system.md)：组件边界、本地化、Widgetbook 与验证。
- [测试与 CI](gate.md)：GitHub Actions Gate / Nightly、测试缝、manifest 与慢轨。
- [Rust binary size](rust-binary-size.md)：FRB cdylib release knobs、APK 三件套与 bloat 分析。
- [维护操作](maintainer.md)：日志支持与标签字典导入。
- [文件元数据写入](metadata-writeback.md)：独立模块、格式映射、扩展协议与验证；[RAR 写入限制](rar-metadata-writing.md)。

开发起步见根目录 [README](../../README.md) 和 [贡献指南](../../CONTRIBUTING.md)，脚本用途见 [scripts/README](../../scripts/README.md)。
