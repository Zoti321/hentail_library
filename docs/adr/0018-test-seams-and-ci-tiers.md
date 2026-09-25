# ADR-0018: 测试三层缝与 CI tier 命名规范

## Status

Accepted

## Context

ADR-0002 把业务逻辑放进 Rust，Dart 只剩 UI 与 FRB 薄边。但 CI 仍沿用 Dart-only 时代的形态：

- 缺少 Rust fmt / Clippy、FRB codegen 漂移检测，以及「Dart 真能调通 Rust」的最小验证。
- Job 名名实不符（`test-unit` 跑 widget 测、`analyze` 含 format），`test-widget (soft)` 以 `continue-on-error` 伪装门禁，绿 PR 不代表回归安全。
- 硬门禁的 Dart 测试路径写死在 workflow 命令行里，本地无法同源复现。

需要一套稳定的测试分层和 CI 命名契约，让贡献者、维护者与 Agent 对「PR 绿意味着什么」有同一答案。

## Decision

### 1. 三层缝 + UI 双轨

| 缝 | 断言什么 | 在哪里测 | CI job |
|----|----------|----------|--------|
| **Rust 业务真值缝** | Library sync、Reader、DB、Path migration 等业务行为 | `core/` 单元 + 集成测（`tests/common/` harness） | `gate-rust-test` |
| **FRB 线缝** | `RustLib.init` 能加载真实 cdylib；sync / async / 错误 DTO 能跨线缝 | `app/test/frb_wire/`（1–3 条直调 API） | `gate-dart-test` |
| **Dart 薄边缝** | FRB ↔ domain 的 mapper / guard / adapter，domain / core 纯逻辑 | `app/test/{domain,core,data}/`（fake / stub） | `gate-dart-test` |
| **UI 双轨** | 快轨：可观察契约、低时序依赖；慢轨：大壳、多断点、阅读器手势 | `app/test/ui/` | 快轨 → `gate-dart-test`；慢轨 → `nightly-dart-ui` |

- 业务行为**只**在 Rust 缝断言。FRB 线缝只证明调用链可通，不复测业务。
- **不做** Dart `*_repository_impl` 全流程 FRB 集成：那会形成第二套集成栈，与 Rust 缝重复且更脆。
- 线缝测通过 `test/frb_wire/frb_wire_harness.dart` 定位宿主平台的 `hentai_flutter` 动态库（`core/target/{debug,release}/`，或 `HENTAI_FLUTTER_LIB`）；`scripts/run-gate.sh dart-test` 先 `cargo build -p hentai_flutter`。

### 2. CI 命名：`{tier}-{domain}-{intent}`

Job id 是稳定契约，与文档、本地脚本一致；display name 用 `tier · domain intent` 形式。

| Tier | 含义 | 合并策略 |
|------|------|----------|
| `gate` | PR 硬门禁 | required checks，失败挡合并 |
| `watch` | 平台 / 设备级冒烟 | 手动或发布触发，不挡 PR；尽量少用 |
| `nightly` | 定时 / `workflow_dispatch` | 不挡 PR |
| `release` | 发布流水线 | tag / manual |

- **Domain**：`rust`（`core/`）、`dart`（`app/`）、`codegen`（FRB + build_runner 产物）、`platform-*`（各平台构建）。
- **Intent**：`test`、`lint`（Rust fmt + Clippy）、`static`（Dart format + analyze，不含 test）、`drift`（重新生成后 git 须干净）、`smoke`、`build`、`verify`（发布前复跑 gate 等价命令）、`coverage`（趋势报告，不挡合并）。
- **名实相符**：名含 `static` 不得跑测试；不以 `(soft)` 后缀或 `continue-on-error` 表达门禁强度，改用 tier。
- Step 名统一 `Checkout` / `Setup Flutter FRB toolchain` / `Check {object}` / `Run {object}`；其他环境准备步骤（JDK、KVM、pdfium、签名配置等）用 `Setup {tool}`。每个 step 都显式命名，不留裸 `uses:`。

Gate workflow 拓扑：

```
Gate (gate.yml)
├── gate-rust-lint
├── gate-rust-test
├── gate-codegen-drift
├── gate-dart-static
└── gate-dart-test      ← app/test/gate/manifest.txt（薄边 + frb_wire + 快轨 UI + smoke）
```

其余 tier 拓扑：

```
Nightly (nightly.yml)            定时 / workflow_dispatch
├── nightly-dart-ui              全量 test/ui（慢轨）
└── nightly-coverage             全量 Dart 覆盖率趋势（非门禁）

Watch (watch.yml)                workflow_dispatch / workflow_call
└── watch-platform-android-pdf   integration_test/pdf_reader_smoke_test.dart（Android 模拟器）

Release (release.yml)            tag v* / workflow_dispatch
├── release-verify               scripts/run-gate.sh（= 完整 Gate）
├── watch-platform-android-pdf   调用 watch.yml；并行跑，不挡发布
├── release-build-{windows,macos,linux,android,ios}   needs release-verify
├── release-publish              needs 全部 release-build-*
└── release-manual-summary       手动构建且不发布时

Manual build（非 tier；仅 workflow_dispatch）
├── manual-build-android.yml
└── manual-build-ios.yml
```

### 3. 单一事实来源

- `app/test/gate/manifest.txt` 是 `gate-dart-test` 的唯一路径来源；扩硬门禁只改 manifest 并在 PR 中列出。
- 每个 `gate-*` job 只调用 `scripts/run-gate.sh <子命令>`；`release-verify` 复用同一脚本，保证发布前与 PR 门禁拓扑一致。
- 操作细则（晋升检查清单、harness 用法、本地全量命令）写在 `docs/agents/testing.md`，本 ADR 只记录决策。

## Consequences

### Positive

- PR 绿 = 全部 `gate-*` 通过、生成产物未漂移、Dart 能调通真实 Rust 库。
- 本地 `./scripts/run-gate.sh` 与 CI 同源，失败可直接复现。
- 新增门禁只需改 manifest，不再改 workflow。

### Negative

- `gate-dart-test` 需要编译 `hentai_flutter` cdylib，job 耗时增加（由 Rust cache 缓解）。
- 慢轨 UI 回归要到 nightly 才暴露，不在 PR 上阻断。
- 全量 `cargo fmt` 与 job 改名产生一次性的大面积机械 diff。

## References

- ADR-0002 — Rust core via FRB（业务在 Rust，Dart 测 UI + 薄边）
- `docs/agents/testing.md` — Gate tier 操作手册、UI 双轨晋升清单、共享 harness
