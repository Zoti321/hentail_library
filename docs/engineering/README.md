# 工程指南

按任务阅读，当前规则以代码、配置与架构门禁为准；决策背景见 [ADR 索引](../adr/README.md)。本目录维护长期有效的英文指南，历史计划、升级调研和验证流水账保存在 Git 历史及 issue / PR。

- [目录与外部实现](feature-data-layout.md)：feature、core、shared、infrastructure、composition 的职责。
- [模块协作](cross-feature-collaboration.md)：public 入口、Command / Query、流、事件和装配。
- [领域所有权](shared-domain-ownership.md)：owner 与 Shared Kernel 的判断。
- [浏览模块边界](library-browse-zones.md)：browse、comic、series 的协作。
- [领域命名](ddd-domain-naming.md)、[Reader 命名](reader-ddd-lexicon.md)：类型与文件命名。
- [设计系统](design-system.md)：组件边界、本地化、Widgetbook 与验证。
- [测试与 CI](gate.md)：GitHub Actions Gate / Nightly、测试缝、manifest 与慢轨。
- [Rust binary size](rust-binary-size.md)：FRB cdylib release knobs、APK 三件套与 bloat 分析。
- [维护操作](maintainer.md)：日志支持与标签字典导入。
- [文件元数据写入](metadata-writeback.md)：独立模块、格式映射、扩展协议与验证；[RAR 写入限制](rar-metadata-writing.md)。

开发起步见根目录 [README](../../README.md) 和 [贡献指南](../../CONTRIBUTING.md)，脚本用途见 [scripts/README](../../scripts/README.md)。
