# Wayfinder 交接文档（整洁架构迁移）

最后更新：2026-10-17。分支：`dev`。远端：`origin dev`。

## 1. 当前状态概览

- `app/lib` 已收敛为 `features/<id>/{presentation,domain,data,di}`、`shared/{core,data,domain,ui,di}`、`src/rust`、`main.dart`。
- Phase B 布局校验已启用（`kEnforceWayfinderPhaseBLayout = true`），strangler 白名单为空。
- Gate 基线：`app/test/gate/import_boundary_baseline.json` 共 **212** 条 = **135** 条 M1/M2（feature↔feature） + **77** 条 M3（product feature→bootstrap）。
- `dart analyze`：0 error；74 条 `unnecessary_import` info，来自 `deps.dart` 总桶，属于迁移遗留，待清理。

## 2. 最近提交（dev）

| commit | 内容 |
|--------|------|
| `d478cbad` | #258 bootstrap-final：legacy 整树迁入 `shared/*`，删除 `ui/providers.dart`，Phase B 启用，l10n 输出目录修正，nightly 测试路径修正 |
| `eb9d1213` | #266 步骤0：`CurrentLibraryPort`、`LibraryReorderModePort`、`LibraryRevisionSignalPort` + library_admin 适配器 |
| `d93543f2` | Gate 新增 M3 ratchet（product feature 导入 `features/bootstrap/` 记入基线） |

## 3. Issue 状态

**已关闭**：#258、#219、#220、#221、#222、#224、#225、#266。

**未关闭**：

- #217（路线图，DoD "基线为空" 未达成）
- #256（延后，不实施）
- #260（spec：消除 feature↔feature 边）
  - 注意：正文中 "R6 零容忍" 已被留言改为 M3 ratchet，正文尚未同步修改，下次更新时应改正文。
  - 正文中 R1 扩展（禁止 feature domain→本 feature data）**尚未在 Gate 中实现**。
- #261–#265（library_browse / home / comic_trash / app_settings / read_session 消费方票，均依赖 #266）
- #261 已在评论中记录拆分方案（见 §5）。

## 4. 已做出的决策（不要重新讨论）

来自 `grilling` 两轮（#260 spec）及后续确认：

