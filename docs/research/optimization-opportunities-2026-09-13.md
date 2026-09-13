# 全库可优化点调研报告

> 调研日期：2026-09-13  
> 范围：`e:\projects\hentai_library` 产品/架构债、性能、代码质量、测试/CI、DX、产品缺口  
> 落盘约定：本仓库 research 约定目录为 `docs/research/`（先例：`docs/research/ui-performance-tuning.md`）  
> 性质：**只读调研**；下文为可直接写入该目录的 Markdown 正文  
> 方法：Glob / Grep / Read 对照 `CONTEXT.md`、`docs/adr/*`、`docs/agents/*`、源码与 `.github/workflows/ci.yml`；**未**调用 GitHub Issues API 拉取 issue 正文（文中涉及 issue 编号处标「未核实」或仅引用本地文档已记载的编号）

---

## 范围与方法

### 范围

| 区域 | 覆盖 |
|------|------|
| A 产品与架构债 | `CONTEXT.md`、`AGENTS.md`、`docs/adr/*`、`docs/agents/rust-migration.md`、monorepo `app/` / `core/`、FRB 边界、ADR 与实现抽样对照 |
| B 性能与阅读体验 | 对照 `docs/research/ui-performance-tuning.md`（2026-09-04）复核落地情况；阅读会话、缩略图、revision、扫描订阅 |
| C 代码质量 | `app/lib` 分层、StatefulWidget、sync FRB / `guardFrbSync`、过宽 catch、文档/注释漂移 |
| D 测试与 CI | `docs/agents/testing.md` vs `.github/workflows/ci.yml`、Rust/Dart 测布局 |
| E DX / 构建 | `README.md`、`scripts/*`、FRB/codegen、根目录遗留产物 |
| F 产品缺口 | All libraries browse、Tag dictionary UI、PDF iOS、Remote 边界、README 能力表述 |

### 统计方式（本机 2026-09-13）

| 指标 | 数值 | 统计命令/规则 |
|------|------|----------------|
| Dart 手写源（排除 `*.g.dart` / `*.freezed.dart` / `app/lib/src/rust`） | **453** 文件 | `find app/lib -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' ! -path '*/src/rust/*' \| wc -l` |
| Dart 生成文件（`*.g.dart` + `*.freezed.dart`） | **78** | 同上路径下 `find` |
| Rust `core/crates/core/src` | **117** `.rs` | `find core/crates/core/src -name '*.rs' \| wc -l` |
| `core/crates/core/tests` 集成测文件 | **34** | Glob `core/crates/core/tests/**/*.rs` |
| Flutter `*_test.dart` | **172** | `find app/test -name '*_test.dart' \| wc -l`（其中 `test/ui`≈121，`test/domain`≈32，`test/data`≈9） |
| `#[flutter_rust_bridge::frb(sync)]` | **70** | `grep -r ... core/crates/flutter/src/api` |
| 纯 `#[flutter_rust_bridge::frb]`（async 入口） | **36** | 同行匹配 `^#\[flutter_rust_bridge::frb\]$` |
| `guardFrbSync(` 调用点 | **60** | `app/lib`，排除生成码与 `frb_call_guard` 定义 |
| `extends StatefulWidget` 文件 | **20** | `app/lib` |
| `extends ConsumerStatefulWidget` 文件 | **28** | `app/lib` |
| `catch (_)` | **20** | `app/lib` 手写源 |
| `TODO`/`FIXME`/`HACK`/`XXX`（`app/lib` + `core/crates`，排除生成/vendor） | **0** | Grep；债更多以注释/ADR/文档表达 |

---

## 已有相关调研与本次关系

### 先例：`docs/research/ui-performance-tuning.md`（2026-09-04）

该报告聚焦 **UI 交互帧预算**，明确排除扫描吞吐与缩略图**生成算法**，并列出 P0–P2 热路径。

### 相对该报告：已落地 / 部分落地 / 仍开放 / 已否决

