# Library resource probe：轻量发现未入库 Resource

ADR-0020 将 Home library alert 的「可能有新 Resource」限制为 sync 时间与失败态启发式。用户需要 **在不全量 Library sync 的前提下**，对 Local / Remote library 发现根上新增或变更的 Resource，并在 Home page 给出可操作的 per-library 提示。

## Status

Accepted

## Context

- **Library sync**（`sync/orchestrator`）对 Local 库仍 **全树遍历**；incremental 仅跳过 archive **解析**，不跳过枚举。Remote 库每次 **递归 PROPFIND** 轻量登记（ADR-0008）。写库路径持 **全局 library 写锁**，与 Metadata refresh 互斥。
- 现有 **mtime/size 指纹** 存于 `comic_thumbnails`（`source_modified_ms`, `source_size`），供 incremental 跳过解析；**无**独立于 sync 的 Resource 索引快照；**无** fs watch。
- Home page（ADR-0020）情境 alert 需真实「发现 N 个新/变更 Resource」语义，但不能把 **枚举 + 解析 + 写库** 的完整 sync 伪装成探测。

## Decision

- 引入 **Library resource probe**：只读、**不持 library 写锁**、**不写 Comic/Series**；输出与上次成功 sync 快照的 diff 计数。
- 引入 **Library resource snapshot**：某 Library **上次成功 Library sync 结束** 时，由 sync 管线写入的 `(location_key → modified_ms, size, resource_type)` 索引；存 SQLite 专用表，**不**复用 `comic_thumbnails` 作探测基准（无 thumb 的 Comic 也应被快照覆盖）。
- **探测算法**（Local / Remote 共用接缝）：
  1. 复用 sync **枚举阶段**（`collect_from_directory` / `collect_remote_files`），respect Supported resource formats 与 nested Local root 排除；**不**调用 `resolve_scan_item` / 不打开 archive。
  2. 对每个 candidate `stat`（Remote 列举时已含 length/mtime 则复用）。
  3. 与 snapshot diff → `added_count`（新 location_key）、`changed_count`（mtime 或 size 变）、`removed_count`（快照有、枚举无）。
  4. Home alert **v1 仅消费 `added_count + changed_count`** 作为「待同步 Resource」；`removed_count` 可记录但不强推 alert（避免删盘文件骚扰）。
- **Remote library** 与 Local **同一套 diff 模型**；不可达时 probe 返回 unreachable，**不** mutate snapshot。
- **调度**（Dart）：应用 idle 后 + Home 可见 debounce；**每 Library 最短间隔 15 分钟**；**Library sync 运行中跳过** probe。结果供 Home library alert kind `pending_resources_detected`（依赖 #188 基座）。
- **不在本 ADR**：目录 mtime 剪枝、fs watch/inotify、probe 触发自动 sync、content hash。

## Considered Options

- **每次 probe 直接跑 incremental sync**：已是全树 walk + 可能解析；持写锁、耗时长，不符合「发现后再让用户决定 sync」。
- **仅用 `comics` 表 path + stat 对比**：无法发现从未入库的新文件；仍须全 walk，且 orphan 语义混乱。
- **仅 Local probe、Remote 仍用 stale 启发式**：实现简单但与多库 Remote 产品叙事不一致；Remote 已有轻量 PROPFIND 枚举，diff 成本可接受。

## Consequences

### Positive

- Home 可诚实展示「发现 N 个新/变更 Resource」，与 ADR-0020 alert 栈对齐。
- Probe 与 sync 枚举共享 `ResourceAccess` 与 format group 规则，行为一致。
- 单 Rust 业务缝可测（fake `ResourceAccess` + snapshot 表）。

### Negative

- 大库 probe 仍 **O(全树枚举)**，与 sync 扫描 IO 同级（仅省解析与写库）。
- 需 migration + sync writer 在成功路径维护 snapshot；sync 失败或取消 **不** 更新 snapshot。
- mtime-only diff 可能对 touch 误报「变更」；可接受，sync 增量可消化。
