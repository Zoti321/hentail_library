# Agent 协作文档（`docs/agents/`）

本目录是 **`AGENTS.md` 的披露层**：只在 agent 需要分支细节时才读。人类维护索引在根目录 `AGENTS.md`（保持短）。

## 文件分工

| 文件 | 何时读 | 写什么 / 不写什么 |
|------|--------|-------------------|
| `product-positioning.md` | 定范围、格式、做不做某能力 | 产品边界；**词汇**指向 `GLOSSARY.md` |
| `rust-core.md` | Rust / FRB / SQLite / 扫描阅读 | 不可破坏契约；**步骤**以 ADR + 代码为准 |
| `coding-style.md` | 写/改 Dart UI 与分层 | 项目特有规则；通用 Flutter 常识不写 |
| `ui-style.md` | 做界面、组件选型 | 与 `design-system/` 一致；主题以代码为准 |
| `testing.md` | 跑 Gate、加测试、import 缝 | 与 `gate.yml` / `manifest.txt` 同源 |
| `issue-tracker.md` | `gh issue` 操作与 triage 标签 | 命令表即可 |
| `operations/*` | 日志导出、标签字典导入 | 运维/数据格式一次性流程 |

已决策记录 → `docs/adr/`。领域词条 → `GLOSSARY.md`。历史调研与迁移矩阵 → `docs/archive/`（**勿当现行规范**）。

## 怎么写（对齐 writing-for-agents / v1.3）

1. **两层负载**  
   - **Context load**：`AGENTS.md` 每一行每轮都占窗口 → 只留触发语 + 路径。  
   - **Cognitive load**：你记住「有哪些 doc」——目录宜少、分工清晰。

2. **单源**  
   - 术语：`GLOSSARY.md`  
   - 架构决策：`docs/adr/`  
   - 能机械检查的（import 边、目录布局、Gate 路径）→ **测试 + CI**，不要在 Markdown 里复制一份会漂移的清单。

3. **指针写法**  
   - 写清 **何时读**（分支），不要只写「详见某某」。  
   - 用仓库内已有的 **leading word**（如 Page image fidelity、Library sync）与 `GLOSSARY.md` 一致。

4. **删减比追加重要**  
   - 删掉「写干净代码」「遵循最佳实践」等 no-op。  
   - 删掉与 ADR、脚本、`package.json` 重复的 cache。  
   - 大表若已被 Gate 取代 → 归档或缩成一行 + 测试路径。

5. **改 doc 时自问**  
   - Agent 缺这条会 **做错** 吗？不会 → 别写。  
   - CI 能拦吗？能 → 写进测试，doc 只指到测试名。  
   - 是否重复 `GLOSSARY` / ADR？是 → 改成链接。

6. **篇幅**  
   - `rust-core` / `issue-tracker` / `operations` 保持短。  
   - `testing.md`、`ui-style.md` 可长，但应是 **操作手册**（命令、表、路径），不是教程。

## 维护节奏

- 动架构或分层：ADR + 必要时改 `coding-style` / `testing` 一节 + Gate。  
- 动产品边界：`product-positioning` + `GLOSSARY.md`。  
- 会话里 agent 反复犯同一错：优先 **lint/测试**，再考虑 `/retro` 式地减 `AGENTS.md` 噪声。