| 原 ID | 结论（2026-09-13） | 证据 |
|-------|-------------------|------|
| **P0-1** shrinkWrap 网格 | **基本已落地**（稳态真 `SliverGrid`；仅排序 FLIP 短暂 shrinkWrap） | `animated_library_catalog_grid_sliver.dart` L96–121 注释与分支 |
| **P0-2** 热路径 sync FRB | **部分落地**：comic 分页/find/search、thumbnail find/ensure、reader open/page list 已 async；history / library / 多数 series 写读、named facet 等仍 sync + `block_on` | `comic.rs` `fetch_comics_page_frb` async；`history.rs` L57–96 sync；统计 sync 70 vs async 36 |
| **P0-3** 封面 sync | **已落地（读取路径）** | `thumbnail.rs` `find_thumbnail_*` / `ensure_thumbnail_*` async；`comic_thumbnail_repository_impl.dart` 用 `guardFrb` |
| **P0-4** 扫描期 revision 400ms | **仍开放** | `comic.rs` `watch_comic_changes` 仍 `sleep(400ms)` + `read_data_version` |
| **P0-5** 封面视口全量 watch | **已落地** | `comic_cover_content.dart` L77–82：`viewport.select(...contains(index))` |
| **P0-6** 预取 cacheWidth | **已落地** | `reader_prefetch_controller.dart` `precacheWindow` / `_resolveReaderImageProvider` 传 `cacheWidth`；`reader_prefetch_hook.dart` 计算并传入 |
| **P0-7** ReaderPage 整包 watch | **部分落地** | `reader_page.dart` L25–30、L70–80：shell 用 `select` 拆出 comic/totalPages |
| **P1-1** 搜索无分页 | **部分落地** | `search_by_keyword_page_frb` + `library_search_page_providers.dart` 使用 `searchByKeywordPage`；全量 `search_by_keyword_frb` 仍保留 |
| **P1-2** build 内 existsSync | **缓解未根除** | `reader_image_cache.dart` L44–45 避免 provider 工厂内 sync；`isUsableReaderCacheFile` 仍 `existsSync`+`lengthSync`（L57–64），展示/预取路径仍会调用 |
| **P1-3** open/loadPageList sync | **已落地（API）** | `reader.rs` `open_reader_frb` / `load_page_list_frb` async + `spawn_blocking` |
| **P1-4** 阅读器缓存过小 | **部分落地** | `kReaderImageCacheMaxEntries = 24`（`reader_prefetch_logic.dart`），高于原报告 ≈7 |
| **P1-5** 扫描进度订阅过宽 | **部分落地** | 侧栏/Home 已 `.select`（如 `libraries_sidebar_section.dart` L525）；原报告点名的 toolbar 路径需个案复核 |
| **P1-10** pageSize 500 | **已收紧** | `kLibraryPageSizeOptions = [20,50,100,200]`（无 500） |
| **P2-1** FilterQuality.high | **已否决且实现固化** | `CONTEXT.md` **Page image fidelity**；`kReaderPageFilterQuality = FilterQuality.medium`（`reader_image_filter_quality.dart`）；产品定位明确 supersede 该建议 |

**本次报告**在 UI 性能之外，补齐：迁移/文档债、ADR 一致性、测试门禁缺口、DX 脚本、产品占位能力，并纠正「旧性能报告仍全部有效」的误判。

---

## 发现清单

优先级说明：**P0** = 用户可感卡顿或文档/契约误导高风险；**P1** = 可维护性或明确产品债；**P2** = 锦上添花或可延后。

---

### 架构 / 迁移债

#### P0-A1 — Agent/产品文档仍描述「迁移中 / Planned」，与仓库现状不一致 — **已处理（2026-09-13）**

- **原现状证据**（调研当日）  
  - 根目录已无 `lib/`、`pubspec.yaml`；布局为 `app/` + `core/`。  
  - `AGENTS.md` / `product-positioning.md` / `README.md` 仍写「until move lands」「Planned: Multi-Library + WebDAV」或纯本地叙事。
- **处理**：已对齐 `AGENTS.md`、`docs/agents/*`（含 `rust-migration` 现时架构、`product-positioning`、`coding-style`、`ui-style`、`issue-tracker`）、根 `README.md`；Multi-Library / WebDAV 标为已实现，Planned 仅保留 iOS PDF。
- **仍须注意**：ADR Context 软刷新、代码注释漂移（如 `ResourceEntry`）不在该次文档对齐范围内。

