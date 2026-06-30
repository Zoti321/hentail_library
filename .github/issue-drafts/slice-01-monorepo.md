## Parent

#1 （PRD 父 issue 创建后替换为真实编号）

## What to build

将仓库重组为 Monorepo：`app/` 下放现有 Flutter 工程（`lib`、`test`、各平台目录、`pubspec.yaml`）；根目录保留 `README.md`、`AGENTS.md`、`CONTEXT.md`、`docs/`、`.github/`。更新 CI 与协作文档中的路径（`cd app && flutter test`）。本切片**不引入 Rust**，行为与重组前一致。

## Acceptance criteria

- [ ] Flutter 源码与平台工程均位于 `app/` 下，根目录无遗留 `lib/`、`pubspec.yaml`（迁移完成态）
- [ ] `cd app && flutter analyze` 与 `flutter test` 通过
- [ ] `.github/workflows/ci.yml` 使用 `working-directory: app`（或等价）
- [ ] `README.md` 开发说明更新为 `cd app`
- [ ] `test/project_layout_test.dart`（或等价）断言 Monorepo 布局

## Blocked by

None - can start immediately
