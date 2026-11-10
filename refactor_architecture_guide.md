> 来源：外部（Gemini）产出的通用单体模块化指南，原文保留在 §一–§四。
> **§五 为本仓适配评估（AI Agent 追加）**，与原文冲突时以 §五 + `docs/adr/` 为准。
> 阅读顺序：先读 §五，再读原文。

---

# 漫画阅读器单体应用模块化重构与架构设计指南

## 一、 核心架构原则与边界划分

在本项目（本地漫画阅读器）中，为实现高内聚、低耦合，严禁产生“大杂烩式”的网状依赖。各模块必须严格遵循以下原则：

1. **实体归属与防腐隔离**：
* 业务实体（聚合根）必须留在其所属的领域模块内。
* **禁止直接引用具体对象**：跨模块关联时，严格采用**按 ID 引用（Reference by ID）**（例如：`Comic` 内部只存 `authorIds` 和 `tagIds`，不直接持有关联对象）。
* **禁止底层下沉业务实体**：`Core` 模块只存放纯技术基建（如本地数据库封装、网络、基础工具类），绝对不能把具体业务实体或模块级 Repository 放入全局 `Core` 充当“垃圾桶”。

2. **模块公开契约（Public API）**：
* 每个业务模块必须提供一个统一的出口文件（例如 `comic_public.dart`、`progress_public.dart`），只对外暴露合法的实体、DTO、抽象接口及 Riverpod Provider。内部数据库模型、具体实现类严格私有化（使用 `_`）。

---

## 二、 模块划分与职责定义

根据当前业务场景，应用划分为以下四大核心模块：

| 模块名称 | 核心职责 | 包含的实体与逻辑 |
| --- | --- | --- |
| **Comic 模块** (漫画) | 管理漫画基本元数据、章节目录 | `Comic` 实体、章节列表、漫画基础增删改查 |
| **Metadata 模块** (元数据) | 管理漫画的衍生标签体系 | `Author`（作者）、`Tag`（标签）、`Role`（角色）实体及查询 |
| **Progress / History 模块** (进度与历史) | 追踪用户的阅读行为与历史记录 | `ReadProgress` 实体、历史记录聚合、进度同步逻辑 |
| **Reader 模块** (阅读器) | 纯粹的 UI 与交互逻辑 | 阅读器翻页组件、手势处理、调用进度控制接口 |

---

## 三、 基于 Riverpod 的通信与解耦方案

所有跨模块通信与数据组合，一律通过 **Riverpod 2.x/3.x** 的响应式机制来实现，绝对禁止模块间直接互相调用对方的底层服务。

### 1. 依赖注入与契约隔离

* 消费模块（如 Reader 模块）如果需要操作某项业务，只能通过依赖注入（DI）或 Riverpod 暴露的 Provider 接口进行。
* 严禁在模块代码中随意 `import` 其他模块的内部实现路径。

### 2. 组合 Provider（View Model 组装）

当 UI 层（如漫画详情页）需要聚合展示多个模块的数据（如：`Comic` + `Author` + `Tag`）时，**不编写跨模块的底层关联查询**，而是在上层通过组合型 `FutureProvider` 进行声明式组装：

```dart
// 示例：组合 Provider 组装漫画详情视图模型
final comicDetailViewModelProvider = FutureProvider.family<ComicDetailViewModel, String>((ref, comicId) async {
  // 1. 获取基础漫画数据（来自 Comic 模块）
  final comic = await ref.watch(comicDetailProvider(comicId).future);

  // 2. 并行去元数据模块获取对应的作者和标签详情（来自 Metadata 模块）
  final authorsFuture = ref.watch(authorsProvider(comic.authorIds).future);
  final tagsFuture = ref.watch(tagsProvider(comic.tagIds).future);

  final results = await Future.wait([authorsFuture, tagsFuture]);

  return ComicDetailViewModel(
    comic: comic,
    authors: results[0] as List<Author>,
    tags: results[1] as List<Tag>,
  );
});
```

### 3. 响应式状态联动（阅读进度与历史）

