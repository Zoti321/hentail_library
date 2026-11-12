import 'package:hentai_library/features/comic_metadata/data/adapters/tag_frb_adapter.dart';
import 'package:hentai_library/features/comic_metadata/data/mappers/tag_frb_mapper.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_dictionary_import_result.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_repository.dart';

class TagRepositoryImpl implements TagRepository {
  const TagRepositoryImpl({
    required this.namedFacets,
    TagFrbAdapter? tagFrbAdapter,
  }) : _tagFrbAdapter = tagFrbAdapter ?? const TagFrbAdapter();

  final NamedFacetManagementRepository namedFacets;
  final TagFrbAdapter _tagFrbAdapter;

  @override
  Future<List<Tag>> listAll() async {
    final List<String> names = await namedFacets.listAll(
      ManagedNamedFacetKind.tag,
    );
    return names.map((String n) => Tag(name: n)).toList();
  }

  @override
  Future<TagDictionaryImportResult> importTagDictionary(
    List<int> jsonBytes,
  ) async {
    return mapTagDictionaryImportResult(
      _tagFrbAdapter.importTagDictionary(jsonBytes),
    );
  }
}
