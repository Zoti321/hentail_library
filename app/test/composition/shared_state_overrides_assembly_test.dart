import 'package:hentai_library/shared/presentation/providers/comic_return_series_providers.dart';
import 'package:hentai_library/shared/presentation/providers/library_reorder_providers.dart';
import 'package:hentai_library/shared/presentation/providers/trash_comics_command_provider.dart';
import 'package:hentai_library/shared/presentation/providers/comic_read_query_provider.dart';
import 'package:hentai_library/composition/infrastructure_overrides.dart';
import 'package:hentai_library/composition/overrides/domain_event_bus_overrides.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:hentai_library/shared/presentation/providers/author_detail_providers.dart';
import 'package:hentai_library/shared/presentation/providers/library_browse_fallback_providers.dart';
import 'package:hentai_library/shared/presentation/providers/series_item_membership_providers.dart';
import 'package:hentai_library/shared/presentation/providers/series_item_sort_providers.dart';
import 'package:hentai_library/shared/presentation/providers/series_reading_context_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/composition/feature_state_overrides.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';

void main() {
  test('featureStateOverrides 注入 library_admin currentLibraryPort', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        ...domainEventBusOverrides(),
        ...infrastructureOverrides(),
        ...featureStateOverrides(),
      ],
    );
    addTearDown(container.dispose);

    expect(
      () => container.read(submitLibraryFormCommandProvider),
      returnsNormally,
    );
    expect(() => container.read(deleteLibraryCommandProvider), returnsNormally);
    expect(
      () => container.read(updateLibrarySidebarCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(startLibraryScanCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(cancelLibraryScanCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(refreshComicMetadataCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(refreshSeriesMetadataCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(refreshLibraryMetadataCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(cancelMetadataRefreshCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(bulkEditComicMetadataCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(exitLibraryReorderCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(rememberComicReturnSeriesCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(clearComicReturnSeriesCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(goLibraryBrowseFallbackCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(openAuthorByIdCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(openAuthorByNameCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(findSeriesItemMembershipQueryProvider),
      returnsNormally,
    );
    expect(
      () => container.read(findSeriesReadingContextQueryProvider),
      returnsNormally,
    );
    expect(
      () => container.read(persistSeriesItemSortCommandProvider),
      returnsNormally,
    );
    expect(
      () => container.read(recordReadingProgressCommandProvider),
      returnsNormally,
    );
    expect(() => container.read(readResumePageQueryProvider), returnsNormally);
    expect(
      () => container.read(recordReadSessionActivityCommandProvider),
      returnsNormally,
    );
    expect(() => container.read(trashComicsCommandProvider), returnsNormally);
    expect(() => container.read(comicReadQueryProvider), returnsNormally);
  });
}
