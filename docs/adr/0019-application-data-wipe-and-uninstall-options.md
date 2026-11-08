# ADR-0019: 应用数据清除与卸载数据选项

## Status

Accepted（部分 Decision 已废止，见实现修订）

> **实现修订（2026-11-08）**：
> 1. 取消 Windows Inno 卸载向导「同时删除用户数据」勾选；卸载只移除安装目录。
> 2. 移除应用内 **Application data wipe**（设置页「清除全部应用数据」及确认流）；Application data 与多数桌面应用一样随卸载保留在用户目录，需清空时由用户手动删除该目录。
> 下文 Decision 历史描述保留作语境。

## Context

用户曾期望卸载或重置应用后，能可控地保留或删除本机 **Application data**（SQLite、自动元数据备份、日志、缓存与应用偏好），同时不触碰 Library root 中的漫画 Resource 与用户手动导出到外置目录的 `.hlmeta.json.gz`。Wayfinder #157 / #167 曾收敛为「应用内 wipe + Windows 卸载可选删除」。

后续产品选择与多数桌面应用对齐：**卸载与设置均不提供清数据入口**。

## Decision

1. **不再提供 Application data wipe（应用内）**
   - 设置 → 存储与日志 仅保留诊断与日志导出。
   - 需要清空本机状态时，用户自行删除当前 **App data profile** 目录（ADR-0010）。

2. **Windows Inno 卸载**
   - 仅卸载 Program Files 安装目录与快捷方式；**不**删除 `{userappdata}\com.example\hentai_library\`。

3. **Rust 清场 API**
   - `shutdown_app_data_frb` 可仍留在 core（关闭 DB / 日志句柄等）；无产品 UI 编排调用。目录删除不由应用代劳。

## Consequences

### Positive

- 卸载 / 重装可继续使用原 Application data；行为符合常见桌面应用预期。
- 设置页少一项高危操作，降低误触。

### Negative

- 无应用内一键清空；依赖用户知悉 App data 路径或通过系统手段清理。
- 移动平台卸载仍可能由系统删除沙箱；与桌面「残留 AppData」不完全对称。

### Considered Options

- **应用内 wipe + Inno 可选删除**：曾作 v1；后改为「卸载与设置均不清数据」；不采纳。
- **仅文档说明 AppData 路径**：仍可作为支持渠道补充；不恢复应用内 wipe。
