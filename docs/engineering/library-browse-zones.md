# `library_browse` 内部分区（方案 A）

**不新增 Wayfinder module**；在 `features/library_browse/` 内用子目录表达 **Comic / Series / Library browse 壳** 三条边界。  
**Catalog 实体 DTO**（`Comic`、`Series` 等）仍 @ `shared/domain`（**ADR-0035**），不在本 feature 内「独占实体」。

## 分区一览

| 分区 id | 语义 | 新代码落点 |
| --- | --- | --- |
| **`domain/comic/`** | 单本漫画：按 id 查询、目录 catalog 写入、缩略图、用户元数据、展示标题、metadata 表单的 smart facet | Repository 契约、comic 侧纯函数 |
| **`domain/series/`** | 系列：Series 仓储、系列列表投影/排序/连载筛选、Prefer library root series | `series_repository` 及系列 browse 规则 |
| **`domain/browse/`** | **当前库** Comics/Series Tab 的筛选/排序/分组 intent（与库页 preference 对齐） | `library_comic_*`、`library_age_restriction_*`、facet 筛选 selection 等 |
| **`presentation/comic/`**（待迁） | 漫画详情、漫画 metadata 编辑、漫画相关 VM | 见下「迁移阶段」 |
| **`presentation/series/`**（待迁） | 系列详情、系列 metadata 编辑、系列相关 VM | 同上 |
| **`presentation/browse/`**（待迁） | `library_md3e_*`、搜索页、双 Tab catalog controller、筛选 sheet | 同上 |
| **`presentation/author/`**（待迁） | 作者详情（Named 面与 catalog 交叉，单独一条） | 同上 |
| **`presentation/catalog/`**（可选） | 双 Tab 共用的分页/选择/ revision 协调 | 与 browse 壳紧耦合时可暂留 `view_models/` 根 |

跨分区 **允许** feature 内 deep import；跨 **feature** 仍仅 `library_browse/public.dart`（ADR-0034）。

## `domain/` 状态

**已完成（2026-11-02）**：原 `domain/*.dart` 已迁入 `comic/`、`series/`、`browse/`。  
`shared/domain/**` strangler export 路径已同步；feature 内请 import **`features/library_browse/domain/<zone>/...`** 或继续经 shared shim（过渡期）。

## `data/` 与 `presentation/view_models/` 状态

**已完成（2026-11-02）**：

| 路径 | 内容 |
| --- | --- |
| `data/comic/` | `comic_repository_impl`、`comic_frb_mapper` |
| `data/series/` | `series_repository_impl` |
| `presentation/comic/view_models/` | 漫画 metadata、详情导航、smart facet 等 |
| `presentation/series/view_models/` | 系列详情、metadata editor、成员 catalog |
| `presentation/browse/view_models/` | 库页 Tab、筛选、搜索、双 catalog controller |
| `presentation/catalog/view_models/` | `catalog_pagination_engine`、`catalog_selection_notifier` |
| `presentation/author/view_models/` | `author_detail_notifier` |

内部聚合 export：`presentation/library.dart`（相对路径已指向各 zone）。

## 迁移阶段（presentation views / patterns）

新功能：**先选分区再建文件**；禁止在 `domain/` 根再堆平铺文件。

## 与 owner 表关系

Repository 真源仍在 **`library_browse/domain/<zone>/`**，归属语义见 [`shared-domain-ownership.md`](shared-domain-ownership.md)（browse owner 筛选规则 + comic/series 仓储）。

## 参考

- ADR-0035（Catalog Shared Kernel 留 shared）
- ADR-0031（组件随 feature 迁入，第二 consumer 再升 shared/ui）
