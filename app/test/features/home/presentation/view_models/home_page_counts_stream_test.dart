import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/features/library_browse/public/library_age_restriction_filter.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_dictionary_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/home_library_stat.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  test(
    'homePageCountsStream exposes one Home page counts seam with facet lengths',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          homePageRepoProvider.overrideWithValue(
            _FakeHomePageRepository(
              const HomePageCounts(
                comicCount: 10,
                tagCount: 4,
                seriesCount: 2,
                authorCount: 3,
                libraryCount: 1,
                parodyCount: 0,
                characterCount: 0,
              ),
            ),
          ),
          parodyRepoProvider.overrideWithValue(
            _FakeFacetDictionaryRepository(const <String>['A', 'B']),
          ),
          characterRepoProvider.overrideWithValue(
            _FakeFacetDictionaryRepository(const <String>['X', 'Y', 'Z']),
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

final class _FakeHomePageRepository implements HomePageRepository {
  const _FakeHomePageRepository(this._counts);

  final HomePageCounts _counts;

  @override
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18}) {
    return Stream<HomePageCounts>.value(_counts);
  }

  @override
  Stream<List<HomeLibraryAlert>> watchHomeLibraryAlerts() {
    return const Stream<List<HomeLibraryAlert>>.empty();
  }

  @override
  Stream<List<HomeLibraryStat>> watchLibraryStats({required bool excludeR18}) {
    return const Stream<List<HomeLibraryStat>>.empty();
  }
}

final class _FakeFacetDictionaryRepository
    implements NamedFacetDictionaryRepository {
  const _FakeFacetDictionaryRepository(this._names);

  final List<String> _names;

  @override
  Future<List<String>> listAll() async => _names;

  @override
  Future<List<String>> listDistinct({String? libraryId}) async => _names;
}
