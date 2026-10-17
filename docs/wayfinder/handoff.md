# Wayfinder 交接文档（整洁架构迁移）

最后更新：2026-10-17。分支：`dev`。远端：`origin dev`。

## 1. 当前状态概览

- `app/lib` 已收敛为 `features/<id>/{presentation,domain,data,di}`、`shared/{core,data,domain,ui,di}`、`src/rust`、`main.dart`。
- Phase B 布局校验已启用（`kEnforceWayfinderPhaseBLayout = true`），strangler 白名单为空。
- Gate 基线：`app/test/gate/import_boundary_baseline.json` 共 **79** 条 = **4** 条 M1/M2（feature↔feature） + **75** 条 M3（product feature→bootstrap）。
  - 相对 #261 开始前（212 = 135 M1/M2 + 77 M3）减少 **121** 条（其中 #262 home 再减 **12** 条、#263 comic_trash 再减 **10** 条、#264 app_settings 再减 **18** 条、#265 read_session 再减 **9** 条、#267 library_admin 再减 **10** 条、#268 library_browse 再减 **12** 条 M1/M2）。
- `dart analyze`：0 error；仍有若干 `unnecessary_import` info，来自 `deps.dart` 总桶，属于迁移遗留，待清理。
- 全量 `flutter test`（约 937 条）在 #261e 合入后全绿。

## 2. 最近提交（dev）

| commit | 内容 |
|--------|------|
| `4d6c8be4` | #261e：library_browse 切换至 shared 状态与端口 Provider |
| `dc8971da` | #261d：`library_management_actions` → shared/ui；扫描与返回系列端口化 |
| `c2897e27` | #261c：toast → shared/ui；批量编辑命令端口 |
| `12ba146a` | #261b：`libraries_routes` → shared/core；`library_form_dialog` → shared/ui |
| `774f8a50` | #261a：状态类型迁 shared/domain；shared/di 声明 + bootstrap override |
| `679ae8d4` | docs：新增本交接文档 |
| `d93543f2` | Gate 新增 M3 ratchet |
| `eb9d1213` | #266 步骤0：三端口 + library_admin 适配器 |
| `d478cbad` | #258 bootstrap-final |

## 3. Issue 状态

**已关闭**：#258、#219、#220、#221、#222、#224、#225、#266、**#261**、**#262**、**#263**、**#264**、**#265**、**#267**、**#268**。

**未关闭**：

- #217（路线图，DoD "基线为空" 未达成）
- #256（延后，不实施；见 §9）
- #260（spec：消除 feature↔feature 边）
  - 注意：正文中 "R6 零容忍" 已被留言改为 M3 ratchet，正文尚未同步修改，下次更新时应改正文。
  - 正文中 R1 扩展（禁止 feature domain→本 feature data）**尚未在 Gate 中实现**。

## 4. 已做出的决策（不要重新讨论）

来自 `grilling` 两轮（#260 spec）及 #261 实施过程确认：

