# Gate 与测试缝

**决策**：ADR-0018（三层缝、CI tier 词汇）、ADR-0002（业务真值在 Rust）。**Job 列表以** `.github/workflows/gate.yml` **为准**；本地与 CI 同源：`./scripts/run-gate.sh`。

## 命令

| 场景 | 命令 |
|------|------|
| PR 硬门禁（全量） | `./scripts/run-gate.sh` |
| 子集 | `./scripts/run-gate.sh rust-test dart-static dart-test` |
| 合并前 UI 怀疑回归 | 再跑 `cd app && flutter test`（含慢轨，**不进 Gate**） |
| Import 边界 | `cd app && flutter test test/gate/import_boundary_test.dart` |
| Shared UI 无 feature import | `cd app && flutter test test/gate/shared_ui_no_feature_import_test.dart` |

`codegen-drift` 会就地重生成；跑前请先提交或 stash。

## 三层缝（测什么）

| 缝 | 位置 |
|----|------|
| Rust 业务 | `core/` + `tests/common/` harness → `gate-rust-test` |
| FRB 线缝 | `app/test/frb_wire/`（`frb_wire_harness.dart`）→ manifest |
| Dart 薄边 | mapper/guard/adapters → `app/test/shared/{data,domain}/`、`test/core/` |
| UI 快轨 | 列入 `app/test/gate/manifest.txt` 的 UI/逻辑 |
| UI 慢轨 | `test/shared/ui`、`test/features` 未进 manifest 部分 → `nightly-dart-ui` |

业务 sync/read/DB：**信任 `cargo test`**。Dart **不要**对真 FRB / `*_repository_impl` 写全流程集成测。

## Gate manifest（唯一扩门禁入口）

- 路径表：`app/test/gate/manifest.txt`（`manifest_test.dart` 自检存在、无重复）。
- 新增快轨 data 契约测或 UI：只改 manifest + PR 说明列出路径；**不要**新 workflow 软门禁。

### 快轨晋升检查清单

1. 可观察契约，不绑私有结构。
2. 本地连续 3 遍稳定；时间逻辑注入 clock。
3. 用 `app/test/support/`（`pumpLocalizedApp` 等），不复制 MaterialApp 样板。
4. 路径写入 manifest 对应分节。

## Import / 布局（规范在测试里）

|  concern | 测试 / 文件 |
|----------|-------------|
| L1 domain↔data、FRB 面 | `import_boundary_test.dart` |
| L2 product 图 ratchet | `import_boundary_baseline.json` → `dart run tool/generate_import_boundary_baseline.dart` |
| L3a shared/ui → features | `shared_ui_no_feature_import_test.dart` |
| L3b shared/domain → features ratchet | `shared_domain_no_feature_import_test.dart` + baseline 生成器 |
| FRB allowlist | `import_boundary_rules.dart`、`shared_feature_import_rules.dart` |
| `lib/` 顶层与 feature 目录 | `project_layout_test.dart`、`wayfinder_layout_helpers.dart` |
| Strangler export shim | `strangler_shims.txt` + `strangler_shims_test.dart` |

启发式模块边（非门禁）：`python scripts/research/cross_feature_import_audit.py`。

## integration_test

仅 **平台冒烟**（cdylib + 原生依赖 + 最小 Reader 链），命名 `*_smoke_test.dart`，走 `watch.yml` / Release 调用，**不**写入 manifest。Library sync / WebDAV 全流程：**仅 Rust 集成测**。

## Harness

| 侧 | 入口 |
|----|------|
| Flutter | `app/test/support/` |
| Rust DB 集成 | `core/crates/core/tests/common/` |
