# 用户日志与支持（维护者指引）

面向维护者：引导用户收集诊断日志。设计见 [ADR-0004](../adr/0004-production-diagnostics.md)。

## 快速流程

1. 请用户在 **设置 → 诊断与支持** 开启 **详细诊断**（顶栏会出现提示条）。
2. 复现问题（如同步失败、某格式无法打开）。
3. 关闭详细诊断（可选，冷启动也会自动关闭）。
4. 点击 **导出日志** → 默认选 **脱敏** → 另存为 zip → 发给你。

## 包内文件

| 文件 | 内容 |
|------|------|
| `app_log.txt` | Dart UI / Repository / FRB 错误 |
| `rust_log.txt` | sync、reader、db 等 Rust 路径 |
| `*.bak` | 轮转备份（若有） |
| `diagnostics.json` | 版本、平台、导出时间、日志级别 |

## 本地查看 Rust 日志（开发）

```bash
# 仅 stderr
RUST_LOG=hentai_core::sync=debug flutter run

# 用户机器上文件路径（Windows 示例）
# %APPDATA%\...\logs\rust_log.txt
```

## 脱敏说明

默认导出会：缩短绝对路径、哈希化 `comic_id`。若路径本身是排障关键，请用户选 **完整日志** 并确认可接受隐私风险。
