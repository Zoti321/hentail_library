# ADR-0030: MD3E Lab 阶段冻结 design-system 文档为归档

## Status

Accepted

## Context

`design-system/hentai-library/`（含 `MASTER.md`、`pages/*` 与 Figma 对齐帧说明）与 ADR-0029 曾作为 Agent 与贡献者的 **UI 规范入口**。`integrate/md3e` 分支上，漫画库等壳层在 **MD3E Lab**（`app/lib/md3e/`）快速迭代：粘滞页头、分页、目录 Tabs/数量布局等与 MASTER §5.1 书库页头已明显分叉。

维护双轨（Figma / MASTER 长文 ↔ Widgetbook 真组件）成本高，且 Figma 稿滞后于 Lab 代码。`material_3_expressive` 包与官方文档已覆盖 M3E 组件语义；Lab 验收以 **Widgetbook** 为准更可靠。

生产路由仍主要使用 `app/lib/shared/ui/`（ADR-0027、ADR-0028），尚未整体迁移到 MD3E；冻结文档 **不** 改变生产 theme/widgets 的真源地位。

## Decision

1. **MD3E Lab 活跃开发期**（至单独 ADR 宣布生产视觉迁移完成或解冻文档为止）：
   - **不** 将 `design-system/hentai-library/` 作为 Lab UI 的规范真源；**不** 要求 Lab PR 同步更新 MASTER / `pages/*` / Figma 帧。
   - Lab UI 规范来源：**`app/lib/md3e/`** 实现 + **`app/widgetbook/`** 用例（Viewport / Theme / Knobs addons）+ **`material_3_expressive`** 官方文档。
   - `design-system/` 目录 **保留在仓库内**，视为 **只读归档**（历史决策、旧帧、research 底稿）；可查阅，不作为 merge 门禁。

2. **生产 Flutter UI**（`features/*` 使用 `shared/ui`）：
   - 可执行真源仍为 **`app/lib/shared/ui/theme/`** 与 **`shared/ui/widgets/`**（ADR-0028）。
   - 大改生产视觉时，可解冻 `design-system/` 或写新 ADR 明确新的文档真源；在此之前 Agent 仍以代码 + ADR-0027/0028 为准，而非过期 MASTER 段落。

3. **ADR-0029** 仍有效于目录 **三重角色定义** 与 ui-ux-pro-max `--persist` 治理；本 ADR **取代** 其在「MD3E Lab 日常开发中 MASTER 为 Agent 入口」这一用法，直至显式解冻。

4. **`AGENTS.md`** 区分 **production UI** 与 **MD3E Lab UI** 指针；贡献者地图见 `CONTRIBUTING.md`（可选后续一句交叉引用）。

## Consequences

### Positive

- Lab 迭代与验收单一闭环（Widgetbook），减少文档/稿面漂移。
- Agent 不再被 MASTER 中与 Kazumi 式目录栏、MD3E 分页等冲突的描述误导。

### Negative

- `design-system/` 与 Lab/生产差距会随时间拉大，解冻或迁生产时需一次性对齐成本。
- ui-ux-pro-max `--persist` 写入 `design-system/` 在 Lab 阶段应 **默认跳过** 或仅用于非 MD3E 范围，避免误以为已更新现行规范。

## References

- ADR-0027、ADR-0028、ADR-0029
- `AGENTS.md`（Flutter UI — production / MD3E Lab / design-system frozen）
- `app/widgetbook/main.dart`、`app/lib/md3e/`
