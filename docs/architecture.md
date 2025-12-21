# 架构说明

## 分层与职责

- **Presentation**：UI、路由、Provider；只依赖 Domain 的实体/值对象与 UseCase（或通过 Provider 注入的 Repository）。
- **Domain**：实体（Entity）、值对象（ValueObject）、仓储接口（Repository）、用例（UseCase）；不依赖 Data 或基础设施。
- **Data**：仓储实现、DAO、Drift 表与迁移、扫描/同步服务、缓存服务；实现 Domain 的仓储接口，依赖 Drift/文件系统等。
- **Core**：错误类型、日志、通用工具；被各层引用。

## 依赖方向

Presentation → Domain (usecases, entities)
↑
Data (repository impls) → Domain (repository interfaces, entities)

- Domain 层不引用 Data 或 Presentation。
- 扫描服务返回与数据库无关的 DTO（如 `ScannedComicModel`），由 Data 层的 `ComicSyncService` 负责转换为 Drift companions 并写入数据库。

## 漫画同步流程

1. UI 调用 `SyncComicsUseCase()`。
2. UseCase 从 `DirectoryRepository` 取已选目录，再调用 `ComicRepository.ingestComicResources(dirs)`。
3. `ComicRepositoryImpl` 将同步委托给 `ComicSyncService.runSync`。
4. `ComicSyncService`：校验目录 → 使用 `DirectoryParseService` 与 `ComicScannerService.scanPath` 收集 `ScannedComicModel` → 将 DTO 转为 Companions → 计算与本地 DB 的差异 → 批量插入/删除并清理缓存。

## 枚举与表结构

- `lib/domain/enums/enums.dart` 中的枚举（如 `CategoryTagType`）被 Drift 表直接引用（如 `CategoryTags.type`）。
- 修改 Domain 枚举时需评估数据库 schema 与迁移（`database.dart` 的 `onUpgrade`）。

## 错误类型

- `AppException`：通用业务异常。
- `ValidationException`：参数/输入无效。
- `SyncException`：同步/扫描过程错误。
- `NotFoundException`：资源不存在。
- `ConflictException`：状态或唯一约束冲突。

Data 层在捕获底层异常时可包装为上述子类，便于 UI 区分提示或重试策略。

## 同步日志与报告约定

- 每次调用 `ComicSyncService.runSync` 视为一次同步任务，并生成一个 `syncId`（当前为毫秒时间戳）。
- 与本次任务相关的日志会带上统一前缀与阶段标签，典型格式如下：

  - `[SYNC][START][syncId=...] rootDirs=...`
  - `[SYNC][SCAN_COLLECT_PATHS][syncId=...] collectedPaths=... roots=...`
  - `[SYNC][SCAN_TO_DTO][syncId=...] total=... ok=... failed=...`
  - `[SYNC][DIFF][syncId=...] newComics=... removedComics=... newChapters=... removedChapters=...`
  - `[SYNC][APPLY][syncId=...] willInsertComics=... willDeleteComics=...`
  - `[SYNC][APPLY][syncId=...] DB_OP:SUCCESS insertedComics=... deletedComics=...`
  - `[SYNC][END][syncId=...] durationMs=...`

- 若发生错误，则会以：

  - `[SYNC][ERROR][syncId=...] message=...`
  - `[SCAN][ERROR] path=... message=扫描路径失败`

  的形式输出，既包含阶段信息，也包含路径等上下文。

- 归档与封面修复等辅助流程采用类似约定：

  - 归档：`[ARCHIVE][START] ...` / `[ARCHIVE][END] ...` / `[ARCHIVE][ERROR] ...`
  - 封面修复：`[REPAIR][START] ...` / `[REPAIR][END] ...` / `[REPAIR][ERROR] ...`

借助上述约定，可以在不引入额外存储的前提下，从日志中还原一次同步或归档/修复的“报告”，未来若需要在 UI 中展示同步历史，也可以按 `syncId` 或前缀进行筛选与聚合。
