# 全库可优化点调研报告

> 首次调研：2026-09-13 ｜ **最近复核：2026-09-16**（对照 `HEAD = 8ec741c7`）｜ FRB sync/async 计数与 P0-B2·P1-A3 于 2026-09-16 晚间按第二刀（#129）回写
> 范围：`e:\projects\hentai_library` 产品/架构债、性能、代码质量、测试/CI、DX、产品缺口
> 落盘约定：本仓库 research 约定目录为 `docs/research/`
> 性质：**只读调研**；结论按「已落地 / 部分落地 / 仍开放 / 不建议现在做」标注
> 方法：Glob / Grep / Read 对照 `CONTEXT.md`、`docs/adr/*`、`docs/agents/*`、源码与 `.github/workflows/ci.yml`；本次复核**已**执行 `gh issue list` 核实 issue 状态（首版未核实）

---

## 本次复核（2026-09-16）摘要

自 2026-09-13 首版落盘（提交 `c8d3f8fb`）以来，仓库新增 4 个提交：`ccd35673`（#123–#126 设置主从布局 / 详情 chip 限行 / 阅读器窄屏 chrome）、`e9dfb20b`·`8dea3318`·`51273d16`（iOS pdfium 发版打包三连修）、`8ec741c7`（桌面启动窗口居中）。

| 变化 | 条目 |
|------|------|
| **已落地（本次可关闭）** | P1-B4 系列导航标题 N 次查询 → 批量 `findByIds`；P1-F3 iOS PDF stub → 真实 pdfium（ADR-0015）；P2-F5 README 能力表述已对齐；P2-E4 issue 债 → 已核实**当前 0 个 open issue** |
| **新增发现** | **P1-A6** ADR-0015 Decision 与 iOS pdfium 实际嵌入方式已漂移（`vendored_frameworks` → Podfile script phase + dynamic linkage）；**P2-C6** #121 系列成员重排被回退，留下无 UI 消费的 `setSeriesItemsOrder` 写路径 |
| **仍开放（优先级不变）** | P0-B1 扫描期 400ms revision 轮询；P0-B2 剩余 sync FRB（**第二刀已落地**，余写路径 / Library CRUD / Tag·Author 管理读）；P0-F1 All libraries browse 占位；P1-A2 `/paths` 退役（ADR-0014 已决策未实现）；P1-B3 阅读器同步文件探测；P1-C1/C2/C3、P1-D2 薄边补测、P2-B5/C4 |
| **文档现状注意** | `docs/research/ui-performance-tuning.md` 已随 `0a3c0806` 删除；其结论对照见下节，原文需从 git 历史取回 |

### 复核后的处置（提交 `47292e94`）

低风险项已直接落地，需决策或需 Mac 验证的已开 issue：

