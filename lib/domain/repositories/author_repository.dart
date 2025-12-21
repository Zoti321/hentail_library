import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';

/// Author 仓储：独立于 Comic 的「作者字典管理」。
abstract class AuthorRepository {
  Future<List<Author>> listAll();

  /// 作者字典表变化时推送（含漫画侧 [replaceComicAuthors] 写入的 insertOrIgnore）。
  Stream<List<Author>> watchAll();

  Future<PagedResult<Author>> fetchPage(PageRequest request);

  Future<void> add(Author author);

  Future<void> deleteByNames(List<String> names);

  Future<void> rename(String oldName, String newName);
}
