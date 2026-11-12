import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/di/overrides/domain_event_bus_overrides.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/library_browse/public/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  test(
    'Home and direct consumer share the source stream and propagate errors',
    () async {
      var subscriptions = 0;
      final source = StreamController<HomePageCounts>(
        onListen: () {
          subscriptions++;
        },
      );
      final container = ProviderContainer(
        overrides: [
          homePageCountsProvider.overrideWith(
            (ref, excludeR18) => source.stream,
          ),
          libraryComicAgeRestrictionStateProvider.overrideWithValue(
            LibraryAgeRestrictionFilter.unrestricted,
          ),
          libraryRevisionThrottleBusyStateProvider.overrideWithValue(false),
        ],
      );
      final changed = Completer<void>();
      final failed = Completer<void>();
      container.listen(homePageCountsStreamProvider, (_, next) {
        if (next.asData?.value.comicCount == 2 && !changed.isCompleted) {
          changed.complete();
        }
        if (next.hasError && !failed.isCompleted) {
          failed.complete();
        }
      });
      container.listen(homePageCountsProvider(false), (_, next) {});
      source.add(
        const HomePageCounts(
          comicCount: 1,
          seriesCount: 0,
          authorCount: 0,
          tagCount: 0,
          parodyCount: 0,
          characterCount: 0,
          libraryCount: 1,
        ),
      );
      expect(
        (await container.read(homePageCountsStreamProvider.future)).comicCount,
        1,
      );
      source.add(
        const HomePageCounts(
          comicCount: 2,
          seriesCount: 0,
          authorCount: 0,
          tagCount: 0,
          parodyCount: 0,
          characterCount: 0,
          libraryCount: 1,
        ),
      );
      await changed.future;
      source.addError(StateError('counts'));
      await failed.future;
      expect(subscriptions, 1);
      container.dispose();
      await source.close();
    },
  );

  test('homePageCountsStream exposes one Home page counts seam via reading_stats port', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        ...domainEventBusOverrides(),
        homePageCountsProvider.overrideWith(
          (ref, excludeR18) => _CountsStream(
            const HomePageCounts(
              comicCount: 10,
              tagCount: 4,
              seriesCount: 2,
              authorCount: 3,
              parodyCount: 2,
              characterCount: 3,
              libraryCount: 1,
            ),
          ).watchHomePageCounts(excludeR18: excludeR18),
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
  });
}

final class _CountsStream {
  const _CountsStream(this._counts);

  final HomePageCounts _counts;

  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18}) {
    return Stream<HomePageCounts>.value(_counts);
  }
}
