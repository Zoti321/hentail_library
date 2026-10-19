# Wayfinder migration slice 验收清单（模板）

**版本**：2026-10-16（#225）  
**用法**：复制本节到各 slice 实施 GitHub issue / PR 描述，将 `<SLICE>`、`<FEATURE_ID>` 替换为实际值；勾选完成项。

**Slice 顺序**（#218）：`app_settings` → `named_metadata` → `metadata_backup` → `read_session` → `library_browse` → `comic_trash` → `home` → `library_admin` → `bootstrap`（收尾）

---

## A. Slice 元数据

| 字段 | 填写 |
|------|------|
| Slice 名称 | `<SLICE>`（如 `app_settings`） |
| 目标 feature id | `features/<FEATURE_ID>/` |
| 矩阵章节 | `docs/wayfinder/source-ownership-matrix.md` §___ |
| 依赖 spec | #219 #220 #221 #222 #224 |
| 预估 PR 数 | ___（建议 1–3，单 PR 保持 Gate 绿） |

---

## B. 搬迁完成（源码）

- [ ] `docs/wayfinder/source-ownership-matrix.md` 中本 slice 所有行已迁到目标 URI（或明确推迟并开 follow-up issue）
- [ ] 本 slice 范围内 **无新增** 非 shim 文件留在 legacy 根（`ui/features/{shell,library,...}`、顶层 `domain/data/core`）— #219
- [ ] 本 slice 涉及文件的 import 已改为 **canonical URI**（`features/...`、`shared/...`）
- [ ] 本 slice 引入的 strangler shim 已列入 **§F** 且计划在 slice 关闭前删除
- [ ] 本 slice **结束前** 已删除本 slice 拥有的全部 shim（零残留）
- [ ] 生成代码（`*.g.dart` / `*.freezed.dart`）已随源文件移动并重新 `build_runner`

---

## C. Gate（合并前必绿）

本地与 CI 同源：

```bash
./scripts/run-gate.sh          # 或至少 run-gate.sh dart-test + gate-rust-test
```

- [ ] `gate-rust-test` 通过（若 slice 未动 Rust，仍须绿）
- [ ] `gate-dart-test` 通过（`app/test/gate/manifest.txt` 清单内测试）
- [ ] **无** 新增 `flutter analyze` 错误（若项目常规跑 analyze）
- [ ] FRB：若动 `shared/data` 或 API，`cargo build -p hentai_flutter` 与 codegen 无漂移（Gate 拓扑）

---

## D. Import 与布局测试（#220 / #219）

- [ ] **R1–R5（L1）**：本 PR 未新增 domain→data、非白名单 FRB、feature 层 FRB、library_browse→read_session 等结构性违规
- [ ] **M1/M2 baseline**（`app/test/gate/import_boundary_baseline.json`）：违规签名 **只减不增**；若修复耦合，已提交 baseline 缩减 diff
- [ ] **禁止** 新增 import `package:hentai_library/ui/providers.dart`（#222）
- [ ] 目标态：本 slice 的 feature `presentation` **未新增** 对 `features/bootstrap/di/deps.dart` 的 import（若暂不可避免，须在 PR 说明并 baseline 不恶化）
- [ ] `app/test/project_layout_test.dart`：若本 slice 改变 `lib/` 顶层或 `features/*` 子目录，已更新 Phase A 断言
- [ ] ADR-0017：`views/` 与 `shared/ui/widgets`（或迁移前 `ui/core/widgets`）仍无 `*RepoProvider`

---

## E. 测试路径镜像

- [ ] `app/test` 下引用已搬迁类型的测试，import 路径已更新
- [ ] 若测试文件随 feature 移动：已加入 **`app/test/gate/manifest.txt`**（扩 Gate 唯一入口 — `docs/agents/testing.md`）
- [ ] 若仅改 import、未移测试文件：manifest **无需** 变更
- [ ] 已跑：`cd app && flutter test test/gate/import_boundary_test.dart`（若已合并 #220）
- [ ] 已跑：与本 slice 相关的原路径测试（如 `test/ui/features/settings/**` → 新路径）

**Manifest 变更记录**（无则写「无」）：

```
# 示例
test/features/app_settings/...
```

---

## F. Strangler shim 清单（本 slice）

文件：`app/test/gate/strangler_shims.txt`（首 slice 引入时创建；每行一个 legacy 路径，相对 `app/lib/`）

