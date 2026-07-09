# ADR-0003: 统一开发期日志（Dart `logging` + Rust `tracing`）

## Status

Accepted

## Context

当前日志能力分裂且覆盖不足：

- **Dart**：`app/lib/core/logging/log_manager.dart` 基于 Talker 单例；约 12 处仅在错误路径调用 `LogManager.instance.handle`；`main.dart`、`frb_zone_guard.dart` 等处仍用 `debugPrint` 旁路。`LogFileWriter` 监听 Talker stream 写 `logs/app_log.txt`（5MB 轮转）。
- **Rust**：`core/` 无日志框架；错误经 `thiserror` + `Result<HentaiError>` 返回，Dart FRB 层映射。scan、reader、DB 内部行为在开发期不可见。
- **FRB 迁移**（ADR-0002）持续推进，双栈可观测性缺口会随 Rust 代码量扩大。

Phase 1 目标为**开发可观测性**；用户侧日志导出、设置页开关等生产诊断能力留待后续阶段。

## Decision

### 目标与阶段

- **Phase 1**：开发可观测性——开发者能在终端（及现有日志文件）看到结构化、可过滤的 Dart + Rust 日志。
- **Phase 2（不在本 ADR 范围）**：设置页日志级别、用户导出、统一跨栈格式桥接等。

### Dart

1. 迁移至 [`package:logging`](https://pub.dev/packages/logging)，**移除 Talker** 依赖。
2. 在 `app/lib/core/logging/` 提供统一初始化：注册 `Logger.root.onRecord` 监听器，**双输出**：
   - **控制台**：彩色、人类可读；
   - **文件**：复用现有轮转策略（5MB、保留 3 份备份），格式为 `时间 level logger message`（含 `stackTrace` 若有）。
3. **Logger 层次**按架构层命名，例如：
   - `hentai.data.repo`
   - `hentai.data.frb`
   - `hentai.ui.shell`
   - `hentai.ui.reader`
4. **默认级别**：
   - `kDebugMode`：`Level.FINE`
   - release：`Level.INFO`
5. 收拢现有 `LogManager.instance.handle`、`debugPrint` 旁路至 `logging`；FRB zone 未捕获错误写入 `hentai.data.frb`。

### Rust

1. 引入 **`tracing`** + **`tracing-subscriber`**（`fmt` + `EnvFilter`），日志输出 **stderr**。
2. 在 `core/crates/flutter` FRB 初始化路径安装 subscriber（避免 `hentai-core` 纯库侧重复初始化）。
3. **默认级别**（开发构建 / 未设置环境变量时）：`hentai_core=debug`；生产/release 构建默认 `info`。开发者可通过 `RUST_LOG` 覆盖（如 `RUST_LOG=hentai_core::sync=trace`）。
4. Phase 1 在 **scan、reader、db 初始化**等关键入口添加 `info` / `debug` / `error` 级 span 或 event，验证端到端可观测性。

### 明确不做（Phase 1）

- Rust 日志经 FRB 回调汇入 Dart Talker/logging（统一单流格式）——复杂度高，后续再评估。
- 全模块铺满日志打点。
- 设置页日志 UI、用户导出。

## Consequences

### Positive

- Dart/Rust 开发调试时可独立过滤（`Logger` 层次 / `RUST_LOG`），FRB 迁移后 Rust 内部可见。
- 移除 Talker 单例与 Riverpod `Talker` provider 的特殊依赖，改用标准 `logging` 生态。
- 保留文件日志能力，不丢失现有排障资产。

### Negative

- 终端中 Dart 与 Rust 日志格式仍分两路（stderr vs Flutter console），开发者需习惯双前缀；完全统一需 Phase 2 桥接。
- `package:logging` 迁移需一次性改动现有调用点并移除 Talker。

## Implementation

任务拆分见 GitHub Issues（父 issue 引用本 ADR）。

## Related

- [ADR-0002](./0002-rust-core-via-frb.md) — Rust 核心经 FRB 接管；日志需覆盖 `core/` 迁入模块。
- `docs/agents/coding-style.md` — `app/lib/core/` 为横切工具层，日志初始化归属此处。