#### P1-A2 — Path / Selected Paths 与 Library 模型并存（Saved path 遗留面）

- **现状证据**  
  - `CONTEXT.md`：Saved path 为 Local root 旧称。  
  - 仍有 `/paths` → `SelectedPathsPage`、`PathRepositoryImpl`（`listAllPathsFrb` / `addPathFrb`），空库 CTA / Home hero 仍 `context.go('/paths')`。  
  - 同时侧栏用 `LibraryFormDialog` 创建 Local/Remote（`library_management_actions.dart`）。  
  - Rust `path` 模块与 `library` 模块并存（`core/crates/core/src/lib.rs`）。
- **问题/机会**：双入口增加心智与测试面；Path API 多为 sync FRB（`path.rs` 全 sync 属性抽样）。
- **建议方向**：产品上明确「路径页 = 库根列表」的唯一叙事或收敛到 Library CRUD；评估废弃 `PathRepository` 薄封装。
- **风险/代价**：中；涉及路由、空态 CTA、数据迁移故事。

#### P1-A3 — FRB 迁移「业务在 Rust」已成立，但 Dart 薄边与 sync 比例仍偏高

- **现状证据**  
  - `docs/agents/rust-migration.md`：无 Dart UseCase；Repository = FRB + DTO 映射。  
  - 未发现 `*use_case*` 文件；`domain/` 含 models / ports / reading / library projection（符合 coding-style）。  
  - FRB：**70 sync / 36 async**；`guardFrbSync` **60** 处。  
  - 交互热路径中 comic catalog 与 thumbnail 读已 async；**History 分页、Library CRUD、多数 Tag/Author/named facet、`get_all_series_frb`、系列 reading context** 仍 sync + `runtime::block_on`（见 `history.rs`、`series.rs` L285–320、`library.rs` 大量 sync）。
- **问题/机会**：主 isolate 仍可能在历史页翻页、元数据管理、库表单保存时被 `block_on` 卡住；与 ADR-0002「I/O 在 core」不矛盾，但与 FRB 官方「慢函数勿 sync」冲突（旧性能报告已引用）。
- **建议方向**：按「UI 热路径优先」继续 sync→async（History / Library list / Series context / facet 列表）；写操作可次优先。
- **风险/代价**：中高；需同步改生成绑定、Repository、`guardFrb` 与可能的调用时序测试。

#### P1-A4 — ADR 与实现总体一致，但注释/次要契约有漂移

| 主题 | ADR | 实现抽样 | 一致性 |
|------|-----|----------|--------|
| Comic deletion 删 Local Resource | ADR-0012 | `comic/write.rs` `maybe_delete_local_resource` | 一致 |
| Path migration | ADR-0013 | `sync/migrate.rs`、`update_local_library_root` 测 | 一致；Remote 改根 remapping **明确不在决策内** |
| Read session | ADR-0005 | 路由 comicId；`drop_series_reading_histories` 测 | 一致 |
| Multi-library + WebDAV | ADR-0008 | `resource/access/webdav.rs`、remote 测 | 能力已有；产品文档仍写 Planned |
| 日志 | ADR-0003 | `app/lib/core/logging/*` + `package:logging` | **Decision 已落地**；ADR Context 仍描述 Talker「当前」状态（过时） |
| ResourceEntry 注释 | — | `resource/access/mod.rs` L39：「WebDAV URL later」 | **过时**（WebDAV 已用 URL 作 location key） |

- **建议方向**：修订 ADR-0003 Context 段与 `ResourceEntry` 注释；不必新开 ADR。
- **风险/代价**：低。

#### P2-A5 — 根目录遗留构建产物与「legacy mobile」UI 债

- **现状证据**：仓库根仍有 `.dart_tool/`、`build/`（本机 `ls`）；`docs/agents/ui-style.md` L157/L182 标明 mobile Material 为 legacy、勿扩展；`product-positioning.md` L29 Android/iOS「legacy Material UI, migrating」。
- **问题/机会**：根产物易混淆工作目录；移动端视觉收敛是长期债，非阻塞桌面主路径。
- **建议方向**：`.gitignore`/清理规范确认；UI 收敛按 ui-style 渐进，勿新开 Material 页。
- **风险/代价**：清理产物低；移动 UI 重构高。

