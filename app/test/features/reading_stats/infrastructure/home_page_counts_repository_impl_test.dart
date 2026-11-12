import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic_metadata/public.dart';
import 'package:hentai_library/features/reading_stats/infrastructure/repositories/home_page_counts_repository_impl.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts_repository.dart';

void main() {
  test('HomePageCountsRepositoryImpl implements HomePageCountsRepository', () {
    final HomePageCountsRepository port = HomePageCountsRepositoryImpl(
      parodyRepository: const _FakeFacetDictionaryRepository(<String>['a']),
      characterRepository: const _FakeFacetDictionaryRepository(<String>[
        'b',
        'c',
      ]),
    );
    expect(port, isA<HomePageCountsRepositoryImpl>());
  });
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
