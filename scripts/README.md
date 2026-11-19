# 维护脚本

在仓库根目录运行 Bash 脚本；Windows 使用 Git Bash。只保留开发环境与发布辅助工具。

PR Gate、Nightly（coverage / fuzz / miri）与 Release verify 只在 GitHub Actions 运行，入口在 [`.github/scripts/`](../.github/scripts/) 与对应 workflow，不提供本地门禁包装脚本。

- `setup-dev.sh`：首次开发环境初始化；组合 Rust 链接与原生依赖下载。参数见 `--help`。
- `link-rust-builder.sh`：为 Cargokit 创建 Rust 链接；由 setup 和 `.github/actions/setup-flutter-frb` 共用。正确链接可重复执行；遇到其他已有路径会报错，需人工核对。
- `normalize-changelog-bullets.sh`、`strip-changelog-bullets.sh`：Release 生成说明时分别提取简洁条目与非条目部分，从标准输入读取 Markdown。

原生依赖下载、校验和平台嵌入仍由 `core/vendor/` 的脚本维护；不在本目录复制。测试策略见 [gate.md](../docs/engineering/gate.md)，开发流程见 [贡献指南](../CONTRIBUTING.md)。