| Legacy shim 路径 | 指向 canonical URI | 删除 PR |
|------------------|-------------------|---------|
| | | |

- [ ] 所有本 slice 新增 shim 已写入上表 + `strangler_shims.txt`
- [ ] `project_layout_test`（或 gate shim 测试）已校验：未列出的 shim 不存在
- [ ] Slice 关闭时上表为空、shim 文件已删

---

## G. DI / shared（若本 slice 触及 #222）

- [ ] 新 Provider 定义在正确层：`shared/di` vs `features/<id>/di` vs `bootstrap/di`
- [ ] 未在 `shared/di` 引入对 feature `presentation` 的 import
- [ ] #221：feature `domain` 无 `shared/data` / `src/rust` import；coordinator 仅依赖 port

---

## H. 文档

- [ ] `docs/wayfinder/source-ownership-matrix.md` 版本表已更新（日期 + 一句说明）
- [ ] 若本 slice 改变 agent 可见路径：**暂不** 要求改 `coding-style.md` / `ui-style.md`（**bootstrap 收尾** 统一改）
- [ ] PR 描述列出：矩阵 §、manifest 变更、baseline 变更、shim 增删

---

## I. Slice 关闭定义（DoD）

在勾选以下全部后，在父 issue #217 或 Wayfinder 看板将本 slice 标为 **done**：

- [ ] §B–§H 全部适用项已完成
- [ ] 本 slice 相关 open issue 已关闭或显式 defer
- [ ] 无本 slice 名下的未删除 strangler shim
- [ ] `import_boundary_baseline.json` 中与本 slice 目标相关的边已减少（或 PR 说明为何暂不能减）

---

## J. 按 slice 的附加项（勾选适用）

### `app_settings`

- [ ] `core/app_data/app_data_wipe_flow` → `features/app_settings/domain`
- [ ] `data/services/app_update` → feature `data`
- [ ] `ui/features/settings/**` → `features/app_settings/presentation/**`

### `named_metadata`

- [ ] `ui/features/metadata/**` → `features/named_metadata/presentation/**`
- [ ] tag dictionary 服务 → `features/named_metadata/data`

### `metadata_backup`

- [ ] `core/metadata/**` → `features/metadata_backup/domain|data`
- [ ] 与 settings 行 UI 的 provider 边界符合矩阵 §9 ⚠️ 决策

### `read_session`

- [ ] `ui/features/reader/**` → `features/read_session/presentation/**`
- [ ] `reader/module/controller` → `view_models`（若本 slice 做 ADR-0017 阶段二）
- [ ] `read_session` di 从 shell `services.dart` 拆出

### `library_browse`

- [ ] `ui/features/library/**` → `features/library_browse/presentation/**`（最大 slice，可分子 PR）
- [ ] Author 共享 UI 若未迁 `shared/ui`，不得标 slice done（矩阵 §5）

### `comic_trash`

- [ ] shell `trash_*` → `features/comic_trash/**`
- [ ] `comic_trash_service` → feature `domain`

### `home`

- [ ] shell `home_*` / `history_*` → `features/home/**`

### `library_admin`

- [ ] shell navigation / sync / refresh / bulk patch → `library_admin`
- [ ] 三 coordinator **端口化**完成（#221 / #220 R1）若尚未在早先 PR 完成
- [ ] `shared/di/adapters` + `library_admin/di` 接线

### `bootstrap`（收尾）

- [ ] 顶层 `lib/` 仅 `{features, shared, src}` + `main.dart`（#219 Phase B）
- [ ] 删除 `ui/`、`domain/`、`data/`、`core/` legacy 根及 **全部** shim
- [ ] 删除 `ui/providers.dart`；`import_boundary_baseline.json` **为空**
- [ ] 更新 `docs/agents/coding-style.md`、`docs/agents/ui-style.md` 路径表
- [ ] `strangler_shims.txt` 删除或仅留空文件+测试断言零行

---

## K. PR 描述粘贴块（模板）

```markdown
## Wayfinder slice: <SLICE>

- Matrix: docs/wayfinder/source-ownership-matrix.md §___
- Gate: ./scripts/run-gate.sh
- Manifest: [无 | 见 manifest.txt]
- Import baseline: [无变化 | 减少 N 条]
- Strangler shims: [无 | 新增 N，已全删 | 见 strangler_shims.txt]
- Follow-ups: [无 | #___]
```
