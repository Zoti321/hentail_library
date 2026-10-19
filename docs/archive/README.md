# 归档文档

**不要**把本目录当作现行规范或任务 backlog。Agent 与贡献者以根目录 `AGENTS.md`、`GLOSSARY.md`、`docs/agents/*`、`docs/adr/*` 与 Gate 测试为准。

| 子目录 | 内容 | 为何归档 |
|--------|------|----------|
| `research/` | 2026-09 / 10 只读调研快照 | 文首已声明「不代表 HEAD」；开放项应以 GitHub Issues 与当前代码为准 |
| `wayfinder/` | #218–#258 模块迁移矩阵与 slice 清单模板 | 迁移已收尾（Phase B）；现行边界由 `app/test/gate/*` 与 `docs/agents/testing.md` 描述 |

复现类脚本仍留在 `scripts/research/`（如 `cross_feature_import_audit.py`），用于人工对照，输出不自动写回仓库。