---

### 性能

#### P0-B1 — 扫描写入期 `data_version` ~400ms 轮询仍驱动 UI 刷新

- **现状证据**：`core/crates/flutter/src/api/comic.rs` `watch_comic_changes`：`sleep(Duration::from_millis(400))` + `read_data_version`（约 L359–362）。`LibraryPage` 已不再整页 watch coordinator（`library_page.dart` L186–188），但 catalog / Home counts 仍依赖 revision 流。
- **问题/机会**：「边扫边逛」仍可能高频重载；原 P0-4 核心未解。
- **建议方向**：扫描进行中合并/降频 revision；或 sync 结束显式 bump + 扫描中节流（旧报告建议仍适用）。
- **风险/代价**：中；节流过度会导致 UI 长时间陈旧。

#### P0-B2 — 剩余 sync FRB 热路径（History / Library / Facet）

- **现状证据**：`fetch_reading_page_frb` 等 history API 均为 sync + `block_on`（`history.rs` L57–96）；`ReadingHistoryRepositoryImpl` 走 `guardFrbSync`；`library_repository_impl.dart` 大量 `guardFrbSync`。
- **问题/机会**：历史页已是真虚拟滚动，但分页查询仍堵 UI isolate。
- **建议方向**：对齐 comic/thumbnail 的 async 改造模式。
- **风险/代价**：中；面广但模式重复。

#### P1-B3 — 阅读器仍有同步文件探测与预取细节债

- **现状证据**：`isUsableReaderCacheFile` 使用 `existsSync`/`lengthSync`；展示与预取在 build/预热路径调用。`load_page_bytes_frb` 仍 sync（`reader.rs` L72–79）。`clear_reader_page_cache_frb` 已 async（原 P2-4 部分过时）。
- **问题/机会**：快速翻页时微卡顿叠加入口成本；相对已修复的 cacheWidth 对齐，收益次一级。
- **建议方向**：存在性并入 async payload 或失败路径；评估废弃 sync `load_page_bytes_frb` 若无调用方。
- **风险/代价**：低～中。

#### P1-B4 — 系列导航标题解析：按成员逐条 `findById`

- **现状证据**：`comic_detail_series_nav_provider.dart` `buildSeriesNavData` 对每个 `SeriesItem` `await resolveComicTitleForDisplay` → `repo.findById`（L110–119）。ADR-0005 Consequences 已预告「大系列可能多次查标题」。
- **问题/机会**：大系列打开详情/卷列表时 N 次异步往返。
- **建议方向**：批量标题 API 或 context 扩展最小标题字段（需谨慎不破坏 ADR-0005 边界）。
- **风险/代价**：中；API 面扩展。

#### P2-B5 — `allSeriesProvider` / `get_all_series_frb` 疑似死路径或潜伏热点

- **现状证据**：`allSeries` provider 仍 `seriesRepo.getAll()`（sync FRB）；`app/lib` 内除生成文件外 **未见** `allSeriesProvider` 消费（Grep）；详情导航已改走 `getReadingContextByComicId`。
- **问题/机会**：死代码占 sync 面；若某处重新 watch 会全量拉系列。
- **建议方向**：确认无引用后删除 provider + 评估移除 `get_all_series_frb`，或改为明确管理用途。
- **风险/代价**：低（需全库引用确认含测试）。

#### P2-B6 — WebDAV / 大库扫描吞吐

- **现状证据**：Remote sync/read 有 Rust 测（`remote_library_sync.rs` 等）且以 `FakeResourceAccess` 为接缝（ADR-0008 Consequences）。源码中 **无** TODO/FIXME 标明已知瓶颈。旧 UI 性能报告**明确不做**扫描吞吐。
- **问题/机会**：真实 NAS 延迟、轻量登记 vs 首次打开解析（ADR-0008）可能成体验瓶颈，但缺本仓库内量化证据。
- **建议方向**：单独做 **Profile/真机 WebDAV** 调研；勿在无证据下改扫描算法。
- **风险/代价**：高（网络变量大）；**建议先测量**。

---

### 代码质量与可维护性

#### P1-C1 — Stateful / ConsumerStateful 仍偏多 vs coding-style

