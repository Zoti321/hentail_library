import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/tag_dictionary_import_result.dart';

/// Tag 仓储：全量 Tag 字典读取与 Tag dictionary import。
///
/// 管理页的分页 / 增删改 / 合并走 `NamedFacetManagementRepository`。
abstract class TagRepository {
  Future<List<Tag>> listAll();

  Future<TagDictionaryImportResult> importTagDictionary(List<int> jsonBytes);
}
