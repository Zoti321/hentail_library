# UI 流畅度性能调优报告

> 调研日期：2026-09-04  
> 范围：减少 UI 卡顿、提升滚动/翻页/打开页交互流畅度  
> 仓库约定：本仓库原先无独立 research 目录；本报告落在 `docs/research/`（与 `docs/adr/`、`docs/agents/` 并列）。

## 目标与边界

**目标**：找出会拖垮交互帧预算（约 16ms @60fps）的主 isolate / 布局 / 重建路径，给出可落地的调优优先级。

**明确不做（长时后台批处理）**

| 排除项 | 定位（仅索引，不优化吞吐） |
|--------|---------------------------|
| 库扫描 / Library sync | `app/lib/ui/features/shell/state/scan_library_controller.dart`、`.../di/library_sync.dart`、Rust sync API |
| 缩略图**生成**流水线 | `ComicCover`/`ensure_thumbnail_*`、`ThumbnailEventCoordinator`、`core/.../api/thumbnail.rs` |
| 元数据批量刷新 | `metadata_refresh_controller.dart`、`di/metadata_refresh.dart` |

说明：封面/页图在 **UI 显示路径上同步读库或 sync FRB** 属于交互热路径，与「优化生成算法」区分开，仍纳入本报告。

---

## 结论摘要

当前最伤流畅度的主链路：

1. **库页网格用 `shrinkWrap` 嵌套 `GridView`**，一页可挂 50～500 张卡片，抵消虚拟化（官方文档：shrink wrapping **显著更贵**）。
2. **大量业务 FRB 标为 `#[frb(sync)]` + Rust `block_on`**，分页/封面读/页列表在 UI isolate 上同步执行。
3. **扫描写入期间** `PRAGMA data_version` ~400ms 轮询 → revision → 活跃 catalog 全量重载 + 整页 rebuild；叠加 shrinkWrap 后「边扫边逛」极易掉帧。
4. **阅读器**：稳态翻页 I/O 已走 async FRB，但 **预取与显示 ImageCache key 不一致（预热常失效）**、**`ReaderPage` 整包 watch 导致每翻页整树重建**、打开路径 sync `open`/`loadPageList`（可能双次列页）仍会卡首屏。

---

## A. UI 热路径地图

### Library（漫画 / 系列目录）

```
LibraryPage
 ├─ watch libraryCatalogRevisionCoordinatorProvider   // 整页订阅 revision 快照
 ├─ watch libraryCatalogInactiveSubscriptionProvider
 ├─ Scroll → libraryCatalogCoverViewportProvider.updateRange
 ├─ Header counts ← catalog controllers
 ├─ LibraryComicsBlock / LibrarySeriesBlock
 │     └─ libraryComics|SeriesCatalogController (keepAlive)
 │           ├─ watch libraryCatalogWatchRevision(target)
 │           │     活跃=立即 / 非活跃=3s debounce
 │           └─ comicRepo|seriesRepo.fetch*Page + countAll  (sync FRB + block_on)
 │     └─ AnimatedLibraryCatalogGridSliver
 │           └─ shrinkWrap GridView.builder → ComicCard / SeriesCard
 │                 └─ ComicCoverContent
 │                       ├─ watch libraryCatalogCoverViewportProvider (全 Set)
 │                       └─ comicCoverProvider → sync find/ensure thumbnail
 └─ revision 源:
       libraryRevisionProvider ← FRB watchComicChanges (~400ms data_version)
       + onSyncSucceeded.notifyExternalChange()
```

主要文件：

- `app/lib/ui/features/library/views/library_page/library_page.dart`
- `.../widgets/animated_library_catalog_grid_sliver.dart`
- `.../view_models/library_comics_catalog_controller.dart`
- `.../view_models/library_catalog_revision_coordinator.dart`
- `core/crates/flutter/src/api/comic.rs`（`watch_comic_changes`、`fetch_comics_page_frb`）

### Home

