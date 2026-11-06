/// Comic/Series 详情与 metadata 编辑所需的 browse 壳层符号（#457）。
///
/// Cross-feature 仅 import 本路径或 [library_browse/public.dart]；勿 deep import presentation。
/// 只保留 comic/series 实际消费的壳原子（阶段 2 收窄）。
library;

export 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_selection_header.dart';
export 'package:hentai_library/features/library_browse/presentation/browse/views/widgets/comic_card_actions.dart';
export 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_comics_providers.dart';
export 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_snapshot.dart';
export 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_page_size_settings.dart';
export 'package:hentai_library/features/library_browse/presentation/catalog/content_breadcrumb_labels.dart';
export 'package:hentai_library/features/library_browse/presentation/catalog/patterns/metadata_edit/metadata_field_locks_kv_list.dart';
export 'package:hentai_library/features/library_browse/presentation/catalog/patterns/metadata_edit/metadata_lock_callbacks.dart';
export 'package:hentai_library/features/library_browse/presentation/catalog/view_models/catalog_pagination_engine.dart';
export 'package:hentai_library/features/library_browse/presentation/catalog/view_models/catalog_selection_notifier.dart';
export 'package:hentai_library/features/library_browse/presentation/catalog/views/metadata_edit/metadata_edit_mappers.dart';
export 'package:hentai_library/features/library_browse/presentation/catalog/views/metadata_edit/metadata_edit_presenters.dart';
export 'package:hentai_library/features/library_browse/presentation/catalog/views/widgets/detail_status/detail_back_header.dart';
export 'package:hentai_library/features/library_browse/presentation/catalog/views/widgets/detail_status/detail_status_scaffold.dart';
export 'package:hentai_library/features/library_browse/public/ui/author_detail_page.dart';
