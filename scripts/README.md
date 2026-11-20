# 维护脚本

在仓库根目录运行 Bash 脚本；Windows 使用 Git Bash。只保留开发环境与发布辅助工具。

PR Gate、Nightly（coverage / fuzz / miri）与 Release verify 只在 GitHub Actions 运行，入口在 [`.github/scripts/`](../.github/scripts/) 与对应 workflow，不提供本地门禁包装脚本。

- `setup-dev.sh`：首次开发环境初始化；组合 Rust 链接与原生依赖下载。参数见 `--help`。
- `link-rust-builder.sh`：为 Cargokit 创建 Rust 链接；由 setup 和 `.github/actions/setup-flutter-frb` 共用。正确链接可重复执行；遇到其他已有路径会报错，需人工核对。Unix 用符号链接，Windows 用 junction。
- `extract-changelog-section.sh`：从 `CHANGELOG.md`（Keep a Changelog）提取指定版本段落正文；`Release` 发布说明必须有该段落，缺失则失败。
- `normalize-changelog-bullets.sh`、`strip-changelog-bullets.sh`：处理 GitHub `generate-notes` Markdown（标准输入）；后者用于 Release 正文尾部的 compare 链接等非条目部分。

原生依赖下载由 `core/vendor/fetch-native-deps.sh` 维护（全平台 Bash；需 curl/tar，以及 jq 或 python）。测试策略见 [gate.md](../docs/engineering/gate.md)，开发流程见 [贡献指南](../CONTRIBUTING.md)。