- **现状证据**：`docs/agents/coding-style.md` 优先 Hook/Consumer；避免 Stateful。实测 **20** StatefulWidget + **28** ConsumerStatefulWidget（含 `LibraryPage`、大量 dialog/form）。
- **问题/机会**：非一律错误（Ticker/第三方例外），但与规范差距大，提高状态推理成本。
- **建议方向**：触达文件时渐进迁移；新代码严格按表。
- **风险/代价**：低～中；大页迁移易回归。

#### P1-C2 — 过宽 `catch (_)` 与静默失败

- **现状证据**：约 **20** 处 `catch (_)`（路由、系列导航、元数据对话框、库凭证、设置更新等）。
- **问题/机会**：吞错导致难诊断；与 ADR-0003/0004 可观测性目标张力。
- **建议方向**：至少 `logError` + 用户可见失败；区分「预期取消」与真实错误。
- **风险/代价**：低；可能增加噪音日志。

#### P1-C3 — Drift 时代注释与空实现残留

- **现状证据**  
  - `author_management_notifier.dart` L6：「监听 Drift `authors` 表变化」——实为 FRB stream。  
  - `reading_history_repository_impl.dart` `clearExpiredHistory`：**空实现**，注释称「365 天清理…后续 slice」「当前无 UI 调用」。
- **问题/机会**：误导维护者；清理能力契约悬空。
- **建议方向**：改注释；要么实现 Rust SQL + UI，要么从接口删除并记产品决定。
- **风险/代价**：低。

#### P2-C4 — 可能未使用的 pub 依赖

- **现状证据**：`app/pubspec.yaml` 含 `card_settings_ui`；`app/lib` 内 **无** import。`archive` 仍用于 `log_export_service.dart`（非死依赖）。
- **问题/机会**：依赖膨胀、许可与解析成本。
- **建议方向**：确认无条件导入后移除 `card_settings_ui`。
- **风险/代价**：低。

#### P2-C5 — Dart data 层 `services/` 仍存在（非 comic I/O）

- **现状证据**：`app/lib/data/services/app_update`、`tag_dictionary`——符合 rust-migration「设置/更新/下载可留 Dart」。
- **问题/机会**：命名上勿与已删除的 `services/comic` 混淆即可。
- **建议方向**：保持；文档已说明。  
- **标注**：**不建议**为「分层纯度」强行迁入 Rust。

---

### 测试 / CI

#### P0-D1 — CI 硬门禁与「绿 PR」语义（有意设计，但是产品风险）

- **现状证据**：`.github/workflows/ci.yml`：`test-rust`、`analyze`、`test-unit`（路径白名单）、`test-widget` **`continue-on-error: true`**。`docs/agents/testing.md` 明确：CI **不**跑全量 `test/ui`、**不**跑 `integration_test`、无 coverage 门禁。
- **问题/机会**：121 个 UI 测中仅少数晋升硬门禁；`integration_test/pdf_reader_smoke_test.dart` 不在 CI。合并后仍可能 UI 回归。
- **建议方向**：按 testing.md 双轨清单，把稳定快轨继续晋升；PDF/WebDAV 关键路径考虑最少 smoke（平台约束下或仅 Rust）。
- **风险/代价**：中；门禁变慢。保持 soft 是有意权衡——**扩大硬门禁需评审**。

#### P1-D2 — FRB thin-edge 缺口（文档已登记）

- **现状证据**：`docs/agents/testing.md` Slice 2（#108）：已有 series/history/reader/thumbnail mapper 测；**残留**：`frb_zone_guard`；`comic_frb_mapper` 仅 sort/filter（缺 `mapRustComic` 等）；`mapPagedSeriesComicsResult`；真 FRB / `*_repository_impl` 本波不做。`comic_frb_mapper_test.dart` 仅 2 个映射测，印证文档。
- **问题/机会**：DTO 映射回归靠人工；`frb_zone_guard.dart` 有生产逻辑但无契约测。
- **建议方向**：补 `mapRustComic` / page 映射与 zone guard 单测（不引入真 FRB）。
- **风险/代价**：低。

#### P1-D3 — WebDAV：Rust Fake 覆盖好，端到端薄

