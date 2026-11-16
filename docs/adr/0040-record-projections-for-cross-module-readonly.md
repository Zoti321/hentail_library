# ADR-0040: 跨模块只读投影使用匿名 record

## Status

Accepted

## Context

[#488](https://github.com/Zoti321/hentail_library/issues/488) 收敛 comic/series 与壳 `library_browse` 的通信边界时，库页双 Tab 需要 owner 模块向壳交付「列表行」这种极薄的只读数据：

- comic：`comicId` / `title` / `pageCount` / `path`
- series：`id` / `name` / `volumeCount`

此前这些行被定义为具名类（`ComicBrowseListItem`、`SeriesBrowseListItem`），住在 owner `domain/`，导致壳 deep import owner domain（M1 baseline 6 条），并在 owner 侧制造「壳专用 DTO」的错觉。

## Decision

### 1. 适用边界

跨模块**只读标量投影**使用 Dart 3 匿名 record，且同时满足：

- 字段 ≤ 6 个，全部为标量或 `String`；
- 无方法、无 `copyWith`、无 `sealed`/继承、无文档注释挂载点；
- 生命周期仅覆盖「owner 查询 → 壳展示」一次传递；
- 需要结构相等（record 天然按字段名与值判等，顺序无关）。

典型落点：仓储查询返回值、壳的 list item、cross-feature 只读摘要。

### 2. 禁止用法

- **禁止**把 record 具名化（`typedef` 以外的 class / extension type）后再跨模块导出，等价于换皮 DTO；
- **禁止**用于需要 `copyWith`、领域行为、事件载荷（事件必须是 `shared/domain/events` 的具名类型，ADR-0039）；
- **禁止**用于命令参数（命令走 Port 的具名 DTO，见 ADR-0034 / ADR-0039）；
- **禁止**为 record 再写第二套 `shared/domain` DTO 镜像。

### 3. 演进成本是特性

字段增删会让所有解包点编译失败（Dart 命名域解包必须列全字段），这是选择 record 的核心理由：跨模块契约变化必须显式暴露，而不是被 `copyWith`/可选字段悄悄吞掉。

### 4. 门禁

- `test/architecture/module_boundary_test.dart`：范围内模块（comic/series/library_browse）跨模块只允许 public 面，零 baseline；
- 列表行形状由仓储签名强制（`PagedResult<({...})>`），不另设类型测试。

## Consequences

### Positive

- 删除 6 条 M1 baseline，壳不再 deep import owner `domain/`。
- 「字段少到不值得一个类」的跨模块数据不再膨胀成 DTO 层。

### Negative

- 报错信息只显示 `PagedResult<记录类型>` 不匹配，字段漂移定位成本略高；缓解：在仓储签名旁注释其镜像的壳 typedef（如 `ComicBrowseViewObject`）。

## References

- ADR-0034（public only / token 归属）、ADR-0036（comic/series 模块与禁止边表）、ADR-0039（命令走 Port、事实走事件）
- GitHub #488
- `app/lib/features/comic/domain/repositories/comic_catalog_repository.dart`、`app/lib/features/series/domain/series_repository.dart`
