# Wayfinder 交接文档（整洁架构迁移）

最后更新：2026-10-17（#217 / #271–#278 已关；**下一主线 #256**）。分支：`dev`。

## 1. 当前状态概览

- `app/lib` 已收敛为 `features/<id>/{presentation,domain,data,di}`、`shared/{core,data,domain,ui,di}`、`src/rust`、`main.dart`。
- Phase B 布局校验已启用（`kEnforceWayfinderPhaseBLayout = true`），strangler 白名单为空。
- Gate 基线：`app/test/gate/import_boundary_baseline.json` 共 **0** 条（M1/M2 与 M3 ratchet 均已清零）。
- 仓储与端口：**接口**在 `shared/domain`；**Provider 声明**在 `shared/di/data_providers.dart`；**实现绑定**在 `features/bootstrap/di/data_overrides.dart`（#278）。
- `dart analyze`：0 error；仍有若干 `annotate_overrides` info（既有）。
- 全量 `flutter test`：**941** 条全绿。

## 2. 最近里程碑（dev）

| 阶段 | 内容 |
|------|------|
| #278 + #271–#277 | M3 product→bootstrap 清零（`24a46e5b`） |
| #261–#270 | 消费方 M1/M2 与状态/端口骨架 |
| #266 | 步骤 0：三端口 + library_admin 适配器 |

## 3. Issue 状态

**已关闭**：#217、#258、#219–#225、#266、#261–#268、#270、#271–#278。

**进行中 / 待收尾**：

| Issue | 角色 |
|-------|------|
| **#256** | **下一主线**：`shared/data` 按 feature owner 回迁（见 §8、§9） |
| #260 | spec 收尾：Gate **R1 扩展**、正文「R6→M3」同步（可与 #256 并行，不合并票） |

## 4. 已做出的决策（不要重新讨论）

来自 `grilling` 两轮（#260 spec）及 #261–#278 实施过程：

1. #260 消费方路线完成标准：feature↔feature M1/M2 与 M3 ratchet **基线均为空**（已达成）。
2. Gate R1 扩展（待实现）：禁止 feature `domain/` 依赖本 feature `data/`；`metadata_backup/domain/metadata_auto_backup_logic.dart` 纳入修复。
3. 跨 feature 共享状态：**端口 + shared/di 声明 + bootstrap override**（见 §5）。
4. **R6 → M3 ratchet**：product feature 不得新增对 `features/bootstrap/` 的 import；基线只减不增。
5. **#256 与 #260 消费方路线分轨**：#256 只动 **data / FRB adapter / repository 实现物理路径**；不改 presentation 依赖方向；不撤销 shared 仓储**接口**。
6. 状态 Provider：notifier 留在 owner feature；shared/di 只声明只读/端口 Provider；bootstrap `overrideWith` 桥接（#261a）。
7. **#256 回迁时**：presentation / domain 继续依赖 `shared/domain/repositories` 与 `shared/domain/ports`；仅 `shared/data/**` 实现类迁到 `features/<owner>/data/**`；`data_overrides()` 改为引用新路径。

## 5. #261 已完成形态（#256 仍沿用）

### 关键路径

| 角色 | 路径 |
|------|------|
| 仓储/端口接口 | `shared/domain/repositories/`、`shared/domain/ports/` |
| Provider 声明 | `shared/di/data_providers.dart`、`shared/di/library_state_providers.dart` 等 |
| 实现绑定（组合根） | `features/bootstrap/di/data_overrides.dart`、`shared_state_overrides.dart` |
| library_admin 状态适配器 | `features/library_admin/di/shared_state_ports.dart` |

### 测试惯例

- 依赖真实仓储的测试：`...dataProviderOverrides()` + 按需 `sharedLibraryStateOverrides()`。
- 改 data 路径后跑 `flutter test test/gate` 与受影响 feature 测试。

## 6. 已知风险与待办

- **R1 扩展**未落地（#260 剩余）。
- `features/bootstrap/di/deps.dart` 仍为**便利 export 桶**（非 Gate 违规）；可随 #256 slice 顺手删未使用 export，非必须一次清完。
- `CurrentLibraryPort` 等适配器缺少独立单测。
- 历史 ADR / `docs/wayfinder/source-ownership-matrix.md` 中旧路径有意保留，slice 完成后再改矩阵对应行。