```
HomePage
 ├─ homePageCountsStreamProvider  ← Rust watch_home_page_counts (~400ms)
 ├─ deferredSectionsReady → Hero / ContinueReading
 └─ ContinueReading → ReadingHistoryCard → ComicCoverContent
```

### History

```
HistoryPage
 ├─ historyPagedFeedController（分页 + debounce）
 └─ SliverGrid.builder + cacheExtent: 1200 → ReadingHistoryCard
```

相对健康：已用真虚拟滚动；封面无 `gridIndex` 视口分级。

### Reader

```
ReaderPage（整包 watch readerPageViewModel → 含 currentIndex/showControls/…）
 └─ ReaderContent → ReaderViewportHost
      ├─ PagedViewport / DualPageViewport → PageView.builder
      ├─ ContinuousVerticalViewport → ScrollablePositionedList.builder
      ├─ comicImages ← loadPages（sync loadPageListFrb；与 open 路径可能各走一遍）
      ├─ 每页 comicReaderPage（autoDispose）← async loadReaderPageFrb
      └─ AppComicImage(cacheWidth) + 命名 ImageCache(maxSize≈7) + prefetch(±2)
           ⚠ precache 未传 cacheWidth → ResizeImage key 与显示不一致
```

### Shell / 诊断

- 侧栏：库列表通常不大；扫描进度 watch 面过宽。
- 日志：`configureAppLogging`；诊断 Verbose → Dart FINE + Rust debug（ADR-0004）。

### 已有正向能力

| 实践 | 位置 |
|------|------|
| 活跃/非活跃 revision 分流 + 3s debounce | `library_catalog_revision_coordinator.dart` |
| 封面视口优先级 + `setEquals` 短路 | `library_catalog_cover_viewport_notifier.dart`、`comic_cover_content.dart` |
| 卡片 `RepaintBoundary` | `catalog_cover_card_shell.dart` |
| 封面 decode `cacheWidth` | `card_letterboxed_cover_image.dart`、`image_decode_cache_size.dart` |
| 封面并发门闸 `ComicCoverLoadGate(max=8)` | `comic_cover_load_gate.dart`（对 **sync** FRB 无法真正并行） |
| 分页默认 50 | `kDefaultPageSize` / catalog controllers |
| 历史页真 `SliverGrid.builder` | `history_page.dart` |
| 系列详情真 `SliverGrid` | `series_detail_comics_grid.dart` |
| 阅读器邻居预取 + 专用 ImageCache | `reader_prefetch_*`、`reader_image_cache.dart`、`image_cache_config.dart` |
| 页加载 async FRB + `spawn_blocking`（对照） | `core/.../api/reader.rs` `load_reader_page_frb` |
| Home 分区延迟挂载 | `home_page.dart` |

---

## B. 发现清单（按优先级）

### P0 — 应优先动手

#### P0-1 库页网格 `shrinkWrap` 抵消虚拟化

- **风险**：外层已是 `CustomScrollView`，内层 `GridView.builder(shrinkWrap: true, NeverScrollableScrollPhysics)` 需按内容测高；一页默认 50、设置可达 **500**（`kLibraryPageSizeOptions`），布局/构建成本随 pageSize 近似线性爆炸。官方 API：shrink wrapping **significantly more expensive**，滚动时尺寸可能反复重算。
- **证据**：`animated_library_catalog_grid_sliver.dart` L68–90；对照 `series_detail_comics_grid.dart` L62–81、`history_page.dart` L104/L304（真 Sliver）。
- **建议**：改为真正的 `SliverGrid`；排序 FLIP（`ReorderableBuilder`）仅在需要时启用或只动画可见项。
- **收益**：库页滚动/换页布局 — **高**。

#### P0-2 热路径 FRB 大量 `sync` + `block_on`