- **现状证据**：`remote_library_{register,sync,read}.rs` + `FakeResourceAccess`；Dart 有 `remote_library_credential_store_test.dart`。无 CI 真 HTTP WebDAV。
- **问题/机会**：协议/TLS/鉴权边界依赖手工；符合 ADR「假实现为最高接缝」，但产品 Remote 已上线则体验风险上升。
- **建议方向**：保持 Fake 为主；可选本地 docker WebDAV 手工清单（不必硬门禁）。
- **风险/代价**：真集成 brittle。

#### P2-D4 — Flutter 测与 Rust 测体量不对称属预期

- **现状证据**：业务信任 `cargo test`（testing.md + ADR-0002）；Dart UI 双轨。  
- **建议方向**：勿在 Dart 重建第二套 sync/reader 集成栈。  
- **标注**：**不建议**对 `*_repository_impl` 写真 FRB 集成测（文档禁止）。

---

### DX / 构建

#### P0-E1 — `setup-dev.ps1` 在文档中存在、仓库中不存在 — **已处理（2026-09-13）**

- **原现状证据**：文档引用不存在的 `scripts/setup-dev.ps1`；仓库仅有 `setup-dev.sh`、`link-rust-builder.sh`。
- **处理**：根 `README`、`docs/agents/rust-migration.md`、`core/README.md`、`core/vendor/README.md` 一律改为 `./scripts/setup-dev.sh`（Windows 用 Git Bash）。未新增 `.ps1` 包装（可选后续 DX）。

#### P1-E2 — 日常开发步骤与 CI 硬门禁不完全同构

- **现状证据**：README 建议 `flutter test` 全量；CI `test-unit` 为白名单。本地全量更严，有利于质量，但贡献者可能只对齐 CI。
- **建议方向**：README 增加「PR 硬门禁命令」与「合并前建议全量」对照表（可链 `docs/agents/testing.md`）。
- **风险/代价**：低。

#### P1-E3 — FRB codegen / Flutter 版本钉死

- **现状证据**：CI `FLUTTER_VERSION: "3.38.5"`、`FRB_CODEGEN_VERSION: "2.12.0"`；`pubspec` `flutter_rust_bridge: 2.12.0`。构建依赖 `app/rust_builder` 链接 + `core/vendor` pdfium。
- **问题/机会**：环境漂移是主要 DX 痛点（文档已强调 setup）；升级 FRB/Flutter 需双端协同。
- **建议方向**：保持钉版本；升级走专项。  
- **标注**：**不建议**在功能 PR 中顺手升 FRB。

#### P2-E4 — GitHub Issues 中的已知债

- **现状证据（仅本地文档）**：`docs/agents/issue-tracker.md` 父 PRD **#11**；testing.md Slice 2 **#108**。  
- **未核实**：issue 正文、评论、当前 open 列表（本调研未跑 `gh issue`）。  
- **建议方向**：落盘前若需引用 issue 细节，用 `gh issue view` 核对后再写入。

---

### 产品缺口

#### P0-F1 — All libraries browse：仅占位

- **现状证据**：`CONTEXT.md` L23–24：`/libraries/all`「本阶段仅占位提示，不实现聚合目录」。`AllLibrariesBrowsePage` 注释「Placeholder」；l10n「跨库聚合浏览后续实现」。侧栏可导航进入（`LibraryManagementActions.goAllLibraries`）。
- **问题/机会**：多库用户期望「全部库」目录；当前为死胡同页。
- **建议方向**：排期聚合 catalog（跨库 query）或弱化入口直至实现。
- **风险/代价**：高（查询模型、筛选、性能）；**明确产品增量**。

#### P1-F2 — Tag dictionary import：基础设施齐、UI 入口未接

- **现状证据**：`docs/agents/tag-dictionary-import.md`：「暂无 UI 入口」；Controller/Dialog/Rust `import_tag_dictionary` 仍在；ADR-0011 移除 EhTag。
- **问题/机会**：能力对用户不可达；自维护词库未发布前可维持。
- **建议方向**：词库 URL 就绪后再加设置/元数据入口。  
- **标注**：无词库源时 **不建议现在做** UI 曝光。

#### P1-F3 — PDF：iOS stub

