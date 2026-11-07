/// library_browse 壳内 Comic 集成桥（#457）。
///
/// browse 本地消费 comic presentation / 窄 public；勿再经 `comic/public/shell`。
library;

export 'package:hentai_library/features/comic/presentation/comic_card_host.dart';
export 'package:hentai_library/features/comic/presentation/view_models/comic_detail_return_series_notifier.dart';
export 'package:hentai_library/features/comic/presentation/view_models/comic_detail_series_nav_provider.dart';
export 'package:hentai_library/features/comic/presentation/view_models/comic_read_progress.dart';
export 'package:hentai_library/features/comic/presentation/views/bulk_edit/bulk_edit_metadata_presenter.dart';
export 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';
export 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_present.dart';
export 'package:hentai_library/features/comic/presentation/views/metadata_edit/comic_metadata_edit_page.dart';
export 'package:hentai_library/features/comic/public/di/comic_cover_providers.dart';
export 'package:hentai_library/features/comic/public/di/comic_repository_providers.dart';
export 'package:hentai_library/features/comic/public/library_comic_browse_rules.dart';
export 'package:hentai_library/features/comic/public/ui/comic_cover_content.dart';