1. #260 完成标准：feature↔feature M1/M2 基线清零，基线改为空集。
2. Gate R1 扩展：禁止任何 feature 的 `domain/` 依赖本 feature 的 `data/`；`metadata_backup/domain/metadata_auto_backup_logic.dart` 的现有边纳入修复。
3. 跨 feature 共享状态端口化（三个端口，见 §5）。
4. `library_management_actions` 拆分：业务动作走端口；对话框与路由跳转随 §5 的决定迁移。
5. 交付顺序：步骤0 端口 (#266，已完成) → library_browse(26) → home(7) → comic_trash(5) → app_settings(9+2) → read_session(剩余)。
6. **R6 不做零容忍，改为 ratchet（规则 ID M3）**。product feature 导入 `features/bootstrap/`（主要是 `deps.dart` 总桶）计入基线，只能减少。
7. #261 中 widget/toast 归宿：
   - 导航 widget 放 **shared/ui**，经 `CurrentLibraryPort` 执行动作（不放 bootstrap，因为 R6/M3）。
   - 批量编辑 controller 走 shared/domain 已有 `comic_metadata_bulk_patch_port`，toast 组件放 shared/ui。
8. 表单对话框 `library_form_dialog.dart`（880 行）→ **shared/ui**；路由常量 `libraries_routes.dart` → **shared/core**。

## 5. #261 拆分（已记录到 #261 评论）

- **261a**：`CurrentLibraryState`、`LibraryRevisionState` 迁到 shared/domain；在 shared/di 声明状态 Provider 与端口 Provider（默认 `throw UnimplementedError`），由 bootstrap `ProviderScope(overrides: ...)`（`features/bootstrap/presentation/views/app.dart` 已支持 overrides）注入 library_admin 实现。注意：`libraryRevisionThrottleBusyProvider`、`seriesByIdProvider` 也需要处理。
- **261b**：`libraries_routes.dart` → shared/core；`library_form_dialog.dart` → shared/ui，并把它对 `features/bootstrap/di/deps.dart` 的依赖收敛到 shared。
- **261c**：`metadata_refresh_toasts.dart`、`comic_metadata_bulk_patch_toasts.dart` → shared/ui；批量编辑走 `comic_metadata_bulk_patch_port`。
- **261d**：`library_management_actions.dart` → shared/ui，经端口调用。它目前还依赖 `scanLibraryControllerProvider` 与 `comicDetailReturnSeriesProvider`，需要一并端口化或迁移。
- **261e**：library_browse 源文件（约 26 条 M1/M2 边，外加若干 M3 边）与相关测试（约 21 个测试文件引用这些 Provider）的导入/override 切换；基线同步减少。

### library_browse 中实际使用的 library_admin 符号（已盘点）

- `currentLibraryProvider`（读 `AsyncValue<CurrentLibraryState>`，`.select` 多处）、`CurrentLibraryState`
- `libraryRevisionProvider`（`.select((LibraryRevisionState s) => s.revision)`，`ref.listen`，`notifyExternalChange`）、`LibraryRevisionState`
- `libraryRevisionThrottleBusyProvider`、`isLibraryRevisionThrottleBusy`
- `seriesByIdProvider`（`series_detail_page.dart`、`comic_detail_series_nav_provider.dart`）
- `libraryReorderModeProvider`（`catalog_selection_notifier.dart` 调用 `.exit()`）
- `LibraryManagementActions`（`goCurrentLibraryBrowseFromContext`、`addLocalLibrary`、`addRemoteLibrary`）
- `showMetadataRefreshBatchToast`、`showComicMetadataBulkPatchToast`、`comicMetadataBulkPatchControllerProvider`

## 6. 已知风险与待办（非 #261 范围）

- R1 扩展（feature domain→本 feature data）未实现，`metadata_auto_backup_logic.dart` 仍违规。
- `deps.dart` 总桶仍是 M3 的主要来源（46 个文件导入 deps）。消费方票应顺带把本 feature 的依赖拆到 feature di / shared/di。
- `library_management_actions.dart` 通过 `deps.dart` 间接依赖多个 library_admin 符号。
- `features/library_admin/di/shared_state_ports.dart` 目前同时含适配器和 Provider 声明。261a 应把 Provider 声明移到 shared/di，只保留适配器工厂，供 bootstrap override 使用。
- `test/features/library_admin/di/shared_state_ports_test.dart` 依赖当前 Provider 声明，261a 迁移时需要同步修改。
- `CurrentLibraryPort` 适配器没有独立测试（依赖仓储）。
- 74 条 `unnecessary_import` info：可在 deps 拆分的同一 PR 中一并清理。
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
- 仓库规则：`Read` 工具对 `docs/agents/ui-style.md` 曾被 hook 拦截，后已恢复；如再遇到，不要绕过，先报告。
- 测试 import 规则：`features/*/presentation/` 下的测试应放在 `app/test/features/<id>/...`，共享测试在 `app/test/shared/...`。

## 8. 下一步

1. 实现 **261a**（状态类型迁移 + shared/di Provider 声明 + bootstrap override + 测试调整）。
2. 依次完成 261b → 261e，每张套用 `docs/wayfinder/migration-slice-checklist-template.md`。
3. 完成 261e 后，library_browse 的 M1/M2 与对应 M3 边应减少；记录新的基线数量。
4. 之后按顺序推进 #262（home）、#263（comic_trash）、#264（app_settings）、#265（read_session）。
5. 最后实现 R1 扩展，并更新 #260 正文（R6 → M3 ratchet）。
6. 全部完成后才能关闭 #260 与 #217（基线为空）。
