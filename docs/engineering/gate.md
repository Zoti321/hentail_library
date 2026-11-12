# Gate 与测试缝

**决策**：ADR-0018（三层缝、CI tier 词汇）、ADR-0002（业务真值在 Rust）、**ADR-0033**（feature `application/`）、**ADR-0034**（cross-feature `public/`）、**ADR-0041**（Comic 实体归属）、**ADR-0042**（Series 实体归属 + 槽位契约）、**ADR-0043**（导航与路由解耦）。**Job 列表以** `.github/workflows/gate.yml` **为准**；本地与 CI 同源：`./scripts/run-gate.sh`。

**Wayfinder `lib/` 顶层目录**（Phase A/B）：`core/`、`design-system/`、`features/`、`shared/`、`src/`；由 `app/test/gate/lib_layout_scan_helpers.dart` · `project_layout_test.dart` 断言。`design-system/**` 归类为 `shared`（ADR-0044），因此**继承** R13 且受独立出边白名单约束。产品 feature 之间 **仅允许** import `features/<owner>/public/**` 或 `features/<owner>/public.dart`（M1）；`shared/**` **禁止** import feature public（R11），且 **不得** import `features/**`（R13，ratchet：`shared/di`、`shared/domain`、`core/**` 等既有边只许减不许增）。

**工具链**：CI 固定 **Flutter 3.47.8**（`gate.yml` → `FLUTTER_VERSION`）。本地请用同 major/minor 的 stable；`flutter analyze` 在 GitHub Actions（`CI=true`）下会将 info 级 lint 也计为失败。Dart 侧另设 **`dart_code_linter`** 硬门禁（`gate-dart-lint`，见下文 DCL 节）。`riverpod_lint` 为可选 dev 依赖（不依赖 `custom_lint`）；**Gate 的 `flutter analyze` 暂未挂 `plugins: riverpod_lint`**，避免未偿还的 Riverpod 风格债挡合并。本地可在 `analysis_options.yaml` 临时启用做增量清理。SDK 升级记录见 `docs/engineering/flutter-3.47-migration.md`。

## 命令

| 场景 | 命令 |
|------|------|
| PR 硬门禁（全量） | `./scripts/run-gate.sh` |
| 子集 | `./scripts/run-gate.sh rust-test dart-static dart-lint dart-test` |
| DCL 规则门禁 | `./scripts/run-gate.sh dart-lint`（见下节） |
| 合并前 UI 怀疑回归 | 再跑 `cd app && flutter test`（含慢轨，**不进 Gate**） |
| Import 边界 | `cd app && flutter test test/gate/import_boundary_test.dart` |
| DI token 覆盖 | `cd app && flutter test test/gate/shared_di_override_coverage_test.dart`（`shared/di` 声明 ⊆ override，漏注入即红） |
| 领域事件门禁 | `cd app && flutter test test/gate/domain_event_rules_test.dart`（ADR-0039） |
| Comic 实体归属 | `cd app && flutter test test/architecture/comic_entity_ownership_test.dart`（ADR-0041；shared 内不得再出现 `Comic`） |
| Series 实体归属 | `cd app && flutter test test/architecture/series_entity_ownership_test.dart`（ADR-0042；shared 内不得再出现 `Series` 实体/VO 引用） |
| 槽位契约 | `cd app && flutter test test/architecture/series_slot_contract_test.dart`（ADR-0042；`shared/ui/slots/**` 不得 import `features/**`） |
| 导航/路由解耦 | `cd app && flutter test test/architecture/navigation_routing_coupling_test.dart`（ADR-0043；go_router 仅宿主路由层，feature 只下达 `AppNavigator` 意图） |
| Shared UI 无 feature import | `cd app && flutter test test/gate/shared_ui_no_feature_import_test.dart` |
| Dart 测试盘存（inventory + rubric） | `python scripts/audit_dart_tests.py`（可选 `--summary-json` / `--json`；见下节） |

`codegen-drift` 会就地重生成；跑前请先提交或 stash。

## dart_code_linter（DCL）

`app/` 的 `dev_dependencies` 引入 **`dart_code_linter` ^4.4.5**（`gate-dart-lint` job → `run-gate.sh dart-lint`），只扫 `app/lib`：

