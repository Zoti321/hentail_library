import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';

/// Tag 仓储：独立于 Comic/Series 的“标签字典管理”。
abstract class TagRepository {
  Future<List<Tag>> listAll();

  Future<PagedResult<Tag>> fetchPage(PageRequest request);

  Future<void> add(Tag tag);

  Future<void> deleteByNames(List<String> names);

  Future<void> rename(String oldName, String newName);
}
