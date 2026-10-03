# ADR-0024: Author 稳定身份与创作平台外链

## Status

Accepted

## Context

Author 原为名字主键的 Named metadata facet（`authors.name` + `comic_authors.author_name`），只能表示 Comic 署名字符串。产品要支持 Author 详情（外链、认证标识、后续平台形象解析与 alias），且用户心智是「改显示名不等于换人」：外链与缓存应挂在稳定身份上，而非随 rename 换键。

备选曾包括：继续名字主键并在 rename 时迁移子行；或 Author 与「Author profile」双实体。前者与「改名只改 name 字段」冲突；后者造成词汇与备份长期分叉。

## Decision

- **Author** 升级为稳定身份实体（见 `CONTEXT.md`）：有稳定 id、可变且全局唯一的显示名（大小写敏感）；Comic 经 junction 附着 `author_id`。
- 现有名字字典行一次性迁移为 Author（生成 id，原 name 作显示名）；`comic_authors` 改为挂 id。
- **Author link** 由用户手填（平台 + URL；可空 `platform_display_name` 供后续解析写入）。**Creative platform** 闭集与优先级：Pixiv > X > Patreon > FANBOX > Discord；Other 可存但不参与 Verified author、Author alias、形象解析。
- **Verified author** = 至少一条 Creative platform 链接；非外部平台官方认证同步。
- **Author alias** 为领域词：平台显示名与当前显示名不一致者按 Creative platform 优先级展示；本决策不要求首版 UI 渲染 alias。
- Author 形象解析为可替换端口：按上列平台序尝试，失败则回退全库可见（含 Healthy mode）下 `title_sort_key` 第一本封面；平台抓取与缓存表不在本 ADR 范围内。
- Author 不再塞回纯名字 `JunctionNamedFacet` 模型；Tag / Parody / Character 仍走名字字典。管理入口可与元数据其它 facet 并列。
- Library browse preference 的 Author 筛选按 Author id 持久化，UI 渲染当前显示名（见 `CONTEXT.md`）。
- Metadata backup 导出/导入包含 Author link；按显示名 upsert Author 并幂等合并链接。

## Consequences

### Positive

- rename 只更新显示名，外链与未来形象缓存不丢键。
- 认证、外链、详情聚合有稳定锚点；与「无社交账号体系、仅手填链接」的产品边界兼容。

### Negative

- 迁移与 FRB/筛选/备份/表单全链路要切 id；Author 与 Tag 等名字 facet 管线不对称，认知与代码都要分清。
- 旧版以作者**名**存的 browse preference 需一次性迁到 id；无法匹配的项丢弃。
- 详情跨库聚合与 `/searched`（当前库）口径不一致，属有意取舍。

## References

- `CONTEXT.md` — Author / Verified author / Author alias / Creative platform / Author link / Named metadata facet / Library browse preference
- ADR-0007 — Metadata field lock（Comic 上 authors 锁附着集合，不锁显示名）
- ADR-0011 — Tag 不做 EhTag 命名空间（Author 外链亦非平台账号体系）
- ADR-0016 — Library browse preference 留在 SharedPreferences