```sh
cd app && dart run dart_code_linter:metrics analyze lib \
  --no-congratulate --fatal-style --fatal-performance \
  --exclude="{/**.g.dart,/**.freezed.dart,/**/src/rust/**}"
```

- **任一严重级（style / performance / warning / error）都硬失败**，没有 baseline：改一个文件就删一行豁免（见下）。
- 规则集、`rules-exclude` 棘轮表都在 `app/analysis_options.yaml` → `dart_code_linter`。
- **不要加顶层 `plugins: dart_code_linter`**：`flutter analyze` 在 `CI=true` 下会把这些诊断算 fatal，等同双份门禁且无法按文件棘轮。
- 规则与 `flutter_lints` / `dart format` 不重叠：DCL 只管 **Flutter 组件规范**（一文件一 Widget、抽回调、不返回 Widget）、反模式与 Dart 结构问题。
- DCL 4.4.5 实现的规则是其 `presets/*.yaml` 的**子集**（约 87 条）；未实现的名字会以 `unknown-config` 警告出现，加规则前先用 `dart run dart_code_linter:metrics analyze lib -c` 验证。

### 当前状态（2026-11-12）

| 项 | 数量 | 说明 |
|----|------|------|
| 启用规则 | 51 | 已对齐 DCL `recommended` 中与仓库约定兼容的部分 |
| 组件规则 | 3 | `prefer-single-widget-per-file`、`prefer-extracting-callbacks`、`avoid-returning-widgets` |
| `rules-exclude` 棘轮 | 129 | 仍违反上述三条组件规则的历史文件（**只许删，不许加**） |
| 存量违规 | 0 | `dart-lint` 全绿；清理明细见下 |

### 本轮清偿（DCL recommended 对齐）

| 规则 | 原违规 | 处理 |
|------|--------|------|
| `prefer-iterable-of` | 34 | `List<T>.from(x)` → `List<T>.of(x)`（15 文件） |
| `avoid-redundant-async` | 12 | 去掉多余的 `async`（含 `main()` 与 Riverpod provider） |
| `avoid-throw-in-catch-block` | 11 | `Error.throwWithStackTrace(newErr, st)`，保留原始栈 |
| `prefer-async-await` | 3 | `.then` / `.catchError` → `try/await` |
| `avoid-dynamic` | 6 | `dynamic` → `Object?`；元数据编辑页用 `MetadataEditSaveActions` 接口替掉 `dynamic state` |
| `avoid-non-exhaustive-switch-on-sealed-classes` | 5 | 补齐 `ComicCover*` / `ReaderViewportPages*` 全部分支 |
| `avoid-unnecessary-setstate` | 4 | `didUpdateWidget` 内改为直接赋值 / `addPostFrameCallback` |
| `avoid-global-state` | 2 | 测试 seam 用 `// ignore: avoid-global-state`（注释写在 ignore 上一行，DCL 不支持行尾说明） |
| `use-setstate-synchronously` | 2 | `mounted` 检查后再 `setState` |
| `avoid-missing-enum-constant-in-map` | 1 | `pageTransitionsTheme` 补 `fuchsia` |
| `prefer-correct-type-name` | 1 | `FlutterSecure…Store` → `SecureRemoteLibraryCredentialStore`（类名/文件同步改名） |
| `prefer-commenting-analyzer-ignores` | 2 | 给已有 `ignore` 补说明注释 |

**`metrics fix` 不可信**：DCL 4.4.5 的 `fix` 对重叠替换处理有 bug（会产出 `);  );`、`(l10n.x: l10n.x, …)` 之类不可解析代码）。只允许**单规则**跑、跑完必须 `dart format --output=none --set-exit-if-changed lib` 验证；批量跑一律禁止。

### 刻意不启用（与仓库约定冲突）

| 规则 | 原因 |
|------|------|
| `avoid-non-ascii-symbols` | 中文注释/文案，必然满屏 |
| `prefer-trailing-comma` | 与 Dart 3.13 `dart format` 互相覆盖（改完再次格式化即复发） |
| `newline-before-return` | 纯格式 churn；1270 处，且 `metrics fix` 会损坏文件 |
| `format-comment` | 要求英文句点收尾，中文文档注释不适用 |
| `prefer-first-or-null` | 与已启用的 `prefer-first` 互斥 |
| `avoid-banned-imports` / `ban-name` | 需 mandatory 配置，暂不启用 |

