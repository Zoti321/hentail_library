import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/tag_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;
import 'package:hentai_library/src/rust/api/tag.dart' as rust_tag;

class TagRepositoryImpl implements TagRepository {
  const TagRepositoryImpl();

  @override
  Future<List<Tag>> listAll() async {
    final List<String> names = guardFrbSync(
      rust_tag.listAllTagsFrb,
      fallbackMessage: '读取标签列表失败',
    );
    return names.map((String n) => Tag(name: n)).toList();
  }

  @override
  Future<PagedResult<Tag>> fetchPage(PageRequest request) async {
    final rust_tag.TagPagedNamesDto page = guardFrbSync(
      () => rust_tag.fetchTagsPageFrb(
        request: rust.PageRequestDto(
          page: request.page,
          pageSize: request.pageSize,
        ),
      ),
      fallbackMessage: '读取标签分页失败',
    );
    return PagedResult<Tag>(
      items: page.items.map((String n) => Tag(name: n)).toList(),
      totalCount: page.totalCount.toInt(),
      page: page.page,
      pageSize: page.pageSize,
    );
  }

  @override
  Future<void> add(Tag tag) async {
    guardFrbSync(
      () => rust_tag.addTagFrb(name: tag.name),
      fallbackMessage: '添加标签失败',
    );
  }

  @override
  Future<void> deleteByNames(List<String> names) async {
    guardFrbSync(
      () => rust_tag.deleteTagsByNamesFrb(names: names),
      fallbackMessage: '删除标签失败',
    );
  }

  @override
  Future<void> rename(String oldName, String newName) async {
    guardFrbSync(
      () => rust_tag.renameTagFrb(oldName: oldName, newName: newName),
      fallbackMessage: '重命名标签失败',
    );
  }
}
