import 'package:hentai_library/shared/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/tag_dictionary_import_result.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/shared/domain/repositories/tag_repository.dart';
import 'package:hentai_library/src/rust/api/tag.dart' as rust_tag;

class TagRepositoryImpl implements TagRepository {
  const TagRepositoryImpl({required this.namedFacets});

  final NamedFacetManagementRepository namedFacets;

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
    final rust_tag.TagDictionaryImportResultDto result = guardFrbSync(
      () => rust_tag.importTagDictionaryFrb(jsonBytes: jsonBytes),
      fallbackMessage: '导入标签字典失败',
    );
    return TagDictionaryImportResult(
      added: result.added,
      skippedExisting: result.skippedExisting,
      skippedFilteredOrEmptyOrDedupe: result.skippedFilteredOrEmptyOrDedupe,
    );
  }
}