- **风险**：同步 Dart API 在 UI isolate 执行；DB 查询经 `runtime::block_on` 占满主 isolate，翻页、筛选、进详情、封面刷入时掉帧。Dart 侧 `Future` 包装（`guardFrbSync`）是假异步。
- **证据**：
  - `core/crates/flutter/src/api/comic.rs` L199–208：`#[frb(sync)] fetch_comics_page_frb` + `block_on`
  - 同文件 `search_by_keyword_frb`、`count_all_comics_frb`、`find_comic_by_id_frb` 等均为 sync
  - `series.rs` / `history.rs` / `home.rs` / `thumbnail.rs` 大量 sync
  - `reader.rs`：`load_page_list_frb` sync（L49–57）；对照 `load_reader_page_frb` **async**（L70+）
  - `ComicRepositoryImpl.fetchComicsPage` / `countAll`：`guardFrbSync(...)`
- **建议**：交互热路径（分页、find、搜索、封面读、页列表）改为 **async FRB**；sync 仅留给极轻量纯计算（如 `comic_id_from_path`）。Repo 去掉「Future 包 sync」。
- **收益**：库翻页/筛选、详情打开、封面到达 — **高**。

#### P0-3 封面显示路径 sync 读缩略图（非生成算法）

- **风险**：网格滚动时大量 `comicCoverProvider` 触发 sync `find`/`ensure`；`ComicCoverLoadGate` 在单 isolate 上无法并行化 sync 调用，只会排队堵帧。
- **证据**：`comic_cover_providers.dart`（ensureLoaded / find 路径）；`comic_cover_load_gate.dart` L8–30；`thumbnail.rs` sync `find_thumbnail_*` / `ensure_thumbnail_*`。
- **建议**：封面**读取**改为 async；UI 消费缓存 bytes；缺失用占位，后台完成后按 comicId invalidate（生成队列本身仍排除）。
- **收益**：库滚动掉帧 — **高**。

#### P0-4 扫描写入期 revision 亚秒级触发活跃 catalog 全量重载

- **风险**：不优化扫描吞吐，但「边扫边逛」时 UI 被拖垮：`data_version` 每 ~400ms 变化 → bump revision → 活跃 Tab 立即 `_load`（`fetchPage` + `countAll`，皆 sync）→ `LibraryPage` 整页 watch coordinator 重建。叠 P0-1 即整页 shrinkWrap 子树反复换血。
- **证据**：
  - `comic.rs` L328–344：`sleep(400ms)` + `read_data_version`
  - `library_revision_notifier.dart` L64–69
  - `library_catalog_revision_coordinator.dart` L86–94（活跃立即推）
  - `library_comics_catalog_controller.dart` L57–69
  - `library_page.dart` L151：`ref.watch(libraryCatalogRevisionCoordinatorProvider)`
- **建议**：扫描进行中对 catalog revision **合并/暂停/降频**（或仅结束时 + 节流 bump）；`LibraryPage` 勿整页 watch coordinator（listen / 拆叶子）。
- **收益**：「边扫边逛」流畅度 — **高**。

#### P0-5 封面视口 `Set` 被每个格子全量 watch

- **风险**：滚动更新可见索引集合时，所有已构建且带 `gridIndex` 的 `ComicCoverContent` 一起 rebuild；在 shrinkWrap 下≈整页。
- **证据**：`comic_cover_content.dart` L72–77；`library_page.dart` L109–111、滚动 Notification 调度。
- **建议**：per-index `select` / 局部 Provider，或仅向进出视口的索引通知。
- **收益**：滚动重建成本 — **中高**（依赖 P0-1）。

#### P0-6 阅读器预取与显示 ImageCache key 不一致（预热常失效）

- **风险**：显示侧 `ResizeImage(cacheWidth: …)`；`precacheWindow` → `_resolveReaderImageProvider` **不传 `cacheWidth`** → 预解码写入的 cache key 与显示不同，邻居预取白做，翻页仍冷解码。
- **证据**：`reader_prefetch_controller.dart` L101–123 vs `reader_image_item.dart` L49–65；工厂在 `reader_image_cache.dart` L25–55。
- **建议**：预热传入与 viewport 相同的 `slotLogicalWidth`/dpr 算出的 `cacheWidth`；或统一同一 provider 工厂。
- **收益**：翻页/条漫稳态流畅度 — **高**（纯 Dart、改动面小）。