## 7. 常用命令与坑

```text
# 生成基线（改 import 规则后）
cd app && dart run tool/generate_import_boundary_baseline.dart

# Gate + 布局
cd app && flutter test test/gate test/project_layout_test.dart

# 分析
cd app && dart analyze

# 推送
git -c http.version=HTTP/1.1 push origin dev
```

- `gh` 偶发 GraphQL 超时，重试或短暂等待代理稳定。
- 注释、commit message、回复使用简体中文。
- #256 子 slice 完成后在 **#256** 留言并链 PR；大 slice 可开子 issue。

## 8. 下一步（下一对话从这里开始）

### 0. 主线：推进 #256 路线图

**Epic**：将 `app/lib/shared/data/**` 的实现按 **feature owner** 迁入 `features/<id>/data/`（Repository 实现、FRB adapter、feature 专属 mapper）。

**不动**：

- `shared/domain/**` 接口与领域类型
- `shared/di/data_providers.dart` 的 Provider **声明**（仍由 bootstrap override 注入）
- presentation 层 import 边界（M3 已清零，勿引入 feature→bootstrap）

**动**：

- 物理文件路径与 `data_overrides.dart` / 各 feature `di/` 中的绑定 import
- 必要时在 owner feature 增加 `data/` 子目录与 barrel export

### 建议 slice 顺序（在 #256 下拆票或 checklist）

| 顺序 | Owner | 候选文件（`shared/data` 今日位置） | 说明 |
|------|--------|-----------------------------------|------|
| 1 | `library_admin` | `adapters/sync_library_frb_adapter.dart`、`metadata_refresh_frb_adapter.dart`、`comic_metadata_bulk_patch_frb_adapter.dart` | 与扫描/刷新/批量元数据域一致；handoff 原建议首 slice |
| 2 | `metadata_backup` | `adapters/metadata_backup_frb_adapter.dart`、`metadata_backup_frb_types.dart` | 与自动备份域一致 |
| 3 | `read_session` | `adapters/reader_session_frb_adapter.dart`、`reader_frb_mapper.dart`；`comic_page_source_frb_adapter.dart` 需确认 owner | 阅读 I/O 与 FRB session |
| 4 | 按矩阵迁 repository impl | `repositories/*_impl.dart` 及共用 mapper | 多 feature 共用的 comic/series/library 等先对照 `source-ownership-matrix.md` 定唯一 owner 或保留 `shared/data` 最小内核 |

每 slice 套用 `docs/wayfinder/migration-slice-checklist-template.md`：`dart analyze`、`flutter test`（gate + 相关 feature）、必要时 FRB/codegen 无漂移。

### #256 开工前盘点

```text
# shared/data 全量清单
cd app && find lib/shared/data -name '*.dart' | sort

# 组合根当前绑了哪些实现
cd app && sed -n '1,80p' lib/features/bootstrap/di/data_overrides.dart

# 某 adapter 被谁引用
cd app && rg -l sync_library_frb_adapter lib
```

### 并行（不阻塞 #256）

1. **#260**：实现 Gate R1 扩展；更新 issue 正文（R6 → M3 ratchet）。
2. **`deps.dart` 瘦身**：删除已无引用的 export（纯清理）。

### 已完成（勿重开）

- #217 路线图（ratchet 基线为空）
- #261–#278 消费方与 M3 实施票

## 9. 与 #260 消费方路线的边界（#256 实施时遵守）

| | #260 / #261–#278（已结束） | #256（进行中） |
|--|---------------------------|----------------|
| 层 | presentation、shared 状态端口、DI override | `shared/data` → `features/*/data` |
| Gate | M1/M2/M3 ratchet | 不新增 product→bootstrap；data 回迁不触发 M1/M2 若 domain 仍只依赖 shared 接口 |
| 依赖方向 | 消费方 → shared 端口 | 实现类靠近 owner；**接口不搬家** |

当前 **shared 端口 + `data_providers` 声明** 是 #256 的稳定外壳：adapter 搬家时，除 `data_overrides` 与 owner `di` 外，presentation 不应改为 import 具体 `*_impl.dart`。

#256 与 #260 **不要合并为一张实施票**；#260 剩余 R1 可在单独 PR 完成。
