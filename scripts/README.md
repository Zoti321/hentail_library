# 维护脚本

在仓库根目录运行 Bash 脚本；Windows 使用 Git Bash。只保留开发、CI、发布及重复维护使用的工具；单次迁移脚本从 Git 历史恢复，不维护为日常入口。

- `setup-dev.sh`：首次开发环境初始化；组合 Rust 链接与原生依赖下载。参数见 `--help`。
- `link-rust-builder.sh`：为 Cargokit 创建 Rust 链接；由 setup 和 `.github/actions/setup-flutter-frb` 共用。正确链接可重复执行；遇到其他已有路径会报错，需人工核对。
- `run-gate.sh`：本地、PR Gate 和 Release 共用的检查入口；子命令见 `--help`。
- `run-rust-coverage.sh`：Nightly 与本地共用的 Rust 覆盖率报告；环境变量见 `--help`。
- `normalize-changelog-bullets.sh`、`strip-changelog-bullets.sh`：Release 生成说明时分别提取简洁条目与非条目部分，从标准输入读取 Markdown。
- `audit_dart_tests.py`：盘点 Dart 测试与 manifest 覆盖，支持 `--summary-json`、`--json`、`--compile-smoke-only`；分类仅供审计，不决定删除。
- `test_audit_dart_tests.py`：盘存工具的单元测试：`python -m unittest discover -s scripts -p test_audit_dart_tests.py`。

原生依赖下载、校验和平台嵌入仍由 `core/vendor/` 的脚本维护；不在本目录复制。测试策略见 [gate.md](../docs/engineering/gate.md)，开发流程见 [贡献指南](../CONTRIBUTING.md)。