#### P0-7 `ReaderPage` 整包 watch ViewModel → 每翻页整树 rebuild

- **风险**：`ref.watch(readerPageViewModelProvider)` 含 `currentIndex` / `showControls` / `readingMode` 等；每次翻页重建 Content + Top/Bottom chrome；放大 `existsSync` 与解码成本。Viewport 层对 `currentIndex` 的 `select` 无法抵消父级整页重建。
- **证据**：`reader_page.dart` L57–62、L290–401；`reader_controller.dart` L75–114。
- **建议**：拆分 provider（chrome / index / mode）；Content 子 `Consumer` + `select`；`initialPage` 仅打开时冻结。
- **收益**：翻页主线程 — **高**。

---

### P1 — 明显交互卡顿

#### P1-1 搜索页无分页 + sync 全量结果 + vocabulary 全表

- **证据**：`library_search_page_providers.dart` L26–27、L62、L95；`search_by_keyword_frb` 返回 `Vec` 且 sync。
- **建议**：搜索分页 API；vocabulary keepAlive；结果区虚拟滚动。
- **收益**：打开/搜索 — **中高**。

#### P1-2 阅读器 build 路径 `File.existsSync`

- **证据**：`reader_image_item.dart` L51–55、L86–88、L165–174；`reader_image_cache.dart` L45–46。
- **建议**：存在性并入 async payload，或失败走 `loadStateChanged`，避免 build 内 sync IO。
- **收益**：翻页微卡顿 — **中**（叠 P0-7 更明显）。

#### P1-3 打开阅读器 sync `open` / `loadPageListFrb`（可能双次列页）

- **证据**：`reader.rs` sync `open_reader_frb` / `load_page_list_frb`；`read_session_providers.dart` 中 `readerSessionOpen` 与 `comicImages` 各可能走 `loadPages`。
- **建议**：改为 async + `spawn_blocking`（对齐 `loadReaderPageFrb`）；合并打开与列页，避免双次 sync。
- **收益**：进阅读器首屏 — **中高**。

#### P1-4 连续模式位置监听 / 预取 generation 抖动 / 内存缓存过小

- **证据**：`continuous_vertical_viewport.dart`（listener deps 含 `currentIndex`）；`reader_prefetch_controller.dart` L20–23、L51–61（每次 `warmWindow` `bumpGeneration`）；`reader_image_cache.dart` L17（`maximumSize = neighbor*2+3` ≈ **7**）；`comicReaderPageProvider` **autoDispose**。
- **建议**：窗口未变则不 bump；webtoon 提高 cache 条目；会话内页 provider keepAlive；listener deps 用 ref 读最新 index；`DualPageViewport` 改为字段 `select`（现 watch 整份 `ReaderState`）。
- **收益**：条漫快速滑动 — **中**。

#### P1-5 扫描进度 UI 订阅过宽（非扫描本体）

- **证据**：`library_search_toolbar.dart` L505 全量 `watch(scanLibraryControllerProvider)`；侧栏同陷阱（watch 整份 state 再取 `.running`）。
- **建议**：一律 `.select((s) => (s.running, s.scanMode))`。
- **收益**：silent 扫描时工具栏/侧栏 — **低中**（主伤仍是 P0-4）。

#### P1-6 Home 跟随 counts / continue-reading 流

- **证据**：Home 与 Rust `watch_home_page_counts` 同源 ~400ms data_version。
- **建议**：扫描中降频；叶子组件 `select`；避免根 `build` 全量跟流。
- **收益**：边扫边看 Home — **中**。

#### P1-7 `allSeriesProvider` 全量拉取用于详情导航

