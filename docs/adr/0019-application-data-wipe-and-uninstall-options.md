# ADR-0019: 应用数据清除与卸载数据选项

## Status

Accepted

## Context

用户期望卸载或重置应用后，能可控地保留或删除本机 **Application data**（SQLite、自动元数据备份、日志、缓存与应用偏好），同时不触碰 Library root 中的漫画 Resource 与用户手动导出到外置目录的 `.hlmeta.json.gz`。Wayfinder #157 / #167 已收敛规格。

平台差异：

- **Windows（Inno Setup）**：卸载 Program Files 安装目录时，Application Support 默认残留；需在卸载向导提供可选删除。
- **Android / iOS / macOS / Linux**：无统一卸载钩子或卸载即删沙箱；需应用内 **Application data wipe** 与说明文案互补。

## Decision

1. **Application data wipe（应用内）**
   - 入口：设置 → 诊断与支持 →「清除全部应用数据」。
   - 守卫：Library sync 进行中禁用。
   - 编排：`shutdown_app_data_frb()` → 递归删除当前 **App data profile** 根目录 → `SharedPreferences.clear()` → 清 `imageCache` → 提示重启 → 退出进程。
   - 失败：不清 prefs，展示路径，再退出。
   - 范围：仅当前构建 profile（ADR-0010）；不删 Library root、不删外置手动导出。

2. **Windows Inno 卸载（v1）**
   - 卸载页复选框，**默认不勾选**。
   - 勾选时删除 `{userappdata}\com.example\hentai_library\`；**不删** `hentai_library_dev`。
   - 文案提示先关闭应用；文件锁时尽力删。
   - **v1 限制**：Inno 仅删 Application Support 目录，**不清 SharedPreferences**；完整干净需应用内 wipe 或手动删 prefs。

3. **Rust 清场 API**
   - `shutdown_app_data_frb`：`clear_reader_sessions` → `shutdown_db` → 关闭 Rust 日志文件句柄；目录删除由 Dart 负责（ADR-0002 薄边）。

## Consequences

### Positive

- 用户可主动、可预期地清除本机应用状态，与元数据自动备份生态（#164）互补。
- Windows 卸载默认保留数据，与现状一致；高级用户可勾选删除。
- Release / dev profile 隔离保持不变（ADR-0010）。

### Negative

- Inno v1 勾选删除后 prefs 可能残留，需文档与应用内 wipe 兜底。
- 移动平台卸载仍无法拦截系统删沙箱；仅能通过说明引导用户先 wipe 或外置备份。

### Considered Options

- **仅文档说明 AppData 路径**：不可发现、易误删错目录；不采纳。
- **Inno 默认勾选删除**：与「便于重装恢复」目标冲突；不采纳。
- **Inno 同时清 SharedPreferences**：v1 无稳定跨安装器 API；延后，应用内 wipe 覆盖完整场景。
