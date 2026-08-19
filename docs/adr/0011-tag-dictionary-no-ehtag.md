# ADR-0011: 移除 EhTagTranslation 接入，保留通用标签字典导入

## Status

Accepted

## Context

元数据页曾提供「从 E-Hentai 导入标签」，从 EhTagTranslation `db.text.json` 下载并将 `female` / `male` / `mixed` / `other` 命名空间的中文译名写入全局 Tag 字典。

产品讨论后明确：

1. 只需**常用通用**标签，而非 EhTag 全量或四命名空间全量（约 1,200+ 条）
2. 不做英文↔中文 alias 映射；Tag 仍为单一 `name`
3. 禁漫天堂、哔咔无独立开源标签库，EhTag 偏 E 站体系，不适合作为长期默认词库
4. 维护者将自建精选标签 JSON 仓库，后续再接入应用

## Decision

- **移除** EhTag 专用代码：固定 URL、`db.text.json` 解析、命名空间过滤、元数据页「从 EHentai 导入」菜单项
- **保留** 通用 **Tag dictionary import** 管道：
  - Rust `import_tag_dictionary`：接受 `{"tags":[...]}` 或 `[...]` JSON
  - Flutter `TagDictionaryDownloadService`（任意 URL）+ `TagDictionaryImportController` + 进度对话框组件
- **暂不暴露** UI 导入入口，待自维护词库就绪后再接线

## Consequences

### Positive

- 词库内容与发布节奏由项目掌控，不受 EhTag CC BY-NC-SA 与 E 站标签体系约束
- 导入逻辑更简单、可测试、与具体平台解耦
- 已有用户手动创建的 Tag 与 Comic 附着不受影响

### Negative

- 首次安装不再一键获得大量中文标签建议；需等待自维护词库或手动添加
- 保留的 controller/dialog 在 UI 接入前为「待用」代码

## 参考

- `docs/agents/tag-dictionary-import.md` — JSON 格式与接入步骤
- `CONTEXT.md` — **Tag dictionary import** 术语