* **进度更新**：阅读器在翻页时，通过 `progressControllerProvider` 触发保存逻辑，直接写入数据库。
* **状态同步**：历史记录页或详情页通过 `StreamProvider` / `Provider` 实时监听进度的变更，做到数据驱动 UI 自动刷新，模块之间完全解耦。

---

## 四、 重构落地清单（Agent 执行目标）

请对照以下清单对现有代码库进行扫描与重构：

1. [ ] **检查并清理循环依赖**：排查所有 `import`，确保不存在 `Comic` 模块引用 `Reader` 或 `History` 模块的反向依赖。
2. [ ] **剥离实体直接引用**：检查 `Comic` 实体内部，将直接持有的对象引用（如 `List<Author> authors`）全部改为 ID 引用（如 `List<String> authorIds`）。
3. [ ] **建立模块 Public API**：为 `comic`、`metadata`、`progress` 模块规范出口，统一通过公开文件导出 Provider。
4. [ ] **引入组合 Provider**：重构多模块交叉展示的页面（如详情页、历史记录页），使用 Riverpod 组合 Provider 代替原本混乱的跨模块 Service 直接调用。
5. [ ] **应用层防腐校验**：引入静态检查规则（如 Lint 规则或目录规范），防止未来开发中直接越权引用其他模块内部私有代码。

---

# 五、 本仓适配评估（Agent 追加，2026-11-10）

## 5.0 结论

指南**约 40% 可直接采纳、30% 需本地化改写、30% 与本仓 ADR 冲突应拒绝**。
它写于「Flutter 持有唯一真相 + 四大模块」的假设下；本仓真相在 Rust `core/`，Flutter 只是 FRB 消费方，且已有比指南更细的 import 门禁。

## 5.1 术语映射

| 指南 | 本仓 |
|---|---|
| Comic 模块 | `features/comic` + `features/library_browse`（浏览壳）+ `features/series` |
| Metadata 模块 | `features/named_metadata` + Catalog Shared Kernel 的 Author/Tag 实体 |
| Progress / History | `features/reading_history` + `features/reading_stats` |
| Reader | `features/reader` |
| Core | Rust `core/crates/**`（真值）+ Dart `shared/`（DTO/端口/事件） |
| —— | 额外：`bootstrap`（组合根）、`library_admin`、`comic_trash`、`app_settings`、`metadata_backup`、`home` |

## 5.2 逐条判定

| # | 指南主张 | 判定 | 本仓落点 |
|---|---|---|---|
| 1 | 聚合根必须留在所属 feature 内 | **拒绝（本阶段）** | `shared/domain` 是 Catalog Shared Kernel（ADR-0035）。整体迁入 `library_browse/domain` 会触发 6 个 feature + `shared/ui` + `shared/data` mapper 大面积改边，且易造第二套 DTO（ADR-0034 反模式）。触发条件见 ADR-0035 §4。 |
| 2 | 跨模块按 ID 引用 | **采纳（唯一真缺口）** | `Comic.authors` 是 `List<Author>` 对象，且 `comic_entity_mapper.dart:18-19` 从字符串重建 `Author(name: n)` / `Tag(name: n)` —— **DB 有 `comic_authors.author_id`（ADR-0024 稳定身份）但 Dart 侧 id 被丢弃**。这是既有 bug 级债务，必须修。 |
| 3 | `Tag` 也改 `tagIds` | **拒绝（无意义）** | `tag.dart` 只有 `name`，无 id；Tag/Parody/Character 是名字字典（ADR-0024 明确）。只有 Author 需要 id。 |
| 4 | Core 只放技术基建 | **部分同意** | Dart `shared/` 已按 kernel/ports/events 三分；Rust `core/` 用 SQL 跨表 join 出 `ComicDto` 是**有意为之的 catalog 真值**（ADR-0002），不是垃圾桶。不要把 Rust 里的关联查询按指南搬到 Flutter 上层。 |
| 5 | 每模块一个 public 出口 | **已满足且超配** | 12 个 feature 各有 `public.dart` barrel（如 `features/comic/public.dart`）+ `public/` 层 + `public_presentation_export_allowlist.txt`。 |
| 6 | 上层组合 Provider 组装 VM | **采纳但改形态** | 组合只允许在**消费方 feature 的 `presentation/`**（页面 owner）；禁止放在 `shared/`（R11 违规）。不得 `ref.watch` 邻居模块的**内部** provider 名 —— 走 `shared/di` token（`xxxPortProvider` / `xxxRepositoryProvider`），实现由 bootstrap override 注入（ADR-0034 §3）。 |
| 7 | 不编写跨模块底层关联查询 | **部分拒绝** | 「多模块」在本仓是**多个 SQL 表**，不是多个进程。Rust 一次 join 出 DTO 优于 Flutter 侧 N+1 次 FRB 调用 + `Future.wait` 内存 join。指南示例会引入性能回退。 |
| 8 | 进度写入 + StreamProvider 联动 | **已满足** | `reading_history` Port + 领域事件（ADR-0039）；`DomainEventRevisions` 单点投影，consumer `select` 版本号。比指南的裸 StreamProvider 更收敛。 |
| 9 | 静态防越权 | **已满足且严格得多** | `app/test/gate/` 27 个门禁：M1/M2/M3、R6–R12、L1–L3b、E1–E5、manifest。**残留 52 条 M1 baseline 深引用**（`import_boundary_baseline.json`），是指南第 1 条真正要清理的对象。 |
| 10 | Reader 是纯 UI | **拒绝** | `reader` 有 `application/` 层（ADR-0033/ADR-0038）。presentation 只调 Port/用例（ADR-0039 E2/E5）。 |