- **证据**：`library_series_providers.dart`；`comic_detail_series_nav_provider.dart`。
- **建议**：按 comicId 定点查所属系列。
- **收益**：进详情首帧 — **中**。

#### P1-8 筛选抽屉 build 内 sort + shrinkWrap ListView

- **证据**：`library_metadata_filter_section.dart`、`library_metadata_filter_controls.dart`（`toList()..sort()`、`ListView.builder(shrinkWrap: true)`）。
- **建议**：排序放 provider；固定高度虚拟列表。
- **收益**：打开筛选 — **中低～中**（词典很大时升）。

#### P1-9 库页视口更新双通道 + 每帧几何测量

- **证据**：`library_page.dart` ScrollController + ScrollNotification 均 schedule；`_updateCoverViewport` 含 `getTransformTo`。
- **建议**：合并通道；节流（如每 N ms 或仅方向变化时）。
- **收益**：惯性滚动主线程 — **中低**。

#### P1-10 pageSize 上限 500 放大 P0-1

- **证据**：`library_tab_page_size_settings.dart` L6：`[20,50,100,200,500]`。
- **建议**：Sliver 落地前限制上限或大页警告；落地后仍建议默认偏小。
- **收益**：大页用户 — **中**。

---

### P2 — 场景性 / 锦上添花

| ID | 问题 | 证据要点 | 建议 |
|----|------|----------|------|
| P2-1 | 阅读器 `FilterQuality.high` | `reader_image_item.dart` | 滚动中 medium/low，静止再升 |
| P2-2 | 分页模式 crossfade | `paged_viewport` + `reader_page_fade_in.dart` | 弱设备关 / 仅首帧 |
| P2-3 | 排序 FLIP 常驻 ReorderableBuilder | `animated_library_catalog_grid_sliver.dart` | 非排序场景卸掉 |
| P2-4 | 退出阅读器 sync `clearReaderPageCacheFrb` | `reader_prefetch_controller.dart`、`reader.dart` | async 清理 |
| P2-5 | History 无 RepaintBoundary / 无视口分级 | `reading_history_card.dart` | 对齐 catalog 卡片 |
| P2-6 | History `loadMore` 滚动通知洪水 | `history_page.dart` L86–100 | 节流（controller 已有 loading 守卫） |
| P2-7 | 诊断 Verbose 热路径日志 | ADR-0004、`app_logging.dart` | 性能复现时关闭 |
| P2-8 | Comics Tab 无 random 时 revision 豁免 | series 有、comics 无 | 对齐策略 |
| P2-9 | `AnimatedSwitcher` 切阅读模式短暂双 viewport | `reader_content.dart` | 缩短/关过渡 |

---

## C. 推荐落地顺序

1. **库页真 `SliverGrid`**（P0-1）— 立刻改善滚动模型，且与系列详情/历史页一致。  
2. **热路径 FRB sync→async**（P0-2 / P0-3 / P1-3）— 去掉主 isolate `block_on`。  
3. **扫描期 revision 节流 + 收窄 LibraryPage watch**（P0-4 / P1-5 / P1-6）。  
4. **封面视口订阅粒度**（P0-5）。  
5. **阅读器预取 cache key 对齐 + 拆分 `ReaderPage` watch**（P0-6 / P0-7）— 纯 Dart、收益大。  
6. 阅读器 `existsSync` / 缓存条数 / autoDispose / FilterQuality（P1-2、P1-4、P2-1）。  
7. 搜索分页与筛选抽屉（P1-1、P1-8）。

---

## D. 推荐验证方法（官方）

