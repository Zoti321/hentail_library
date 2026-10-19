# 维护者操作

## GitHub Issues（`gh`）

仓库内用 `gh`（从 `git remote` 推断 repo）。

| 操作 | 命令 |
|------|------|
| 创建 | `gh issue create --title "..." --body "..."` |
| 查看 | `gh issue view <n> --comments` |
| 列表 | `gh issue list --state open --json number,title,labels` |
| 评论 | `gh issue comment <n> --body "..."` |
| 标签 | `gh issue edit <n> --add-label "..."` / `--remove-label "..."` |
| 关闭 | `gh issue close <n> --comment "..."` |

Triage：**恰好一个**标签——`needs-triage` · `needs-info` · `ready-for-agent` · `ready-for-human` · `wontfix`。

## 用户日志与支持

设计：ADR-0004。

1. 用户：**设置 → 诊断与支持** 开 **详细诊断** → 复现 → **导出日志**（默认脱敏 zip）。
2. 包内：`app_log.txt`、`rust_log.txt`、`diagnostics.json`（及 `.bak` 轮转）。
3. UI 卡顿排查：关详细诊断，用 `flutter run --profile` + DevTools Performance。
4. 开发 Rust 日志：`RUST_LOG=hentai_core::sync=debug flutter run`；文件见 ADR-0010 / ADR-0004。

脱敏会缩短路径、哈希 `comic_id`；路径关键时用户选 **完整日志** 并确认隐私。

## Tag dictionary import

背景：ADR-0011（已移除 EhTag 专用接入）。**Tag dictionary import** = 从 JSON 幂等写入全局 Tag 字典。

JSON：

```json
{ "tags": ["标签A", "标签B"] }
```

或 `["标签A", "标签B"]`。trim 非空；库内按 name 精确匹配跳过；不删不改已有 Tag；不附着 Comic。

实现：`import_tag_dictionary`（Rust）、`TagDictionaryImportController` / Dialog（Flutter）。接入自维护词库：发布 JSON + UI 调 `importFromNetwork` / `importFromBytes`。

Issue/文档用 **Tag dictionary import**，勿再以 EhTagTranslation 为默认数据源。
