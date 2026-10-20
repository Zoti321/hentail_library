# UI / 设计系统改造路线图

> **状态：** 规划真源；实现由 `ready-for-agent` spec 驱动。Wayfinder 地图：[#319](https://github.com/Zoti321/hentail_library/issues/319)。  
> **分支：** `dev`；合 `main` 须显式 PR 审批。

## 阶段

| 阶段 | 产出 | 状态 |
|------|------|------|
| **P0** | `foundations/*` 正文、`references.md`、MASTER Documentation index | 骨架见 [#324](https://github.com/Zoti321/hentail_library/issues/324)；`/to-spec` 落盘 |
| **P1** | `references.md` 官方链接 + Figma TBD | [#323](https://github.com/Zoti321/hentail_library/issues/323) |
| **P2** | `buildAppTheme` / `ThemeExtension` 与 Tier A 对齐 | 见下文 |
| **P3** | 按 `pages/*` 六批改版 | [#322](https://github.com/Zoti321/hentail_library/issues/322) |

采纳分层（Tier A/B/C）：[foundations/README.md](./foundations/README.md#采纳分层tier-abc)（[#327](https://github.com/Zoti321/hentail_library/issues/327)）。

## P2 — 代码同步（[#325](https://github.com/Zoti321/hentail_library/issues/325)）

单次 PR **不得**夹带 P3 整页视觉改版。建议拆为：

| 批次 | 范围 |
|------|------|
| **P2-a 色板** | `app_color_scheme`、`hentai_color_scheme`、`buildAppTheme`；可含 `AppShadowPalette` |
| **P2-b 几何字阶** | `AppSpacingTokens`、`AppRadiusTokens`、`AppTextTokens`、`AppLayoutTokens` |
| **P2-c 阴影动效** | `AppShadowTokens`、`AppMotionTokens`；不要求单 PR 改完 shadow call site |
| **P2-d 迁移** | `colorScheme.hentai` → `context.hentai`；触及文件内硬编码；≤15 文件或单 feature |

**解锁 P3-1：** P2-a + P2-c **最小集**（extensions 齐全、`hentai_color_scheme_tokens_test` 通过）。

**必跑：** `./scripts/run-gate.sh`；`app/test/shared/ui/theme/hentai_color_scheme_tokens_test.dart`；改 tailor 源则提交 `*.tailor.dart`。

**Widgetbook：** 尽力更新 Light/Dark 相关用例；非 gate。

**文档：** 语义/角色变更与代码 **同 PR**；仅数值可调可紧接 PR（≤48h），见 ADR-0029。

## P3 — 按路由（[#322](https://github.com/Zoti321/hentail_library/issues/322)）

| 批 | 页面 | Scope |
|----|------|-------|
| P3-1 | `library`、`all-libraries` | P3-V |
| P3-2 | `comic-detail`、`series-detail`、`author-detail` | P3-V |
| P3-3 | `settings` | P3-L |
| P3-4 | `reader` | P3-V+（仅 chrome，不动 Page image fidelity） |
| P3-5 | `metadata`、`searched`、`history` | P3-V |
| P3-6 | `home`、`route-not-found` | P3-V |

Shell（sidebar、title bar）不纳入上表；另立 **P3-Shell** spec。

## 外链与稿面

裁决顺序与 R0/R1/R2：[#323](https://github.com/Zoti321/hentail_library/issues/323) → 落盘 `references.md`（P0 spec）。
