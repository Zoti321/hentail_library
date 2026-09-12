# Path migration：位置键变化时保留用户态

Comic identity 仍锚定资源位置键（ADR-0001）。位置变化会生成新 `comicId` / `seriesId`；若要保留用户元数据与阅读历史，须**显式** Path migration，而不是改成内容哈希身份。

## Decision

- **Library sync（Comic）**：在 removed / added 之间用弱指纹 `(resource_type, resource_size, page_count)` 做 **1:1 唯一**配对；成功则 rekey 并按 Metadata field lock merge，失败（歧义或指纹不同）则 orphan + 新导入。
- **Library sync（Series / F0）**：Comic 1:1 配对已知后，若某 Folder series 的**全部**成员均出现在这些配对中且落在**同一**新父路径，则将该 Series rekey 到新 `folder_path` / `seriesId`，并保留连载状态、计划总卷数、字段锁、自定义名（name-locked）、系列封面，以及成员 `sort_order` / `sort_order_locked`（经 Comic rekey 后的 membership）。未锁定的显示名（及 name sort key）随新文件夹 basename 更新。额外出现在目标夹中、未参与 Comic 迁移的新成员**不**阻断 Series 迁移。配对歧义、仅部分成员换夹、或多个 Series 争用同一目标 id 时不迁 Series，交由 orphan + 新建。不引入文件夹内容哈希身份。
- **Local 改 Library root**：在保存新根时（与写 `root_path` 同一事务），若新根可读，则按**相对旧根的路径**对 Comic 与 Series 做前缀 remapping 并 rekey；相对路径在新根下不存在的条目不迁。新根不可读则只更新 `root_path`，不迁。不自动 Library sync。
- **不在本决策内**：跨 Library 的自动 Series 迁移；Remote 改 WebDAV 根的前缀 remapping；以文件夹内容哈希作为 Series 身份或主匹配器。

与 Library sync / Metadata refresh 共用库级写锁；改根或 Path migration 成功后使相关阅读会话失效。

## Consequences

- 单文件改名在指纹唯一时可保留进度与用户元数据；同质多本同时改名仍可能丢用户态（有意保守）。
- 整库根目录改名/搬家在相对树不变且新根可读时，Comic 与 Series 用户态可保留。
- 同库内系列夹 rename/move（及 Remote 同库父路径变化）在 F0 成立时可保留 Series 用户态；部分成员换夹或指纹歧义则不迁 Series。
- 文档与实现以「Path migration」为领域用语；避免把弱指纹或 F0 误称为内容身份 / 系列内容哈希。
