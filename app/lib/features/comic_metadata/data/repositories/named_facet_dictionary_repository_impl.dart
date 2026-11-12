import 'package:hentai_library/features/comic_metadata/data/adapters/named_facet_dictionary_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_dictionary_repository.dart';

class NamedFacetDictionaryRepositoryImpl
    implements NamedFacetDictionaryRepository {
  NamedFacetDictionaryRepositoryImpl(
    this.kind, {
    NamedFacetDictionaryFrbAdapter? adapter,
  }) : _adapter = adapter ?? NamedFacetDictionaryFrbAdapter(kind);

  final NamedFacetKind kind;
  final NamedFacetDictionaryFrbAdapter _adapter;

  @override
  Future<List<String>> listAll() => _adapter.listAll();

  @override
  Future<List<String>> listDistinct({String? libraryId}) =>
      _adapter.listDistinct(libraryId: libraryId);
}