- **现状证据**：`formats/mobile_pdf.rs`：「iOS-only PDF stub」；`open_pdf_backend` → `validation("当前平台不支持 PDF 格式")`；`formats/mod.rs` `cfg(target_os = "ios")`；`build.rs` 注释待 packaging。产品定位矩阵标注 iOS stub。
- **问题/机会**：iOS 用户 PDF Comic 无法读；Android/桌面走 pdfium。
- **建议方向**：专项 pdfium iOS 打包；此前在 UI 上明确禁用/提示该 Format group。
- **风险/代价**：高（原生打包）。

#### P1-F4 — Remote library 产品边界（已实现能力内的缺口）

- **现状证据**：ADR-0008 / CONTEXT：远程不含 `folder`；不整本落盘；根不可达跳过不删库；Remote 改 WebDAV 根 **无**前缀 remapping（ADR-0013 不在决策内）；WebDAV 备份设置/DB 明确非当前工作。
- **问题/机会**：用户可能期望远程文件夹漫画、改 URL 保身份、备份——均未交付且文档已声明。
- **建议方向**：README/设置文案写清边界；改根 remapping 需新 ADR。  
- **标注**：远程 folder / Digest 认证 / 备份 — **不建议现在做**（超出 ADR-0008）。

#### P2-F5 — README 能力表述落后于产品

- **现状证据**：README「指定路径扫描」、未提 WebDAV/多 Library/Metadata field lock/Path migration 等；平台表称 iOS ✅ 但 PDF stub。
- **建议方向**：与 product-positioning 矩阵对齐。
- **风险/代价**：低。

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
| 功能 PR 中升级 FRB/Flutter | CI 钉版本；升级面大 |
| 把 `settings.json` / 应用更新迁入 Rust | rust-migration.md「永久留 Dart」 |
| 仅为分层纯度把 `data/services` 下载/更新迁 Rust | 同上 |

---

## 结论：最值得跟进的机会（7）

1. ~~**刷新文档真相源（P0）**~~ — **已做**：monorepo 完成态、多库/WebDAV、`setup-dev.sh` 对齐（见同日文档提交）。  
2. **扫描期 revision 降频（P0）**：`watch_comic_changes` 400ms 仍是边扫边逛主因；库页网格虚拟化已修好，收益集中在订阅策略。  
3. **History / Library / Facet sync→async（P0/P1）**：接续已完成的 comic/thumbnail/reader 改造，去掉剩余 UI 热路径 `block_on`。  
4. **FRB thin-edge 补测（P1）**：`mapRustComic` 等与 `frb_zone_guard`——符合现有测试哲学，挡回归。  
5. **All libraries browse 产品决策（P0 产品）**：占位页已挂入口；要么排期聚合查询，要么降级入口，避免半成品体验。  
6. **Path/Selected Paths vs Library Form 收敛（P1）**：减少 Saved path 遗留双模型。  
7. **iOS PDF 或显式降级（P1）**：stub 与「平台 ✅」叙事冲突；打包专项或格式层提示二选一。

---

## 附录：一手来源索引（抽样）

- 领域与产品：`CONTEXT.md`；`docs/agents/product-positioning.md`；`docs/agents/rust-migration.md`；`docs/agents/testing.md`；`docs/agents/coding-style.md`；`docs/agents/ui-style.md`；`docs/agents/tag-dictionary-import.md`；`docs/agents/issue-tracker.md`  
- ADR：`docs/adr/0002`–`0013`、`docs/adr/README.md`  
- 性能先例：`docs/research/ui-performance-tuning.md`  
- CI：`.github/workflows/ci.yml`  
- FRB API：`core/crates/flutter/src/api/{comic,reader,thumbnail,history,series,library,path}.rs`  
- UI 热路径：`app/lib/ui/features/library/views/library_page/widgets/animated_library_catalog_grid_sliver.dart`；`comic_cover_content.dart`；`reader_page.dart`；`reader_prefetch_controller.dart`  
- Remote：`core/crates/core/src/resource/access/webdav.rs`；`core/crates/core/tests/remote_library_*.rs`  
- 删除：`core/crates/core/src/comic/write.rs`（`maybe_delete_local_resource`）  
- 占位产品：`app/lib/ui/features/shell/views/all_libraries_browse_page.dart`  

---

*报告结束。*
