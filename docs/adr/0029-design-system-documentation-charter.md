# ADR-0029: design-system 目录章程（规划文档、Agent 规范、ui-ux-pro-max 输出）

## Status

Accepted

## Context

仓库已有 Flutter 主题与组件实现（ADR-0028）、UI 四层边界（ADR-0027），以及 `design-system/hentai-library/MASTER.md` 与按路由的 `pages/*` override。贡献者与 Agent 需要明确：`design-system/` 不仅是可选的设计笔记，而是与 `AGENTS.md` 对齐的 **UI 规范入口**；同时 ui-ux-pro-max 的 `--persist` 默认写入同一路径结构，若职责不清易出现「Skill 泛化建议覆盖人工 MASTER」或「文档与 `buildAppTheme` 数值分叉」。

产品领域词汇仍在 `GLOSSARY.md`（如 **Settings list–detail**、**Page image fidelity**）；本 ADR 不将实现细节写入词汇表。

## Decision

### 1. 三重角色（同一目录树）

`design-system/hentai-library/` 同时承担：

1. **项目设计系统规划文档** — 风格方向（Fluent 现代化、跨平台单壳）、页面模式、组件选用与反模式。
2. **面向 Agent 的 UI 规范** — `AGENTS.md` 指向 MASTER + `pages/*`；构建某路由时先读 override，再读 MASTER。
3. **ui-ux-pro-max 持久化输出** — `--design-system --persist` 写入相同 `MASTER.md` / `pages/` 形状；**默认不 `--force` 覆盖**已有人工维护内容。

### 2. 真源分层（避免双主）

| 层 | 职责 |
|----|------|
| **规范文档** | `design-system/hentai-library/` — 意图、语义、页面差异、检查清单；可含外部稿（Figma）链接。 |
| **可执行真值** | `app/lib/shared/ui/theme/` 与 `shared/ui/widgets/` — token 数值与组件行为；MASTER 声明数值以代码为准，变更须文档与代码同 PR 或紧接跟进。 |
| **结构决策** | `docs/adr/` — 为何不把 design system 抽成独立 package（ADR-0028 与 #227）、依赖边界（ADR-0027）等。 |

### 3. Skill 产出治理

- 合并 ui-ux-pro-max 输出前，按 MASTER **Anti-Patterns** 与产品语境筛选；忽略与漫画库、单壳响应式无关的泛化「营销页」建议（见既有 page override 先例）。
- 页面级差异只写在 `pages/<name>.md`，禁止在 MASTER 重复整页说明。

### 4. 不在此目录承载的内容

- Gate 细则、CI tier、Rust/FRB 契约 → `docs/engineering/`
- 过期 backlog → 非 `docs/archive/` 现行规范
- 大段可复制进仓库的 Dart 实现

## Consequences

### Positive

- 人、Agent、Skill 共享一套层级检索（Master + Overrides）。
- 与 ADR-0028「代码侧 token 主骨架」互补，减少「只有 Figma/只有 Markdown」的漂移。

### Negative

- 需纪律：视觉现代化大改时同步更新 MASTER/pages 与 theme/widgets。
- ui-ux-pro-max 与人工编辑同一树，合并前需人工或 PR review。

## References

- `design-system/hentai-library/MASTER.md`（含 Directory charter）
- ADR-0027、ADR-0028
- ui-ux-pro-max Skill Step 2b（`--persist` 路径约定）
