# v1 下线清理清单（v2 迁移后）

本清单用于在 v2 链路稳定后，逐步移除 v1 数据层/领域层代码。

## 前置验收

- [ ] `useV2PipelineProvider` 长期开启后，主流程（扫描、列表、详情、阅读、标签）无回归
- [ ] v2 单元测试稳定通过（DAO/Repo/UseCase）
- [ ] 至少一轮真实目录数据对账完成（数量、标题、标签、分级）

## 第一批可移除（低风险）

- [ ] v1 专用 provider 标记废弃并替换调用点：
  - `comicRepoProvider`
  - `archiveChaptersUseCaseProvider`
  - `incrementReadCountUseCaseProvider`
- [ ] UI 中直接依赖 v1 `CategoryTagType.series` 的旧筛选分支

## 第二批可移除（中风险）

- [ ] v1 `ComicRepositoryImpl` 及其关联旧同步链路：
  - `ComicSyncService`（仅在确认不再写 v1 DB 后）
  - 旧 `syncComicsUseCase` 适配入口
- [ ] v1 tag 管理仓储调用路径（替换为 `LibraryTagRepository`）

## 第三批可移除（高风险）

- [ ] v1 数据库定义与 DAO（确认无页面/服务依赖）
  - `lib/data/resources/local/database/*`
- [ ] v1 领域实体与值对象（确认 UI/UseCase 已全部改为 v2）
  - `lib/domain/entity/comic/*`
  - `lib/domain/value_objects/comic_*`

## 收尾

- [ ] 删除 `useV2PipelineProvider` 开关，固定使用 v2
- [ ] 删除迁移适配层（v2 -> v1 comic 兼容映射）
- [ ] 更新 README：移除 v1 并行说明，保留 v2 运行/排障说明

