# Path migration：位置键变化时保留用户态

Comic identity 仍锚定资源位置键（ADR-0001）。位置变化会生成新 `comicId` / `seriesId`；若要保留用户元数据与阅读历史，须**显式** Path migration，而不是改成内容哈希身份。

## Decision

- **Library sync（Comic）**：在 removed / added 之间用弱指纹 `(resource_type, resource_size, page_count)` 做 **1:1 唯一**配对；成功则 rekey 并按 Metadata field lock merge，失败（歧义或指纹不同）则 orphan + 新导入。
- **Local 改 Library root**：在保存新根时（与写 `root_path` 同一事务），若新根可读，则按**相对旧根的路径**对 Comic 与 Series 做前缀 remapping 并 rekey；相对路径在新根下不存在的条目不迁。新根不可读则只更新 `root_path`，不迁。不自动 Library sync。
- **不在本决策内**：仅改系列目录名时的 Series 用户态迁移；Remote 改 WebDAV 根的前缀 remapping。

与 Library sync / Metadata refresh 共用库级写锁；改根或 Path migration 成功后使相关阅读会话失效。

## Consequences

- 单文件改名在指纹唯一时可保留进度与用户元数据；同质多本同时改名仍可能丢用户态（有意保守）。
- 整库根目录改名/搬家在相对树不变且新根可读时，Comic 与 Series 用户态可保留。
- 文档与实现以「Path migration」为领域用语；避免把弱指纹误称为内容身份。
