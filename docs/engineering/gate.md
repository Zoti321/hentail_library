# Gate 与测试缝

**决策**：ADR-0018（三层缝、CI tier 词汇）、ADR-0002（业务真值在 Rust）、**ADR-0033**（feature `application/`）、**ADR-0034**（cross-feature `public/`）。**Job 列表以** `.github/workflows/gate.yml` **为准**；本地与 CI 同源：`./scripts/run-gate.sh`。

**Wayfinder `lib/` 顶层目录**（Phase A/B）：`app/test/gate/lib_layout_scan_helpers.dart` · `project_layout_test.dart`。产品 feature 之间 **仅允许** import `features/<owner>/public/**` 或 `features/<owner>/public.dart`（M1）；`shared/**` **禁止** import feature public（R11）。

**工具链**：CI 固定 **Flutter 3.47.8**（`gate.yml` → `FLUTTER_VERSION`）。本地请用同 major/minor 的 stable；`flutter analyze` 在 GitHub Actions（`CI=true`）下会将 info 级 lint 也计为失败。`riverpod_lint` 为可选 dev 依赖（不依赖 `custom_lint`）；**Gate 的 `flutter analyze` 暂未挂 `plugins: riverpod_lint`**，避免未偿还的 Riverpod 风格债挡合并。本地可在 `analysis_options.yaml` 临时启用做增量清理。SDK 升级记录见 `docs/engineering/flutter-3.47-migration.md`。

## 命令

| 场景 | 命令 |
|------|------|
| PR 硬门禁（全量） | `./scripts/run-gate.sh` |
| 子集 | `./scripts/run-gate.sh rust-test dart-static dart-test` |
| 合并前 UI 怀疑回归 | 再跑 `cd app && flutter test`（含慢轨，**不进 Gate**） |
| Import 边界 | `cd app && flutter test test/gate/import_boundary_test.dart` |
| Shared UI 无 feature import | `cd app && flutter test test/gate/shared_ui_no_feature_import_test.dart` |
| Dart 测试盘存（inventory + rubric） | `python scripts/audit_dart_tests.py`（可选 `--summary-json` / `--json`；见下节） |

`codegen-drift` 会就地重生成；跑前请先提交或 stash。

## 三层缝（测什么）

| 缝 | 位置 |
|----|------|
| Rust 业务 | `core/` + `tests/common/` harness → `gate-rust-test` |
| FRB 线缝 | `app/test/frb_wire/`（`frb_wire_harness.dart`）→ manifest |
| Dart 薄边 | mapper/guard/adapters → `app/test/shared/data/{frb,mappers}/`、`test/features/*/data/` · 见 [`feature-data-layout.md`](./feature-data-layout.md) |
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

## Dart 测试盘存与分类 rubric

Epic [#447](https://github.com/Zoti321/hentail_library/issues/447) 清理 Flutter 侧测试时，用 **`scripts/audit_dart_tests.py`** 做可重复盘存（**不进 gate CI**；nightly 或 maintainer 本地可选附带 `--summary-json` 输出）。

### 运行

| 命令 | 输出 |
|------|------|
| `python scripts/audit_dart_tests.py` | 总数、manifest 展开覆盖数、慢轨数、rubric 计数、慢轨分桶 |
| `python scripts/audit_dart_tests.py --summary-json` | 同上（JSON，无逐文件列表） |
| `python scripts/audit_dart_tests.py --json` | 含每个 `*_test.dart` 的 tier + rubric |
| `python scripts/audit_dart_tests.py --rubric candidate-retire --slow-only` | 仅列出慢轨且标记为 candidate-retire 的路径 |

单元测：`cd scripts && python -m unittest test_audit_dart_tests.py -v`。

### tier 与 nightly

| tier | 含义 | CI |
|------|------|-----|
| **gate-fast** | 路径落在 `manifest.txt` 展开集合内 | `gate-dart-test` |
| **slow-track** | `app/test/**/*_test.dart` 中未进 manifest 的文件 | `nightly-dart-ui` 扫描 `test/shared/ui` + `test/features`（与 manifest 互补；盘存脚本的慢轨计数 = 全树减 manifest） |

### rubric 四层（启发式，供审计 #450–#454；非 gate 断言）

脚本对每个测试文件打 **一个主标签**（优先级自上而下）：

| rubric | 典型路径 | 清理 epic 中的含义 |
|--------|----------|-------------------|
| **architecture-guard** | `test/gate/**`、`project_layout_test.dart` | **禁止**批量删除；仅随 ADR/规则 drift 修改 |
| **thin-edge** | `frb_wire`、`shared/data|domain|di`、`core`、feature `data/` / `domain/` / `application/`、`test/support/` | 保留并加强；业务真值仍在 Rust |
| **ui-contract** | manifest 内其余项（MD3E entry、confirm 对话框、ViewModel persist/policy、motion/theme 等） | manifest 反向审计 (#450)；不合格则降级 |
| **candidate-retire** | 慢轨下的 `shared/ui`、feature `presentation/` 等 | 优先删/改 (#451–#454)；与 #447 决策一致：MD3E entry + 可观察结果为主缝 |

降级流程（manifest → nightly 至少一轮 → 再删）见子 issue #449（将写入本节「退役」段落）。

## Import / 布局（规范在测试里）

|  concern | 测试 / 文件 |
|----------|-------------|
| L1 domain↔data、FRB 面、application 依赖、shared→feature public、public→presentation | `import_boundary_test.dart`（R1–R12） |
| L2 product 图 ratchet（M1 非 public 边、M2/M3） | `import_boundary_baseline.json` → `dart run tool/generate_import_boundary_baseline.dart` |
| Cross-feature 协作约定 | [`cross-feature-collaboration.md`](cross-feature-collaboration.md) |
| public 图无环 | `import_boundary_test.dart`（`collectPublicCrossFeatureAdjacency`） |
| bootstrap shared 注入 | `features/bootstrap/di/overrides/*` + `shared_state_overrides.dart`（#435） |
| L3a shared/ui → features | `shared_ui_no_feature_import_test.dart` |
| L3b shared/domain → features ratchet | `shared_domain_no_feature_import_test.dart` + baseline 生成器；归属见 [`shared-domain-ownership.md`](./shared-domain-ownership.md) |
| FRB allowlist | `import_boundary_rules.dart`、`shared_feature_import_rules.dart` |
| `lib/` 顶层目录、public barrel、presentation/state | `project_layout_test.dart`、`lib_layout_scan_helpers.dart` |
| Strangler export shim | `strangler_shims.txt` + `strangler_shims_test.dart` |

启发式模块边（非门禁）：`python scripts/research/cross_feature_import_audit.py`。

## integration_test

仅 **平台冒烟**（cdylib + 原生依赖 + 最小 Reader 链），命名 `*_smoke_test.dart`，走 `watch.yml` / Release 调用，**不**写入 manifest。Library sync / WebDAV 全流程：**仅 Rust 集成测**。

## Harness

| 侧 | 入口 |
|----|------|
| Flutter | `app/test/support/` |
| Rust DB 集成 | `core/crates/core/tests/common/` |
