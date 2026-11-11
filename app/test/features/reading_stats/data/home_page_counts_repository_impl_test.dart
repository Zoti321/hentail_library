import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/named_metadata/public.dart';
import 'package:hentai_library/features/reading_stats/data/repositories/home_page_counts_repository_impl.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts_port.dart';

void main() {
  test('HomePageCountsRepositoryImpl implements HomePageCountsPort', () {
    final HomePageCountsPort port = HomePageCountsRepositoryImpl(
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
