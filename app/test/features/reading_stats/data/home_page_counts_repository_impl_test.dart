import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts_repository.dart';
import 'package:hentai_library/shared/domain/library/home_page_counts.dart';
import 'package:hentai_library/shared/domain/ports/home_page_counts_port.dart';

void main() {
  test(
    'HomePageCountsPort surfaces repository Home page counts including facets',
    () async {
      final HomePageCountsPort port = _Adapter(
        _FakeHomePageCountsRepository(
          const HomePageCounts(
            comicCount: 5,
            tagCount: 3,
            seriesCount: 1,
            authorCount: 2,
            parodyCount: 2,
            characterCount: 1,
            libraryCount: 1,
          ),
        ),
      );

      final HomePageCounts counts = await port
          .watchHomePageCounts(excludeR18: false)
          .first;

      expect(counts.comicCount, 5);
      expect(counts.seriesCount, 1);
      expect(counts.authorCount, 2);
      expect(counts.parodyCount, 2);
      expect(counts.characterCount, 1);
      expect(counts.tagCount, 3);
    },
  );
}

final class _FakeHomePageCountsRepository implements HomePageCountsRepository {
  const _FakeHomePageCountsRepository(this._counts);

  final HomePageCounts _counts;

  @override
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18}) {
    return Stream<HomePageCounts>.value(_counts);
  }
}

final class _Adapter implements HomePageCountsPort {
  const _Adapter(this._repository);

  final HomePageCountsRepository _repository;

  @override
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18}) {
    return _repository.watchHomePageCounts(excludeR18: excludeR18);
  }
}
