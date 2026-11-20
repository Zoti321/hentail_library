# 贡献指南

## 开发流程

1. 在仓库根运行 `./scripts/setup-dev.sh`（Linux、macOS 或 Windows Git Bash）。工具链版本以 `.github/workflows/gate.yml` 为准。
2. 进入 `app/` 执行 `flutter pub get`。修改 Freezed / Riverpod 等代码生成输入后执行 `dart run build_runner build`；**仅改 ARB 时只跑** `flutter gen-l10n`，避免无输入变更时全量 `build_runner` 刷新无关 `theme_tailor` 产物。修改 Rust FRB API 后执行 `flutter_rust_bridge_codegen generate`。
3. 硬门禁与 Nightly 只在 GitHub Actions 跑（见 `docs/engineering/gate.md`）。本地可按需跑受影响的 `cargo` / `flutter test`；工具链版本以 `.github/workflows/gate.yml` 为准，环境初始化见 `./scripts/setup-dev.sh`。
4. 使用 [PR 模板](.github/pull_request_template.md)，写明行为变化、验证证据和未验证项。显著用户可见变更写入根目录 [CHANGELOG.md](CHANGELOG.md) 的 `Unreleased`（[Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)）；发版时移入对应版本段落后再打 `v*` tag。

Rust 侧补充：`core/` 为 Cargo workspace；体积说明见 [rust-binary-size.md](docs/engineering/rust-binary-size.md)；Nightly 含 fuzz / miri（`.github/workflows/nightly.yml`）。

PR 测试范围由 `app/test/gate/manifest.txt` 统一维护；目录项已覆盖的测试文件不重复列出。Nightly 用一次全量 `flutter test --coverage` 同时完成快慢轨回归和覆盖率采集；平台集成冒烟仍走 Watch。

`codegen-drift` 会就地生成并比较 `app/`、`core/` 与 HEAD 的差异，运行前先保存并提交相关改动。Agent 在当前 clone 和分支工作，新分支或 worktree 需要用户明确允许。

## 文档入口

- [README](README.md)：产品能力、平台与首次运行。
- [AGENTS](AGENTS.md)：Agent 按任务读取的入口。
- [GLOSSARY](GLOSSARY.md)：领域术语；issue、PR 和代码使用一致词汇。
- [架构决策](docs/adr/README.md)：决策与修订关系。
- [工程指南](docs/engineering/README.md)：模块协作、领域所有权/命名、设计系统、测试和维护操作。
- [Issue 约定](docs/agents/issue-tracker.md)、[分拣标签](docs/agents/triage-labels.md)：GitHub 协作流程。
- [脚本说明](scripts/README.md)：长期维护脚本及调用方。

工程指南、Agent 协作文档和术语表使用英文；README 与贡献指南使用简体中文。历史 ADR 保留决策记录，当前操作步骤写入工程指南；迁移流水账和单次验证结果放 issue / PR。目录与依赖边界以 `app/test/gate/`、`app/test/architecture/` 的检查为准，避免维护重复快照。
