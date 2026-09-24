# ADR-0016: App preference 经 SharedPreferences 持久化

## Status

Accepted

## Context

ADR-0002 将应用级设置留在 Dart 侧，实现为手动维护的 `settings.json`（Application Support 目录）。库浏览/筛选偏好已独立使用 SharedPreferences；部分原 JSON 字段（`autoScan`、`enabledFormatGroups`）已一次性迁入 Rust SQLite 的 Library property。

继续维护单独的 `settings.json` 与 SharedPreferences 两套 Dart 侧持久化，重复了序列化/读写/错误处理逻辑。SharedPreferences 在各平台由系统或插件提供原子读写，底层亦为结构化存储（如 XML / plist），适合承载 App preference 而不必自管文件路径。

## Decision

1. **App preference**（主题、语言、阅读模式、Webtoon 参数、自动播放、桌面侧栏展开、应用更新偏好等）改由 **SharedPreferences** 持久化，不再写入 `settings.json`。
2. **Library browse preference** 继续直接使用 SharedPreferences（现状不变）。
3. **Library property** 继续经 FRB 写入 Rust SQLite（现状不变）。
4. 首次启动时若存在遗留 `settings.json`，一次性读入、经现有 `_migrateAppSettingJson` 规范化后写入 SharedPreferences，随后**删除**旧文件。Dart 侧偏好只保留 SharedPreferences 一份存储，不保留 `settings.json` 或其备份副本。
5. **本 ADR 不涉及 Rust SQLite 表结构变更**（无新 SeaORM migration、无 `core/` schema 改动）；但 Dart 侧须做迁移后清理：自 `AppSetting` 移除 `enabledFormatGroups`；调整 `CurrentLibraryNotifier` 的 autoScan / format groups 一次性迁移以适配 SharedPreferences 存储与 `settings.json` 删除；补迁移测试。
6. ADR-0002 中「`settings.json` 留 Dart」修订为「App preference 与 Library browse preference 留 Dart（SharedPreferences）；应用更新、打开文件管理器仍留 Dart UI 层」。

## Consequences

### Positive

- Dart 侧偏好存储统一为 SharedPreferences，减少自管 JSON 文件的 I/O 与路径耦合。
- 与已有 Library browse preference 模式一致，测试可复用 `SharedPreferences.setMockInitialValues`。
- ADR-0002「业务数据在 Rust、偏好留 Flutter」的分层不变。

### Negative

- 需一次性迁移路径；老用户 `settings.json` 须在首启迁移中无损，且迁移成功后旧文件即删、不可回滚至文件级备份。
- `AppSetting` 作为 aggregate 仍可在内存与 repository 层保留，但持久化键设计与版本迁移须明确（建议单 key 存 JSON blob + schema version）。
- 文档与 ADR-0002 / `rust-migration.md` 须同步修订。