### 待清偿（存量债，清理后再加）

按 2026-11-12 实测违规数排序（`lib/`）：`prefer-dot-shorthands` 1953、`member-ordering` 1163（recommended 顺序下 155）、`prefer-static-class` 993、`arguments-ordering` 783、`no-magic-number` 719、`prefer-moving-to-variable` 279、`avoid-ignoring-return-values` 244、`prefer-match-file-name` 202、`avoid-non-null-assertion` 214、`no-equal-arguments` 151、`prefer-correct-identifier-length` 115、`avoid-late-keyword` 73、`no-empty-block` 37、`avoid-nested-conditional-expressions` 34、`prefer-named-record-fields` 28、`avoid-passing-async-when-sync-expected` 26、`avoid-substring` 20、`avoid-unused-parameters` 19、`no-object-declaration` 16。

**指标（metrics）暂不进门禁**：`maintainability-index` 320、`number-of-parameters` 89、`maximum-nesting-level` 15、`cyclomatic-complexity` 10 处超阈，无 baseline 机制，清偿前保持关闭。

**指标（metrics）暂不进门禁**：`maintainability-index` 320、`number-of-parameters` 89、`maximum-nesting-level` 15、`cyclomatic-complexity` 10 处超阈，无 baseline 机制，清偿前保持关闭。

### 棘轮维护

1. 修好一个豁免文件 → 删 `rules-exclude` 对应行；`dart-lint` 变红则说明还有残留。
2. 新增规则 → 先本地跑通全绿（`dart-lint`），再单独提交。
3. 新增文件**不要**随手加豁免；`rules-exclude` 只减不增。

## 三层缝（测什么）

| 缝 | 位置 |
|----|------|
| Rust 业务 | `core/` + `tests/common/` harness → `gate-rust-test` |
| FRB 线缝 | `app/test/frb_wire/`（`frb_wire_harness.dart`）→ manifest |
| Dart 薄边 | mapper/guard/adapters → `app/test/shared/data/{frb,mappers}/`、`test/features/*/data/` · 见 [`feature-data-layout.md`](./feature-data-layout.md) |
| UI 快轨 | 列入 `app/test/gate/manifest.txt` 的 UI/逻辑（含 `test/design-system`，ADR-0044 层门禁与迁入组件测试） |
| UI 慢轨 | `test/shared/ui`、`test/features` 未进 manifest 部分 → `nightly-dart-ui`（`test/design-system` 整体走快轨） |

业务 sync/read/DB：**信任 `cargo test`**。Dart **不要**对真 FRB / `*_repository_impl` 写全流程集成测。

## Gate manifest（唯一扩门禁入口）

- 路径表：`app/test/gate/manifest.txt`（`manifest_test.dart` 自检存在、无重复）。
- 新增快轨 data 契约测或 UI：只改 manifest + PR 说明列出路径；**不要**新 workflow 软门禁。

### 快轨晋升检查清单

1. 可观察契约，不绑私有结构。
2. 本地连续 3 遍稳定；时间逻辑注入 clock。
3. 用 `app/test/support/`（`pumpLocalizedApp` 等），不复制 MaterialApp 样板。
4. 路径写入 manifest 对应分节。

## Dart 测试盘存与分类 rubric