## 5.3 明令禁止的照搬

1. 在 Flutter 上层写跨表组合 Provider 取代 Rust 的 catalog 查询。
2. 跨 feature `import` 或 `ref.watch` 邻居模块 `domain/`、`data/`、`di/` 的 provider 真名。
3. 把 `Comic`/`Series` 从 `shared/domain` 批量搬到 `library_browse/domain`，只为实现「实体归模块」。
4. 为 `Tag` 引入 id。
5. 在 `shared/**` 里写组合 Provider 或 import `features/*/public/**`。

## 5.4 改写后的执行清单

- [ ] **A. Author 按 ID 引用落地**（唯一高优先级代码重构）
  - SQL/FRB：`ComicDto.authors` 改 `authorIds` + `authorNames`（或加 `authors: List<AuthorRef{id,name}>`），Rust 侧 join 一次取回。
  - Dart：`Comic.authors` → `List<AuthorRef>`（`id` + `name` 只读投影），或 `List<String> authorIds` + 页面级 Author 查询 Port。
  - 同步：`comic_entity_mapper.dart`、metadata form、bulk edit、series detail、backup 导出、browse 筛选（ADR-0024 已要求的全链路切 id）。
  - 门禁：新增 `shared/domain` 实体不得持有可变对象引用（除 VO/enum）的扫描或 review 规则。
- [ ] **B. 清理 52 条 M1 baseline**：按 `import_boundary_baseline.json` 逐条改走 owner `public/` 或 `shared/di` token，只收缩、不扩张。
- [ ] **C. 补公开 read model 约定**：需要聚合展示的页面，owner `public/` 提供 `XxxSummary`（只含消费方所需字段），consumer 不拿整聚合。
- [ ] **D. 文档对齐**：把本文件 §5.4 结论回写 `docs/engineering/cross-feature-collaboration.md`；若采纳 Author ID 全链路，开 ADR 修订 ADR-0024 的遗留项。
- [ ] **E. 不做**：§5.3 全部条目。

## 5.5 版本与事实校正

- Riverpod 实际为 **3.4.x**（`flutter_riverpod ^3.4.3`、`riverpod_annotation ^4.0.7`），指南「2.x/3.x」的示例 API（`FutureProvider.family` 手写）在本仓以 codegen（`@riverpod`）为主，勿混用。
- 本仓 feature 数为 13，非 4；模块划分以 `AGENTS.md` 列表为准。