1. #260 完成标准：feature↔feature M1/M2 基线清零，基线改为空集。
2. Gate R1 扩展：禁止任何 feature 的 `domain/` 依赖本 feature 的 `data/`；`metadata_backup/domain/metadata_auto_backup_logic.dart` 的现有边纳入修复。
3. 跨 feature 共享状态端口化（见 §5）。
4. `library_management_actions` → **shared/ui**，业务动作走端口（不放 bootstrap，因 R6/M3）。
5. 交付顺序：步骤0 (#266) → library_browse (#261，**已完成**) → home(#262) → comic_trash(#263) → app_settings(#264) → read_session(#265)。
6. **R6 不做零容忍，改为 ratchet（规则 ID M3）**。product feature 导入 `features/bootstrap/`（主要是 `deps.dart` 总桶）计入基线，只能减少。
7. toast 组件 → **shared/ui**；批量编辑经命令端口（见下），不是直接改用无状态的 `ComicMetadataBulkPatchPort`。
8. 表单对话框 `library_form_dialog.dart` → **shared/ui**；路由常量 `libraries_routes.dart` → **shared/core**。
9. **状态 Provider 形态（#261a）**：notifier 留在 library_admin；shared/di 声明只读/端口 Provider（默认 `UnimplementedError`）；bootstrap 用 `overrideWith(ref => ref.watch(library_admin 的 provider))` 桥接。不要把 notifier 类迁到 shared。
10. **命令端口扩展（#261b–d）**：在 `CurrentLibraryPort` 上增加 `submitLibraryForm`；新增 `ComicMetadataBulkEditCommandPort`、`LibraryScanCommandPort`、`ComicDetailReturnSeriesPort`（保留 controller 的 running/互斥/备份/revision 行为，由适配器委托）。
11. **#256 不与当前消费方路线合并**（见 §9）。

## 5. #261 已完成形态（供后续票复用）

### 关键路径

| 角色 | 路径 |
|------|------|
| 状态类型 | `shared/domain/library/current_library_state.dart`、`library_revision_state.dart` |
| Provider 声明（默认抛错） | `shared/di/library_state_providers.dart` |
| 端口接口 | `shared/domain/library/*_port.dart`、`comic_detail_return_series_port.dart`、`library_scan_command_port.dart`、`comic_metadata_bulk_edit_command_port.dart` |
| library_admin 适配器工厂 | `features/library_admin/di/shared_state_ports.dart`（仅工厂，无 Provider 声明） |
| library_browse 适配器 | `features/library_browse/di/comic_detail_return_series_ports.dart` |
| bootstrap 注入 | `features/bootstrap/di/shared_state_overrides.dart` → `main.dart` 的 `MyApp(overrides: sharedLibraryStateOverrides())` |
| 共享 UI | `shared/ui/widgets/navigation/library_management_actions.dart`、`shared/ui/widgets/overlays/dialog/library_form_dialog.dart`、`shared/ui/widgets/feedback/*_toasts.dart` |
| 路由常量 | `shared/core/constants/libraries_routes.dart` |

### shared/di 中已声明的 Provider（消费方应改用这些，不要再 import library_admin）

- 端口：`currentLibraryPortProvider`、`libraryReorderModePortProvider`、`libraryRevisionSignalPortProvider`、`comicMetadataBulkEditCommandPortProvider`、`libraryScanCommandPortProvider`、`comicDetailReturnSeriesPortProvider`
- 状态：`currentLibraryStateProvider`、`libraryRevisionStateProvider`、`libraryRevisionThrottleBusyStateProvider`、`seriesByIdStateProvider`

### 测试惯例

- 单元/widget 测试若依赖上述 shared Provider，在 `ProviderContainer`/`ProviderScope` 的 overrides 中加入 `...sharedLibraryStateOverrides()`（可与具体 fake notifier override 并存；fake 写在前，bridge 写在后亦可，因 bridge 是 watch 委托）。
- 若同一同步段内连续两次 `notifyExternalChange()`，bridge 可能合并通知；测试中在两次 bump 之间 `read` 一次相关 Provider，使 listener 逐次观察（见 `library_catalog_revision_coordinator_test.dart`）。业务语义不变。

### #261 遗留（非阻塞下一票，但需知情）

- library_browse **仍有约 18 个文件**直接 import `features/bootstrap/di/deps.dart`（M3 主要来源）。涉及 named_metadata、repos 等，需随 deps 拆分处理，不必阻塞 #262。
- library_browse 残留 M1/M2（各 6 条）指向 **comic_trash / metadata_backup / named_metadata**，不是 library_admin；属其他消费方或后续票。
- 原 notifier 文件仍 `export` 状态类型以兼容旧导入；消费方票切换后可择机删 re-export。

## 6. 已知风险与待办

- R1 扩展（feature domain→本 feature data）未实现，`metadata_auto_backup_logic.dart` 仍违规。
- `deps.dart` 总桶仍是 M3 的主要来源。消费方票应**顺带**把本 feature 的依赖拆到 feature di / shared/di（能减则减，不要求一张票清光）。
- `CurrentLibraryPort` 适配器没有独立测试（依赖仓储）。
- `unnecessary_import` info：可在 deps 拆分的同一 PR 中一并清理。
- 历史文档（ADR、research、`docs/wayfinder/source-ownership-matrix.md` 早期 slice 记录）中仍保留旧路径，这是有意保留，不要批量替换。

## 7. 常用命令与坑

```text
# 生成基线（修改 import 规则后必须执行）
cd app && dart run tool/generate_import_boundary_baseline.dart

# Gate + 布局
cd app && flutter test test/gate test/project_layout_test.dart

# 分析
cd app && dart analyze

# l10n（输出目录 lib/shared/core/l10n）
cd app && flutter gen-l10n

# 推送
git -c http.version=HTTP/1.1 push origin dev
```

- `gh` 偶发 `Post https://api.github.com/graphql: EOF`，重试即可。
- 自动审查可能拦截 `git push` 与 `gh issue close`，需要用户批准。
- 注释、commit message、回复一律使用简体中文。
- 仓库规则：`Read` 工具若被 hook 拦截，不要绕过，先报告；由用户处理 hook 后再继续。
- 测试路径：`features/*/presentation/` 下的测试应放在 `app/test/features/<id>/...`，共享测试在 `app/test/shared/...`。
- 每张消费方子票完成后：在对应 GitHub issue 留言并记录基线数量变化；全部子工作完成后关闭该消费方票。

## 8. 下一步（下一对话从这里开始）

1. ~~实现 #262（home）~~：**已完成并关闭**。home 的 M1/M2 边已清零。
   - 新增 shared Provider：`libraryComicAgeRestrictionStateProvider`、`libraryScanRunningStateProvider`（`shared/di/library_state_providers.dart`，由 bootstrap 的 `shared_state_overrides.dart` 注入）。
   - `visibleCatalogGridIndexRange` 迁至 `shared/ui/layout/catalog_grid_visible_range.dart`。
   - 涉及 home / 应用壳的测试统一接入 `sharedLibraryStateOverrides()`。
   - 待办：在 #262 留言并关闭；home 仍有 M3（`deps.dart`）边，可随后续票顺手拆。
   - #264（app_settings）：**已完成并关闭**。设置页备份板块改由 bootstrap 经 `shared/di/settings_slot_providers.dart` 的 slot 组装；板块实现迁至 `features/metadata_backup/presentation/views/metadata_backup_settings_detail.dart`；设置原语与布局常量下沉至 `shared/ui/widgets/settings/`；最近备份时间读取迁至 `features/metadata_backup/data/recent_metadata_backup_at.dart`。app_settings 仍有 1 条 M1（`settings_notifier.dart` → read_session `auto_play_mode`），留待 #265 一并处理。
   - #263（comic_trash）：**已完成并关闭**。library_admin 边清零；新增 `libraryMutationBusyStateProvider`、复用 `libraryRevisionSignalPortProvider` / `libraryRevisionStateProvider`。comic_trash 仍对 home 的 `history_layout_constants` / `history_page_header` 有 M1/M2（4 条），属 home 视图共享，可在后续票处理。
   - #265（read_session）：**已完成并关闭**。`AutoPlayMode` 下沉至 `shared/domain/reading/`；新增 `ReaderSettingsCommandPort` 与 `appSettingsStateProvider` / `appSettingsFutureProvider`（适配器在 `features/app_settings/di/shared_state_ports.dart`）；`series_reader_provider` 删除冗余的 library_browse import。read_session 与 app_settings 的 M1/M2 已清零。
   - #267（library_admin）：**已完成并关闭**。新增 shared 端口 `CatalogSelectionCommandPort` / `DictionaryInvalidationPort` / `MetadataSavedPort`，声明于 `shared/di/library_command_providers.dart`；适配器分别位于 `features/library_browse/di/`、`features/bootstrap/di/`（组合根，失效 named_metadata 与 library_browse 字典 Provider）、`features/metadata_backup/di/`，由 `sharedLibraryStateOverrides()` 注入。library_admin 的 M1/M2 已清零；返回系列清理改走 shared 的 `comicDetailReturnSeriesPortProvider`。
   - #268（library_browse）：**已完成并关闭**。采用**事件 revision 驱动**（C 方案）：新增 `shared/domain/library/library_change.dart`（`LibraryChange`）与 `shared/di/library_change_bus.dart`（`libraryChangeBusProvider`，状态为 `dictionaryRevision` + `metadataSaveRevision`）。写入方只 `publish` 发生了什么；named_metadata 的 `allTags/allAuthors/allParodies/allCharacters` 与 library_browse 的 distinct 字典 Provider 自行 `watch` 字典 revision；metadata_backup 协调器自行 `listen` 保存 revision 并调度备份。filter 抽屉改读 `shared/di/library_dictionary_providers.dart` 的只读 Provider（bootstrap 桥接）；删除入口经 `ComicTrashCommandPort`（生产适配器位于 `comic_trash/di`）。**回收 #267 的 `MetadataSavedPort` 与 `DictionaryInvalidationPort`**（已被事件总线取代，适配器一并删除）。基线 91 → 79。
2. **剩余 4 条 M1/M2**：comic_trash→home（`history_layout_constants` / `history_page_header`），暂未建票，需另行决定。
3. 消费方票推进时顺手减少本 feature 对 `deps.dart` 的 M3 边。
4. 全部消费方完成后：实现 R1 扩展，并更新 #260 正文（R6 → M3 ratchet）。
5. 全部完成后才能关闭 #260 与 #217（基线为空）。

### #262 开工前建议盘点

```text
# home 当前指向谁
cd app && grep -E '"M[12]\|home\|' test/gate/import_boundary_baseline.json

# home 源码里用到的 library_admin / shared 符号
cd app && grep -rn "library_admin\|currentLibrary\|libraryRevision\|LibraryManagement" lib/features/home --include='*.dart'
```

套用 `docs/wayfinder/migration-slice-checklist-template.md`；每步后跑 analyze + gate；改 import 规则后重生成基线。

## 9. 与 #256 的关系（评估结论，勿合并）

#256「按 feature 划分 Repository / FRB data 层」**延后、不实施**，且**不要与 #260 消费方路线合并**：

| | #260 / #261–#265 | #256 |
|--|------------------|------|
| 层 | presentation / 共享状态端口 / DI override | data / FRB adapter / repository 物理归属 |
| 目标 | M1/M2 基线清零 | `shared/data` 按 owner 回迁到 `features/*/data` |
| 时机 | 正在做 | bootstrap 已完成后的后续 epic |

当前端口骨架是 #256 将来回迁时的稳定外壳：adapter 搬家时消费方继续依赖 shared 端口即可。等 #262–#265 完成后再单独开 #256（建议首迁 library_admin 的 sync/refresh/bulk patch adapter）。