Epic [#447](https://github.com/Zoti321/hentail_library/issues/447) 清理 Flutter 侧测试时，用 **`scripts/audit_dart_tests.py`** 做可重复盘存（**不进 gate CI**；nightly 或 maintainer 本地可选附带 `--summary-json` 输出）。

### 运行

| 命令 | 输出 |
|------|------|
| `python scripts/audit_dart_tests.py` | 总数、manifest 展开覆盖数、慢轨数、rubric 计数、慢轨分桶 |
| `python scripts/audit_dart_tests.py --summary-json` | 同上（JSON，无逐文件列表） |
| `python scripts/audit_dart_tests.py --json` | 含每个 `*_test.dart` 的 tier + rubric |
| `python scripts/audit_dart_tests.py --rubric candidate-retire --slow-only` | 仅列出慢轨且标记为 candidate-retire 的路径 |

单元测：`cd scripts && python -m unittest test_audit_dart_tests.py -v`。

### tier 与 nightly

| tier | 含义 | CI |
|------|------|-----|
| **gate-fast** | 路径落在 `manifest.txt` 展开集合内 | `gate-dart-test` |
| **slow-track** | `app/test/**/*_test.dart` 中未进 manifest 的文件 | `nightly-dart-ui` 扫描 `test/shared/ui` + `test/features`（与 manifest 互补；盘存脚本的慢轨计数 = 全树减 manifest） |

**Epic #447 清理后基线（2026-11-03，`python scripts/audit_dart_tests.py`）**：共 **253** 个 `*_test.dart`；manifest 展开 **175**；慢轨 **78**。典型慢轨分桶：`library_browse` 26、`reader` 11（旧名 `read_session`）、`shared/ui` 2（主题装配契约）、其余 feature 见盘存 JSON。

### nightly-dart-ui（`.github/workflows/nightly.yml`）

| 项 | 说明 |
|----|------|
| 命令 | `cd app && flutter test test/shared/ui test/features` |
| 与 manifest 关系 | 与 gate-fast **互补**，非子集相等；大量 presentation 测已删除，nightly 失败应优先查 **仍存在的 MD3E 页级 / data·domain 薄边** |
| 失败 triage | ① 对照 `gate.md` 降级/删除表是否预期移除 ② 时序/动画 → 移出 manifest 或删 ③ 业务断言 → 改 Rust 缝 ④ `frb_wire`/gate 失败 → 另开 issue，不算 nightly 债 |

盘存脚本输出与上表不一致时，以脚本为准并更新本段（#456）。

### rubric 四层（启发式，供审计 #450–#454；非 gate 断言）

脚本对每个测试文件打 **一个主标签**（优先级自上而下）：

| rubric | 典型路径 | 清理 epic 中的含义 |
|--------|----------|-------------------|
| **architecture-guard** | `test/gate/**`、`project_layout_test.dart` | **禁止**批量删除；仅随 ADR/规则 drift 修改 |
| **thin-edge** | `frb_wire`、`shared/data|domain|di`、`core`、feature `data/` / `domain/` / `application/`、`test/support/` | 保留并加强；业务真值仍在 Rust |
| **ui-contract** | manifest 内其余项（MD3E entry、confirm 对话框、ViewModel persist/policy、motion/theme 等） | manifest 反向审计 (#450)；不合格则降级 |
| **candidate-retire** | 慢轨下的 `shared/ui`、feature `presentation/` 等 | 优先删/改 (#451–#454)；与 #447 决策一致：MD3E entry + 可观察结果为主缝 |

降级流程见下节 **[测试退役与 manifest 降级 / 晋升](#测试退役与-manifest-降级--晋升)**。

## 测试退役与 manifest 降级 / 晋升

与 ADR-0018、Epic [#447](https://github.com/Zoti321/hentail_library/issues/447) 一致：**业务真值在 Rust**；Dart gate 只挡 **架构护栏、薄边、可观察 UI 契约**。盘存用 `python scripts/audit_dart_tests.py`；降级/晋升只改 `app/test/gate/manifest.txt`（+ 本段记录），**不要**新 workflow。

### Protected 路径（禁止批量删除）

以下目录/条目是架构或线缝护栏，清理 epic 中 **不得** 整目录删除或移出 manifest（除非配套 ADR + 规则迁移）：

| 类别 | manifest / 路径 |
|------|-----------------|
| Gate 自检 | `test/gate/**`（import boundary、L3、strangler、manifest 自检） |
| 布局 ratchet | `test/project_layout_test.dart` |
| FRB 线缝 | `test/frb_wire/**` |
| Dart 薄边（目录级） | `test/shared/domain`、`test/shared/data`、`test/core`、`test/shared/di` |
| App / Lab 最小冒烟 | `test/widget_test.dart`、`test/md3e/**`（Lab 契约，非 Figma CI） |

单文件是否 protected 以盘存 rubric **`architecture-guard`** / **`thin-edge`** 为准；**`ui-contract`** 在 manifest 内仍可 **降级**（移出 manifest，非立即删文件）。

### 降级（manifest → nightly）

适用：晋升清单未通过、绑定私有实现、与 Rust Reader/sync 重复、或时序不稳定。

1. **PR 必须**在描述中列出每个路径、**rubric 标签**、一句话理由（可参考下表模板）。
2. 从 `manifest.txt` **删除对应行**（目录展开条目删单行即可）；**不要**删 `test/gate/manifest_test.dart` 对固定 seam 的 `containsAll` 断言，除非同步改该测试。
3. 测试文件 **保留**在树中 → 进入 **slow-track**，由 `nightly-dart-ui`（`test/shared/ui` + `test/features`）覆盖。
4. **至少一轮 nightly 绿**（或 maintainer 本地 `cd app && flutter test <path>`）后，才可在后续 PR（#451–#454）中 **删除文件**。
5. 不得无声消失：降级 PR 引用 #447；删除 PR 引用原降级 PR 或 issue。

### 晋升（slow-track / 新建 → manifest）

1. 满足上文 **快轨晋升检查清单** 全部 4 条。
2. 本地 **连续 3 遍** `flutter test <path>` 稳定；含时钟逻辑则注入 fake clock。
3. PR 说明列出新增 manifest 路径；合并前 `./scripts/run-gate.sh dart-test` 绿。

### Manifest 降级记录

| 日期 | 路径（相对 `app/`） | rubric | 理由 |
|------|---------------------|--------|------|
| 2026-11-03 | `test/features/reader/presentation/reader_image_cache_test.dart` | candidate-retire | 断言 `ResizeImage`/命名缓存等解码实现细节，非 MD3E/用户可观察契约（#450） |
| 2026-11-03 | `test/features/reader/presentation/reader_prefetch_generation_test.dart` | candidate-retire | 预取 generation 窗口纯算法，与 Reader 性能策略强耦合，留 nightly/#452 审计（#450） |
| 2026-11-03 | `test/shared/ui/layout/reading_history_list_layout_lazy_test.dart` | candidate-retire | 断言 sliver 构建条数等布局实现，未用 `test/support/` harness（#450） |

### 慢轨删除记录（#451 / #452）

在 #450 降级后，按 #447 决策删除以下慢轨文件（不再参与 nightly；薄边与 MD3E 页级契约保留）。

**#452 reader（−14；旧模块名 read_session）** — rubric `candidate-retire`：视口/图片管线/预取 widget 或实现细节；`reader_page_shell_select_test` 仅测文件内重复 helper。保留：`data/`、`domain/**`、`public/**`、`reader_controller_test`、`reader_page_facade_test`、`series_reader_provider_test`（thin-edge / 编排薄边）。

**#451 library_browse（−7）** — rubric `candidate-retire`：MD3E 子块测（filter/sort/header/sheet）由 `library_md3e_page_test` 覆盖；flicker 时序测；`detail_status` 私有 scaffold。保留：`data/**`、`domain/**`、VM 薄边、`library_md3e_page_test`、`searched_md3e_page_test`、删除/批量/元数据 MD3E 流、`public/**`。

**#453 shared/ui（−26）** — rubric `candidate-retire`：叶子 widget / form / 封面 / 分页 / context menu 等；`reading_history_list_layout_lazy`（#450 降级后删除）。**保留（thin-edge）**：`theme/build_app_theme_md3e_test.dart`、`theme/build_app_theme_preferences_contract_test.dart`（ADR-0032 主题装配契约）。快轨仍覆盖 `destructive_filled_button`、`dialog/confirm`、motion、token、md3e layout spec。

**#454 其余 feature（−13）** — rubric `candidate-retire`  unless noted:

| Feature | 删除 | 保留要点 |
|---------|------|----------|
| bootstrap | `responsive_app_shell*`×2、`app_locale_preference`、`series_detail_route_page` | `di/**` override 装配、`application_shell_import_contract`、`retired_paths_route`（ADR-0014）、`app_startup_coordinator` |
| home | `home_md3e_page_test`（与快轨 `md3e_home_page_test` 重复） | `public/**` |
| reading_history | `history_list_progress_test` | `data/mappers`；快轨 `history_page_test` |
| library_admin | `libraries_sidebar_navigation`、`library_management_port_delete`（大壳路由） | `data/`、`di/` 契约、`domain/`、`public/**`；快轨 dashboard/dialog |
| app_settings | `app_update_check`、`theme_preference_l10n` | `domain/**`、`data/`、`public/**`；快轨 settings MD3E / persist VM |
| named_metadata | `metadata_md3e_page_test` | mappers、controller、`public/**`；快轨 `named_facet_fill_viewport` |
| comic_trash / metadata_backup | — | 慢轨全保留（application / data / flow 薄边） |

## Import / 布局（规范在测试里）

|  concern | 测试 / 文件 |
|----------|-------------|
| L1 domain↔data、FRB 面、application 依赖、shared→feature public、public→presentation（含 `export`，R12 allowlist） | `import_boundary_test.dart`（R1–R12）；`public_presentation_export_allowlist.txt`（只缩不扩） |
| L1b shared→features ratchet（R13） | **单一实现**：`test/architecture/module_boundary_test.dart`（扫 `import` + `export`），baseline `test/gate/import_boundary_baseline.json` + `test/architecture/baseline.json`；两份 baseline 都有 stale 校验（当前扫描产不出的条目必须删）。`import_boundary_test.dart` 只断言「R13 无第二实现」。归属判定见 ADR-0045 |
| L2 product 图 ratchet（M1 非 public 边、M2/M3） | `import_boundary_baseline.json` → `dart run tool/generate_import_boundary_baseline.dart` |
| Cross-feature 协作约定 | [`cross-feature-collaboration.md`](cross-feature-collaboration.md)；**新增 Port 前先判定可达性**（ADR-0045） |
| 领域事件（E1 事件子类位置 / E2 仅 application·data 发布 / E4 实现收敛） | `domain_event_rules_test.dart`（ADR-0039） |
| public 图无环 | `import_boundary_test.dart`（`collectPublicCrossFeatureAdjacency`） |
| bootstrap shared 注入 | `features/bootstrap/di/overrides/*` + `shared_state_overrides.dart`（#435） |
| L3a shared/ui → features | `shared_ui_no_feature_import_test.dart` |
| L3a design-system → features / shared domain·di·data·ui | `test/design-system/design_system_boundary_test.dart`（ADR-0044；零 allowlist） |
| L3b shared/domain → features ratchet | `shared_domain_no_feature_import_test.dart` + baseline 生成器；归属见 [`shared-domain-ownership.md`](./shared-domain-ownership.md) |
| FRB allowlist | `import_boundary_rules.dart`、`shared_feature_import_rules.dart` |
| `lib/` 顶层目录（含 `design-system/`）、public barrel、presentation/state | `project_layout_test.dart`、`lib_layout_scan_helpers.dart` |
| Strangler export shim | `strangler_shims.txt` + `strangler_shims_test.dart` |

启发式模块边（非门禁）：`python scripts/research/cross_feature_import_audit.py`。

## integration_test

仅 **平台冒烟**（cdylib + 原生依赖 + 最小 Reader 链），命名 `*_smoke_test.dart`，走 `watch.yml` / Release 调用，**不**写入 manifest。Library sync / WebDAV 全流程：**仅 Rust 集成测**。

## Harness

| 侧 | 入口 |
|----|------|
| Flutter | `app/test/support/`（见下表） |
| Rust DB 集成 | `core/crates/core/tests/common/` |

### Flutter widget / 页级测试入口（#455）

| API | 文件 | 何时用 |
|-----|------|--------|
| `pumpLocalizedApp` | `pump_localized_app.dart` | 产品主题 + zh/en l10n + 可选 `ProviderScope` overrides（**默认首选**） |
| `pumpMd3eApp` | `pump_md3e_app.dart` | MD3E lab 主题 + `Md3eThemeScope`；可选 overrides |
| `buildLocalizedTestMaterialApp` | `pump_localized_app.dart` | 自定义外壳（`UncontrolledProviderScope`、GoRouter）内嵌 MaterialApp |
| `localizedTestAppConfig` | `localized_test_app.dart` | 仅 delegates/locale 元组（少见） |
| `configureTestView` | `test_view.dart` | 统一 viewport physicalSize / DPR |
| Fakes | `support/fakes/*` | 覆盖/仓库/port 复用（author、cover、settings、revision throttle） |

**例外**：需 `GlobalMaterialLocalizations` 的日历类 widget 测（如 `md3e_docked_calendar_date_picker_test`）仍自建 `M3ETheme` + `MaterialApp`；新测勿复制该模式除非测 Material 日历本地化。

新 widget 测 **禁止** 复制 `MaterialApp` + `AppLocalizations` 样板；晋升快轨前须用上表 harness（`gate.md` 快轨清单第 3 条）。
