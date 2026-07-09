# ADR-0004: 生产诊断与用户支持（日志导出）

## Status

Accepted

## Context

[ADR-0003](./0003-unified-dev-logging.md) Phase 1 已交付开发期可观测性：Dart `package:logging` 写 `logs/app_log.txt`，Rust `tracing` 输出 stderr。维护者排查用户问题时面临：

- Rust 日志不在导出路径内，sync/reader/db 上下文缺失；
- 用户无法自行打包日志发给维护者；
- 本地漫画库路径、书名、`comic_id` 等敏感信息不宜默认明文外传。

Phase 2 目标：**生产诊断 / 用户支持**——用户可在设置页开启短时详细诊断、导出 zip 日志包；维护者有足够上下文且默认脱敏。

## Decision

### 支持流程

1. **默认**：release 构建 Dart `INFO`、Rust `info` 写入各自日志文件，用户可一键导出 INFO 快照。
2. **深挖**：维护者引导用户开启「详细诊断」→ 复现 → 导出；Dart `FINE`、Rust `debug`，会话结束或应用冷启动后恢复默认。

### 日志来源与落盘

| 来源 | 文件 | 落盘方式 |
|------|------|----------|
| Dart | `logs/app_log.txt` | 现有 `LogFileWriter`（5MB 轮转，保留 3 份 `.bak`） |
| Rust | `logs/rust_log.txt` | `tracing-subscriber` 文件层，同目录、同轮转策略 |

**不**合并为单一时间线（避免 FRB 热路径桥接与格式对齐成本）。导出时 zip 打包两个文件及其备份。

Rust release 默认 `info` 写文件；`set_diagnostic_logging_frb(verbose: true)` 临时升为 `debug`，关闭或冷启动后恢复。`RUST_LOG` 环境变量在 subscriber 初始化时仍优先；诊断开关覆盖会话内默认级别，不持久化。

Dart 在 `init_db` 同级调用 `configure_rust_log_frb(app_data_dir)` 打开 Rust 文件 sink。

### 导出包（Issue ②）

- 当前 `app_log.txt` / `rust_log.txt` 及轮转备份（各最多 3 份）
- `diagnostics.json`：应用版本、平台、导出时间、当前日志级别、是否曾开 verbose 等
- 导出前弹窗：**脱敏**（默认）或 **完整**
- 脱敏规则（Issue ②）：绝对路径 → 文件名 + `<HOME>` 替换；`comic_id` 等业务 ID → 短哈希（前 8 位）
- 交互：脱敏选择 → 打包 zip → 系统另存为 → 成功提示

### 设置 UI（Issue ③）

- 新建设置分组 **「诊断与支持」**（位于「漫画库」与「关于」之间）
- 「详细诊断」开关：状态仅存 **Riverpod 内存**，不落盘；冷启动自动关闭
- 开启时：设置行 badge + Shell 顶栏细条双处提示；联动 Dart `Logger.root.level` 与 Rust FRB
- 「导出日志」按钮（依赖 Issue ②）

### 明确不做（Phase 2）

- Dart/Rust 单时间线合并、崩溃自动上传
- 分享面板（可后续 issue）
- 脱敏规则 JSON 可配置编辑器

## Consequences

### Positive

- 用户可自助导出，减少远程排障往返
- Rust 业务路径日志可随 zip 交付，与 ADR-0003 打点（#45）衔接
- 默认脱敏降低隐私风险，完整日志仍可选

### Negative

- 双文件 + 双轮转，导出前需收集多路径
- stderr 与文件层重复输出，磁盘略增（可接受）

## Implementation

| Issue | 范围 |
|-------|------|
| **①** | Rust `rust_log.txt` 落盘、轮转、`configure_rust_log_frb` / `set_diagnostic_logging_frb` |
| **②** | zip 打包、脱敏、`diagnostics.json`、另存为 |
| **③** | 设置页「诊断与支持」、verbose provider、顶栏提示 |

维护者指引见 `docs/agents/log-support.md`。

## Related

- [ADR-0003](./0003-unified-dev-logging.md) — Phase 1 日志基础设施
- [ADR-0002](./0002-rust-core-via-frb.md) — FRB 初始化与 API 边界
