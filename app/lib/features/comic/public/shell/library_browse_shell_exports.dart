/// library_browse 壳层所需的 Comic presentation 符号（#457）。
///
/// **壳接缝，非领域 API**：为 browse 壳临时 re-export presentation；
/// 后续可按消费者收窄或迁回 browse 本地 bridge。勿把新的跨 feature 契约堆进本文件。
library;

export 'package:hentai_library/features/comic/presentation/comic_card_host.dart';
export 'package:hentai_library/features/comic/presentation/view_models/comic_detail_return_series_notifier.dart';
export 'package:hentai_library/features/comic/presentation/view_models/comic_detail_series_nav_provider.dart';
export 'package:hentai_library/features/comic/presentation/view_models/comic_read_progress.dart';
export 'package:hentai_library/features/comic/presentation/views/bulk_edit/bulk_edit_metadata_presenter.dart';
export 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';
export 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_present.dart';
export 'package:hentai_library/features/comic/presentation/views/metadata_edit/comic_metadata_edit_page.dart';
