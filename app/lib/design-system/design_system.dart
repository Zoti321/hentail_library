/// Design System 层：业务无关的主题、动效、布局常量与通用控件（ADR-0044）。
///
/// 本文件是**唯一对外入口**。层内不得 import `features/**`、`shared/ui/**`、
/// `shared/domain/**`、`shared/di/**`、`shared/data/**`；只允许依赖
/// `core/**`、`shared/util/**`、层内相对路径与第三方包。
///
/// 段填充顺序：#495 S1（theme / motion / layout / l10n）、S2–S3（components / util）。
library;
