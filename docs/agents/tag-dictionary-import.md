# Tag dictionary import

标签字典从外部 JSON 批量导入全局 **Tag** 字典的基础设施说明。

## 背景

应用曾接入 [EhTagTranslation/Database](https://github.com/EhTagTranslation/Database)（E-Hentai 标签中文库）。该方案已移除 UI 与 EhTag 专用解析，原因：

- EhTag 覆盖 E 站全量命名空间，与「只导入常用通用标签」的产品方向不符
- 禁漫天堂、哔咔等平台无对等开源标签库，EhTag 无法作为跨平台通用词库
- 后续改由维护者自建精选标签仓库并接入

详见 [ADR-0011](../adr/0011-tag-dictionary-no-ehtag.md)。

## 仍保留的基础能力

| 层 | 模块 | 职责 |
| --- | --- | --- |
| Rust core | `import_tag_dictionary` | 解析 JSON、去重、幂等写入 `tags` 表 |
| Flutter data | `TagDictionaryDownloadService` | 从任意 URL 下载 JSON 字节 |
| Flutter UI/state | `TagDictionaryImportController` | 编排下载 → 导入；`TagDictionaryImportDialog` 进度对话框（暂无 UI 入口） |
| Domain | `TagRepository.importTagDictionary` | 仓储边界 |

接入自维护词库时，只需：

1. 在 GitHub（或其他）发布符合下方格式的 JSON
2. 在 UI 增加入口，调用 `TagDictionaryImportController.importFromNetwork(url: …)` 或 `importFromBytes`
3. 可选：在 `app/lib/core/constants/` 增加默认下载 URL 常量

## JSON 格式

支持两种等价形态：

```json
{ "tags": ["全彩", "无修正", "NTR"] }
```

或

```json
["全彩", "无修正", "NTR"]
```

规则：

- 每项为 Tag 的 `name` 字符串（trim 后非空）
- 导入内去重；与库中已有 Tag 按 name 精确匹配，已存在则跳过
- 不修改、不删除已有 Tag；不自动附着到任何 Comic

## 导入结果

`TagDictionaryImportResult` 字段：

| 字段 | 含义 |
| --- | --- |
| `added` | 新写入字典的 Tag 数 |
| `skipped_existing` | 库中已存在而跳过 |
| `skipped_filtered_or_empty_or_dedupe` | 空名、重复项等被过滤 |

## Agent 指引

- 文档与 issue 中用 **Tag dictionary import**，勿再引用 EhTagTranslation 为默认数据源
- 不要恢复 EhTag 命名空间过滤逻辑；新词库由发布方在 JSON 中 curated
- UI 未暴露导入入口前，相关 l10n 键（`metadataImportTagDictionary*`）供后续接入使用
