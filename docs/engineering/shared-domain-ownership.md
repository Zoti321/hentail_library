# `shared/domain` 归属表（Epic #436 收尾）

**决策索引**：ADR-0033（Application 层）、ADR-0034（public only）、**ADR-0035**（Catalog Shared Kernel）。  
**门禁**：L3b `shared_domain_feature_import_baseline.json`（当前应为 `[]`）；strangler 仅 `app/test/gate/strangler_shims.txt` 列出的 export-only 路径。

## 真源在 owner feature（shared 仅为 strangler re-export）

| shared 路径（薄 shim） | Owner 真源 |
| --- | --- |
| `comic_trash/*`、`models/read_models/trashed_comic.dart` | `features/comic_trash/domain/` |
| `reading/*` | `features/read_session/domain/` |
| `library/*`（除下表「仍 @ shared」） | `library_browse/domain/` 或 `library_admin/domain/`（见各文件 `export` 目标） |
| `comic/comic_display_title.dart` | `features/library_browse/domain/` |
| `ports/reader_session_port.dart`、`comic_page_source_port.dart`、`clipboard_image_port.dart` | `features/read_session/domain/` |
| `ports/reader_settings_command_port.dart` | `features/app_settings/domain/` |
| `repositories/*`（除 reading_history） | 各 owner `features/*/domain/`（与 data 实现同 feature） |
| **reading_history feature** | `features/reading_history/`（domain、data、`/history` 全套 presentation）；`public.dart` export 实体与 `HistoryCardItem` 供 home「继续阅读」网格 |
| `models/app_setting*.dart` | `features/app_settings/domain/` |
| `models/entity/reading_history.dart`、`repositories/reading_history_repository.dart` | `features/reading_history/domain/` |
| `models/read_models/home_page_read_models.dart` | `features/home/domain/` |
| `models/named_facet_form_candidate.dart`、`models/tag_dictionary_import_result.dart` | `features/named_metadata/domain/` |

Feature 内代码应 **import owner `domain/`**；跨 feature 经 **`features/<owner>/public/**`**（ADR-0034）。过渡期仍可从 `shared/domain/...` import，但新代码勿增 shared 路径依赖。

## Catalog Shared Kernel（真源 @ shared，ADR-0035）

不在 #436 批量迁出；consumer 继续 `import shared/domain/...`：

- `models/entity/comic/**`、`models/enums.dart`
- `models/value_objects/page_request.dart`、`paged_result.dart`、`page_jump.dart`
- 与 catalog 强绑定的 form / pick / meta VO（见 `models/models.dart` barrel）
- `thumbnail/**`

## 契约仍定义在 `shared/domain`（未 owner 化）

UI / 编排命令类型；发现面经 owner `public/` re-export（ADR-0034）：

- `ports/author_detail_port.dart`
- `ports/comic_trash_command_port.dart`
- `ports/library_management_port.dart`
- `ports/library_revision_port.dart`、`ports/library_revision_signal_port.dart`
- `ports/read_session_launch_port.dart`
- `library/comic_detail_return_series_port.dart`

`shared/di` 与 bootstrap 仍从此处 import 类型（R11：shared 不得 import feature public）。

## 测试目录约定

- Owner 域行为单测：`app/test/features/<owner>/domain/**`
- Shared Kernel / 跨库契约：`app/test/shared/domain/**`（entity、VO、repository 契约等）
