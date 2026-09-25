# Testing guide（Gate tier · 三层缝 · UI 双轨）

单一事实来源：PR 硬门禁保证什么、本地还应跑什么、Dart data 测什么、UI 快/慢轨如何晋升。决策依据见 **ADR-0018**（三层缝 + CI tier 命名）与 ADR-0002（业务在 Rust `cargo test`；Dart 测 UI + FRB 薄边）。

## 三层缝

| 缝 | 断言什么 | 位置 | Job |
|----|----------|------|-----|
| Rust 业务真值缝 | sync / reader / DB / path migration 业务行为 | `core/`（`tests/common/` harness） | `gate-rust-test` |
| FRB 线缝 | `RustLib.init` 加载真实 cdylib；sync / async / 错误 DTO 跨线缝可通 | `app/test/frb_wire/` | `gate-dart-test` |
| Dart 薄边缝 | mapper / guard / adapter、domain / core 纯逻辑 | `app/test/{domain,core,data}/` | `gate-dart-test` |
| UI 双轨 | 快轨 = Dart hard-manifest UI；慢轨 = Dart slow-track UI | `app/test/ui/` | `gate-dart-test` / `nightly-dart-ui` |

## CI tier 命名

Job id 形如 `{tier}-{domain}-{intent}`（词汇表见 ADR-0018）。

| Tier | Workflow | Job 前缀 | 是否挡合并 |
|------|----------|----------|------------|
| **Gate** | `gate.yml`（name: `Gate`） | `gate-*` | 是：PR 绿 = 全部 `gate-*` 已过 |
| **Watch** | `watch.yml`（手动；或由 `release.yml` 调用） | `watch-*` | 否（平台级冒烟） |
| **Nightly** | `nightly.yml`（每日 UTC 18:00 / `workflow_dispatch`） | `nightly-*` | 否 |
| **Release** | `release.yml`（tag `v*` / 手动） | `release-*` | 发布流水线专用 |

所有 `gate-*` job 与 `release-verify` 都只调用 `scripts/run-gate.sh`，本地与 CI 命令同源。Composite action 统一为 `.github/actions/setup-flutter-frb`。单平台手动打包（不走 Release 拓扑）是 `manual-build-android.yml` / `manual-build-ios.yml`。

## Nightly / Watch / Release tier（不挡 PR）

| Job | Workflow | 本地复现 | 内容 |
|-----|----------|----------|------|
| `nightly-dart-ui` | `nightly.yml` | `cd app && flutter test test/ui` | 全量 `test/ui`（含慢轨） |
| `nightly-coverage` | `nightly.yml` | `cargo build --manifest-path core/Cargo.toml -p hentai_flutter && cd app && flutter test --coverage` | 全量 Dart 覆盖率趋势：Step Summary 行覆盖率 + `lcov.info` artifact；**不是**门禁 |
| `watch-platform-android-pdf` | `watch.yml` | 连接 Android 设备/模拟器后 `cd app && flutter test integration_test/pdf_reader_smoke_test.dart` | x86_64 模拟器上真机链路打开 PDF 并读首页；发布时并行跑，失败不挡 `release-publish` |
| `release-verify` | `release.yml` | `./scripts/run-gate.sh` | 完整 Gate 拓扑（含 codegen 漂移与 FRB 线缝）；`release-build-*` 均 `needs` 它 |
| `release-build-{windows,macos,linux,android,ios}` | `release.yml` | — | 各平台打包产物 |
| `release-publish` / `release-manual-summary` | `release.yml` | — | 发布 GitHub Release / 手动构建仅产出 artifact |

Nightly 的定时触发只在默认分支（`main`）生效；其他分支用 `workflow_dispatch` 手动跑。

## Gate tier（必须绿）

| Job | 本地复现 | 内容 | 失败含义 |
|-----|----------|------|----------|
| `gate-rust-lint` | `./scripts/run-gate.sh rust-lint` | `cargo fmt --check` + `cargo clippy --workspace --all-targets -D warnings` | Rust 格式 / lint |
| `gate-rust-test` | `./scripts/run-gate.sh rust-test` | `cargo test --manifest-path core/Cargo.toml` | Rust 核心（sync / reader / DB）回归 |
| `gate-codegen-drift` | `./scripts/run-gate.sh codegen-drift` | FRB generate + build_runner，随后 `git status` 须干净 | 提交的生成产物与源码不一致 |
| `gate-dart-static` | `./scripts/run-gate.sh dart-static` | `dart format --set-exit-if-changed lib test` + `flutter analyze` | Dart 格式 / 静态分析 |
| `gate-dart-test` | `./scripts/run-gate.sh dart-test` | `cargo build -p hentai_flutter` + `flutter test` ← `app/test/gate/manifest.txt` | manifest 内硬门禁 Dart 测试（含 FRB 线缝） |

`./scripts/run-gate.sh`（无参数）按顺序跑全部；可传多个子命令跑子集，如 `./scripts/run-gate.sh dart-static dart-test`。`codegen-drift` 会就地重生成产物，本地运行前请先提交或暂存改动。

### Gate manifest

`app/test/gate/manifest.txt` 是 `gate-dart-test` 的**唯一**路径来源（每行一个相对 `app/` 的文件或目录，`#` 为注释）。它覆盖 domain / core / data 薄边、FRB 线缝（`test/frb_wire`）、monorepo layout、app smoke（`test/widget_test.dart`）与已晋升快轨 UI。`test/gate/manifest_test.dart` 自检每条路径存在且无重复。

