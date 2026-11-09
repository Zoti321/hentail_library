import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/library_browse/public/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/reading_stats_providers.dart';
import 'package:hentai_library/shared/domain/ports/home_page_counts_port.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  test(
    'homePageCountsStream exposes one Home page counts seam via reading_stats port',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          homePageCountsPortProvider.overrideWithValue(
            _FakeHomePageCountsPort(
              const HomePageCounts(
                comicCount: 10,
                tagCount: 4,
                seriesCount: 2,
                authorCount: 3,
                parodyCount: 2,
                characterCount: 3,
                libraryCount: 1,
              ),
            ),
          ),
          libraryComicAgeRestrictionStateProvider.overrideWithValue(
            LibraryAgeRestrictionFilter.unrestricted,
          ),
          libraryRevisionThrottleBusyStateProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final Completer<HomePageCounts> completer = Completer<HomePageCounts>();
      container.listen(homePageCountsStreamProvider, (
        AsyncValue<HomePageCounts>? previous,
        AsyncValue<HomePageCounts> next,
      ) {
        next.when(
          data: (HomePageCounts value) {
            if (!completer.isCompleted) {
              completer.complete(value);
            }
          },
          error: (Object error, StackTrace stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
          loading: () {},
        );
      }, fireImmediately: true);

      final HomePageCounts counts = await completer.future.timeout(
        const Duration(seconds: 5),
      );

      expect(counts.comicCount, 10);
      expect(counts.seriesCount, 2);
      expect(counts.authorCount, 3);
      expect(counts.parodyCount, 2);
      expect(counts.characterCount, 3);
      expect(counts.tagCount, 4);
    },
  );
}

final class _FakeHomePageCountsPort implements HomePageCountsPort {
  const _FakeHomePageCountsPort(this._counts);

  final HomePageCounts _counts;

  @override
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18}) {
    return Stream<HomePageCounts>.value(_counts);
  }
}
