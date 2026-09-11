# Testing guide（CI vs 本地 · FRB 薄边 · UI 双轨）

单一事实来源：PR 硬门禁保证什么、本地还应跑什么、Dart data 测什么、UI 快/慢轨如何晋升。对齐 ADR-0002（业务在 Rust `cargo test`；Dart 测 UI + FRB 薄边）。

## CI hard gates（必须绿）

| Job | 命令（可本地复现） | 失败含义 |
|-----|-------------------|----------|
| `test-rust` | `cargo test --manifest-path core/Cargo.toml` | Rust 核心（sync / reader / DB）回归 |
| `analyze` · format | `cd app && dart format --output=none --set-exit-if-changed lib test` | 格式漂移 |
| `analyze` · analyze | `cd app && flutter analyze` | 静态分析问题 |
| `test-unit` | `cd app && flutter test test/domain test/core test/data test/project_layout_test.dart test/ui/core/widgets/actions/destructive_filled_button_test.dart test/ui/core/widgets/overlays/dialog/confirm` | domain / core / data 契约 / monorepo layout / 已晋升快轨 UI |

新增 **data 契约测** 或 **已晋升的快轨 UI/纯逻辑测** 时：扩展 `test-unit` 的路径列表（或把文件放进已有 `test/data` / 已列入的快轨路径），不要另开「假绿」软门禁冒充硬跑。

## Soft / 非阻塞

| Job | 命令 | 说明 |
|-----|------|------|
| `test-widget (soft)` | `cd app && flutter test test/widget_test.dart` | Smoke only；`continue-on-error`。**绿 PR 不代表全量 UI 测已过。** |

慢轨 viewport / shell / 大 widget（如 `test/ui/features/reader/*viewport*`、大面积 responsive shell）默认留在本地或 soft，除非按下方双轨规则显式晋升。

## 本地全量

合并前若你改了 UI 或怀疑 widget 回归，本地再跑：

```bash
cd app && flutter test
cargo test --manifest-path core/Cargo.toml
```

CI **不会**跑全量 `test/ui`、不会跑 `integration_test`、不上 coverage 门禁。

## ADR-0002 测试含义

- **信任 `cargo test`**：Library sync / 阅读 I/O / DB / series 业务行为以 Rust 集成为准。
- **Dart data**：只测 FRB ↔ domain 的 **mapper / error·call guard / adapter**（见 `app/test/data/`）。**不要**对真 FRB 或 `*_repository_impl` 写集成测（避免第二套集成栈）。
- **Dart UI**：widget / 交互；优先薄 smoke + 抽纯逻辑到 unit。

## UI 双轨（快硬 / 慢软）

| 轨 | 进入条件 | CI |
|----|----------|-----|
| **快轨** | 低 timing、少 `pumpAndSettle`、无脆弱 viewport 尺寸依赖；优先纯逻辑 unit 或极薄 smoke | 可列入 `test-unit` 硬门禁 |
| **慢轨** | 大壳、侧栏、多断点 responsive、阅读器 viewport 手势/时序 | soft 或仅本地；全量 `test/ui` **本波不硬门禁** |

### 晋升快轨检查清单

1. 测的是可观察契约，不绑私有结构。
2. 本地连续跑稳定（无偶发 timeout）。
3. 已改用共享 harness（见下），无新复制的 MaterialApp / `_Fake*` 样板。
4. 在 PR 中显式列出路径，并改 `.github/workflows/ci.yml` 的 `test-unit` 命令。
5. 评审确认后合入；失败必须挡合并。

## 共享 harness（强制）

新测 **必须**走共享入口，禁止再复制一套：

| 侧 | 入口 | 用途 |
|----|------|------|
| Flutter | `app/test/support/`（如 `pump_localized_app.dart`、`fakes/`） | 本地化 pump、常用 overrides/fakes |
| Rust | `core/crates/core/tests/common/` | DB init 锁、`create_fixture_db`、fixture SQL |

迁移存量测试时顺手改到 harness；`test/features` 遗留路径被触及时迁到镜像的 `test/ui` / `test/data`，不要继续扩张 `test/features`。

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

**残留缺口（有意延后）：** `frb_zone_guard`；`comic_frb_mapper` 仍仅覆盖 sort/filter（缺 `mapRustComic` / page 映射等）；`mapPagedSeriesComicsResult`；真 FRB / `*_repository_impl`（本波不做）。