新增 **data 契约测** 或 **已晋升的快轨 UI/纯逻辑测** 时：把路径加进 manifest（或把文件放进已列入的目录），并在 PR 说明中列出；不要另开 `continue-on-error` 软门禁冒充硬跑。

慢轨 viewport / shell / 大 widget（如 `test/ui/features/reader/*viewport*`、大面积 responsive shell）默认只在本地跑，除非按下方双轨规则显式晋升。

## 本地全量

合并前若你改了 UI 或怀疑 widget 回归，本地再跑：

```bash
./scripts/run-gate.sh          # 完整 Gate
cd app && flutter test         # 全量 Dart（含慢轨 test/ui）
```

Gate **不会**跑全量 `test/ui`（由 `nightly-dart-ui` 覆盖）、不会跑 `integration_test`（由 `watch-platform-android-pdf` 覆盖）、不上 coverage 门禁（`nightly-coverage` 只出趋势）。

## ADR-0002 测试含义

- **信任 `cargo test`**：Library sync / 阅读 I/O / DB / series 业务行为以 Rust 集成为准。
- **Dart data**：只测 FRB ↔ domain 的 **mapper / error·call guard / adapter**（见 `app/test/data/`）。**不要**对真 FRB 或 `*_repository_impl` 写全流程集成测（避免第二套集成栈）。
- **FRB 线缝**：唯一碰真实 cdylib 的 Dart 测试，只保留 1–3 条直调 API 的冒烟（`app/test/frb_wire/`），不断言业务。新线缝测必须走 `frb_wire_harness.dart` 的 `initRustLibForWireTest()`；本地需先 `cargo build --manifest-path core/Cargo.toml -p hentai_flutter`（或设置 `HENTAI_FLUTTER_LIB` 指向动态库）。
- **Dart UI**：widget / 交互；优先薄 smoke + 抽纯逻辑到 unit。

## UI 双轨（快硬 / 慢软）

| 轨 | 进入条件 | CI |
|----|----------|-----|
| **快轨**（Dart hard-manifest UI） | 低 timing、少 `pumpAndSettle`、无脆弱 viewport 尺寸依赖；优先纯逻辑 unit 或极薄 smoke | 列入 gate manifest 硬门禁 |
| **慢轨**（Dart slow-track UI） | 大壳、侧栏、多断点 responsive、阅读器 viewport 手势/时序 | 本地 + `nightly-dart-ui`；全量 `test/ui` **不进 Gate** |

### 晋升快轨检查清单

`app/test/gate/manifest.txt` 是扩 Gate 的**唯一入口**：不改 workflow、不加新 job，也不另起白名单文件。

1. 测的是可观察契约，不绑私有结构。
2. 本地连续跑 3 遍稳定（无偶发 timeout）；时间相关逻辑用注入的 `now` / clock，不依赖真实计时。
3. 已改用共享 harness（见下），无新复制的 MaterialApp / `_Fake*` 样板。
4. 把路径加入 manifest 对应分节，并在 PR 中显式列出新增路径。
5. 评审确认后合入；此后失败必须挡合并。

慢轨测试**不**写进 manifest；它们由 `nightly-dart-ui` 覆盖。

## 共享 harness（强制）

新测 **必须**走共享入口，禁止再复制一套：

| 侧 | 入口 | 用途 |
|----|------|------|
| Flutter | `app/test/support/`（如 `pump_localized_app.dart`、`fakes/`） | 本地化 pump、常用 overrides/fakes |
| Rust | `core/crates/core/tests/common/` | DB init 锁、`create_fixture_db`、fixture SQL |

`core/crates/core/tests/*.rs` 中凡涉及全局 DB 或 `drift_v2.sql` fixture 的集成测已统一走 `mod common;`（#154）；纯解析 / 纯函数测试（如 `metadata_read_test.rs`、`metadata_lock_test.rs`、`rar_comic_formats.rs`）无需引入。迁移存量 Dart 测试时顺手改到 harness；`test/features` 遗留路径被触及时迁到镜像的 `test/ui` / `test/data`，不要继续扩张 `test/features`。

### Flutter 示例

```dart
await pumpLocalizedApp(
  tester,
  home: const Scaffold(body: MyWidget()),
);
```

### Rust 示例

```rust
mod common;

#[test]
fn example() {
    common::with_global_db(|| {
        let temp = tempfile::TempDir::new().unwrap();
        let db_path = common::create_fixture_db(temp.path());
        // ...
    });
}
```

## Slice 2 inventory（#108）

**新增契约测：** `series_frb_mapper`、`history_frb_mapper`、`reader_frb_mapper`、`thumbnail_frb_mapper`。

**补齐（2026-09-16）：** `frb_zone_guard`（三条：映射后 present、非 FRB 错误忽略、benign stream closed 忽略）；`comic_frb_mapper` 的 `mapRustComic`（全字段 + 可选字段为空）与 `mapPagedResult`；`series_frb_mapper` 的 `mapPagedSeriesComicsResult`。

**残留缺口（有意延后）：** 真 FRB / `*_repository_impl` 集成测（按 ADR-0002 不做）。
