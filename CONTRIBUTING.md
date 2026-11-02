# 贡献指南

## 开始

1. 仓库根：`./scripts/setup-dev.sh`
2. 日常：`cd app` → `flutter pub get` → `dart run build_runner build --delete-conflicting-outputs`（若改了生成代码）
3. 合并前：`./scripts/run-gate.sh`；改 UI 时再 `cd app && flutter test`

详见 `README.md` § 协作建议。

## Agent / 文档地图

| 需求 | 读哪里 |
|------|--------|
| 始终加载的 brief | `AGENTS.md` |
| 领域词汇 | `GLOSSARY.md` |
| 架构决策 | `docs/adr/` |
| Feature 用例层 / public API | ADR-0033、ADR-0034；bootstrap 注入见 `features/bootstrap/di/overrides/` |
| UI 规范与规划 | `design-system/` 已清空（仅保留占位与示例参考图，2026-11-01）；现行 UI 真源见 `AGENTS.md` 与 ADR-0027/0028/0030 |
| Gate、测试缝 | `docs/engineering/gate.md` |
| `gh`、日志、标签字典 | `docs/engineering/maintainer.md` |

分层与 import 的**机械真相**在 `app/test/gate/` 与 `gate.yml`，不要依赖过期快照文档。

## Pull Request

使用 [PR 模板](.github/pull_request_template.md)（Summary / Evidence / Merge danger）。领域用语与 `GLOSSARY.md` 一致。