| 处置 | 内容 |
|------|------|
| **已做** | P1-D2 薄边补测（`mapRustComic` 全字段/空可选字段、`mapPagedResult`、`mapPagedSeriesComicsResult`、新增 `frb_zone_guard_test` 三条）；P1-A6 文档回写（ADR-0015 加「实现修订」小节 + `core/vendor/README.md` + `rust-migration.md`）；P2-C4 移除 `card_settings_ui`；P1-C3 的 Drift 错注释订正；`testing.md` Slice 2 缺口清单更新 |
| **已开 issue** | [#128](https://github.com/Zoti321/hentail_library/issues/128) revision 降频（P0-B1）· [#129](https://github.com/Zoti321/hentail_library/issues/129) sync→async 第二刀（P0-B2）→ **已落地（2026-09-16）** · [#130](https://github.com/Zoti321/hentail_library/issues/130) 系列重排去留决策（P2-C6）→ **已决策并关闭（2026-09-16）**，实施承载转重开的 [#121](https://github.com/Zoti321/hentail_library/issues/121) · [#131](https://github.com/Zoti321/hentail_library/issues/131) `allSeriesProvider` 死路径（P2-B5）→ **已落地（2026-09-16）** · [#132](https://github.com/Zoti321/hentail_library/issues/132) iOS `build-ios-xcframework.sh` 去留 |
| **已实现** | P1-A2 ADR-0014 的 `/paths` 退役（2026-09-16）：路由重定向 + 空态/Hero 双 CTA + 删 Dart/Rust Path 面 |
| **仍未承载** | P0-F1 All libraries browse、P1-B3 阅读器同步探测、P1-C1 Stateful 收敛、P1-C3 的 `clearExpiredHistory` 去留、P1-E2 README 门禁对照 |

---

## 范围与方法

### 范围

| 区域 | 覆盖 |
|------|------|
| A 产品与架构债 | `CONTEXT.md`、`AGENTS.md`、`docs/adr/*`、`docs/agents/rust-migration.md`、monorepo `app/` / `core/`、FRB 边界、ADR 与实现抽样对照 |
| B 性能与阅读体验 | 阅读会话、缩略图、revision 流、扫描订阅；对照已删除的 `ui-performance-tuning.md` 结论 |
| C 代码质量 | `app/lib` 分层、StatefulWidget、sync FRB / `guardFrbSync`、过宽 catch、文档/注释漂移 |
| D 测试与 CI | `docs/agents/testing.md` vs `.github/workflows/ci.yml`、Rust/Dart 测布局 |
| E DX / 构建 | `README.md`、`scripts/*`、`core/vendor/*`、FRB/codegen、iOS 打包链 |
| F 产品缺口 | All libraries browse、Tag dictionary UI、Remote 边界 |

### 统计（2026-09-16 本机，括号内为 2026-09-13 首版数值）

| 指标 | 数值 | 统计命令/规则 |
|------|------|----------------|
| Dart 手写源（排除 `*.g.dart` / `*.freezed.dart` / `app/lib/src/rust`） | **456**（453） | `find app/lib -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' ! -path '*/src/rust/*'` |
| Dart 生成文件（`*.g.dart` + `*.freezed.dart`） | **78**（78） | 同上路径 |
| Rust `core/crates/core/src` | **116**（117）`.rs` | `mobile_pdf.rs` 随 ADR-0015 删除 |
| `core/crates/core/tests` 集成测文件 | **35**（34） | `find core/crates/core/tests -name '*.rs'` |
| Flutter `*_test.dart` | **178**（172） | `find app/test -name '*_test.dart'`；2026-09-16 新增 `frb_zone_guard_test.dart` |
| `#[flutter_rust_bridge::frb(sync)]` | **48**（70） | `grep -r ... core/crates/flutter/src/api`；2026-09-16 晚间 P0-B2 第二刀 + 首页死 sync 删除后 |
| 纯 `#[flutter_rust_bridge::frb]`（async 入口） | **51**（36） | 同行匹配 `^#\[flutter_rust_bridge::frb\]$`；**async 首次成为多数** |
| `guardFrbSync(` 调用点 | **40**（60） | `app/lib`，排除生成码与 `frb_call_guard` 定义；第二刀后 |
| `extends StatefulWidget` 文件 | **19**（20） | `app/lib` |
| `extends ConsumerStatefulWidget` 文件 | **28**（28） | `app/lib` |
| `catch (_)` | **12**（20） | `app/lib` 手写源 |
| `TODO`/`FIXME`/`HACK`/`XXX` | **0**（0） | 债仍以注释/ADR/文档表达 |
| GitHub open issues | **0** | `gh issue list --state open`（#11 PRD、#108 切片2 均 CLOSED） |

sync/async 比的演进：首版 70:36 → 第一刀 + 批量读改造后 63:44 → ADR-0014 退役 Path API 60:43 → #131 删 `get_all_series_frb` 58:43 → **P0-B2 第二刀（2026-09-16 晚间）50:51 → 删首页死 sync 读 48:51**。第二刀把 series reading context / comics metadata / facet 名称列表 / facet attachment count / character·parody 的 4 个字典读共 8 个入口改成真 async，**async 自此成为多数**；随后删掉 `home.rs` 两个无消费方的一次性读（首页消费的是 async watch 流）。

### FRB 入口分布（按模块，2026-09-16 第二刀后）

| 模块 | sync | async | 仍 sync 的性质 |
|------|------|-------|----------------|
| `comic.rs` | 5 | 10 | 主要写 + revision 流辅助 |
| `series.rs` | 5 | 12 | 全部 order/lock/meta 写 + 无消费方的 `load_home_series_comic_order_map` |
| `library.rs` | 9 | 3 | 全部 CRUD 与设置写（热读 list/current 已 async） |
| `tag.rs` / `author.rs` | 6 / 5 | 1 / 1 | 管理读 + 写 |
| `named_facet.rs` | 3 | 4 | 仅管理写（名称列表读、attachment count 读已 async） |
| `history.rs` | 4 | 3 | 全部写（分页/开读恢复读已 async） |
| `reader.rs` | 3 | 5 | `load_page_bytes` 读（见 P1-B3）、`close/clear_sessions` |
| `thumbnail.rs` | 3 | 5 | 写/清理 |
| `sync.rs` / `home.rs` / `logging.rs` | 3 / 0 / 2 | 1 / 2 / 0 | 轻量控制面；`home.rs` 2 个无消费方的 sync 读已删除 |
| `character.rs` / `parody.rs` | 0 / 0 | 2 / 2 | 第二刀已全部 async |

> `path.rs`（3 sync / 1 async）随 ADR-0014 于 2026-09-16 删除。

---

## 已有相关调研与本次关系

### 先例：`docs/research/ui-performance-tuning.md`（2026-09-04，现已删除）

该报告聚焦 **UI 交互帧预算**，明确排除扫描吞吐与缩略图**生成算法**，并列出 P0–P2 热路径。**该文件已在工作区删除（未提交）**，因此以下对照表是其结论在本仓库内的唯一留存摘要。

| 原 ID | 结论（2026-09-16 复核） | 证据 |
|-------|------------------------|------|
| **P0-1** shrinkWrap 网格 | **已落地**（稳态真 `SliverGrid`；仅排序 FLIP 短暂 shrinkWrap） | `animated_library_catalog_grid_sliver.dart` |
| **P0-2** 热路径 sync FRB | **热路径已清零**：comic 分页/find/search、thumbnail 读、reader open/page list、history 读、library 热读、facet 分页与名称列表、series reading context / comics metadata、character·parody 字典读均已 async；剩余 sync 集中在写路径与 Tag/Author 管理读（48 sync / 51 async） | 见上表 |
| **P0-3** 封面 sync | **已落地** | `thumbnail.rs` find/ensure async；`comic_thumbnail_repository_impl.dart` 用 `guardFrb` |
| **P0-4** 扫描期 revision 400ms | **仍开放** | `comic.rs` L369–372：`read_data_version` + `sleep(400ms)` |
| **P0-5** 封面视口全量 watch | **已落地** | `comic_cover_content.dart` `viewport.select(...contains(index))` |
| **P0-6** 预取 cacheWidth | **已落地** | `reader_prefetch_controller.dart` / `reader_prefetch_hook.dart` |
| **P0-7** ReaderPage 整包 watch | **部分落地** | `reader_page.dart` shell 用 `select` 拆 comic/totalPages |
| **P1-1** 搜索无分页 | **部分落地** | `search_by_keyword_page_frb` 已用于库搜索；全量 `search_by_keyword_frb` 仍保留 |
| **P1-2** build 内 existsSync | **缓解未根除** | `reader_image_cache.dart` L44 注释避免工厂内 sync IO；L64 `isUsableReaderCacheFile` 仍 `existsSync() && lengthSync()` |
| **P1-3** open/loadPageList sync | **已落地** | `reader.rs` L40 / L56 async + `spawn_blocking` |
| **P1-4** 阅读器缓存过小 | **部分落地** | `kReaderImageCacheMaxEntries = 24`（原 ≈7） |
| **P1-5** 扫描进度订阅过宽 | **部分落地** | 侧栏/Home 已 `.select`；toolbar 路径仍需个案复核 |
| **P1-10** pageSize 500 | **已收紧** | `kLibraryPageSizeOptions = [20,50,100,200]` |
| **P2-1** FilterQuality.high | **已否决且固化** | `CONTEXT.md` Page image fidelity；`kReaderPageFilterQuality = FilterQuality.medium` |

---

## 发现清单

优先级：**P0** = 用户可感卡顿或文档/契约误导高风险；**P1** = 可维护性或明确产品债；**P2** = 锦上添花或可延后。

---

### 架构 / 迁移债

#### P0-A1 — Agent/产品文档「迁移中 / Planned」叙事 — **已处理（2026-09-13，2026-09-16 复验）**

- **处理**：`AGENTS.md`、`docs/agents/*`、根 `README.md` 已按 monorepo 完成态与「多库 + WebDAV 已实现」重写。
- **复验**：`product-positioning.md` L29 写「Android / iOS Supported; 剩余为组件级打磨」；L50–52 PDF 全平台 Supported；README L24–25 写多 Library 与 WebDAV。**Planned 清单现已为空**（原唯一保留项 iOS PDF 已交付，见 P1-F3）。

#### P1-A2 — Path / Selected Paths 与 Library 模型并存 — **已实现（2026-09-16，ADR-0014）**

- **处理**：`/paths` 改为 `redirect → /home`（新增 `retired_paths_route_test.dart` 挡回归）；空库 CTA 与 Home hero 改为 createLocal + createRemote（走 `LibraryManagementActions`）；删除 `SelectedPathsPage` 及 widgets、`SelectedPathsPageNotifier`、`PathRepository(+Impl)`、`pathRepoProvider`、Rust `core/src/path/` 与 `flutter/src/api/path.rs`，并重跑 FRB codegen / build_runner / gen-l10n；Path 页专属 l10n 键删除，`pathsAddedOneToast` / `pathsRemovedToast` 改名为 `libraryLocalAddedToast` / `libraryRemovedToast` 并改成 Library 措辞。
- **效果**：FRB 入口 60 sync / 43 async（此前 63 / 44），`guardFrbSync` 48（此前 51），Dart 手写源 444（此前 456），`ConsumerStatefulWidget` 25（此前 28）。
- **按原决策保留**：`saved_paths` 表与 migration / 迁移测试；`RemoveSavedPathConfirmDialog` 类名（文案已是 Library 措辞，改名可另排）。Path migration（ADR-0013）、`/libraries/all` 实现、Library CRUD sync→async 仍在决策外。

#### P1-A3 — Dart 薄边 sync 比例仍偏高 — **第二刀已落地（2026-09-16，[#129](https://github.com/Zoti321/hentail_library/issues/129)）；async 已成多数**

- **第一刀（2026-09-13）**：History 读、Named facet 分页/form list、Library `list`/`get_current`/`set_current` → 真 async。
- **本次复核补充**：`comic.findComicsByIdsFrb` 批量读为 async（P1-B4 的落地副产品），async 入口升至 44。
- **第二刀（2026-09-16）**：见 P0-B2；Dart 侧 `guardFrbSync` 从 9 个 repository impl 收窄到 8 个（`named_facet_dictionary_repository_impl` 已全 async），50:51 且 async 反超；随后删首页死 sync 读至 48:51。
- **后续切片意向（未开）**：Tag/Author 管理读 → 各模块写；死 sync 清理只剩 `load_home_series_comic_order_map`（`home.rs` 两个读已删）。
- **政策**：`docs/agents/rust-migration.md`「FRB sync vs async」；Library **CRUD** 仍在 ADR-0014 决策外。
- **风险/代价**：剩余部分中；需同步改生成绑定、Repository、`guardFrb`。

#### P1-A4 — ADR 与实现总体一致，注释/次要契约漂移 — **首版条目已处理**

| 主题 | ADR | 实现抽样 | 一致性 |
|------|-----|----------|--------|
| Comic deletion 删 Local Resource | ADR-0012 | `comic/write.rs` `maybe_delete_local_resource` | 一致 |
| Path migration | ADR-0013 | `sync/migrate.rs`、`update_local_library_root` 测 | 一致；Remote 改根 remapping 明确不在决策内 |
| Read session | ADR-0005 | 路由 comicId；`drop_series_reading_histories` 测 | 一致 |
| Multi-library + WebDAV | ADR-0008 | `resource/access/webdav.rs`、remote 测 | 一致 |
| 日志 | ADR-0003 | `app/lib/core/logging/*` + `package:logging` | 已对齐（Context 改为决策前叙事） |
| ResourceEntry 注释 | — | `resource/access/mod.rs` | 已对齐 |
| **iOS PDF 打包** | **ADR-0015** | **`podspec` / `Podfile` / `embed_pdfium.sh`** | **漂移 → 见 P1-A6** |

#### P1-A6 — ADR-0015 Decision 与 iOS pdfium 实际嵌入方式不一致 — **已处理（2026-09-16，`47292e94`）**

- **现状证据**
  - ADR-0015 Decision 写：「`hentai_flutter.podspec` 以 `vendored_frameworks` 嵌入并代签」。
  - 实现（9-15 三连修后）：`hentai_flutter.podspec` L26–29 注释明确「CocoaPods 不支持 `vendored_frameworks` 引用含 `.dylib` 的 xcframework」，改由 `app/ios/Podfile` L30–31 `use_frameworks! :linkage => :dynamic` + L39–45 `[HL] Embed pdfium dylib` script phase 调 `app/rust_builder/ios/embed_pdfium.sh` 拷进 App `Frameworks/`；运行时仍按 `pdf.rs` L26–28 / L44+ `bind_pdfium_ios()` 从 bundle `dlopen`。
- **问题/机会**：ADR 是打包链的真相源，且本次改动把**整个 iOS pod 图切成 dynamic linkage**（副作用范围远超 PDF），Consequences 未记录；下次 iOS 构建失败排查会先读错文档。
- **处理**：ADR-0015 Decision 改写为 script phase 事实并加「实现修订」小节，Consequences 补记 dynamic linkage 影响全部 Pod、选片逻辑自维护；`core/vendor/README.md` 与 `docs/agents/rust-migration.md` 同步。未新开 ADR。
- **连带发现**：`core/vendor/build-ios-xcframework.sh` 的产物 `pdfium.xcframework` **已无消费方**（`embed_pdfium.sh` 直取 `core/vendor/ios-*/` 下的 dylib），`install_name` 归一化不再作用于入包文件；因 `dlopen` 走绝对路径，功能不受影响。去留需 Mac 验证 → [#132](https://github.com/Zoti321/hentail_library/issues/132)。

#### P2-A5 — 根目录遗留产物与「legacy mobile」叙事 — **已决策并文档对齐（2026-09-13）**

- **P2-A5a**：根 `.dart_tool/`、`build/` 可能残留但 `.gitignore` 已覆盖且 git 未跟踪；规范工程在 `app/`。不新增清理脚本。
- **P2-A5b**：架构迁移视为完成（单 `appRouter` + `ResponsiveAppShell` + `buildAppTheme`）；`ui-style.md` / `product-positioning.md` 已改写；「勿新开 mobile-only Material 页」政策保留防回归。

---

### 性能

#### P0-B1 — 扫描写入期 `data_version` ~400ms 轮询仍驱动 UI 刷新 — **仍开放，见 [#128](https://github.com/Zoti321/hentail_library/issues/128)**

- **现状证据（未变）**：`core/crates/flutter/src/api/comic.rs` L369–372：`read_data_version()` 后 `tokio::time::sleep(400ms)` 循环比对版本号。`LibraryPage` 已不整页 watch coordinator，但 catalog / Home counts 仍吃这条 revision 流。
- **问题/机会**：「边扫边逛」仍可能高频重载；`allSeriesProvider`（`keepAlive` + watch revision，见 P2-B5）一旦被消费会放大该成本。
- **建议方向**：扫描进行中合并/降频 revision；或 sync 结束显式 bump + 扫描期节流。
- **风险/代价**：中；节流过度会让 UI 长时间陈旧。

#### P0-B2 — 剩余 sync FRB — **第一刀 + 第二刀均已落地（[#129](https://github.com/Zoti321/hentail_library/issues/129)，2026-09-16）；剩余为写路径与 Tag/Author 管理读**

- **第一刀（2026-09-13）**：History 读、Named facet 分页/form list、Library 热读 → async。
- **第二刀（2026-09-16，#129）**：`get_series_reading_context_by_comic_id_frb`（开读路径）、`fetch_series_comics_metadata_frb`、`list_all_named_facet_names_frb`、`count_named_facet_attachments_frb`、`list_all_characters_frb` / `list_distinct_characters_frb` / `list_all_parodies_frb` / `list_distinct_parodies_frb` 共 8 个入口 → async；Dart 侧仅动 3 个 repository impl（`guardFrbSync` → `guardFrb`），domain 接口本就返回 `Future`，**provider/消费方零改动**。
- **未做（按收益排序）**：Tag/Author 管理读（`tag.rs` `list_all_tags` / `fetch_tags_page`、`author.rs` 同构 2 个）→ 各模块写（History 4、Library 9、**Series 4**：`update_series_user_meta` / `set_series_meta_locks` / `update_series_item_sort_order` / `set_series_item_sort_order_locked`）。
- **计数订正（2026-09-16）**：本条此前写的「Series 7 写」是把 `series.rs` 的 sync **总数**当成了写数量；扣掉两个在第二刀范围内的读与 `load_home_series_comic_order_map` 读后，实际写路径当时是 5、删 `set_series_items_order_frb` 后是 4。
- **清单减项（2026-09-16 决策，见 P2-C6）**：`set_series_items_order_frb` 不必改 async 而是**直接删除**（无消费方，API 降级为 core-only）。
- **死 sync 读处置**：`home.rs` `get_home_page_counts_frb` / `get_continue_reading_top5_frb` **已删除**（2026-09-16）——首页消费的是 async `watch_home_page_counts_frb` / `watch_continue_reading_top5_frb`，这两个一次性读是功能重复且 `app/lib` 内无调用方；连带删掉 core 的 `get_home_page_counts` / `get_continue_reading_top5`（原本只是 `load_counts` / `load_continue_reading` 的薄包装，watch 版直接用后者）与 `lib.rs` 再导出。余 `series.rs` `load_home_series_comic_order_map_frb`，与 [#121](https://github.com/Zoti321/hentail_library/issues/121) 对齐后处理。
- **验收**：契约以 async 入口为准；第二刀已过 `cargo check`/`cargo test`、`flutter analyze`、`flutter test test/domain test/core test/data` 及系列导航/阅读器/系列详情三组 UI 测。
- **风险/代价**：剩余部分低～中；模式已固化。

#### P1-B3 — 阅读器仍有同步文件探测与残留 sync 入口 — **仍开放**

- **现状证据**：`reader_image_cache.dart` L64 `isUsableReaderCacheFile` 仍 `existsSync() && lengthSync() > 0`，展示/预取路径调用（L44 注释只保证不在 provider 工厂内 sync）。`reader.rs` L72 `load_page_bytes_frb` 仍 sync；`clear_reader_page_cache_frb` 已 async。
- **建议方向**：把存在性并入 async payload 或交由加载失败路径；确认 `load_page_bytes_frb` 无调用方后废弃。
- **风险/代价**：低～中。

#### P1-B4 — 系列导航标题解析 N 次 `findById` — **已落地（2026-09-16 复核关闭）**

- **证据**：`comic_detail_series_nav_provider.dart` L99–116 新增 `resolveComicTitlesForDisplay`，`buildSeriesNavData`（L125+）改为一次批量读；`comic_repository_impl.dart` L77–86 `findByIds` 走 async `findComicsByIdsFrb`，缺失 id 保留截断兜底。
- **余留**：单条 `resolveComicTitleForDisplay` 现是批量版的薄封装，无额外往返。

#### P2-B5 — `allSeriesProvider` / `get_all_series_frb` 死路径且是潜伏热点 — **已落地（2026-09-16 完成，[#131](https://github.com/Zoti321/hentail_library/issues/131)）**

- **原证据**：`library_series_providers.dart` L9–18 `allSeries` 为 `@Riverpod(keepAlive: true)`，watch `libraryRevisionProvider.revision` 后 `seriesRepo.getAll()`（sync `get_all_series_frb`）并在 Dart 侧排序；`app/lib` 内除生成码无消费者。
- **复核修正**：`getAll` 本身仍有生产消费者 `edit_metadata_dialog._loadSeriesSortMembership`，它为查一本漫画的成员归属拉全库系列 + 全部 `items` 再线性扫，因此不能直接删。
- **处置**：删除 `allSeriesProvider` 与 Dart 侧 `watchAll`；core 新增窄查询 `find_series_item_by_comic_id`（FRB `find_series_item_by_comic_id_frb`，async），对话框改走该接口；随后移除 `getAll` / `get_all_series_frb` / `watch_all_series_frb` 及 core 的 `get_all_series` / `watch_all_series`。
- **余留**：`load_home_series_comic_order_map_frb` / `watch_home_series_comic_order_map_frb` 仍无 app 侧调用方，去留待与 [#121](https://github.com/Zoti321/hentail_library/issues/121) 对齐。

#### P2-B6 — WebDAV / 大库扫描吞吐 — **建议先测量**

- **现状证据**：Remote sync/read 以 `FakeResourceAccess` 为接缝（`remote_library_*.rs`）；源码无 TODO 标注瓶颈；旧 UI 性能报告明确不做扫描吞吐。
- **建议方向**：单独做真机 WebDAV Profile 调研；勿在无证据下改扫描算法。
- **风险/代价**：高（网络变量大）。

---

### 代码质量与可维护性

#### P1-C1 — Stateful / ConsumerStateful 仍偏多 vs coding-style

- **现状证据**：`coding-style.md` 优先 Hook/Consumer；实测 **19** StatefulWidget + **28** ConsumerStatefulWidget（含 `LibraryPage`、`SelectedPathsPage`、大量 dialog/form）。较首版仅 −1。
- **建议方向**：触达文件时渐进迁移；新代码严格按表（`SelectedPathsPage` 可随 ADR-0014 直接消失）。
- **风险/代价**：低～中。

#### P1-C2 — 过宽 `catch (_)` 与静默失败 — **明显改善，仍未清零**

- **现状证据**：`catch (_)` 从 20 降至 **12**（路由、系列导航、元数据对话框、库凭证、设置更新等）。
- **建议方向**：剩余点至少 `logError` + 用户可见失败；区分「预期取消」与真实错误。
- **风险/代价**：低。

#### P1-C3 — Drift 时代注释与空实现残留 — **部分处理（2026-09-16）**

- **已改**：`author_management_notifier.dart` L6 注释订正为「经 FRB stream 监听 Rust 侧作者变化」。
- **仍开放**：`reading_history_repository_impl.dart` L162–164 `clearExpiredHistory` 仍是空实现，注释「365 天清理…后续 slice 补齐；当前无 UI 调用」——要么实现 Rust SQL + UI 入口，要么从接口删除并记产品决定；暂未开 issue。
- （`migration/m20240630_000002_drift_v2_seed.rs` 提到 Drift 属历史迁移语义，**正确**，勿改。）
- **风险/代价**：低。

#### P2-C4 — 未使用的 pub 依赖 — **已处理（2026-09-16，`47292e94`）**

- **处理**：`card_settings_ui` 已从 `app/pubspec.yaml` 移除（`flutter pub get` + `analyze` 验证无引用）。`archive` 仍被 `log_export_service.dart` 使用，保留。

#### P2-C5 — Dart data 层 `services/` 仍存在（非 comic I/O）

- **现状**：`data/services/app_update`、`tag_dictionary` 符合 rust-migration「设置/更新/下载可留 Dart」。
- **标注**：**不建议**为分层纯度迁入 Rust。

#### P2-C6 — #121 系列成员重排回退后留下无消费的写路径 — **已决策（2026-09-16），#130 关闭，实施承载转 [#121](https://github.com/Zoti321/hentail_library/issues/121)**

- **现状证据**：`c8d3f8fb` 提交信息标注「#121 已回退」；`app/lib` 内无 series reorder mode UI（仅侧栏 `sidebarReorderLibraries` 与 `librariesReorderMenuEnabled` 属库排序，另一回事）。但 `series_repository_impl.dart` L179–186 `setSeriesItemsOrder` 与 domain L68 声明仍在，Rust `set_series_items_order_frb`（`series.rs` L378，sync）亦在册，**无 UI 调用点**。
- **决策（重做，但阻塞）**：产品需求保留——#121 已重开并挂「[阻塞]」前缀 + `help wanted`，阻塞原因是缺少满足要求的网格拖拽方案：已在依赖的 `flutter_reorderable_grid_view`（5.7.0）只支持 `GridView` / `GridView.builder`，**无 sliver 支持**，用它会让重排模式下的全量成员失去虚拟化（本仓库现有用法即 `enableDraggable: false` + `shrinkWrap` 仅做排序 FLIP 动画）；`reorderable_grid`（1.0.13，含 `SliverReorderableGrid`）是唯一 sliver 原生候选但未验证；`reorderable_plus`（0.0.2，两年未更新）与 `sliver_dashboard`（缩放/碰撞引擎，量级过大）均否决。准入条件与自研兜底见 #121 body。
- **API 处置**：`setSeriesItemsOrder` **降级为 core-only**——删 Dart domain / data 声明与 `set_series_items_order_frb`，保留 `core` 实现与 `series_item_sort_order.rs` 测试；ADR-0006 已加「实现修订（2026-09-16）」记录。代码删除作为独立一刀执行（要跑 FRB codegen，不与 ADR-0014 Path 退役的生成产物混在同一 diff）。
- **风险/代价**：低。

---

### 测试 / CI

#### P0-D1 — CI 硬门禁与「绿 PR」语义（有意设计，但是产品风险）

- **现状证据（2026-09-16）**：`.github/workflows/ci.yml`：`test-rust`（`cargo test`）、`analyze`（format + analyze）、`test-unit`（白名单：`test/domain`、`test/core`、`test/data`、`project_layout_test.dart` + 5 个已晋升 UI 测，最新一枚是 `reader_chrome_layout_test.dart`，随 #126 由 `ccd35673` 加入）、`test-widget` 仍 `continue-on-error: true` 且只跑 `test/widget_test.dart`。
- **问题/机会**：177 个 Flutter 测里仅 ~1/3 目录进硬门禁；`app/integration_test/pdf_reader_smoke_test.dart` 仍不在 CI（iOS PDF 刚落地，更需要它）。
- **建议方向**：继续按 testing.md 双轨清单晋升稳定快轨（晋升机制本身运转正常）；PDF 关键路径考虑 Rust 侧最小 smoke 或 macOS 手工清单。
- **风险/代价**：中；保持 soft 是有意权衡，**扩大硬门禁需评审**。

#### P1-D2 — FRB thin-edge 缺口 — **已处理（2026-09-16，`47292e94`）**

- **原缺口**：`frb_zone_guard.dart`（`main.dart` 生产引用）无测试；`comic_frb_mapper_test.dart` 仅覆盖 sort/filter，`mapRustComic` 未覆盖；`series_frb_mapper_test.dart` 不含 `mapPagedSeriesComicsResult`。
- **处理**：新增 `app/test/data/adapters/frb_zone_guard_test.dart`（映射后 present / 非 FRB 错误忽略 / benign stream closed 忽略）；`comic_frb_mapper_test.dart` 补 `mapRustComic` 全字段与空可选字段、`mapPagedResult` 分页信封；`series_frb_mapper_test.dart` 补 `mapPagedSeriesComicsResult` 逐项 sortOrder/锁。`test/data` 已在 `test-unit` 硬门禁路径内，无需改 CI 命令；`testing.md` Slice 2 清单同步更新。
- **余留**：真 FRB / `*_repository_impl` 集成测按 ADR-0002 不做。

#### P1-D3 — WebDAV：Rust Fake 覆盖好，端到端薄

- **现状证据**：`remote_library_{register,sync,read}.rs` + `FakeResourceAccess`；Dart 侧 `remote_library_credential_store_test.dart`。无 CI 真 HTTP WebDAV。
- **建议方向**：保持 Fake 为主；可选本地 docker WebDAV 手工清单（不必硬门禁）。

#### P2-D4 — Flutter 测与 Rust 测体量不对称属预期

- **标注**：**不建议**对 `*_repository_impl` 写真 FRB 集成测（testing.md 明确禁止）。

---

### DX / 构建

#### P0-E1 — `setup-dev.ps1` 文档幽灵 — **已处理（2026-09-13）**

- 根 `README`、`rust-migration.md`、`core/README.md`、`core/vendor/README.md` 统一为 `./scripts/setup-dev.sh`（Windows 用 Git Bash）；未新增 `.ps1` 包装。

#### P1-E2 — 日常开发步骤与 CI 硬门禁不完全同构

- **现状证据**：README 建议 `flutter test` 全量；CI `test-unit` 为白名单。本地更严有利质量，但贡献者可能只对齐 CI。
- **建议方向**：README 增「PR 硬门禁命令 vs 合并前全量」对照，链 `docs/agents/testing.md`。

#### P1-E3 — FRB codegen / Flutter 版本钉死，且 iOS 构建前置步骤变长

- **现状证据**：CI `FLUTTER_VERSION: "3.38.5"`、`FRB_CODEGEN_VERSION: "2.12.0"`；`pubspec` `flutter_rust_bridge: 2.12.0`。iOS 侧新增 `core/vendor/fetch-native-deps.sh --ios` + `core/vendor/build-ios-xcframework.sh`（仅 macOS/Xcode）+ Podfile dynamic linkage，`manifest.json` 增 3 个 iOS 产物并与桌面同 pin `chromium/7825`。
- **问题/机会**：环境漂移仍是主要 DX 痛点；iOS 链路只能在 Mac 验证（ADR-0015 Negative 已承认），Windows 上无法自检。
- **建议方向**：保持钉版本；升级 FRB/Flutter 走专项。**不建议**在功能 PR 中顺手升级。

#### P2-E4 — GitHub Issues 中的已知债 — **已核实（2026-09-16）**

- **核实结果**：`gh issue list --state open` → **0 条**；`docs/agents/issue-tracker.md` 引用的父 PRD **#11** 与 testing.md 的切片 **#108** 均为 CLOSED；最近批次 #123–#126 已由 `ccd35673` 关闭，#121 关闭但实现被回退（见 P2-C6）。
- **含义**：复核当时本报告的开放条目**没有对应 issue 承载**；此后已补开 #128–#133，其中 #129（P0-B2 第二刀）、#131 已落地，ADR-0014 实现已完成。

---

### 产品缺口

#### P0-F1 — All libraries browse：仅占位 — **未变**

- **现状证据**：`CONTEXT.md` L24：`/libraries/all`「本阶段仅占位提示，不实现聚合目录」；`all_libraries_browse_page.dart` L8 注释「Placeholder」，页面只有标题栏 + 提示文案；侧栏仍可导航进入（`LibraryManagementActions.goAllLibraries`）。
- **问题/机会**：多库用户期望「全部库」目录，当前是死胡同页。
- **建议方向**：排期跨库聚合 catalog，或先弱化/隐藏入口直至实现。
- **风险/代价**：高（查询模型、筛选、性能）；**明确产品增量**。

#### P1-F2 — Tag dictionary import：基础设施齐、UI 入口未接 — **未变**

- **现状证据**：`tag-dictionary-import.md` L21 仍写「暂无 UI 入口」；`TagDictionaryImportController`（L103 调 `importTagDictionary`）、Dialog、Rust `import_tag_dictionary` 均在册。
- **标注**：无自维护词库源时 **不建议现在做** UI 曝光；词库 URL 就绪后再加设置/元数据入口。

#### P1-F3 — PDF iOS stub — **已落地（2026-09-16 复核关闭，转为验证债）**

- **证据**：`mobile_pdf.rs` 已删除，`core/src/formats/` 仅 `mod.rs`/`pdf.rs`/`rar.rs`/`sevenz.rs`；`pdf.rs` L26–28 iOS 走 `bind_pdfium_ios()`（bundle `Frameworks/libpdfium.dylib` `dlopen`）；`manifest.json` L16–18 增 3 个 iOS 产物；`build-ios-xcframework.sh` + `embed_pdfium.sh` + Podfile script phase 完成打包；「当前平台不支持 PDF 格式」文案已无来源；`product-positioning.md` L50–52 / L65 标 PDF 全平台 Supported（ADR-0015）。
- **余留债**：① 打包方式与 ADR 文本漂移（**P1-A6**）；② 该链路无 CI 覆盖，`integration_test/pdf_reader_smoke_test.dart` 未进 CI，真机/模拟器验证仍是人工（**P0-D1**）。

#### P1-F4 — Remote library 产品边界

- **现状证据**：ADR-0008 / CONTEXT：远程不含 `folder`；不整本落盘；根不可达跳过不删库；Remote 改 WebDAV 根无前缀 remapping（ADR-0013 明确不在决策内）；WebDAV 备份设置/DB 非当前工作。
- **建议方向**：README/设置文案写清边界；改根 remapping 需新 ADR。
- **标注**：远程 folder / Digest 认证 / 备份 — **不建议现在做**。

#### P2-F5 — README 能力表述落后 — **已处理（2026-09-16 复核关闭）**

- **证据**：README L16 列全格式（图片目录、ZIP/CBZ、EPUB、PDF，RAR/7Z 已识别并纳入同步）、L24–25 多 Library + WebDAV、L36 平台表 iOS ✅（现与 PDF 能力一致，不再矛盾）、L57 提示 vendor 原生依赖步骤。

---

## 明确标注「不建议现在做」

| 项 | 理由（含来源） |
|----|----------------|
| 阅读器页图 `FilterQuality` 滚动降档 / 静止升 `high` | `CONTEXT.md` Page image fidelity；产品定位 supersede 旧 P2-1 |
| 为流畅度优化扫描/缩略图**生成算法**吞吐 | 旧 research 边界；缺瓶颈证据 |
| 真 FRB / `*_repository_impl` Dart 集成测 | `docs/agents/testing.md` 明确本波不做 |
| 远程 image folder、WebDAV 备份 DB、Digest/客户端证书 | ADR-0008 范围外 |
| Remote 改根 Path migration | ADR-0013「不在本决策内」 |
| Tag dictionary UI（无自维护词库源时） | tag-dictionary-import.md |
| 功能 PR 中升级 FRB/Flutter（含 pdfium pin） | CI 钉版本；iOS 打包链现已耦合同一 pin |
| 把 `settings.json` / 应用更新迁入 Rust | rust-migration.md「永久留 Dart」 |
| 仅为分层纯度把 `data/services` 下载/更新迁 Rust | 同上 |
| Mac Catalyst PDF 支持 | ADR-0015 明确不支持 |

---

## 结论：最值得跟进的机会（2026-09-16 处置后）

已完成：FRB 薄边补测（P1-D2）、ADR-0015 回写（P1-A6）、`card_settings_ui` 与 Drift 错注释（P2-C4 / P1-C3 一半）。剩余按下述顺序推进：

1. **扫描期 revision 降频** — [#128](https://github.com/Zoti321/hentail_library/issues/128)；唯一仍在的可感卡顿源，且与 #131 的潜伏全量查询叠加。
2. ~~**sync→async 第二刀** — [#129](https://github.com/Zoti321/hentail_library/issues/129)~~ — **已完成（2026-09-16）**：8 个读入口转 async + 删 `home.rs` 两个死 sync 读，48:51；下一刀为 Tag/Author 管理读与各模块写，死 sync 只剩 `load_home_series_comic_order_map`（待 #121 对齐）。
3. **死路径与回退遗留清理** — [#131](https://github.com/Zoti321/hentail_library/issues/131)（`allSeriesProvider`）+ [#130](https://github.com/Zoti321/hentail_library/issues/130)（系列重排去留，需产品决策）。
4. **All libraries browse 产品决策（P0-F1）** — 占位页已挂入口；排期聚合查询或降级入口，别留半成品。**尚无 issue**。
5. ~~**ADR-0014 实现（P1-A2）**~~ — **已完成（2026-09-16）**。
6. **iOS 构建链收口** — [#132](https://github.com/Zoti321/hentail_library/issues/132)；需 Mac 验证后再动，顺带在 Mac 上跑一次 `integration_test/pdf_reader_smoke_test.dart`。
7. **阅读器同步文件探测（P1-B3）** 与 **`clearExpiredHistory` 去留（P1-C3 余留）** — 低优先，触达时处理。

---

## 附录：一手来源索引（抽样）

- 领域与产品：`CONTEXT.md`；`docs/agents/{product-positioning,rust-migration,testing,coding-style,ui-style,tag-dictionary-import,issue-tracker}.md`
- ADR：`docs/adr/0002`–`0015`、`docs/adr/README.md`
- CI：`.github/workflows/ci.yml`（`test-unit` 白名单、`test-widget` soft）
- FRB API：`core/crates/flutter/src/api/{comic,reader,thumbnail,history,series,library,named_facet,path}.rs`
- UI 热路径：`animated_library_catalog_grid_sliver.dart`；`comic_cover_content.dart`；`reader_page.dart`；`reader_prefetch_controller.dart`；`reader_image_cache.dart`
- 批量标题：`app/lib/ui/features/library/view_models/comic_detail_series_nav_provider.dart`；`comic_repository_impl.dart` `findByIds`
- iOS PDF：`core/crates/core/src/formats/pdf.rs`；`core/vendor/{manifest.json,build-ios-xcframework.sh}`；`app/rust_builder/ios/{hentai_flutter.podspec,embed_pdfium.sh}`；`app/ios/Podfile`
- Remote：`core/crates/core/src/resource/access/webdav.rs`；`core/crates/core/tests/remote_library_*.rs`
- 占位产品：`app/lib/ui/features/shell/views/all_libraries_browse_page.dart`
- 死/悬空路径：`app/lib/ui/features/shell/state/library_series_providers.dart`；~~`series_repository_impl.dart` `setSeriesItemsOrder`~~（2026-09-16 已删，降级 core-only）；`reading_history_repository_impl.dart` `clearExpiredHistory`

---

*报告结束（2026-09-16 复核版）。*
