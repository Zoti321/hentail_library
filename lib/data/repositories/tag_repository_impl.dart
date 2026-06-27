import 'package:hentai_library/data/database/dao/dao.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/tag_repository.dart';

class TagRepositoryImpl implements TagRepository {
  TagRepositoryImpl(this._dao);

  final TagDao _dao;

  @override
  Future<List<Tag>> listAll() async {
    final rows = await _dao.listAll();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return rows.map((r) => Tag(name: r.name)).toList();
  }

  @override
  Future<PagedResult<Tag>> fetchPage(PageRequest request) async {
    final int totalCount = await _dao.countAllTags();
    if (totalCount <= 0) {
      return PagedResult<Tag>(
        items: const <Tag>[],
        totalCount: 0,
        page: 1,
        pageSize: request.pageSize,
      );
    }
    final int totalPages = (totalCount + request.pageSize - 1) ~/ request.pageSize;
    int effectivePage = request.page;
    if (effectivePage > totalPages) {
      effectivePage = totalPages;
    }
    final int offset = (effectivePage - 1) * request.pageSize;
    final rows = await _dao.fetchTagsPage(
      limit: request.pageSize,
      offset: offset,
    );
    return PagedResult<Tag>(
      items: rows.map((r) => Tag(name: r.name)).toList(),
      totalCount: totalCount,
      page: effectivePage,
      pageSize: request.pageSize,
    );
  }

  @override
  Future<void> add(Tag tag) => _dao.addTag(tag.name);

  @override
  Future<void> deleteByNames(List<String> names) async {
    await _dao.deleteByNames(names);
  }

  @override
  Future<void> rename(String oldName, String newName) =>
      _dao.renameTag(oldName, newName);
}