1. **Profile 模式**（debug 帧时不可信）  
   - `flutter run --profile`  
   - [Build modes](https://docs.flutter.dev/testing/build-modes)  
   - [UI performance](https://docs.flutter.dev/perf/ui-performance)

2. **DevTools Performance**  
   - 标红帧（>~16ms）、Timeline 抓：库页滚动、换页、打开阅读器、打开筛选、边扫边逛。  
   - [Performance view](https://docs.flutter.dev/tools/devtools/performance)

3. **对照实验**  
   - P0-1：同一库 pageSize 50 vs 200，对比 Build/Layout；对照系列详情 `SliverGrid`。  
   - P0-2：Timeline/CPU 是否出现 `guardFrbSync` / `block_on` 尖刺。  
   - P0-3：冷缓存快速滚库页，尖刺是否对齐 cover provider。  
   - P0-4：扫描进行中停在 Library，看 revision/catalog 刷新频率。  
   - 阅读器：归档本翻页 vs 目录本；看 build 时段是否含 `existsSync`。

4. **Performance Overlay / CPU Profiler** — 仅在 profile 下解读。

5. **渲染**  
   - [Improving rendering performance](https://docs.flutter.dev/perf/rendering-performance)  
   - 本仓库未配置 `enable-impeller`；依赖平台默认。

6. **ImageCache 现状**（便于对照实验）  
   - 全局：600 条 / 256MB（`image_cache_config.dart`）  
   - 阅读器命名缓存：邻居窗口相关条目上限 + 128MB

---

## E. 一手来源

### 源码（节选）

- `app/lib/ui/features/library/views/library_page/library_page.dart`
- `.../widgets/animated_library_catalog_grid_sliver.dart`
- `.../view_models/library_comics_catalog_controller.dart`
- `.../view_models/library_catalog_revision_coordinator.dart`
- `.../view_models/library_catalog_cover_viewport_notifier.dart`
- `.../view_models/library_search_page_providers.dart`
- `app/lib/ui/providers/comic_cover_providers.dart`、`comic_cover_load_gate.dart`
- `app/lib/ui/core/widgets/element/card/catalog_cover_card_shell.dart`
- `app/lib/ui/core/widgets/element/image/{comic_cover_content,app_comic_image,card_letterboxed_cover_image}.dart`
- `app/lib/data/repositories/comic_repository_impl.dart`
- `app/lib/data/adapters/library_revision_frb_adapter.dart`
- `app/lib/ui/features/reader/**`（viewport、prefetch、`reader_image_item.dart`）
- `app/lib/ui/features/shell/views/history_page.dart`
- `app/lib/core/image/image_cache_config.dart`
- `core/crates/flutter/src/api/{comic,series,reader,thumbnail,history,home}.rs`
- `docs/adr/0004-production-diagnostics.md`、`0010-windows-app-data-profile-isolation.md`

### 官方 / 一方案文档

- [ScrollView.shrinkWrap](https://api.flutter.dev/flutter/widgets/ScrollView/shrinkWrap.html) — shrink wrapping 显著更贵  
- [UI performance](https://docs.flutter.dev/perf/ui-performance)  
- [DevTools Performance](https://docs.flutter.dev/tools/devtools/performance)  
- [Build modes](https://docs.flutter.dev/testing/build-modes)  
- [Rendering performance](https://docs.flutter.dev/perf/rendering-performance)  
- [FRB Synchronous Dart](https://cjycode.com/flutter_rust_bridge/guides/concurrency/sync-dart) — 慢函数用 sync 会阻塞 Dart UI  
- [FRB Asynchronous Dart](https://cjycode.com/flutter_rust_bridge/guides/concurrency/async-dart) — 默认 async，Rust 不堵 Flutter UI  
- 本仓库生成绑定标注 `@generated by flutter_rust_bridge@ 2.12.0`

---

## 附录：扫描进度 vs 流畅度（边界说明）

**不做**扫描算法/IO 吞吐优化。

但 UI 侧需区分：

1. **进度条 tick** → 主要打在小控件；应用 `.select` 即可。  
2. **写入 → data_version → revision → catalog/Home 刷新** → 才是边扫边逛卡顿主链路（P0-4），属于「交互帧如何订阅长时任务副作用」，纳入本报告。
